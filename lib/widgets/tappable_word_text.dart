import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Renders a sentence where each long-enough word is individually tappable.
///
/// Used by the quiz screens so a student stuck on a word can tap it and get a
/// definition from the dictionary API, without leaving the question.
///
/// Punctuation and short words (articles, "is", "of", …) are rendered as plain
/// text — they are not worth a lookup and making them tappable would just make
/// the sentence look noisy.
class TappableWordText extends StatefulWidget {
  final String text;
  final TextStyle style;

  /// Colour applied to words that can be tapped, plus a dotted underline.
  final Color highlightColor;
  final TextAlign textAlign;

  /// Called with the tapped word, already stripped of punctuation.
  final ValueChanged<String> onWordTap;

  /// Words shorter than this stay plain.
  final int minWordLength;

  const TappableWordText({
    super.key,
    required this.text,
    required this.style,
    required this.onWordTap,
    this.highlightColor = const Color(0xFF1976D2),
    this.textAlign = TextAlign.center,
    this.minWordLength = 4,
  });

  @override
  State<TappableWordText> createState() => _TappableWordTextState();
}

class _TappableWordTextState extends State<TappableWordText> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  /// Very common words a lookup would not help with.
  static const Set<String> _stopWords = {
    'the', 'and', 'that', 'this', 'with', 'from', 'they', 'them', 'then',
    'have', 'has', 'had', 'was', 'were', 'are', 'you', 'your', 'his', 'her',
    'its', 'their', 'what', 'which', 'when', 'will', 'would', 'into', 'than',
    'there', 'these', 'those', 'each', 'some', 'because',
  };

  bool _isLookupable(String word) {
    final cleaned = _strip(word);
    if (cleaned.length < widget.minWordLength) return false;
    if (_stopWords.contains(cleaned.toLowerCase())) return false;
    // Anything with a digit is not a dictionary word.
    return !cleaned.contains(RegExp(r'[0-9]'));
  }

  String _strip(String word) {
    return word.replaceAll(RegExp(r"^[^A-Za-z'-]+|[^A-Za-z'-]+$"), '');
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();

    // Split on whitespace but keep the separators so spacing is preserved.
    final tokens = widget.text.split(RegExp(r'(\s+)'));
    final spans = <InlineSpan>[];

    for (var i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      if (token.isEmpty) continue;

      if (!_isLookupable(token)) {
        spans.add(TextSpan(text: token));
      } else {
        final recognizer = TapGestureRecognizer()
          ..onTap = () => widget.onWordTap(_strip(token));
        _recognizers.add(recognizer);

        spans.add(
          TextSpan(
            text: token,
            recognizer: recognizer,
            style: TextStyle(
              color: widget.highlightColor,
              decoration: TextDecoration.underline,
              decorationStyle: TextDecorationStyle.dotted,
              decorationThickness: 2,
            ),
          ),
        );
      }

      if (i < tokens.length - 1) spans.add(const TextSpan(text: ' '));
    }

    return Text.rich(
      TextSpan(style: widget.style, children: spans),
      textAlign: widget.textAlign,
    );
  }
}
