import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../data/subject_question_bank.dart';
import '../models/quiz_question_record.dart';
import 'local_question_cache.dart';
import 'question_repository.dart';

/// Where the questions currently in play came from.
enum QuestionSourceState {
  /// Nothing loaded yet.
  idle,

  /// Serving the on-device copy; Firestore has not answered this session.
  localCache,

  /// Serving fresh data straight from Firestore.
  live,
}

/// Keeps [SubjectQuestionBank]'s custom question pool in sync with the
/// `quiz_questions` collection, **offline first**.
///
/// Startup order matters and is deliberate:
///
///   1. [LocalQuestionCache] is read and applied to the bank. This needs no
///      network, so teacher-made questions are playable immediately — on a
///      plane, on school Wi-Fi that has dropped, or on a device that has not
///      been online since the questions were written.
///   2. A live Firestore listener is attached. When it delivers, the bank is
///      replaced with the fresh data and the on-device copy is rewritten.
///
/// If step 2 never succeeds the app keeps running on step 1's data rather than
/// silently falling back to only the bundled questions.
class CustomQuestionSync {
  CustomQuestionSync._();

  static final CustomQuestionSync instance = CustomQuestionSync._();

  final QuestionRepository _repository = QuestionRepository();
  final LocalQuestionCache _cache = LocalQuestionCache();

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  /// Number of published admin questions currently loaded into the bank.
  final ValueNotifier<int> loadedCount = ValueNotifier<int>(0);

  /// Set when the last sync attempt failed, so the UI can say the questions on
  /// screen may be stale instead of pretending everything is current.
  final ValueNotifier<String?> lastError = ValueNotifier<String?>(null);

  /// Whether the questions in play are live or came off the device.
  final ValueNotifier<QuestionSourceState> sourceState =
      ValueNotifier<QuestionSourceState>(QuestionSourceState.idle);

  /// When the on-device copy was last refreshed from Firestore.
  final ValueNotifier<DateTime?> lastSyncedAt = ValueNotifier<DateTime?>(null);

  bool get isListening => _subscription != null;

  /// Loads the cached questions, then attaches the live listener.
  /// Safe to call more than once.
  Future<void> start() async {
    if (_subscription != null) return;

    await loadFromCache();
    _listen();
  }

  /// Applies the on-device copy to the question bank. Never throws and never
  /// touches the network.
  Future<int> loadFromCache() async {
    final cached = await _cache.load();
    lastSyncedAt.value = await _cache.lastSyncedAt();

    if (cached.isEmpty) return 0;

    // Only claim the cache as the active source if Firestore has not already
    // delivered something fresher this session.
    _apply(cached, persist: false);
    if (sourceState.value != QuestionSourceState.live) {
      sourceState.value = QuestionSourceState.localCache;
    }
    return loadedCount.value;
  }

  void _listen() {
    _subscription = FirebaseFirestore.instance
        .collection(QuestionRepository.collectionPath)
        .where('published', isEqualTo: true)
        .snapshots()
        .listen(
      (snapshot) {
        final records =
            snapshot.docs.map(QuizQuestionRecord.fromSnapshot).toList();

        // Firestore replays its own cache before the server answers. Treat a
        // cached snapshot as cache, not as live data, so the UI does not claim
        // to be current while offline.
        final fromServer = !snapshot.metadata.isFromCache;

        // Mirror server data always. Also mirror a non-empty local snapshot,
        // so a question an admin wrote offline reaches the on-device copy —
        // but never let an *empty* cache snapshot wipe a good copy, which is
        // what a first launch with a cold Firestore cache would otherwise do.
        final shouldPersist = fromServer || records.isNotEmpty;

        _apply(records, persist: shouldPersist, markSynced: fromServer);
        sourceState.value = fromServer
            ? QuestionSourceState.live
            : QuestionSourceState.localCache;
        if (fromServer) lastError.value = null;
      },
      onError: (Object error) {
        lastError.value = _describe(error);
        // Keep whatever the cache already put in the bank.
        if (sourceState.value == QuestionSourceState.live) {
          sourceState.value = QuestionSourceState.localCache;
        }
      },
    );
  }

  /// One-shot refresh, used after an admin saves so the change is playable
  /// immediately rather than waiting on the listener.
  Future<int> refreshOnce() async {
    try {
      final records = await _repository.fetchPublished();
      _apply(records, persist: true);
      lastError.value = null;
      return loadedCount.value;
    } catch (error) {
      lastError.value = _describe(error);
      rethrow;
    }
  }

  void _apply(
    Iterable<QuizQuestionRecord> records, {
    required bool persist,
    bool markSynced = true,
  }) {
    final bySubject = <SubjectQuizType, List<LeveledQuizQuestion>>{
      for (final subject in SubjectQuizType.values)
        subject: <LeveledQuizQuestion>[],
    };

    final valid = <QuizQuestionRecord>[];
    for (final record in records) {
      // Never let a malformed document reach the game loop — a question with
      // no wrong answers would render an unanswerable screen.
      if (!record.isValid) continue;
      valid.add(record);
      bySubject[record.subject]!.add(
        LeveledQuizQuestion(
          minLevel: record.minLevel,
          question: record.toQuizQuestion(),
        ),
      );
    }

    SubjectQuestionBank.setCustomQuestions(bySubject);
    loadedCount.value = valid.length;

    if (persist) {
      // Fire and forget: the bank is already updated, and a slow disk write
      // must not delay the first question appearing.
      unawaited(
        _cache.save(valid, markSynced: markSynced).then((_) async {
          lastSyncedAt.value = await _cache.lastSyncedAt();
        }),
      );
    }
  }

  String _describe(Object error) {
    if (error is FirebaseException) {
      if (error.code == 'unavailable') {
        return 'You are offline. Showing the questions saved on this device.';
      }
      if (error.code == 'permission-denied') {
        return 'This account is not allowed to read the question bank.';
      }
      return error.message ?? 'Could not load teacher questions (${error.code}).';
    }
    return 'Could not load teacher questions.';
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    SubjectQuestionBank.clearCustomQuestions();
    loadedCount.value = 0;
    sourceState.value = QuestionSourceState.idle;
  }
}
