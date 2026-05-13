import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LeaveAttemptLogger {
  static Future<void> logAttempt({
    required String gameName,
    required String reason,
    String source = 'leave_detector',
    Map<String, dynamic>? details,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final firestore = FirebaseFirestore.instance;
    final userRef = firestore.collection('users').doc(user.uid);
    final now = Timestamp.now();

    await userRef.collection('leave_attempts').add({
      'game': gameName,
      'reason': reason,
      'source': source,
      'timestamp': now,
      'enforcement': 'auto_restart',
      'auto_submit_after_leaves': 1,
      if (details != null) ...details,
    });

    final updateData = <String, dynamic>{
      'cheat_attempts_count': FieldValue.increment(1),
      'last_cheat_attempt_at': now,
      'last_cheated_game': gameName,
      'last_cheat_reason': reason,
      'last_cheat_source': source,
      'cheated_games': FieldValue.arrayUnion([gameName]),
      'email': user.email,
    };
    if (source == 'face_detector') {
      updateData['face_cheat_attempts_count'] = FieldValue.increment(1);
      updateData['last_face_cheat_at'] = now;
    } else {
      updateData['leave_attempts_count'] = FieldValue.increment(1);
      updateData['last_leave_attempt_at'] = now;
    }

    await userRef.set(
      updateData,
      SetOptions(merge: true),
    );
  }
}
