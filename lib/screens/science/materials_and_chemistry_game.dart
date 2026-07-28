import 'package:flutter/material.dart';

import '../../data/subject_question_bank.dart';
import '../shared/subject_quiz_game.dart';

class ScienceMaterialsAndChemistryGame extends StatelessWidget {
  const ScienceMaterialsAndChemistryGame({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubjectQuizGame(
      subject: SubjectQuizType.science,
      lessonTitle: 'Materials and Chemistry',
      lessonDescription:
          'Physical Science: practice states of matter, material properties, and mixtures.',
      lessonTopicsSummary:
          'States of matter, material properties, and mixtures.',
      allowedTopics: {
        'States of Matter',
        'Material Properties',
        'Mixtures',
      },
    );
  }
}
