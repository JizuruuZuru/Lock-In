import 'package:flutter/material.dart';

import '../../data/subject_question_bank.dart';
import '../shared/subject_quiz_game.dart';

class EnglishSentenceStructureGame extends StatelessWidget {
  const EnglishSentenceStructureGame({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubjectQuizGame(
      subject: SubjectQuizType.english,
      lessonTitle: 'Sentence Structure',
      lessonDescription:
          'Sentence-level grammar: spot complete sentences, subjects, and compound sentences.',
      lessonTopicsSummary:
          'Sentence structure and compound sentences.',
      allowedTopics: {
        'Sentence Structure',
        'Compound Sentences',
      },
    );
  }
}
