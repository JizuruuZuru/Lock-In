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
      // Case-sensitive on purpose. Capitalization and punctuation questions
      // are built from answers that differ *only* in case - "The dog ran
      // home." against "the dog ran home." - so folding case here deleted
      // every distractor and left the student one button to press.
      final normalizedChoice = _normalizeChoice(choice);
      final alreadyAdded = uniqueChoices.any(
        (item) => _normalizeChoice(item) == normalizedChoice,
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
    _poolCache.clear();
  }

  static void clearCustomQuestions() {
    _customQuestions.clear();
    _poolCache.clear();
  }

  /// Resolved pools, keyed by subject and by the topic filter applied to it.
  ///
  /// Building a pool means normalizing the topic of every one of the ~5,800
  /// bundled questions, and [randomQuestion] is called once per question the
  /// player sees. Doing that work on every draw was the most expensive thing
  /// in the game loop, so the result is cached here and thrown away only when
  /// the custom question pool actually changes - the two methods above are
  /// its only mutation points.
  static final Map<String, _ResolvedPool> _poolCache = <String, _ResolvedPool>{};

  /// The questions compiled into the app for [type], without any of the
  /// admin-authored ones pooled in.
  ///
  /// The admin question list shows these alongside the Firestore records so a
  /// teacher can see the whole bank, not just the part they wrote themselves.
  /// They are const literals in the binary, so they are read-only.
  static List<LeveledQuizQuestion> bundledQuestionsFor(SubjectQuizType type) {
    return _questions[type]!;
  }

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
    return _resolvePool(type, topics).questions.length;
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
    for (final item in _resolvePool(type, null).questions) {
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
    var pool = _resolvePool(subject, topics);
    // A topic filter that matches nothing falls back to the whole subject, so
    // a lesson whose topics were all renamed still plays.
    if (pool.questions.isEmpty) pool = _resolvePool(subject, null);
    if (pool.questions.isEmpty) {
      throw StateError('No questions available for ${subject.name}.');
    }

    // The pool is sorted by minLevel, so everything the player has unlocked
    // sits at the front and the cutoff is one binary search rather than a
    // scan and a copy of the whole list.
    var end = pool.eligibleCount(level);
    if (end == 0) end = pool.questions.length;

    if (excludeKeys != null && excludeKeys.isNotEmpty) {
      final unseen = pool.sampleUnseen(random, end, excludeKeys);
      if (unseen != null) return unseen.question.shuffled(random);
      // Every eligible question has already been asked, so repeats become
      // possible again rather than the game running out of things to serve.
    }

    return pool.questions[random.nextInt(end)].question.shuffled(random);
  }

  /// Bundled + custom questions for [subject], narrowed to [topics], sorted by
  /// minLevel, with every question key precomputed. Cached; see [_poolCache].
  static _ResolvedPool _resolvePool(
    SubjectQuizType subject,
    Set<String>? topics,
  ) {
    final normalizedTopics = (topics == null || topics.isEmpty)
        ? const <String>[]
        : (topics.map(_normalize).toSet().toList()..sort());
    final cacheKey = '${subject.name}|${normalizedTopics.join(',')}';

    final cached = _poolCache[cacheKey];
    if (cached != null) return cached;

    var questions = _poolFor(subject);
    if (normalizedTopics.isNotEmpty) {
      final wanted = normalizedTopics.toSet();
      questions = questions
          .where((item) => wanted.contains(_normalize(item.question.topic)))
          .toList(growable: false);
    }

    final sorted = List<LeveledQuizQuestion>.of(questions)
      ..sort((a, b) => a.minLevel.compareTo(b.minLevel));
    final resolved = _ResolvedPool(
      questions: List<LeveledQuizQuestion>.unmodifiable(sorted),
      keys: List<String>.unmodifiable(
        sorted.map((item) => questionKey(item.question)),
      ),
    );

    _poolCache[cacheKey] = resolved;
    return resolved;
  }
}

/// A ready-to-draw-from question pool: sorted by minLevel, with each
/// question's [SubjectQuestionBank.questionKey] worked out once up front
/// instead of rebuilt for every candidate on every draw.
class _ResolvedPool {
  final List<LeveledQuizQuestion> questions;

  /// Parallel to [questions] - `keys[i]` is the key of `questions[i]`.
  final List<String> keys;

  const _ResolvedPool({required this.questions, required this.keys});

  /// How many leading questions are unlocked at [level]. The list is sorted by
  /// minLevel, so this is an upper-bound index found by binary search.
  int eligibleCount(int level) {
    var low = 0;
    var high = questions.length;
    while (low < high) {
      final mid = (low + high) ~/ 2;
      if (questions[mid].minLevel <= level) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    return low;
  }

  /// A uniformly random question from `questions[0..end)` whose key is not in
  /// [excludeKeys], or null once every eligible question has been asked.
  ///
  /// Reservoir sampling: one pass, no intermediate list, and every unseen
  /// question is equally likely.
  LeveledQuizQuestion? sampleUnseen(
    Random random,
    int end,
    Set<String> excludeKeys,
  ) {
    LeveledQuizQuestion? chosen;
    var unseenSoFar = 0;
    for (var i = 0; i < end; i++) {
      if (excludeKeys.contains(keys[i])) continue;
      unseenSoFar++;
      if (random.nextInt(unseenSoFar) == 0) chosen = questions[i];
    }
    return chosen;
  }
}

/// Compiled once. Building the RegExp inside [_normalize] meant recompiling
/// it for every question in the bank on every single lookup.
final RegExp _whitespaceRun = RegExp(r'\s+');

String _normalize(String value) {
  return value.toLowerCase().replaceAll(_whitespaceRun, ' ').trim();
}

/// Like [_normalize] but keeps case, for comparing answer choices. Two choices
/// count as the same only when they are the same text, not merely the same
/// letters - see [SubjectQuizQuestion.shuffled].
String _normalizeChoice(String value) {
  return value.replaceAll(_whitespaceRun, ' ').trim();
}
