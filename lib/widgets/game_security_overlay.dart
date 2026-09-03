import 'dart:async';

import 'package:flutter/material.dart';

import '../services/face_proctor_contract.dart';
import '../services/face_proctor_service.dart';
import '../services/leave_attempt_logger.dart';
import '../services/sound_service.dart';
import 'leave_warning_overlay.dart';

typedef GameSecurityAsyncCallback = FutureOr<void> Function();
typedef GameSecurityLockCallback = void Function(bool locked);

class GameSecurityOverlay extends StatefulWidget {
  final String gameName;
  final bool isActive;
  final GameSecurityLockCallback? onLockChanged;
  final GameSecurityAsyncCallback? onLeave;
  final GameSecurityAsyncCallback? onStay;
  final GameSecurityAsyncCallback? onAttemptRecorded;
  final Duration faceAbsenceThreshold;
  final bool enableFaceProctor;
  final FaceProctorService? faceProctor;

  /// Fired when proctoring was wanted for this run but could not run - camera
  /// permission denied, no front camera, or an initialisation failure.
  ///
  /// The game continues either way; this exists so the screen can record the
  /// run as unwatched, which is what lets a teacher tell a proctored score from
  /// an unproctored one. It is not fired when proctoring was switched off by an
  /// admin, or on a platform that never supports it - neither of those is an
  /// exam-integrity event.
  final VoidCallback? onProctoringUnavailable;

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
    this.onProctoringUnavailable,
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
    if (widget.isActive && !_isOverlayVisible && !_isHandlingAttempt) {
      await _startFaceProctor();
    } else {
      await _stopFaceProctor();
    }
  }

  Future<void> _startFaceProctor() async {
    if (!widget.enableFaceProctor || _faceUnsupported || _isProctorRunning) {
      return;
    }

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
        return;
      case FaceProctorStartStatus.unsupportedPlatform:
        // Same behavior as Math Game: web/desktop can continue, while Android
        // and iOS use the mobile face proctor implementation.
        _faceUnsupported = true;
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
    _showProctorNotice(message);
    widget.onProctoringUnavailable?.call();
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
      await LeaveAttemptLogger.logAttempt(
        gameName: widget.gameName,
        reason: reason,
        source: source,
        details: details,
      );
      if (widget.onAttemptRecorded != null) {
        await widget.onAttemptRecorded!();
      }
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
    await _stopFaceProctor();
    // Nothing left to unlock or navigate if the game screen is already gone.
    if (!mounted) return;
    setState(() {
      _isOverlayVisible = false;
      _didLeaveApp = false;
    });
    widget.onLockChanged?.call(false);

    if (widget.onLeave != null) {
      await widget.onLeave!();
      return;
    }

    if (!mounted) return;
    await Navigator.of(context).maybePop();
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
