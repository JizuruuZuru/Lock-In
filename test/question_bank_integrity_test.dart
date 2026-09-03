import 'dart:math';

import 'package:benchmark/data/subject_question_bank.dart';
import 'package:flutter_test/flutter_test.dart';

/// The bundled bank holds 5,793 questions but only 5,768 distinct
/// `topic::prompt` keys - 24 questions are written twice and one three times.
///
/// That matters because a run records every served question in
/// `_askedQuestionKeys` and excludes it from the next draw, so a duplicate's
/// second copy could never be served. It only skewed the draw odds and
/// inflated the question count shown on the start panel.
///
/// `_resolvePool` now de-duplicates, and these hold that in place.
void main() {
  group('resolved pools contain no duplicate keys', () {
    for (final subject in SubjectQuizType.values) {
      test(subject.name, () {
        final random = Random(1);
        final seen = <String>{};
        final asked = <String>{};

        // Draw the whole pool: every key must be new.
        final poolSize = SubjectQuestionBank.questionCountFor(subject);
        expect(poolSize, greaterThan(0));

        for (var i = 0; i < poolSize; i++) {
          final q = SubjectQuestionBank.randomQuestion(
            subject: subject,
            level: 99,
            random: random,
            excludeKeys: asked,
          );
          final key = SubjectQuestionBank.questionKey(q);
          asked.add(key);
          seen.add(key);
        }

        expect(seen.length, poolSize,
            reason: 'the pool should be exactly its distinct keys');
      });
    }
  });

  group('the reported count matches what can actually be served', () {
    for (final subject in SubjectQuizType.values) {
      test(subject.name, () {
        final bundled = SubjectQuestionBank.bundledQuestionsFor(subject);
        final distinct = bundled
            .map((e) => SubjectQuestionBank.questionKey(e.question))
            .toSet();

        // The raw list still holds the duplicates - they are in the data.
        // The pool the game draws from must not.
        expect(SubjectQuestionBank.questionCountFor(subject), distinct.length);
        expect(SubjectQuestionBank.questionCountFor(subject),
            lessThanOrEqualTo(bundled.length));
      });
    }
  });

  test('every bundled topic is reachable from some lesson', () {
    // "Sentence Types" sat in the bank with no lesson allowing it, so its two
    // questions could only ever be served by the un-filtered free-roam quiz,
    // which nothing in the menu navigates to. A topic no lesson claims is
    // content nobody can reach.
    //
    // The lesson topic sets live in the screen wrappers under
    // lib/screens/english and lib/screens/science; this mirrors them, so
    // adding a topic to the bank without filing it under a lesson fails here.
    const claimedEnglishTopics = <String>{
      'Adjectives', 'Adverbs', 'Comparative Adjectives',
      'Conjunctions', 'Interjections',
      'Determiners', 'Prepositions',
      'Nouns', 'Plural Nouns', 'Possessive Nouns', 'Pronouns',
      'Phonics', 'Letter Sounds',
      'Punctuation', 'Capitalization', 'Commas',
      'Questions', 'Tag Questions', 'Reported Speech',
      'Sentence Structure', 'Compound Sentences', 'Sentence Types',
      'Subject-Verb Agreement',
      'Verbs', 'Simple Present Tense', 'Simple Past Tense',
      'Simple Future Tense', 'Active and Passive Voice',
      'Direct and Indirect Objects',
      'Word Study', 'Synonyms', 'Antonyms', 'Homophones',
      'Compound Words', 'Contractions', 'Spelling',
      'Comprehension', 'Main Idea', 'Sequencing', 'Cause and Effect',
      'Inference', 'Context Clues', 'Details', 'Fact and Opinion',
    };

    final bankTopics = <String>{
      for (final e
          in SubjectQuestionBank.bundledQuestionsFor(SubjectQuizType.english))
        e.question.topic,
    };

    final unreachable = bankTopics.difference(claimedEnglishTopics);
    expect(unreachable, isEmpty,
        reason: 'these English topics are in the bank but no lesson serves '
            'them: $unreachable');
  });

  test('every bundled question is well formed', () {
    for (final subject in SubjectQuizType.values) {
      for (final entry in SubjectQuestionBank.bundledQuestionsFor(subject)) {
        final q = entry.question;
        expect(q.topic.trim(), isNotEmpty);
        expect(q.prompt.trim(), isNotEmpty);
        expect(q.correctAnswer.trim(), isNotEmpty);
        expect(q.instruction.trim(), isNotEmpty);
        expect(entry.minLevel, greaterThanOrEqualTo(1));
        expect(q.choices, isNotEmpty);
        expect(q.choices, isNot(contains(q.correctAnswer)),
            reason: 'the correct answer is folded in by shuffled(), so it '
                'must not already be a distractor: "${q.prompt}"');
      }
    }
  });
}
