import 'package:flutter/material.dart';

import '../../data/subject_question_bank.dart';
import '../shared/subject_quiz_game.dart';

class EnglishSubjectVerbAgreementGame extends StatelessWidget {
  const EnglishSubjectVerbAgreementGame({super.key});

  @override
  Widget build(BuildContext context) {
    return const SubjectQuizGame(
      subject: SubjectQuizType.english,
      lessonTitle: 'Subject-Verb Agreement',
      lessonDescription:
          'Sentence-level grammar: match subjects with the correct verb, and find direct and indirect objects.',
      lessonTopicsSummary:
          'Subject-verb agreement and direct and indirect objects.',
      allowedTopics: {
        'Subject-Verb Agreement',
        'Direct and Indirect Objects',
      },
    );
  }
}
