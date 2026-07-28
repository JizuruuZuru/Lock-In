import 'package:flutter/material.dart';

import '../../data/subject_question_bank.dart';
import '../shared/subject_quiz_game.dart';

class ScienceHumansAndAnimalsGame extends StatelessWidget {
  const ScienceHumansAndAnimalsGame({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubjectQuizGame(
      subject: SubjectQuizType.science,
      lessonTitle: 'Humans and Animals',
      lessonDescription:
          'Life Science: practice animal groups, habitats, adaptations, and the human body.',
      lessonTopicsSummary:
          'Animal classification, life cycles, habitats, adaptations, five senses, the skeleton, organ systems, and health.',
      allowedTopics: {
        'Animal Classification',
        'Animal Life Cycles',
        'Habitats',
        'Adaptations',
        'Five Senses',
        'Skeletal System',
        'Organ Systems',
        'Health',
      },
    );
  }
}
