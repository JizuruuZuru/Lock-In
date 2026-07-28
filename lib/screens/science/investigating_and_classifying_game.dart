import 'package:flutter/material.dart';

import '../../data/subject_question_bank.dart';
import '../shared/subject_quiz_game.dart';

class ScienceInvestigatingAndClassifyingGame extends StatelessWidget {
  const ScienceInvestigatingAndClassifyingGame({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubjectQuizGame(
      subject: SubjectQuizType.science,
      lessonTitle: 'Investigating and Classifying',
      lessonDescription:
          'Practice how scientists ask questions, use tools, and sort living and nonliving things.',
      lessonTopicsSummary:
          'Classifying living and nonliving things, observation tools, and the scientific method.',
      allowedTopics: {
        'Classifying Living and Nonliving',
        'Observation Tools',
        'Scientific Method',
      },
    );
  }
}
