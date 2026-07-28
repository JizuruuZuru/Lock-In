import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

String _safeGameId(String gameName) {
  return gameName
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

Future<String> _currentPlayerName(User user) async {
  final firestore = FirebaseFirestore.instance;
  final userDoc = await firestore.collection('users').doc(user.uid).get();
  final data = userDoc.data();

  final fullName = data?['fullName']?.toString().trim();
  final username = data?['username']?.toString().trim();
  final firstName = data?['firstName']?.toString().trim();
  final lastName = data?['lastName']?.toString().trim();

  if (fullName != null && fullName.isNotEmpty) return fullName;
  if (username != null && username.isNotEmpty) return username;
  if ((firstName != null && firstName.isNotEmpty) ||
      (lastName != null && lastName.isNotEmpty)) {
    return [firstName, lastName]
        .where((part) => part != null && part.isNotEmpty)
        .join(' ');
  }
  if ((user.displayName ?? '').trim().isNotEmpty) return user.displayName!.trim();
  if (user.email != null && user.email!.isNotEmpty) {
    return user.email!.split('@').first;
  }
  return 'Player';
}

/// Updates or creates one leaderboard entry per user per game.
/// All games should call this after score save.
Future<void> updateLeaderboardEntry({
  required String gameName,
  required int newScore,
  String? difficulty,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  if (newScore <= 0) return;

  final firestore = FirebaseFirestore.instance;
  final playerName = await _currentPlayerName(user);
  final safeGameId = _safeGameId(gameName);
  final docId = '${user.uid}_$safeGameId';
  final docRef = firestore.collection('leaderboard_entries').doc(docId);

  await firestore.runTransaction((transaction) async {
    final snapshot = await transaction.get(docRef);
    if (snapshot.exists) {
      final data = snapshot.data();
      final existingScore = data?['score'];
      final scoreToBeat = existingScore is num ? existingScore.toInt() : 0;
      if (newScore <= scoreToBeat) {
        transaction.set(
          docRef,
          {
            'username': playerName,
            'fullName': playerName,
            'lastSeenAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        return;
      }
    }

    transaction.set(
      docRef,
      {
        'userId': user.uid,
        'username': playerName,
        'fullName': playerName,
        'game': gameName,
        'gameKey': safeGameId,
        'score': newScore,
        if (difficulty != null) 'difficulty': difficulty,
        'timestamp': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  });
}
