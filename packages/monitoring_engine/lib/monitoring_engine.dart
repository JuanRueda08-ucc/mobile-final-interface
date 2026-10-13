import 'monitoring_engine_platform_interface.dart';

export 'src/front_camera.dart';
export 'src/monitoring_api.g.dart'
    show
        CameraPermissionStatus,
        FaceAnalysisSnapshot,
        FaceAnalysisStatus,
        PreviewCloseReason,
        PreviewClosedEvent,
        PreviewOpenResult,
        PreviewOpenStatus;

class MonitoringEngine {
  Future<String?> getPlatformVersion() {
    return MonitoringEnginePlatform.instance.getPlatformVersion();
  }
}
