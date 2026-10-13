import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monitoring_engine/monitoring_engine.dart';

/// Estado del recorrido experimental tal como lo presenta Flutter (fase 5C).
@immutable
class ExperimentalState {
  const ExperimentalState({
    this.snapshot,
    this.connected = false,
    this.pending,
    this.rejection,
    this.bridgeError = false,
  });

  /// Último estado del coordinador nativo aceptado (en orden).
  final MonitoringSnapshot? snapshot;

  /// `false` sin estado o tras [ExperimentalMonitoringController.connectionTimeout]
  /// sin mensajes: no se muestra ninguna señal.
  final bool connected;

  /// Orden en curso; las pulsaciones repetidas no crean otra.
  final String? pending;

  /// Código del último rechazo del motor.
  final String? rejection;

  /// La última orden falló en el canal.
  final bool bridgeError;

  ExperimentalState copyWith({
    MonitoringSnapshot? snapshot,
    bool? connected,
    String? Function()? pending,
    String? Function()? rejection,
    bool? bridgeError,
  }) => ExperimentalState(
    snapshot: snapshot ?? this.snapshot,
    connected: connected ?? this.connected,
    pending: pending == null ? this.pending : pending(),
    rejection: rejection == null ? this.rejection : rejection(),
    bridgeError: bridgeError ?? this.bridgeError,
  );

  EngineSessionLifecycle get lifecycle =>
      snapshot?.lifecycle ?? EngineSessionLifecycle.none;

  bool get sessionVigente =>
      lifecycle == EngineSessionLifecycle.active ||
      lifecycle == EngineSessionLifecycle.paused;

  bool get calibrating => switch (snapshot?.calibrationStep) {
    CalibrationStep.openReference ||
    CalibrationStep.closeLeadIn ||
    CalibrationStep.closedProbe ||
    CalibrationStep.reopen => true,
    _ => false,
  };

  /// Señal que se muestra: sin conexión vigente, nunca una señal.
  EngineSignal get signal => connected
      ? snapshot?.signal ?? EngineSignal.notEvaluable
      : EngineSignal.notEvaluable;
}

/// Puente con el coordinador experimental. Las pruebas lo sustituyen.
final experimentalBridgeProvider = Provider<ExperimentalMonitoringBridge>(
  (ref) => PigeonExperimentalMonitoringBridge(),
);

final experimentalMonitoringProvider =
    NotifierProvider<ExperimentalMonitoringController, ExperimentalState>(
      ExperimentalMonitoringController.new,
    );

/// Controlador del recorrido experimental. **No decide señales**: pide
/// órdenes al motor y presenta su estado.
///
/// - Acepta estados en orden (`sequence` creciente dentro de la misma
///   instancia del motor); uno de otra instancia sustituye al anterior.
/// - Conexión: 3000 ms sin mensajes (propuesta de transporte del Área 04
///   §8) la declaran no disponible y se deja de mostrar la señal.
/// - Una orden a la vez; las pulsaciones repetidas no crean otra.
class ExperimentalMonitoringController extends Notifier<ExperimentalState> {
  static const connectionTimeout = Duration(milliseconds: 3000);

  late ExperimentalMonitoringBridge _bridge;
  Timer? _silence;

  @override
  ExperimentalState build() {
    _bridge = ref.read(experimentalBridgeProvider);
    final sub = _bridge.updates.listen(_apply);
    ref.onDispose(() {
      sub.cancel();
      _silence?.cancel();
    });
    return const ExperimentalState();
  }

  /// Consulta el estado al entrar en la pantalla.
  Future<void> refresh() async {
    try {
      final s = await _bridge.snapshot();
      if (ref.mounted) _apply(s);
    } catch (e) {
      debugPrint('Vigía · estado experimental no disponible: $e');
      if (ref.mounted) state = state.copyWith(connected: false);
    }
  }

  void _apply(MonitoringSnapshot s) {
    if (!ref.mounted) return;
    final cur = state.snapshot;
    if (cur != null &&
        cur.engineInstanceId == s.engineInstanceId &&
        s.sequence <= cur.sequence) {
      return;
    }
    _silence?.cancel();
    _silence = Timer(connectionTimeout, () {
      if (ref.mounted) state = state.copyWith(connected: false);
    });
    state = state.copyWith(snapshot: s, connected: true);
  }

  Future<bool> _command(
    String name,
    Future<MonitoringCommandResult> Function() run,
  ) async {
    if (state.pending != null) return false;
    state = state.copyWith(
      pending: () => name,
      rejection: () => null,
      bridgeError: false,
    );
    try {
      final r = await run();
      if (!ref.mounted) return false;
      state = state.copyWith(
        pending: () => null,
        rejection: () => r.accepted ? null : r.errorCode,
      );
      _apply(r.snapshot);
      return r.accepted;
    } catch (e) {
      debugPrint('Vigía · orden $name sin respuesta: $e');
      if (ref.mounted) {
        state = state.copyWith(pending: () => null, bridgeError: true);
      }
      return false;
    }
  }

  Future<bool> beginCalibration() =>
      _command('calibrate', _bridge.beginCalibration);

  Future<bool> cancelCalibration() =>
      _command('cancelCalibration', _bridge.cancelCalibration);

  Future<bool> testSound() => _command('testSound', _bridge.testSound);

  Future<bool> confirmSoundHeard() {
    final id = state.snapshot?.soundTestId;
    if (id == null) return Future.value(false);
    return _command('confirmSound', () => _bridge.confirmSoundHeard(id));
  }

  Future<bool> start() {
    final s = state.snapshot;
    final cal = s?.calibrationId;
    final sound = s?.soundTestId;
    if (cal == null || sound == null) return Future.value(false);
    return _command('start', () => _bridge.startSession(cal, sound));
  }

  Future<bool> pause() => _withSession('pause', _bridge.pauseSession);

  Future<bool> resume() => _withSession('resume', _bridge.resumeSession);

  Future<bool> stop() => _withSession('stop', _bridge.stopSession);

  Future<bool> _withSession(
    String name,
    Future<MonitoringCommandResult> Function(String) run,
  ) {
    final id = state.snapshot?.sessionId;
    if (id == null) return Future.value(false);
    return _command(name, () => run(id));
  }
}
