import 'package:flutter/material.dart';

import '../../data/subject_question_bank.dart';
import '../shared/subject_quiz_game.dart';

class SciencePhysicsAndForcesGame extends StatelessWidget {
  const SciencePhysicsAndForcesGame({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubjectQuizGame(
      subject: SubjectQuizType.science,
      lessonTitle: 'Physics and Forces',
      lessonDescription:
          'Physical Science: practice forces, motion, simple machines, and energy.',
      lessonTopicsSummary:
          'Forces, motion, simple machines, magnets, friction, energy, light, sound, heat, electricity, and circuits.',
      allowedTopics: {
        'Forces',
        'Motion',
        'Simple Machines',
        'Magnets',
        'Friction',
        'Energy',
        'Light',
        'Sound',
        'Heat',
        'Electricity',
        'Circuits',
      },
    );
  }
}
