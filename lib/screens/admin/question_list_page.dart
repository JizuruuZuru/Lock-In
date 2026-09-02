import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/subject_question_bank.dart';
import '../../models/quiz_question_record.dart';
import '../../services/custom_question_sync.dart';
import '../../services/question_repository.dart';
import '../../services/sound_service.dart';
import '../../utils/admin_theme.dart';
import '../../utils/responsive_layout.dart';
import '../../widgets/offline_banner.dart';
import 'question_editor_page.dart';
import 'trivia_import_page.dart';

/// The **Read** and **Delete** half of question CRUD.
///
/// Lists every stored question live from Firestore with subject and text
/// filters, and hands off to [QuestionEditorPage] for create and update.
class QuestionListPage extends StatefulWidget {
  const QuestionListPage({super.key});

  @override
  State<QuestionListPage> createState() => _QuestionListPageState();
}

class _QuestionListPageState extends State<QuestionListPage> {
  final QuestionRepository _repository = QuestionRepository();
  final TextEditingController _searchController = TextEditingController();

  /// Held in state so a rebuild does not open a second Firestore listener.
  /// The search field calls setState on every keystroke, and building the
  /// stream inline would hand StreamBuilder a new stream each time - dropping
  /// the subscription, resetting to ConnectionState.waiting, and flashing the
  /// whole list back to "Loading questions..." between characters.
  ///
  /// The query takes no filter arguments; subject and text filtering are both
  /// applied client-side below, so this never needs rebuilding on its own.
  late Stream<List<QuizQuestionRecord>> _questionStream =
      _repository.watchQuestions();

  SubjectQuizType? _subjectFilter;
  _SourceFilter _sourceFilter = _SourceFilter.all;
  String _search = '';

  /// Re-filtering means scanning every question in the bank, and the built-in
  /// ones carry whole reading passages - roughly a megabyte of text in total.
  /// Doing that on each keystroke made typing lag, so the search waits until
  /// the admin stops typing. The field itself stays instant either way.
  /// Ids picked for a bulk action. Empty means selection mode is off.
  ///
  /// `QuestionRepository.deleteMany` has existed - and been documented as
  /// "admin multi-select" - since the repository was written, with no caller.
  /// This is that caller. Bundled questions cannot be selected: they live in
  /// the binary, not Firestore, and there is nothing to delete.
  final Set<String> _selected = <String>{};

  bool get _selecting => _selected.isNotEmpty;

  void _toggleSelected(QuizQuestionRecord record) {
    if (record.bundled) return;
    setState(() {
      if (!_selected.remove(record.id)) _selected.add(record.id);
    });
  }

  Future<void> _deleteSelected() async {
    final count = _selected.length;
    if (count == 0) return;

    final confirmed = await confirmAdminAction(
      context,
      title: count == 1 ? 'Delete 1 question?' : 'Delete $count questions?',
      message: 'This cannot be undone. Students will stop getting '
          '${count == 1 ? 'it' : 'them'} straight away.',
      confirmLabel: 'Delete',
      confirmColor: AdminPalette.danger,
    );
    if (!confirmed || !mounted) return;

    try {
      final removed = await _repository.deleteMany(_selected);
      await _refreshPlayableBank();
      if (!mounted) return;
      setState(_selected.clear);
      showAdminSnack(
        context,
        removed == 1 ? '1 question deleted.' : '$removed questions deleted.',
      );
    } catch (error) {
      if (!mounted) return;
      showAdminSnack(context, 'Could not delete: $error', isError: true);
    }
  }

  Timer? _searchDebounce;
  static const Duration _searchDelay = Duration(milliseconds: 220);

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    if (value.isEmpty) {
      // Clearing should feel immediate - there is nothing to wait for.
      setState(() => _search = '');
      return;
    }
    _searchDebounce = Timer(_searchDelay, () {
      if (!mounted) return;
      setState(() => _search = value);
    });
  }

  /// The app's compiled-in questions, wrapped as records so they can be listed
  /// beside the Firestore ones. Built once: the bundled bank cannot change
  /// while the app is running, and there are thousands of them.
  static final List<_Listed> _bundled = [
    for (final subject in SubjectQuizType.values)
      for (final leveled in SubjectQuestionBank.bundledQuestionsFor(subject))
        _Listed(QuizQuestionRecord.fromBundled(subject, leveled)),
  ];

  /// The Firestore half, wrapped the same way. Rebuilt only when the snapshot
  /// itself changes, not on every keystroke.
  List<_Listed>? _storedCache;
  List<QuizQuestionRecord>? _storedCacheSource;

  List<_Listed> _wrapStored(List<QuizQuestionRecord> stored) {
    if (identical(_storedCacheSource, stored)) return _storedCache!;
    _storedCacheSource = stored;
    _storedCache = stored.map(_Listed.new).toList(growable: false);
    return _storedCache!;
  }

  /// Reattaches the listener after an error. The retry button used to rely on
  /// the stream being rebuilt by setState, which no longer happens.
  void _reloadQuestions() {
    setState(() {
      _questionStream = _repository.watchQuestions();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- actions

  Future<void> _createQuestion() async {
    SoundService().playButtonSoundNow();
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => QuestionEditorPage(initialSubject: _subjectFilter),
      ),
    );
    if (saved == true) await _refreshPlayableBank();
  }

  Future<void> _editQuestion(QuizQuestionRecord record) async {
    SoundService().playButtonSoundNow();
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => QuestionEditorPage(existing: record)),
    );
    if (saved == true) await _refreshPlayableBank();
  }

  Future<void> _deleteQuestion(QuizQuestionRecord record) async {
    final confirmed = await confirmAdminAction(
      context,
      title: 'Delete this question?',
      message:
          '"${_truncate(record.prompt, 90)}"\n\nThis permanently removes it from the question bank. Students will stop seeing it right away.',
    );
    if (!confirmed) return;

    try {
      final syncState = await _repository.delete(record.id);
      await _refreshPlayableBank();
      if (!mounted) return;
      showAdminSnack(
        context,
        syncState == WriteSyncState.queuedOffline
            ? 'Deleted on this device. The deletion will sync when you are back online.'
            : 'Question deleted.',
      );
    } catch (error) {
      if (!mounted) return;
      showAdminSnack(context, 'Could not delete: $error', isError: true);
    }
  }

  Future<void> _togglePublished(QuizQuestionRecord record) async {
    // Hiding pulls a question out of every student's pool immediately, so it
    // is confirmed like the other destructive actions. Publishing is additive
    // and goes through without a prompt.
    if (record.published) {
      final confirmed = await confirmAdminAction(
        context,
        title: 'Hide this question?',
        message:
            'Students will stop getting it straight away. You can publish it '
            'again at any time.',
        confirmLabel: 'Hide',
        confirmColor: AdminPalette.danger,
      );
      if (!confirmed || !mounted) return;
    }

    try {
      final syncState =
          await _repository.setPublished(record.id, !record.published);
      await _refreshPlayableBank();
      if (!mounted) return;

      final pending = syncState == WriteSyncState.queuedOffline;
      showAdminSnack(
        context,
        record.published
            ? 'Hidden from students.${pending ? ' Will sync when you reconnect.' : ''}'
            : pending
                ? 'Published on this device. It will sync when you reconnect.'
                : 'Published - students can get this question now.',
      );
    } catch (error) {
      if (!mounted) return;
      showAdminSnack(context, 'Could not update: $error', isError: true);
    }
  }

  /// Pushes the change into the in-memory pool the games read from, so the
  /// edit is playable without an app restart.
  Future<void> _refreshPlayableBank() async {
    try {
      await CustomQuestionSync.instance.refreshOnce();
    } catch (_) {
      // The live listener will catch up; nothing to tell the admin here.
    }
  }

  // ------------------------------------------------------------------- view

  /// How many questions exist in total for the current source filter, before
  /// the search and subject filters narrow them.
  int _totalFor(List<QuizQuestionRecord> stored) {
    return switch (_sourceFilter) {
      _SourceFilter.all => stored.length + _bundled.length,
      _SourceFilter.teacher => stored.length,
      _SourceFilter.builtIn => _bundled.length,
    };
  }

  /// Teacher-written questions first, then the built-in bank - the editable
  /// ones are what an admin came here to manage.
  ///
  /// Filtering runs straight over the two source lists instead of merging them
  /// into one first. With ~5,800 built-in questions, that merge allocated a
  /// whole new list on every keystroke, and re-lowercased three fields of every
  /// record while it was at it.
  List<QuizQuestionRecord> _visibleQuestions(List<QuizQuestionRecord> stored) {
    final needle = _search.trim().toLowerCase();
    final visible = <QuizQuestionRecord>[];

    void collect(List<_Listed> source) {
      for (final item in source) {
        if (_subjectFilter != null && item.record.subject != _subjectFilter) {
          continue;
        }
        if (needle.isEmpty || item.haystack.contains(needle)) {
          visible.add(item.record);
        }
      }
    }

    if (_sourceFilter != _SourceFilter.builtIn) collect(_wrapStored(stored));
    if (_sourceFilter != _SourceFilter.teacher) collect(_bundled);
    return visible;
  }

  /// Built-in questions ship inside the app, so there is no document to edit,
  /// hide, or delete. Say so rather than silently doing nothing.
  void _explainBundled() {
    showAdminSnack(
      context,
      'This question is built into the app, so it cannot be edited or '
      'deleted. Write a new question to add your own.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return AdminScaffold(
      title: _selecting ? '${_selected.length} selected' : 'Questions',
      subtitle: _selecting
          ? 'Tap a number to add or remove'
          : 'Create, edit, and delete quiz questions',
      actions: [
        if (_selecting) ...[
          IconButton(
            tooltip: 'Delete selected',
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: _deleteSelected,
          ),
          IconButton(
            tooltip: 'Cancel selection',
            icon: const Icon(Icons.close_rounded),
            onPressed: () => setState(_selected.clear),
          ),
        ],
        IconButton(
          tooltip: 'Import from Open Trivia DB',
          icon: const Icon(Icons.cloud_download_rounded),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TriviaImportPage()),
            );
            await _refreshPlayableBank();
          },
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createQuestion,
        backgroundColor: AdminPalette.accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AdminPalette.ink, width: 2),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New question',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              responsiveCardPadding(width),
              responsiveCardPadding(width),
              responsiveCardPadding(width),
              8,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(maxWidth: responsivePanelMaxWidth(width)),
                child: Column(
                  children: [
                    const OfflineBanner(),
                    _filterBar(),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<QuizQuestionRecord>>(
              stream: _questionStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return AdminStateView.error(
                    'Could not load questions.\n\n${snapshot.error}',
                    onRetry: _reloadQuestions,
                  );
                }
                if (!snapshot.hasData) {
                  return AdminStateView.loading('Loading questions...');
                }

                final total = _totalFor(snapshot.data!);
                if (total == 0) {
                  return AdminStateView(
                    icon: Icons.quiz_outlined,
                    title: 'No questions yet',
                    message: _sourceFilter == _SourceFilter.teacher
                        ? 'You have not written any questions yet. The app still '
                            'ships with a built-in bank - switch to "All" to see it.'
                        : 'Tap "New question" to write one, or import a batch from Open Trivia DB.',
                    actionLabel: 'Write the first question',
                    onAction: _createQuestion,
                  );
                }

                final visible = _visibleQuestions(snapshot.data!);
                if (visible.isEmpty) {
                  return AdminStateView(
                    icon: Icons.search_off_rounded,
                    title: 'No matches',
                    message:
                        'No question matches your filters. Clear them to see all $total.',
                    actionLabel: 'Clear filters',
                    onAction: () {
                      _searchController.clear();
                      _searchDebounce?.cancel();
                      setState(() {
                        _search = '';
                        _subjectFilter = null;
                        _sourceFilter = _SourceFilter.all;
                      });
                    },
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    responsiveCardPadding(width),
                    4,
                    responsiveCardPadding(width),
                    100,
                  ),
                  itemCount: visible.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: responsivePanelMaxWidth(width),
                        ),
                        child: _QuestionCard(
                          record: visible[index],
                          index: index + 1,
                          selecting: _selecting,
                          selected: _selected.contains(visible[index].id),
                          onToggleSelected: () =>
                              _toggleSelected(visible[index]),
                          onEdit: visible[index].bundled
                              ? _explainBundled
                              : () => _editQuestion(visible[index]),
                          onDelete: visible[index].bundled
                              ? _explainBundled
                              : () => _deleteQuestion(visible[index]),
                          onTogglePublished: visible[index].bundled
                              ? _explainBundled
                              : () => _togglePublished(visible[index]),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterBar() {
    return AdminPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              isDense: true,
              labelText: 'Search questions',
              hintText: 'Search by question, topic, or answer',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _search.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                'Subject:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _subjectFilterChip(null, 'All'),
                      for (final subject in SubjectQuizType.values)
                        _subjectFilterChip(subject, subjectQuizTypeLabel(subject)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                'Source:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final source in _SourceFilter.values)
                        _sourceFilterChip(source),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sourceFilterChip(_SourceFilter source) {
    final selected = _sourceFilter == source;
    final label = switch (source) {
      _SourceFilter.all => 'All (${_bundled.length}+ built in)',
      _SourceFilter.teacher => 'Teacher-made',
      _SourceFilter.builtIn => 'Built in (${_bundled.length})',
    };
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _sourceFilter = source),
      ),
    );
  }

  Widget _subjectFilterChip(SubjectQuizType? subject, String label) {
    final selected = _subjectFilter == subject;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _subjectFilter = subject),
        showCheckmark: false,
        labelStyle: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          color: selected ? Colors.white : AdminPalette.ink,
        ),
        backgroundColor: AdminPalette.panel,
        selectedColor: AdminPalette.accent,
        side: const BorderSide(color: AdminPalette.ink, width: 1.8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }
}

String _truncate(String value, int max) {
  if (value.length <= max) return value;
  return '${value.substring(0, max)}...';
}

/// One row in the question list: the prompt, its answers, and the row actions.
/// Which half of the bank the list is showing.
enum _SourceFilter { all, teacher, builtIn }

/// A record plus the lowercase text the search box matches against.
///
/// Worked out once when the list is built rather than on every keystroke -
/// with the built-in bank listed, that was three `toLowerCase()` allocations
/// per record per character typed.
class _Listed {
  final QuizQuestionRecord record;
  final String haystack;

  _Listed(this.record)
      : haystack = '${record.prompt}\u0000${record.topic}'
                '\u0000${record.correctAnswer}'
            .toLowerCase();
}

class _QuestionCard extends StatelessWidget {
  final QuizQuestionRecord record;
  final int index;
  final bool selecting;
  final bool selected;
  final VoidCallback onToggleSelected;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTogglePublished;

  const _QuestionCard({
    required this.record,
    required this.index,
    required this.selecting,
    required this.selected,
    required this.onToggleSelected,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePublished,
  });

  @override
  Widget build(BuildContext context) {
    return AdminPanel(
      padding: const EdgeInsets.all(16),
      borderColor: record.published ? AdminPalette.ink : AdminPalette.muted,
      color: record.published ? AdminPalette.panel : AdminPalette.surfaceMuted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The row number doubles as the multi-select handle. Long-press
              // any editable card to start selecting; after that a single tap
              // here toggles. Bundled questions cannot be selected.
              Semantics(
                label: record.bundled
                    ? 'Question $index, built in'
                    : (selected
                        ? 'Question $index, selected'
                        : 'Question $index'),
                button: !record.bundled,
                child: InkWell(
                  onTap: record.bundled ? null : onToggleSelected,
                  onLongPress: record.bundled ? null : onToggleSelected,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? AdminPalette.accent
                          : AdminPalette.accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: AdminPalette.accent, width: 1.6),
                    ),
                    child: selected
                        ? const Icon(Icons.check_rounded,
                            size: 18, color: Colors.white)
                        : Text(
                            '$index',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              color: AdminPalette.accent,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  record.prompt,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              AdminChip(
                label: subjectQuizTypeLabel(record.subject),
                icon: record.subject == SubjectQuizType.science
                    ? Icons.science_rounded
                    : Icons.menu_book_rounded,
              ),
              AdminChip(
                label: record.topic,
                color: AdminPalette.teal,
                icon: Icons.label_rounded,
              ),
              AdminChip(
                label: 'Level ${record.minLevel}+',
                color: AdminPalette.warning,
                icon: Icons.trending_up_rounded,
              ),
              if (record.source == QuestionSource.openTrivia)
                const AdminChip(
                  label: 'Open Trivia DB',
                  color: AdminPalette.secondary,
                  icon: Icons.cloud_rounded,
                ),
              if (record.bundled)
                const AdminChip(
                  label: 'Built in',
                  color: Color(0xFF455A64),
                  icon: Icons.inventory_2_rounded,
                )
              else
                AdminChip(
                  label: record.published ? 'Live' : 'Hidden',
                  color:
                      record.published ? AdminPalette.success : AdminPalette.muted,
                  icon: record.published
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                ),
            ],
          ),
          const SizedBox(height: 12),
          _answerRow(
            icon: Icons.check_circle_rounded,
            color: AdminPalette.success,
            label: 'Correct',
            value: record.correctAnswer,
          ),
          const SizedBox(height: 6),
          _answerRow(
            icon: Icons.cancel_rounded,
            color: AdminPalette.danger,
            label: 'Wrong',
            value: record.choices.join('   -   '),
          ),
          const Divider(height: 22),
          Row(
            children: [
              Expanded(
                child: Text(
                  record.instruction,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                    color: AdminPalette.muted,
                  ),
                ),
              ),
              // A built-in question has no document behind it, so its actions
              // are shown greyed out and explain themselves when tapped rather
              // than disappearing - the row would otherwise look broken.
              IconButton(
                tooltip: record.bundled
                    ? 'Built-in questions are always available'
                    : (record.published ? 'Hide from students' : 'Publish'),
                onPressed: onTogglePublished,
                icon: Icon(
                  record.published
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: AdminPalette.muted,
                ),
              ),
              IconButton(
                tooltip: record.bundled ? 'Built-in - cannot be edited' : 'Edit',
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_rounded,
                  color: AdminPalette.accent,
                ),
              ),
              IconButton(
                tooltip:
                    record.bundled ? 'Built-in - cannot be deleted' : 'Delete',
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_rounded,
                  color: AdminPalette.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _answerRow({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        SizedBox(
          width: 58,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '-' : value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
