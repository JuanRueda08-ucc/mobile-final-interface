import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_engine/monitoring_engine.dart';
import 'package:monitoring_engine/monitoring_engine_platform_interface.dart';
import 'package:monitoring_engine/monitoring_engine_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockMonitoringEnginePlatform
    with MockPlatformInterfaceMixin
    implements MonitoringEnginePlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final MonitoringEnginePlatform initialPlatform =
      MonitoringEnginePlatform.instance;

  test('$MethodChannelMonitoringEngine is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelMonitoringEngine>());
  });

  test('getPlatformVersion', () async {
    MonitoringEngine monitoringEnginePlugin = MonitoringEngine();
    MockMonitoringEnginePlatform fakePlatform = MockMonitoringEnginePlatform();
    MonitoringEnginePlatform.instance = fakePlatform;

    expect(await monitoringEnginePlugin.getPlatformVersion(), '42');
  });
}
