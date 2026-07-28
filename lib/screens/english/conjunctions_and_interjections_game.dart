import 'package:flutter/material.dart';

import '../../data/subject_question_bank.dart';
import '../shared/subject_quiz_game.dart';

class EnglishConjunctionsAndInterjectionsGame extends StatelessWidget {
  const EnglishConjunctionsAndInterjectionsGame({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubjectQuizGame(
      subject: SubjectQuizType.english,
      lessonTitle: 'Conjunctions and Interjections',
      lessonDescription:
          'Word-level grammar: join ideas with conjunctions and add feeling with interjections.',
      lessonTopicsSummary: 'Conjunctions and interjections.',
      allowedTopics: {
        'Conjunctions',
        'Interjections',
      },
    );
  }
}
