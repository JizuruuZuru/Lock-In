import 'package:flutter/material.dart';

import '../../data/subject_question_bank.dart';
import '../shared/subject_quiz_game.dart';

class EnglishQuestionsAndSpeechGame extends StatelessWidget {
  const EnglishQuestionsAndSpeechGame({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubjectQuizGame(
      subject: SubjectQuizType.english,
      lessonTitle: 'Questions and Speech',
      lessonDescription:
          'Sentence-level grammar: ask questions, use tag questions, and practice active/passive voice and reported speech.',
      lessonTopicsSummary:
          'Questions, tag questions, active and passive voice, and reported speech.',
      allowedTopics: {
        'Questions',
        'Tag Questions',
        'Active and Passive Voice',
        'Reported Speech',
      },
    );
  }
}
