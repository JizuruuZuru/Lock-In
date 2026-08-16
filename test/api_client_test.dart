import 'dart:convert';

import 'package:benchmark/data/subject_question_bank.dart';
import 'package:benchmark/services/api/api_exception.dart';
import 'package:benchmark/services/api/dictionary_api.dart';
import 'package:benchmark/services/api/open_trivia_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Exercises the HTTP layer against canned responses, so JSON parsing and
/// failure handling are verified without hitting the real APIs.
void main() {
  group('OpenTriviaApi', () {
    test('parses categories from the category endpoint', () async {
      final api = OpenTriviaApi(
        client: MockClient((request) async {
          expect(request.url.host, 'opentdb.com');
          expect(request.url.path, '/api_category.php');
          return http.Response(
            jsonEncode({
              'trivia_categories': [
                {'id': 17, 'name': 'Science & Nature'},
                {'id': 10, 'name': 'Entertainment: Books'},
              ]
            }),
            200,
          );
        }),
      );

      final categories = await api.fetchCategories();
      expect(categories, hasLength(2));
      expect(categories.first.id, 17);
      expect(categories.first.name, 'Science & Nature');
    });

    test('decodes url3986-encoded question text', () async {
      final api = OpenTriviaApi(
        client: MockClient((request) async {
          // The service must ask for the encoding it knows how to decode.
          expect(request.url.queryParameters['encode'], 'url3986');
          expect(request.url.queryParameters['type'], 'multiple');
          return http.Response(_triviaBody, 200);
        }),
      );

      final result = await api.fetchQuestions(amount: 1, categoryId: 17);
      expect(result.questions, hasLength(1));

      final question = result.questions.single;
      expect(question.question, 'What is the largest planet?');
      expect(question.correctAnswer, 'Jupiter');
      expect(question.incorrectAnswers, ['Mars', 'Venus', 'Earth']);
      expect(question.category, 'Science: Nature');
      expect(result.rawJson, contains('response_code'));
    });

    test('clamps the requested amount to the API range', () async {
      late Uri captured;
      final api = OpenTriviaApi(
        client: MockClient((request) async {
          captured = request.url;
          return http.Response(_triviaBody, 200);
        }),
      );

      await api.fetchQuestions(amount: 500);
      expect(captured.queryParameters['amount'], '50');
    });

    test('turns response_code 1 into a readable error, not a crash', () async {
      final api = OpenTriviaApi(
        client: MockClient((_) async => http.Response(
              jsonEncode({'response_code': 1, 'results': []}),
              200,
            )),
      );

      await expectLater(
        api.fetchQuestions(amount: 50),
        throwsA(isA<ApiException>().having(
          (error) => error.message,
          'message',
          contains('does not have that many questions'),
        )),
      );
    });

    test('reports the rate limit clearly (response_code 5)', () async {
      final api = OpenTriviaApi(
        client: MockClient((_) async => http.Response(
              jsonEncode({'response_code': 5, 'results': []}),
              200,
            )),
      );

      await expectLater(
        api.fetchQuestions(amount: 10),
        throwsA(isA<ApiException>().having(
          (error) => error.message,
          'message',
          contains('5 seconds'),
        )),
      );
    });

    test('drops rows without enough wrong answers to be playable', () async {
      final api = OpenTriviaApi(
        client: MockClient((_) async => http.Response(
              jsonEncode({
                'response_code': 0,
                'results': [
                  {
                    'category': 'Science',
                    'difficulty': 'easy',
                    'question': 'Good%20question%3F',
                    'correct_answer': 'Yes',
                    'incorrect_answers': ['No', 'Maybe'],
                  },
                  {
                    'category': 'Science',
                    'difficulty': 'easy',
                    'question': 'Broken%20question%3F',
                    'correct_answer': 'Yes',
                    'incorrect_answers': ['No'],
                  },
                ],
              }),
              200,
            )),
      );

      final result = await api.fetchQuestions(amount: 2);
      expect(result.questions, hasLength(1));
      expect(result.questions.single.question, 'Good question?');
    });

    test('maps an HTTP failure onto a friendly ApiException', () async {
      final api = OpenTriviaApi(
        client: MockClient((_) async => http.Response('nope', 503)),
      );

      await expectLater(
        api.fetchCategories(),
        throwsA(isA<ApiException>().having(
          (error) => error.statusCode,
          'statusCode',
          503,
        )),
      );
    });

    test('converts an API question into a storable record', () async {
      final api = OpenTriviaApi(
        client: MockClient((_) async => http.Response(_triviaBody, 200)),
      );

      final result = await api.fetchQuestions(amount: 1);
      final record =
          result.questions.single.toRecord(subject: SubjectQuizType.science);

      expect(record.subject, SubjectQuizType.science);
      // "Science: Nature" is shortened so it reads as a topic.
      expect(record.topic, 'Nature');
      expect(record.correctAnswer, 'Jupiter');
      expect(record.choices, ['Mars', 'Venus', 'Earth']);
      expect(record.validate(), isEmpty);
    });

    test('difficulty maps onto the level gate', () async {
      const easy = TriviaQuestion(
        category: 'c',
        difficulty: 'easy',
        question: 'q',
        correctAnswer: 'a',
        incorrectAnswers: ['b', 'c'],
      );
      expect(easy.suggestedMinLevel, 1);

      const hard = TriviaQuestion(
        category: 'c',
        difficulty: 'hard',
        question: 'q',
        correctAnswer: 'a',
        incorrectAnswers: ['b', 'c'],
      );
      expect(hard.suggestedMinLevel, 7);
    });
  });

  group('DictionaryApi', () {
    test('parses a word, its phonetic, and its meanings', () async {
      final api = DictionaryApi(
        client: MockClient((request) async {
          expect(request.url.host, 'api.dictionaryapi.dev');
          expect(request.url.path, '/api/v2/entries/en/sun');
          return _jsonResponse(_dictionaryBody);
        }),
      );

      final entry = await api.lookup('Sun.');
      expect(entry.word, 'sun');
      expect(entry.phonetic, '/sʌn/');
      expect(entry.hasAudio, isTrue);
      expect(entry.meanings, hasLength(1));

      final meaning = entry.meanings.single;
      expect(meaning.partOfSpeech, 'noun');
      expect(meaning.definitions.first, contains('star'));
      expect(meaning.example, 'The sun rose over the hill.');
      expect(meaning.synonyms, contains('daystar'));
    });

    test('turns a 404 into a "no entry found" message', () async {
      final api = DictionaryApi(
        client: MockClient((_) async => http.Response(
              jsonEncode({'title': 'No Definitions Found'}),
              404,
            )),
      );

      await expectLater(
        api.lookup('zzzzqqq'),
        throwsA(isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 404)
            .having((error) => error.message, 'message', contains('zzzzqqq'))),
      );
    });

    test('rejects an empty word without making a request', () async {
      var called = false;
      final api = DictionaryApi(
        client: MockClient((_) async {
          called = true;
          return http.Response('[]', 200);
        }),
      );

      await expectLater(api.lookup('  ...  '), throwsA(isA<ApiException>()));
      expect(called, isFalse);
    });

    test('caches a word so a repeat lookup makes no second request', () async {
      var requests = 0;
      final api = DictionaryApi(
        client: MockClient((_) async {
          requests++;
          return _jsonResponse(_dictionaryBody);
        }),
      );

      await api.lookup('sun');
      await api.lookup('SUN');
      expect(requests, 1);
    });
  });

  group('ApiException', () {
    test('describes common status codes in plain language', () {
      expect(ApiException.fromStatus(429).message, contains('Too many requests'));
      expect(ApiException.fromStatus(503).message, contains('trouble'));
      expect(ApiException.fromStatus(403).message, contains('not allowed'));
    });

    test('passes an existing ApiException through unchanged', () {
      const original = ApiException('Original message');
      expect(ApiException.from(original), same(original));
    });
  });
}

/// [http.Response] defaults to latin-1 when the headers carry no charset,
/// which would fail on the phonetic characters in the dictionary fixture.
http.Response _jsonResponse(String body, {int status = 200}) {
  return http.Response(
    body,
    status,
    headers: const {'content-type': 'application/json; charset=utf-8'},
  );
}

/// One url3986-encoded question, as opentdb.com returns it.
final String _triviaBody = jsonEncode({
  'response_code': 0,
  'results': [
    {
      'type': 'multiple',
      'difficulty': 'easy',
      'category': 'Science%3A%20Nature',
      'question': 'What%20is%20the%20largest%20planet%3F',
      'correct_answer': 'Jupiter',
      'incorrect_answers': ['Mars', 'Venus', 'Earth'],
    }
  ],
});

final String _dictionaryBody = jsonEncode([
  {
    'word': 'sun',
    'phonetic': '/sʌn/',
    'phonetics': [
      {'text': '/sʌn/', 'audio': ''},
      {'text': '/sʌn/', 'audio': 'https://example.com/sun.mp3'},
    ],
    'meanings': [
      {
        'partOfSpeech': 'noun',
        'definitions': [
          {
            'definition': 'The star at the centre of our solar system.',
            'example': 'The sun rose over the hill.',
          }
        ],
        'synonyms': ['daystar', 'sol'],
      }
    ],
  }
]);
