import 'package:flutter/material.dart';

import '../../data/subject_question_bank.dart';
import '../shared/subject_quiz_game.dart';

class EnglishWordStudyGame extends StatelessWidget {
  const EnglishWordStudyGame({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubjectQuizGame(
      subject: SubjectQuizType.english,
      lessonTitle: 'Word Study',
      lessonDescription:
          'Build vocabulary with synonyms, antonyms, homophones, and word parts.',
      lessonTopicsSummary: 'Synonyms, antonyms, homophones, and compound words.',
      allowedTopics: {
        'Word Study',
        'Synonyms',
        'Antonyms',
        'Homophones',
        'Compound Words',
        'Contractions',
      },
    );
  }
}
