import 'package:flutter/material.dart';

import '../services/sound_service.dart';

class LeaveWarningOverlay extends StatefulWidget {
  final String title;
  final String message;
  final VoidCallback onOk;
  final VoidCallback onBack;
  final bool isBusy;
  final String okText;
  final String backText;

  const LeaveWarningOverlay({
    super.key,
    required this.title,
    required this.message,
    required this.onOk,
    required this.onBack,
    this.isBusy = false,
    this.okText = 'Leave',
    this.backText = 'Stay',
  });

  @override
  State<LeaveWarningOverlay> createState() => _LeaveWarningOverlayState();
}

class _LeaveWarningOverlayState extends State<LeaveWarningOverlay> {
  @override
  void initState() {
    super.initState();
    SoundService().playLeaveWarningSoundNow();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xD9000000),
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD84315), width: 2.2),
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
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF3E2723),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4E342E),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 18),
              if (widget.isBusy) ...[
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Saving attempt...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5D4037),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.isBusy
                          ? null
                          : () {
                              SoundService().playButtonSoundNow();
                              widget.onBack();
                            },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        side: const BorderSide(
                          color: Color(0xFF6D4C41),
                          width: 2,
                        ),
                        foregroundColor: const Color(0xFF4E342E),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(widget.backText),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.isBusy
                          ? null
                          : () {
                              SoundService().playButtonSoundNow();
                              widget.onOk();
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
                      child: Text(widget.okText),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
