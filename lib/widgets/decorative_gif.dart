import 'package:flutter/material.dart';

/// An `Image.asset` for the app's decorative GIFs, decoded at the size it is
/// actually drawn at.
///
/// The GIFs are large - `exam.gif` is 4.2 MB and `hard.gif` 3.6 MB - and a bare
/// `Image.asset` decodes every animated frame at the source resolution no
/// matter how small the box is. The exam-difficulty screen shows three of them
/// side by side, so that was three full-size decodes for three thumbnails.
/// Passing `cacheWidth` makes Flutter downsample once, on decode.
///
/// Also supplies an `errorBuilder`: without one a missing or corrupt asset
/// renders Flutter's grey error box in the middle of the menu.
class DecorativeGif extends StatelessWidget {
  /// Asset path, e.g. `assets/gifs/exam.gif`.
  final String assetPath;

  /// Roughly how wide the image is drawn, in logical pixels. Scaled by the
  /// device pixel ratio to pick the decode width. When null the image is
  /// decoded at full size, as before.
  final double? displayWidth;

  final BoxFit fit;

  const DecorativeGif({
    super.key,
    required this.assetPath,
    this.displayWidth,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final width = displayWidth;
    final ratio = MediaQuery.devicePixelRatioOf(context);

    return Image.asset(
      assetPath,
      fit: fit,
      gaplessPlayback: true,
      cacheWidth:
          (width == null || width <= 0) ? null : (width * ratio).round(),
      errorBuilder: (context, error, stackTrace) => const ColoredBox(
        color: Color(0x11000000),
        child: Center(
          child: Icon(Icons.image_not_supported_rounded, color: Colors.black26),
        ),
      ),
    );
  }
}
