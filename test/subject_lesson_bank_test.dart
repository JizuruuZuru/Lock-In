import 'package:flutter_test/flutter_test.dart';
import 'package:benchmark/services/subject_lesson_bank.dart';

void main() {
  test('English lesson bank includes grammar, reading, vocabulary, and phonics topics', () {
    final questions = SubjectLessonBank.questionsFor(
      SubjectLessonSubject.english,
      count: 8,
    );

    expect(questions.length, 8);
    expect(
      questions.map((question) => question.topic).toSet(),
      containsAll({'Grammar', 'Reading', 'Vocabulary', 'Phonics'}),
    );
  });

  test('Science lesson bank uses elementary-level quiz questions with four choices', () {
    final questions = SubjectLessonBank.questionsFor(
      SubjectLessonSubject.science,
      count: 6,
    );

    expect(questions.length, 6);
    expect(questions.every((question) => question.options.length == 4), isTrue);
    expect(
      questions.every((question) => question.options.contains(question.answer)),
      isTrue,
    );
  });
}
