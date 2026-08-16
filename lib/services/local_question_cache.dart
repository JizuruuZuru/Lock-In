import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/quiz_question_record.dart';

/// On-device mirror of the admin-authored question bank.
///
/// Firestore keeps its own offline cache, but relying on it alone is not
/// enough for this app:
///
///  * on the web that cache is **off** unless persistence is enabled, and it
///    can be dropped whenever the browser clears site data;
///  * a cold start on a device that has never been online has nothing cached
///    at all;
///  * Firestore may evict cached documents once its size budget is reached.
///
/// So every successful sync also writes a plain JSON copy here. On launch the
/// copy is loaded into [SubjectQuestionBank] *before* Firestore is contacted,
/// which means teacher-made questions are playable offline immediately — even
/// on the very first frame, and even if the network never comes back.
class LocalQuestionCache {
  static const String questionsKey = 'lockin.custom_questions.v1';
  static const String syncedAtKey = 'lockin.custom_questions.synced_at.v1';

  /// Injected in tests; production uses [SharedPreferences.getInstance].
  final Future<SharedPreferences> Function() _preferences;

  LocalQuestionCache({Future<SharedPreferences> Function()? preferences})
      : _preferences = preferences ?? SharedPreferences.getInstance;

  /// Reads the cached questions. Returns an empty list when nothing has been
  /// cached yet, or when the stored payload is unreadable — a corrupt cache
  /// must never stop the app from starting.
  Future<List<QuizQuestionRecord>> load() async {
    try {
      final prefs = await _preferences();
      final raw = prefs.getString(questionsKey);
      if (raw == null || raw.isEmpty) return const [];

      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(QuizQuestionRecord.fromCacheJson)
          // Guard the game loop: a half-written record must never be served.
          .where((record) => record.isValid)
          .toList(growable: false);
    } catch (error) {
      debugPrint('Local question cache unreadable, ignoring it: $error');
      return const [];
    }
  }

  /// Replaces the cached copy. Called after every successful Firestore sync,
  /// including a sync that returns nothing, so deletions propagate to the
  /// cache instead of leaving deleted questions playable forever.
  ///
  /// [markSynced] stamps the "last synced" time. It is false when the data
  /// came from a local snapshot rather than the server, so the UI does not
  /// claim to be up to date while offline.
  Future<void> save(
    List<QuizQuestionRecord> records, {
    bool markSynced = true,
  }) async {
    try {
      final prefs = await _preferences();
      final payload = jsonEncode(
        records.map((record) => record.toCacheJson()).toList(growable: false),
      );
      await prefs.setString(questionsKey, payload);
      if (markSynced) {
        await prefs.setString(syncedAtKey, DateTime.now().toIso8601String());
      }
    } catch (error) {
      // A failed cache write is not worth interrupting the user for; the app
      // still works, it just will not have an offline copy this session.
      debugPrint('Could not write the local question cache: $error');
    }
  }

  /// When the cache was last refreshed from Firestore, or null if never.
  Future<DateTime?> lastSyncedAt() async {
    try {
      final prefs = await _preferences();
      final raw = prefs.getString(syncedAtKey);
      if (raw == null) return null;
      return DateTime.tryParse(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    try {
      final prefs = await _preferences();
      await prefs.remove(questionsKey);
      await prefs.remove(syncedAtKey);
    } catch (error) {
      debugPrint('Could not clear the local question cache: $error');
    }
  }
}
