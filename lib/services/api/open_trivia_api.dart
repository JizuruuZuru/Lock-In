import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../data/subject_question_bank.dart';
import '../../models/quiz_question_record.dart';
import 'api_exception.dart';

/// One category offered by Open Trivia DB (`/api_category.php`).
class TriviaCategory {
  final int id;
  final String name;

  const TriviaCategory({required this.id, required this.name});

  factory TriviaCategory.fromJson(Map<String, dynamic> json) {
    return TriviaCategory(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
    );
  }
}

/// A multiple-choice question exactly as Open Trivia DB returns it.
class TriviaQuestion {
  final String category;
  final String difficulty;
  final String question;
  final String correctAnswer;
  final List<String> incorrectAnswers;

  const TriviaQuestion({
    required this.category,
    required this.difficulty,
    required this.question,
    required this.correctAnswer,
    required this.incorrectAnswers,
  });

  factory TriviaQuestion.fromJson(Map<String, dynamic> json) {
    return TriviaQuestion(
      category: _decode(json['category']),
      difficulty: _decode(json['difficulty']),
      question: _decode(json['question']),
      correctAnswer: _decode(json['correct_answer']),
      incorrectAnswers: (json['incorrect_answers'] as List<dynamic>? ?? const [])
          .map(_decode)
          .toList(growable: false),
    );
  }

  /// Requests use `encode=url3986`, so every text field arrives
  /// percent-encoded and has to be decoded before display.
  static String _decode(dynamic value) {
    final raw = (value ?? '').toString();
    try {
      return Uri.decodeComponent(raw).trim();
    } on FormatException {
      return raw.trim();
    }
  }

  /// Difficulty maps onto the game's level gate so imported "hard" questions
  /// only appear once a student has levelled up.
  int get suggestedMinLevel => switch (difficulty) {
        'hard' => 7,
        'medium' => 4,
        _ => 1,
      };

  /// Converts an API result into the app's own stored entity.
  QuizQuestionRecord toRecord({
    required SubjectQuizType subject,
    String? topicOverride,
  }) {
    return QuizQuestionRecord(
      subject: subject,
      topic: (topicOverride ?? _shortCategory()).trim(),
      instruction: 'Choose the correct answer.',
      prompt: question,
      correctAnswer: correctAnswer,
      choices: incorrectAnswers,
      minLevel: suggestedMinLevel,
      source: QuestionSource.openTrivia,
    );
  }

  /// "Science: Computers" -> "Computers", so the topic reads naturally in the
  /// topic filter alongside the built-in topics.
  String _shortCategory() {
    final parts = category.split(':');
    return parts.length > 1 ? parts.sublist(1).join(':').trim() : category;
  }
}

/// Result of a question pull, including the raw JSON so the admin screen can
/// show a real response sample.
class TriviaFetchResult {
  final List<TriviaQuestion> questions;
  final String rawJson;
  final String requestUrl;

  const TriviaFetchResult({
    required this.questions,
    required this.rawJson,
    required this.requestUrl,
  });
}

/// Read-only client for the **Open Trivia Database** (https://opentdb.com).
///
/// Free, no API key, no registration. Used by the admin panel to pull
/// ready-made multiple-choice questions that map directly onto
/// [QuizQuestionRecord], so a teacher can stock a subject in seconds instead
/// of typing every question by hand.
///
/// Endpoints used (all HTTP GET):
///  * `GET /api_category.php` — the category list
///  * `GET /api.php`          — the questions themselves
class OpenTriviaApi {
  static const String host = 'opentdb.com';
  static const Duration timeout = Duration(seconds: 15);

  /// Open Trivia DB rate-limits one request per IP every 5 seconds.
  static const Duration rateLimitWindow = Duration(seconds: 5);

  final http.Client _client;

  OpenTriviaApi({http.Client? client}) : _client = client ?? http.Client();

  /// Categories that make sense for an elementary English/Science app, so the
  /// admin is not shown "Entertainment: Anime & Manga" by default.
  static const Map<SubjectQuizType, List<int>> suggestedCategoryIds = {
    SubjectQuizType.science: [17, 18, 19, 27], // Nature, Computers, Maths, Animals
    SubjectQuizType.english: [10, 9, 26], // Books, General Knowledge, Celebrities
  };

  /// `GET https://opentdb.com/api_category.php`
  Future<List<TriviaCategory>> fetchCategories() async {
    final uri = Uri.https(host, '/api_category.php');
    final json = await _getJson(uri);

    final categories = json['trivia_categories'];
    if (categories is! List) {
      throw const ApiException('Open Trivia DB returned an unexpected category list.');
    }
    return categories
        .whereType<Map<String, dynamic>>()
        .map(TriviaCategory.fromJson)
        .toList(growable: false);
  }

  /// `GET https://opentdb.com/api.php?amount=..&category=..&difficulty=..&type=multiple&encode=url3986`
  ///
  /// [amount] is clamped to the API's 1–50 range.
  Future<TriviaFetchResult> fetchQuestions({
    required int amount,
    int? categoryId,
    String? difficulty,
  }) async {
    final uri = Uri.https(host, '/api.php', <String, String>{
      'amount': amount.clamp(1, 50).toString(),
      if (categoryId != null && categoryId > 0) 'category': categoryId.toString(),
      if (difficulty != null && difficulty.isNotEmpty) 'difficulty': difficulty,
      'type': 'multiple',
      'encode': 'url3986',
    });

    final response = await _get(uri);
    final json = _decodeBody(response.body);
    _throwForResponseCode(json['response_code']);

    final results = json['results'];
    if (results is! List) {
      throw const ApiException('Open Trivia DB returned no question list.');
    }

    final questions = results
        .whereType<Map<String, dynamic>>()
        .map(TriviaQuestion.fromJson)
        // Guard against malformed rows before they reach the preview table.
        .where((item) =>
            item.question.isNotEmpty &&
            item.correctAnswer.isNotEmpty &&
            item.incorrectAnswers.length >= QuizQuestionRecord.minWrongChoices)
        .toList(growable: false);

    if (questions.isEmpty) {
      throw const ApiException(
        'No usable questions came back for that category. Try another category or a smaller amount.',
      );
    }

    return TriviaFetchResult(
      questions: questions,
      rawJson: _prettyPrint(json),
      requestUrl: uri.toString(),
    );
  }

  /// Open Trivia DB always answers HTTP 200 and reports real failures in a
  /// `response_code` field, so that code has to be checked separately.
  void _throwForResponseCode(dynamic code) {
    final value = (code as num?)?.toInt() ?? 0;
    switch (value) {
      case 0:
        return;
      case 1:
        throw const ApiException(
          'Open Trivia DB does not have that many questions for this category. Try a smaller amount.',
        );
      case 2:
        throw const ApiException(
          'That category or difficulty is not valid for Open Trivia DB.',
        );
      case 3:
      case 4:
        throw const ApiException(
          'This category is used up for now. Pick a different category.',
        );
      case 5:
        throw const ApiException(
          'Open Trivia DB allows one request every 5 seconds. Wait a moment and try again.',
        );
      default:
        throw ApiException('Open Trivia DB returned an unknown status ($value).');
    }
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final response = await _get(uri);
    return _decodeBody(response.body);
  }

  Future<http.Response> _get(Uri uri) async {
    try {
      final response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(timeout);

      if (response.statusCode != 200) {
        throw ApiException.fromStatus(response.statusCode, body: response.body);
      }
      return response;
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  Map<String, dynamic> _decodeBody(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('The server sent data in a format we could not read.');
    }
    return decoded;
  }

  String _prettyPrint(Map<String, dynamic> json) {
    return const JsonEncoder.withIndent('  ').convert(json);
  }

  void dispose() => _client.close();
}
