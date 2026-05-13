enum FaceProctorStartStatus {
  started,
  unsupportedPlatform,
  permissionDenied,
  noFrontCamera,
  initializationFailed,
}

enum FaceViolationReason {
  noFaceDetected,
  notFacingDevice,
}

class FaceViolationEvent {
  final FaceViolationReason reason;
  final int secondsWithoutValidFace;

  const FaceViolationEvent({
    required this.reason,
    required this.secondsWithoutValidFace,
  });
}

typedef FaceViolationCallback = void Function(FaceViolationEvent event);

abstract class FaceProctorService {
  bool get isRunning;

  Future<FaceProctorStartStatus> start({
    required FaceViolationCallback onViolation,
    Duration absenceThreshold = const Duration(seconds: 3),
  });

  Future<void> stop();
}
