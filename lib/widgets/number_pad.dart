import 'dart:math';

import 'package:flutter/material.dart';

import '../services/sound_service.dart';

class NumberPad extends StatelessWidget {
  final String input;
  final Function(String) onNumberTap;
  final VoidCallback onClear;
  final VoidCallback onSubmit;
  final bool isDisabled;
  final bool showSignToggle;
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
        final panelExtent = (panelSize ?? min(maxAvailableWidth, maxAvailableHeight))
            .clamp(150.0, 560.0);

        // No answer box here anymore. The answer is shown below the question,
        // so the keypad can be more compact and the buttons can be larger.
        final panelPadding = (panelExtent * 0.02).clamp(3.0, 10.0);
        final effectiveSpacing = (spacing ?? (panelExtent * 0.012)).clamp(2.0, 7.0);
        final bottomButtonCount = showSignToggle ? 4 : 3;

        final maxButtonByGridWidth =
            (panelExtent - (panelPadding * 2) - (effectiveSpacing * 2)) / 3;
        final maxButtonByBottomWidth =
            (panelExtent - (panelPadding * 2) - (effectiveSpacing * (bottomButtonCount - 1))) /
                bottomButtonCount;
        final maxButtonByHeight =
            (panelExtent - (panelPadding * 2) - (effectiveSpacing * 3)) / 4;

        final computedButtonSize = min(
          buttonSize ?? 132.0,
          min(maxButtonByGridWidth, min(maxButtonByBottomWidth, maxButtonByHeight)),
        ).clamp(38.0, 158.0);

        final gridWidth = computedButtonSize * 3 + effectiveSpacing * 2;
        final bottomRowWidth = computedButtonSize * bottomButtonCount +
            effectiveSpacing * (bottomButtonCount - 1);
        final buttonFontSize = (computedButtonSize * 0.45).clamp(22.0, 48.0);
        final actionFontSize = (computedButtonSize * 0.36).clamp(17.0, 36.0);

        return Align(
          alignment: alignment,
          child: SizedBox(
            width: panelExtent,
            height: panelExtent,
            child: Container(
              padding: EdgeInsets.all(panelPadding),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.86),
                borderRadius: BorderRadius.circular((panelExtent * 0.065).clamp(18.0, 34.0)),
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
                  _buttonRow(
                    width: gridWidth,
                    spacing: effectiveSpacing,
                    buttonSize: computedButtonSize,
                    buttons: [
                      _uniformButton('1', computedButtonSize, fontSize: buttonFontSize),
                      _uniformButton('2', computedButtonSize, fontSize: buttonFontSize),
                      _uniformButton('3', computedButtonSize, fontSize: buttonFontSize),
                    ],
                  ),
                  SizedBox(height: effectiveSpacing),
                  _buttonRow(
                    width: gridWidth,
                    spacing: effectiveSpacing,
                    buttonSize: computedButtonSize,
                    buttons: [
                      _uniformButton('4', computedButtonSize, fontSize: buttonFontSize),
                      _uniformButton('5', computedButtonSize, fontSize: buttonFontSize),
                      _uniformButton('6', computedButtonSize, fontSize: buttonFontSize),
                    ],
                  ),
                  SizedBox(height: effectiveSpacing),
                  _buttonRow(
                    width: gridWidth,
                    spacing: effectiveSpacing,
                    buttonSize: computedButtonSize,
                    buttons: [
                      _uniformButton('7', computedButtonSize, fontSize: buttonFontSize),
                      _uniformButton('8', computedButtonSize, fontSize: buttonFontSize),
                      _uniformButton('9', computedButtonSize, fontSize: buttonFontSize),
                    ],
                  ),
                  SizedBox(height: effectiveSpacing),
                  _buttonRow(
                    width: bottomRowWidth,
                    spacing: effectiveSpacing,
                    buttonSize: computedButtonSize,
                    buttons: [
                      if (showSignToggle)
                        _uniformButton(
                          '+/-',
                          computedButtonSize,
                          action: _toggleSign,
                          fontSize: actionFontSize,
                        ),
                      _uniformButton(
                        'C',
                        computedButtonSize,
                        action: onClear,
                        fontSize: actionFontSize,
                      ),
                      _uniformButton(
                        '0',
                        computedButtonSize,
                        action: () => onNumberTap('0'),
                        fontSize: buttonFontSize,
                      ),
                      _uniformButton(
                        '→',
                        computedButtonSize,
                        action: onSubmit,
                        fontSize: actionFontSize,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buttonRow({
    required List<Widget> buttons,
    required double width,
    required double spacing,
    required double buttonSize,
  }) {
    return SizedBox(
      width: width,
      height: buttonSize,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < buttons.length; i++) ...[
            if (i > 0) SizedBox(width: spacing),
            buttons[i],
          ],
        ],
      ),
    );
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
            borderRadius: BorderRadius.circular((size * 0.22).clamp(10.0, 22.0)),
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
