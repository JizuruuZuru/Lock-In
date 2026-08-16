import 'dart:math';

import 'package:flutter/material.dart';

part 'questions/english/nouns_and_pronouns.dart';
part 'questions/english/verbs_and_tenses.dart';
part 'questions/english/adjectives_and_adverbs.dart';
part 'questions/english/determiners_and_prepositions.dart';
part 'questions/english/conjunctions_and_interjections.dart';
part 'questions/english/sentence_structure.dart';
part 'questions/english/subject_verb_agreement.dart';
part 'questions/english/punctuation_and_capitalization.dart';
part 'questions/english/questions_and_speech.dart';
part 'questions/english/comprehension.dart';
part 'questions/english/word_study.dart';
part 'questions/english/phonics.dart';
part 'questions/science/investigating_and_classifying.dart';
part 'questions/science/life_science_and_plants.dart';
part 'questions/science/humans_and_animals.dart';
part 'questions/science/materials_and_chemistry.dart';
part 'questions/science/physics_and_forces.dart';
part 'questions/science/earth_and_space.dart';

enum SubjectQuizType { english, science }

class SubjectQuizConfig {
  final SubjectQuizType type;
  final String title;
  final String description;
  final String topicsSummary;
  final IconData icon;
  final Color inkColor;
  final Color bgTopColor;
  final Color bgBottomColor;
  final Color panelColor;
  final Color accentColor;
  final String primarySymbol;
  final String secondarySymbol;

  const SubjectQuizConfig({
    required this.type,
    required this.title,
    required this.description,
    required this.topicsSummary,
    required this.icon,
    required this.inkColor,
    required this.bgTopColor,
    required this.bgBottomColor,
    required this.panelColor,
    required this.accentColor,
    required this.primarySymbol,
    required this.secondarySymbol,
  });
}

class SubjectQuizQuestion {
  final String topic;
  final String instruction;
  final String prompt;
  final String correctAnswer;
  final List<String> choices;

  const SubjectQuizQuestion({
    required this.topic,
    required this.instruction,
    required this.prompt,
    required this.correctAnswer,
    required this.choices,
  });

  SubjectQuizQuestion shuffled(Random random) {
    final uniqueChoices = <String>[];

    void addChoice(String choice) {
      final normalizedChoice = _normalize(choice);
      final alreadyAdded = uniqueChoices.any(
        (item) => _normalize(item) == normalizedChoice,
      );
      if (!alreadyAdded) uniqueChoices.add(choice);
    }

    addChoice(correctAnswer);
    for (final choice in choices) {
      addChoice(choice);
    }
    uniqueChoices.shuffle(random);

    return SubjectQuizQuestion(
      topic: topic,
      instruction: instruction,
      prompt: prompt,
      correctAnswer: correctAnswer,
      choices: uniqueChoices,
    );
  }
}

/// A question plus the level a player must reach before it can be served.
class LeveledQuizQuestion {
  final int minLevel;
  final SubjectQuizQuestion question;

  const LeveledQuizQuestion({
    required this.minLevel,
    required this.question,
  });
}

/// The bundled question files were written against the old private name and
/// there are tens of thousands of `const _LeveledQuestion(...)` literals across
/// `data/questions/`. Aliasing keeps every one of them compiling while the
/// class itself becomes public so admin-authored questions can be injected.
typedef _LeveledQuestion = LeveledQuizQuestion;

class SubjectQuestionBank {
  static const _configs = <SubjectQuizType, SubjectQuizConfig>{
    SubjectQuizType.english: SubjectQuizConfig(
      type: SubjectQuizType.english,
      title: 'English',
      description:
          'Practice elementary grammar, vocabulary, punctuation, spelling, and reading basics.',
      topicsSummary:
          'Nouns, verbs, adjectives, synonyms, antonyms, punctuation, spelling, and sentence skills.',
      icon: Icons.menu_book_rounded,
      inkColor: Color(0xFF26324A),
      bgTopColor: Color(0xFFFFF7E8),
      bgBottomColor: Color(0xFFEAF6FF),
      panelColor: Color(0xFFFFFEFA),
      accentColor: Color(0xFF1976D2),
      primarySymbol: 'ABC',
      secondarySymbol: '?',
    ),
    SubjectQuizType.science: SubjectQuizConfig(
      type: SubjectQuizType.science,
      title: 'Science',
      description:
          'Practice elementary life science, Earth science, matter, energy, and simple forces.',
      topicsSummary:
          'Plants, animals, habitats, matter, weather, Earth, magnets, energy, and the human body.',
      icon: Icons.science_rounded,
      inkColor: Color(0xFF1F3D36),
      bgTopColor: Color(0xFFEAF8EF),
      bgBottomColor: Color(0xFFFFF8DE),
      panelColor: Color(0xFFFAFFFB),
      accentColor: Color(0xFF00897B),
      primarySymbol: 'H2O',
      secondarySymbol: 'SUN',
    ),
  };

  static const _questions = <SubjectQuizType, List<_LeveledQuestion>>{
    SubjectQuizType.english: [
      ..._englishNounsAndPronounsQuestions,
      ..._englishVerbsAndTensesQuestions,
      ..._englishAdjectivesAndAdverbsQuestions,
      ..._englishDeterminersAndPrepositionsQuestions,
      ..._englishConjunctionsAndInterjectionsQuestions,
      ..._englishSentenceStructureQuestions,
      ..._englishSubjectVerbAgreementQuestions,
      ..._englishPunctuationAndCapitalizationQuestions,
      ..._englishQuestionsAndSpeechQuestions,
      ..._englishComprehensionQuestions,
      ..._englishWordStudyQuestions,
      ..._englishPhonicsQuestions,
    ],
    SubjectQuizType.science: [
      ..._scienceInvestigatingAndClassifyingQuestions,
      ..._scienceLifeScienceAndPlantsQuestions,
      ..._scienceHumansAndAnimalsQuestions,
      ..._scienceMaterialsAndChemistryQuestions,
      ..._sciencePhysicsAndForcesQuestions,
      ..._scienceEarthAndSpaceQuestions,
    ],
  };

  /// Admin-authored questions loaded from Firestore at startup, keyed by
  /// subject. They are pooled with [_questions] so teacher-made questions show
  /// up inside the lessons students already play — no separate mode needed.
  static final Map<SubjectQuizType, List<LeveledQuizQuestion>> _customQuestions =
      <SubjectQuizType, List<LeveledQuizQuestion>>{};

  /// Replaces the custom pool for every subject at once. Called by
  /// `CustomQuestionSync` after it reads the `quiz_questions` collection, and
  /// again whenever an admin saves a change.
  static void setCustomQuestions(
    Map<SubjectQuizType, List<LeveledQuizQuestion>> bySubject,
  ) {
    _customQuestions
      ..clear()
      ..addAll(bySubject.map(
        (subject, questions) =>
            MapEntry(subject, List<LeveledQuizQuestion>.unmodifiable(questions)),
      ));
  }

  static void clearCustomQuestions() => _customQuestions.clear();

  /// How many admin-authored questions are currently live for [type].
  static int customQuestionCountFor(SubjectQuizType type) =>
      _customQuestions[type]?.length ?? 0;

  /// Bundled questions plus any admin-authored ones for the subject.
  static List<LeveledQuizQuestion> _poolFor(SubjectQuizType type) {
    final bundled = _questions[type]!;
    final custom = _customQuestions[type];
    if (custom == null || custom.isEmpty) return bundled;
    return <LeveledQuizQuestion>[...bundled, ...custom];
  }

  static SubjectQuizConfig configFor(SubjectQuizType type) {
    return _configs[type]!;
  }

  static int questionCountFor(
    SubjectQuizType type, {
    Set<String>? topics,
  }) {
    return _filteredQuestions(type, topics: topics).length;
  }

  /// Every distinct topic available for [type], bundled and admin-authored,
  /// sorted alphabetically.
  ///
  /// The admin question editor offers these as suggestions so a new question
  /// is filed under a topic an existing lesson already asks for — that is what
  /// makes it show up inside the lesson rather than only in the free-roam quiz.
  static List<String> topicsFor(SubjectQuizType type) {
    // Keyed by the normalized form so "Plural Nouns" and "plural  nouns"
    // collapse to one entry, while the original casing is what gets shown.
    final byNormalized = <String, String>{};
    for (final item in _poolFor(type)) {
      final topic = item.question.topic.trim();
      if (topic.isEmpty) continue;
      byNormalized.putIfAbsent(_normalize(topic), () => topic);
    }
    final topics = byNormalized.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return topics;
  }

  /// Stable identity for a question, usable as a key to track which ones a
  /// player has already been asked. Shuffling choices (see
  /// [SubjectQuizQuestion.shuffled]) doesn't change this key.
  static String questionKey(SubjectQuizQuestion question) =>
      '${question.topic}::${question.prompt}';

  /// Picks a random eligible question, preferring one whose [questionKey]
  /// isn't in [excludeKeys] so a player doesn't see the same question twice
  /// in the same session. Once every eligible question has been asked
  /// (i.e. all of them are in [excludeKeys]), repeats become possible again
  /// rather than the game getting stuck with nothing to serve.
  static SubjectQuizQuestion randomQuestion({
    required SubjectQuizType subject,
    required int level,
    required Random random,
    Set<String>? topics,
    Set<String>? excludeKeys,
  }) {
    final filteredQuestions = _filteredQuestions(subject, topics: topics);
    final allQuestions =
        filteredQuestions.isEmpty ? _poolFor(subject) : filteredQuestions;
    final eligibleQuestions = allQuestions
        .where((item) => item.minLevel <= level)
        .toList(growable: false);
    final pool = eligibleQuestions.isEmpty ? allQuestions : eligibleQuestions;

    var candidates = pool;
    if (excludeKeys != null && excludeKeys.isNotEmpty) {
      final unseen = pool
          .where((item) => !excludeKeys.contains(questionKey(item.question)))
          .toList(growable: false);
      if (unseen.isNotEmpty) candidates = unseen;
    }

    return candidates[random.nextInt(candidates.length)].question.shuffled(random);
  }

  static List<LeveledQuizQuestion> _filteredQuestions(
    SubjectQuizType subject, {
    Set<String>? topics,
  }) {
    final allQuestions = _poolFor(subject);
    if (topics == null || topics.isEmpty) return allQuestions;

    final normalizedTopics = topics.map(_normalize).toSet();
    final filtered = allQuestions
        .where((item) =>
            normalizedTopics.contains(_normalize(item.question.topic)))
        .toList(growable: false);
    return filtered;
  }
}

String _normalize(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}
