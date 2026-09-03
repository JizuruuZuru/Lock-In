import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ExamFirestoreService {
  final FirebaseFirestore _firestore;

  ExamFirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> logAttempt({
    required String gameName,
    required String difficulty,
    required List<String> selectedSubjects,
    required String subject,
    required String topic,
    required String prompt,
    required String correctAnswer,
    required String submittedAnswer,
    required bool isCorrect,
    required int score,
    required int level,
    bool? proctored,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('exam_attempts').add({
        'uid': user.uid,
        'gameName': gameName,
        'difficulty': difficulty,
        'selectedSubjects': selectedSubjects,
        'subject': subject,
        'topic': topic,
        'prompt': prompt,
        'correctAnswer': correctAnswer,
        'submittedAnswer': submittedAnswer,
        'isCorrect': isCorrect,
        'score': score,
        'level': level,
        if (proctored != null) 'proctored': proctored,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      debugPrint('Exam attempt logging failed: $error');
    }
  }

  Future<void> saveSession({
    required String gameName,
    required String difficulty,
    required List<String> selectedSubjects,
    required int score,
    required int level,
    required int hearts,
    required int attempts,
    bool? proctored,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('exam_sessions').add({
        'uid': user.uid,
        'gameName': gameName,
        'difficulty': difficulty,
        'selectedSubjects': selectedSubjects,
        'score': score,
        'level': level,
        'hearts': hearts,
        'attempts': attempts,
        if (proctored != null) 'proctored': proctored,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      debugPrint('Exam session save failed: $error');
    }
  }
}
