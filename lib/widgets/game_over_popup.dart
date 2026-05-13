import 'package:flutter/material.dart';

import '../services/sound_service.dart';
import 'game_confirmation_dialog.dart';

class GameOverPopup extends StatefulWidget {
  final String incorrectAnswer;
  final String correctAnswer;
  final int heartsRemaining;
  final int? score; // Optional score for final game over
  final int? level; // Optional level for final game over
  final VoidCallback onRetry;
  final VoidCallback onBack;

  const GameOverPopup({
    super.key,
    required this.incorrectAnswer,
    required this.correctAnswer,
    required this.heartsRemaining,
    this.score,
    this.level,
    required this.onRetry,
    required this.onBack,
  });

  @override
  State<GameOverPopup> createState() => _GameOverPopupState();
}

class _GameOverPopupState extends State<GameOverPopup>
    with SingleTickerProviderStateMixin {
  static const double _actionButtonHeight = 52;
  static const TextStyle _actionButtonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.5,
  );

  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInCubic),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }


  Future<void> _confirmBack() async {
    if (!mounted) return;
    SoundService().playButtonSoundNow();

    final shouldGoBack = await GameConfirmationDialog.show(
      context,
      title: 'Go back?',
      message: 'Are you sure you want to go back? This review popup will close.',
      confirmText: 'Back',
      cancelText: 'Stay',
      confirmColor: const Color(0xFF9C27B0),
      icon: Icons.arrow_back_rounded,
    );

    if (!mounted || !shouldGoBack) return;
    widget.onBack();
  }

  ButtonStyle _primaryActionButtonStyle(Color backgroundColor) {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(_actionButtonHeight),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      textStyle: _actionButtonTextStyle,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      elevation: 0,
    );
  }

  ButtonStyle _secondaryActionButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF9C27B0),
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(_actionButtonHeight),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      textStyle: _actionButtonTextStyle,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      elevation: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if this is a final game over (hearts = 0)
    final isFinalGameOver = widget.heartsRemaining == 0;

    return ScaleTransition(
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
              border: Border.all(color: const Color(0xFF2C1B47), width: 2.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x332C3550),
                  offset: Offset(8, 8),
                  blurRadius: 16,
                ),
              ],
            ),
            child:
                isFinalGameOver ? _buildFinalGameOver() : _buildAnswerReview(),
          ),
        ),
      ),
    );
  }

  Widget _buildFinalGameOver() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with X icon
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Game Over',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFFF44336),
              ),
            ),
            GestureDetector(
              onTap: () {
                _confirmBack();
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF44336).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.close,
                  color: Color(0xFFF44336),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Game Over Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFF44336).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(50),
          ),
          child: const Icon(
            Icons.sentiment_very_dissatisfied,
            size: 50,
            color: Color(0xFFF44336),
          ),
        ),
        const SizedBox(height: 24),

        // Stats
        if (widget.level != null) ...[
          Text(
            'Level Reached: ${widget.level}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C1B47),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (widget.score != null) ...[
          Text(
            'Score: ${widget.score}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C1B47),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          'No Lives Left',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFF44336).withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 24),

        // Buttons
        SizedBox(
          width: double.infinity,
          height: _actionButtonHeight,
          child: ElevatedButton(
            onPressed: () {
              SoundService().playButtonSoundNow();
              widget.onRetry();
            },
            style: _primaryActionButtonStyle(const Color(0xFF4CAF50)),
            child: const Text('Try Again'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: _actionButtonHeight,
          child: ElevatedButton(
            onPressed: () {
              _confirmBack();
            },
            style: _secondaryActionButtonStyle(),
            child: const Text('Back'),
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerReview() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with X icon
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Answer Review',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2C1B47),
              ),
            ),
            GestureDetector(
              onTap: () {
                _confirmBack();
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF44336).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.close,
                  color: Color(0xFFF44336),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Incorrect Answer
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF44336).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFF44336).withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.cancel,
                    color: Color(0xFFF44336),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Your Answer',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF44336),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.incorrectAnswer,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2C1B47),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Correct Answer
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF4CAF50),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Correct Answer',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.correctAnswer,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2C1B47),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Hearts Remaining
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.favorite,
              color: Color(0xFFF44336),
              size: 28,
            ),
            const SizedBox(width: 8),
            Text(
              '${widget.heartsRemaining} remaining',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFFF44336),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Buttons
        SizedBox(
          width: double.infinity,
          height: _actionButtonHeight,
          child: ElevatedButton(
            onPressed: () {
              SoundService().playButtonSoundNow();
              widget.onRetry();
            },
            style: _primaryActionButtonStyle(const Color(0xFF4CAF50)),
            child: const Text('Next'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: _actionButtonHeight,
          child: ElevatedButton(
            onPressed: () {
              _confirmBack();
            },
            style: _secondaryActionButtonStyle(),
            child: const Text('Back'),
          ),
        ),
      ],
    );
  }
}
