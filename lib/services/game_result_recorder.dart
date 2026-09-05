import 'dart:async';

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
      proctored: proctored,
    );
  }
}

/// Runs a save that must not hold up leaving a screen.
///
/// A Firestore write future only completes when the **server** acknowledges
/// it. With no connection that acknowledgement never arrives, so awaiting one
/// never returns - the same trap `AppGate` documents for its `lastSeenAt`
/// write, and `QuestionRepository._settle` solves for the admin forms.
///
/// Every exit path in the games awaited exactly that before navigating: the
/// exit confirmation's Leave button, the back arrow, and the security
/// overlay's Leave. Offline, all three simply stopped responding - the tap did
/// nothing at all, with no spinner and no error, for as long as the device
/// stayed offline.
///
/// Nothing is lost by giving up on the acknowledgement: the write is applied
/// to Firestore's local cache the instant it is issued and is delivered on
/// reconnect. The deadline is generous enough that a healthy connection still
/// finishes first, so online behaviour is unchanged.
Future<void> saveBeforeLeaving(
  Future<void> Function() save, {
  Duration deadline = const Duration(seconds: 3),
}) async {
  final Future<void> pending;
  try {
    pending = save();
  } catch (error) {
    // A synchronous throw before any future existed.
    debugPrint('Save before leaving could not start: $error');
    return;
  }

  try {
    await pending.timeout(deadline);
  } on TimeoutException {
    // Still in flight. Keep a handler on it so a later failure - a rules
    // rejection on reconnect, say - does not surface as an unhandled
    // asynchronous error long after the screen has gone.
    unawaited(pending.catchError((Object error) {
      debugPrint('Queued save failed after leaving: $error');
    }));
  } catch (error) {
    debugPrint('Save before leaving failed: $error');
  }
}

/// Serialises the saves for one game screen.
///
/// Every screen had a bare `if (_isSavingScore) return;` guard, which quietly
/// turned into a data-loss path: a heart loss fires an unawaited save, and if
/// the player hits back immediately the awaited save on the way out returned
/// instantly *without saving*. Callers are now queued behind the running save
/// rather than dropped - or, as an earlier version of this class did, handed
/// the running save's future, which waits without ever saving their data.
class GameSaveGate {
  Future<void>? _inFlight;

  /// Whether a save is in flight, for a button that should show a spinner.
  bool get isSaving => _inFlight != null;

  /// Runs [save], queued behind any save already in flight.
  ///
  /// Returning the in-flight future instead - which is what this did - is not
  /// the same as saving: the newer call's `save` was never invoked, so its
  /// score was dropped exactly as the bare `if (_isSaving) return;` guard used
  /// to drop it, just with a longer wait first. Offline that window is tens of
  /// seconds, which is long enough for a player to climb from 3 to 50 and have
  /// only the 3 recorded.
  ///
  /// Chaining keeps the writes ordered - they touch the same document - while
  /// making sure every caller's data actually reaches Firestore.
  Future<void> run(Future<void> Function() save) {
    final running = _inFlight;

    Future<void> next() => save().catchError((Object error) {
          debugPrint('saveGameResult failed: $error');
        });

    final future = running == null ? next() : running.then((_) => next());

    final tracked = future.whenComplete(() {
      // Only the newest save clears the slot; an older one completing must not
      // hand the next caller an empty queue while this is still running.
      if (identical(_inFlight, future)) _inFlight = null;
    });

    _inFlight = future;
    return tracked;
  }
}
