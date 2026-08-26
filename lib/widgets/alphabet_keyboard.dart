import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/sound_service.dart';
import '../utils/responsive_layout.dart';

/// A cellphone-style on-screen QWERTY keyboard for typing single words.
///
/// The three letter rows and the action row all span the same width, so the
/// block reads as one rectangle rather than three centred strips of different
/// lengths. Key size is solved from the available width *including* the gaps
/// between keys, which is what keeps the ten-key top row from overflowing on
/// narrow phones.
class AlphabetKeyboard extends StatelessWidget {
  final Function(String) onLetterTap;
  final VoidCallback onBackspace;
  final VoidCallback onSubmit;
  final bool isDisabled;
  final Color accentColor;
  final Color inkColor;

  static const _rows = [
    ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
    ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
    ['Z', 'X', 'C', 'V', 'B', 'N', 'M'],
  ];

  /// Keys in the widest row. Everything is sized against this.
  static const int _columns = 10;

  /// Gap between keys, as a fraction of one key's width.
  static const double _gapRatio = 0.12;

  /// Letter keys are slightly taller than they are wide, as on a phone.
  static const double _keyAspect = 1.15;

  const AlphabetKeyboard({
    super.key,
    required this.onLetterTap,
    required this.onBackspace,
    required this.onSubmit,
    required this.isDisabled,
    required this.accentColor,
    required this.inkColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final desktop = isDesktopLayout(width);

        // A row is `_columns` keys plus `_columns - 1` gaps, and each gap is
        // `_gapRatio` of a key. The gap is settled first, then the key width is
        // taken from whatever is left, so the widest row fills the space
        // exactly. Sizing the key first and clamping it *up* to a floor is what
        // used to push the ten-key row past the edge on a 320px phone.
        final double ideal = width / (_columns + (_columns - 1) * _gapRatio);
        final double gap = (ideal * _gapRatio).clamp(3.0, 8.0).toDouble();

        // Only ever capped, never raised: a key is allowed to end up small on a
        // narrow screen, but it must not be wider than its share of the row.
        final double cap = desktop ? 84.0 : 56.0;
        final double keySize =
            min((width - gap * (_columns - 1)) / _columns, cap);
        final double keyHeight = keySize * _keyAspect;
        final double rowWidth = keySize * _columns + gap * (_columns - 1);

        final double fontSize = desktop
            ? (keySize * 0.46).clamp(18.0, 32.0).toDouble()
            : (keySize * 0.42).clamp(14.0, 22.0).toDouble();
        final double radius = desktop
            ? (keySize * 0.12).clamp(6.0, 10.0).toDouble()
            : (keySize * 0.22).clamp(6.0, 12.0).toDouble();

        return Focus(
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
          child: SizedBox(
            width: rowWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final row in _rows) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final letter in row) ...[
                        _key(letter, keySize, keyHeight, fontSize, radius),
                        if (letter != row.last) SizedBox(width: gap),
                      ],
                    ],
                  ),
                  SizedBox(height: gap),
                ],
                // Delete and Enter split the full row width, so the block ends
                // flush with the letters above rather than floating narrower.
                Row(
                  children: [
                    Expanded(
                      child: _actionKey(
                        icon: Icons.backspace_rounded,
                        label: 'Delete',
                        height: keyHeight,
                        fontSize: fontSize,
                        radius: radius,
                        onTap: onBackspace,
                      ),
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      child: _actionKey(
                        icon: Icons.check_circle_rounded,
                        label: 'Enter',
                        height: keyHeight,
                        fontSize: fontSize,
                        radius: radius,
                        onTap: onSubmit,
                        filled: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (isDisabled) return KeyEventResult.ignored;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.backspace) {
      SoundService().playButtonSoundNow();
      onBackspace();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      SoundService().playButtonSoundNow();
      onSubmit();
      return KeyEventResult.handled;
    }

    final char = event.character;
    if (char != null && char.length == 1) {
      final upper = char.toUpperCase();
      if (_letter.hasMatch(upper)) {
        SoundService().playButtonSoundNow();
        onLetterTap(upper);
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  /// Compiled once rather than rebuilt on every key event.
  static final RegExp _letter = RegExp(r'^[A-Z]$');

  Widget _key(
    String letter,
    double width,
    double height,
    double fontSize,
    double radius,
  ) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isDisabled
            ? null
            : () {
                SoundService().playButtonSoundNow();
                onLetterTap(letter);
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: inkColor,
          padding: EdgeInsets.zero,
          minimumSize: Size(width, height),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
            side: BorderSide(color: inkColor.withValues(alpha: 0.35)),
          ),
          elevation: 1,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            letter,
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }

  Widget _actionKey({
    required IconData icon,
    required String label,
    required double height,
    required double fontSize,
    required double radius,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    return SizedBox(
      height: height,
      child: ElevatedButton.icon(
        onPressed: isDisabled
            ? null
            : () {
                SoundService().playButtonSoundNow();
                onTap();
              },
        icon: Icon(icon, size: fontSize + 4),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontSize: fontSize * 0.8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: filled ? accentColor : Colors.white,
          foregroundColor: filled ? Colors.white : inkColor,
          padding: EdgeInsets.symmetric(horizontal: height * 0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
            side: BorderSide(color: inkColor.withValues(alpha: 0.35)),
          ),
        ),
      ),
    );
  }
}
