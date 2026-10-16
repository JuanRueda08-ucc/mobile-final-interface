import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monitoring_engine/monitoring_engine.dart';

final experimentalBridgeProvider = Provider<ExperimentalMonitoringBridge>(
  (ref) => PigeonExperimentalMonitoringBridge(),
);
