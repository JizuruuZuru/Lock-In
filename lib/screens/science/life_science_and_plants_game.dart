import 'package:flutter/material.dart';

import '../../data/subject_question_bank.dart';
import '../shared/subject_quiz_game.dart';

class ScienceLifeScienceAndPlantsGame extends StatelessWidget {
  const ScienceLifeScienceAndPlantsGame({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubjectQuizGame(
      subject: SubjectQuizType.science,
      lessonTitle: 'Life Science and Plants',
      lessonDescription:
          'Life Science: practice plant parts, plant needs, life cycles, and pollination.',
      lessonTopicsSummary:
          'Plant parts, plant needs, plant life cycles, and pollination.',
      allowedTopics: {
        'Plant Parts',
        'Plant Needs',
        'Plant Life Cycles',
        'Pollination',
      },
    );
  }
}
