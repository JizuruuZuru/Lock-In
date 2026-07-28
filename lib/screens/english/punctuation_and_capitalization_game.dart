import 'package:flutter/material.dart';

import '../../data/subject_question_bank.dart';
import '../shared/subject_quiz_game.dart';

class EnglishPunctuationAndCapitalizationGame extends StatelessWidget {
  const EnglishPunctuationAndCapitalizationGame({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubjectQuizGame(
      subject: SubjectQuizType.english,
      lessonTitle: 'Punctuation and Capitalization',
      lessonDescription:
          'Sentence-level grammar: practice capital letters, end punctuation, and commas.',
      lessonTopicsSummary: 'Capitalization, punctuation, and commas.',
      allowedTopics: {
        'Capitalization',
        'Punctuation',
        'Commas',
      },
    );
  }
}
