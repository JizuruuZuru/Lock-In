import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

/// Updates (or creates) a leaderboard entry for the current user.
/// Only keeps the highest score per user per game.
Future<void> updateLeaderboardEntry({
  required String gameName,
  required int newScore,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final firestore = FirebaseFirestore.instance;
  final userRef = firestore.collection('users').doc(user.uid);
  final userSnapshot = await userRef.get();
  final profile = userSnapshot.data();
  final username = _displayNameFromProfile(user, profile);
  final docId = '${user.uid}_$gameName';
  final docRef = firestore.collection('leaderboard_entries').doc(docId);

  await firestore.runTransaction((transaction) async {
    final snapshot = await transaction.get(docRef);
    if (snapshot.exists) {
      final existingScore = snapshot.get('score') as int;
      if (newScore <= existingScore) {
        return;
      }
    }
    transaction.set(docRef, {
      'userId': user.uid,
      'username': username,
      'fullName': username,
      'firstName': profile?['firstName'],
      'lastName': profile?['lastName'],
      'age': profile?['age'],
      'isAnonymous': user.isAnonymous,
      'game': gameName,
      'score': newScore,
      'timestamp': FieldValue.serverTimestamp(),
    });
  });
}
