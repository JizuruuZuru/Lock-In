import 'dart:convert';

import 'package:benchmark/data/subject_question_bank.dart';
import 'package:benchmark/models/quiz_question_record.dart';
import 'package:benchmark/services/api/api_exception.dart';
import 'package:benchmark/services/api/firestore_rest_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Exercises the Cloud Firestore REST layer — the project's own backend reached
/// over plain HTTPS — against canned responses.
///
/// The service takes a `tokenProvider` and a `uid` so the whole surface runs
/// with no Firebase app initialized, which is what makes these tests fast and
/// offline.
void main() {
  const projectId = 'benchmark-14acf';
  const documentsPath =
      '/v1/projects/$projectId/databases/(default)/documents';

  FirestoreRestApi apiWith(MockClient client) {
    return FirestoreRestApi(
      client: client,
      projectId: projectId,
      tokenProvider: () async => 'test-id-token',
      uid: 'admin-uid',
    );
  }

  QuizQuestionRecord sample({String id = ''}) {
    return QuizQuestionRecord(
      id: id,
      subject: SubjectQuizType.science,
      topic: 'Nature',
      instruction: 'Choose the correct answer.',
      prompt: 'What is the largest planet in our solar system?',
      correctAnswer: 'Jupiter',
      choices: const ['Mars', 'Venus', 'Earth'],
      minLevel: 1,
    );
  }

  /// A Firestore document reply, in the typed-envelope form the REST API uses.
  String documentBody(String id, {String prompt = 'What is the largest planet in our solar system?'}) {
    return jsonEncode({
      'name': 'projects/$projectId/databases/(default)/documents/quiz_questions/$id',
      'fields': {
        'subject': {'stringValue': 'science'},
        'topic': {'stringValue': 'Nature'},
        'instruction': {'stringValue': 'Choose the correct answer.'},
        'prompt': {'stringValue': prompt},
        'correctAnswer': {'stringValue': 'Jupiter'},
        'choices': {
          'arrayValue': {
            'values': [
              {'stringValue': 'Mars'},
              {'stringValue': 'Venus'},
              {'stringValue': 'Earth'},
            ]
          }
        },
        'minLevel': {'integerValue': '1'},
        'source': {'stringValue': 'manual'},
        'published': {'booleanValue': true},
      },
      'createTime': '2026-08-16T04:12:55.401Z',
      'updateTime': '2026-08-16T04:12:55.401Z',
    });
  }

  group('POST — create', () {
    test('creates a document and returns its new id', () async {
      late http.Request captured;

      final api = apiWith(MockClient((request) async {
        captured = request;
        return http.Response(documentBody('abc123'), 200);
      }));

      final result = await api.createQuestionDetailed(sample());

      expect(captured.method, 'POST');
      expect(captured.url.host, FirestoreRestApi.host);
      expect(captured.url.path, '$documentsPath/quiz_questions');
      expect(result.createdIds, ['abc123']);
    });

    test('sends the Firebase ID token as a bearer credential', () async {
      late http.Request captured;

      final api = apiWith(MockClient((request) async {
        captured = request;
        return http.Response(documentBody('abc123'), 200);
      }));

      await api.createQuestion(sample());

      expect(captured.headers['Authorization'], 'Bearer test-id-token');
      expect(captured.headers['Content-Type'], contains('application/json'));
    });

    test('wraps every value in the typed envelope Firestore requires', () async {
      late Map<String, dynamic> fields;

      final api = apiWith(MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        fields = body['fields'] as Map<String, dynamic>;
        return http.Response(documentBody('abc123'), 200);
      }));

      await api.createQuestion(sample());

      expect(fields['prompt'], {
        'stringValue': 'What is the largest planet in our solar system?'
      });
      expect(fields['minLevel'], {'integerValue': '1'});
      expect(fields['published'], {'booleanValue': true});
      expect(fields['createdBy'], {'stringValue': 'admin-uid'});
      expect(
        (fields['choices'] as Map)['arrayValue']['values'],
        [
          {'stringValue': 'Mars'},
          {'stringValue': 'Venus'},
          {'stringValue': 'Earth'},
        ],
      );
    });

    test('refuses an invalid question before making a request', () async {
      var called = false;

      final api = apiWith(MockClient((request) async {
        called = true;
        return http.Response(documentBody('abc123'), 200);
      }));

      await expectLater(
        api.createQuestion(sample().copyWith(correctAnswer: '')),
        throwsA(isA<ApiException>()),
      );
      expect(called, isFalse);
    });

    test('a bulk publish collects per-row failures instead of aborting', () async {
      var callCount = 0;

      final api = apiWith(MockClient((request) async {
        callCount++;
        // The second row is rejected; the third must still be attempted.
        if (callCount == 2) {
          return http.Response(
            jsonEncode({
              'error': {'message': 'Permission denied on resource.'}
            }),
            403,
          );
        }
        return http.Response(documentBody('id$callCount'), 200);
      }));

      final result = await api.createQuestions([
        sample(),
        sample(),
        sample(),
      ]);

      expect(callCount, 3);
      expect(result.successCount, 2);
      expect(result.failureCount, 1);
      expect(result.hasFailures, isTrue);
    });
  });

  group('PATCH — update', () {
    test('updates a document with an explicit update mask', () async {
      late http.Request captured;

      final api = apiWith(MockClient((request) async {
        captured = request;
        return http.Response(documentBody('abc123', prompt: 'Edited prompt?'), 200);
      }));

      final log = await api.updateQuestion(
        sample(id: 'abc123').copyWith(prompt: 'Edited prompt?'),
      );

      expect(captured.method, 'PATCH');
      expect(captured.url.path, '$documentsPath/quiz_questions/abc123');
      expect(log.method, 'PATCH');
      expect(log.statusCode, 200);
      expect(log.responseBody, contains('Edited prompt?'));
    });

    test('the mask never lets an edit rewrite createdAt or createdBy', () async {
      late Uri captured;
      late Map<String, dynamic> fields;

      final api = apiWith(MockClient((request) async {
        captured = request.url;
        fields = (jsonDecode(request.body) as Map<String, dynamic>)['fields']
            as Map<String, dynamic>;
        return http.Response(documentBody('abc123'), 200);
      }));

      await api.updateQuestion(sample(id: 'abc123'));

      final mask = captured.queryParametersAll['updateMask.fieldPaths'] ?? const [];
      expect(mask, contains('prompt'));
      expect(mask, contains('updatedAt'));
      expect(mask, isNot(contains('createdAt')));
      expect(mask, isNot(contains('createdBy')));

      expect(fields.containsKey('createdAt'), isFalse);
      expect(fields.containsKey('createdBy'), isFalse);
      // Whatever is on the mask must also be in the body, or Firestore clears it.
      expect(mask.toSet(), fields.keys.toSet());
    });

    test('the publish toggle masks only the two fields it touches', () async {
      late Uri captured;

      final api = apiWith(MockClient((request) async {
        captured = request.url;
        return http.Response(documentBody('abc123'), 200);
      }));

      await api.setPublished('abc123', false);

      expect(
        captured.queryParametersAll['updateMask.fieldPaths']?.toSet(),
        {'published', 'updatedAt'},
      );
    });

    test('refuses to update a record with no id', () async {
      final api = apiWith(MockClient((request) async {
        return http.Response(documentBody('abc123'), 200);
      }));

      await expectLater(
        api.updateQuestion(sample()),
        throwsA(isA<ApiException>()),
      );
    });

    test('surfaces a rules rejection as a readable message', () async {
      final api = apiWith(MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {'message': 'Missing or insufficient permissions.'}
          }),
          403,
        );
      }));

      await expectLater(
        api.updateQuestion(sample(id: 'abc123')),
        throwsA(
          isA<ApiException>()
              .having((error) => error.statusCode, 'statusCode', 403)
              .having(
                (error) => error.message,
                'message',
                contains('not allowed'),
              )
              .having(
                (error) => error.detail,
                'detail',
                'Missing or insufficient permissions.',
              ),
        ),
      );
    });
  });

  group('DELETE — remove', () {
    test('deletes a document by id', () async {
      late http.Request captured;

      final api = apiWith(MockClient((request) async {
        captured = request;
        return http.Response('{}', 200);
      }));

      final log = await api.deleteQuestion('abc123');

      expect(captured.method, 'DELETE');
      expect(captured.url.path, '$documentsPath/quiz_questions/abc123');
      expect(captured.headers['Authorization'], 'Bearer test-id-token');
      expect(log.method, 'DELETE');
      expect(log.statusCode, 200);
    });

    test('an empty body is reported as {} rather than blank', () async {
      final api = apiWith(MockClient((request) async => http.Response('', 200)));

      final log = await api.deleteQuestion('abc123');

      expect(log.responseBody, '{}');
    });

    test('refuses an empty id instead of deleting the collection path', () async {
      var called = false;

      final api = apiWith(MockClient((request) async {
        called = true;
        return http.Response('{}', 200);
      }));

      await expectLater(
        api.deleteQuestion('   '),
        throwsA(isA<ApiException>()),
      );
      expect(called, isFalse);
    });

    test('a missing document comes back as a 404 with a readable message', () async {
      final api = apiWith(MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {'message': 'Document does not exist.'}
          }),
          404,
        );
      }));

      await expectLater(
        api.deleteQuestion('gone'),
        throwsA(
          isA<ApiException>()
              .having((error) => error.statusCode, 'statusCode', 404)
              .having(
                (error) => error.message,
                'message',
                contains('could not find'),
              ),
        ),
      );
    });
  });

  group('POST — runQuery search', () {
    test('builds a single fieldFilter for one condition', () async {
      late Map<String, dynamic> query;

      final api = apiWith(MockClient((request) async {
        query = (jsonDecode(request.body) as Map<String, dynamic>)['structuredQuery']
            as Map<String, dynamic>;
        return http.Response(
          jsonEncode([
            {'document': jsonDecode(documentBody('abc123'))}
          ]),
          200,
        );
      }));

      final result = await api.runQuestionQuery(subject: SubjectQuizType.science);

      expect(query['from'], [
        {'collectionId': 'quiz_questions'}
      ]);
      expect(query['where'], containsPair('fieldFilter', isA<Map>()));
      expect(query['where']['fieldFilter']['field'], {'fieldPath': 'subject'});
      expect(result, hasLength(1));
      expect(result.single.id, 'abc123');
      expect(result.single.correctAnswer, 'Jupiter');
    });

    test('combines two conditions under a compositeFilter', () async {
      late Map<String, dynamic> query;

      final api = apiWith(MockClient((request) async {
        query = (jsonDecode(request.body) as Map<String, dynamic>)['structuredQuery']
            as Map<String, dynamic>;
        return http.Response(jsonEncode(const []), 200);
      }));

      await api.runQuestionQuery(
        subject: SubjectQuizType.english,
        publishedOnly: true,
      );

      expect(query['where']['compositeFilter']['op'], 'AND');
      expect(query['where']['compositeFilter']['filters'], hasLength(2));
    });

    test('skips the read-time markers Firestore returns for no match', () async {
      final api = apiWith(MockClient((request) async {
        return http.Response(
          jsonEncode([
            {'readTime': '2026-08-16T04:12:55.401Z'}
          ]),
          200,
        );
      }));

      expect(await api.runQuestionQuery(), isEmpty);
    });

    test('the detailed form returns the exchange alongside the rows', () async {
      final api = apiWith(MockClient((request) async {
        return http.Response(
          jsonEncode([
            {'document': jsonDecode(documentBody('abc123'))}
          ]),
          200,
        );
      }));

      final result = await api.runQuestionQueryDetailed(limit: 5);

      expect(result.questions, hasLength(1));
      expect(result.log.method, 'POST');
      expect(result.log.url, contains(':runQuery'));
      expect(result.log.requestBody, contains('structuredQuery'));
      expect(result.log.summary, contains('-> 200'));
    });
  });

  group('authentication', () {
    test('a request with no signed-in user never reaches the network', () async {
      var called = false;

      final api = FirestoreRestApi(
        client: MockClient((request) async {
          called = true;
          return http.Response('{}', 200);
        }),
        projectId: projectId,
        tokenProvider: () async =>
            throw const ApiException('You must be signed in to save to the server.'),
      );

      await expectLater(
        api.deleteQuestion('abc123'),
        throwsA(
          isA<ApiException>().having(
            (error) => error.message,
            'message',
            contains('signed in'),
          ),
        ),
      );
      expect(called, isFalse);
    });
  });

  group('QuizQuestionRestCodec', () {
    test('a document round-trips back into a record', () {
      final decoded = QuizQuestionRestCodec.fromDocument(
        jsonDecode(documentBody('abc123')) as Map<String, dynamic>,
      );

      expect(decoded.id, 'abc123');
      expect(decoded.subject, SubjectQuizType.science);
      expect(decoded.topic, 'Nature');
      expect(decoded.correctAnswer, 'Jupiter');
      expect(decoded.choices, ['Mars', 'Venus', 'Earth']);
      expect(decoded.minLevel, 1);
      expect(decoded.published, isTrue);
    });

    test('update fields drop the create-time audit stamps', () {
      final fields = QuizQuestionRestCodec.toUpdateFields(sample(id: 'abc123'));

      expect(fields.containsKey('createdAt'), isFalse);
      expect(fields.containsKey('createdBy'), isFalse);
      expect(fields.containsKey('updatedAt'), isTrue);
    });
  });
}
