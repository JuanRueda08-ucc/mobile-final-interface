import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'monitoring_engine_method_channel.dart';

abstract class MonitoringEnginePlatform extends PlatformInterface {
  /// Constructs a MonitoringEnginePlatform.
  MonitoringEnginePlatform() : super(token: _token);

  static final Object _token = Object();

  static MonitoringEnginePlatform _instance = MethodChannelMonitoringEngine();

  /// The default instance of [MonitoringEnginePlatform] to use.
  ///
  /// Defaults to [MethodChannelMonitoringEngine].
  static MonitoringEnginePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MonitoringEnginePlatform] when
  /// they register themselves.
  static set instance(MonitoringEnginePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
