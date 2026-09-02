import 'dart:math' as math;

import 'package:flutter/material.dart';

enum BackgroundShapeKind {
  roundedSquare,
  circle,
  diamond,
  capsule,
  iconBadge,
}

class AnimatedBackgroundShape {
  final BackgroundShapeKind kind;
  final Alignment alignment;
  final Offset baseOffset;
  final Offset drift;
  final double size;
  final Color color;
  final Color borderColor;
  final double borderWidth;
  final double cornerRadius;
  final double initialRotation;
  final double rotationDrift;
  final double phase;
  final IconData? iconData;
  final String? symbol;
  final Color? contentColor;
  final double contentScale;
  final FontWeight symbolWeight;

  const AnimatedBackgroundShape({
    required this.kind,
    required this.alignment,
    required this.baseOffset,
    required this.drift,
    required this.size,
    required this.color,
    required this.borderColor,
    this.borderWidth = 2,
    this.cornerRadius = 24,
    this.initialRotation = 0,
    this.rotationDrift = 0.08,
    this.phase = 0,
    this.iconData,
    this.symbol,
    this.contentColor,
    this.contentScale = 0.48,
    this.symbolWeight = FontWeight.w900,
  });
}

class AnimatedShapeBackground extends StatefulWidget {
  final List<Color> gradientColors;
  final Alignment begin;
  final Alignment end;
  final Duration duration;
  final List<AnimatedBackgroundShape> shapes;
  final Widget child;

  const AnimatedShapeBackground({
    super.key,
    required this.gradientColors,
    required this.shapes,
    required this.child,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
    this.duration = const Duration(seconds: 24),
  });

  @override
  State<AnimatedShapeBackground> createState() =>
      _AnimatedShapeBackgroundState();
}

class _AnimatedShapeBackgroundState extends State<AnimatedShapeBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.gradientColors,
          begin: widget.begin,
          end: widget.end,
        ),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        // The page content does not depend on the animation, so it is passed
        // through `child` and reused instead of being rebuilt. Without this the
        // whole subtree under the background - the entire game screen - was
        // reallocated 60 times a second, and this controller `repeat`s forever
        // on the home menu, every game, the leaderboard, and both auth screens.
        child: widget.child,
        builder: (context, child) {
          final t = _controller.value * math.pi * 2;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < widget.shapes.length; i++)
                _buildShape(widget.shapes[i], i, t),
              Positioned.fill(child: child!),
            ],
          );
        },
      ),
    );
  }

  Widget _buildShape(AnimatedBackgroundShape shape, int index, double t) {
    final phase = shape.phase + (index * 0.7);
    final dx = shape.baseOffset.dx + math.sin(t + phase) * shape.drift.dx;
    final dy =
        shape.baseOffset.dy + math.cos((t * 0.85) + phase) * shape.drift.dy;
    final rotation = shape.initialRotation +
        math.sin((t * 0.55) + phase) * shape.rotationDrift;

    return Align(
      alignment: shape.alignment,
      child: Transform.translate(
        offset: Offset(dx, dy),
        child: Transform.rotate(
          angle: rotation,
          child: _shapeBody(shape),
        ),
      ),
    );
  }

  Widget _shapeBody(AnimatedBackgroundShape shape) {
    final decoration = BoxDecoration(
      color: shape.color,
      border: Border.all(color: shape.borderColor, width: shape.borderWidth),
    );

    switch (shape.kind) {
      case BackgroundShapeKind.circle:
        return Container(
          width: shape.size,
          height: shape.size,
          decoration: decoration.copyWith(shape: BoxShape.circle),
        );
      case BackgroundShapeKind.diamond:
        return Transform.rotate(
          angle: math.pi / 4,
          child: Container(
            width: shape.size,
            height: shape.size,
            decoration: decoration.copyWith(
              borderRadius: BorderRadius.circular(shape.cornerRadius),
            ),
          ),
        );
      case BackgroundShapeKind.capsule:
        return Container(
          width: shape.size * 1.45,
          height: shape.size * 0.72,
          decoration: decoration.copyWith(
            borderRadius: BorderRadius.circular(shape.size),
          ),
        );
      case BackgroundShapeKind.roundedSquare:
        return Container(
          width: shape.size,
          height: shape.size,
          decoration: decoration.copyWith(
            borderRadius: BorderRadius.circular(shape.cornerRadius),
          ),
        );
      case BackgroundShapeKind.iconBadge:
        return Container(
          width: shape.size,
          height: shape.size,
          decoration: decoration.copyWith(
            borderRadius: BorderRadius.circular(shape.cornerRadius),
          ),
          alignment: Alignment.center,
          child: shape.symbol != null
              ? Text(
                  shape.symbol!,
                  style: TextStyle(
                    fontSize: shape.size * shape.contentScale,
                    fontWeight: shape.symbolWeight,
                    color: shape.contentColor ?? shape.borderColor,
                    height: 1,
                  ),
                )
              : Icon(
                  shape.iconData ?? Icons.circle,
                  size: shape.size * shape.contentScale,
                  color: shape.contentColor ?? shape.borderColor,
                ),
        );
    }
  }
}
