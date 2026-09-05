import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/sound_service.dart';
import '../utils/responsive_layout.dart';

/// The shared on-screen number pad, laid out as a phone keypad:
///
/// ```
///   1    2    3
///   4    5    6
///   7    8    9
///  +/-   0    <x
///  [    Enter    ]
/// ```
///
/// Every cell in the grid is the same size, and the only vertical rhythm is one
/// spacing value repeated. The optional sign / colon key takes the free slot to
/// the left of `0`; when neither is shown that slot stays empty so `0` keeps
/// its place under `8`, the way a real keypad reads.
class NumberPad extends StatelessWidget {
  final String input;
  final Function(String) onNumberTap;
  final VoidCallback onClear;

  /// Deletes the last character. Optional so existing callers keep working,
  /// falling back to [onClear].
  ///
  /// Without it there was no way to correct a single digit: the key drawn as a
  /// backspace, and the hardware Backspace, both wiped the whole answer -
  /// mid-question, with the timer running. `AlphabetKeyboard` has always had
  /// this; the number pad simply never did.
  final VoidCallback? onBackspace;
  final VoidCallback onSubmit;
  final bool isDisabled;
  final bool showSignToggle;
  final bool showColonButton;
  final bool showInputDisplay;
  final double? buttonSize;
  final double? spacing;
  final Alignment alignment;
  final double? panelSize;

  const NumberPad({
    super.key,
    required this.input,
    required this.onNumberTap,
    required this.onClear,
    this.onBackspace,
    required this.onSubmit,
    required this.isDisabled,
    this.showSignToggle = false,
    this.showColonButton = false,
    this.showInputDisplay = true,
    this.buttonSize,
    this.spacing,
    this.alignment = Alignment.center,
    this.panelSize,
  });

  /// Height of the Enter bar as a fraction of one grid button.
  static const double _enterHeightRatio = 0.64;

  /// The panel's border. A decoration border eats into a Container's content
  /// box on every side, so it has to be part of the size arithmetic below -
  /// leaving it out is what used to cost 2.6px and force a fudge factor.
  static const double _panelBorder = 1.3;

  /// The key that shares row four with `0` and Delete, if any. Only one is ever
  /// requested: the sign toggle by the subtraction games, the colon by the
  /// clock game.
  String? get _extraKey {
    if (showSignToggle) return '+/-';
    if (showColonButton) return ':';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaSize = MediaQuery.sizeOf(context);
        final fallbackSize = min(mediaSize.width, mediaSize.height) * 0.82;
        final maxAvailableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : fallbackSize;
        final maxAvailableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : fallbackSize;

        final bool desktop = isDesktopLayout(maxAvailableWidth);

        final double panelExtent =
            (panelSize ?? min(maxAvailableWidth, maxAvailableHeight))
                .clamp(150.0, 560.0)
                .toDouble();

        final double panelPadding = desktop
            ? (panelExtent * 0.024).clamp(6.0, 12.0).toDouble()
            : (panelExtent * 0.038).clamp(8.0, 18.0).toDouble();
        final double gap = desktop
            ? (spacing ?? (panelExtent * 0.016)).clamp(4.0, 8.0).toDouble()
            : (spacing ?? (panelExtent * 0.025)).clamp(5.0, 12.0).toDouble();
        final double answerHeight = showInputDisplay
            ? (panelExtent * 0.17).clamp(46.0, 82.0).toDouble()
            : 0.0;

        // What the border and padding leave for content, on each axis.
        final double chrome = (panelPadding + _panelBorder) * 2;

        // Width: three columns and two gaps.
        final double maxButtonByWidth = (panelExtent - chrome - (gap * 2)) / 3;

        // Height: four grid rows (three gaps), one gap, then the Enter bar.
        // Solving `4b + 3g + g + b * ratio = available` for b.
        final double verticalRoom = panelExtent -
            chrome -
            answerHeight -
            (showInputDisplay ? gap : 0) -
            (gap * 4);
        final double maxButtonByHeight = verticalRoom / (4 + _enterHeightRatio);

        final double button = min(
          buttonSize ?? 100.0,
          min(maxButtonByWidth, maxButtonByHeight),
        ).clamp(18.0, 116.0).toDouble();

        final double gridWidth = button * 3 + gap * 2;
        final double gridHeight = button * 4 + gap * 3;
        final double enterHeight = button * _enterHeightRatio;

        final double panelHeight = (chrome +
                answerHeight +
                (showInputDisplay ? gap : 0) +
                gridHeight +
                gap +
                enterHeight)
            .clamp(120.0, 640.0)
            .toDouble();

        final double answerFontSize = desktop
            ? (button * 0.46).clamp(22.0, 40.0).toDouble()
            : (button * 0.38).clamp(18.0, 34.0).toDouble();
        final double digitFontSize = desktop
            ? (button * 0.42).clamp(20.0, 40.0).toDouble()
            : (button * 0.34).clamp(16.0, 34.0).toDouble();
        final double actionFontSize = desktop
            ? (button * 0.32).clamp(16.0, 32.0).toDouble()
            : (button * 0.27).clamp(14.0, 28.0).toDouble();
        final double radius = desktop
            ? (button * 0.12).clamp(6.0, 10.0).toDouble()
            : (button * 0.22).clamp(10.0, 22.0).toDouble();

        final extra = _extraKey;

        return Focus(
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
          child: Align(
            alignment: alignment,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: alignment,
              child: SizedBox(
                width: panelExtent,
                height: panelHeight,
                child: Container(
                  padding: EdgeInsets.all(panelPadding),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.86),
                    borderRadius: BorderRadius.circular(
                      desktop
                          ? (panelExtent * 0.035).clamp(10.0, 16.0).toDouble()
                          : (panelExtent * 0.065).clamp(18.0, 34.0).toDouble(),
                    ),
                    border: Border.all(
                      color: const Color(0x1F000000),
                      width: _panelBorder,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x18000000),
                        blurRadius: 14,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showInputDisplay) ...[
                        _answerDisplay(panelExtent, answerHeight,
                            answerFontSize),
                        SizedBox(height: gap),
                      ],
                      SizedBox(
                        width: gridWidth,
                        height: gridHeight,
                        child: GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: gap,
                          crossAxisSpacing: gap,
                          childAspectRatio: 1.0,
                          children: [
                            for (var i = 1; i <= 9; i++)
                              _digitKey(i.toString(), button,
                                  fontSize: digitFontSize, radius: radius),
                            // Row four. The empty slot keeps 0 centred under 8
                            // when no sign or colon key was asked for.
                            if (extra == null)
                              const SizedBox.shrink()
                            else
                              _digitKey(
                                extra,
                                button,
                                fontSize: extra == '+/-'
                                    ? actionFontSize
                                    : digitFontSize,
                                radius: radius,
                                action: extra == '+/-'
                                    ? _toggleSign
                                    : () => onNumberTap(extra),
                              ),
                            _digitKey('0', button,
                                fontSize: digitFontSize, radius: radius),
                            _deleteKey(context, button,
                                iconSize: digitFontSize, radius: radius),
                          ],
                        ),
                      ),
                      SizedBox(height: gap),
                      _enterBar(
                        context,
                        width: gridWidth,
                        height: enterHeight,
                        fontSize: actionFontSize,
                        radius: radius,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _answerDisplay(double panelExtent, double height, double fontSize) {
    return SizedBox(
      height: height,
      child: Container(
        width: double.infinity,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(
          horizontal: (panelExtent * 0.035).clamp(8.0, 16.0).toDouble(),
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FB),
          borderRadius: BorderRadius.circular(
            (panelExtent * 0.045).clamp(12.0, 22.0).toDouble(),
          ),
          border: Border.all(color: const Color(0xFFD6DFEB)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            input.isEmpty ? 'Your Answer' : input,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (isDisabled) return KeyEventResult.ignored;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.backspace) {
      (onBackspace ?? onClear)();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      onSubmit();
      return KeyEventResult.handled;
    }
    if (showSignToggle &&
        (key == LogicalKeyboardKey.minus ||
            key == LogicalKeyboardKey.numpadSubtract)) {
      _toggleSign();
      return KeyEventResult.handled;
    }

    final digit = _digitForKey(key);
    if (digit != null) {
      onNumberTap(digit);
      return KeyEventResult.handled;
    }
    if (showColonButton &&
        (key == LogicalKeyboardKey.semicolon || event.character == ':')) {
      onNumberTap(':');
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  String? _digitForKey(LogicalKeyboardKey key) {
    const digitKeys = [
      LogicalKeyboardKey.digit0,
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit5,
      LogicalKeyboardKey.digit6,
      LogicalKeyboardKey.digit7,
      LogicalKeyboardKey.digit8,
      LogicalKeyboardKey.digit9,
    ];
    const numpadKeys = [
      LogicalKeyboardKey.numpad0,
      LogicalKeyboardKey.numpad1,
      LogicalKeyboardKey.numpad2,
      LogicalKeyboardKey.numpad3,
      LogicalKeyboardKey.numpad4,
      LogicalKeyboardKey.numpad5,
      LogicalKeyboardKey.numpad6,
      LogicalKeyboardKey.numpad7,
      LogicalKeyboardKey.numpad8,
      LogicalKeyboardKey.numpad9,
    ];
    final digitIndex = digitKeys.indexOf(key);
    if (digitIndex != -1) return digitIndex.toString();
    final numpadIndex = numpadKeys.indexOf(key);
    if (numpadIndex != -1) return numpadIndex.toString();
    return null;
  }

  void _toggleSign() {
    if (isDisabled) return;
    SoundService().playButtonSoundNow();
    onNumberTap('-');
  }

  Widget _digitKey(
    String label,
    double size, {
    required double fontSize,
    required double radius,
    VoidCallback? action,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: ElevatedButton(
        onPressed: isDisabled ? null : (action ?? () => onNumberTap(label)),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size(size, size),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          textStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label),
        ),
      ),
    );
  }

  /// Delete sits in the grid but is styled to recede, so the digits stay the
  /// thing the eye lands on.
  Widget _deleteKey(
    BuildContext context,
    double size, {
    required double iconSize,
    required double radius,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: ElevatedButton(
        onPressed: isDisabled ? null : (onBackspace ?? onClear),
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.surfaceContainerHighest,
          foregroundColor: scheme.onSurfaceVariant,
          padding: EdgeInsets.zero,
          minimumSize: Size(size, size),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
            side: BorderSide(color: scheme.outlineVariant),
          ),
        ),
        child: Icon(Icons.backspace_rounded, size: iconSize),
      ),
    );
  }

  /// Enter spans the whole grid. It is the one action a player repeats every
  /// question, so it gets the largest, hardest-to-miss target.
  Widget _enterBar(
    BuildContext context, {
    required double width,
    required double height,
    required double fontSize,
    required double radius,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton.icon(
        onPressed: isDisabled ? null : onSubmit,
        icon: Icon(Icons.check_circle_rounded, size: fontSize + 2),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Enter',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: EdgeInsets.symmetric(horizontal: height * 0.4),
          minimumSize: Size(width, height),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
    );
  }
}
