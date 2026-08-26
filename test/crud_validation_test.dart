import 'dart:math';

import 'package:benchmark/data/subject_question_bank.dart';
import 'package:benchmark/models/app_user_record.dart';
import 'package:benchmark/models/quiz_question_record.dart';
import 'package:flutter_test/flutter_test.dart';

/// Validation is the gate every CRUD write passes through, so it is tested
/// directly rather than only through the UI.
void main() {
  QuizQuestionRecord buildQuestion({
    String topic = 'Nouns',
    String instruction = 'Choose the noun.',
    String prompt = 'The bright sun warmed the park.',
    String correctAnswer = 'sun',
    List<String> choices = const ['bright', 'warmed'],
    int minLevel = 1,
  }) {
    return QuizQuestionRecord(
      subject: SubjectQuizType.english,
      topic: topic,
      instruction: instruction,
      prompt: prompt,
      correctAnswer: correctAnswer,
      choices: choices,
      minLevel: minLevel,
    );
  }

  group('QuizQuestionRecord validation', () {
    test('accepts a complete question', () {
      expect(buildQuestion().validate(), isEmpty);
    });

    test('rejects an empty topic, prompt, and correct answer', () {
      final errors =
          buildQuestion(topic: '  ', prompt: '   ', correctAnswer: '').validate();

      expect(errors.keys, containsAll(<String>['topic', 'prompt', 'correctAnswer']));
    });

    test('rejects a prompt that is too short to be a real question', () {
      expect(buildQuestion(prompt: 'Hi').validate(), contains('prompt'));
    });

    test('requires at least two wrong choices', () {
      final errors = buildQuestion(choices: ['bright']).validate();
      expect(errors, contains('choices'));
    });

    test('rejects more than the maximum number of wrong choices', () {
      final errors = buildQuestion(
        choices: const ['a', 'b', 'c', 'd', 'e', 'f'],
      ).validate();
      expect(errors, contains('choices'));
    });

    test('rejects a wrong choice repeated exactly', () {
      final errors = buildQuestion(choices: const ['bright', 'bright']).validate();
      expect(errors['choices'], contains('different'));
    });

    test('allows wrong choices that differ only in case', () {
      // Capitalization and punctuation lessons are built from answers that
      // differ only in case - "The dog ran home." against "the dog ran
      // home.". Treating those as duplicates refused to let an admin write
      // such a question, and the matching de-dup in the game loop collapsed
      // the bundled ones down to a single choice.
      final errors = buildQuestion(choices: const ['Bright', 'bright']).validate();
      expect(errors, isNot(contains('choices')));
    });

    test('rejects the correct answer also appearing as a wrong choice', () {
      final errors =
          buildQuestion(choices: const ['bright', 'sun']).validate();
      expect(errors['choices'], contains('also listed'));
    });

    test('rejects an out-of-range level', () {
      expect(buildQuestion(minLevel: 0).validate(), contains('minLevel'));
      expect(
        buildQuestion(minLevel: QuizQuestionRecord.maxLevel + 1).validate(),
        contains('minLevel'),
      );
    });

    test('sanitized() trims whitespace and drops empty choices', () {
      final clean = buildQuestion(
        topic: '  Nouns  ',
        correctAnswer: ' sun ',
        choices: const ['bright', '   ', 'warmed'],
      ).sanitized();

      expect(clean.topic, 'Nouns');
      expect(clean.correctAnswer, 'sun');
      expect(clean.choices, ['bright', 'warmed']);
    });

    test('survives a round trip through the Firestore map form', () {
      final original = buildQuestion(minLevel: 4);
      final restored = QuizQuestionRecord.fromMap('abc123', original.toMap());

      expect(restored.id, 'abc123');
      expect(restored.subject, original.subject);
      expect(restored.topic, original.topic);
      expect(restored.prompt, original.prompt);
      expect(restored.correctAnswer, original.correctAnswer);
      expect(restored.choices, original.choices);
      expect(restored.minLevel, 4);
      expect(restored.published, isTrue);
    });

    test('toQuizQuestion() shuffles the correct answer in with the wrong ones', () {
      final question = buildQuestion().toQuizQuestion();
      // The stored `choices` list holds only wrong answers; the game engine
      // mixes the correct one back in.
      expect(question.choices, isNot(contains('sun')));

      final played = question.shuffled(Random(1));
      expect(played.choices, contains('sun'));
      expect(played.choices.length, 3);
    });
  });

  group('AppUserRecord validation', () {
    AppUserRecord buildUser({
      String firstName = 'Ana',
      String lastName = 'Cruz',
      int? age = 9,
    }) {
      return AppUserRecord(
        uid: 'uid-1',
        firstName: firstName,
        lastName: lastName,
        age: age,
      );
    }

    test('accepts a complete profile', () {
      expect(buildUser().validate(), isEmpty);
    });

    test('requires both names', () {
      final errors = buildUser(firstName: '', lastName: '  ').validate();
      expect(errors.keys, containsAll(<String>['firstName', 'lastName']));
    });

    test('rejects digits in names', () {
      expect(buildUser(firstName: 'An4').validate(), contains('firstName'));
    });

    test('requires an age inside the allowed range', () {
      expect(buildUser(age: null).validate(), contains('age'));
      expect(
        buildUser(age: AppUserRecord.minAge - 1).validate(),
        contains('age'),
      );
      expect(
        buildUser(age: AppUserRecord.maxAge + 1).validate(),
        contains('age'),
      );
    });

    test('defaults to the student role for documents with no role field', () {
      final record = AppUserRecord.fromMap('uid-2', const {'firstName': 'Bo'});
      expect(record.role, UserRole.student);
      expect(record.isAdmin, isFalse);
      expect(record.disabled, isFalse);
    });

    test('reads the admin role and disabled flag', () {
      final record = AppUserRecord.fromMap('uid-3', const {
        'firstName': 'Mia',
        'lastName': 'Reyes',
        'role': kAdminRoleValue,
        'disabled': true,
      });
      expect(record.isAdmin, isTrue);
      expect(record.disabled, isTrue);
    });

    test('toUpdateMap() carries the role and rebuilds the login id', () {
      final record = buildUser(firstName: 'Ana', lastName: 'Cruz')
          .copyWith(role: UserRole.admin);
      final map = record.toUpdateMap();

      expect(map['role'], kAdminRoleValue);
      expect(map['loginId'], 'ana.cruz');
      expect(map['fullName'], 'Ana Cruz');
    });
  });

  group('SubjectQuestionBank custom question pool', () {
    tearDown(SubjectQuestionBank.clearCustomQuestions);

    test('admin questions join the pool their subject and topic belongs to', () {
      const prompt = 'A test-only question added by an admin.';
      SubjectQuestionBank.setCustomQuestions({
        SubjectQuizType.english: [
          const LeveledQuizQuestion(
            minLevel: 1,
            question: SubjectQuizQuestion(
              topic: 'AdminOnlyTopic',
              instruction: 'Choose the correct answer.',
              prompt: prompt,
              correctAnswer: 'yes',
              choices: ['no', 'maybe'],
            ),
          ),
        ],
      });

      expect(SubjectQuestionBank.customQuestionCountFor(SubjectQuizType.english), 1);
      expect(
        SubjectQuestionBank.topicsFor(SubjectQuizType.english),
        contains('AdminOnlyTopic'),
      );

      // Filtering to that topic can only return the admin question.
      final served = SubjectQuestionBank.randomQuestion(
        subject: SubjectQuizType.english,
        level: 1,
        random: Random(3),
        topics: {'AdminOnlyTopic'},
      );
      expect(served.prompt, prompt);
    });

    test('clearing the pool removes admin questions again', () {
      SubjectQuestionBank.setCustomQuestions({
        SubjectQuizType.science: [
          const LeveledQuizQuestion(
            minLevel: 1,
            question: SubjectQuizQuestion(
              topic: 'Temp',
              instruction: 'i',
              prompt: 'p',
              correctAnswer: 'a',
              choices: ['b', 'c'],
            ),
          ),
        ],
      });
      expect(SubjectQuestionBank.customQuestionCountFor(SubjectQuizType.science), 1);

      SubjectQuestionBank.clearCustomQuestions();
      expect(SubjectQuestionBank.customQuestionCountFor(SubjectQuizType.science), 0);
    });
  });
}
