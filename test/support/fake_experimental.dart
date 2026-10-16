import 'dart:async';

import 'package:clock/clock.dart';

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
  String soundPatternId = 'patron_1',
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
  int? eyesValidForMs,
  int? signalValidForMs,
  int? observationId,
}) => MonitoringSnapshot(
  engineInstanceId: engine,
  sequence: sequence,
  profileId: 'lab-eye-rules-0.1',
  qualificationStatus: 'experimental',
  eyesValid: eyesValid,
  observationId: observationId,
  eyesValidForMs: eyesValidForMs ?? (eyesValid ? 750 : null),
  signalValidForMs:
      signalValidForMs ?? (signal == EngineSignal.notEvaluable ? null : 150),
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
  soundPatternId: soundPatternId,
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
    : current = initial ?? fakeSnapshot(),
      _age = clock.stopwatch()..start() {
    _stamp(current);
  }

  MonitoringSnapshot current;
  final calls = <String>[];
  final _updates = StreamController<MonitoringSnapshot>.broadcast();
  Stopwatch _age;
  final _retired = <String>{};
  int _observation = 0;
  void _stamp(MonitoringSnapshot s) {
    if (s.eyesValid || s.signal != EngineSignal.notEvaluable) {
      s.observationId ??= ++_observation;
      if (s.observationId! > _observation) _observation = s.observationId!;
    }
  }

  @override
  Object get queryChannel => this;

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
    if (!_retired.contains(s.engineInstanceId) &&
        (s.engineInstanceId != current.engineInstanceId ||
            s.sequence > current.sequence)) {
      if (s.engineInstanceId != current.engineInstanceId) {
        _retired.add(current.engineInstanceId);
      }
      current = s;
      _stamp(current);
      _age = clock.stopwatch()..start();
    }
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
    _stamp(s);
    if (next != null) _age = clock.stopwatch()..start();
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
    final s = MonitoringSnapshot.decode(current.encode());
    final elapsed = _age.elapsedMilliseconds;
    s.eyesValidForMs = s.eyesValidForMs == null
        ? null
        : s.eyesValidForMs! - elapsed;
    s.signalValidForMs = s.signalValidForMs == null
        ? null
        : s.signalValidForMs! - elapsed;
    return s;
  }

  @override
  Future<MonitoringCommandResult> beginCalibration() => _cmd('calibrate');

  @override
  Future<MonitoringCommandResult> cancelCalibration() =>
      _cmd('cancelCalibration');

  /// Patrones con los que se pidió cada prueba de sonido.
  final testPatterns = <String>[];

  @override
  Future<MonitoringCommandResult> testSound(String patternId) {
    testPatterns.add(patternId);
    return _cmd('testSound');
  }

  /// Retiene los cambios de patrón (independiente de [hold]).
  Completer<void>? patternHold;

  /// Código de rechazo del siguiente cambio de patrón.
  String? rejectPattern;
  String? settingsChange;
  (String, String)? finishedSettings;
  bool failBeginSettings = false;
  bool loseFinishReply = false;
  bool restartOnFinish = false;

  @override
  Future<MonitoringCommandResult> beginSettingsChange(
    String id,
    String patternId,
  ) async {
    if (failBeginSettings) throw StateError('motor no disponible');
    if (settingsChange == id) {
      return MonitoringCommandResult(accepted: true, snapshot: current);
    }
    if (current.lifecycle == EngineSessionLifecycle.active ||
        current.lifecycle == EngineSessionLifecycle.paused) {
      current = _resequence(current);
      return MonitoringCommandResult(
        accepted: false,
        errorCode: 'sessionActive',
        snapshot: current,
      );
    }
    final r = await setSoundPattern(patternId);
    if (r.accepted) settingsChange = id;
    return r;
  }

  @override
  Future<MonitoringCommandResult> finishSettingsChange(
    String id,
    String patternId,
  ) async {
    if (restartOnFinish) {
      restartOnFinish = false;
      settingsChange = null;
      finishedSettings = null;
      current = _resequence(fakeSnapshot(engine: 'motor-reabierto'));
    }
    if (settingsChange == null && finishedSettings == (id, patternId)) {
      return MonitoringCommandResult(accepted: true, snapshot: current);
    }
    if (settingsChange != id) {
      return MonitoringCommandResult(
        accepted: false,
        errorCode: 'unknownSettingsChange',
        snapshot: current,
      );
    }
    final r = await setSoundPattern(patternId);
    if (r.accepted) {
      settingsChange = null;
      finishedSettings = (id, patternId);
    }
    if (loseFinishReply) {
      loseFinishReply = false;
      throw StateError('respuesta perdida después de aplicar');
    }
    return r;
  }

  /// Como el motor (fase 5E): un patrón distinto invalida la prueba de
  /// sonido y su confirmación; con sesión vigente se rechaza.
  @override
  Future<MonitoringCommandResult> setSoundPattern(String patternId) async {
    calls.add('soundPattern:$patternId');
    final h = patternHold;
    if (h != null) await h.future;
    var code = rejectPattern;
    rejectPattern = null;
    var s = current;
    if (code == null && s.soundPatternId != patternId) {
      if (s.lifecycle == EngineSessionLifecycle.active ||
          s.lifecycle == EngineSessionLifecycle.paused) {
        code = 'sessionActive';
      } else {
        s = MonitoringSnapshot.decode(s.encode())
          ..soundPatternId = patternId
          ..soundTestId = null
          ..soundTestPlayed = false
          ..soundHeard = false
          ..soundFailure = null;
      }
    }
    current = _resequence(s);
    return MonitoringCommandResult(
      accepted: code == null,
      errorCode: code,
      snapshot: current,
    );
  }

  /// Retiene las vistas previas de P13 y fija su rechazo.
  Completer<void>? previewHold;
  String? rejectPreview;

  @override
  Future<MonitoringCommandResult> previewSound(String patternId) async {
    calls.add('preview:$patternId');
    final h = previewHold;
    if (h != null) await h.future;
    final code = rejectPreview;
    rejectPreview = null;
    current = _resequence(current);
    return MonitoringCommandResult(
      accepted: code == null,
      errorCode: code,
      snapshot: current,
    );
  }

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
