import 'package:flutter/material.dart';

enum ReactionGifState { thinking, success, fail }

class GameReactionGif extends StatelessWidget {
  final ReactionGifState state;
  final double? size;
  final double? width;
  final double? height;

  const GameReactionGif({
    super.key,
    required this.state,
    this.size,
    this.width,
    this.height,
  });

  static const String thinkingAsset = 'assets/gifs/thinking.gif';
  static const String successAsset = 'assets/gifs/success.gif';
  static const String failAsset = 'assets/gifs/fail.gif';

  String get _assetPath {
    switch (state) {
      case ReactionGifState.success:
        return successAsset;
      case ReactionGifState.fail:
        return failAsset;
      case ReactionGifState.thinking:
        return thinkingAsset;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double effectiveWidth = size ?? width ?? 280;
    final double effectiveHeight = size ?? height ?? effectiveWidth;

    return SizedBox(
      width: effectiveWidth,
      height: effectiveHeight,
      child: Container(
        padding: EdgeInsets.all((effectiveWidth * 0.012).clamp(2.0, 8.0)),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.48),
          borderRadius: BorderRadius.circular((effectiveWidth * 0.065).clamp(18.0, 34.0)),
          border: Border.all(color: Colors.white70, width: 1.8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 14,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular((effectiveWidth * 0.055).clamp(14.0, 28.0)),
          child: Image.asset(
            _assetPath,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.white,
                alignment: Alignment.center,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image_not_supported_rounded, size: 64),
                    SizedBox(height: 8),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'GIF asset not found. Add the GIFs to assets/gifs and declare them in pubspec.yaml.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
