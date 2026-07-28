import 'package:flutter/material.dart';

import '../../data/subject_question_bank.dart';
import '../shared/subject_quiz_game.dart';

class ScienceEarthAndSpaceGame extends StatelessWidget {
  const ScienceEarthAndSpaceGame({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubjectQuizGame(
      subject: SubjectQuizType.science,
      lessonTitle: 'Earth and Space',
      lessonDescription:
          'Earth and Space Science: practice the solar system, rocks, weather, and seasons.',
      lessonTopicsSummary:
          'Solar system, the Sun, Moon, planets, rocks and soil, minerals, landforms, weather, climate, water cycle, and seasons.',
      allowedTopics: {
        'Solar System',
        'Sun',
        'Moon',
        'Planets',
        'Rocks and Soil',
        'Minerals',
        'Landforms',
        'Weather',
        'Climate',
        'Water Cycle',
        'Seasons',
      },
    );
  }
}
