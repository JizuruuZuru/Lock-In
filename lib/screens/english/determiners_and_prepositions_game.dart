import 'package:flutter/material.dart';

import '../../data/subject_question_bank.dart';
import '../shared/subject_quiz_game.dart';

class EnglishDeterminersAndPrepositionsGame extends StatelessWidget {
  const EnglishDeterminersAndPrepositionsGame({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubjectQuizGame(
      subject: SubjectQuizType.english,
      lessonTitle: 'Determiners and Prepositions',
      lessonDescription:
          'Word-level grammar: choose the right article or determiner, and the right preposition.',
      lessonTopicsSummary: 'Determiners and prepositions.',
      allowedTopics: {
        'Determiners',
        'Prepositions',
      },
    );
  }
}
