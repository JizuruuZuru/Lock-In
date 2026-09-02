import 'package:benchmark/utils/game_key.dart';
import 'package:flutter_test/flutter_test.dart';

/// `saveGameResult` derives a game's Firestore field prefix from
/// [safeGameKey]. That is right for eleven of the twelve games - but not all
/// of them, and getting it wrong does not fail loudly: the write succeeds
/// under a *new* field name and the player's existing highscore is silently
/// orphaned under the old one.
///
/// These pin the derivation for every game that relies on the default, and
/// pin the one game that must keep an explicit override.
void main() {
  group('safeGameKey matches the field prefixes already in Firestore', () {
    const expected = <String, String>{
      'Place Value': 'place_value',
      'Rounding Numbers': 'rounding_numbers',
      'Roman Numerals': 'roman_numerals',
      'Fractions': 'fractions',
      'Measurements': 'measurements',
      'Analog Clock': 'analog_clock',
      'Number Memory': 'number_memory',
      'English: Spelling': 'english_spelling',
    };

    expected.forEach((gameName, prefix) {
      test('$gameName -> $prefix', () {
        expect(safeGameKey(gameName), prefix);
      });
    });
  });

  test(
      'Order of Operations is the exception that needs an explicit storageKey',
      () {
    // The screen has always written `order_operations_*`. safeGameKey keeps
    // the "of", so passing the game name here would move the field and lose
    // every stored highscore for that game. saveGameResult takes an explicit
    // storageKey for exactly this case - if this expectation ever flips, the
    // override in order_operations_game.dart can be dropped.
    expect(safeGameKey('Order of Operations'), 'order_of_operations');
    expect(safeGameKey('Order of Operations'), isNot('order_operations'));
  });

  test('keys are stable under punctuation and spacing', () {
    expect(safeGameKey('  Place   Value  '), 'place_value');
    expect(safeGameKey('English: Word Study'), 'english_word_study');
    expect(safeGameKey('Math Game (addition)'), 'math_game_addition');
  });

  test('a key never starts or ends with an underscore, which would create a '
      'double separator once a suffix is appended', () {
    for (final name in ['!Fractions!', ' Spelling ', '::Exam::']) {
      final key = safeGameKey(name);
      expect(key.startsWith('_'), isFalse, reason: name);
      expect(key.endsWith('_'), isFalse, reason: name);
      expect('${key}_highscore'.contains('__'), isFalse, reason: name);
    }
  });
}
