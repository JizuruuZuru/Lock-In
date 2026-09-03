import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/game_key.dart';

/// The display name resolved for each uid this session, keyed by uid so two
/// players on one device can never see each other's name.
///
/// Every game over used to re-read `users/{uid}` purely to find out what to
/// call the player. The name does not change mid-game, so it is looked up
/// once and reused; [resetPlayerNameCache] clears it at sign-out.
final Map<String, String> _playerNameCache = <String, String>{};

/// Clears the cached display names, so a name edited after sign-out is picked
/// up fresh on the next leaderboard write.
void resetPlayerNameCache() => _playerNameCache.clear();

Future<String> _currentPlayerName(User user) async {
  final cached = _playerNameCache[user.uid];
  if (cached != null) return cached;

  final firestore = FirebaseFirestore.instance;
  Map<String, dynamic>? data;
  var readSucceeded = false;
  try {
    final userDoc = await firestore.collection('users').doc(user.uid).get();
    data = userDoc.data();
    readSucceeded = true;
  } catch (_) {
    // Offline, or the read was refused. Fall back to whatever the auth record
    // itself can tell us rather than failing the leaderboard write - but do
    // not cache that guess, or one offline finish would pin a worse name for
    // the rest of the session.
    data = null;
  }

  final resolved = _nameFrom(user, data);
  if (readSucceeded) _playerNameCache[user.uid] = resolved;
  return resolved;
}

String _nameFrom(User user, Map<String, dynamic>? data) {
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
///
/// [proctored] is whether the front camera was watching the run that set this
/// score, and it is what the leaderboard's "Camera on / Camera off" badge
/// reads. Null means the run could not say - which is also what every row
/// written before the badge existed looks like - and those rows get no badge
/// rather than a wrong one.
Future<void> updateLeaderboardEntry({
  required String gameName,
  required int newScore,
  String? difficulty,
  bool? proctored,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  if (newScore <= 0) return;

  final firestore = FirebaseFirestore.instance;
  final playerName = await _currentPlayerName(user);
  final safeGameId = safeGameKey(gameName);
  final docId = '${user.uid}_$safeGameId';
  final docRef = firestore.collection('leaderboard_entries').doc(docId);

  // Deliberately no `proctored` here. The row describes the run that set the
  // stored best score, so a later, weaker run must not rewrite the badge on a
  // score it did not set - a player could otherwise turn the camera on, play
  // badly once, and relabel an unwatched high score as watched.
  Map<String, dynamic> touchOnly() => {
        'username': playerName,
        'fullName': playerName,
        'lastSeenAt': FieldValue.serverTimestamp(),
      };

  Map<String, dynamic> fullEntry() => {
        'userId': user.uid,
        'username': playerName,
        'fullName': playerName,
        'game': gameName,
        'gameKey': safeGameId,
        'score': newScore,
        if (difficulty != null) 'difficulty': difficulty,
        if (proctored != null) 'proctored': proctored,
        'timestamp': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  int scoreIn(Map<String, dynamic>? data) {
    final existing = data?['score'];
    return existing is num ? existing.toInt() : 0;
  }

  try {
    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (snapshot.exists && newScore <= scoreIn(snapshot.data())) {
        transaction.set(docRef, touchOnly(), SetOptions(merge: true));
        return;
      }

      transaction.set(docRef, fullEntry(), SetOptions(merge: true));
    });
  } on FirebaseException catch (error) {
    // A transaction needs the server, so offline it cannot complete - and
    // unlike a plain write it is not queued, so the score was simply lost.
    // GameLogger.logGame already solved this for the other half of the same
    // game-over path; this is the matching fallback. The read comes from the
    // local cache and the write is queued until the device reconnects. Not
    // atomic, but nothing concurrent can reach the document with no network.
    if (error.code != 'unavailable' && error.code != 'deadline-exceeded') {
      rethrow;
    }

    Map<String, dynamic>? cached;
    try {
      cached = (await docRef.get()).data();
    } catch (_) {
      cached = null;
    }

    final beatsStored = cached == null || newScore > scoreIn(cached);
    await docRef.set(
      beatsStored ? fullEntry() : touchOnly(),
      SetOptions(merge: true),
    );
  }
}
