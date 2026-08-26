import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/subject_question_bank.dart';

/// Where a stored question originally came from. Imported questions keep the
/// tag so an admin can tell their own authoring apart from an API pull.
enum QuestionSource { manual, openTrivia }

String questionSourceLabel(QuestionSource source) {
  return switch (source) {
    QuestionSource.manual => 'Written by admin',
    QuestionSource.openTrivia => 'Open Trivia DB',
  };
}

/// A single admin-authored quiz question stored in Firestore.
///
/// This is the main data entity the admin CRUD screens manage. It mirrors
/// [SubjectQuizQuestion] (the shape the game engine consumes) plus the
/// bookkeeping fields a stored record needs: id, level, source, audit stamps.
///
/// Note the [choices] semantics match [SubjectQuizQuestion.choices] — the list
/// holds the *wrong* answers only. [SubjectQuizQuestion.shuffled] mixes the
/// correct answer back in at play time.
class QuizQuestionRecord {
  final String id;
  final SubjectQuizType subject;
  final String topic;
  final String instruction;
  final String prompt;
  final String correctAnswer;
  final List<String> choices;
  final int minLevel;
  final QuestionSource source;
  final bool published;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// True for a question compiled into the app rather than stored in
  /// Firestore. Never persisted - [toMap] does not write it - it exists so the
  /// admin list can show the bundled bank read-only next to the editable
  /// records. A bundled question has no document to update or delete.
  final bool bundled;

  const QuizQuestionRecord({
    this.id = '',
    required this.subject,
    required this.topic,
    required this.instruction,
    required this.prompt,
    required this.correctAnswer,
    required this.choices,
    this.minLevel = 1,
    this.source = QuestionSource.manual,
    this.published = true,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.bundled = false,
  });

  /// Smallest number of wrong answers a question needs to be playable.
  static const int minWrongChoices = 2;
  static const int maxWrongChoices = 5;
  static const int maxLevel = 20;

  /// Longest a question may be. Reading-comprehension questions carry a whole
  /// passage in the prompt - the longest one bundled with the app runs to 761
  /// characters - so the cap has to clear that with room to spare rather than
  /// rejecting the app's own questions.
  static const int maxPromptLength = 1000;

  QuizQuestionRecord copyWith({
    String? id,
    SubjectQuizType? subject,
    String? topic,
    String? instruction,
    String? prompt,
    String? correctAnswer,
    List<String>? choices,
    int? minLevel,
    QuestionSource? source,
    bool? published,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? bundled,
  }) {
    return QuizQuestionRecord(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      topic: topic ?? this.topic,
      instruction: instruction ?? this.instruction,
      prompt: prompt ?? this.prompt,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      choices: choices ?? this.choices,
      minLevel: minLevel ?? this.minLevel,
      source: source ?? this.source,
      published: published ?? this.published,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      bundled: bundled ?? this.bundled,
    );
  }

  /// Wraps one of the app's compiled-in questions so it can be listed beside
  /// the Firestore records. [id] is left empty: there is no document behind it.
  factory QuizQuestionRecord.fromBundled(
    SubjectQuizType subject,
    LeveledQuizQuestion leveled,
  ) {
    final question = leveled.question;
    return QuizQuestionRecord(
      subject: subject,
      topic: question.topic,
      instruction: question.instruction,
      prompt: question.prompt,
      correctAnswer: question.correctAnswer,
      choices: question.choices,
      minLevel: leveled.minLevel,
      bundled: true,
    );
  }

  /// The shape the existing quiz engine plays.
  SubjectQuizQuestion toQuizQuestion() {
    return SubjectQuizQuestion(
      topic: topic,
      instruction: instruction,
      prompt: prompt,
      correctAnswer: correctAnswer,
      choices: choices,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subject': subject.name,
      'topic': topic,
      'instruction': instruction,
      'prompt': prompt,
      'correctAnswer': correctAnswer,
      'choices': choices,
      'minLevel': minLevel,
      'source': source.name,
      'published': published,
      if (createdBy != null) 'createdBy': createdBy,
    };
  }

  factory QuizQuestionRecord.fromMap(String id, Map<String, dynamic> data) {
    return QuizQuestionRecord(
      id: id,
      subject: subjectQuizTypeFromName(data['subject']?.toString()),
      topic: (data['topic'] ?? '').toString(),
      instruction: (data['instruction'] ?? '').toString(),
      prompt: (data['prompt'] ?? '').toString(),
      correctAnswer: (data['correctAnswer'] ?? '').toString(),
      choices: (data['choices'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      minLevel: _asInt(data['minLevel']) ?? 1,
      source: data['source']?.toString() == QuestionSource.openTrivia.name
          ? QuestionSource.openTrivia
          : QuestionSource.manual,
      published: data['published'] != false,
      createdBy: data['createdBy']?.toString(),
      createdAt: _asDate(data['createdAt']),
      updatedAt: _asDate(data['updatedAt']),
    );
  }

  factory QuizQuestionRecord.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return QuizQuestionRecord.fromMap(
      snapshot.id,
      snapshot.data() ?? const <String, dynamic>{},
    );
  }

  /// JSON form used by the on-device cache.
  ///
  /// Unlike [toMap] this keeps the document [id] and stores the timestamps as
  /// ISO-8601 strings, so a cached question round-trips without Firestore.
  Map<String, dynamic> toCacheJson() {
    return {
      ...toMap(),
      'id': id,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  factory QuizQuestionRecord.fromCacheJson(Map<String, dynamic> json) {
    return QuizQuestionRecord.fromMap(
      (json['id'] ?? '').toString(),
      json,
    );
  }

  /// Field-by-field validation shared by the editor form, the bulk importer,
  /// and the repository. Returns a map of `fieldName -> message`; an empty map
  /// means the record is safe to write.
  Map<String, String> validate() {
    final errors = <String, String>{};

    final trimmedTopic = topic.trim();
    if (trimmedTopic.isEmpty) {
      errors['topic'] = 'Pick or type a topic.';
    } else if (trimmedTopic.length > 60) {
      errors['topic'] = 'Keep the topic under 60 characters.';
    }

    if (instruction.trim().isEmpty) {
      errors['instruction'] = 'Tell the student what to do, e.g. "Choose the noun".';
    }

    final trimmedPrompt = prompt.trim();
    if (trimmedPrompt.isEmpty) {
      errors['prompt'] = 'The question cannot be empty.';
    } else if (trimmedPrompt.length < 5) {
      errors['prompt'] = 'The question is too short to be clear.';
    } else if (trimmedPrompt.length > maxPromptLength) {
      errors['prompt'] = 'Keep the question under $maxPromptLength characters.';
    }

    final trimmedAnswer = correctAnswer.trim();
    if (trimmedAnswer.isEmpty) {
      errors['correctAnswer'] = 'Mark which answer is correct.';
    }

    final wrongAnswers =
        choices.map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
    if (wrongAnswers.length < minWrongChoices) {
      errors['choices'] =
          'Add at least $minWrongChoices wrong answers so there is something to choose between.';
    } else if (wrongAnswers.length > maxWrongChoices) {
      errors['choices'] = 'Use at most $maxWrongChoices wrong answers.';
    } else {
      // Compared with case intact: a capitalization question's whole point is
      // answers that differ only in case, and folding case here would refuse
      // to let an admin write one.
      final seen = <String>{};
      for (final wrong in wrongAnswers) {
        if (!seen.add(wrong)) {
          errors['choices'] = 'Wrong answers must all be different ("$wrong" is repeated).';
          break;
        }
      }
      if (!errors.containsKey('choices') && seen.contains(trimmedAnswer)) {
        errors['choices'] =
            'The correct answer is also listed as a wrong answer. Remove the duplicate.';
      }
    }

    if (minLevel < 1 || minLevel > maxLevel) {
      errors['minLevel'] = 'Level must be between 1 and $maxLevel.';
    }

    return errors;
  }

  bool get isValid => validate().isEmpty;

  /// Normalized copy that is safe to persist: whitespace trimmed and empty
  /// choices dropped.
  QuizQuestionRecord sanitized() {
    return copyWith(
      topic: topic.trim(),
      instruction: instruction.trim(),
      prompt: prompt.trim(),
      correctAnswer: correctAnswer.trim(),
      choices: choices
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false),
    );
  }
}

/// String <-> enum helpers. Firestore only stores primitives, so the subject
/// travels as its enum name.
SubjectQuizType subjectQuizTypeFromName(String? name) {
  return SubjectQuizType.values.firstWhere(
    (value) => value.name == name,
    orElse: () => SubjectQuizType.english,
  );
}

String subjectQuizTypeLabel(SubjectQuizType subject) {
  return SubjectQuestionBank.configFor(subject).title;
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

DateTime? _asDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
