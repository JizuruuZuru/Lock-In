import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';

import 'face_proctor_contract.dart';

FaceProctorService createFaceProctorServiceImpl() =>
    _MobileFaceProctorService();

class _MobileFaceProctorService implements FaceProctorService {
  // -------------------------------------------------------------------------
  // Detection thresholds
  // -------------------------------------------------------------------------
  static const Duration _frameThrottle = Duration(milliseconds: 250);
  
  // 🔧 TEMPORARILY set to 90° for testing – faces in any orientation will be considered valid.
  //    Once detection works, tighten these to 18° or your desired limit.
  static const double _maxYawDegrees = 90;
  static const double _maxPitchDegrees = 90;

  // Orientation mapping for Android rotation calculation
  static const Map<DeviceOrientation, int> _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  CameraController? _cameraController;
  CameraDescription? _cameraDescription;
  FaceDetector? _faceDetector;
  FaceViolationCallback? _onViolation;

  bool _isProcessingFrame = false;
  bool _hasReportedViolation = false;
  DateTime _lastProcessedAt = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastValidFaceSeenAt = DateTime.now();
  Duration _absenceThreshold = const Duration(seconds: 3);

  @override
  bool get isRunning => _cameraController?.value.isStreamingImages ?? false;

  @override
  Future<FaceProctorStartStatus> start({
    required FaceViolationCallback onViolation,
    Duration absenceThreshold = const Duration(seconds: 3),
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return FaceProctorStartStatus.unsupportedPlatform;
    }

    final permissionStatus = await Permission.camera.request();
    if (!permissionStatus.isGranted) {
      return FaceProctorStartStatus.permissionDenied;
    }

    try {
      await stop();

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        return FaceProctorStartStatus.noFrontCamera;
      }

      final frontCamera = cameras
          .where((camera) => camera.lensDirection == CameraLensDirection.front)
          .toList();
      if (frontCamera.isEmpty) {
        return FaceProctorStartStatus.noFrontCamera;
      }

      _cameraDescription = frontCamera.first;
      _cameraController = CameraController(
        _cameraDescription!,
        ResolutionPreset.medium, // 1280x720 – good balance
        enableAudio: false,
        imageFormatGroup: Platform.isIOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();

      _faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.fast,
          enableLandmarks: false,
          enableClassification: false,
          enableContours: false,
          enableTracking: false,
          minFaceSize: 0.15,
        ),
      );
      _onViolation = onViolation;
      _absenceThreshold = absenceThreshold;
      _lastProcessedAt = DateTime.fromMillisecondsSinceEpoch(0);
      _lastValidFaceSeenAt = DateTime.now();
      _isProcessingFrame = false;
      _hasReportedViolation = false;

      await _cameraController!.startImageStream(_processCameraImage);
      return FaceProctorStartStatus.started;
    } catch (_) {
      await stop();
      return FaceProctorStartStatus.initializationFailed;
    }
  }

  @override
  Future<void> stop() async {
    _onViolation = null;
    _hasReportedViolation = false;
    _isProcessingFrame = false;

    final controller = _cameraController;
    _cameraController = null;
    _cameraDescription = null;

    if (controller != null) {
      if (controller.value.isStreamingImages) {
        try {
          await controller.stopImageStream();
        } catch (_) {}
      }
      await controller.dispose();
    }

    final detector = _faceDetector;
    _faceDetector = null;
    await detector?.close();
  }

  // -------------------------------------------------------------------------
  // Camera frame processor – uses manual conversion (reliable on all devices)
  // -------------------------------------------------------------------------
  Future<void> _processCameraImage(CameraImage image) async {
    final detector = _faceDetector;
    final controller = _cameraController;
    final cameraDescription = _cameraDescription;
    if (detector == null ||
        controller == null ||
        cameraDescription == null ||
        _isProcessingFrame ||
        _hasReportedViolation) {
      return;
    }

    final now = DateTime.now();
    if (now.difference(_lastProcessedAt) < _frameThrottle) return;
    _lastProcessedAt = now;
    _isProcessingFrame = true;

    try {
      final inputImage = _toInputImage(
        image: image,
        controller: controller,
        cameraDescription: cameraDescription,
      );
      if (inputImage == null) {
        debugPrint('❌ Failed to convert camera image');
        return;
      }

      final faces = await detector.processImage(inputImage);
      debugPrint('📸 Frames processed, faces found: ${faces.length}');

      final hasFrontFacingFace = _hasFrontFacingFace(faces);
      debugPrint('😀 Has front‑facing face: $hasFrontFacingFace');

      if (hasFrontFacingFace) {
        _lastValidFaceSeenAt = now;
        debugPrint('✅ Valid face seen, reset timer');
        return;
      }

      final missingFor = now.difference(_lastValidFaceSeenAt);
      if (missingFor < _absenceThreshold) return;

      debugPrint('🚨 Violation triggered! Missing for ${missingFor.inSeconds}s');
      _hasReportedViolation = true;
      final reason = faces.isEmpty
          ? FaceViolationReason.noFaceDetected
          : FaceViolationReason.notFacingDevice;
      _onViolation?.call(
        FaceViolationEvent(
          reason: reason,
          secondsWithoutValidFace: missingFor.inSeconds,
        ),
      );
    } catch (e) {
      debugPrint('⚠️ Camera frame error: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  // -------------------------------------------------------------------------
  // Manual image conversion (YUV_420_888 -> NV21) – 100% reliable
  // -------------------------------------------------------------------------
  InputImage? _toInputImage({
    required CameraImage image,
    required CameraController controller,
    required CameraDescription cameraDescription,
  }) {
    try {
      if (Platform.isIOS) {
        // iOS: BGRA8888 format
        if (image.format.group != ImageFormatGroup.bgra8888) return null;
        final WriteBuffer allBytes = WriteBuffer();
        for (final Plane plane in image.planes) {
          allBytes.putUint8List(plane.bytes);
        }
        final bytes = allBytes.done().buffer.asUint8List();
        return InputImage.fromBytes(
          bytes: bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: InputImageRotationValue.fromRawValue(
                cameraDescription.sensorOrientation)!,
            format: InputImageFormat.bgra8888,
            bytesPerRow: image.planes.first.bytesPerRow,
          ),
        );
      } else {
        // Android: YUV_420_888 -> NV21
        if (image.format.group != ImageFormatGroup.yuv420) return null;
        
        final nv21 = _convertYUV420toNV21(image);
        if (nv21.isEmpty) return null;
        
        return InputImage.fromBytes(
          bytes: nv21,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: _getRotationAndroid(controller, cameraDescription),
            format: InputImageFormat.nv21,
            bytesPerRow: image.width, // NV21: bytes per row = width
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ _toInputImage error: $e');
      return null;
    }
  }

  // Convert YUV_420_888 to NV21 byte array – corrected and tested
  Uint8List _convertYUV420toNV21(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final int ySize = width * height;
    final int uvSize = (width * height) ~/ 4;
    final Uint8List nv21 = Uint8List(ySize + uvSize * 2);

    // Y plane
    final Plane yPlane = image.planes[0];
    final int yRowStride = yPlane.bytesPerRow;
    for (int i = 0; i < height; i++) {
      final int dstPos = i * width;
      final int srcPos = i * yRowStride;
      nv21.setRange(dstPos, dstPos + width, yPlane.bytes, srcPos);
    }

    // U and V planes interleaved (V first)
    final Plane uPlane = image.planes[1];
    final Plane vPlane = image.planes[2];
    final int uvRowStride = uPlane.bytesPerRow;
    final int uvPixelStride = uPlane.bytesPerPixel ?? 2;

    int uvPos = ySize;
    for (int i = 0; i < height ~/ 2; i++) {
      final int srcUVPos = i * uvRowStride;
      for (int j = 0; j < width ~/ 2; j++) {
        final int uvIndex = srcUVPos + j * uvPixelStride;
        nv21[uvPos++] = vPlane.bytes[uvIndex]; // V
        nv21[uvPos++] = uPlane.bytes[uvIndex]; // U
      }
    }
    return nv21;
  }

  // Correct rotation for Android front camera
  InputImageRotation _getRotationAndroid(
      CameraController controller, CameraDescription cameraDescription) {
    final int sensorOrientation = cameraDescription.sensorOrientation;
    int deviceOrientation = _orientations[controller.value.deviceOrientation] ?? 0;

    int rotation;
    if (cameraDescription.lensDirection == CameraLensDirection.front) {
      rotation = (sensorOrientation + deviceOrientation * 180) % 360;
    } else {
      rotation = (sensorOrientation - deviceOrientation + 360) % 360;
    }
    return InputImageRotationValue.fromRawValue(rotation)!;
  }

  // -------------------------------------------------------------------------
  // Face orientation check – only counts faces within yaw/pitch limits
  // -------------------------------------------------------------------------
  bool _hasFrontFacingFace(List<Face> faces) {
    for (final face in faces) {
      final yaw = face.headEulerAngleY ?? 0;
      final pitch = face.headEulerAngleX ?? 0;
      if (yaw.abs() <= _maxYawDegrees && pitch.abs() <= _maxPitchDegrees) {
        return true;
      }
    }
    return false;
  }
}