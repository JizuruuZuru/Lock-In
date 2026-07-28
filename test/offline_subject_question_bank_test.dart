import 'package:flutter_test/flutter_test.dart';
import 'package:benchmark/services/offline_subject_question_bank.dart';

void main() {
  test('offline English bank provides more than 30 elementary questions', () {
    final questions = OfflineSubjectQuestionBank.questionsFor(
      OfflineSubject.english,
      count: 32,
    );

    expect(questions.length, 32);
    expect(questions.every((question) => question.choices.length >= 4), isTrue);
  });

  test('offline Science bank provides more than 30 elementary questions', () {
    final questions = OfflineSubjectQuestionBank.questionsFor(
      OfflineSubject.science,
      count: 32,
    );

    expect(questions.length, 32);
    expect(questions.every((question) => question.choices.contains(question.answer)), isTrue);
  });
}
