import 'package:benchmark/services/text_to_speech_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// What the spelling game hands the speech engine.
///
/// A synthesiser given a bare word has no sentence to take intonation from,
/// so it produces a flat, clipped reading and often swallows the first sound.
/// These tests pin the phrasing that fixes it.
void main() {
  group('buildSpellingPhrase', () {
    test('wraps the word in a carrier phrase rather than speaking it alone', () {
      final phrase = TextToSpeechService.buildSpellingPhrase('cat');

      expect(phrase, 'The word is cat.');
      expect(phrase, isNot('cat'));
    });

    test('adds the example sentence after the word', () {
      final phrase = TextToSpeechService.buildSpellingPhrase(
        'cat',
        sentence: 'The cat sat on the mat.',
      );

      expect(phrase, 'The word is cat. The cat sat on the mat.');
    });

    test('a replay drops the preamble but keeps the sentence', () {
      final phrase = TextToSpeechService.buildSpellingPhrase(
        'cat',
        sentence: 'The cat sat on the mat.',
        repeat: true,
      );

      expect(phrase, 'cat. The cat sat on the mat.');
      expect(phrase, isNot(contains('The word is')));
    });

    test('always ends on a full stop so the engine lands the sentence', () {
      // Without terminal punctuation many engines cut the last word short.
      for (final sentence in ['A cat naps', 'A cat naps.', 'Is that a cat?']) {
        final phrase =
            TextToSpeechService.buildSpellingPhrase('cat', sentence: sentence);
        expect(
          phrase.endsWith('.') || phrase.endsWith('?') || phrase.endsWith('!'),
          isTrue,
          reason: 'phrase for "$sentence" has no terminal punctuation',
        );
      }
    });

    test('does not double up punctuation the sentence already has', () {
      final phrase = TextToSpeechService.buildSpellingPhrase(
        'cat',
        sentence: 'The cat sat.',
      );
      expect(phrase, isNot(contains('..')));
    });

    test('copes with a missing or blank sentence', () {
      expect(
        TextToSpeechService.buildSpellingPhrase('cat', sentence: null),
        'The word is cat.',
      );
      expect(
        TextToSpeechService.buildSpellingPhrase('cat', sentence: '   '),
        'The word is cat.',
      );
    });

    test('trims stray whitespace around the word and sentence', () {
      final phrase = TextToSpeechService.buildSpellingPhrase(
        '  cat  ',
        sentence: '  The cat sat.  ',
      );
      expect(phrase, 'The word is cat. The cat sat.');
    });

    test('an empty word produces nothing to say', () {
      expect(TextToSpeechService.buildSpellingPhrase(''), isEmpty);
      expect(TextToSpeechService.buildSpellingPhrase('   '), isEmpty);
    });

    test('the spoken sentence still contains the word', () {
      // The screen blanks the word out; the audio is what gives it away, and
      // that is the point - it is a spelling test, not a guessing game.
      final phrase = TextToSpeechService.buildSpellingPhrase(
        'their',
        sentence: 'They rode their bikes to school.',
      );
      expect(phrase, contains('their'));
    });
  });
}
