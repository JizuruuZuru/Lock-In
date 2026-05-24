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

    final status = await _faceProctor.start(
      absenceThreshold: widget.faceAbsenceThreshold,
      onViolation: (event) {
        unawaited(_handleFaceViolation(event));
      },
    );

    if (!mounted) return;

    switch (status) {
      case FaceProctorStartStatus.started:
        _isProctorRunning = true;
        return;
      case FaceProctorStartStatus.unsupportedPlatform:
        // Same behavior as Math Game: web/desktop can continue, while Android
        // and iOS use the mobile face proctor implementation.
        _faceUnsupported = true;
        _showProctorNotice(
          'Face detection anti-cheat is available only on Android/iOS.',
        );
        return;
      case FaceProctorStartStatus.permissionDenied:
        await _showProctorRequiredOverlay(
          'Camera permission is required to start the game.',
        );
        return;
      case FaceProctorStartStatus.noFrontCamera:
        await _showProctorRequiredOverlay(
          'No front camera found on this device.',
        );
        return;
      case FaceProctorStartStatus.initializationFailed:
        await _showProctorRequiredOverlay(
          'Unable to initialize face detection. Please try again.',
        );
        return;
    }
  }

  void _showProctorNotice(String message) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showProctorRequiredOverlay(String message) async {
    if (!mounted || _isOverlayVisible || _isHandlingAttempt) return;
    await _stopFaceProctor();
    widget.onLockChanged?.call(true);
    setState(() {
      _title = 'Camera required';
      _message = message;
      _didLeaveApp = false;
      _isOverlayVisible = true;
    });
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
