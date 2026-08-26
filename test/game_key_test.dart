import 'package:benchmark/utils/game_key.dart';
import 'package:flutter_test/flutter_test.dart';

/// [safeGameKey] replaced four byte-identical private copies that lived in
/// game_logger, leaderboard_service, subject_quiz_game, and spelling_game.
///
/// Scores, game logs, and leaderboard entries already in Firestore are stored
/// under keys the old copies produced, so the output has to stay exactly the
/// same - a change here silently orphans a player's history.
void main() {
  group('safeGameKey', () {
    test('lowercases and joins words with underscores', () {
      expect(safeGameKey('Number Memory'), 'number_memory');
    });

    test('collapses punctuation into a single underscore', () {
      expect(safeGameKey('English: Word Study'), 'english_word_study');
      expect(safeGameKey('Subject-Verb Agreement'), 'subject_verb_agreement');
      expect(safeGameKey('All Subjects + Science'), 'all_subjects_science');
    });

    test('trims leading and trailing separators', () {
      expect(safeGameKey('  Roman Numerals  '), 'roman_numerals');
      expect(safeGameKey('...Fractions!!!'), 'fractions');
      expect(safeGameKey('_Place Value_'), 'place_value');
    });

    test('keeps digits', () {
      expect(safeGameKey('Level 3 Exam'), 'level_3_exam');
    });

    test('handles the real game names each caller passes', () {
      expect(safeGameKey('English Quiz'), 'english_quiz');
      expect(safeGameKey('Science: Earth and Space'), 'science_earth_and_space');
      expect(safeGameKey('All Subjects Hard Exam'), 'all_subjects_hard_exam');
      expect(safeGameKey('spelling'), 'spelling');
    });

    test('degrades to an empty key rather than throwing', () {
      expect(safeGameKey(''), '');
      expect(safeGameKey('   '), '');
      expect(safeGameKey('!!!'), '');
    });
  });
}
