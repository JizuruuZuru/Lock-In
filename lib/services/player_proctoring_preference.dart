import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'proctoring_settings.dart';

/// The player's own answer to "may the camera watch me while I play?".
///
/// This is the half of proctoring the *student* controls. [ProctoringSettings]
/// stays the teacher-owned gate: when a teacher has the camera switched off for
/// exams or lessons, nothing here can switch it back on. Within what the
/// teacher allows, a player may decline - and the score they set is written to
/// the leaderboard as unwatched, so declining is visible rather than secret.
/// That visibility is what makes an opt-out safe for an anti-cheat feature.
///
/// Stored per uid rather than per device, for the same reason the leaderboard's
/// player-name cache is keyed by uid: two children sharing one tablet must not
/// inherit each other's answer. It is a plain `shared_preferences` value and
/// never touches the network, so a game screen can read it on its first frame.
class PlayerProctoringPreference {
  PlayerProctoringPreference._();

  static final PlayerProctoringPreference instance =
      PlayerProctoringPreference._();

  /// Test seam: a fresh instance with an injectable preference store.
  @visibleForTesting
  PlayerProctoringPreference.forTesting({
    Future<SharedPreferences> Function()? preferences,
  }) : _preferences = preferences ?? SharedPreferences.getInstance;

  /// The uid is appended, so `lockin.face_proctor_opt_in.v1.<uid>`.
  static const String keyPrefix = 'lockin.face_proctor_opt_in.v1.';

  Future<SharedPreferences> Function() _preferences =
      SharedPreferences.getInstance;

  /// Whose answer [optedIn] currently holds. Null before anyone has signed in.
  String? _uid;

  /// Defaults to on, matching [ProctoringConfig.defaults]: an anti-cheat
  /// feature must not switch itself off because a read failed or because nobody
  /// has answered yet.
  final ValueNotifier<bool> optedIn = ValueNotifier<bool>(true);

  String? get loadedUid => _uid;

  static String keyFor(String uid) => '$keyPrefix$uid';

  /// Reads this player's saved answer. Never throws and never touches the
  /// network - a device with no usable preference store just gets the default.
  Future<void> loadFor(String uid) async {
    _uid = uid;
    try {
      final prefs = await _preferences();
      // A uid that has never answered keeps the default rather than being
      // written to disk, so "never asked" and "asked, said yes" stay the same
      // thing until the player actually touches the switch.
      optedIn.value = prefs.getBool(keyFor(uid)) ?? true;
    } catch (error) {
      debugPrint('Could not read the camera preference: $error');
      optedIn.value = true;
    }
  }

  /// Applies the player's choice immediately, then persists it. The switch must
  /// not wait on a disk write, and a failed write costs nothing worse than the
  /// choice not sticking to the next launch.
  Future<void> setOptedIn(bool value) async {
    optedIn.value = value;
    final uid = _uid;
    if (uid == null) return;
    try {
      final prefs = await _preferences();
      await prefs.setBool(keyFor(uid), value);
    } catch (error) {
      debugPrint('Could not save the camera preference: $error');
    }
  }

  /// Back to the default at sign-out, so one account's answer is not still in
  /// force for whoever signs in next on a shared classroom device.
  void reset() {
    _uid = null;
    optedIn.value = true;
  }
}

/// Is the front camera going to watch this run?
///
/// Both halves have to agree: the teacher's switch for this kind of activity,
/// and the player's own answer. This is the single expression every game screen
/// asks, so the two settings can never drift apart at one call site.
bool faceProctorEnabledFor({required bool isExam}) =>
    ProctoringSettings.instance.enabledFor(isExam: isExam) &&
    PlayerProctoringPreference.instance.optedIn.value;
