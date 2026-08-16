import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';

/// One sense of a word: its part of speech and the definitions under it.
class DictionaryMeaning {
  final String partOfSpeech;
  final List<String> definitions;
  final String? example;
  final List<String> synonyms;

  const DictionaryMeaning({
    required this.partOfSpeech,
    required this.definitions,
    this.example,
    this.synonyms = const [],
  });

  factory DictionaryMeaning.fromJson(Map<String, dynamic> json) {
    final rawDefinitions =
        (json['definitions'] as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>();

    return DictionaryMeaning(
      partOfSpeech: (json['partOfSpeech'] ?? '').toString(),
      definitions: rawDefinitions
          .map((item) => (item['definition'] ?? '').toString())
          .where((item) => item.isNotEmpty)
          .toList(growable: false),
      example: rawDefinitions
          .map((item) => (item['example'] ?? '').toString())
          .firstWhere((item) => item.isNotEmpty, orElse: () => ''),
      synonyms: (json['synonyms'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .take(6)
          .toList(growable: false),
    );
  }
}

/// A word with everything the lookup sheet needs to render.
class DictionaryEntry {
  final String word;
  final String? phonetic;
  final String? audioUrl;
  final List<DictionaryMeaning> meanings;
  final String rawJson;

  const DictionaryEntry({
    required this.word,
    this.phonetic,
    this.audioUrl,
    this.meanings = const [],
    this.rawJson = '',
  });

  bool get hasAudio => (audioUrl ?? '').isNotEmpty;

  factory DictionaryEntry.fromJson(Map<String, dynamic> json, {String rawJson = ''}) {
    final phonetics =
        (json['phonetics'] as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>();

    // The API returns several phonetic blocks; take the first with real text
    // and the first with a playable audio file (they are often different).
    final phoneticText = [
      (json['phonetic'] ?? '').toString(),
      ...phonetics.map((item) => (item['text'] ?? '').toString()),
    ].firstWhere((item) => item.isNotEmpty, orElse: () => '');

    final audio = phonetics
        .map((item) => (item['audio'] ?? '').toString())
        .firstWhere((item) => item.isNotEmpty, orElse: () => '');

    return DictionaryEntry(
      word: (json['word'] ?? '').toString(),
      phonetic: phoneticText.isEmpty ? null : phoneticText,
      audioUrl: audio.isEmpty ? null : audio,
      meanings: (json['meanings'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(DictionaryMeaning.fromJson)
          .where((meaning) => meaning.definitions.isNotEmpty)
          .toList(growable: false),
      rawJson: rawJson,
    );
  }
}

/// Read-only client for the **Free Dictionary API**
/// (https://dictionaryapi.dev).
///
/// Free, no API key. Powers the in-game "What does this word mean?" helper:
/// a student stuck on a word in an English question taps it and gets the
/// definition, the phonetic spelling, and a pronunciation clip — without
/// leaving the quiz.
///
/// Endpoint used (HTTP GET):
///  * `GET /api/v2/entries/en/{word}`
class DictionaryApi {
  static const String host = 'api.dictionaryapi.dev';
  static const Duration timeout = Duration(seconds: 12);

  final http.Client _client;

  /// Small in-memory cache so re-tapping the same word during a quiz does not
  /// re-hit the network.
  final Map<String, DictionaryEntry> _cache = {};

  DictionaryApi({http.Client? client}) : _client = client ?? http.Client();

  /// `GET https://api.dictionaryapi.dev/api/v2/entries/en/{word}`
  ///
  /// Throws [ApiException] with a friendly message when the word is unknown
  /// (the API answers HTTP 404 with a JSON body for that case).
  Future<DictionaryEntry> lookup(String word) async {
    final cleaned = _normalize(word);
    if (cleaned.isEmpty) {
      throw const ApiException('Type a word to look up.');
    }

    final cached = _cache[cleaned];
    if (cached != null) return cached;

    final uri = Uri.https(host, '/api/v2/entries/en/$cleaned');

    try {
      final response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(timeout);

      if (response.statusCode == 404) {
        throw ApiException(
          'No dictionary entry found for "$cleaned".',
          statusCode: 404,
          detail: response.body,
        );
      }
      if (response.statusCode != 200) {
        throw ApiException.fromStatus(response.statusCode, body: response.body);
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List || decoded.isEmpty) {
        throw ApiException('No dictionary entry found for "$cleaned".');
      }

      final first = decoded.first;
      if (first is! Map<String, dynamic>) {
        throw const ApiException('The dictionary sent data we could not read.');
      }

      final entry = DictionaryEntry.fromJson(
        first,
        rawJson: const JsonEncoder.withIndent('  ').convert(first),
      );
      if (entry.meanings.isEmpty) {
        throw ApiException('No definition available for "$cleaned".');
      }

      _cache[cleaned] = entry;
      return entry;
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException.from(error);
    }
  }

  /// Strips punctuation so tapping "sun." or "(sun)" still resolves.
  String _normalize(String word) {
    return word
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r"[^a-z'-]"), '')
        .replaceAll(RegExp(r"^[''-]+|[''-]+$"), '');
  }

  void dispose() => _client.close();
}
