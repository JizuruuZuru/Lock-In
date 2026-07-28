import 'package:benchmark/screens/exams/exam_game.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('exam subject selection labels', () {
    test('returns a friendly label for each exam subject', () {
      expect(examSubjectSelectionLabel(ExamSubjectSelection.english), 'English');
      expect(examSubjectSelectionLabel(ExamSubjectSelection.math), 'Math');
      expect(examSubjectSelectionLabel(ExamSubjectSelection.science), 'Science');
    });
  });

  group('exam subject set titles', () {
    test('single subject uses its plain label', () {
      expect(
        examSubjectSetTitle({ExamSubjectSelection.english}),
        'English',
      );
    });

    test('a free combination of subjects is joined with "+"', () {
      expect(
        examSubjectSetTitle(
          {ExamSubjectSelection.english, ExamSubjectSelection.science},
        ),
        'English + Science',
      );
    });

    test('selecting every subject collapses to "All Subjects"', () {
      expect(
        examSubjectSetTitle({
          ExamSubjectSelection.english,
          ExamSubjectSelection.math,
          ExamSubjectSelection.science,
        }),
        'All Subjects',
      );
    });
  });
}
