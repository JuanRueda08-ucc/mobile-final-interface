import 'dart:async';

import 'package:monitoring_engine/monitoring_engine.dart';

/// Estado compacto del coordinador para pruebas. **No es una medición**: lo
/// fija la prueba. La lógica real se prueba en Kotlin (JVM) y en Android.
MonitoringSnapshot fakeSnapshot({
  String engine = 'motor-1',
  int sequence = 1,
  bool eyesValid = false,
  String? eyeIssue = 'noResults',
  double? earRight,
  double? earLeft,
  double? ratioRight,
  double? ratioLeft,
  CalibrationStep step = CalibrationStep.idle,
  int probe = 0,
  int? stepElapsedMs,
  int? stepDurationMs,
  int? stepValidSamples,
  String? calibrationId,
  String? calibrationRejection,
  double? openEarRight,
  double? openEarLeft,
  int? calibrationSamples,
  String? soundTestId,
  bool soundTestPlayed = false,
  bool soundHeard = false,
  String? soundFailure,
  EngineSessionLifecycle lifecycle = EngineSessionLifecycle.none,
  bool resumePending = false,
  String? sessionId,
  EngineMeasurement measurement = EngineMeasurement.unavailable,
  EngineSignal signal = EngineSignal.notEvaluable,
  String? measurementCause,
  int activeMs = 0,
  int pausedMs = 0,
  int evaluableMs = 0,
  int closureActivations = 0,
  int tonesPlayed = 0,
  int tonesFailed = 0,
}) => MonitoringSnapshot(
  engineInstanceId: engine,
  sequence: sequence,
  profileId: 'lab-eye-rules-0.1',
  qualificationStatus: 'experimental',
  eyesValid: eyesValid,
  eyeIssue: eyesValid ? null : eyeIssue,
  earRight: earRight,
  earLeft: earLeft,
  ratioRight: ratioRight,
  ratioLeft: ratioLeft,
  calibrationStep: step,
  calibrationAttempt: step == CalibrationStep.idle ? 0 : 1,
  calibrationProbe: probe,
  stepElapsedMs: stepElapsedMs,
  stepDurationMs: stepDurationMs,
  stepValidSamples: stepValidSamples,
  calibrationId: calibrationId,
  calibrationRejection: calibrationRejection,
  openEarRight: openEarRight,
  openEarLeft: openEarLeft,
  calibrationSamples: calibrationSamples,
  soundTestId: soundTestId,
  soundTestPlayed: soundTestPlayed,
  soundHeard: soundHeard,
  soundFailure: soundFailure,
  lifecycle: lifecycle,
  resumePending: resumePending,
  sessionId: sessionId,
  measurement: measurement,
  signal: signal,
  measurementCause: measurementCause,
  activeMs: activeMs,
  pausedMs: pausedMs,
  evaluableMs: evaluableMs,
  closureActivations: closureActivations,
  tonesPlayed: tonesPlayed,
  tonesFailed: tonesFailed,
);

/// Doble de [ExperimentalMonitoringBridge]: registra las órdenes y responde
/// con el estado que fija la prueba ([next]) o con un rechazo.
class FakeExperimentalBridge implements ExperimentalMonitoringBridge {
  FakeExperimentalBridge([MonitoringSnapshot? initial])
    : current = initial ?? fakeSnapshot();

  MonitoringSnapshot current;
  final calls = <String>[];
  final _updates = StreamController<MonitoringSnapshot>.broadcast();

  /// Estado con el que responderá la siguiente orden (si es nulo, el actual
  /// con otra secuencia).
  MonitoringSnapshot? next;

  /// Código de rechazo de la siguiente orden.
  String? rejectNext;

  /// Retiene las órdenes hasta [release].
  Completer<void>? hold;

  int _seq = 100;

  /// Publica [s] como aviso del motor.
  void emit(MonitoringSnapshot s) {
    if (s.sequence > _seq) _seq = s.sequence;
    current = s;
    _updates.add(s);
  }

  Future<void> release() async => hold?.complete();

  Future<MonitoringCommandResult> _cmd(String name) async {
    calls.add(name);
    final h = hold;
    if (h != null) await h.future;
    final code = rejectNext;
    rejectNext = null;
    final s = next ?? current;
    next = null;
    current = _resequence(s);
    return MonitoringCommandResult(
      accepted: code == null,
      errorCode: code,
      snapshot: current,
    );
  }

  MonitoringSnapshot _resequence(MonitoringSnapshot s) {
    final copy = MonitoringSnapshot.decode(s.encode());
    copy.sequence = ++_seq;
    return copy;
  }

  @override
  Future<MonitoringSnapshot> snapshot() async {
    calls.add('snapshot');
    return current;
  }

  @override
  Future<MonitoringCommandResult> beginCalibration() => _cmd('calibrate');

  @override
  Future<MonitoringCommandResult> cancelCalibration() =>
      _cmd('cancelCalibration');

  @override
  Future<MonitoringCommandResult> testSound() => _cmd('testSound');

  @override
  Future<MonitoringCommandResult> confirmSoundHeard(String soundTestId) =>
      _cmd('confirmSound:$soundTestId');

  @override
  Future<MonitoringCommandResult> startSession(
    String calibrationId,
    String soundTestId,
  ) => _cmd('start:$calibrationId:$soundTestId');

  @override
  Future<MonitoringCommandResult> pauseSession(String sessionId) =>
      _cmd('pause:$sessionId');

  @override
  Future<MonitoringCommandResult> resumeSession(String sessionId) =>
      _cmd('resume:$sessionId');

  @override
  Future<MonitoringCommandResult> stopSession(String sessionId) =>
      _cmd('stop:$sessionId');

  @override
  Stream<MonitoringSnapshot> get updates => _updates.stream;
}
