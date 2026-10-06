import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'monitoring_engine_platform_interface.dart';

/// An implementation of [MonitoringEnginePlatform] that uses method channels.
class MethodChannelMonitoringEngine extends MonitoringEnginePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('monitoring_engine');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
