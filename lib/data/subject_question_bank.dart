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

class _LeveledQuestion {
  final int minLevel;
  final SubjectQuizQuestion question;

  const _LeveledQuestion({
    required this.minLevel,
    required this.question,
  });
}

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

  static SubjectQuizConfig configFor(SubjectQuizType type) {
    return _configs[type]!;
  }

  static int questionCountFor(
    SubjectQuizType type, {
    Set<String>? topics,
  }) {
    return _filteredQuestions(type, topics: topics).length;
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
        filteredQuestions.isEmpty ? _questions[subject]! : filteredQuestions;
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

  static List<_LeveledQuestion> _filteredQuestions(
    SubjectQuizType subject, {
    Set<String>? topics,
  }) {
    final allQuestions = _questions[subject]!;
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
