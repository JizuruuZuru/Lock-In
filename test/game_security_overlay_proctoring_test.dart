import 'package:benchmark/services/face_proctor_contract.dart';
import 'package:benchmark/widgets/game_security_overlay.dart';
import 'package:benchmark/widgets/leave_warning_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A proctor that answers with whatever status the test asks for, and records
/// whether it was ever asked to start.
class _FakeFaceProctor implements FaceProctorService {
  _FakeFaceProctor(this.status);

  final FaceProctorStartStatus status;

  int startCalls = 0;
  int stopCalls = 0;

  @override
  bool get isRunning => false;

  @override
  Future<FaceProctorStartStatus> start({
    required FaceViolationCallback onViolation,
    Duration absenceThreshold = const Duration(seconds: 3),
  }) async {
    startCalls++;
    return status;
  }

  @override
  Future<void> stop() async => stopCalls++;
}

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required _FakeFaceProctor proctor,
    required bool enableFaceProctor,
    VoidCallback? onUnavailable,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              GameSecurityOverlay(
                gameName: 'Test Game',
                isActive: true,
                enableFaceProctor: enableFaceProctor,
                faceProctor: proctor,
                onProctoringUnavailable: onUnavailable,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('with proctoring switched off the camera is never opened',
      (tester) async {
    // The admin switch has to actually prevent the camera from opening, not
    // just hide a warning: the whole point is that no lens turns on.
    final proctor = _FakeFaceProctor(FaceProctorStartStatus.started);

    await pump(tester, proctor: proctor, enableFaceProctor: false);

    expect(proctor.startCalls, 0);
  });

  testWidgets('with proctoring switched on the camera is opened',
      (tester) async {
    final proctor = _FakeFaceProctor(FaceProctorStartStatus.started);

    await pump(tester, proctor: proctor, enableFaceProctor: true);

    expect(proctor.startCalls, 1);
  });

  testWidgets('a denied camera does not lock the game', (tester) async {
    // This is the regression that matters most. Declining the camera prompt
    // used to raise a blocking "Camera required" overlay, shutting a child out
    // of the app entirely with no way back in.
    var reportedUnavailable = false;
    final proctor = _FakeFaceProctor(FaceProctorStartStatus.permissionDenied);

    await pump(
      tester,
      proctor: proctor,
      enableFaceProctor: true,
      onUnavailable: () => reportedUnavailable = true,
    );
    await tester.pump();

    expect(find.byType(LeaveWarningOverlay), findsNothing,
        reason: 'the game must stay playable');
    expect(reportedUnavailable, isTrue,
        reason: 'the run has to be recorded as unwatched');
  });

  testWidgets('no front camera does not lock the game either', (tester) async {
    var reportedUnavailable = false;
    final proctor = _FakeFaceProctor(FaceProctorStartStatus.noFrontCamera);

    await pump(
      tester,
      proctor: proctor,
      enableFaceProctor: true,
      onUnavailable: () => reportedUnavailable = true,
    );
    await tester.pump();

    expect(find.byType(LeaveWarningOverlay), findsNothing);
    expect(reportedUnavailable, isTrue);
  });

  testWidgets('a failed initialisation does not lock the game', (tester) async {
    var reportedUnavailable = false;
    final proctor =
        _FakeFaceProctor(FaceProctorStartStatus.initializationFailed);

    await pump(
      tester,
      proctor: proctor,
      enableFaceProctor: true,
      onUnavailable: () => reportedUnavailable = true,
    );
    await tester.pump();

    expect(find.byType(LeaveWarningOverlay), findsNothing);
    expect(reportedUnavailable, isTrue);
  });

  testWidgets('an unsupported platform is not reported as unavailable',
      (tester) async {
    // Web and desktop were never going to be watched, so this is not an
    // exam-integrity event and must not mark the run unproctored.
    var reportedUnavailable = false;
    final proctor =
        _FakeFaceProctor(FaceProctorStartStatus.unsupportedPlatform);

    await pump(
      tester,
      proctor: proctor,
      enableFaceProctor: true,
      onUnavailable: () => reportedUnavailable = true,
    );
    await tester.pump();

    expect(find.byType(LeaveWarningOverlay), findsNothing);
    expect(reportedUnavailable, isFalse);
  });

  testWidgets('a declined camera is not re-prompted for on every resume',
      (tester) async {
    final proctor = _FakeFaceProctor(FaceProctorStartStatus.permissionDenied);

    await pump(tester, proctor: proctor, enableFaceProctor: true);
    await tester.pump();
    expect(proctor.startCalls, 1);

    // Rebuild the way a lifecycle change would.
    await tester.pump();
    await tester.pump();

    expect(proctor.startCalls, 1,
        reason: 'a refused permission must not re-prompt in a loop');
  });
}
