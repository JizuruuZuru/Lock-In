import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/sound_service.dart';
import '../utils/responsive_layout.dart';

/// A cellphone-style on-screen QWERTY keyboard for typing single words.
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
        final keyWidth = (width - 16) / 10;
        final keySize = desktop
            ? keyWidth.clamp(30.0, 84.0).toDouble()
            : keyWidth.clamp(30.0, 56.0).toDouble();
        final fontSize = desktop
            ? (keySize * 0.46).clamp(18.0, 32.0).toDouble()
            : (keySize * 0.42).clamp(14.0, 22.0).toDouble();
        final spacing = desktop
            ? (keySize * 0.08).clamp(3.0, 6.0).toDouble()
            : (keySize * 0.12).clamp(4.0, 8.0).toDouble();
        final radius = desktop
            ? (keySize * 0.12).clamp(6.0, 10.0).toDouble()
            : (keySize * 0.22).clamp(6.0, 12.0).toDouble();

        return Focus(
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final row in _rows) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final letter in row) ...[
                      _key(letter, keySize, fontSize, radius),
                      if (letter != row.last) SizedBox(width: spacing),
                    ],
                  ],
                ),
                SizedBox(height: spacing),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _actionKey(
                    icon: Icons.backspace_rounded,
                    label: 'Delete',
                    width: keySize * 1.9,
                    height: keySize,
                    fontSize: fontSize,
                    radius: radius,
                    onTap: onBackspace,
                  ),
                  SizedBox(width: spacing),
                  _actionKey(
                    icon: Icons.check_circle_rounded,
                    label: 'Enter',
                    width: keySize * 1.9,
                    height: keySize,
                    fontSize: fontSize,
                    radius: radius,
                    onTap: onSubmit,
                    filled: true,
                  ),
                ],
              ),
            ],
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
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      SoundService().playButtonSoundNow();
      onSubmit();
      return KeyEventResult.handled;
    }

    final char = event.character;
    if (char != null && char.length == 1) {
      final upper = char.toUpperCase();
      if (RegExp(r'^[A-Z]$').hasMatch(upper)) {
        SoundService().playButtonSoundNow();
        onLetterTap(upper);
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  Widget _key(String letter, double size, double fontSize, double radius) {
    return SizedBox(
      width: size,
      height: size * 1.15,
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
          minimumSize: Size(size, size * 1.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
            side: BorderSide(color: inkColor.withValues(alpha: 0.35)),
          ),
          elevation: 1,
        ),
        child: Text(
          letter,
          style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  Widget _actionKey({
    required IconData icon,
    required String label,
    required double width,
    required double height,
    required double fontSize,
    required double radius,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton.icon(
        onPressed: isDisabled
            ? null
            : () {
                SoundService().playButtonSoundNow();
                onTap();
              },
        icon: Icon(icon, size: fontSize + 4),
        label: Text(
          label,
          style: TextStyle(fontSize: fontSize * 0.8, fontWeight: FontWeight.w800),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: filled ? accentColor : Colors.white,
          foregroundColor: filled ? Colors.white : inkColor,
          minimumSize: Size(width, height),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
            side: BorderSide(color: inkColor.withValues(alpha: 0.35)),
          ),
        ),
      ),
    );
  }
}
