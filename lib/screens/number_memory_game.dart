import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/game_logger.dart';
import '../services/face_proctor_contract.dart';
import '../services/face_proctor_service.dart';
import '../services/leave_attempt_logger.dart';
import '../services/sound_service.dart';
import '../services/leaderboard_service.dart';
import '../widgets/animated_shape_background.dart';
import '../widgets/correct_splash.dart';
import '../widgets/game_over_popup.dart';
import '../widgets/hearts_display.dart';
import '../widgets/app_brightness_overlay.dart';
import '../widgets/game_timer.dart';
import '../widgets/leave_warning_overlay.dart';
import '../widgets/number_pad.dart';
import '../widgets/game_reaction_gif.dart';
import '../widgets/incorrect_splash.dart';

class NumberMemoryGame extends StatefulWidget {
  const NumberMemoryGame({super.key});

  @override
  State<NumberMemoryGame> createState() => _NumberMemoryGameState();
}

class _NumberMemoryGameState extends State<NumberMemoryGame>
    with WidgetsBindingObserver {

ReactionGifState get _reactionState {
  if (showCorrectSplash) return ReactionGifState.success;
  if (showIncorrectSplash) return ReactionGifState.fail;
  return ReactionGifState.thinking;
}

double _bottomControlGap(double availableWidth) {
  if (availableWidth < 520) return 3;
  if (availableWidth < 760) return 4;
  return 8;
}

double _bottomControlSize(BoxConstraints constraints) {
  final screenSize = MediaQuery.sizeOf(context);
  final availableWidth = constraints.maxWidth.isFinite
      ? constraints.maxWidth
      : screenSize.width;
  final availableHeight = constraints.maxHeight.isFinite
      ? constraints.maxHeight
      : screenSize.height * 0.42;
  final gap = _bottomControlGap(availableWidth);
  final widthBased = (availableWidth - gap) / 2;
  final heightBased = availableHeight * 1.0;
  return min(widthBased, heightBased).clamp(170.0, 560.0);
}

double _bottomButtonSize(double panelSize) {
  // Larger keypad buttons while still fitting the input display and bottom row.
  return ((panelSize - 36) / 4).clamp(34.0, 128.0);
}

double _reactionOnlySize(BoxConstraints constraints) {
  final screenSize = MediaQuery.sizeOf(context);
  final availableWidth = constraints.maxWidth.isFinite
      ? constraints.maxWidth
      : screenSize.width;
  final availableHeight = constraints.maxHeight.isFinite
      ? constraints.maxHeight
      : screenSize.height;

  // Bigger centered companion GIF. It scales down automatically on smaller screens.
  return min(availableWidth * 0.72, availableHeight * 0.52).clamp(220.0, 520.0);
}

Widget _buildResponsiveBottomControls() {
  return LayoutBuilder(
    builder: (context, constraints) {
      final panelSize = _bottomControlSize(constraints);
      final gap = _bottomControlGap(constraints.maxWidth.isFinite
          ? constraints.maxWidth
          : MediaQuery.sizeOf(context).width);
      final buttonSize = _bottomButtonSize(panelSize);

      return Align(
        alignment: Alignment.bottomCenter,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: gap,
            runSpacing: 10,
            children: [
              SizedBox(
                width: panelSize,
                height: panelSize,
                child: NumberPad(
                  input: input,
                  isDisabled: isGameOver,
                  onNumberTap: appendInput,
                  onClear: clearInput,
                  onSubmit: submitInput,
                  panelSize: panelSize,
                  buttonSize: buttonSize,
                  alignment: Alignment.bottomCenter,
                ),
              ),
              SizedBox(
                width: panelSize,
                height: panelSize,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: GameReactionGif(
                    state: _reactionState,
                    size: panelSize,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

  static const Color _inkColor = Color(0xFF1B4965);
  static const Color _bgTopColor = Color(0xFFFFE5D9);
  static const Color _bgBottomColor = Color(0xFFFFCCB3);
  static const Color _panelColor = Color(0xFFFFF9E6);
  static const Color _accentColor = Color(0xFF069A8E);
  static const Duration _correctFeedbackDuration = Duration(milliseconds: 850);
  static const Duration _incorrectFeedbackDuration = Duration(milliseconds: 2600);
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
  bool _isSavingScore = false;
  
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
    GameLogger.endSession(); // Clean up session
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

    final status = await _faceProctor.start(
      absenceThreshold: const Duration(seconds: 3),
      onViolation: (event) {
        _handleFaceViolation(
          gameName: 'Number Memory',
          event: event,
        );
      },
    );

    if (status == FaceProctorStartStatus.started) {
      _isProctorActive = true;
      return true;
    }
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

    final revealDelaySeconds = displayTime >= minRevealToInputDelay
        ? displayTime
        : minRevealToInputDelay;

    // Use Timer instead of Future.delayed so we can cancel it
    _displayTimer = Timer(Duration(seconds: revealDelaySeconds), () {
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
      hearts = 3;
      _didLeaveApp = false;
      _processingLeaveAttempt = false;
      _showLeaveWarning = false;
      _showExitConfirmation = false;
      _suspendLeaveDetector = false;
      _leaveAttemptsThisRun = 0;
      _isSavingScore = false; // reset flag
    });
    startLevel();
    _isProctorActive = true;
  }

  Future<bool> _ensureFaceMonitoring() async {
    final status = await _faceProctor.start(
      absenceThreshold: const Duration(seconds: 3),
      onViolation: (event) {
        _handleFaceViolation(
          gameName: 'Number Memory',
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
        gameName: 'Number Memory',
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
      hearts = 3;
      isGameOver = false;
      showCorrectSplash = false;
      showIncorrectSplash = false;
      _showExitConfirmation = false;
      _suspendLeaveDetector = false;
      _didLeaveApp = false;
      _leaveAttemptsThisRun = 0;
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
      Future.delayed(_correctFeedbackDuration, () {
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
      Future.delayed(_incorrectFeedbackDuration, () {
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
              hearts = 3;
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
            input = '';
            number = '';
            timerKey = UniqueKey();
            displayTimerKey = UniqueKey();
            hasStarted = false;
            hearts = 3;
            isGameOver = false;
            showCorrectSplash = false;
            showIncorrectSplash = false;
          });
        },
      ),
    );
  }

  // 🔧 UPDATED saveScore with duplicate prevention
  Future<void> saveScore() async {
    if (_isSavingScore) return;
    _isSavingScore = true;
    try {
      await GameLogger.logGame(
        gameName: 'Number Memory',
        score: level,
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await updateLeaderboardEntry(
          gameName: 'Number Memory',
          newScore: level,
        );
      }
    } catch (e) {
      debugPrint('Error in saveScore (Number Memory): $e');
    } finally {
      _isSavingScore = false;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    onOk: _restartFromLeaveWarning,
                    onBack: _backFromLeaveWarning,
                  ),
                ),
              if (showCorrectSplash)
                const Positioned.fill(
                  child: IgnorePointer(
                    child: CorrectSplash(
                      duration: _correctFeedbackDuration,
                    ),
                  ),
                ),
              if (showIncorrectSplash)
                const Positioned.fill(
                  child: IgnorePointer(
                    child: IncorrectSplash(
                      duration: _incorrectFeedbackDuration,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  ThemeData _buildTheme(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: _inkColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: _inkColor,
        displayColor: _inkColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentColor,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: _inkColor, width: 2),
          ),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _inkColor,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
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
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: _panelColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _inkColor, width: 2.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332C3550),
            offset: Offset(5, 6),
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }


  Widget _buildInlineAnswerBox() {
    final displayText = input.isEmpty ? 'Your Answer' : input;
    final isPlaceholder = input.isEmpty;

    return Center(
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 210,
          maxWidth: 340,
          minHeight: 52,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isPlaceholder
                ? const Color(0xFFD6DFEB)
                : _accentColor.withValues(alpha: 0.75),
            width: 2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            displayText,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: TextStyle(
              fontSize: isPlaceholder ? 20 : 28,
              fontWeight: FontWeight.w900,
              color: isPlaceholder
                  ? const Color(0xFF6B7280)
                  : const Color(0xFF1B4965),
              letterSpacing: isPlaceholder ? 0 : 1.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: _card(
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
          ),
        ),
      ),
    );
  }

  Widget _buildGameUI() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 680 || constraints.maxWidth < 430;
        final sectionGap = isCompact ? 8.0 : 12.0;
        final cardPadding = EdgeInsets.symmetric(
          horizontal: isCompact ? 12 : 16,
          vertical: isCompact ? 10 : 14,
        );
        final titleSize = isCompact ? 20.0 : 24.0;
        final promptSize = isCompact ? 15.0 : 17.0;
        final numberSize = isCompact ? 38.0 : 48.0;

        return Column(
          children: [
            _card(
              padding: cardPadding,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Level $level',
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (!showNumber)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: isCompact ? 10 : 14),
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
            SizedBox(height: sectionGap),
            if (!showNumber) HeartsDisplay(hearts: hearts),
            if (!showNumber) SizedBox(height: sectionGap),
            if (showNumber)
              Expanded(
                child: LayoutBuilder(
                  builder: (context, innerConstraints) {
                    final gifSize = _reactionOnlySize(innerConstraints);
                    return Column(
                      children: [
                        Flexible(
                          flex: isCompact ? 4 : 5,
                          child: Center(
                            child: _card(
                              padding: EdgeInsets.fromLTRB(
                                isCompact ? 14 : 20,
                                isCompact ? 10 : 14,
                                isCompact ? 14 : 20,
                                isCompact ? 14 : 20,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: IconButton(
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 36,
                                        minHeight: 36,
                                      ),
                                      onPressed: null,
                                      icon: const Icon(Icons.record_voice_over_rounded),
                                      tooltip: 'Replay number voice',
                                    ),
                                  ),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      number,
                                      style: TextStyle(
                                        fontSize: numberSize,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: isCompact ? 5 : 8,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  SizedBox(height: isCompact ? 14 : 20),
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
                                  SizedBox(height: isCompact ? 12 : 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: skipToAnswerPhase,
                                      icon: const Icon(Icons.keyboard_arrow_right_rounded, size: 22),
                                      label: const Text('Start Answering'),
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: Size.fromHeight(isCompact ? 44 : 50),
                                        backgroundColor: _accentColor,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isCompact ? 14 : 18,
                                          vertical: isCompact ? 10 : 13,
                                        ),
                                        textStyle: TextStyle(
                                          fontSize: isCompact ? 14 : 16,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.4,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: sectionGap),
                        Flexible(
                          flex: isCompact ? 3 : 4,
                          child: Center(
                            child: GameReactionGif(
                              state: _reactionState,
                              size: gifSize,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              )
            else
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _card(
                      padding: cardPadding,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Enter the number you saw',
                                  style: TextStyle(
                                    fontSize: promptSize,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 36,
                                  minHeight: 36,
                                ),
                                onPressed: null,
                                icon: const Icon(Icons.volume_up_rounded),
                                tooltip: 'Replay prompt',
                              ),
                            ],
                          ),
                          SizedBox(height: isCompact ? 8 : 12),
                          _buildInlineAnswerBox(),
                        ],
                      ),
                    ),
                    SizedBox(height: sectionGap),
                    Expanded(
                      child: _buildResponsiveBottomControls(),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

}