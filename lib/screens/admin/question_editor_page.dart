import 'dart:math';

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
    setState(() {
      _wrongControllers.removeAt(index).dispose();
      _revalidateIfNeeded();
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
          // RawAutocomplete (rather than Autocomplete) so the field can share
          // _topicController instead of owning a second controller that would
          // have to be mirrored back on every keystroke.
          RawAutocomplete<String>(
            textEditingController: _topicController,
            focusNode: _topicFocus,
            optionsBuilder: (value) {
              final needle = value.text.trim().toLowerCase();
              if (needle.isEmpty) return topics.take(12);
              return topics
                  .where((topic) => topic.toLowerCase().contains(needle))
                  .take(12);
            },
            onSelected: (_) => _revalidateIfNeeded(),
            fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: (_) => _revalidateIfNeeded(),
                onSubmitted: (_) => onSubmitted(),
                decoration: InputDecoration(
                  labelText: 'Topic',
                  hintText: 'e.g. Nouns, Plants, Weather',
                  prefixIcon: const Icon(Icons.label_rounded),
                  helperText: 'Start typing to see topics already in use',
                  errorText: _errors['topic'],
                ),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 0,
                  color: AdminPalette.panel,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: AdminPalette.ink, width: 2),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 240, maxWidth: 420),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      children: [
                        for (final option in options)
                          ListTile(
                            dense: true,
                            title: Text(
                              option,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                            onTap: () => onSelected(option),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
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
            maxLength: 600,
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
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _wrongControllers[i],
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
