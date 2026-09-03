import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../utils/game_key.dart';
import 'game_logger.dart';
import 'leaderboard_service.dart';

/// Records one finished run: the history log, the highscores, the per-game
/// "last played" fields, and the leaderboard entry.
///
/// Twelve game screens carried their own copy of this. Diffing two of them,
/// 26 of 37 lines differed - and every difference was mechanical: the game's
/// name and the `place_value_` / `rounding_numbers_` field prefix. Two had
/// already drifted (one hardcoded a local `gameName` instead of using the
/// screen's own getter, another skipped the leaderboard refresh on a non-best
/// run), which is what copies do.
///
/// The field prefix is derived with [safeGameKey], the helper that exists for
/// exactly that and which only two of the twelve callers were using.
///
/// It is also one round trip cheaper than the code it replaces. Each copy did
/// `GameLogger.logGame` (which already opens a transaction on `users/{uid}`)
/// and then a *second* `set` on the same document for the "last score / last
/// level / last played" fields. Those now ride inside the transaction.
/// [storageKey] overrides the `users/{uid}` field prefix. It defaults to
/// [safeGameKey] of the game name, which is what almost every game already
/// stored under - but not all of them: "Order of Operations" has always written
/// `order_operations_*`, while `safeGameKey` yields `order_of_operations`.
/// Passing the existing prefix keeps a player's saved highscore attached to the
/// game instead of silently orphaning it under a new field name.
Future<void> saveGameResult({
  required String gameName,
  required int score,
  required int level,
  String? difficulty,
  String? storageKey,
  bool? proctored,
  Map<String, int> extraHighscoreFields = const <String, int>{},
}) async {
  final key = storageKey ?? safeGameKey(gameName);

  await GameLogger.logGame(
    gameName: gameName,
    score: score,
    difficulty: difficulty,
    proctored: proctored,
    extraHighscoreFields: {
      '${key}_highscore': score,
      ...extraHighscoreFields,
    },
    extraFields: {
      if (proctored != null) '${key}_last_proctored': proctored,
      '${key}_last_score': score,
      '${key}_last_level': level,
      '${key}_last_played': FieldValue.serverTimestamp(),
    },
  );

  // A zero score is a run the player abandoned or lost immediately; it should
  // not create a leaderboard row. `updateLeaderboardEntry` guards this too, but
  // saying so here keeps the rule visible at the call site.
  if (score > 0) {
    await updateLeaderboardEntry(
      gameName: gameName,
      newScore: score,
      difficulty: difficulty,
    );
  }
}

/// Serialises the saves for one game screen.
///
/// Every screen had a bare `if (_isSavingScore) return;` guard, which quietly
/// turned into a data-loss path: a heart loss fires an unawaited save, and if
/// the player hits back immediately the awaited save on the way out returned
/// instantly *without saving*. Callers now join the in-flight save instead of
/// dropping theirs.
class GameSaveGate {
  Future<void>? _inFlight;

  /// Whether a save is in flight, for a button that should show a spinner.
  bool get isSaving => _inFlight != null;

  /// Runs [save] unless one is already running, in which case this waits for
  /// that one rather than skipping.
  Future<void> run(Future<void> Function() save) {
    final running = _inFlight;
    if (running != null) return running;

    final future = save().catchError((Object error) {
      debugPrint('saveGameResult failed: $error');
    }).whenComplete(() => _inFlight = null);

    _inFlight = future;
    return future;
  }
}
