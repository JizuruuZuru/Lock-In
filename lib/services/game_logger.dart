import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

String _safeGameField(String gameName) {
  return gameName
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

class GameLogger {
  static String? _currentSessionId;
  static String? _currentGameName;

  static void startNewSession(String gameName) {
    _currentSessionId = const Uuid().v4();
    _currentGameName = gameName;
  }

  static void endSession() {
    _currentSessionId = null;
    _currentGameName = null;
  }

  /// Shared Firebase history logger for all games.
  /// This creates/updates one log document per active session to prevent duplicates.
  static Future<void> logGame({
    required String gameName,
    required int score,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_currentSessionId == null || _currentGameName != gameName) {
      startNewSession(gameName);
    }

    final firestore = FirebaseFirestore.instance;
    final userRef = firestore.collection('users').doc(user.uid);
    final now = FieldValue.serverTimestamp();
    final gameKey = _safeGameField(gameName);

    await userRef.collection('game_logs').doc(_currentSessionId).set({
      'game': gameName,
      'gameKey': gameKey,
      'score': score,
      'sessionId': _currentSessionId,
      'timestamp': now,
      'updatedAt': now,
    }, SetOptions(merge: true));

    final snapshot = await userRef.get();
    final data = snapshot.data();
    final currentGameHighscore = data?['${gameKey}_highscore'];
    final currentGlobalHighscore = data?['highscore'];
    final gameHighscore = currentGameHighscore is num ? currentGameHighscore.toInt() : 0;
    final globalHighscore = currentGlobalHighscore is num ? currentGlobalHighscore.toInt() : 0;

    await userRef.set({
      'last_game': gameName,
      'last_game_key': gameKey,
      'last_score': score,
      'last_played': now,
      'email': user.email,
      if (score > gameHighscore) '${gameKey}_highscore': score,
      if (score > globalHighscore) 'highscore': score,
    }, SetOptions(merge: true));
  }
}
