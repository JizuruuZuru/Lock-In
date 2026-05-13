import 'face_proctor_contract.dart';
import 'face_proctor_service_stub.dart'
    if (dart.library.io) 'face_proctor_service_mobile.dart';

FaceProctorService createFaceProctorService() => createFaceProctorServiceImpl();
