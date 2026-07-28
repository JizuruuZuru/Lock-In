import 'package:flutter/material.dart';

import '../../data/subject_question_bank.dart';
import '../shared/subject_quiz_game.dart';

class EnglishVerbsAndTensesGame extends StatelessWidget {
  const EnglishVerbsAndTensesGame({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubjectQuizGame(
      subject: SubjectQuizType.english,
      lessonTitle: 'Verbs and Tenses',
      lessonDescription:
          'Word-level grammar: identify action and state verbs, and simple present, past, and future tense.',
      lessonTopicsSummary:
          'Verbs, simple present tense, simple past tense, and simple future tense.',
      allowedTopics: {
        'Verbs',
        'Simple Present Tense',
        'Simple Past Tense',
        'Simple Future Tense',
      },
    );
  }
}
