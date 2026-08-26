import 'dart:math';

import 'package:benchmark/data/subject_question_bank.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the question-selection contract that [SubjectQuestionBank]'s cached,
/// minLevel-sorted pools are an optimization of. Every expectation here held
/// before that change and must keep holding after it.
void main() {
  tearDown(SubjectQuestionBank.clearCustomQuestions);

  group('level gating', () {
    // A pool with known minLevels under a topic nothing else uses, so the
    // level cutoff can be asserted exactly.
    const gatedTopic = 'Level Gating Fixture';

    void installGatedPool() {
      SubjectQuestionBank.setCustomQuestions({
        SubjectQuizType.english: [
          for (var level = 1; level <= 5; level++)
            LeveledQuizQuestion(
              minLevel: level,
              question: SubjectQuizQuestion(
                topic: gatedTopic,
                instruction: 'Pick one.',
                prompt: 'A question unlocked at level $level.',
                correctAnswer: 'right',
                choices: const ['wrong one', 'wrong two'],
              ),
            ),
        ],
        SubjectQuizType.science: const [],
      });
    }

    test('never serves a question above the player level', () {
      installGatedPool();
      final random = Random(7);

      for (var level = 1; level <= 5; level++) {
        for (var i = 0; i < 60; i++) {
          final question = SubjectQuestionBank.randomQuestion(
            subject: SubjectQuizType.english,
            level: level,
            random: random,
            topics: const {gatedTopic},
          );
          final unlockedAt =
              int.parse(question.prompt.split('level ').last.replaceAll('.', ''));
          expect(
            unlockedAt,
            lessThanOrEqualTo(level),
            reason: 'level $level served a question gated at $unlockedAt',
          );
        }
      }
    });

    test('a higher level unlocks strictly more questions', () {
      installGatedPool();
      final random = Random(9);

      Set<String> promptsAt(int level) {
        final seen = <String>{};
        for (var i = 0; i < 200; i++) {
          seen.add(SubjectQuestionBank.randomQuestion(
            subject: SubjectQuizType.english,
            level: level,
            random: random,
            topics: const {gatedTopic},
          ).prompt);
        }
        return seen;
      }

      expect(promptsAt(1).length, 1);
      expect(promptsAt(3).length, 3);
      expect(promptsAt(5).length, 5);
    });

    test('a level below every question still serves something', () {
      installGatedPool();
      final question = SubjectQuestionBank.randomQuestion(
        subject: SubjectQuizType.english,
        level: 0,
        random: Random(1),
        topics: const {gatedTopic},
      );
      expect(question.prompt, isNotEmpty);
    });
  });

  group('topic filtering', () {
    test('only serves questions from the requested topics', () {
      const topics = {'Nouns', 'Pronouns'};
      final random = Random(11);
      for (var i = 0; i < 300; i++) {
        final question = SubjectQuestionBank.randomQuestion(
          subject: SubjectQuizType.english,
          level: 20,
          random: random,
          topics: topics,
        );
        expect(topics, contains(question.topic));
      }
    });

    test('a topic that matches nothing falls back to the whole subject', () {
      final question = SubjectQuestionBank.randomQuestion(
        subject: SubjectQuizType.english,
        level: 3,
        random: Random(3),
        topics: const {'A Topic That Does Not Exist'},
      );
      expect(question.prompt, isNotEmpty);
    });

    test('topic matching ignores case and extra whitespace', () {
      final spaced = SubjectQuestionBank.questionCountFor(
        SubjectQuizType.english,
        topics: const {'  nouns  '},
      );
      final plain = SubjectQuestionBank.questionCountFor(
        SubjectQuizType.english,
        topics: const {'Nouns'},
      );
      expect(plain, greaterThan(0));
      expect(spaced, plain);
    });
  });

  group('repeat avoidance', () {
    test('exhausts a topic pool before repeating', () {
      const topics = {'Nouns'};
      final total = SubjectQuestionBank.questionCountFor(
        SubjectQuizType.english,
        topics: topics,
      );
      expect(total, greaterThan(0));

      final random = Random(23);
      final asked = <String>{};
      for (var i = 0; i < total; i++) {
        final question = SubjectQuestionBank.randomQuestion(
          subject: SubjectQuizType.english,
          level: 20,
          random: random,
          topics: topics,
          excludeKeys: asked,
        );
        final key = SubjectQuestionBank.questionKey(question);
        expect(asked.add(key), isTrue, reason: 'repeated "$key" at draw $i');
      }
      expect(asked.length, total);
    });

    test('allows repeats again once everything has been asked', () {
      const topics = {'Nouns'};
      final total = SubjectQuestionBank.questionCountFor(
        SubjectQuizType.english,
        topics: topics,
      );

      final random = Random(5);
      final asked = <String>{};
      for (var i = 0; i < total; i++) {
        asked.add(SubjectQuestionBank.questionKey(
          SubjectQuestionBank.randomQuestion(
            subject: SubjectQuizType.english,
            level: 20,
            random: random,
            topics: topics,
            excludeKeys: asked,
          ),
        ));
      }

      // The pool is exhausted; the next draw must still return a question
      // rather than throwing or hanging.
      final extra = SubjectQuestionBank.randomQuestion(
        subject: SubjectQuizType.english,
        level: 20,
        random: random,
        topics: topics,
        excludeKeys: asked,
      );
      expect(asked, contains(SubjectQuestionBank.questionKey(extra)));
    });

    test('spreads draws across the pool rather than favouring one question',
        () {
      const topics = {'Nouns'};
      final random = Random(31);
      final counts = <String, int>{};
      for (var i = 0; i < 400; i++) {
        final question = SubjectQuestionBank.randomQuestion(
          subject: SubjectQuizType.english,
          level: 20,
          random: random,
          topics: topics,
          excludeKeys: const <String>{'a key that matches nothing'},
        );
        final key = SubjectQuestionBank.questionKey(question);
        counts[key] = (counts[key] ?? 0) + 1;
      }
      // Reservoir sampling must not collapse onto a handful of questions.
      expect(counts.length, greaterThan(10));
    });
  });

  group('custom questions', () {
    test('an admin question becomes drawable and invalidates the cache', () {
      const topics = {'Nouns'};
      final before = SubjectQuestionBank.questionCountFor(
        SubjectQuizType.english,
        topics: topics,
      );

      SubjectQuestionBank.setCustomQuestions({
        SubjectQuizType.english: const [
          LeveledQuizQuestion(
            minLevel: 1,
            question: SubjectQuizQuestion(
              topic: 'Nouns',
              instruction: 'Choose the noun.',
              prompt: 'A teacher-authored question about nouns.',
              correctAnswer: 'noun',
              choices: ['verb', 'adverb'],
            ),
          ),
        ],
        SubjectQuizType.science: const [],
      });

      final after = SubjectQuestionBank.questionCountFor(
        SubjectQuizType.english,
        topics: topics,
      );
      expect(after, before + 1,
          reason: 'the cached pool was not rebuilt after a custom question');

      // And it is actually reachable: exhaust the pool and look for it.
      final random = Random(13);
      final asked = <String>{};
      for (var i = 0; i < after; i++) {
        asked.add(SubjectQuestionBank.questionKey(
          SubjectQuestionBank.randomQuestion(
            subject: SubjectQuizType.english,
            level: 20,
            random: random,
            topics: topics,
            excludeKeys: asked,
          ),
        ));
      }
      expect(asked, contains('Nouns::A teacher-authored question about nouns.'));
    });

    test('clearing custom questions restores the original count', () {
      final before =
          SubjectQuestionBank.questionCountFor(SubjectQuizType.english);

      SubjectQuestionBank.setCustomQuestions({
        SubjectQuizType.english: const [
          LeveledQuizQuestion(
            minLevel: 1,
            question: SubjectQuizQuestion(
              topic: 'Temporary',
              instruction: 'Pick one.',
              prompt: 'Throwaway question.',
              correctAnswer: 'yes',
              choices: ['no', 'maybe'],
            ),
          ),
        ],
      });
      expect(
        SubjectQuestionBank.questionCountFor(SubjectQuizType.english),
        before + 1,
      );

      SubjectQuestionBank.clearCustomQuestions();
      expect(
        SubjectQuestionBank.questionCountFor(SubjectQuizType.english),
        before,
      );
    });
  });
}
