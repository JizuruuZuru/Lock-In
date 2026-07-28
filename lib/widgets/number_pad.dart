import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/sound_service.dart';
import '../utils/responsive_layout.dart';

class NumberPad extends StatelessWidget {
  final String input;
  final Function(String) onNumberTap;
  final VoidCallback onClear;
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
        final double effectiveSpacing = desktop
            ? (spacing ?? (panelExtent * 0.016)).clamp(4.0, 8.0).toDouble()
            : (spacing ?? (panelExtent * 0.025)).clamp(5.0, 12.0).toDouble();
        final double actionRowSpacing =
            (effectiveSpacing * 4.8).clamp(28.0, 56.0).toDouble();
        final double bottomRowSpacing =
            (effectiveSpacing * 1.6).clamp(10.0, 22.0).toDouble();
        final double answerHeight = showInputDisplay
            ? (panelExtent * 0.17).clamp(46.0, 82.0).toDouble()
            : 0.0;

        final centerButtons = <String>[
          if (showSignToggle) '+/-',
          '0',
          if (showColonButton) ':',
        ];

        final maxButtonByGridWidth =
            (panelExtent - (panelPadding * 2) - (effectiveSpacing * 2)) / 3;
        final maxButtonByHeight =
            (panelExtent -
                    (panelPadding * 2) -
                    answerHeight -
                    (effectiveSpacing * 2) -
                    (showInputDisplay ? effectiveSpacing : 0) -
                    actionRowSpacing) /
                4;

        final double computedButtonSize = min(
          buttonSize ?? 100.0,
          min(maxButtonByGridWidth, maxButtonByHeight),
        ).clamp(18.0, 116.0).toDouble();

        final gridWidth = computedButtonSize * 3 + effectiveSpacing * 2;
        final gridHeight = computedButtonSize * 3 + effectiveSpacing * 2;
        final bottomRowWidth = gridWidth;
        final double bottomButtonSize = computedButtonSize;
        final double centerButtonSize = centerButtons.length <= 1
            ? computedButtonSize
            : min(
                computedButtonSize * 0.76,
                ((gridWidth - (computedButtonSize * 2) -
                            (bottomRowSpacing * 4)) /
                        centerButtons.length)
                    .clamp(18.0, computedButtonSize),
              ).toDouble();
        // Add a small safety buffer so Flutter debug mode never shows the
        // yellow/black RenderFlex overflow stripes from fractional pixel rounding.
        final contentHeight = panelPadding * 2 +
            answerHeight +
            (showInputDisplay ? effectiveSpacing : 0) +
            gridHeight +
            actionRowSpacing +
            bottomButtonSize +
            18;
        final panelHeight = contentHeight.clamp(120.0, 640.0).toDouble();
        final double answerFontSize = desktop
            ? (computedButtonSize * 0.46).clamp(22.0, 40.0).toDouble()
            : (computedButtonSize * 0.38).clamp(18.0, 34.0).toDouble();
        final double buttonFontSize = desktop
            ? (computedButtonSize * 0.42).clamp(20.0, 40.0).toDouble()
            : (computedButtonSize * 0.34).clamp(16.0, 34.0).toDouble();
        final double actionFontSize = desktop
            ? (computedButtonSize * 0.32).clamp(16.0, 32.0).toDouble()
            : (computedButtonSize * 0.27).clamp(14.0, 28.0).toDouble();
        final double buttonRadius = desktop
            ? (computedButtonSize * 0.12).clamp(6.0, 10.0).toDouble()
            : (computedButtonSize * 0.22).clamp(10.0, 22.0).toDouble();

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
                border: Border.all(color: const Color(0x1F000000), width: 1.3),
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
                    SizedBox(
                      height: answerHeight,
                      child: Container(
                        width: double.infinity,
                        alignment: Alignment.center,
                        padding: EdgeInsets.symmetric(
                          horizontal: (panelExtent * 0.035)
                              .clamp(8.0, 16.0)
                              .toDouble(),
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7FB),
                          borderRadius: BorderRadius.circular(
                            (panelExtent * 0.045)
                                .clamp(12.0, 22.0)
                                .toDouble(),
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
                              fontSize: answerFontSize,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: effectiveSpacing),
                  ],
                  SizedBox(
                    width: gridWidth,
                    height: gridHeight,
                    child: GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: effectiveSpacing,
                      crossAxisSpacing: effectiveSpacing,
                      childAspectRatio: 1.0,
                      children: [
                        for (var i = 1; i <= 9; i++)
                          _uniformButton(
                            i.toString(),
                            computedButtonSize,
                            fontSize: buttonFontSize,
                            radius: buttonRadius,
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: actionRowSpacing),
                  SizedBox(
                    width: bottomRowWidth,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buttonForLabel(
                          'Delete',
                          bottomButtonSize,
                          buttonFontSize: buttonFontSize,
                          actionFontSize: actionFontSize,
                          radius: buttonRadius,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var index = 0; index < centerButtons.length; index++) ...[
                              _buttonForLabel(
                                centerButtons[index],
                                centerButtonSize,
                                buttonFontSize: buttonFontSize,
                                actionFontSize: actionFontSize,
                                radius: buttonRadius,
                              ),
                              if (index != centerButtons.length - 1)
                                SizedBox(width: bottomRowSpacing),
                            ],
                          ],
                        ),
                        _buttonForLabel(
                          'Enter',
                          bottomButtonSize,
                          buttonFontSize: buttonFontSize,
                          actionFontSize: actionFontSize,
                          radius: buttonRadius,
                        ),
                      ],
                    ),
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

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (isDisabled) return KeyEventResult.ignored;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.backspace) {
      onClear();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
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

  Widget _buttonForLabel(
    String label,
    double size, {
    required double buttonFontSize,
    required double actionFontSize,
    required double radius,
  }) {
    switch (label) {
      case '+/-':
        return _uniformButton(
          label,
          size,
          action: _toggleSign,
          fontSize: actionFontSize,
          radius: radius,
        );
      case 'Delete':
        return _uniformButton(
          label,
          size,
          action: onClear,
          fontSize: actionFontSize,
          radius: radius,
        );
      case 'Enter':
        return _uniformButton(
          label,
          size,
          action: onSubmit,
          fontSize: actionFontSize,
          radius: radius,
        );
      case ':':
        return _uniformButton(
          label,
          size,
          action: () => onNumberTap(':'),
          fontSize: buttonFontSize,
          radius: radius,
        );
      default:
        return _uniformButton(
          label,
          size,
          action: () => onNumberTap(label),
          fontSize: buttonFontSize,
          radius: radius,
        );
    }
  }

  void _toggleSign() {
    if (isDisabled) return;
    SoundService().playButtonSoundNow();
    onNumberTap('-');
  }

  Widget _uniformButton(
    String label,
    double size, {
    VoidCallback? action,
    required double fontSize,
    required double radius,
  }) {
    final buttonAction = action ?? () => onNumberTap(label);

    return SizedBox(
      width: size,
      height: size,
      child: ElevatedButton(
        onPressed: isDisabled ? null : buttonAction,
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
}
