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

        final double panelExtent =
            (panelSize ?? min(maxAvailableWidth, maxAvailableHeight))
                .clamp(150.0, 560.0)
                .toDouble();

        final double panelPadding =
            (panelExtent * 0.045).clamp(10.0, 20.0).toDouble();
        final double effectiveSpacing =
            (spacing ?? (panelExtent * 0.025)).clamp(5.0, 12.0).toDouble();
        final double answerHeight = showInputDisplay
            ? (panelExtent * 0.17).clamp(46.0, 82.0).toDouble()
            : 0.0;

        final bottomButtons = <String>[
          if (showSignToggle) '+/-',
          'C',
          '0',
          if (showColonButton) ':',
          '→',
        ];
        final bottomButtonCount = bottomButtons.length;

        final maxButtonByGridWidth =
            (panelExtent - (panelPadding * 2) - (effectiveSpacing * 2)) / 3;
        final maxButtonByBottomWidth =
            (panelExtent -
                    (panelPadding * 2) -
                    (effectiveSpacing * (bottomButtonCount - 1))) /
                bottomButtonCount;
        final verticalSpacingCount = showInputDisplay ? 4 : 3;
        final maxButtonByHeight =
            (panelExtent -
                    (panelPadding * 2) -
                    answerHeight -
                    (effectiveSpacing * verticalSpacingCount)) /
                4;

        final double computedButtonSize = min(
          buttonSize ?? 100.0,
          min(
            maxButtonByGridWidth,
            min(maxButtonByBottomWidth, maxButtonByHeight),
          ),
        ).clamp(18.0, 116.0).toDouble();

        final gridWidth = computedButtonSize * 3 + effectiveSpacing * 2;
        final gridHeight = computedButtonSize * 3 + effectiveSpacing * 2;
        final bottomRowWidth = computedButtonSize * bottomButtonCount +
            effectiveSpacing * (bottomButtonCount - 1);
        final double answerFontSize =
            (computedButtonSize * 0.38).clamp(18.0, 34.0).toDouble();
        final double buttonFontSize =
            (computedButtonSize * 0.34).clamp(16.0, 34.0).toDouble();
        final double actionFontSize =
            (computedButtonSize * 0.27).clamp(14.0, 28.0).toDouble();

        return Align(
          alignment: alignment,
          child: SizedBox(
            width: panelExtent,
            height: panelExtent,
            child: Container(
              padding: EdgeInsets.all(panelPadding),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.86),
                borderRadius: BorderRadius.circular(
                  (panelExtent * 0.065).clamp(18.0, 34.0).toDouble(),
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
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: effectiveSpacing),
                  SizedBox(
                    width: bottomRowWidth,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var index = 0; index < bottomButtons.length; index++) ...[
                          _buttonForLabel(
                            bottomButtons[index],
                            computedButtonSize,
                            buttonFontSize: buttonFontSize,
                            actionFontSize: actionFontSize,
                          ),
                          if (index != bottomButtons.length - 1)
                            SizedBox(width: effectiveSpacing),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buttonForLabel(
    String label,
    double size, {
    required double buttonFontSize,
    required double actionFontSize,
  }) {
    switch (label) {
      case '+/-':
        return _uniformButton(
          label,
          size,
          action: _toggleSign,
          fontSize: actionFontSize,
        );
      case 'C':
        return _uniformButton(
          label,
          size,
          action: onClear,
          fontSize: actionFontSize,
        );
      case '→':
        return _uniformButton(
          label,
          size,
          action: onSubmit,
          fontSize: actionFontSize,
        );
      case ':':
        return _uniformButton(
          label,
          size,
          action: () => onNumberTap(':'),
          fontSize: buttonFontSize,
        );
      default:
        return _uniformButton(
          label,
          size,
          action: () => onNumberTap(label),
          fontSize: buttonFontSize,
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
            borderRadius: BorderRadius.circular(
              (size * 0.22).clamp(10.0, 22.0).toDouble(),
            ),
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
