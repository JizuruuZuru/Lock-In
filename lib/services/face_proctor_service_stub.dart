import 'face_proctor_contract.dart';

FaceProctorService createFaceProctorServiceImpl() => _UnsupportedFaceProctor();

class _UnsupportedFaceProctor implements FaceProctorService {
  @override
  bool get isRunning => false;

  @override
  Future<FaceProctorStartStatus> start({
    required FaceViolationCallback onViolation,
    Duration absenceThreshold = const Duration(seconds: 3),
  }) async {
    return FaceProctorStartStatus.unsupportedPlatform;
  }

  @override
  Future<void> stop() async {}
}
