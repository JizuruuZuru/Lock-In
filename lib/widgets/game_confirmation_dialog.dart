import 'package:flutter/material.dart';

class GameConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final Color confirmColor;
  final IconData icon;

  const GameConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Back',
    this.cancelText = 'Stay',
    this.confirmColor = const Color(0xFF9C27B0),
    this.icon = Icons.help_rounded,
  });

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Back',
    String cancelText = 'Stay',
    Color confirmColor = const Color(0xFF9C27B0),
    IconData icon = Icons.help_rounded,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameConfirmationDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        confirmColor: confirmColor,
        icon: icon,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 430),
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: confirmColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: confirmColor.withValues(alpha: 0.35), width: 2),
              ),
              child: Icon(icon, color: confirmColor, size: 34),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2C1B47),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: Color(0xFF2C1B47),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF2C1B47),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Color(0xFF2C1B47), width: 2),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: Text(cancelText),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Color(0xFF2C1B47), width: 2),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: Text(confirmText),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
