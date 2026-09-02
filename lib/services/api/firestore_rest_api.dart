import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../data/subject_question_bank.dart';
import '../../models/quiz_question_record.dart';
import '../../utils/firebase_options.dart';
import '../question_repository.dart';
import 'api_exception.dart';

/// Outcome of a bulk publish, so the UI can report partial success honestly.
class RestPublishResult {
  final List<String> createdIds;
  final List<String> failures;
  final String lastRequestUrl;
  final String lastRequestBody;
  final String lastResponseBody;

  const RestPublishResult({
    required this.createdIds,
    required this.failures,
    this.lastRequestUrl = '',
    this.lastRequestBody = '',
    this.lastResponseBody = '',
  });

  int get successCount => createdIds.length;
  int get failureCount => failures.length;
  bool get hasFailures => failures.isNotEmpty;
}

/// One HTTP exchange, kept verbatim so the admin API console and the smoke-test
/// script can show the real traffic instead of a summary of it.
class RestCallLog {
  final String method;
  final String url;
  final String requestBody;
  final String responseBody;
  final int statusCode;

  const RestCallLog({
    required this.method,
    required this.url,
    this.requestBody = '',
    this.responseBody = '',
    this.statusCode = 0,
  });

  /// `PATCH https://... -> 200`, the one-line form used in list rows and logs.
  String get summary => '$method $url -> $statusCode';
}

/// A [runQuestionQuery] result plus the exchange that produced it.
class RestQueryResult {
  final List<QuizQuestionRecord> questions;
  final RestCallLog log;

  const RestQueryResult({required this.questions, required this.log});
}

/// HTTP client for the **Cloud Firestore REST API** — the project's own
/// backend, reached over plain HTTPS instead of through the Firestore SDK.
///
/// This is where the app's `POST` requests live:
///  * `POST /v1/projects/{project}/databases/(default)/documents/quiz_questions`
///    — creates a question document (used when publishing an API import).
///  * `POST /v1/projects/{project}/databases/(default)/documents:runQuery`
///    — runs a structured query; Firestore models search as a POST because the
///    query travels in the request body.
///
/// Requests are authenticated with the signed-in user's Firebase ID token, so
/// the same security rules that guard the SDK also guard these calls.
class FirestoreRestApi {
  static const String host = 'firestore.googleapis.com';
  static const Duration timeout = Duration(seconds: 20);

  final http.Client _client;

  /// Left null in tests. Resolved lazily through [_auth] so constructing this
  /// service never requires Firebase to have been initialized.
  final FirebaseAuth? _authOverride;

  /// Test seam. When supplied it replaces the Firebase ID token lookup, which
  /// is what lets the whole REST surface be exercised against a [MockClient]
  /// with no Firebase app running.
  final Future<String> Function()? _tokenProvider;

  /// Test seam for the `createdBy` stamp, paired with [_tokenProvider].
  final String? _uidOverride;

  final String projectId;

  FirestoreRestApi({
    http.Client? client,
    FirebaseAuth? auth,
    String? projectId,
    Future<String> Function()? tokenProvider,
    String? uid,
  })  : _client = client ?? http.Client(),
        _authOverride = auth,
        _tokenProvider = tokenProvider,
        _uidOverride = uid,
        projectId = projectId ?? DefaultFirebaseOptions.currentPlatform.projectId;

  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

  /// The signed-in uid, or null when nobody is signed in. Never throws, so a
  /// missing session degrades the `createdBy` stamp instead of the write.
  String? get _currentUid {
    if (_uidOverride != null) return _uidOverride;
    try {
      return _auth.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  String get _documentsPath => '/v1/projects/$projectId/databases/(default)/documents';

  /// Human-readable base URL, shown in the admin screen so the endpoint being
  /// called is visible rather than hidden in code.
  String get documentsBaseUrl => 'https://$host$_documentsPath';

  // ------------------------------------------------------------------ POST

  /// Creates one question document via HTTP POST and returns its new id.
  Future<String> createQuestion(QuizQuestionRecord record) async {
    final result = await createQuestionDetailed(record);
    return result.createdIds.first;
  }

  /// Same as [createQuestion] but also returns the exact request/response
  /// bodies so the admin screen can display a genuine JSON sample.
  Future<RestPublishResult> createQuestionDetailed(QuizQuestionRecord record) async {
    final clean = record.sanitized();
    final errors = clean.validate();
    if (errors.isNotEmpty) {
      throw ApiException(errors.values.first);
    }

    final uri = Uri.https(host, '$_documentsPath/${QuizQuestionRestCodec.collectionId}');
    final body = jsonEncode({'fields': QuizQuestionRestCodec.toFields(clean, _currentUid)});

    final response = await _post(uri, body);
    final json = _decodeObject(response.body);
    final name = (json['name'] ?? '').toString();
    final id = name.isEmpty ? '' : name.split('/').last;

    if (id.isEmpty) {
      throw const ApiException('Firestore accepted the write but returned no document id.');
    }

    return RestPublishResult(
      createdIds: [id],
      failures: const [],
      lastRequestUrl: uri.toString(),
      lastRequestBody: const JsonEncoder.withIndent('  ')
          .convert(jsonDecode(body)),
      lastResponseBody: const JsonEncoder.withIndent('  ').convert(json),
    );
  }

  /// Publishes a whole batch one POST at a time, collecting per-row failures
  /// instead of aborting so one bad row cannot lose the rest of the import.
  Future<RestPublishResult> createQuestions(List<QuizQuestionRecord> records) async {
    final createdIds = <String>[];
    final failures = <String>[];
    var lastUrl = '';
    var lastRequest = '';
    var lastResponse = '';

    for (final record in records) {
      try {
        final result = await createQuestionDetailed(record);
        createdIds.addAll(result.createdIds);
        lastUrl = result.lastRequestUrl;
        lastRequest = result.lastRequestBody;
        lastResponse = result.lastResponseBody;
      } catch (error) {
        final label = record.prompt.length > 60
            ? '${record.prompt.substring(0, 60)}…'
            : record.prompt;
        failures.add('$label — ${ApiException.from(error).message}');
      }
    }

    return RestPublishResult(
      createdIds: createdIds,
      failures: failures,
      lastRequestUrl: lastUrl,
      lastRequestBody: lastRequest,
      lastResponseBody: lastResponse,
    );
  }

  // ----------------------------------------------------------------- PATCH

  /// Updates one question document via **HTTP PATCH**.
  ///
  /// Firestore models a partial update as `PATCH` with an `updateMask` naming
  /// exactly which fields may change. Everything not on the mask is left
  /// untouched, which is how `createdAt` and `createdBy` survive an edit.
  Future<RestCallLog> updateQuestion(QuizQuestionRecord record) async {
    if (record.id.trim().isEmpty) {
      throw const ApiException('This question has no id, so it cannot be updated.');
    }

    final clean = record.sanitized();
    final errors = clean.validate();
    if (errors.isNotEmpty) {
      throw ApiException(errors.values.first);
    }

    final fields = QuizQuestionRestCodec.toUpdateFields(clean);
    final uri = Uri.https(
      host,
      '$_documentsPath/${QuizQuestionRestCodec.collectionId}/${record.id.trim()}',
      // Uri.https takes a Map, so a repeated key needs the List form.
      {'updateMask.fieldPaths': fields.keys.toList(growable: false)},
    );
    final body = jsonEncode({'fields': fields});

    final response = await _send('PATCH', uri, body: body);

    return RestCallLog(
      method: 'PATCH',
      url: uri.toString(),
      requestBody: _pretty(body),
      responseBody: _pretty(response.body),
      statusCode: response.statusCode,
    );
  }

  /// Publishes or hides a question over HTTP PATCH, touching only the two
  /// fields involved rather than rewriting the whole document.
  Future<RestCallLog> setPublished(String id, bool published) async {
    if (id.trim().isEmpty) {
      throw const ApiException('This question has no id, so it cannot be updated.');
    }

    final fields = <String, dynamic>{
      'published': {'booleanValue': published},
      'updatedAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
    };
    final uri = Uri.https(
      host,
      '$_documentsPath/${QuizQuestionRestCodec.collectionId}/${id.trim()}',
      {'updateMask.fieldPaths': fields.keys.toList(growable: false)},
    );
    final body = jsonEncode({'fields': fields});

    final response = await _send('PATCH', uri, body: body);

    return RestCallLog(
      method: 'PATCH',
      url: uri.toString(),
      requestBody: _pretty(body),
      responseBody: _pretty(response.body),
      statusCode: response.statusCode,
    );
  }

  // ---------------------------------------------------------------- DELETE

  /// Removes one question document via **HTTP DELETE**.
  ///
  /// Firestore answers a successful delete with `200` and an empty JSON object,
  /// so there is no body to parse — the status code is the result.
  Future<RestCallLog> deleteQuestion(String id) async {
    if (id.trim().isEmpty) {
      throw const ApiException('This question has no id, so it cannot be deleted.');
    }

    final uri = Uri.https(
      host,
      '$_documentsPath/${QuizQuestionRestCodec.collectionId}/${id.trim()}',
    );

    final response = await _send('DELETE', uri);

    return RestCallLog(
      method: 'DELETE',
      url: uri.toString(),
      responseBody: response.body.trim().isEmpty ? '{}' : _pretty(response.body),
      statusCode: response.statusCode,
    );
  }

  // ------------------------------------------------------------------ POST

  /// Structured query over HTTP POST (`documents:runQuery`).
  ///
  /// Firestore models search as a POST because the query travels in the request
  /// body. Driven from the admin API console, it is how the app *reads* through
  /// the REST API rather than only writing through it.
  Future<List<QuizQuestionRecord>> runQuestionQuery({
    SubjectQuizType? subject,
    bool? publishedOnly,
    int limit = 50,
  }) async {
    final result = await runQuestionQueryDetailed(
      subject: subject,
      publishedOnly: publishedOnly,
      limit: limit,
    );
    return result.questions;
  }

  /// Same query, but also returns the exchange so the console can show it.
  Future<RestQueryResult> runQuestionQueryDetailed({
    SubjectQuizType? subject,
    bool? publishedOnly,
    int limit = 50,
  }) async {
    final uri = Uri.https(host, '$_documentsPath:runQuery');

    final filters = <Map<String, dynamic>>[
      if (subject != null)
        {
          'fieldFilter': {
            'field': {'fieldPath': 'subject'},
            'op': 'EQUAL',
            'value': {'stringValue': subject.name},
          }
        },
      if (publishedOnly == true)
        {
          'fieldFilter': {
            'field': {'fieldPath': 'published'},
            'op': 'EQUAL',
            'value': {'booleanValue': true},
          }
        },
    ];

    final structuredQuery = <String, dynamic>{
      'from': [
        {'collectionId': QuizQuestionRestCodec.collectionId}
      ],
      if (filters.length == 1) 'where': filters.first,
      if (filters.length > 1)
        'where': {
          'compositeFilter': {'op': 'AND', 'filters': filters}
        },
      'limit': limit,
    };

    final body = jsonEncode({'structuredQuery': structuredQuery});
    final response = await _post(uri, body);

    // A bare `jsonDecode` here let a malformed 200 escape as a raw
    // FormatException, unlike every sibling method in this class.
    final Object? decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException catch (error) {
      throw ApiException(
        'Firestore sent a query result we could not read.',
        statusCode: response.statusCode,
        detail: error.message,
      );
    }
    if (decoded is! List) {
      throw const ApiException('Firestore returned an unexpected query result.');
    }

    final questions = decoded
        .whereType<Map<String, dynamic>>()
        // Rows without a `document` key are read-time markers for "no match".
        .where((row) => row['document'] is Map<String, dynamic>)
        .map((row) => QuizQuestionRestCodec.fromDocument(
              row['document'] as Map<String, dynamic>,
            ))
        .toList(growable: false);

    return RestQueryResult(
      questions: questions,
      log: RestCallLog(
        method: 'POST',
        url: uri.toString(),
        requestBody: _pretty(body),
        responseBody: _pretty(response.body),
        statusCode: response.statusCode,
      ),
    );
  }

  // ------------------------------------------------------------- internals

  Future<http.Response> _post(Uri uri, String body) =>
      _send('POST', uri, body: body);

  /// The one place every REST call goes through, so authentication, timeouts,
  /// and status-code handling are identical for POST, PATCH, and DELETE.
  Future<http.Response> _send(String method, Uri uri, {String? body}) async {
    final token = await _idToken();
    final headers = <String, String>{
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
      if (body != null) 'Content-Type': 'application/json',
    };

    try {
      final Future<http.Response> call = switch (method) {
        'POST' => _client.post(uri, headers: headers, body: body),
        'PATCH' => _client.patch(uri, headers: headers, body: body),
        'DELETE' => _client.delete(uri, headers: headers),
        _ => throw ApiException("Unsupported HTTP method $method."),
      };

      final response = await call.timeout(timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException.fromStatus(
          response.statusCode,
          body: _describeError(response.body),
        );
      }
      return response;
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  Future<String> _idToken() async {
    final provider = _tokenProvider;
    if (provider != null) return provider();

    final user = _auth.currentUser;
    if (user == null) {
      throw const ApiException('You must be signed in to save to the server.');
    }
    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw const ApiException('Could not get a sign-in token. Try signing in again.');
    }
    return token;
  }

  /// Re-indents a JSON payload for display. Falls back to the raw text, since a
  /// body that will not parse is exactly the one worth showing verbatim.
  String _pretty(String body) {
    try {
      return const JsonEncoder.withIndent('  ').convert(jsonDecode(body));
    } catch (_) {
      return body;
    }
  }

  /// Firestore reports failures as `{"error": {"message": "..."}}`.
  String _describeError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded['error'] is Map) {
        return (decoded['error'] as Map)['message']?.toString() ?? body;
      }
      if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
        final first = decoded.first as Map;
        if (first['error'] is Map) {
          return (first['error'] as Map)['message']?.toString() ?? body;
        }
      }
    } catch (_) {
      // Fall through to the raw body.
    }
    return body;
  }

  Map<String, dynamic> _decodeObject(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('Firestore sent data we could not read.');
    }
    return decoded;
  }

  void dispose() => _client.close();
}

/// Translates between [QuizQuestionRecord] and Firestore's REST wire format.
///
/// The REST API does not accept plain JSON: every value is wrapped in a typed
/// envelope (`stringValue`, `integerValue`, `arrayValue`, …), so encoding and
/// decoding live here rather than being scattered through the service.
class QuizQuestionRestCodec {
  /// Same collection the SDK repository writes to, so REST-created questions
  /// and SDK-created questions are indistinguishable to the rest of the app.
  static const String collectionId = QuestionRepository.collectionPath;

  static Map<String, dynamic> toFields(QuizQuestionRecord record, String? uid) {
    final now = DateTime.now().toUtc().toIso8601String();
    return {
      'subject': {'stringValue': record.subject.name},
      'topic': {'stringValue': record.topic},
      'instruction': {'stringValue': record.instruction},
      'prompt': {'stringValue': record.prompt},
      'correctAnswer': {'stringValue': record.correctAnswer},
      'choices': {
        'arrayValue': {
          'values': record.choices
              .map((choice) => {'stringValue': choice})
              .toList(growable: false),
        }
      },
      'minLevel': {'integerValue': record.minLevel.toString()},
      'source': {'stringValue': record.source.name},
      'published': {'booleanValue': record.published},
      if (uid != null) 'createdBy': {'stringValue': uid},
      'createdAt': {'timestampValue': now},
      'updatedAt': {'timestampValue': now},
    };
  }

  /// Fields an edit is allowed to rewrite, used as both the PATCH body and the
  /// `updateMask`. `createdAt` and `createdBy` are deliberately absent so an
  /// update cannot rewrite who first authored the question or when.
  static Map<String, dynamic> toUpdateFields(QuizQuestionRecord record) {
    final fields = toFields(record, null);
    fields.remove('createdAt');
    fields.remove('createdBy');
    fields['updatedAt'] = {
      'timestampValue': DateTime.now().toUtc().toIso8601String(),
    };
    return fields;
  }

  static QuizQuestionRecord fromDocument(Map<String, dynamic> document) {
    final name = (document['name'] ?? '').toString();
    final id = name.isEmpty ? '' : name.split('/').last;
    final fields = document['fields'];
    final plain = <String, dynamic>{};

    if (fields is Map<String, dynamic>) {
      for (final entry in fields.entries) {
        plain[entry.key] = _unwrap(entry.value);
      }
    }
    return QuizQuestionRecord.fromMap(id, plain);
  }

  static dynamic _unwrap(dynamic value) {
    if (value is! Map<String, dynamic>) return value;
    if (value.containsKey('stringValue')) return value['stringValue'];
    if (value.containsKey('booleanValue')) return value['booleanValue'];
    if (value.containsKey('integerValue')) {
      return int.tryParse(value['integerValue'].toString());
    }
    if (value.containsKey('doubleValue')) return value['doubleValue'];
    if (value.containsKey('timestampValue')) return value['timestampValue'];
    if (value.containsKey('nullValue')) return null;
    if (value.containsKey('arrayValue')) {
      final array = value['arrayValue'];
      final values = array is Map<String, dynamic> ? array['values'] : null;
      if (values is List) return values.map(_unwrap).toList();
      return const <dynamic>[];
    }
    return null;
  }
}
