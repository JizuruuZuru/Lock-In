import 'package:flutter/material.dart';

import '../services/sound_service.dart';

class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;

  const ErrorDialog({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    // Play the same warning sound as the leave warning overlay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SoundService().playLeaveWarningSoundNow();
    });

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0), // cream background
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFD84315), // orange border
            width: 2.2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_rounded,
              color: Color(0xFFD84315),
              size: 52,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF3E2723), // dark brown
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4E342E), // medium brown
                height: 1.3,
              ),
            ),
            const SizedBox(height: 18),
            // Single OK button – styled like the right button of LeaveWarningOverlay
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  SoundService().playButtonSoundNow();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: const Color(0xFFD84315),
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text('OK'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}