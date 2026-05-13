import 'dart:async';

import 'package:flutter/material.dart';

import '../services/sound_service.dart';

class LevelUpPopup extends StatefulWidget {
  final int newLevel;
  final String message;
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
      duration: const Duration(milliseconds: 650),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInCubic),
    );

    _bounceAnimation = Tween<double>(begin: -26, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirmContinue() async {
    SoundService().playButtonSoundNow();
    final shouldContinue = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Go to next level?'),
        content: Text('Proceed to Level ${widget.newLevel}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Next'),
          ),
        ],
      ),
    );

    if (shouldContinue == true && mounted) {
      widget.onContinue();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final gifHeight = (screen.height * 0.22).clamp(170.0, 250.0);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEE),
              borderRadius: BorderRadius.circular(26),
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
                Transform.translate(
                  offset: Offset(0, _bounceAnimation.value),
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF9C27B0), Color(0xFFF57C00)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(48),
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
                      size: 56,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Level Up!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF9C27B0),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 10),
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
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: double.infinity,
                    height: gifHeight,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        'assets/gifs/clap.gif',
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _confirmContinue,
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
    );
  }
}
