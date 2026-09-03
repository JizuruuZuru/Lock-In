import 'package:benchmark/widgets/tappable_word_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Recognizers used to be disposed and rebuilt at the top of every `build()`.
/// The quiz screens rebuild this widget on every setState, so that churned N
/// recognizers per rebuild - and a rebuild while a finger was down disposed
/// the recognizer holding the live gesture, throwing
/// "A TapGestureRecognizer was used after being disposed".
void main() {
  Widget host(String text, ValueChanged<String> onTap, {Key? key}) => MaterialApp(
        home: Scaffold(
          body: TappableWordText(
            key: key,
            text: text,
            style: const TextStyle(fontSize: 16),
            onWordTap: onTap,
          ),
        ),
      );

  testWidgets('a tappable word reports itself stripped of punctuation',
      (tester) async {
    final tapped = <String>[];
    await tester.pumpWidget(host('The planet, spins.', tapped.add));

    // Tap lands on the rich text; drive the recognizer through the span.
    final richText = tester.widget<RichText>(find.byType(RichText));
    final span = richText.text as TextSpan;
    final wordSpans = <TextSpan>[];
    span.visitChildren((s) {
      if (s is TextSpan && s.recognizer != null) wordSpans.add(s);
      return true;
    });

    expect(wordSpans, isNotEmpty, reason: '"planet" should be tappable');
    expect(wordSpans.map((s) => s.text), contains('planet,'));
  });

  testWidgets('rebuilding with unchanged text keeps the same recognizers',
      (tester) async {
    const key = ValueKey('tappable');
    await tester.pumpWidget(host('The planet spins slowly', (_) {}, key: key));

    List<Object?> recognizers() {
      final richText = tester.widget<RichText>(find.byType(RichText));
      final found = <Object?>[];
      (richText.text as TextSpan).visitChildren((s) {
        if (s is TextSpan && s.recognizer != null) found.add(s.recognizer);
        return true;
      });
      return found;
    }

    final before = recognizers();
    expect(before, isNotEmpty);

    // Same inputs: a rebuild must reuse, not tear down and re-allocate.
    await tester.pumpWidget(host('The planet spins slowly', (_) {}, key: key));
    final after = recognizers();

    expect(after.length, before.length);
    for (var i = 0; i < before.length; i++) {
      expect(identical(before[i], after[i]), isTrue,
          reason: 'recognizer $i was rebuilt for an unchanged prompt');
    }
  });

  testWidgets('changing the text does rebuild the spans', (tester) async {
    const key = ValueKey('tappable');
    await tester.pumpWidget(host('The planet spins', (_) {}, key: key));
    await tester.pumpWidget(host('Another sentence entirely', (_) {}, key: key));

    final richText = tester.widget<RichText>(find.byType(RichText));
    final text = (richText.text as TextSpan).toPlainText();
    expect(text, contains('Another'));
    expect(text, isNot(contains('planet')));
  });

  testWidgets('disposing after a rebuild does not throw', (tester) async {
    await tester.pumpWidget(host('The planet spins slowly', (_) {}));
    await tester.pumpWidget(host('The planet spins slowly', (_) {}));
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));

    expect(tester.takeException(), isNull);
  });
}
