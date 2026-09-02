import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../data/subject_question_bank.dart';
import '../models/quiz_question_record.dart';

/// Thrown when a write is rejected before it reaches Firestore. The [errors]
/// map is the same `field -> message` shape the editor form renders.
class QuestionValidationException implements Exception {
  final Map<String, String> errors;

  const QuestionValidationException(this.errors);

  String get summary => errors.values.join('\n');

  @override
  String toString() => 'QuestionValidationException: $summary';
}

/// Whether a write reached the server or is waiting in the offline queue.
enum WriteSyncState { synced, queuedOffline }

/// Outcome of a single question write.
///
/// [id] is always usable — Firestore generates document ids on the client, so
/// a question created offline already has its permanent id.
class QuestionWriteResult {
  final String id;
  final WriteSyncState syncState;

  const QuestionWriteResult({required this.id, required this.syncState});

  bool get isPendingSync => syncState == WriteSyncState.queuedOffline;
}

/// Create / Read / Update / Delete for the `quiz_questions` collection.
///
/// Every write is validated through [QuizQuestionRecord.validate] first, so an
/// invalid question can never be persisted regardless of which screen calls in.
class QuestionRepository {
  static const String collectionPath = 'quiz_questions';

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  QuestionRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionPath);

  /// How long to wait for the server to acknowledge a write before treating it
  /// as queued offline.
  static const Duration serverAckTimeout = Duration(seconds: 4);

  /// Resolves a Firestore write into a [WriteSyncState].
  ///
  /// Firestore applies a write to its local cache immediately, but the Future
  /// it returns only completes once the **server** acknowledges it. With no
  /// network that acknowledgement never arrives, so awaiting it would leave
  /// the save button spinning forever even though the question is already
  /// stored locally and queued for sync.
  ///
  /// So the ack is given a short deadline. Past that the write is reported as
  /// pending — it is durable either way, and Firestore delivers it when the
  /// device reconnects.
  Future<WriteSyncState> _settle(Future<void> write) async {
    try {
      await write.timeout(serverAckTimeout);
      return WriteSyncState.synced;
    } on TimeoutException {
      // The write is still in flight. Attach a handler so a later failure
      // (say, a rules rejection on reconnect) does not surface as an
      // unhandled asynchronous error.
      unawaited(write.catchError((Object error) {
        debugPrint('Queued question write failed after reconnect: $error');
      }));
      return WriteSyncState.queuedOffline;
    }
  }

  // ---------------------------------------------------------------- CREATE

  /// Adds one question. Works offline: the id is generated on the client and
  /// the write is queued until the device reconnects.
  Future<QuestionWriteResult> create(QuizQuestionRecord record) async {
    final clean = record.sanitized();
    final errors = clean.validate();
    if (errors.isNotEmpty) throw QuestionValidationException(errors);

    // doc() (not add()) so the id exists before the server is involved.
    final doc = _collection.doc();
    final syncState = await _settle(doc.set({
      ...clean.toMap(),
      'createdBy': _auth.currentUser?.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }));

    return QuestionWriteResult(id: doc.id, syncState: syncState);
  }

  /// Bulk create used by the Open Trivia DB importer. Invalid rows are skipped
  /// rather than aborting the whole batch; the count of accepted rows is
  /// returned so the UI can report "imported 8 of 10".
  Future<int> createMany(List<QuizQuestionRecord> records) async {
    final uid = _auth.currentUser?.uid;
    final batch = _firestore.batch();
    var accepted = 0;

    for (final record in records) {
      final clean = record.sanitized();
      if (!clean.isValid) continue;
      batch.set(_collection.doc(), {
        ...clean.toMap(),
        'createdBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      accepted++;
    }

    if (accepted > 0) await _settle(batch.commit());
    return accepted;
  }

  // ------------------------------------------------------------------ READ

  /// Live list for the admin table. Filtering happens in the query only on a
  /// single equality field so no composite Firestore index is required; the
  /// ordering is applied client-side.
  Stream<List<QuizQuestionRecord>> watchQuestions({SubjectQuizType? subject}) {
    Query<Map<String, dynamic>> query = _collection;
    if (subject != null) {
      query = query.where('subject', isEqualTo: subject.name);
    }
    return query.snapshots().map(_mapAndSort);
  }

  Future<List<QuizQuestionRecord>> fetchAll({SubjectQuizType? subject}) async {
    Query<Map<String, dynamic>> query = _collection;
    if (subject != null) {
      query = query.where('subject', isEqualTo: subject.name);
    }
    final snapshot = await query.get();
    return _mapAndSort(snapshot);
  }

  Future<QuizQuestionRecord?> fetchById(String id) async {
    final snapshot = await _collection.doc(id).get();
    if (!snapshot.exists) return null;
    return QuizQuestionRecord.fromSnapshot(snapshot);
  }

  /// Only the questions that should reach students.
  Future<List<QuizQuestionRecord>> fetchPublished() async {
    final snapshot = await _collection.where('published', isEqualTo: true).get();
    return _mapAndSort(snapshot);
  }

  /// [fetchPublished], but it also says whether Firestore actually reached the
  /// server or quietly served its local cache.
  ///
  /// A plain `.get()` succeeds offline by falling back to the cache, so a
  /// caller that only sees the records cannot tell a real refresh from a
  /// replay - which is how the admin dashboard came to report "synced just
  /// now" on a device with no connection.
  Future<({List<QuizQuestionRecord> records, bool fromCache})>
      fetchPublishedDetailed() async {
    final snapshot = await _collection.where('published', isEqualTo: true).get();
    return (
      records: _mapAndSort(snapshot),
      fromCache: snapshot.metadata.isFromCache,
    );
  }

  List<QuizQuestionRecord> _mapAndSort(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final records = snapshot.docs.map(QuizQuestionRecord.fromSnapshot).toList();
    records.sort((a, b) {
      final left = b.updatedAt ?? b.createdAt;
      final right = a.updatedAt ?? a.createdAt;
      if (left == null && right == null) return a.prompt.compareTo(b.prompt);
      if (left == null) return 1;
      if (right == null) return -1;
      return left.compareTo(right);
    });
    return records;
  }

  /// Prompt keys already stored, used to keep the importer from adding the
  /// same API question twice. Matches [SubjectQuestionBank.questionKey].
  Future<Set<String>> existingQuestionKeys() async {
    final snapshot = await _collection.get();
    return snapshot.docs
        .map(QuizQuestionRecord.fromSnapshot)
        .map((record) => SubjectQuestionBank.questionKey(record.toQuizQuestion()))
        .toSet();
  }

  // ---------------------------------------------------------------- UPDATE

  Future<QuestionWriteResult> update(QuizQuestionRecord record) async {
    if (record.id.isEmpty) {
      throw const QuestionValidationException({
        'id': 'This question has no id, so it cannot be updated.',
      });
    }
    final clean = record.sanitized();
    final errors = clean.validate();
    if (errors.isNotEmpty) throw QuestionValidationException(errors);

    final syncState = await _settle(_collection.doc(record.id).update({
      ...clean.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }));

    return QuestionWriteResult(id: record.id, syncState: syncState);
  }

  /// Toggles whether students can be served this question, without deleting it.
  Future<WriteSyncState> setPublished(String id, bool published) {
    return _settle(_collection.doc(id).update({
      'published': published,
      'updatedAt': FieldValue.serverTimestamp(),
    }));
  }

  // ---------------------------------------------------------------- DELETE

  Future<WriteSyncState> delete(String id) async {
    if (id.isEmpty) return WriteSyncState.synced;
    return _settle(_collection.doc(id).delete());
  }

  /// Deletes several questions in one batch (admin multi-select).
  Future<int> deleteMany(Iterable<String> ids) async {
    final targets = ids.where((id) => id.isNotEmpty).toList();
    if (targets.isEmpty) return 0;

    final batch = _firestore.batch();
    for (final id in targets) {
      batch.delete(_collection.doc(id));
    }
    await _settle(batch.commit());
    return targets.length;
  }
}
