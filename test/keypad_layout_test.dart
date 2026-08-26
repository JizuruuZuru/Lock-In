import 'package:benchmark/widgets/alphabet_keyboard.dart';
import 'package:benchmark/widgets/number_pad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Layout guards for the two on-screen keypads.
///
/// Both size themselves from the space they are given, which is easy to get
/// subtly wrong - a ten-key row that ignores the gaps between keys overflows
/// only on narrow phones, and a grid that mis-solves its height only overflows
/// once an answer display is added. A RenderFlex overflow surfaces as a real
/// exception in a widget test, so rendering each keypad across the range of
/// sizes it actually ships at catches both before a student does.

/// Sizes worth checking: small phone, typical phone, large phone, tablet,
/// desktop window.
const _screens = <Size>[
  Size(320, 568),
  Size(360, 690),
  Size(414, 896),
  Size(768, 1024),
  Size(1440, 900),
];

Future<void> _pump(WidgetTester tester, Size size, Widget child) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

/// The key (the button) a label sits inside, rather than the glyph itself.
Finder _keyOf(String label) => find.ancestor(
      of: find.text(label),
      matching: find.byType(ElevatedButton),
    );

void main() {
  group('NumberPad', () {
    for (final screen in _screens) {
      testWidgets('lays out without overflow at ${screen.width.toInt()}px',
          (tester) async {
        await _pump(
          tester,
          screen,
          SizedBox(
            width: screen.width,
            height: screen.height,
            child: NumberPad(
              input: '42',
              onNumberTap: (_) {},
              onClear: () {},
              onSubmit: () {},
              isDisabled: false,
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('shows every digit, delete and enter', (tester) async {
      await _pump(
        tester,
        const Size(414, 896),
        SizedBox(
          width: 380,
          height: 620,
          child: NumberPad(
            input: '',
            onNumberTap: (_) {},
            onClear: () {},
            onSubmit: () {},
            isDisabled: false,
          ),
        ),
      );

      for (var i = 0; i <= 9; i++) {
        expect(find.text(i.toString()), findsOneWidget,
            reason: 'digit $i is missing from the pad');
      }
      expect(find.byIcon(Icons.backspace_rounded), findsOneWidget);
      expect(find.text('Enter'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('every digit key is the same size', (tester) async {
      await _pump(
        tester,
        const Size(414, 896),
        SizedBox(
          width: 380,
          height: 620,
          child: NumberPad(
            input: '',
            onNumberTap: (_) {},
            onClear: () {},
            onSubmit: () {},
            isDisabled: false,
            showSignToggle: true,
          ),
        ),
      );

      // 0 used to be shrunk to 76% whenever an extra key shared its row.
      final zero = tester.getSize(find.text('0'));
      final eight = tester.getSize(find.text('8'));
      expect(zero.height, closeTo(eight.height, 0.5));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the optional sign and colon keys each get a slot',
        (tester) async {
      await _pump(
        tester,
        const Size(414, 896),
        SizedBox(
          width: 380,
          height: 620,
          child: NumberPad(
            input: '',
            onNumberTap: (_) {},
            onClear: () {},
            onSubmit: () {},
            isDisabled: false,
            showSignToggle: true,
          ),
        ),
      );
      expect(find.text('+/-'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _pump(
        tester,
        const Size(414, 896),
        SizedBox(
          width: 380,
          height: 620,
          child: NumberPad(
            input: '',
            onNumberTap: (_) {},
            onClear: () {},
            onSubmit: () {},
            isDisabled: false,
            showColonButton: true,
            showInputDisplay: false,
          ),
        ),
      );
      expect(find.text(':'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('taps reach the right callbacks', (tester) async {
      final tapped = <String>[];
      var cleared = 0;
      var submitted = 0;

      await _pump(
        tester,
        const Size(414, 896),
        SizedBox(
          width: 380,
          height: 620,
          child: NumberPad(
            input: '',
            onNumberTap: tapped.add,
            onClear: () => cleared++,
            onSubmit: () => submitted++,
            isDisabled: false,
          ),
        ),
      );

      await tester.tap(find.text('7'));
      await tester.tap(find.byIcon(Icons.backspace_rounded));
      await tester.tap(find.byIcon(Icons.check_circle_rounded));
      await tester.pump();

      expect(tapped, ['7']);
      expect(cleared, 1);
      expect(submitted, 1);
    });

    testWidgets('disabled pad ignores taps', (tester) async {
      final tapped = <String>[];
      await _pump(
        tester,
        const Size(414, 896),
        SizedBox(
          width: 380,
          height: 620,
          child: NumberPad(
            input: '',
            onNumberTap: tapped.add,
            onClear: () {},
            onSubmit: () {},
            isDisabled: true,
          ),
        ),
      );

      await tester.tap(find.text('5'));
      await tester.pump();
      expect(tapped, isEmpty);
    });
  });

  group('AlphabetKeyboard', () {
    for (final screen in _screens) {
      testWidgets('lays out without overflow at ${screen.width.toInt()}px',
          (tester) async {
        await _pump(
          tester,
          screen,
          SizedBox(
            width: screen.width,
            child: AlphabetKeyboard(
              onLetterTap: (_) {},
              onBackspace: () {},
              onSubmit: () {},
              isDisabled: false,
              accentColor: const Color(0xFF4CAF50),
              inkColor: const Color(0xFF2F5233),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('shows all 26 letters plus both actions', (tester) async {
      await _pump(
        tester,
        const Size(414, 896),
        SizedBox(
          width: 400,
          child: AlphabetKeyboard(
            onLetterTap: (_) {},
            onBackspace: () {},
            onSubmit: () {},
            isDisabled: false,
            accentColor: const Color(0xFF4CAF50),
            inkColor: const Color(0xFF2F5233),
          ),
        ),
      );

      for (final letter in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('')) {
        expect(find.text(letter), findsOneWidget,
            reason: 'letter $letter is missing from the keyboard');
      }
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Enter'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the ten-key row fits inside the width it is given',
        (tester) async {
      // The old sizing divided by 10 without allowing for the 9 gaps between
      // keys, so the top row could be wider than the space available.
      const available = 330.0;
      await _pump(
        tester,
        const Size(360, 690),
        SizedBox(
          width: available,
          child: AlphabetKeyboard(
            onLetterTap: (_) {},
            onBackspace: () {},
            onSubmit: () {},
            isDisabled: false,
            accentColor: const Color(0xFF4CAF50),
            inkColor: const Color(0xFF2F5233),
          ),
        ),
      );

      final left = tester.getTopLeft(_keyOf('Q')).dx;
      final right = tester.getTopRight(_keyOf('P')).dx;
      expect(right - left, lessThanOrEqualTo(available + 0.5));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the action row lines up with the letter rows', (tester) async {
      await _pump(
        tester,
        const Size(414, 896),
        SizedBox(
          width: 400,
          child: AlphabetKeyboard(
            onLetterTap: (_) {},
            onBackspace: () {},
            onSubmit: () {},
            isDisabled: false,
            accentColor: const Color(0xFF4CAF50),
            inkColor: const Color(0xFF2F5233),
          ),
        ),
      );

      // Delete starts at the left edge of the letter block, and Enter ends at
      // its right edge, so the keyboard reads as one rectangle.
      final qLeft = tester.getTopLeft(_keyOf('Q')).dx;
      final pRight = tester.getTopRight(_keyOf('P')).dx;

      expect(tester.getTopLeft(_keyOf('Delete')).dx, closeTo(qLeft, 1.0));
      expect(tester.getTopRight(_keyOf('Enter')).dx, closeTo(pRight, 1.0));
      expect(tester.takeException(), isNull);
    });

    testWidgets('taps reach the right callbacks', (tester) async {
      final letters = <String>[];
      var backspaced = 0;
      var submitted = 0;

      await _pump(
        tester,
        const Size(414, 896),
        SizedBox(
          width: 400,
          child: AlphabetKeyboard(
            onLetterTap: letters.add,
            onBackspace: () => backspaced++,
            onSubmit: () => submitted++,
            isDisabled: false,
            accentColor: const Color(0xFF4CAF50),
            inkColor: const Color(0xFF2F5233),
          ),
        ),
      );

      await tester.tap(find.text('K'));
      await tester.tap(find.text('Delete'));
      await tester.tap(find.text('Enter'));
      await tester.pump();

      expect(letters, ['K']);
      expect(backspaced, 1);
      expect(submitted, 1);
    });
  });
}
