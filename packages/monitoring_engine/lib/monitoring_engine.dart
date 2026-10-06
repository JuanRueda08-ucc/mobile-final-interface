import 'monitoring_engine_platform_interface.dart';

class MonitoringEngine {
  Future<String?> getPlatformVersion() {
    return MonitoringEnginePlatform.instance.getPlatformVersion();
  }
}
