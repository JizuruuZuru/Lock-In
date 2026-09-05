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

/// Owns the countdown, and therefore owns "do not count while nobody can see
/// me".
///
/// Backgrounding the app used to drain the clock: `GameSecurityOverlay` marks
/// the leave and stops the camera, but it only locks the game on *resume*, so
/// `isPaused: () => isGameOver` stayed false the whole time the app was away.
/// A player alt-tabbed, came back, and had lost a heart to a timeout on a
/// question they could not see. Fixing it here covers all twelve games at once
/// and leaves the anti-cheat flow, which is deliberately separate, alone.
class _GameTimerState extends State<GameTimer> with WidgetsBindingObserver {
  bool _inForeground = true;
  late int timeLeft;
  late int effectiveSeconds;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // The caller's number, honoured. This used to floor at 5, silently,
    // inside a shared widget - which killed Math Quest's difficulty ramp from
    // level 6 on, where `max(10 - level, 3)` asks for 4 and then 3 and got 5
    // every time. A timer of 0 or less would never tick, so that is the only
    // thing still clamped.
    effectiveSeconds = math.max(widget.seconds, 1);
    startTimer();
  }

  @override
  void didUpdateWidget(covariant GameTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Without this a changed `seconds` was silently ignored: the countdown
    // kept whatever duration it was first built with. It only ever worked
    // because every caller happens to mint a fresh `UniqueKey` per question,
    // which forces a new State - an undocumented coupling that would bite the
    // first caller to reuse a key.
    if (oldWidget.seconds != widget.seconds) {
      effectiveSeconds = math.max(widget.seconds, 1);
      startTimer();
    }
  }

  void startTimer() {
    timer?.cancel();
    timeLeft = effectiveSeconds;

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      // Off screen counts as paused, whatever the host screen thinks.
      if (!_inForeground) return;
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _inForeground = state == AppLifecycleState.resumed;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
