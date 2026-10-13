import 'dart:async';

import 'package:flutter/services.dart';

import 'monitoring_api.g.dart';

/// Órdenes y estado del recorrido experimental del motor (fase 5C).
///
/// La app depende de esta interfaz; las pruebas la sustituyen por un doble.
/// Kotlin decide las señales y reproduce el tono: Flutter solo pide órdenes
/// y presenta el estado compacto que recibe.
abstract interface class ExperimentalMonitoringBridge {
  Future<MonitoringSnapshot> snapshot();
  Future<MonitoringCommandResult> beginCalibration();
  Future<MonitoringCommandResult> cancelCalibration();
  Future<MonitoringCommandResult> testSound();
  Future<MonitoringCommandResult> confirmSoundHeard(String soundTestId);
  Future<MonitoringCommandResult> startSession(
    String calibrationId,
    String soundTestId,
  );
  Future<MonitoringCommandResult> pauseSession(String sessionId);
  Future<MonitoringCommandResult> resumeSession(String sessionId);
  Future<MonitoringCommandResult> stopSession(String sessionId);

  /// Cambios y latido (cada 1000 ms) del coordinador.
  Stream<MonitoringSnapshot> get updates;

  /// Mensajero efectivo y nombre/sufijo del canal de consulta.
  Object get queryChannel;
}

/// [ExperimentalMonitoringBridge] sobre los mensajes generados por Pigeon.
class PigeonExperimentalMonitoringBridge
    implements ExperimentalMonitoringBridge {
  PigeonExperimentalMonitoringBridge({ExperimentalMonitoringHostApi? host})
    : _host = host ?? ExperimentalMonitoringHostApi() {
    ExperimentalMonitoringFlutterApi.setUp(
      _Updates(_updates),
      binaryMessenger: _host.pigeonVar_binaryMessenger,
      messageChannelSuffix: _host.pigeonVar_messageChannelSuffix.isEmpty
          ? ''
          : _host.pigeonVar_messageChannelSuffix.substring(1),
    );
  }

  final ExperimentalMonitoringHostApi _host;
  final _updates = StreamController<MonitoringSnapshot>.broadcast();

  @override
  Object get queryChannel => _MonitoringChannelKey(
    _host.pigeonVar_binaryMessenger ??
        ServicesBinding.instance.defaultBinaryMessenger,
    _host.pigeonVar_messageChannelSuffix,
  );

  @override
  Future<MonitoringSnapshot> snapshot() => _host.getMonitoringSnapshot();

  @override
  Future<MonitoringCommandResult> beginCalibration() =>
      _host.beginCalibration();

  @override
  Future<MonitoringCommandResult> cancelCalibration() =>
      _host.cancelCalibration();

  @override
  Future<MonitoringCommandResult> testSound() => _host.testSound();

  @override
  Future<MonitoringCommandResult> confirmSoundHeard(String soundTestId) =>
      _host.confirmSoundHeard(soundTestId);

  @override
  Future<MonitoringCommandResult> startSession(
    String calibrationId,
    String soundTestId,
  ) => _host.startSession(calibrationId, soundTestId);

  @override
  Future<MonitoringCommandResult> pauseSession(String sessionId) =>
      _host.pauseSession(sessionId);

  @override
  Future<MonitoringCommandResult> resumeSession(String sessionId) =>
      _host.resumeSession(sessionId);

  @override
  Future<MonitoringCommandResult> stopSession(String sessionId) =>
      _host.stopSession(sessionId);

  @override
  Stream<MonitoringSnapshot> get updates => _updates.stream;
}

final class _MonitoringChannelKey {
  const _MonitoringChannelKey(this.messenger, this.suffix);
  final BinaryMessenger messenger;
  final String suffix;
  @override
  bool operator ==(Object other) =>
      other is _MonitoringChannelKey &&
      identical(messenger, other.messenger) &&
      suffix == other.suffix;
  @override
  int get hashCode => Object.hash(identityHashCode(messenger), suffix);
}

class _Updates implements ExperimentalMonitoringFlutterApi {
  _Updates(this._sink);

  final StreamController<MonitoringSnapshot> _sink;

  @override
  void onMonitoring(MonitoringSnapshot snapshot) => _sink.add(snapshot);
}
