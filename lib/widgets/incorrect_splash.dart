import 'package:flutter/material.dart';

class IncorrectSplash extends StatefulWidget {
  final VoidCallback? onComplete;
  final Duration duration;

  const IncorrectSplash({
    super.key,
    this.onComplete,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  State<IncorrectSplash> createState() => _IncorrectSplashState();
}

class _IncorrectSplashState extends State<IncorrectSplash>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // Fade animation: in quickly, then out
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.4)),
    );

    // Scale animation: grow slightly during appearance
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward().then((_) {
      if (mounted) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Fade out after reaching peak
        final fadeOutStart = 0.5;
        final fadeOutProgress = (_controller.value - fadeOutStart) / (1 - fadeOutStart);
        final opacity = _controller.value < fadeOutStart
            ? _fadeAnimation.value
            : (1 - fadeOutProgress).clamp(0, 1).toDouble();

        return Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF44336).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cancel,
                      size: 80,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Incorrect!',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withValues(alpha: 0.9),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
