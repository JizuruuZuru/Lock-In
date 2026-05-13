import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

String _displayNameFromProfile(
  User user,
  Map<String, dynamic>? profile,
) {
  final fullName = (profile?['fullName'] ?? '').toString().trim();
  if (fullName.isNotEmpty) return fullName;

  final firstName = (profile?['firstName'] ?? '').toString().trim();
  final lastName = (profile?['lastName'] ?? '').toString().trim();
  final combinedName = '$firstName $lastName'.trim();
  if (combinedName.isNotEmpty) return combinedName;

  final username = (profile?['username'] ?? '').toString().trim();
  if (username.isNotEmpty) return username;

  final displayName = user.displayName?.trim();
  if (displayName != null && displayName.isNotEmpty) return displayName;

  return user.email?.split('@').first ?? 'Player';
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
    final snapshot = await userRef.get();
    final profile = snapshot.data();
    final playerName = _displayNameFromProfile(user, profile);

    await userRef.collection('game_logs').doc(_currentSessionId).set({
      'score': score,
      'timestamp': Timestamp.now(),
      'game': gameName,
      'sessionId': _currentSessionId,
      'userId': user.uid,
      'username': playerName,
      'fullName': playerName,
      'firstName': profile?['firstName'],
      'lastName': profile?['lastName'],
      'age': profile?['age'],
      'isAnonymous': user.isAnonymous,
    }, SetOptions(merge: true));

    final highscore = snapshot.data()?['highscore'] ?? 0;
    await userRef.set({
      'email': user.email,
      'username': playerName,
      'fullName': playerName,
      'lastPlayedAt': FieldValue.serverTimestamp(),
      'games_played_count': FieldValue.increment(1),
      if (score > highscore) 'highscore': score,
    }, SetOptions(merge: true));
  }
}
