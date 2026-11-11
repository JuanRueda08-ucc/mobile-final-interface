import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monitoring_engine/monitoring_engine.dart';

import '../settings/preferences_controller.dart';
import '../settings/real_settings_writer.dart';
import 'experimental_bridge_provider.dart';
export 'experimental_bridge_provider.dart';
import 'monitoring_query_channel.dart';
import 'monitoring_account.dart';

/// Estado del recorrido experimental tal como lo presenta Flutter (fase 5C).
@immutable
class ExperimentalState {
  const ExperimentalState({
    this.snapshot,
    this.connected = false,
    this.pending,
    this.rejection,
    this.bridgeError = false,
    this.eyesFresh = true,
    this.signalFresh = true,
    this.queryStalled = false,
    this.validityWatch,
    this.eyesValidity,
    this.signalValidity,
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
  final bool eyesFresh;
  final bool signalFresh;
  final bool queryStalled;

  /// Plazos locales conservadores. También se consultan al leer, aunque el
  /// bucle de eventos todavía no haya ejecutado los temporizadores.
  final Stopwatch? validityWatch;
  final Duration? eyesValidity;
  final Duration? signalValidity;
  bool _within(Duration? budget) =>
      budget == null ||
      validityWatch == null ||
      validityWatch!.elapsed <= budget;
  bool get _eyesCurrent => eyesFresh && _within(eyesValidity);
  bool get _signalCurrent =>
      signalFresh && _eyesCurrent && _within(signalValidity);

  bool get available => connected && !queryStalled;
  bool get eyesValid =>
      available && _eyesCurrent && (snapshot?.eyesValid ?? false);
  EngineMeasurement get measurement => !available
      ? EngineMeasurement.unavailable
      : snapshot?.measurement == EngineMeasurement.usable && !_signalCurrent
      ? (_eyesCurrent
            ? EngineMeasurement.limited
            : EngineMeasurement.unavailable)
      : snapshot?.measurement ?? EngineMeasurement.unavailable;

  ExperimentalState copyWith({
    MonitoringSnapshot? snapshot,
    bool? connected,
    String? Function()? pending,
    String? Function()? rejection,
    bool? bridgeError,
    bool? eyesFresh,
    bool? signalFresh,
    bool? queryStalled,
    Stopwatch? validityWatch,
    Duration? eyesValidity,
    Duration? signalValidity,
  }) => ExperimentalState(
    snapshot: snapshot ?? this.snapshot,
    connected: connected ?? this.connected,
    pending: pending == null ? this.pending : pending(),
    rejection: rejection == null ? this.rejection : rejection(),
    bridgeError: bridgeError ?? this.bridgeError,
    eyesFresh: eyesFresh ?? this.eyesFresh,
    signalFresh: signalFresh ?? this.signalFresh,
    queryStalled: queryStalled ?? this.queryStalled,
    validityWatch: validityWatch ?? this.validityWatch,
    eyesValidity: eyesValidity ?? this.eyesValidity,
    signalValidity: signalValidity ?? this.signalValidity,
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
  EngineSignal get signal => available && _signalCurrent
      ? snapshot?.signal ?? EngineSignal.notEvaluable
      : EngineSignal.notEvaluable;
}

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
/// - **Patrón de sonido (fase 5E).** El motor usa el patrón guardado en
///   Ajustes: se le envía al confirmarse un guardado y cada vez que su
///   estado indica otro (fuera de sesión), y la prueba de sonido lo lleva
///   consigo. El cambio de patrón va por su propio canal de orden, así que
///   no espera a otra orden ni la bloquea. Mientras el motor no informe el
///   patrón guardado, su prueba no cuenta aquí: no se confirma ni se inicia
///   con la prueba de otro patrón ([soundConfirmedFor]).
class ExperimentalMonitoringController extends Notifier<ExperimentalState> {
  static const connectionTimeout = Duration(milliseconds: 3000);

  late ExperimentalMonitoringBridge _bridge;
  Timer? _silence;
  Timer? _poll;
  Timer? _queryTimeout;
  Timer? _eyesExpiry;
  Timer? _signalExpiry;
  MonitoringQueryTicket<MonitoringSnapshot>? _watched;
  MonitoringQueryListener<MonitoringSnapshot>? _listener;
  MonitoringQueryListener<MonitoringCommandResult>? _commandListener;
  Timer? _commandTimeout;
  Completer<bool>? _commandCompletion;
  MonitoringSnapshot? _latest;
  final _retiredEngines = <String>{};
  bool _active = true;
  int _epoch = 0;
  int? _observation;
  int _eyesRetired = -1;
  int _signalRetired = -1;
  Duration? _eyesLeft;
  Duration? _signalLeft;
  Stopwatch? _validityWatch;
  static const queryTimeout = Duration(milliseconds: 750);
  static const pollInterval = Duration(milliseconds: 100);

  /// Patrón del último rechazo definitivo del motor, por instancia: no se
  /// reenvía en cada estado (un patrón fuera del catálogo nunca se acepta).
  (String, String)? _patternRefused;

  /// Las respuestas de Ajustes actualizan configuración/ciclo, nunca renuevan
  /// la vigencia de mediciones. El canal normal vuelve a medir su transporte.
  void _settingsSnapshot(MonitoringSnapshot s) {
    if (!ref.mounted || _retiredEngines.contains(s.engineInstanceId)) return;
    final previous = _latest;
    if (previous != null &&
        previous.engineInstanceId == s.engineInstanceId &&
        s.sequence < previous.sequence) {
      return;
    }
    if (previous != null && previous.engineInstanceId != s.engineInstanceId) {
      _retiredEngines.add(previous.engineInstanceId);
    }
    _latest = s;
    state = state.copyWith(
      snapshot: s,
      connected: false,
      eyesFresh: false,
      signalFresh: false,
    );
    _syncPattern();
  }

  /// Patrón confirmado por SQLite.
  String get savedSoundPattern =>
      ref.read(preferencesProvider).value.soundPatternId;

  /// Consulta al entrar en Ajustes sin abrir cámara ni arrancar el monitoreo.
  Future<void> querySettings() async {
    _settingsSnapshot(await queryCurrentSnapshot());
  }

  /// Consulta puntual del ciclo de sesión, sin abrir cámara ni iniciar sondeos.
  Future<MonitoringSnapshot> queryCurrentSnapshot({
    void Function(VoidCallback)? onDispose,
  }) async {
    final ticket =
        MonitoringQueryChannel.pendingOn(_bridge) ??
        MonitoringQueryChannel.start(_bridge, _epoch, clock.stopwatch());
    if (ticket == null) throw StateError('Consulta no disponible');
    final done = Completer<MonitoringSnapshot>();
    final listener = ticket.listen((r) {
      if (r.error != null ||
          r.answer == null ||
          r.watch.elapsed >= queryTimeout) {
        done.completeError(StateError('Motor no disponible'));
      } else {
        done.complete(r.answer!);
      }
    });
    final timeout = Timer(queryTimeout, () {
      if (!done.isCompleted) {
        done.completeError(StateError('Motor no disponible'));
      }
    });
    onDispose?.call(() {
      timeout.cancel();
      listener.cancel();
      if (!done.isCompleted) {
        done.completeError(StateError('Consulta cancelada'));
      }
    });
    try {
      return await done.future;
    } finally {
      timeout.cancel();
      listener.cancel();
    }
  }

  @override
  ExperimentalState build() {
    _bridge = ref.read(experimentalBridgeProvider);
    final sub = _bridge.updates.listen(_notice);
    final settingsSub = ref
        .read(realSettingsWriterProvider)
        .snapshots
        .listen(_settingsSnapshot);
    ref.listen(
      preferencesProvider.select((p) => p.value.soundPatternId),
      (_, _) => _syncPattern(force: true),
    );
    ref.onDispose(() {
      sub.cancel();
      settingsSub.cancel();
      _cancelTimers();
      _active = false;
      _epoch++;
    });
    return const ExperimentalState();
  }

  /// Consulta el estado al entrar en la pantalla.
  Future<void> refresh() async {
    if (!ref.mounted) return;
    _active = true;
    _poll ??= Timer.periodic(pollInterval, (_) => _query());
    _query();
  }

  /// Fuera de pantalla/segundo plano no se consulta ni se conservan plazos.
  void leave() {
    _active = false;
    _epoch++;
    _cancelTimers();
    if (ref.mounted) {
      Future.microtask(() {
        if (!_active && ref.mounted) {
          state = state.copyWith(
            connected: false,
            eyesFresh: false,
            signalFresh: false,
            pending: () => null,
          );
        }
      });
    }
  }

  void _cancelTimers() {
    _commandTimeout?.cancel();
    _commandListener?.cancel();
    _commandListener = null;
    final completion = _commandCompletion;
    _commandCompletion = null;
    if (completion != null && !completion.isCompleted) {
      completion.complete(false);
    }
    _silence?.cancel();
    _poll?.cancel();
    _poll = null;
    _queryTimeout?.cancel();
    _eyesExpiry?.cancel();
    _signalExpiry?.cancel();
    _listener?.cancel();
    _listener = null;
    _watched = null;
  }

  bool get unresolvedStart =>
      MonitoringQueryChannel.pendingCommand(_bridge, 'start') != null;

  void _notice(MonitoringSnapshot s) {
    if (!_active ||
        !ref.mounted ||
        _retiredEngines.contains(s.engineInstanceId)) {
      return;
    }
    final cur = _latest;
    if (cur != null &&
        cur.engineInstanceId == s.engineInstanceId &&
        s.sequence <= cur.sequence) {
      return;
    }
    // El aviso no tiene demora conocida: nunca publica una señal directamente.
    _query();
  }

  void _query() {
    if (!_active || !ref.mounted) return;
    final pending = MonitoringQueryChannel.pendingOn(_bridge);
    final ticket =
        pending ??
        MonitoringQueryChannel.start(_bridge, _epoch, clock.stopwatch());
    if (ticket == null || identical(ticket, _watched)) return;
    final own = pending == null;
    final epoch = _epoch;
    _watched = ticket;
    _listener?.cancel();
    _queryTimeout?.cancel();
    void expire() {
      if (!_active || !ref.mounted || !identical(ticket, _watched)) return;
      _eyesExpiry?.cancel();
      _signalExpiry?.cancel();
      state = state.copyWith(
        queryStalled: true,
        eyesFresh: false,
        signalFresh: false,
      );
    }

    final left = queryTimeout - ticket.watch.elapsed;
    if (left <= Duration.zero) {
      expire();
    } else {
      _queryTimeout = Timer(left, expire);
    }
    _listener = ticket.listen((outcome) {
      if (!identical(ticket, _watched)) return;
      _watched = null;
      _listener = null;
      _queryTimeout?.cancel();
      if (!_active || !ref.mounted || epoch != _epoch || !own) return;
      if (outcome.error != null ||
          outcome.finishedIn >= queryTimeout ||
          outcome.watch.elapsed >= queryTimeout) {
        state = state.copyWith(
          queryStalled: true,
          eyesFresh: false,
          signalFresh: false,
        );
        return;
      }
      _apply(outcome.answer!, outcome.watch.elapsed);
    });
  }

  void _apply(MonitoringSnapshot s, Duration transport) {
    if (!_active ||
        !ref.mounted ||
        _retiredEngines.contains(s.engineInstanceId)) {
      return;
    }
    final cur = _latest;
    if (cur != null &&
        cur.engineInstanceId == s.engineInstanceId &&
        s.sequence <= cur.sequence) {
      return;
    }
    if (cur != null && cur.engineInstanceId != s.engineInstanceId) {
      _retiredEngines.add(cur.engineInstanceId);
      _eyesRetired = -1;
      _signalRetired = -1;
      _observation = null;
      _validityWatch = null;
    }
    _latest = s;
    _silence?.cancel();
    _silence = Timer(connectionTimeout, () {
      if (ref.mounted) state = state.copyWith(connected: false);
    });
    _eyesExpiry?.cancel();
    _signalExpiry?.cancel();
    Duration? remaining(int? ms) =>
        ms == null || ms < 0 ? null : Duration(milliseconds: ms) - transport;
    var eyes = remaining(s.eyesValidForMs);
    var signal = remaining(s.signalValidForMs);
    final id = s.observationId;
    if (id != null && id == _observation && _validityWatch != null) {
      Duration? least(Duration? incoming, Duration? known) {
        if (incoming == null || known == null) return incoming;
        final left = known - _validityWatch!.elapsed;
        return left < incoming ? left : incoming;
      }

      eyes = least(eyes, _eyesLeft);
      signal = least(signal, _signalLeft);
    }
    _observation = id;
    _eyesLeft = eyes;
    _signalLeft = signal;
    _validityWatch = clock.stopwatch()..start();
    final eyesFresh =
        id != null &&
        id > _eyesRetired &&
        s.eyesValid &&
        eyes != null &&
        !eyes.isNegative;
    final signalFresh =
        eyesFresh &&
        s.lifecycle == EngineSessionLifecycle.active &&
        id > _signalRetired &&
        s.measurement == EngineMeasurement.usable &&
        s.signal != EngineSignal.notEvaluable &&
        signal != null &&
        !signal.isNegative;
    if (eyesFresh) {
      _eyesExpiry = Timer(eyes + const Duration(microseconds: 1), () {
        _eyesRetired = id > _eyesRetired ? id : _eyesRetired;
        if (_active && ref.mounted) state = state.copyWith(eyesFresh: false);
      });
    } else if (id != null && id > _eyesRetired) {
      _eyesRetired = id;
    }
    if (signalFresh) {
      _signalExpiry = Timer(signal + const Duration(microseconds: 1), () {
        _signalRetired = id > _signalRetired ? id : _signalRetired;
        if (_active && ref.mounted) state = state.copyWith(signalFresh: false);
      });
    } else if (id != null && id > _signalRetired) {
      _signalRetired = id;
    }
    if (!state.connected ||
        state.queryStalled ||
        state.eyesFresh != eyesFresh ||
        state.signalFresh != signalFresh ||
        !_sameDisplay(state.snapshot, s)) {
      state = state.copyWith(
        snapshot: s,
        connected: true,
        queryStalled: false,
        eyesFresh: eyesFresh,
        signalFresh: signalFresh,
        validityWatch: _validityWatch,
        eyesValidity: eyes,
        signalValidity: signal,
      );
    }
    _syncPattern();
  }

  /// Envía al motor el patrón guardado si su estado indica otro. Con
  /// [force] (guardado recién confirmado) se envía aunque no se conozca su
  /// estado: el motor decide y, con sesión vigente, lo rechaza.
  void _syncPattern({bool force = false}) {
    if (!ref.mounted) return;
    if (ref.read(realSettingsWriterProvider).pending ||
        ref.read(preferencesProvider).pending.isNotEmpty) {
      return;
    }
    final want = savedSoundPattern;
    final s = _latest;
    if (!force) {
      if (!_active || s == null || s.soundPatternId == want) return;
      if (s.lifecycle == EngineSessionLifecycle.active ||
          s.lifecycle == EngineSessionLifecycle.paused) {
        return; // La sesión conserva su patrón; se envía al terminar.
      }
      if (_patternRefused == (s.engineInstanceId, want)) return;
    }
    // Una sola llamada real a la vez: al terminar, su estado vuelve a pasar
    // por aquí y se envía el patrón guardado entonces, si sigue siendo otro.
    if (MonitoringQueryChannel.pendingCommand(_bridge, 'soundPattern') !=
        null) {
      return;
    }
    final epoch = _epoch;
    final ticket = MonitoringQueryChannel.startCommand(
      _bridge,
      'soundPattern',
      epoch,
      clock.stopwatch(),
      () => _bridge.setSoundPattern(want),
    );
    ticket?.listen((outcome) {
      final r = outcome.answer;
      if (!ref.mounted || !_active) return;
      if (r == null ||
          outcome.finishedIn >= queryTimeout ||
          outcome.watch.elapsed >= queryTimeout ||
          _retiredEngines.contains(r.snapshot.engineInstanceId)) {
        _query();
        return;
      }
      if (!r.accepted && r.errorCode == 'unknownSoundPattern') {
        _patternRefused = (r.snapshot.engineInstanceId, want);
      }
      _apply(r.snapshot, outcome.watch.elapsed);
    });
  }

  /// La prueba de sonido del motor vale para el patrón guardado: el motor
  /// informa ese patrón y la prueba se reprodujo (o además se confirmó).
  bool soundTestPlayedFor(MonitoringSnapshot? s) =>
      !ref.read(realSettingsWriterProvider).pending &&
      !ref
          .read(preferencesProvider)
          .pending
          .contains(PreferenceField.soundPattern) &&
      s != null &&
      s.soundPatternId == savedSoundPattern &&
      s.soundTestPlayed;

  bool soundConfirmedFor(MonitoringSnapshot? s) =>
      soundTestPlayedFor(s) && s!.soundHeard;

  bool _sameDisplay(MonitoringSnapshot? a, MonitoringSnapshot b) {
    if (a == null) return false;
    List<Object?> displayed(MonitoringSnapshot s) {
      final copy = MonitoringSnapshot.decode(s.encode())
        ..sequence = 0
        ..observationAgeMs = null
        ..eyesValidForMs = null
        ..signalValidForMs = null
        ..activeMs = s.activeMs ~/ 1000
        ..pausedMs = s.pausedMs ~/ 1000
        ..evaluableMs = s.evaluableMs ~/ 1000
        ..stepElapsedMs = (s.stepElapsedMs ?? 0) ~/ 1000;
      return copy.encode() as List<Object?>;
    }

    return listEquals(displayed(a), displayed(b));
  }

  Future<bool> _command(
    String name,
    Future<MonitoringCommandResult> Function() run,
  ) {
    if (!ref.mounted || !_active || state.pending != null) {
      return Future.value(false);
    }
    if (MonitoringQueryChannel.pendingCommand(_bridge, name) != null) {
      state = state.copyWith(bridgeError: true);
      return Future.value(false);
    }
    final epoch = _epoch;
    state = state.copyWith(
      pending: () => name,
      rejection: () => null,
      bridgeError: false,
    );
    final completion = Completer<bool>();
    _commandCompletion = completion;
    final ticket = MonitoringQueryChannel.startCommand(
      _bridge,
      name,
      epoch,
      clock.stopwatch(),
      run,
    )!;
    void finish(bool accepted, {String? rejection, bool error = false}) {
      _commandTimeout?.cancel();
      _commandListener?.cancel();
      _commandListener = null;
      _commandCompletion = null;
      if (ref.mounted && _active && epoch == _epoch) {
        state = state.copyWith(
          pending: () => null,
          rejection: () => rejection,
          bridgeError: error,
        );
      }
      if (!completion.isCompleted) completion.complete(accepted);
    }

    _commandTimeout = Timer(queryTimeout, () {
      finish(false, error: true);
      _query();
    });
    _commandListener = ticket.listen((outcome) {
      if (!ref.mounted || !_active || epoch != _epoch) {
        finish(false);
        return;
      }
      final r = outcome.answer;
      if (outcome.error != null ||
          outcome.finishedIn >= queryTimeout ||
          outcome.watch.elapsed >= queryTimeout ||
          r == null ||
          _retiredEngines.contains(r.snapshot.engineInstanceId)) {
        finish(false, error: true);
        _query();
        return;
      }
      _apply(r.snapshot, outcome.watch.elapsed);
      finish(r.accepted, rejection: r.accepted ? null : r.errorCode);
    });
    return completion.future;
  }

  Future<bool> beginCalibration() =>
      _command('calibrate', _bridge.beginCalibration);

  Future<bool> cancelCalibration() =>
      _command('cancelCalibration', _bridge.cancelCalibration);

  /// Prueba el tono con el patrón guardado (fase 5E).
  Future<bool> testSound() {
    if (ref.read(realSettingsWriterProvider).pending ||
        ref
            .read(preferencesProvider)
            .pending
            .contains(PreferenceField.soundPattern)) {
      return Future.value(false);
    }
    final pattern = savedSoundPattern;
    return _command('testSound', () => _bridge.testSound(pattern));
  }

  /// «Lo escuché»: solo para una prueba del patrón guardado. La de otro
  /// patrón (respuesta tardía o cambio en Ajustes) no se confirma.
  Future<bool> confirmSoundHeard() {
    final s = state.snapshot;
    final id = s?.soundTestId;
    if (id == null || !soundTestPlayedFor(s)) return Future.value(false);
    return _command('confirmSound', () => _bridge.confirmSoundHeard(id));
  }

  Future<bool> start() {
    final s = state.snapshot;
    final cal = s?.calibrationId;
    final sound = s?.soundTestId;
    if (cal == null || sound == null || !soundConfirmedFor(s)) {
      return Future.value(false);
    }
    final account = ref.read(monitoringAccountIdProvider);
    if (account == null && ref.read(monitoringAccountRequiredProvider)) {
      state = state.copyWith(rejection: () => 'accountRequired');
      return Future.value(false);
    }
    if (account != null) {
      final bridge = _bridge;
      if (bridge is! AccountMonitoringBridge) return Future.value(false);
      return _command(
        'start',
        () => (bridge as AccountMonitoringBridge).startAccountSession(
          cal,
          sound,
          account,
        ),
      );
    }
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
