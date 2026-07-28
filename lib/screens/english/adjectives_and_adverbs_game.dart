import 'package:flutter/material.dart';

import '../../data/subject_question_bank.dart';
import '../shared/subject_quiz_game.dart';

class EnglishAdjectivesAndAdverbsGame extends StatelessWidget {
  const EnglishAdjectivesAndAdverbsGame({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubjectQuizGame(
      subject: SubjectQuizType.english,
      lessonTitle: 'Adjectives and Adverbs',
      lessonDescription:
          'Word-level grammar: describe nouns with adjectives and verbs with adverbs.',
      lessonTopicsSummary:
          'Adjectives, comparative adjectives, and adverbs.',
      allowedTopics: {
        'Adjectives',
        'Comparative Adjectives',
        'Adverbs',
      },
    );
  }
}
