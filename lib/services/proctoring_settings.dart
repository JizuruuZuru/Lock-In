import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which activities the front-camera proctor watches.
@immutable
class ProctoringConfig {
  /// Watch during Exam mode.
  final bool faceProctorExams;

  /// Watch during the practice lessons (the 11 non-exam games).
  final bool faceProctorLessons;

  const ProctoringConfig({
    this.faceProctorExams = true,
    this.faceProctorLessons = true,
  });

  /// Both on - which is exactly how the app behaved before this setting
  /// existed, and the right way to fail when nothing is known yet. An
  /// anti-cheat feature should not switch itself off because a read failed.
  static const ProctoringConfig defaults = ProctoringConfig();

  /// The flag that applies to a given screen.
  bool enabledFor({required bool isExam}) =>
      isExam ? faceProctorExams : faceProctorLessons;

  ProctoringConfig copyWith({bool? faceProctorExams, bool? faceProctorLessons}) {
    return ProctoringConfig(
      faceProctorExams: faceProctorExams ?? this.faceProctorExams,
      faceProctorLessons: faceProctorLessons ?? this.faceProctorLessons,
    );
  }

  Map<String, Object?> toJson() => {
        'faceProctorExams': faceProctorExams,
        'faceProctorLessons': faceProctorLessons,
      };

  /// Anything missing or non-boolean falls back to the default rather than to
  /// `false`, so a half-written document cannot silently disable proctoring
  /// everywhere.
  factory ProctoringConfig.fromMap(Map<String, dynamic>? data) {
    bool read(String key, bool fallback) {
      final value = data?[key];
      return value is bool ? value : fallback;
    }

    return ProctoringConfig(
      faceProctorExams: read('faceProctorExams', defaults.faceProctorExams),
      faceProctorLessons:
          read('faceProctorLessons', defaults.faceProctorLessons),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ProctoringConfig &&
      other.faceProctorExams == faceProctorExams &&
      other.faceProctorLessons == faceProctorLessons;

  @override
  int get hashCode => Object.hash(faceProctorExams, faceProctorLessons);

  @override
  String toString() =>
      'ProctoringConfig(exams: $faceProctorExams, lessons: $faceProctorLessons)';
}

/// Where the settings currently in force came from.
enum ProctoringSource { idle, localCache, live }

/// The teacher-owned switch for front-camera proctoring.
///
/// Deliberately **not** a per-device preference. Proctoring is an anti-cheat
/// feature, so a control the student can reach would defeat it - this lives in
/// Firestore under `app_config/proctoring`, is writable only by an admin (see
/// `firestore.rules`), and applies to every device at once.
///
/// Start-up mirrors `CustomQuestionSync`: the on-device copy is applied first
/// so a game can start with the right setting on the very first frame and with
/// no network, then a live listener takes over. The local mirror exists for the
/// same reasons the question cache does - the web has no Firestore cache unless
/// persistence is on, a cold first launch has nothing cached at all, and
/// Firestore evicts under its size budget.
class ProctoringSettings {
  ProctoringSettings._();

  static final ProctoringSettings instance = ProctoringSettings._();

  /// Test seam: a fresh instance with an injectable preference store.
  @visibleForTesting
  ProctoringSettings.forTesting({
    Future<SharedPreferences> Function()? preferences,
  }) : _preferences = preferences ?? SharedPreferences.getInstance;

  static const String collectionPath = 'app_config';
  static const String documentId = 'proctoring';
  static const String cacheKey = 'lockin.proctoring_settings.v1';
  static const String syncedAtKey = 'lockin.proctoring_settings.synced_at.v1';

  Future<SharedPreferences> Function() _preferences =
      SharedPreferences.getInstance;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subscription;

  /// The in-flight [start], so concurrent callers join it rather than each
  /// attaching their own listener - the same race `CustomQuestionSync.start`
  /// had to be fixed for.
  Future<void>? _starting;

  /// The settings in force right now. Games and the admin page both watch this.
  final ValueNotifier<ProctoringConfig> config =
      ValueNotifier<ProctoringConfig>(ProctoringConfig.defaults);

  final ValueNotifier<ProctoringSource> source =
      ValueNotifier<ProctoringSource>(ProctoringSource.idle);

  final ValueNotifier<DateTime?> lastSyncedAt = ValueNotifier<DateTime?>(null);

  final ValueNotifier<String?> lastError = ValueNotifier<String?>(null);

  bool get isListening => _subscription != null;

  /// Convenience for a game screen: is proctoring wanted here?
  bool enabledFor({required bool isExam}) =>
      config.value.enabledFor(isExam: isExam);

  DocumentReference<Map<String, dynamic>> get _document =>
      FirebaseFirestore.instance.collection(collectionPath).doc(documentId);

  /// Applies the cached copy, then attaches the live listener.
  /// Safe to call more than once.
  Future<void> start() async {
    if (_subscription != null) return;
    final inFlight = _starting;
    if (inFlight != null) return inFlight;

    final future = _start();
    _starting = future;
    try {
      await future;
    } finally {
      _starting = null;
    }
  }

  Future<void> _start() async {
    await loadFromCache();
    if (_subscription != null) return;
    _listen();
  }

  /// Reads the on-device copy. Never throws and never touches the network.
  Future<void> loadFromCache() async {
    try {
      final prefs = await _preferences();
      lastSyncedAt.value = DateTime.tryParse(prefs.getString(syncedAtKey) ?? '');

      final raw = prefs.getString(cacheKey);
      if (raw == null || raw.isEmpty) return;

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;

      config.value = ProctoringConfig.fromMap(decoded);
      // Only claim the cache as the source if the server has not already
      // answered this session.
      if (source.value != ProctoringSource.live) {
        source.value = ProctoringSource.localCache;
      }
    } catch (error) {
      debugPrint('Proctoring settings cache unreadable, ignoring it: $error');
    }
  }

  void _listen() {
    _subscription = _document.snapshots().listen(
      (snapshot) {
        // Firestore replays its own cache before the server answers; treat a
        // cached snapshot as cache so the admin page cannot claim to be live
        // while offline.
        final fromServer = !snapshot.metadata.isFromCache;

        // A missing document is a valid state - it just means no admin has
        // saved yet - and it means the defaults apply.
        config.value = snapshot.exists
            ? ProctoringConfig.fromMap(snapshot.data())
            : ProctoringConfig.defaults;

        source.value =
            fromServer ? ProctoringSource.live : ProctoringSource.localCache;
        if (fromServer) {
          lastError.value = null;
          unawaited(writeCache(config.value));
        }
      },
      onError: (Object error) {
        lastError.value = _describe(error);
        // Keep whatever the cache already put in force.
        if (source.value == ProctoringSource.live) {
          source.value = ProctoringSource.localCache;
        }
      },
    );
  }

  /// Admin write. Throws on failure so the page can report it.
  Future<void> save(ProctoringConfig next) async {
    await _document.set({
      ...next.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': FirebaseAuth.instance.currentUser?.uid,
    }, SetOptions(merge: true));

    // Apply immediately rather than waiting for the listener to echo it back,
    // so the switch does not visibly snap back before the round trip lands.
    config.value = next;
    unawaited(writeCache(next));
  }

  @visibleForTesting
  Future<void> writeCache(ProctoringConfig value) async {
    try {
      final prefs = await _preferences();
      await prefs.setString(cacheKey, jsonEncode(value.toJson()));
      final now = DateTime.now();
      await prefs.setString(syncedAtKey, now.toIso8601String());
      lastSyncedAt.value = now;
    } catch (error) {
      debugPrint('Could not write the proctoring settings cache: $error');
    }
  }

  String _describe(Object error) {
    if (error is FirebaseException) {
      if (error.code == 'unavailable') {
        return 'You are offline. Using the settings saved on this device.';
      }
      if (error.code == 'permission-denied') {
        return 'This account is not allowed to read the proctoring settings.';
      }
      return error.message ??
          'Could not load proctoring settings (${error.code}).';
    }
    return 'Could not load proctoring settings.';
  }

  /// Detaches the listener and returns to the defaults.
  ///
  /// Called at sign-out for the same reason `CustomQuestionSync.stop` is: on a
  /// shared classroom device one account's settings must not stay in force for
  /// whoever signs in next.
  Future<void> stop() async {
    _starting = null;
    await _subscription?.cancel();
    _subscription = null;
    config.value = ProctoringConfig.defaults;
    source.value = ProctoringSource.idle;
    lastError.value = null;
  }
}
