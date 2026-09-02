import 'package:benchmark/utils/game_difficulty_mode.dart';
import 'package:benchmark/widgets/hearts_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// HeartsDisplay used to hardcode three slots. Hard mode grants one heart, so
/// a Hard player opened the game looking at one filled and two empty hearts -
/// which reads as "you have already lost two lives" before a single question.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) =>
      tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));

  int filled(WidgetTester tester) => tester
      .widgetList<Icon>(find.byType(Icon))
      .where((icon) => icon.icon == Icons.favorite)
      .length;

  int empty(WidgetTester tester) => tester
      .widgetList<Icon>(find.byType(Icon))
      .where((icon) => icon.icon == Icons.favorite_border)
      .length;

  testWidgets('Hard mode shows a single full heart, not one of three',
      (tester) async {
    final hearts = gameDifficultyModeHearts(GameDifficultyMode.hard);
    expect(hearts, 1);

    await pump(tester, HeartsDisplay(hearts: hearts, maxHearts: hearts));

    expect(filled(tester), 1);
    expect(empty(tester), 0, reason: 'no phantom lost lives at the start');
  });

  testWidgets('Normal mode still shows three', (tester) async {
    final hearts = gameDifficultyModeHearts(GameDifficultyMode.normal);
    expect(hearts, 3);

    await pump(tester, HeartsDisplay(hearts: hearts, maxHearts: hearts));

    expect(filled(tester), 3);
    expect(empty(tester), 0);
  });

  testWidgets('losing a life empties a slot without shortening the row',
      (tester) async {
    await pump(tester, const HeartsDisplay(hearts: 1, maxHearts: 3));

    expect(filled(tester), 1);
    expect(empty(tester), 2);
  });

  testWidgets('a stale capacity never hides a life the player actually has',
      (tester) async {
    // Guards the clamp in build(): slots must never be fewer than `hearts`.
    await pump(tester, const HeartsDisplay(hearts: 3, maxHearts: 1));

    expect(filled(tester), 3);
  });

  testWidgets('defaults to three when no capacity is given', (tester) async {
    await pump(tester, const HeartsDisplay(hearts: 2));

    expect(filled(tester), 2);
    expect(empty(tester), 1);
  });
}
