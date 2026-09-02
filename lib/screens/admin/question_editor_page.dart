import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../data/subject_question_bank.dart';
import '../../models/quiz_question_record.dart';
import '../../services/custom_question_sync.dart';
import '../../services/question_repository.dart';
import '../../services/sound_service.dart';
import '../../utils/admin_theme.dart';
import '../../utils/responsive_layout.dart';
import '../../widgets/offline_banner.dart';

/// The **Create** and **Update** half of question CRUD.
///
/// One form serves both: passing [existing] switches it to edit mode. Every
/// field is validated through [QuizQuestionRecord.validate] before a write is
/// attempted, and the same errors are painted next to the offending field.
///
/// A live preview shows the question exactly as a student will meet it, with
/// the correct answer mixed into the choices the way the game shuffles them.
class QuestionEditorPage extends StatefulWidget {
  /// Null when creating a new question.
  final QuizQuestionRecord? existing;

  /// Pre-selects the subject when opened from a filtered list.
  final SubjectQuizType? initialSubject;

  const QuestionEditorPage({super.key, this.existing, this.initialSubject});

  @override
  State<QuestionEditorPage> createState() => _QuestionEditorPageState();
}

class _QuestionEditorPageState extends State<QuestionEditorPage> {
  final QuestionRepository _repository = QuestionRepository();

  late final TextEditingController _topicController;
  late final TextEditingController _instructionController;
  late final TextEditingController _promptController;
  late final TextEditingController _correctController;
  late final List<TextEditingController> _wrongControllers;
  final FocusNode _topicFocus = FocusNode();

  late SubjectQuizType _subject;
  late int _minLevel;
  late bool _published;

  /// Populated after a failed save; drives the red text under each field.
  Map<String, String> _errors = const {};
  bool _saving = false;

  /// Form contents as of the last save, or of first open.
  late List<Object?> _savedSignature;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;

    _subject = existing?.subject ?? widget.initialSubject ?? SubjectQuizType.english;
    _minLevel = existing?.minLevel ?? 1;
    _published = existing?.published ?? true;

    _topicController = TextEditingController(text: existing?.topic ?? '');
    _instructionController = TextEditingController(
      text: existing?.instruction ?? 'Choose the correct answer.',
    );
    _promptController = TextEditingController(text: existing?.prompt ?? '');
    _correctController = TextEditingController(text: existing?.correctAnswer ?? '');

    final wrongAnswers = existing?.choices ?? const <String>[];
    _wrongControllers = [
      for (var i = 0; i < max(wrongAnswers.length, 3); i++)
        TextEditingController(
          text: i < wrongAnswers.length ? wrongAnswers[i] : '',
        ),
    ];

    SoundService().playPageBgm(BgmPage.home);
    _savedSignature = _signature();
  }

  /// Everything the form owns, flattened, so an edit can be detected without
  /// tracking each field. Compared against [_savedSignature] on the way out.
  List<Object?> _signature() => [
        _subject.name,
        _minLevel,
        _published,
        _topicController.text.trim(),
        _instructionController.text.trim(),
        _promptController.text.trim(),
        _correctController.text.trim(),
        ..._wrongControllers.map((c) => c.text.trim()),
      ];

  bool get _hasUnsavedChanges => !listEquals(_signature(), _savedSignature);

  /// Asks before discarding an edit. The back arrow and the Android back
  /// gesture used to throw away a half-written question with no prompt at all.
  Future<void> _handlePop() async {
    if (!_hasUnsavedChanges) {
      Navigator.pop(context);
      return;
    }

    final discard = await confirmAdminAction(
      context,
      title: 'Discard your changes?',
      message: _isEditing
          ? 'This question has edits that have not been saved yet.'
          : 'This question has not been saved yet.',
      confirmLabel: 'Discard',
      confirmColor: AdminPalette.danger,
    );
    if (!discard || !mounted) return;
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _topicController.dispose();
    _instructionController.dispose();
    _promptController.dispose();
    _correctController.dispose();
    _topicFocus.dispose();
    for (final controller in _wrongControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // ------------------------------------------------------------------ state

  /// Builds the record the form currently describes.
  QuizQuestionRecord _buildRecord() {
    return QuizQuestionRecord(
      id: widget.existing?.id ?? '',
      subject: _subject,
      topic: _topicController.text,
      instruction: _instructionController.text,
      prompt: _promptController.text,
      correctAnswer: _correctController.text,
      choices: _wrongControllers
          .map((controller) => controller.text.trim())
          .where((text) => text.isNotEmpty)
          .toList(growable: false),
      minLevel: _minLevel,
      source: widget.existing?.source ?? QuestionSource.manual,
      published: _published,
    ).sanitized();
  }

  /// Re-runs validation only once the admin has already hit save, so the form
  /// does not shout at them while they are still typing the first field.
  void _revalidateIfNeeded() {
    if (_errors.isEmpty) return;
    setState(() => _errors = _buildRecord().validate());
  }

  void _addWrongAnswer() {
    if (_wrongControllers.length >= QuizQuestionRecord.maxWrongChoices) return;
    setState(() => _wrongControllers.add(TextEditingController()));
  }

  void _removeWrongAnswer(int index) {
    if (_wrongControllers.length <= QuizQuestionRecord.minWrongChoices) return;
    // `_revalidateIfNeeded` calls setState itself, so calling it from inside a
    // setState callback was a nested setState - a double markNeedsBuild with
    // unclear intent. One rebuild does both jobs.
    _wrongControllers.removeAt(index).dispose();
    setState(() {
      if (_errors.isNotEmpty) _errors = _buildRecord().validate();
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final record = _buildRecord();
    final errors = record.validate();

    if (errors.isNotEmpty) {
      setState(() => _errors = errors);
      showAdminSnack(context, 'Please fix the highlighted fields.', isError: true);
      return;
    }

    setState(() {
      _errors = const {};
      _saving = true;
    });

    try {
      final result = _isEditing
          ? await _repository.update(record)
          : await _repository.create(record);

      // The question is already in the local bank either way; the message just
      // has to be honest about whether the server has it yet.
      await CustomQuestionSync.instance.refreshOnce().catchError((Object _) => 0);

      if (!mounted) return;
      showAdminSnack(
        context,
        result.isPendingSync
            ? (_isEditing
                ? 'Saved on this device. The update will sync when you are back online.'
                : 'Saved on this device. It will sync when you are back online.')
            : (_isEditing ? 'Question updated.' : 'Question created and published.'),
      );
      Navigator.pop(context, true);
    } on QuestionValidationException catch (error) {
      if (!mounted) return;
      setState(() => _errors = error.errors);
      showAdminSnack(context, error.summary, isError: true);
    } catch (error) {
      if (!mounted) return;
      showAdminSnack(context, 'Could not save: $error', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ------------------------------------------------------------------- view

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        _handlePop();
      },
      child: _buildEditor(context, width),
    );
  }

  Widget _buildEditor(BuildContext context, double width) {
    return AdminScaffold(
      title: _isEditing ? 'Edit Question' : 'New Question',
      subtitle: _isEditing ? 'Update and save' : 'Add a question to the bank',
      body: SingleChildScrollView(
        padding: EdgeInsets.all(responsiveCardPadding(width) + 4),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const OfflineBanner(
                  message: 'You are offline. This question will be saved on '
                      'this device, played straight away, and uploaded when you '
                      'reconnect.',
                ),
                _subjectAndTopicPanel(),
                const SizedBox(height: 14),
                _questionPanel(),
                const SizedBox(height: 14),
                _answersPanel(),
                const SizedBox(height: 14),
                _settingsPanel(),
                const SizedBox(height: 14),
                _previewPanel(),
                const SizedBox(height: 20),
                _saveButton(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _subjectAndTopicPanel() {
    final topics = SubjectQuestionBank.topicsFor(_subject);

    return AdminPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AdminSectionHeader(
            icon: Icons.category_rounded,
            title: 'Subject and topic',
            caption:
                'Pick the same topic an existing lesson uses and this question joins that lesson.',
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<SubjectQuizType>(
            initialValue: _subject,
            decoration: const InputDecoration(
              labelText: 'Subject',
              prefixIcon: Icon(Icons.school_rounded),
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
            onChanged: (value) {
              if (value == null) return;
              setState(() => _subject = value);
              _revalidateIfNeeded();
            },
          ),
          const SizedBox(height: 14),
          // A read-only field that opens a centred picker. The old inline
          // dropdown floated over the cards below it and showed at most 12 of
          // the topics, with no way to reach the rest.
          TextField(
            controller: _topicController,
            focusNode: _topicFocus,
            readOnly: true,
            onTap: _openTopicPicker,
            decoration: InputDecoration(
              labelText: 'Topic',
              hintText: 'Tap to choose a topic',
              prefixIcon: const Icon(Icons.label_rounded),
              suffixIcon: IconButton(
                icon: const Icon(Icons.unfold_more_rounded),
                tooltip: 'Browse topics',
                onPressed: _openTopicPicker,
              ),
              helperText: topics.isEmpty
                  ? 'Tap to name the first topic for this subject'
                  : 'Tap to browse all ${topics.length} topics, or add a new one',
              errorText: _errors['topic'],
            ),
          ),
        ],
      ),
    );
  }

  /// Opens the topic picker over the middle of the screen.
  ///
  /// Every topic already in use for this subject is listed and searchable, and
  /// a topic that does not exist yet can be added from the same sheet - filing
  /// a question under an existing topic is what makes it join that lesson, so
  /// seeing the real list matters more than free typing.
  Future<void> _openTopicPicker() async {
    final picked = await showDialog<String>(
      context: context,
      builder: (_) => _TopicPickerDialog(
        topics: SubjectQuestionBank.topicsFor(_subject),
        subjectLabel: subjectQuizTypeLabel(_subject),
        initialTopic: _topicController.text.trim(),
      ),
    );
    if (picked == null || !mounted) return;
    _topicController.text = picked;
    _revalidateIfNeeded();
  }

  Widget _questionPanel() {
    return AdminPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AdminSectionHeader(
            icon: Icons.help_center_rounded,
            title: 'The question',
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _instructionController,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            // Was unbounded: a 5,000-character instruction saved fine and then
            // overflowed the question screen.
            maxLength: 200,
            onChanged: (_) => _revalidateIfNeeded(),
            decoration: InputDecoration(
              labelText: 'Instruction',
              hintText: 'Choose the noun in the sentence.',
              prefixIcon: const Icon(Icons.info_rounded),
              helperText: 'Shown above the question to tell the student what to do',
              errorText: _errors['instruction'],
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _promptController,
            maxLines: 4,
            minLines: 2,
            maxLength: QuizQuestionRecord.maxPromptLength,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => _revalidateIfNeeded(),
            decoration: InputDecoration(
              labelText: 'Question',
              hintText: 'The bright sun warmed the park.',
              alignLabelWithHint: true,
              errorText: _errors['prompt'],
            ),
          ),
        ],
      ),
    );
  }

  Widget _answersPanel() {
    final canAdd = _wrongControllers.length < QuizQuestionRecord.maxWrongChoices;
    final canRemove = _wrongControllers.length > QuizQuestionRecord.minWrongChoices;

    return AdminPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AdminSectionHeader(
            icon: Icons.checklist_rounded,
            title: 'Answers',
            caption:
                'One correct answer plus the wrong choices. The game shuffles them for every student.',
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _correctController,
            textInputAction: TextInputAction.next,
            onChanged: (_) => _revalidateIfNeeded(),
            decoration: InputDecoration(
              labelText: 'Correct answer',
              prefixIcon: const Icon(
                Icons.check_circle_rounded,
                color: AdminPalette.success,
              ),
              errorText: _errors['correctAnswer'],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Wrong choices',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ),
              TextButton.icon(
                onPressed: canAdd ? _addWrongAnswer : null,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(
                  canAdd
                      ? 'Add choice'
                      : 'Max ${QuizQuestionRecord.maxWrongChoices}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (var i = 0; i < _wrongControllers.length; i++)
            Padding(
              // Keyed on the controller, not the index. Without a key, removing
              // choice 2 made Flutter reuse element 2 with choice 3's
              // controller, so focus and the caret jumped to the wrong row.
              key: ObjectKey(_wrongControllers[i]),
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _wrongControllers[i],
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => _revalidateIfNeeded(),
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: 'Wrong choice ${i + 1}',
                        prefixIcon: const Icon(
                          Icons.cancel_rounded,
                          color: AdminPalette.danger,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: canRemove
                        ? 'Remove this choice'
                        : 'At least ${QuizQuestionRecord.minWrongChoices} wrong choices are needed',
                    onPressed: canRemove ? () => _removeWrongAnswer(i) : null,
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                  ),
                ],
              ),
            ),
          if (_errors['choices'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 4),
              child: Text(
                _errors['choices']!,
                style: const TextStyle(
                  color: AdminPalette.danger,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _settingsPanel() {
    return AdminPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AdminSectionHeader(
            icon: Icons.tune_rounded,
            title: 'When students see it',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.trending_up_rounded, color: AdminPalette.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _minLevel == 1
                      ? 'Available from the very first level'
                      : 'Unlocks once the student reaches level $_minLevel',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AdminPalette.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AdminPalette.accent, width: 1.8),
                ),
                child: Text(
                  'Lv $_minLevel',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AdminPalette.accent,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: _minLevel.toDouble(),
            min: 1,
            max: QuizQuestionRecord.maxLevel.toDouble(),
            divisions: QuizQuestionRecord.maxLevel - 1,
            label: 'Level $_minLevel',
            activeColor: AdminPalette.accent,
            onChanged: (value) => setState(() => _minLevel = value.round()),
          ),
          if (_errors['minLevel'] != null)
            Text(
              _errors['minLevel']!,
              style: const TextStyle(
                color: AdminPalette.danger,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          const Divider(height: 24),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _published,
            activeThumbColor: AdminPalette.success,
            onChanged: (value) => setState(() => _published = value),
            title: const Text(
              'Live for students',
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              _published
                  ? 'Students can be asked this question right away.'
                  : 'Saved as a draft - nobody will be asked it yet.',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AdminPalette.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Renders the question the way the game will, using the same shuffle the
  /// engine uses, so the admin can sanity-check it before saving.
  Widget _previewPanel() {
    final record = _buildRecord();
    final config = SubjectQuestionBank.configFor(_subject);
    final preview = record.toQuizQuestion().shuffled(Random(7));

    return AdminPanel(
      color: config.bgTopColor,
      borderColor: config.accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminSectionHeader(
            icon: Icons.visibility_rounded,
            title: 'Student preview',
            caption: 'How this looks inside a ${config.title} lesson',
          ),
          const SizedBox(height: 14),
          Text(
            record.instruction.isEmpty ? 'Choose the correct answer.' : record.instruction,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: config.accentColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            record.prompt.isEmpty ? 'Your question will appear here.' : record.prompt,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1.3,
              color: record.prompt.isEmpty ? AdminPalette.muted : config.inkColor,
            ),
          ),
          const SizedBox(height: 14),
          if (preview.choices.isEmpty)
            const Text(
              'Add a correct answer and some wrong choices to see the buttons.',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AdminPalette.muted,
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final choice in preview.choices)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    decoration: BoxDecoration(
                      color: config.panelColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: config.inkColor, width: 2),
                      boxShadow: AdminPalette.softShadow,
                    ),
                    child: Text(
                      choice,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: config.inkColor,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _saveButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _saving
            ? null
            : () {
                SoundService().playButtonSoundNow();
                _save();
              },
        icon: _saving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
              )
            : Icon(_isEditing ? Icons.save_rounded : Icons.add_circle_rounded),
        label: Text(
          _saving
              ? 'Saving...'
              : (_isEditing ? 'Save changes' : 'Create question'),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

/// The centred topic picker. Split out as its own stateful widget so the
/// search box can filter without rebuilding the whole editor behind it.
class _TopicPickerDialog extends StatefulWidget {
  final List<String> topics;
  final String subjectLabel;
  final String initialTopic;

  const _TopicPickerDialog({
    required this.topics,
    required this.subjectLabel,
    required this.initialTopic,
  });

  @override
  State<_TopicPickerDialog> createState() => _TopicPickerDialogState();
}

class _TopicPickerDialogState extends State<_TopicPickerDialog> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String get _query => _search.text.trim();

  List<String> get _visible {
    final needle = _query.toLowerCase();
    if (needle.isEmpty) return widget.topics;
    return widget.topics
        .where((topic) => topic.toLowerCase().contains(needle))
        .toList(growable: false);
  }

  /// True when what was typed is not already a topic, so it can be added.
  bool get _canCreate {
    if (_query.isEmpty) return false;
    final needle = _query.toLowerCase();
    return !widget.topics.any((topic) => topic.toLowerCase() == needle);
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      backgroundColor: AdminPalette.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AdminPalette.ink, width: 2),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.label_rounded, color: AdminPalette.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Choose a topic',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '${widget.topics.length} in use for '
                          '${widget.subjectLabel}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AdminPalette.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _search,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search topics, or type a new one',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          tooltip: 'Clear',
                          onPressed: () {
                            _search.clear();
                            setState(() {});
                          },
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: visible.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            widget.topics.isEmpty
                                ? 'No topics yet for ${widget.subjectLabel}.\n'
                                    'Type one above to create the first.'
                                : 'No topic matches "$_query".',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AdminPalette.muted,
                            ),
                          ),
                        ),
                      )
                    : Scrollbar(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: visible.length,
                          itemBuilder: (context, index) {
                            final topic = visible[index];
                            final selected = topic == widget.initialTopic;
                            return ListTile(
                              dense: true,
                              selected: selected,
                              selectedTileColor:
                                  AdminPalette.accent.withValues(alpha: 0.10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              leading: Icon(
                                selected
                                    ? Icons.check_circle_rounded
                                    : Icons.circle_outlined,
                                size: 20,
                                color: selected
                                    ? AdminPalette.accent
                                    : AdminPalette.muted,
                              ),
                              title: Text(
                                topic,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              onTap: () => Navigator.of(context).pop(topic),
                            );
                          },
                        ),
                      ),
              ),
              if (_canCreate) ...[
                const Divider(height: 20),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(_query),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(
                    'Add new topic "$_query"',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
