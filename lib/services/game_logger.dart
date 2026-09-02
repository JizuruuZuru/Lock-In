import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../utils/game_key.dart';

class GameLogger {
  /// One session id per game, rather than one for the whole process.
  ///
  /// A single `_currentSessionId` collided whenever two game screens were
  /// alive at once: opening game B clobbered game A's id, and B's `dispose()`
  /// nulled it - so when A then logged its result it minted a *fresh* id and
  /// wrote a second `game_logs` document for what was one session, showing up
  /// as a duplicate row in the player's history.
  static final Map<String, String> _sessionIdByGame = <String, String>{};

  static void startNewSession(String gameName) {
    _sessionIdByGame[gameName] = const Uuid().v4();
  }

  /// Ends one game's session. Passing no name clears every session, which is
  /// only wanted on sign-out.
  static void endSession([String? gameName]) {
    if (gameName == null) {
      _sessionIdByGame.clear();
      return;
    }
    _sessionIdByGame.remove(gameName);
  }

  /// Shared Firebase history logger for all games.
  /// This creates/updates one log document per active session to prevent
  /// duplicates.
  ///
  /// [extraHighscoreFields] lets a caller fold its own "keep the larger value"
  /// fields - a per-lesson highscore, say - into the same transaction, rather
  /// than doing a second read-then-write against the same document.
  ///
  /// [extraFields] are merged as-is on every save - "last score", "last level"
  /// and similar latest-wins bookkeeping. They ride along in the same
  /// transaction as the highscores, which is what lets a caller drop the
  /// separate `users/{uid}` write it used to make right after this one.
  static Future<void> logGame({
    required String gameName,
    required int score,
    String? difficulty,
    Map<String, int> extraHighscoreFields = const <String, int>{},
    Map<String, Object?> extraFields = const <String, Object?>{},
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final sessionId = _sessionIdByGame[gameName] ??= const Uuid().v4();

    final firestore = FirebaseFirestore.instance;
    final userRef = firestore.collection('users').doc(user.uid);
    final now = FieldValue.serverTimestamp();
    final gameKey = safeGameKey(gameName);

    await userRef.collection('game_logs').doc(sessionId).set({
      'game': gameName,
      'gameKey': gameKey,
      'score': score,
      if (difficulty != null) 'difficulty': difficulty,
      'sessionId': sessionId,
      'timestamp': now,
      'updatedAt': now,
    }, SetOptions(merge: true));

    // Read and write in one transaction. Reading the document, comparing
    // highscores, then writing them back as two separate round trips loses an
    // update whenever a player finishes on two devices at once - and it cost
    // an extra read on every single game over.
    final candidates = <String, int>{
      '${gameKey}_highscore': score,
      'highscore': score,
      ...extraHighscoreFields,
    };

    try {
      await firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        final data = snapshot.data();

        transaction.set(
          userRef,
          {
            'last_game': gameName,
            'last_game_key': gameKey,
            'last_score': score,
            'last_played': now,
            'email': user.email,
            ...extraFields,
            for (final entry in candidates.entries)
              if (entry.value > _storedScore(data, entry.key)) entry.key: entry.value,
          },
          SetOptions(merge: true),
        );
      });
    } on FirebaseException catch (error) {
      // A transaction needs the server, so it cannot complete while offline.
      // Fall back to the read-then-write this used to do unconditionally: the
      // read is served from Firestore's local cache and the write is queued
      // until the device reconnects, so a highscore set on a school bus still
      // survives. It is not atomic, but nothing concurrent can reach the
      // document while there is no connection anyway.
      if (error.code != 'unavailable' && error.code != 'deadline-exceeded') {
        rethrow;
      }

      Map<String, dynamic>? cached;
      try {
        cached = (await userRef.get()).data();
      } catch (_) {
        // Nothing cached for this user yet. Every stored score reads as zero,
        // so the current run is written as the best - which is correct for a
        // document that does not exist.
        cached = null;
      }

      await userRef.set({
        'last_game': gameName,
        'last_game_key': gameKey,
        'last_score': score,
        'last_played': now,
        'email': user.email,
        ...extraFields,
        for (final entry in candidates.entries)
          if (entry.value > _storedScore(cached, entry.key)) entry.key: entry.value,
      }, SetOptions(merge: true));
    }
  }

  /// Reads a stored highscore field, treating anything missing or non-numeric
  /// as zero so a malformed document cannot block a new best score.
  static int _storedScore(Map<String, dynamic>? data, String field) {
    final value = data?[field];
    return value is num ? value.toInt() : 0;
  }
}
