import 'package:flutter/material.dart';

import '../../data/subject_question_bank.dart';
import '../shared/subject_quiz_game.dart';

class EnglishComprehensionGame extends StatelessWidget {
  const EnglishComprehensionGame({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubjectQuizGame(
      subject: SubjectQuizType.english,
      lessonTitle: 'Comprehension',
      lessonDescription:
          'Find main ideas, details, order, causes, facts, and clues in short passages.',
      lessonTopicsSummary:
          'Main idea, details, sequencing, cause and effect, fact and opinion, and inference.',
      allowedTopics: {
        'Comprehension',
        'Main Idea',
        'Details',
        'Sequencing',
        'Cause and Effect',
        'Fact and Opinion',
        'Inference',
        'Context Clues',
      },
    );
  }
}
