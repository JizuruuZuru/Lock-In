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

  SubjectQuizType? _subjectFilter;
  String _search = '';

  @override
  void dispose() {
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

  List<QuizQuestionRecord> _applyFilters(List<QuizQuestionRecord> records) {
    final needle = _search.trim().toLowerCase();
    return records.where((record) {
      if (_subjectFilter != null && record.subject != _subjectFilter) return false;
      if (needle.isEmpty) return true;
      return record.prompt.toLowerCase().contains(needle) ||
          record.topic.toLowerCase().contains(needle) ||
          record.correctAnswer.toLowerCase().contains(needle);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return AdminScaffold(
      title: 'Questions',
      subtitle: 'Create, edit, and delete quiz questions',
      actions: [
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
              stream: _repository.watchQuestions(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return AdminStateView.error(
                    'Could not load questions.\n\n${snapshot.error}',
                    onRetry: () => setState(() {}),
                  );
                }
                if (!snapshot.hasData) {
                  return AdminStateView.loading('Loading questions...');
                }

                final all = snapshot.data!;
                if (all.isEmpty) {
                  return AdminStateView(
                    icon: Icons.quiz_outlined,
                    title: 'No questions yet',
                    message:
                        'Tap "New question" to write one, or import a batch from Open Trivia DB.',
                    actionLabel: 'Write the first question',
                    onAction: _createQuestion,
                  );
                }

                final visible = _applyFilters(all);
                if (visible.isEmpty) {
                  return AdminStateView(
                    icon: Icons.search_off_rounded,
                    title: 'No matches',
                    message:
                        'No question matches your filters. Clear them to see all ${all.length}.',
                    actionLabel: 'Clear filters',
                    onAction: () {
                      _searchController.clear();
                      setState(() {
                        _search = '';
                        _subjectFilter = null;
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
                          onEdit: () => _editQuestion(visible[index]),
                          onDelete: () => _deleteQuestion(visible[index]),
                          onTogglePublished: () => _togglePublished(visible[index]),
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
            onChanged: (value) => setState(() => _search = value),
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
                        setState(() => _search = '');
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
        ],
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
class _QuestionCard extends StatelessWidget {
  final QuizQuestionRecord record;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTogglePublished;

  const _QuestionCard({
    required this.record,
    required this.index,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePublished,
  });

  @override
  Widget build(BuildContext context) {
    return AdminPanel(
      padding: const EdgeInsets.all(16),
      borderColor: record.published ? AdminPalette.ink : AdminPalette.muted,
      color: record.published ? AdminPalette.panel : const Color(0xFFF2F0F7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AdminPalette.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AdminPalette.accent, width: 1.6),
                ),
                child: Text(
                  '$index',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: AdminPalette.accent,
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
                color: const Color(0xFF00796B),
                icon: Icons.label_rounded,
              ),
              AdminChip(
                label: 'Level ${record.minLevel}+',
                color: const Color(0xFFEF6C00),
                icon: Icons.trending_up_rounded,
              ),
              if (record.source == QuestionSource.openTrivia)
                const AdminChip(
                  label: 'Open Trivia DB',
                  color: Color(0xFF5E35B1),
                  icon: Icons.cloud_rounded,
                ),
              AdminChip(
                label: record.published ? 'Live' : 'Hidden',
                color: record.published ? AdminPalette.success : AdminPalette.muted,
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
              IconButton(
                tooltip: record.published ? 'Hide from students' : 'Publish',
                onPressed: onTogglePublished,
                icon: Icon(
                  record.published
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: AdminPalette.muted,
                ),
              ),
              IconButton(
                tooltip: 'Edit',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded, color: AdminPalette.accent),
              ),
              IconButton(
                tooltip: 'Delete',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_rounded, color: AdminPalette.danger),
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
