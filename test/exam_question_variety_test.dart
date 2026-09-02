import 'dart:math';

import 'package:benchmark/data/subject_question_bank.dart';
import 'package:flutter_test/flutter_test.dart';

/// The exam used to hold every English and Science question as a
/// `const _ExamQuestion` with fixed text: two per subject per difficulty, and
/// Hard reused Easy's two verbatim. "English Hard Exam" therefore served the
/// same two easy questions forever, while the bundled bank sat unused and the
/// start panel promised "Questions are randomized every round."
///
/// The exam now draws from [SubjectQuestionBank], mapping its difficulty onto
/// the bank's `minLevel`. These exercise the draw the exam performs - the same
/// call, with the same arguments - so the variety it depends on is pinned.
void main() {
  // Mirrors _ExamGameState._bankLevel.
  const easyLevel = 1;
  const mediumLevel = 2;
  const hardLevel = 4;

  SubjectQuizQuestion draw(
    SubjectQuizType subject,
    int level,
    Random random,
    Set<String> asked,
  ) {
    final question = SubjectQuestionBank.randomQuestion(
      subject: subject,
      level: level,
      random: random,
      excludeKeys: asked,
    );
    asked.add(SubjectQuestionBank.questionKey(question));
    return question;
  }

  for (final subject in SubjectQuizType.values) {
    group('${subject.name} exam draws', () {
      test('serves far more than the two questions it used to', () {
        final random = Random(7);
        final asked = <String>{};

        for (var i = 0; i < 50; i++) {
          draw(subject, easyLevel, random, asked);
        }

        expect(asked.length, 50,
            reason: 'every draw should be a distinct question');
      });

      test('the whole subject pool is far bigger than the old two questions',
          () {
        expect(
          SubjectQuestionBank.questionCountFor(subject),
          greaterThan(500),
          reason: subject.name,
        );
      });

      test('every difficulty can fill a long run without repeating', () {
        for (final level in [easyLevel, mediumLevel, hardLevel]) {
          final random = Random(3);
          final asked = <String>{};
          for (var i = 0; i < 60; i++) {
            draw(subject, level, random, asked);
          }
          expect(asked.length, 60, reason: '${subject.name} at level $level');
        }
      });

      test('a Hard exam reaches material an Easy one cannot', () {
        // The old Hard tier literally reused the Easy builders. The bank gates
        // by minLevel, so a Hard draw must be able to surface questions that
        // never appear at level 1.
        final easyReachable = <String>{};
        final easyRandom = Random(5);
        for (var i = 0; i < 400; i++) {
          final asked = <String>{};
          easyReachable.add(SubjectQuestionBank.questionKey(
            draw(subject, easyLevel, easyRandom, asked),
          ));
        }

        final hardOnly = <String>{};
        final hardRandom = Random(5);
        for (var i = 0; i < 400; i++) {
          final asked = <String>{};
          final key = SubjectQuestionBank.questionKey(
            draw(subject, hardLevel, hardRandom, asked),
          );
          if (!easyReachable.contains(key)) hardOnly.add(key);
        }

        expect(hardOnly, isNotEmpty,
            reason: 'Hard should not be a subset of Easy');
      });

      test('drawn questions are shaped for the exam UI', () {
        final random = Random(11);
        final asked = <String>{};

        for (var i = 0; i < 25; i++) {
          final q = draw(subject, hardLevel, random, asked).shuffled(random);

          expect(q.prompt.trim(), isNotEmpty);
          expect(q.instruction.trim(), isNotEmpty);
          expect(q.correctAnswer.trim(), isNotEmpty);
          // shuffled() folds the correct answer in, so the exam can render the
          // choice list directly and still have a right button to press.
          expect(q.choices, contains(q.correctAnswer));
          expect(q.choices.length, greaterThanOrEqualTo(2));
          expect(q.choices.toSet().length, q.choices.length,
              reason: 'no duplicate buttons');
        }
      });
    });
  }
}
