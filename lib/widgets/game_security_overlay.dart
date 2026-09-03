import 'dart:async';

import 'package:flutter/material.dart';

import '../services/face_proctor_contract.dart';
import '../services/face_proctor_service.dart';
import '../services/game_result_recorder.dart';
import '../services/leave_attempt_logger.dart';
import '../services/sound_service.dart';
import 'leave_warning_overlay.dart';

typedef GameSecurityAsyncCallback = FutureOr<void> Function();
typedef GameSecurityLockCallback = void Function(bool locked);

class GameSecurityOverlay extends StatefulWidget {
  final String gameName;
  final bool isActive;
  final GameSecurityLockCallback? onLockChanged;

  /// Called when the player taps **Leave**, to save whatever the run produced
  /// before the screen goes.
  ///
  /// It is *not* responsible for navigating. This overlay leaves the screen
  /// itself once this completes. It used to be the other way round - supplying
  /// an `onLeave` made the caller responsible for getting off the screen - and
  /// eight of the ten screens that supply one only saved the score and never
  /// navigated, so tapping Leave dismissed the warning and dropped the player
  /// straight back into the game they had just asked to leave.
  final GameSecurityAsyncCallback? onLeave;

  final GameSecurityAsyncCallback? onStay;
  final GameSecurityAsyncCallback? onAttemptRecorded;
  final Duration faceAbsenceThreshold;
  final bool enableFaceProctor;
  final FaceProctorService? faceProctor;

  /// Reports whether the camera is actually watching this run.
  ///
  /// The game continues either way; this exists so the screen can record the
  /// run truthfully, which is what the leaderboard's "Camera on / Camera off"
  /// badge reads. Every reason for a `false` looks the same to whoever reads
  /// that badge, so they are all reported the same way: the teacher switched
  /// proctoring off, the player declined it in their own settings, the platform
  /// has no face detection, the camera permission was refused, or the device
  /// has no front camera. Only a clean start reports `true`.
  ///
  /// This replaced an `onProctoringUnavailable` callback that fired only for
  /// the three *failure* cases. A screen listening to that one had no way to
  /// tell "watched" from "never even attempted", so a round played on the web -
  /// where face detection does not exist - was saved claiming it was watched.
  final ValueChanged<bool>? onProctorWatchingChanged;

  const GameSecurityOverlay({
    super.key,
    required this.gameName,
    required this.isActive,
    this.onLockChanged,
    this.onLeave,
    this.onStay,
    this.onAttemptRecorded,
    this.faceAbsenceThreshold = const Duration(seconds: 3),
    this.enableFaceProctor = true,
    this.faceProctor,
    this.onProctorWatchingChanged,
  });

  @override
  State<GameSecurityOverlay> createState() => _GameSecurityOverlayState();
}

class _GameSecurityOverlayState extends State<GameSecurityOverlay>
    with WidgetsBindingObserver {
  late final FaceProctorService _faceProctor;

  bool _didLeaveApp = false;
  bool _isHandlingAttempt = false;
  bool _isOverlayVisible = false;
  bool _isProctorRunning = false;
  bool _faceUnsupported = false;

  /// The last answer handed to [GameSecurityOverlay.onProctorWatchingChanged],
  /// so a repeated start attempt does not re-announce what the screen already
  /// knows.
  bool? _reportedWatching;

  String _title = 'Warning';
  String _message = 'You have left the app. The game will restart.';

  @override
  void initState() {
    super.initState();
    _faceProctor = widget.faceProctor ?? createFaceProctorService();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_syncProctorWithActiveState());
  }

  @override
  void didUpdateWidget(covariant GameSecurityOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive ||
        oldWidget.gameName != widget.gameName ||
        oldWidget.enableFaceProctor != widget.enableFaceProctor) {
      unawaited(_syncProctorWithActiveState());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_stopFaceProctor());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isHandlingAttempt || _isOverlayVisible || !widget.isActive) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _didLeaveApp = true;
      unawaited(_stopFaceProctor());
      return;
    }

    if (state == AppLifecycleState.resumed && _didLeaveApp) {
      _didLeaveApp = false;
      unawaited(_handleSecurityAttempt(
        title: 'Warning',
        message: 'You have left the app. The game will restart.',
        reason: 'app_backgrounded_or_home_pressed',
        source: 'leave_detector',
      ));
    }
  }

  Future<void> _syncProctorWithActiveState() async {
    if (!mounted) return;

    if (!widget.enableFaceProctor) {
      // Proctoring is off for this run - either the teacher's switch or the
      // player's own. Release the camera if a previous state had it open, and
      // tell the screen, so the score is not saved claiming it was watched.
      await _stopFaceProctor();
      _setWatching(false);
      return;
    }

    if (widget.isActive && !_isOverlayVisible && !_isHandlingAttempt) {
      await _startFaceProctor();
    } else {
      await _stopFaceProctor();
    }
  }

  /// Announces the watching state once, and only when it actually changes.
  void _setWatching(bool watching) {
    if (_reportedWatching == watching) return;
    _reportedWatching = watching;
    widget.onProctorWatchingChanged?.call(watching);
  }

  Future<void> _startFaceProctor() async {
    if (_faceUnsupported || _isProctorRunning) return;

    // Claimed *before* the await, not after.
    //
    // `start()` takes hundreds of milliseconds on mobile - a permission
    // prompt, `availableCameras()`, `CameraController.initialize()`, then
    // `startImageStream`. `_isProctorRunning` used to be set only once all of
    // that had finished, so a player leaving during that window hit two
    // problems at once: `dispose()` called `_stopFaceProctor()`, which saw the
    // flag still false and returned without doing anything; and then `start()`
    // completed and bailed at the `!mounted` check below without stopping what
    // it had just started. The front camera and the ML Kit detector stayed
    // live for the rest of the process.
    //
    // Setting it here also makes a second concurrent `start()` impossible,
    // which used to build two CameraControllers and orphan the first.
    _isProctorRunning = true;

    final FaceProctorStartStatus status;
    try {
      status = await _faceProctor.start(
        absenceThreshold: widget.faceAbsenceThreshold,
        onViolation: (event) {
          unawaited(_handleFaceViolation(event));
        },
      );
    } catch (_) {
      _isProctorRunning = false;
      rethrow;
    }

    if (!mounted) {
      // Unmounted mid-start. Nothing else will ever stop this, so do it here.
      await _faceProctor.stop();
      _isProctorRunning = false;
      return;
    }

    // Anything other than a clean start left no camera running, so release the
    // claim before reporting the problem.
    if (status != FaceProctorStartStatus.started) {
      _isProctorRunning = false;
    }

    switch (status) {
      case FaceProctorStartStatus.started:
        _setWatching(true);
        return;
      case FaceProctorStartStatus.unsupportedPlatform:
        // Same behavior as Math Game: web/desktop can continue, while Android
        // and iOS use the mobile face proctor implementation.
        //
        // Not an exam-integrity event - nobody declined anything - but the run
        // is still not being watched, and the score has to say so.
        _faceUnsupported = true;
        _setWatching(false);
        _showProctorNotice(
          'Face detection anti-cheat is available only on Android/iOS.',
        );
        return;
      // None of the three failures below stop the game any more.
      //
      // They used to raise a blocking "Camera required" overlay, so a child who
      // tapped Deny once - or whose tablet has no front camera - was shut out
      // of the whole app with no way back in. Being unable to watch somebody is
      // not a reason to stop them learning. The run continues, the screen is
      // told so it can record the attempt as unwatched, and the teacher sees
      // that in the log.
      case FaceProctorStartStatus.permissionDenied:
        _reportProctoringUnavailable(
          'Camera permission was declined, so this round is not being watched.',
        );
        return;
      case FaceProctorStartStatus.noFrontCamera:
        _reportProctoringUnavailable(
          'No front camera on this device, so this round is not being watched.',
        );
        return;
      case FaceProctorStartStatus.initializationFailed:
        _reportProctoringUnavailable(
          'Face detection could not start, so this round is not being watched.',
        );
        return;
    }
  }

  /// Tells the player once, tells the screen so it can flag the run, and lets
  /// play continue.
  void _reportProctoringUnavailable(String message) {
    if (!mounted) return;
    // Do not retry for the rest of this screen's life: a denied permission
    // would otherwise re-prompt on every pause/resume cycle.
    _faceUnsupported = true;
    _setWatching(false);
    _showProctorNotice(message);
  }

  void _showProctorNotice(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _stopFaceProctor() async {
    if (!_isProctorRunning) return;
    await _faceProctor.stop();
    _isProctorRunning = false;
  }

  Future<void> _handleFaceViolation(FaceViolationEvent event) async {
    final reason = _faceViolationReasonTag(event.reason);
    final message = _faceViolationMessage(event.reason);

    await _handleSecurityAttempt(
      title: 'Warning',
      message: message,
      reason: reason,
      source: 'face_detector',
      details: {
        'seconds_without_valid_face': event.secondsWithoutValidFace,
      },
    );
  }

  Future<void> _handleSecurityAttempt({
    required String title,
    required String message,
    required String reason,
    required String source,
    Map<String, dynamic>? details,
  }) async {
    if (_isHandlingAttempt || _isOverlayVisible || !widget.isActive) return;

    _isHandlingAttempt = true;
    await _stopFaceProctor();

    if (mounted) {
      widget.onLockChanged?.call(true);
      setState(() {
        _title = title;
        _message = message;
        _isOverlayVisible = true;
      });
    }

    try {
      // Bounded, because `isBusy: _isHandlingAttempt` below disables *both*
      // Stay and Leave while this runs. A Firestore write future only
      // completes once the server acknowledges it, so with no connection this
      // never returned and the overlay sat on "Saving attempt..." with both
      // buttons greyed out - permanently, with no way back into the game and
      // no way out of it.
      //
      // The two are issued together rather than in sequence so the score save
      // still reaches Firestore's local cache even when the log write is the
      // one hanging.
      final recorded = widget.onAttemptRecorded;
      await saveBeforeLeaving(() async {
        await Future.wait<void>([
          LeaveAttemptLogger.logAttempt(
            gameName: widget.gameName,
            reason: reason,
            source: source,
            details: details,
          ),
          if (recorded != null) Future<void>.sync(() async => recorded()),
        ]);
      });
    } catch (error) {
      debugPrint('Security attempt log failed: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isHandlingAttempt = false;
        });
      } else {
        _isHandlingAttempt = false;
      }
    }
  }

  String _faceViolationReasonTag(FaceViolationReason reason) {
    switch (reason) {
      case FaceViolationReason.noFaceDetected:
        return 'face_not_detected_for_3_seconds';
      case FaceViolationReason.notFacingDevice:
        return 'face_not_facing_device_for_3_seconds';
    }
  }

  String _faceViolationMessage(FaceViolationReason reason) {
    switch (reason) {
      case FaceViolationReason.noFaceDetected:
        return 'You have left the camera view for 3 seconds. The game will restart.';
      case FaceViolationReason.notFacingDevice:
        return 'You are not facing the camera. The game will restart.';
    }
  }

  Future<void> _stayInGame() async {
    if (_isHandlingAttempt) return;
    SoundService().playButtonSoundNow();
    setState(() {
      _isOverlayVisible = false;
      _didLeaveApp = false;
    });
    widget.onLockChanged?.call(false);

    if (widget.onStay != null) {
      await widget.onStay!();
    }

    await _syncProctorWithActiveState();
  }

  Future<void> _leaveGame() async {
    if (_isHandlingAttempt) return;
    SoundService().playButtonSoundNow();

    // Every step of leaving is behind this await, so a camera that refuses to
    // release would strand the player on a screen they asked to leave.
    // Releasing the lens is best-effort; getting out is not.
    try {
      await _stopFaceProctor();
    } catch (error) {
      debugPrint('Could not release the camera while leaving: $error');
    }

    // Nothing left to unlock or navigate if the game screen is already gone.
    if (!mounted) return;
    setState(() {
      _isOverlayVisible = false;
      _didLeaveApp = false;
    });

    // Deliberately *not* unlocking the screen here. `onLockChanged(false)`
    // clears `isGameOver` and hands most screens a fresh `timerKey`, which
    // restarts the countdown for as long as the save below takes - on a slow
    // connection, long enough for the timer to fire behind a screen that is on
    // its way out. The player asked to leave; the game does not resume.
    if (widget.onLeave != null) {
      // Bounded, even though every screen's own `onLeave` already is. This
      // widget promises that Leave leaves, and that promise cannot depend on
      // what a caller chooses to await inside its save callback.
      await saveBeforeLeaving(() async => widget.onLeave!());
    }

    if (!mounted) return;

    // `Navigator.pop`, not `maybePop`. Every game screen wraps itself in
    // `PopScope(canPop: false)` so the Android back gesture is routed through
    // its own confirm-and-save handler, and `maybePop` honours that - it pops
    // nothing and re-enters the screen's back handler instead, which then
    // ignores it because a warning overlay is already showing.
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    // Nothing to pop, so this game is the root route. Unlock rather than
    // stranding the player on a screen with a dismissed warning and a game
    // that never resumes.
    widget.onLockChanged?.call(false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOverlayVisible) return const SizedBox.shrink();

    return Positioned.fill(
      child: LeaveWarningOverlay(
        title: _title,
        message: _message,
        isBusy: _isHandlingAttempt,
        backText: 'Stay',
        okText: 'Leave',
        onBack: _stayInGame,
        onOk: _leaveGame,
      ),
    );
  }
}
