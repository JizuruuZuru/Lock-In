import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/game_result_recorder.dart';
import '../../services/game_logger.dart';
import '../../services/face_proctor_contract.dart';
import '../../services/face_proctor_service.dart';
import '../../services/leave_attempt_logger.dart';
import '../../services/sound_service.dart';
import '../../utils/game_theme.dart';
import '../../utils/game_difficulty_mode.dart';
import '../../utils/responsive_layout.dart';
import '../../widgets/animated_shape_background.dart';
import '../../widgets/correct_splash.dart';
import '../../widgets/difficulty_mode_selector.dart';
import '../../widgets/game_over_popup.dart';
import '../../widgets/hearts_display.dart';
import '../../widgets/incorrect_splash.dart';
import '../../widgets/app_brightness_overlay.dart';
import '../../widgets/game_timer.dart';
import '../../widgets/leave_warning_overlay.dart';
import '../../widgets/number_pad.dart';

class NumberMemoryGame extends StatefulWidget {
  const NumberMemoryGame({super.key});

  @override
  State<NumberMemoryGame> createState() => _NumberMemoryGameState();
}

class _NumberMemoryGameState extends State<NumberMemoryGame>
    with WidgetsBindingObserver {
  static const Color _inkColor = Color(0xFF1B4965);
  static const Color _bgTopColor = Color(0xFFFFE5D9);
  static const Color _bgBottomColor = Color(0xFFFFCCB3);
  static const Color _panelColor = Color(0xFFFFF9E6);
  static const Color _accentColor = Color(0xFF069A8E);
  static const int _autoSubmitAfterLeaves = 1;

  int level = 1;
  String number = '';
  bool showNumber = true;
  String input = '';
  static const int maxTime = 8;
  static const int displayTime = 5;
  static const int minRevealToInputDelay = 2;
  Key timerKey = UniqueKey();
  Key displayTimerKey = UniqueKey();
  bool isGameOver = false;
  bool hasStarted = false;
  bool showCorrectSplash = false;
  bool showIncorrectSplash = false;
  int hearts = 3;
  GameDifficultyMode _selectedMode = GameDifficultyMode.normal;
  bool _didLeaveApp = false;
  bool _processingLeaveAttempt = false;
  bool _showLeaveWarning = false;
  bool _showExitConfirmation = false;
  bool _suspendLeaveDetector = false;
  String _leaveWarningMessage =
      'You have left the app. The game will restart.';
  int _leaveAttemptsThisRun = 0;
  bool _faceSupportNoticeShown = false;
  final FaceProctorService _faceProctor = createFaceProctorService();
  bool _isProctorActive = false;

  // 🔥 duplicate prevention
  final GameSaveGate _saveGate = GameSaveGate();

  static const String _gameName = 'Number Memory';
  
  // Timer for auto-transition from display to input
  Timer? _displayTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SoundService().playPageBgm(BgmPage.memory);
    SoundService().registerUserInteraction();
  }

  @override
  void dispose() {
    _displayTimer?.cancel(); // Cancel any pending timer
    GameLogger.endSession(_gameName);
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_stopFaceProctor());
    SoundService().playPageBgm(BgmPage.home);
    super.dispose();
  }

  Future<void> _stopFaceProctor() async {
    if (_isProctorActive) {
      await _faceProctor.stop();
      _isProctorActive = false;
    }
  }

  Future<bool> _startFaceProctor() async {
    if (_isProctorActive) return true;

    // Claimed before the await. `start()` takes hundreds of milliseconds on
    // mobile, and `dispose()` during that window used to find this flag still
    // false, so `_stopFaceProctor()` no-opped and the camera and ML Kit
    // detector stayed live after the screen was gone. Setting it here also
    // stops two concurrent starts building two CameraControllers.
    _isProctorActive = true;

    final FaceProctorStartStatus status;
    try {
      status = await _faceProctor.start(
        absenceThreshold: const Duration(seconds: 3),
        onViolation: (event) {
          _handleFaceViolation(
            gameName: _gameName,
            event: event,
          );
        },
      );
    } catch (_) {
      _isProctorActive = false;
      rethrow;
    }

    if (status == FaceProctorStartStatus.started) {
      if (!mounted) {
        // Unmounted mid-start; nothing else will release the camera.
        await _faceProctor.stop();
        _isProctorActive = false;
        return false;
      }
      return true;
    }

    _isProctorActive = false;
    return false;
  }

  void startLevel() {
    input = '';
    showNumber = true;
    isGameOver = false;

    // Cancel any existing timer
    _displayTimer?.cancel();

    number = List.generate(level + 2, (_) => Random().nextInt(10)).join();

    setState(() {});

    const revealDelaySeconds = displayTime >= minRevealToInputDelay
        ? displayTime
        : minRevealToInputDelay;

    // Use Timer instead of Future.delayed so we can cancel it
    _displayTimer = Timer(const Duration(seconds: revealDelaySeconds), () {
      if (!mounted) return;
      setState(() {
        showNumber = false;
        timerKey = UniqueKey();
      });
    });
  }

  // Method to skip the display timer and go straight to input
  void skipToAnswerPhase() {
    SoundService().playButtonSoundNow();
    _displayTimer?.cancel();
    if (!mounted) return;
    setState(() {
      showNumber = false;
      timerKey = UniqueKey();
    });
  }

  Future<void> startGame() async {
    await _stopFaceProctor();

    final monitoringReady = await _ensureFaceMonitoring();
    if (!monitoringReady || !mounted) return;

    // Start new game session for logging
    GameLogger.startNewSession('Number Memory');

    setState(() {
      hasStarted = true;
      level = 1;
      hearts = gameDifficultyModeHearts(_selectedMode);
      _didLeaveApp = false;
      _processingLeaveAttempt = false;
      _showLeaveWarning = false;
      _showExitConfirmation = false;
      _suspendLeaveDetector = false;
      _leaveAttemptsThisRun = 0;
    });
    startLevel();
    _isProctorActive = true;
  }

  Future<bool> _ensureFaceMonitoring() async {
    final status = await _faceProctor.start(
      absenceThreshold: const Duration(seconds: 3),
      onViolation: (event) {
        _handleFaceViolation(
          gameName: _gameName,
          event: event,
        );
      },
    );

    if (!mounted) return false;

    switch (status) {
      case FaceProctorStartStatus.started:
        _isProctorActive = true;
        return true;
      case FaceProctorStartStatus.unsupportedPlatform:
        if (!_faceSupportNoticeShown) {
          _faceSupportNoticeShown = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Face detection anti-cheat is available only on Android/iOS.',
              ),
            ),
          );
        }
        return true;
      case FaceProctorStartStatus.permissionDenied:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission is required to start the game.'),
          ),
        );
        return false;
      case FaceProctorStartStatus.noFrontCamera:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No front camera found on this device.'),
          ),
        );
        return false;
      case FaceProctorStartStatus.initializationFailed:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to initialize face detection. Please try again.',
            ),
          ),
        );
        return false;
    }
  }

  bool _isRoundActive() {
    return hasStarted &&
        !isGameOver &&
        !showCorrectSplash &&
        !showIncorrectSplash &&
        !_showLeaveWarning &&
        !_showExitConfirmation &&
        !_suspendLeaveDetector;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_suspendLeaveDetector) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      unawaited(_stopFaceProctor());
      _didLeaveApp = true;
      return;
    }

    if (state == AppLifecycleState.resumed) {
      if (_didLeaveApp) {
        _didLeaveApp = false;
        _handleLeaveAttempt();
      }
    }
  }

  Future<void> _handleLeaveAttempt() async {
    if (_suspendLeaveDetector ||
        _processingLeaveAttempt ||
        (!_isRoundActive() && !_showExitConfirmation)) {
      return;
    }

    _processingLeaveAttempt = true;
    _leaveAttemptsThisRun++;

    if (_leaveAttemptsThisRun < _autoSubmitAfterLeaves) {
      _processingLeaveAttempt = false;
      return;
    }

    await _stopFaceProctor();

    // Stopping the proctor tears down the camera and the ML Kit detector,
    // which is slow enough that the player can leave the screen first.
    if (!mounted) {
      _processingLeaveAttempt = false;
      return;
    }

    setState(() {
      isGameOver = true;
      showCorrectSplash = false;
      showIncorrectSplash = false;
      _showLeaveWarning = true;
      _showExitConfirmation = false;
      _suspendLeaveDetector = true;
      _leaveWarningMessage = 'You have left the app. The game will restart.';
    });

    try {
      await LeaveAttemptLogger.logAttempt(
        gameName: _gameName,
        reason: 'app_backgrounded_or_home_pressed',
      );
      await saveScore();
    } finally {
      if (mounted) {
        setState(() {
          _processingLeaveAttempt = false;
        });
      }
    }
  }

  Future<void> _handleFaceViolation({
    required String gameName,
    required FaceViolationEvent event,
  }) async {
    if (_suspendLeaveDetector || _processingLeaveAttempt || !_isRoundActive()) {
      return;
    }

    _processingLeaveAttempt = true;
    await _stopFaceProctor();

    if (mounted) {
      setState(() {
        isGameOver = true;
        showCorrectSplash = false;
        showIncorrectSplash = false;
        _showLeaveWarning = true;
        _showExitConfirmation = false;
        _suspendLeaveDetector = true;
        _leaveWarningMessage = _faceViolationMessage(event.reason);
      });
    }

    try {
      await LeaveAttemptLogger.logAttempt(
        gameName: gameName,
        reason: _faceViolationReasonTag(event.reason),
        source: 'face_detector',
        details: {
          'seconds_without_valid_face': event.secondsWithoutValidFace,
        },
      );
      await saveScore();
    } finally {
      if (mounted) {
        setState(() {
          _processingLeaveAttempt = false;
        });
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

  void _restartFromLeaveWarning() {
    if (_processingLeaveAttempt) return;

    setState(() {
      _showLeaveWarning = false;
      _showExitConfirmation = false;
      _suspendLeaveDetector = false;
      _didLeaveApp = false;
      _leaveAttemptsThisRun = 0;
    });
    startGame();
  }

  void _backFromLeaveWarning() {
    if (_processingLeaveAttempt) return;

    unawaited(_stopFaceProctor());
    setState(() {
      _showLeaveWarning = false;
      hasStarted = false;
      level = 1;
      showNumber = true;
      input = '';
      number = '';
      hearts = gameDifficultyModeHearts(_selectedMode);
      isGameOver = false;
      showCorrectSplash = false;
      showIncorrectSplash = false;
      _showExitConfirmation = false;
      _suspendLeaveDetector = false;
      _didLeaveApp = false;
      _leaveAttemptsThisRun = 0;
    });
  }

  bool _shouldConfirmExit() {
    return _isRoundActive();
  }

  void _showExitConfirmationOverlay() {
    if (_showExitConfirmation || !_shouldConfirmExit()) return;

    unawaited(_stopFaceProctor());

    setState(() {
      _showExitConfirmation = true;
      isGameOver = true;
    });
  }

  void _cancelExitConfirmation() {
    if (!_showExitConfirmation) return;

    setState(() {
      _showExitConfirmation = false;
      _suspendLeaveDetector = false;
      isGameOver = false;
    });

    if (hasStarted && !isGameOver) {
      unawaited(_startFaceProctor());
    }
  }

  void _confirmExitFromBack() {
    if (_processingLeaveAttempt) return;

    unawaited(_stopFaceProctor());
    Navigator.of(context).maybePop();
  }

  Future<void> _onAppBarBackPressed() async {
    if (_processingLeaveAttempt || _showLeaveWarning || _showExitConfirmation) {
      return;
    }
    SoundService().playButtonSoundNow();

    if (_shouldConfirmExit()) {
      _showExitConfirmationOverlay();
      return;
    }

    Navigator.of(context).maybePop();
  }

  void appendInput(String value) {
    if (isGameOver) return;
    setState(() {
      input += value;
    });
  }

  void clearInput() {
    setState(() {
      input = '';
    });
  }

  void submitInput() {
    if (isGameOver) return;

    if (input == number) {
      SoundService().playCorrectSound();
      setState(() {
        showCorrectSplash = true;
        isGameOver = true;
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            level++;
            timerKey = UniqueKey();
            showCorrectSplash = false;
          });
          startLevel();
        }
      });
    } else {
      SoundService().playIncorrectSplashSound();
      setState(() {
        showIncorrectSplash = true;
        hearts--;
        isGameOver = true;
      });
      unawaited(saveScore().catchError((e) {
        debugPrint('Error saving score on incorrect: $e');
      }));
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            showIncorrectSplash = false;
          });
          unawaited(_stopFaceProctor());
          showGameOverScreen(input);
        }
      });
    }
  }

  void showGameOverScreen(String incorrectInput, {bool timeout = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => GameOverPopup(
        incorrectAnswer: timeout ? 'Time\'s up!' : incorrectInput,
        correctAnswer: number,
        heartsRemaining: hearts,
        level: hearts == 0 ? level : null,
        onRetry: () {
          Navigator.pop(context);
          if (hearts == 0) {
            setState(() {
              level = 1;
              timerKey = UniqueKey();
              isGameOver = false;
              hearts = gameDifficultyModeHearts(_selectedMode);
            });
            startLevel();
          } else {
            setState(() {
              input = '';
              timerKey = UniqueKey();
              isGameOver = false;
            });
            unawaited(_startFaceProctor());
            startLevel();
          }
        },
        onBack: () {
          Navigator.pop(context);
          unawaited(_stopFaceProctor());
          setState(() {
            level = 1;
            showNumber = true;
            timerKey = UniqueKey();
            hasStarted = false;
            hearts = gameDifficultyModeHearts(_selectedMode);
          });
        },
      ),
    );
  }

  // 🔧 UPDATED saveScore with duplicate prevention
  Future<void> saveScore() async {
    // This game scores by how many digits were recalled, which is `level`.
    await _saveGate.run(() async {
      await saveGameResult(
        gameName: _gameName,
        score: level,
        level: level,
        difficulty: gameDifficultyModeLabel(_selectedMode),
        storageKey: 'number_memory',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // The screen drives every exit through _onAppBarBackPressed: it confirms, logs the
    // leave attempt, and saves the score. The Android hardware/gesture back
    // popped the route directly and skipped all three - no confirmation, no
    // score, and no proctoring record. `canPop: false` routes that gesture
    // into the same handler the on-screen arrow uses.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        _onAppBarBackPressed();
      },
      child: _buildGameScreen(context),
    );
  }

  Widget _buildGameScreen(BuildContext context) {
    return Theme(
      data: _buildTheme(context),
      child: AppBrightnessOverlay(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: IconButton(
              onPressed: _onAppBarBackPressed,
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back',
            ),
            title: const Text('Memory Quest'),
          ),
          body: Stack(
            children: [
              _buildBackground(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: hasStarted ? _buildGameUI() : _buildInstructions(),
                  ),
                ),
              ),
              if (showCorrectSplash)
                Positioned.fill(
                  child: CorrectSplash(
                    onComplete: () {},
                  ),
                ),
              if (showIncorrectSplash)
                Positioned.fill(
                  child: IncorrectSplash(
                    onComplete: () {},
                  ),
                ),
              if (_showExitConfirmation)
                Positioned.fill(
                  child: LeaveWarningOverlay(
                    title: 'Leave game?',
                    message: 'Your current progress in this game will be lost.',
                    onOk: _confirmExitFromBack,
                    onBack: _cancelExitConfirmation,
                    okText: 'Leave',
                    backText: 'Stay',
                  ),
                ),
              if (_showLeaveWarning)
                Positioned.fill(
                  child: LeaveWarningOverlay(
                    title: 'Warning',
                    message: _leaveWarningMessage,
                    isBusy: _processingLeaveAttempt,
                    okText: 'Leave',
                    backText: 'Stay',
                    onOk: _backFromLeaveWarning,
                    onBack: _restartFromLeaveWarning,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  ThemeData _buildTheme(BuildContext context) {
    return buildGameTheme(context, ink: _inkColor, accent: _accentColor);
  }

  Widget _buildBackground({required Widget child}) {
    return AnimatedShapeBackground(
      duration: const Duration(seconds: 20),
      gradientColors: const [_bgTopColor, _bgBottomColor],
      shapes: const [
        AnimatedBackgroundShape(
          kind: BackgroundShapeKind.iconBadge,
          alignment: Alignment.topLeft,
          baseOffset: Offset(-34, -24),
          drift: Offset(14, 11),
          size: 112,
          color: Color(0x32069A8E),
          borderColor: Color(0x4A1B4965),
          iconData: Icons.memory_rounded,
          contentColor: Color(0xFF1B4965),
          cornerRadius: 24,
        ),
        AnimatedBackgroundShape(
          kind: BackgroundShapeKind.iconBadge,
          alignment: Alignment.topRight,
          baseOffset: Offset(30, 84),
          drift: Offset(10, 16),
          size: 96,
          color: Color(0x30E94B3C),
          borderColor: Color(0x4A1B4965),
          iconData: Icons.psychology_alt_rounded,
          contentColor: Color(0xFF1B4965),
          cornerRadius: 22,
          initialRotation: 0.22,
        ),
        AnimatedBackgroundShape(
          kind: BackgroundShapeKind.iconBadge,
          alignment: Alignment.bottomLeft,
          baseOffset: Offset(34, 36),
          drift: Offset(11, 11),
          size: 98,
          color: Color(0x2A069A8E),
          borderColor: Color(0x441B4965),
          iconData: Icons.numbers_rounded,
          contentColor: Color(0xFF1B4965),
          cornerRadius: 20,
        ),
        AnimatedBackgroundShape(
          kind: BackgroundShapeKind.iconBadge,
          alignment: Alignment.bottomRight,
          baseOffset: Offset(24, 28),
          drift: Offset(12, 14),
          size: 92,
          color: Color(0x26E94B3C),
          borderColor: Color(0x401B4965),
          iconData: Icons.visibility_rounded,
          contentColor: Color(0xFF1B4965),
          cornerRadius: 20,
          initialRotation: -0.12,
        ),
        AnimatedBackgroundShape(
          kind: BackgroundShapeKind.iconBadge,
          alignment: Alignment.centerLeft,
          baseOffset: Offset(-46, -8),
          drift: Offset(9, 9),
          size: 70,
          color: Color(0x24069A8E),
          borderColor: Color(0x3D1B4965),
          iconData: Icons.grid_4x4_rounded,
          contentColor: Color(0xFF1B4965),
          cornerRadius: 18,
          phase: 1.2,
        ),
        AnimatedBackgroundShape(
          kind: BackgroundShapeKind.iconBadge,
          alignment: Alignment.centerRight,
          baseOffset: Offset(46, 12),
          drift: Offset(9, 8),
          size: 72,
          color: Color(0x25E94B3C),
          borderColor: Color(0x3D1B4965),
          iconData: Icons.timer_rounded,
          contentColor: Color(0xFF1B4965),
          cornerRadius: 18,
          phase: 2.0,
        ),
        AnimatedBackgroundShape(
          kind: BackgroundShapeKind.iconBadge,
          alignment: Alignment.topCenter,
          baseOffset: Offset(0, 26),
          drift: Offset(10, 8),
          size: 66,
          color: Color(0x22069A8E),
          borderColor: Color(0x381B4965),
          iconData: Icons.pin_rounded,
          contentColor: Color(0xFF1B4965),
          cornerRadius: 16,
          phase: 0.9,
        ),
      ],
      child: child,
    );
  }

  Widget _card({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(18),
  }) {
    return gameCard(
      child: child,
      panel: _panelColor,
      ink: _inkColor,
      padding: padding,
    );
  }

  Widget _buildInstructions() {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: responsivePanelMaxWidth(
            MediaQuery.sizeOf(context).width,
          ),
        ),
        child: _card(
          child: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Memorize the Numbers!",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                "Study the number shown on screen, then enter it from memory. "
                "The number grows longer with each level. Stay sharp!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 14),
              const Text(
                'Difficulty',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              DifficultyModeSelector(
                selected: _selectedMode,
                accentColor: _accentColor,
                onChanged: (mode) => setState(() => _selectedMode = mode),
              ),
              const SizedBox(height: 4),
              Text(
                gameDifficultyModeDescription(_selectedMode),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    SoundService().playButtonSoundNow();
                    startGame();
                  },
                  child: const Text("Start Game"),
                ),
              ),
            ],
          )),
        ),
      ),
    );
  }

  Widget _buildGameUI() {
    return Column(
      children: [
        _card(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Level $level',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (!showNumber && gameDifficultyModeHasTimer(_selectedMode))
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: GameTimer(
                      key: timerKey,
                      seconds: maxTime,
                      isPaused: () => isGameOver,
                      onTimeUp: () {
                        setState(() {
                          isGameOver = true;
                        });
                        unawaited(_stopFaceProctor());
                        unawaited(saveScore().catchError((e) {
                          debugPrint('Error saving score on timeout: $e');
                        }));
                        showGameOverScreen('', timeout: true);
                      },
                      showBar: true,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (!showNumber) HeartsDisplay(
          hearts: hearts,
          maxHearts: gameDifficultyModeHearts(_selectedMode),
        ),
        if (!showNumber) const SizedBox(height: 14),
        if (showNumber)
          Expanded(
            child: Center(
              child: _card(
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 34),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: null,
                        icon: Icon(Icons.record_voice_over_rounded),
                        tooltip: 'Replay number voice',
                      ),
                    ),
                    Text(
                      number,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: GameTimer(
                        key: displayTimerKey,
                        seconds: displayTime,
                        isPaused: () => isGameOver,
                        onTimeUp: () {},
                        showBar: true,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: skipToAnswerPhase,
                        icon: const Icon(Icons.keyboard_arrow_right_rounded, size: 24),
                        label: const Text('Start Answering'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          backgroundColor: _accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _card(
                  child: const Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Enter the number you saw",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        onPressed: null,
                        icon: Icon(Icons.volume_up_rounded),
                        tooltip: 'Replay prompt',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: NumberPad(
                    input: input,
                    isDisabled: isGameOver,
                    onNumberTap: appendInput,
                    onClear: clearInput,
                    onSubmit: submitInput,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}