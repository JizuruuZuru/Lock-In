import 'dart:async';

import 'package:flutter/material.dart';

import '../services/sound_service.dart';

class LevelUpPopup extends StatefulWidget {
  final int newLevel;
  final String message; // Custom message like "Great Job!" or achievement text
  final VoidCallback onContinue;

  const LevelUpPopup({
    super.key,
    required this.newLevel,
    required this.message,
    required this.onContinue,
  });

  @override
  State<LevelUpPopup> createState() => _LevelUpPopupState();
}

class _LevelUpPopupState extends State<LevelUpPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    unawaited(SoundService().playLevelUpSound());

    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInCubic),
    );

    _bounceAnimation = Tween<double>(begin: -30, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // `showDialog(barrierDismissible: false)` stops a tap outside, but not the
    // Android system back button. Backing out of this popup left the game
    // frozen behind it - `isGameOver` still true, the timer paused, every
    // answer button disabled - with no way to recover but the app-bar arrow.
    return PopScope(
      canPop: false,
      child: ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEE),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF9C27B0), width: 2.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x332C3550),
                  offset: Offset(8, 8),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Level Up Icon with animation.
                //
                // The AnimatedBuilder is what makes this move. `Transform`
                // read `_bounceAnimation.value` directly in build(), but the
                // only animated wrappers here are ScaleTransition and
                // FadeTransition - and those rebuild themselves, not their
                // child subtree. Nothing ever listened for this one, so the
                // star was painted once at `begin: -30` and sat permanently
                // 30px too high instead of bouncing into place.
                AnimatedBuilder(
                  animation: _bounceAnimation,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, _bounceAnimation.value),
                    child: child,
                  ),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF9C27B0), Color(0xFFF57C00)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF9C27B0).withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.star,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                const Text(
                  'Level Up!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF9C27B0),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),

                // Level Number
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9C27B0).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: const Color(0xFF9C27B0).withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    'Level ${widget.newLevel}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF9C27B0),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Message
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C1B47),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                // Continue Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      SoundService().playButtonSoundNow();
                      widget.onContinue();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9C27B0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      shadowColor: const Color(0xFF9C27B0).withValues(alpha: 0.5),
                      elevation: 8,
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
