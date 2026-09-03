import 'dart:math';

import 'package:benchmark/data/subject_question_bank.dart';
import 'package:benchmark/models/quiz_question_record.dart';
import 'package:flutter_test/flutter_test.dart';

/// The bundled bank is what makes the app playable with no account and no
/// connection, and it is now also what the admin "Questions" screen lists.
/// These tests hold both of those promises to the numbers the README quotes.
void main() {
  group('the bundled bank ships complete', () {
    test('carries 5,809 questions across English and Science', () {
      final english =
          SubjectQuestionBank.bundledQuestionsFor(SubjectQuizType.english);
      final science =
          SubjectQuestionBank.bundledQuestionsFor(SubjectQuizType.science);

      expect(english, hasLength(2953));
      expect(science, hasLength(2856));
      expect(english.length + science.length, 5809);
    });

    test('the servable count is the distinct count, not the raw one', () {
      // 24 bundled questions are written twice (one three times), so the raw
      // list has always been larger than what a player can actually be served:
      // a run excludes every key it has already asked, so a duplicate's second
      // copy is unreachable. The pool de-duplicates, and this is the number
      // that matters for "how many questions does this app have".
      var raw = 0;
      var distinct = 0;
      for (final subject in SubjectQuizType.values) {
        raw += SubjectQuestionBank.bundledQuestionsFor(subject).length;
        distinct += SubjectQuestionBank.questionCountFor(subject);
      }

      expect(raw, 5809);
      expect(distinct, 5784);
      expect(distinct, lessThan(raw), reason: 'the duplicates are still in the data');
    });

    test('needs no network: the bank is const data inside the binary', () {
      // Reading it must not require Firestore, a signed-in user, or the
      // custom-question sync ever having run.
      SubjectQuestionBank.clearCustomQuestions();
      for (final subject in SubjectQuizType.values) {
        expect(
          SubjectQuestionBank.bundledQuestionsFor(subject),
          isNotEmpty,
          reason: '${subject.name} has no offline questions',
        );
      }
      final offline = SubjectQuestionBank.randomQuestion(
        subject: SubjectQuizType.science,
        level: 1,
        random: Random(4),
      );
      expect(offline.prompt, isNotEmpty);
      expect(offline.correctAnswer, isNotEmpty);
    });
  });

  group('every bundled question is playable', () {
    test('offers at least two choices after shuffling', () {
      final random = Random(2);
      final thin = <String>[];

      for (final subject in SubjectQuizType.values) {
        for (final leveled
            in SubjectQuestionBank.bundledQuestionsFor(subject)) {
          final shuffled = leveled.question.shuffled(random);
          if (shuffled.choices.length < 2) {
            thin.add('${subject.name}: ${leveled.question.prompt}');
          }
        }
      }

      // Capitalization questions are built from answers that differ only in
      // case. A case-insensitive de-dup collapsed all of them into one, so the
      // student was shown a single button - the correct answer.
      expect(
        thin,
        isEmpty,
        reason: '${thin.length} questions render with fewer than two choices:\n'
            '${thin.take(5).join('\n')}',
      );
    });

    test('keeps the correct answer among the choices', () {
      final random = Random(3);
      final broken = <String>[];

      for (final subject in SubjectQuizType.values) {
        for (final leveled
            in SubjectQuestionBank.bundledQuestionsFor(subject)) {
          final shuffled = leveled.question.shuffled(random);
          if (!shuffled.choices.contains(shuffled.correctAnswer)) {
            broken.add('${subject.name}: ${leveled.question.prompt}');
          }
        }
      }

      expect(broken, isEmpty,
          reason: 'unanswerable questions:\n${broken.take(5).join('\n')}');
    });

    test('a capitalization question keeps all four of its choices', () {
      const question = SubjectQuizQuestion(
        topic: 'Capitalization',
        instruction: 'Choose the correctly capitalized sentence.',
        prompt: 'Which sentence is written correctly?',
        correctAnswer: 'The dog ran home.',
        choices: [
          'the dog ran home.',
          'The dog ran Home.',
          'the Dog ran home.',
        ],
      );

      final shuffled = question.shuffled(Random(1));
      expect(shuffled.choices, hasLength(4));
      expect(shuffled.choices, contains('The dog ran home.'));
      expect(shuffled.choices, contains('the dog ran home.'));
    });

    test('still collapses a genuinely repeated choice', () {
      const question = SubjectQuizQuestion(
        topic: 'Nouns',
        instruction: 'Choose the noun.',
        prompt: 'Which word is a noun?',
        correctAnswer: 'cat',
        choices: ['run', 'run', 'happy'],
      );

      final shuffled = question.shuffled(Random(1));
      expect(shuffled.choices, hasLength(3));
    });
  });

  group('the admin list can show the bundled bank', () {
    test('every bundled question converts to a valid record', () {
      final invalid = <String>[];

      for (final subject in SubjectQuizType.values) {
        for (final leveled
            in SubjectQuestionBank.bundledQuestionsFor(subject)) {
          final record = QuizQuestionRecord.fromBundled(subject, leveled);
          if (!record.isValid) {
            invalid.add('${subject.name}: ${record.prompt} '
                '-> ${record.validate()}');
          }
        }
      }

      expect(
        invalid,
        isEmpty,
        reason: '${invalid.length} bundled questions would not render:\n'
            '${invalid.take(5).join('\n')}',
      );
    });

    test('records are marked read-only and carry no document id', () {
      final leveled =
          SubjectQuestionBank.bundledQuestionsFor(SubjectQuizType.english)
              .first;
      final record =
          QuizQuestionRecord.fromBundled(SubjectQuizType.english, leveled);

      expect(record.bundled, isTrue);
      expect(record.id, isEmpty);
      expect(record.subject, SubjectQuizType.english);
      expect(record.minLevel, leveled.minLevel);
    });

    test('a Firestore-backed record is not marked bundled', () {
      final record = QuizQuestionRecord.fromMap('abc123', const {
        'subject': 'science',
        'topic': 'Weather',
        'instruction': 'Choose one.',
        'prompt': 'What falls from clouds?',
        'correctAnswer': 'rain',
        'choices': ['wind', 'sun'],
      });

      expect(record.bundled, isFalse);
      expect(record.id, 'abc123');
    });
  });
}
