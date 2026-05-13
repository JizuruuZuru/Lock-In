import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class GameTimer extends StatefulWidget {
  final int seconds;
  final VoidCallback onTimeUp;
  final bool Function()? isPaused; // 🔹 optional function to pause timer
  final bool showBar; // 🔹 show visual progress bar

  const GameTimer({
    super.key,
    required this.seconds,
    required this.onTimeUp,
    this.isPaused,
    this.showBar = true,
  });

  @override
  State<GameTimer> createState() => _GameTimerState();
}

class _GameTimerState extends State<GameTimer> {
  late int timeLeft;
  late int effectiveSeconds;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    // Ensure minimum 5 seconds display
    effectiveSeconds = math.max(widget.seconds, 5);
    startTimer();
  }

  void startTimer() {
    timer?.cancel();
    timeLeft = effectiveSeconds;

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (widget.isPaused != null && widget.isPaused!()) {
        // 🔹 pause timer if function returns true
        return;
      }

      if (timeLeft <= 1) {
        t.cancel();
        widget.onTimeUp();
      } else {
        setState(() => timeLeft--);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Color _getTimerColor() {
    if (timeLeft <= 2) return Colors.red;
    if (timeLeft <= 4) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final progress = timeLeft / effectiveSeconds;
    final barColor = _getTimerColor();

    if (widget.showBar) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Time Left: $timeLeft s",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: barColor,
            ),
          ),
        ],
      );
    }

    // Fallback to text-only version
    return Text(
      "Time Left: $timeLeft s",
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: barColor,
      ),
    );
  }
}
