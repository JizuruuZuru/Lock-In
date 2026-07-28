import 'package:flutter/material.dart';

import '../../data/subject_question_bank.dart';
import '../shared/subject_quiz_game.dart';

class EnglishNounsAndPronounsGame extends StatelessWidget {
  const EnglishNounsAndPronounsGame({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubjectQuizGame(
      subject: SubjectQuizType.english,
      lessonTitle: 'Nouns and Pronouns',
      lessonDescription:
          'Word-level grammar: identify nouns, plural and possessive forms, and pronouns.',
      lessonTopicsSummary:
          'Nouns, plural nouns, possessive nouns, and pronouns.',
      allowedTopics: {
        'Nouns',
        'Plural Nouns',
        'Possessive Nouns',
        'Pronouns',
      },
    );
  }
}
