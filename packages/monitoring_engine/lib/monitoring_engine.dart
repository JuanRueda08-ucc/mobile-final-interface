import 'monitoring_engine_platform_interface.dart';

export 'src/experimental_monitoring.dart';
export 'src/front_camera.dart';
export 'src/monitoring_api.g.dart'
    show
        CalibrationStep,
        EngineMeasurement,
        EngineSessionLifecycle,
        EngineSignal,
        MonitoringCommandResult,
        MonitoringSnapshot,
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
