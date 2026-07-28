import 'package:flutter/material.dart';

import '../../data/subject_question_bank.dart';
import '../shared/subject_quiz_game.dart';

class EnglishPhonicsGame extends StatelessWidget {
  const EnglishPhonicsGame({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubjectQuizGame(
      subject: SubjectQuizType.english,
      lessonTitle: 'Phonics',
      lessonDescription:
          'Practice spelling patterns, beginning sounds, blends, and vowel sounds.',
      lessonTopicsSummary:
          'Spelling patterns, letter sounds, blends, and vowel sounds.',
      allowedTopics: {
        'Phonics',
        'Spelling',
        'Letter Sounds',
      },
    );
  }
}
