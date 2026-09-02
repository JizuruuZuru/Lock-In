import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/subject_question_bank.dart';
import '../../models/quiz_question_record.dart';
import '../../services/api/api_exception.dart';
import '../../services/api/firestore_rest_api.dart';
import '../../services/api/open_trivia_api.dart';
import '../../services/custom_question_sync.dart';
import '../../services/question_repository.dart';
import '../../services/sound_service.dart';
import '../../utils/admin_theme.dart';
import '../../utils/responsive_layout.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/source_link.dart';

/// The API integration screen.
///
/// It exercises both halves of the HTTP requirement in one workflow:
///
///  * **GET** — [OpenTriviaApi] fetches the category list and then a batch of
///    multiple-choice questions from https://opentdb.com. Responses are JSON
///    and are parsed into [TriviaQuestion] objects.
///  * **POST** — the questions the admin keeps are written to the project's own
///    backend through [FirestoreRestApi], one HTTP POST per document against
///    the Cloud Firestore REST API.
///
/// Loading, empty, and failure states are all rendered explicitly, and the raw
/// JSON of the last response is viewable so the data behind the table is never
/// a black box.
class TriviaImportPage extends StatefulWidget {
  const TriviaImportPage({super.key});

  @override
  State<TriviaImportPage> createState() => _TriviaImportPageState();
}

/// What the screen is doing right now.
enum _ImportPhase { idle, loadingCategories, fetching, ready, publishing, failed }

class _TriviaImportPageState extends State<TriviaImportPage> {
  final OpenTriviaApi _triviaApi = OpenTriviaApi();
  final FirestoreRestApi _restApi = FirestoreRestApi();
  final QuestionRepository _repository = QuestionRepository();

  _ImportPhase _phase = _ImportPhase.loadingCategories;
  String? _errorMessage;

  List<TriviaCategory> _categories = const [];
  TriviaCategory? _selectedCategory;
  SubjectQuizType _subject = SubjectQuizType.science;
  String _difficulty = 'easy';
  int _amount = 10;

  TriviaFetchResult? _result;

  /// Index-keyed selection over [_result]. Everything starts checked so the
  /// common case is one tap to publish.
  final Set<int> _selected = <int>{};

  /// Prompt keys already in Firestore, used to grey out duplicates.
  Set<String> _existingKeys = <String>{};

  String? _lastPublishJson;
  String? _lastPublishUrl;

  @override
  void initState() {
    super.initState();
    SoundService().playPageBgm(BgmPage.home);
    _loadCategories();
  }

  @override
  void dispose() {
    _triviaApi.dispose();
    _restApi.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------- GET calls

  Future<void> _loadCategories() async {
    setState(() {
      _phase = _ImportPhase.loadingCategories;
      _errorMessage = null;
    });

    try {
      final categories = await _triviaApi.fetchCategories();
      final suggested = OpenTriviaApi.suggestedCategoryIds[_subject] ?? const [];

      if (!mounted) return;
      setState(() {
        _categories = categories;
        _selectedCategory = categories.firstWhere(
          (category) => suggested.contains(category.id),
          orElse: () => categories.first,
        );
        _phase = _ImportPhase.idle;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = ApiException.from(error).message;
        _phase = _ImportPhase.failed;
      });
    }
  }

  Future<void> _fetchQuestions() async {
    SoundService().playButtonSoundNow();
    setState(() {
      _phase = _ImportPhase.fetching;
      _errorMessage = null;
      _result = null;
      _selected.clear();
    });

    try {
      // Loaded alongside the fetch so duplicates can be flagged in the preview
      // instead of being discovered only after publishing.
      final existing = await _repository.existingQuestionKeys();
      final result = await _triviaApi.fetchQuestions(
        amount: _amount,
        categoryId: _selectedCategory?.id,
        difficulty: _difficulty,
      );

      if (!mounted) return;
      setState(() {
        _existingKeys = existing;
        _result = result;
        _selected
          ..clear()
          ..addAll([
            for (var i = 0; i < result.questions.length; i++)
              if (!_isDuplicate(result.questions[i])) i,
          ]);
        _phase = _ImportPhase.ready;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = ApiException.from(error).message;
        _phase = _ImportPhase.failed;
      });
    }
  }

  bool _isDuplicate(TriviaQuestion question) {
    final record = question.toRecord(subject: _subject);
    return _existingKeys.contains(
      SubjectQuestionBank.questionKey(record.toQuizQuestion()),
    );
  }

  // ------------------------------------------------------------- POST calls

  Future<void> _publishSelected() async {
    final result = _result;
    if (result == null || _selected.isEmpty) return;

    SoundService().playButtonSoundNow();
    setState(() {
      _phase = _ImportPhase.publishing;
      _errorMessage = null;
    });

    final records = <QuizQuestionRecord>[
      for (final index in _selected.toList()..sort())
        result.questions[index].toRecord(subject: _subject),
    ];

    try {
      final publish = await _restApi.createQuestions(records);

      // Make the new questions playable immediately.
      await CustomQuestionSync.instance.refreshOnce().catchError((Object _) => 0);

      if (!mounted) return;
      setState(() {
        _lastPublishJson = publish.lastResponseBody;
        _lastPublishUrl = publish.lastRequestUrl;
        _phase = _ImportPhase.ready;
        // Drop the rows that landed so a second tap cannot double-publish.
        _existingKeys = {
          ..._existingKeys,
          for (final record in records)
            SubjectQuestionBank.questionKey(record.toQuizQuestion()),
        };
        _selected.clear();
      });

      if (publish.hasFailures) {
        showAdminSnack(
          context,
          'Saved ${publish.successCount}, but ${publish.failureCount} failed. First error: ${publish.failures.first}',
          isError: true,
        );
      } else {
        showAdminSnack(
          context,
          'Saved ${publish.successCount} question${publish.successCount == 1 ? '' : 's'} to the question bank.',
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = ApiException.from(error).message;
        _phase = _ImportPhase.ready;
      });
      showAdminSnack(context, _errorMessage!, isError: true);
    }
  }

  // ------------------------------------------------------------------- view

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return AdminScaffold(
      title: 'Import Questions',
      subtitle: 'Borrow ready-made questions, then keep the ones you like',
      actions: [
        if (_result != null)
          IconButton(
            tooltip: 'View JSON response',
            icon: const Icon(Icons.data_object_rounded),
            onPressed: _showJsonSheet,
          ),
      ],
      body: SingleChildScrollView(
        padding: EdgeInsets.all(responsiveCardPadding(width) + 4),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: responsivePanelMaxWidth(width)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Unlike the rest of the admin area this screen genuinely
                // cannot work offline — it calls a public API over HTTP, which
                // has no local queue to fall back on.
                const OfflineBanner(
                  blocking: true,
                  message: 'You are offline. Importing needs an internet '
                      'connection because the questions come from opentdb.com. '
                      'You can still write questions by hand while offline.',
                ),
                _aboutPanel(),
                const SizedBox(height: 14),
                _requestPanel(),
                const SizedBox(height: 14),
                _resultsSection(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _aboutPanel() {
    return const AdminPanel(
      color: Color(0xFFFFF6EC),
      borderColor: AdminPalette.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSectionHeader(
            icon: Icons.public_rounded,
            title: 'Where these questions come from',
            caption:
                'Questions are borrowed from the Open Trivia Database, a free '
                'community-run quiz library. Pick a category below, look through '
                'what comes back, and keep only the ones you want.',
          ),
          SizedBox(height: 4),
          SourceLink(
            url: 'https://opentdb.com',
            label: 'Visit opentdb.com',
            description:
                'Browse the full library, see who writes the questions, and '
                'read the terms they are shared under.',
          ),
        ],
      ),
    );
  }

  Widget _requestPanel() {
    final busy = _phase == _ImportPhase.fetching ||
        _phase == _ImportPhase.publishing ||
        _phase == _ImportPhase.loadingCategories;

    return AdminPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AdminSectionHeader(
            icon: Icons.tune_rounded,
            title: 'Build the request',
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<SubjectQuizType>(
            initialValue: _subject,
            decoration: const InputDecoration(
              labelText: 'Save into subject',
              prefixIcon: Icon(Icons.school_rounded),
              helperText: 'Which Lock In subject these questions join',
            ),
            items: [
              for (final subject in SubjectQuizType.values)
                DropdownMenuItem(
                  value: subject,
                  child: Text(
                    subjectQuizTypeLabel(subject),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
            ],
            onChanged: busy
                ? null
                : (value) {
                    if (value != null) setState(() => _subject = value);
                  },
          ),
          const SizedBox(height: 14),
          if (_phase == _ImportPhase.loadingCategories)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AdminPalette.accent,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Loading categories from opentdb.com...',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            )
          else if (_categories.isEmpty)
            OutlinedButton.icon(
              onPressed: _loadCategories,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry loading categories'),
            )
          else
            DropdownButtonFormField<int>(
              initialValue: _selectedCategory?.id,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category_rounded),
              ),
              items: [
                for (final category in _categories)
                  DropdownMenuItem(
                    value: category.id,
                    child: Text(
                      category.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
              onChanged: busy
                  ? null
                  : (value) {
                      setState(() {
                        _selectedCategory =
                            _categories.firstWhere((item) => item.id == value);
                      });
                    },
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _difficulty,
                  decoration: const InputDecoration(
                    labelText: 'Difficulty',
                    prefixIcon: Icon(Icons.speed_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'easy', child: Text('Easy')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'hard', child: Text('Hard')),
                  ],
                  onChanged: busy
                      ? null
                      : (value) {
                          if (value != null) setState(() => _difficulty = value);
                        },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _amount,
                  decoration: const InputDecoration(
                    labelText: 'How many',
                    prefixIcon: Icon(Icons.numbers_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(value: 5, child: Text('5 questions')),
                    DropdownMenuItem(value: 10, child: Text('10 questions')),
                    DropdownMenuItem(value: 20, child: Text('20 questions')),
                    DropdownMenuItem(value: 30, child: Text('30 questions')),
                  ],
                  onChanged: busy
                      ? null
                      : (value) {
                          if (value != null) setState(() => _amount = value);
                        },
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: busy || _categories.isEmpty ? null : _fetchQuestions,
              icon: _phase == _ImportPhase.fetching
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.2,
                      ),
                    )
                  : const Icon(Icons.download_rounded),
              label: Text(
                _phase == _ImportPhase.fetching
                    ? 'Requesting...'
                    : 'Fetch questions (GET)',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Open Trivia DB allows one request every 5 seconds.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AdminPalette.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultsSection() {
    if (_phase == _ImportPhase.fetching) {
      return AdminPanel(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: AdminStateView.loading('Asking Open Trivia DB for $_amount questions...'),
      );
    }

    if (_phase == _ImportPhase.failed) {
      return AdminPanel(
        borderColor: AdminPalette.danger,
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded, size: 44, color: AdminPalette.danger),
            const SizedBox(height: 12),
            const Text(
              'The request did not work',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: AdminPalette.muted,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _categories.isEmpty ? _loadCategories : _fetchQuestions,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ),
          ],
        ),
      );
    }

    final result = _result;
    if (result == null) {
      return const AdminPanel(
        child: Column(
          children: [
            Icon(Icons.inbox_rounded, size: 44, color: AdminPalette.muted),
            SizedBox(height: 10),
            Text(
              'No questions requested yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 6),
            Text(
              'Choose a category and tap "Fetch questions" to see what the API returns.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.35,
                color: AdminPalette.muted,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminSectionHeader(
                icon: Icons.fact_check_rounded,
                title: '${result.questions.length} questions returned',
                caption: 'Tick the ones to keep, then save them to your bank.',
                trailing: TextButton(
                  onPressed: () {
                    setState(() {
                      final selectable = [
                        for (var i = 0; i < result.questions.length; i++)
                          if (!_isDuplicate(result.questions[i])) i,
                      ];
                      if (_selected.length == selectable.length) {
                        _selected.clear();
                      } else {
                        _selected
                          ..clear()
                          ..addAll(selectable);
                      }
                    });
                  },
                  child: const Text(
                    'Toggle all',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < result.questions.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _previewRow(result.questions[i], i),
                ),
              const SizedBox(height: 4),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _selected.isEmpty || _phase == _ImportPhase.publishing
                      ? null
                      : _publishSelected,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminPalette.success,
                  ),
                  icon: _phase == _ImportPhase.publishing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.2,
                          ),
                        )
                      : const Icon(Icons.cloud_upload_rounded),
                  label: Text(
                    _phase == _ImportPhase.publishing
                        ? 'Saving...'
                        : 'Save ${_selected.length} to question bank (POST)',
                    style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          AdminPanel(
            borderColor: AdminPalette.danger,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: AdminPalette.danger, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AdminPalette.danger,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _previewRow(TriviaQuestion question, int index) {
    final duplicate = _isDuplicate(question);
    final selected = _selected.contains(index);

    return Opacity(
      opacity: duplicate ? 0.55 : 1,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF0FFF3) : const Color(0xFFF7F5FC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AdminPalette.success : const Color(0x442B1B4D),
            width: selected ? 2 : 1.4,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: selected,
              activeColor: AdminPalette.success,
              onChanged: duplicate
                  ? null
                  : (value) {
                      setState(() {
                        if (value == true) {
                          _selected.add(index);
                        } else {
                          _selected.remove(index);
                        }
                      });
                    },
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question.question,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      AdminChip(
                        label: question.correctAnswer,
                        color: AdminPalette.success,
                        icon: Icons.check_rounded,
                      ),
                      for (final wrong in question.incorrectAnswers)
                        AdminChip(
                          label: wrong,
                          color: AdminPalette.muted,
                          icon: Icons.close_rounded,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      AdminChip(
                        label: question.difficulty.toUpperCase(),
                        color: AdminPalette.warning,
                      ),
                      AdminChip(
                        label: 'Unlocks Lv ${question.suggestedMinLevel}',
                        color: AdminPalette.teal,
                      ),
                      if (duplicate)
                        const AdminChip(
                          label: 'Already in your bank',
                          color: AdminPalette.danger,
                          icon: Icons.block_rounded,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows the exact JSON that came back, so the response behind the table can
  /// be inspected (and screenshotted) rather than taken on trust.
  void _showJsonSheet() {
    final result = _result;
    if (result == null) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: AdminPalette.panel,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(color: AdminPalette.ink, width: 2.5),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AdminPalette.muted,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 8, 4),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'JSON response',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Copy',
                          icon: const Icon(Icons.copy_rounded),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: result.rawJson));
                            showAdminSnack(context, 'JSON copied to clipboard.');
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                      children: [
                        _jsonBlock(
                          'GET ${result.requestUrl}',
                          result.rawJson,
                        ),
                        if (_lastPublishJson != null) ...[
                          const SizedBox(height: 16),
                          _jsonBlock(
                            'POST ${_lastPublishUrl ?? ''}',
                            _lastPublishJson!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _jsonBlock(String title, String json) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            fontFamily: 'monospace',
            color: AdminPalette.accent,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AdminPalette.codeBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AdminPalette.ink, width: 2),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SelectableText(
              json,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11.5,
                height: 1.5,
                color: AdminPalette.codeFg,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
