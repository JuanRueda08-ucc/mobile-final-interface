import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/alert_sound.dart';
import '../../core/clock/monotonic_clock.dart';
import '../../data/demo_history/demo_history_repository.dart';
import '../../data/demo_history/history_providers.dart';
import '../preparation/preparation_controller.dart';
import '../settings/preferences_controller.dart';
import 'domain/demo_script.dart';
import 'domain/session_model.dart';
import 'domain/session_summary.dart';

/// Episodio abierto (advertencia o cierre ocular prolongado).
final class OpenEpisode {
  const OpenEpisode(this.id, this.kind);

  final String id;
  final EpisodeKind kind;
}

/// Proyección de la sesión demostrativa que ve la interfaz.
final class DemoSessionState {
  const DemoSessionState({
    this.lifecycle = SessionLifecycle.none,
    this.sessionId,
    this.pending,
    this.startedAt,
    this.startedWall,
    this.calibrationId,
    this.measurement = Measurement.initializing,
    this.signal = SignalState.notEvaluable,
    this.cause,
    this.openEpisode,
    this.events = const [],
    this.pausedBefore = Duration.zero,
    this.pauseStartedAt,
    this.stopRequestedAt,
    this.recoverUntil,
    this.soundFailure,
  });

  final SessionLifecycle lifecycle;

  /// Identidad estable desde el inicio confirmado hasta el cierre (RF08,
  /// RF17.CA1). Nula mientras se inicia.
  final String? sessionId;
  final PendingOperation? pending;

  /// Instante monotónico del inicio confirmado.
  final Duration? startedAt;
  final DateTime? startedWall;
  final String? calibrationId;
  final Measurement measurement;
  final SignalState signal;
  final String? cause;
  final OpenEpisode? openEpisode;
  final List<SessionEvent> events;

  /// Tiempo en pausas ya cerradas.
  final Duration pausedBefore;

  /// Inicio monotónico de la pausa abierta, si la hay.
  final Duration? pauseStartedAt;

  /// Instante monotónico de la solicitud de cierre: aquí termina el tiempo
  /// representado.
  final Duration? stopRequestedAt;

  /// Tiempo activo hasta el que la medición se reinicia tras reanudar.
  final Duration? recoverUntil;

  /// Último fallo técnico del sonido (visible hasta una reproducción correcta).
  final String? soundFailure;

  /// Sesión vigente: activa, pausada o en transición, hasta confirmar cierre
  /// (UX §4.2).
  bool get isVigente =>
      lifecycle == SessionLifecycle.starting ||
      lifecycle == SessionLifecycle.active ||
      lifecycle == SessionLifecycle.paused ||
      lifecycle == SessionLifecycle.stopping;

  /// Tiempo de monitoreo en [now] (monotónico): desde el inicio confirmado,
  /// sin las pausas y sin lo posterior a la solicitud de cierre.
  Duration monitoredAt(Duration now) {
    final start = startedAt;
    if (start == null) return Duration.zero;
    final end = stopRequestedAt ?? now;
    var t = end - start - pausedBefore;
    final pauseStart = pauseStartedAt;
    if (pauseStart != null) t -= end - pauseStart;
    return t.isNegative ? Duration.zero : t;
  }

  DemoSessionState copyWith({
    SessionLifecycle? lifecycle,
    String? sessionId,
    PendingOperation? pending,
    bool clearPending = false,
    Duration? startedAt,
    DateTime? startedWall,
    String? calibrationId,
    Measurement? measurement,
    SignalState? signal,
    String? cause,
    bool clearCause = false,
    OpenEpisode? openEpisode,
    bool clearEpisode = false,
    List<SessionEvent>? events,
    Duration? pausedBefore,
    Duration? pauseStartedAt,
    bool clearPause = false,
    Duration? stopRequestedAt,
    Duration? recoverUntil,
    String? soundFailure,
    bool clearSoundFailure = false,
  }) => DemoSessionState(
    lifecycle: lifecycle ?? this.lifecycle,
    sessionId: sessionId ?? this.sessionId,
    pending: clearPending ? null : pending ?? this.pending,
    startedAt: startedAt ?? this.startedAt,
    startedWall: startedWall ?? this.startedWall,
    calibrationId: calibrationId ?? this.calibrationId,
    measurement: measurement ?? this.measurement,
    signal: signal ?? this.signal,
    cause: clearCause ? null : cause ?? this.cause,
    openEpisode: clearEpisode ? null : openEpisode ?? this.openEpisode,
    events: events ?? this.events,
    pausedBefore: pausedBefore ?? this.pausedBefore,
    pauseStartedAt: clearPause ? null : pauseStartedAt ?? this.pauseStartedAt,
    stopRequestedAt: stopRequestedAt ?? this.stopRequestedAt,
    recoverUntil: recoverUntil ?? this.recoverUntil,
    soundFailure: clearSoundFailure ? null : soundFailure ?? this.soundFailure,
  );
}

/// Retraso con que el «motor» demostrativo confirma cada orden. Permite ver
/// Iniciando, Pausando, Reanudando y Finalizando antes de la confirmación.
final demoConfirmDelayProvider = Provider<Duration>(
  (ref) => const Duration(milliseconds: 700),
);

/// Controlador de la sesión **demostrativa**.
///
/// Separado del plugin nativo `monitoring_engine`: no abre cámara, no ejecuta
/// IA y no habla con Kotlin, salvo el tono local de las alertas. Hace de motor
/// simulado con una sola sesión vigente:
/// - las órdenes repetidas durante una transición no crean otra (RF08.CA1,
///   RF16.CA3);
/// - la identidad no cambia con pausa y reanudación (RF17.CA1);
/// - el tiempo se calcula desde anclas monotónicas, sin acumular pausas;
/// - los eventos salen del guion reproducible [DemoScript] solo mientras la
///   sesión está activa (RF16.CA2); al pausar o pedir el cierre se cancelan;
/// - el cierre se confirma una sola vez (RF18.CA3).
///
/// Fase 3: cada hecho se guarda en el historial DEMO ([DemoHistoryRepository])
/// en el orden en que ocurre, y el cierre confirmado guarda fin y totales una
/// sola vez. La sesión no se reanuda al reabrir la app: lo que quedó sin
/// cierre se marca interrumpido al abrir el historial (RF19).
class DemoSessionController extends Notifier<DemoSessionState> {
  Timer? _scriptTimer;
  Timer? _confirmTimer;

  /// Cambia con cada sesión y con cada orden: invalida callbacks tardíos.
  var _generation = 0;
  var _episodes = 0;
  var _sequence = 0;

  /// Cambia al confirmar una pausa y al pedir el cierre: la respuesta de un
  /// tono anterior ya no registra eventos, aunque la sesión se reanude antes
  /// de que llegue.
  var _alertEpoch = 0;

  /// Tiempo activo hasta el que ya se aplicó el guion.
  var _scriptCursor = Duration.zero;

  // Guardado en el historial.
  int? _sessionNumber;
  String? _savedId;
  var _savedCount = 0;
  SessionLifecycle? _savedLifecycle;
  SessionSummary? _closingSummary;

  MonotonicClock get _clock => ref.read(monotonicClockProvider);

  /// Patrón guardado en Ajustes. No cambia durante la sesión: Sonido está
  /// bloqueado mientras haya una sesión vigente (UX §4.2).
  String get _patternId => ref.read(preferencesProvider).value.soundPatternId;

  @override
  DemoSessionState build() {
    ref.onDispose(_cancelTimers);
    listenSelf((_, next) => _save(next));
    return const DemoSessionState();
  }

  // ── Órdenes ──────────────────────────────────────────────────────────

  /// «Iniciar monitoreo». Vuelve a comprobar las seis condiciones (RF05.CA3)
  /// y no crea nada si fallan. Devuelve `false` si la orden no se aceptó.
  bool requestStart() {
    if (state.isVigente) return false; // una sola sesión vigente
    // Con un registro que no se pudo guardar no se empieza otra sesión
    // (Área 06 §3: no reemplazar evidencia pendiente).
    if (ref.read(historySyncProvider).failure != null) return false;
    final prep = ref.read(preparationProvider);
    if (!prep.ready) return false;
    final calibrationId = prep.reference!.id;
    ref.read(preparationProvider.notifier).consume();
    _episodes = 0;
    _sequence = 0;
    final gen = ++_generation;
    state = DemoSessionState(
      lifecycle: SessionLifecycle.starting,
      pending: PendingOperation.start,
      calibrationId: calibrationId,
    );
    _confirmLater(gen, _confirmStart);
    return true;
  }

  /// «Pausar»: solo desde Activa y sin otra orden pendiente.
  void requestPause() {
    if (state.lifecycle != SessionLifecycle.active || state.pending != null) {
      return;
    }
    state = state.copyWith(pending: PendingOperation.pause);
    _confirmLater(_generation, _confirmPause);
  }

  /// «Reanudar»: solo desde Pausada y sin otra orden pendiente.
  void requestResume() {
    if (state.lifecycle != SessionLifecycle.paused || state.pending != null) {
      return;
    }
    state = state.copyWith(pending: PendingOperation.resume);
    _confirmLater(_generation, _confirmResume);
  }

  /// «Finalizar» confirmado en D02. Detiene la generación de eventos y los
  /// sonidos en el acto; el resumen llega con la confirmación.
  void requestFinish() {
    final l = state.lifecycle;
    if ((l != SessionLifecycle.active && l != SessionLifecycle.paused) ||
        state.pending != null) {
      return;
    }
    final now = _clock.elapsed;
    if (l == SessionLifecycle.active) _advanceScript(now);
    _scriptTimer?.cancel();
    _alertEpoch++;
    var s = state;
    final events = [...s.events];
    final episode = s.openEpisode;
    if (episode != null) {
      events.add(
        _event(SessionEventType.episodeEnded, s, now, episode: episode),
      );
    }
    events.add(_event(SessionEventType.stopRequested, s, now));
    state = s.copyWith(
      lifecycle: SessionLifecycle.stopping,
      pending: PendingOperation.finish,
      stopRequestedAt: now,
      clearEpisode: true,
      events: events,
    );
    _confirmLater(_generation, _confirmFinish);
  }

  // ── Confirmaciones del motor simulado ─────────────────────────────────

  void _confirmLater(int gen, void Function() confirm) {
    _confirmTimer?.cancel();
    _confirmTimer = Timer(ref.read(demoConfirmDelayProvider), () {
      if (gen == _generation && ref.mounted) confirm();
    });
  }

  void _confirmStart() {
    final now = _clock.elapsed;
    // El número viene del historial: no se repite entre ejecuciones.
    final number = _sessionNumber = ref
        .read(demoHistoryRepositoryProvider)
        .reserveSessionNumber();
    final id = 'S-DEMO-${number.toString().padLeft(4, '0')}';
    var s = state.copyWith(
      lifecycle: SessionLifecycle.active,
      clearPending: true,
      sessionId: id,
      startedAt: now,
      startedWall: _clock.wallNow(),
      measurement: Measurement.initializing,
      signal: SignalState.notEvaluable,
    );
    s = s.copyWith(
      events: [
        _event(SessionEventType.started, s, now),
        _event(
          SessionEventType.measurementChanged,
          s,
          now,
          measurement: Measurement.initializing,
        ),
        _event(
          SessionEventType.signalChanged,
          s,
          now,
          signal: SignalState.notEvaluable,
        ),
      ],
    );
    state = s;
    _scriptCursor = Duration.zero;
    _scheduleScript();
  }

  void _confirmPause() {
    final now = _clock.elapsed;
    _advanceScript(now);
    _scriptTimer?.cancel();
    _alertEpoch++;
    final s = state;
    final events = [...s.events];
    final episode = s.openEpisode;
    if (episode != null) {
      // La pausa descarta las ventanas: el episodio abierto termina aquí.
      events.add(
        _event(SessionEventType.episodeEnded, s, now, episode: episode),
      );
    }
    events.add(_event(SessionEventType.pauseStarted, s, now));
    state = s.copyWith(
      lifecycle: SessionLifecycle.paused,
      clearPending: true,
      pauseStartedAt: now,
      clearEpisode: true,
      events: events,
    );
  }

  void _confirmResume() {
    final now = _clock.elapsed;
    final s = state;
    final pausedBefore = s.pausedBefore + (now - s.pauseStartedAt!);
    var next = s.copyWith(
      lifecycle: SessionLifecycle.active,
      clearPending: true,
      pausedBefore: pausedBefore,
      clearPause: true,
    );
    final active = next.monitoredAt(now);
    next = next.copyWith(
      recoverUntil: active + DemoScript.recoveryAfterResume,
      events: [...s.events, _event(SessionEventType.pauseEnded, s, now)],
    );
    state = next;
    _scriptCursor = active;
    // La medición se reconstruye: no se reutiliza la ventana anterior.
    _applyPoint(DemoScript.at(active, recoverUntil: next.recoverUntil), now);
    _scheduleScript();
  }

  void _confirmFinish() {
    final now = _clock.elapsed;
    final s = state;
    final events = [...s.events, _event(SessionEventType.finished, s, now)];
    final finished = s.copyWith(
      lifecycle: SessionLifecycle.finalized,
      clearPending: true,
      events: events,
    );
    _closingSummary = SessionSummary.fromEvents(
      sessionId: s.sessionId!,
      startedAt: s.startedWall!,
      finishedAt: _clock.wallNow(),
      events: events,
    );
    _generation++; // nada de esta sesión vuelve a cambiar el estado
    _cancelTimers();
    state = finished;
  }

  // ── Guion ────────────────────────────────────────────────────────────

  void _scheduleScript() {
    _scriptTimer?.cancel();
    if (state.lifecycle != SessionLifecycle.active) return;
    final now = _clock.elapsed;
    final active = state.monitoredAt(now);
    final next = DemoScript.next(active, recoverUntil: state.recoverUntil);
    final gen = _generation;
    _scriptTimer = Timer(next - active, () {
      if (gen != _generation || !ref.mounted) return;
      if (state.lifecycle != SessionLifecycle.active) return;
      _advanceScript(_clock.elapsed);
      _scheduleScript();
    });
  }

  /// Aplica los cambios del guion hasta [now], cada uno en su instante exacto.
  void _advanceScript(Duration now) {
    if (state.lifecycle != SessionLifecycle.active) return;
    final target = state.monitoredAt(now);
    while (true) {
      final next = DemoScript.next(
        _scriptCursor,
        recoverUntil: state.recoverUntil,
      );
      if (next > target) break;
      _scriptCursor = next;
      _applyPoint(
        DemoScript.at(next, recoverUntil: state.recoverUntil),
        _monotonicForActive(next),
      );
    }
  }

  /// Instante monotónico de un tiempo activo dentro del tramo activo actual.
  Duration _monotonicForActive(Duration active) =>
      state.startedAt! + active + state.pausedBefore;

  void _applyPoint(ScriptPoint p, Duration at) {
    final s = state;
    final events = [...s.events];
    if (p.measurement != s.measurement) {
      events.add(
        _event(
          SessionEventType.measurementChanged,
          s,
          at,
          measurement: p.measurement,
        ),
      );
    }
    var episode = s.openEpisode;
    var clearEpisode = false;
    AlertSoundKind? sound;
    if (p.signal != s.signal) {
      events.add(
        _event(SessionEventType.signalChanged, s, at, signal: p.signal),
      );
      if (episode != null) {
        events.add(
          _event(SessionEventType.episodeEnded, s, at, episode: episode),
        );
        episode = null;
        clearEpisode = true;
      }
      if (p.signal.isAlert) {
        final kind = p.signal == SignalState.warning
            ? EpisodeKind.warning
            : EpisodeKind.prolongedEyeClosure;
        episode = OpenEpisode(
          '${s.sessionId}-E${(++_episodes).toString().padLeft(2, '0')}',
          kind,
        );
        clearEpisode = false;
        events.add(
          _event(SessionEventType.episodeStarted, s, at, episode: episode),
        );
        sound = kind == EpisodeKind.warning
            ? AlertSoundKind.warning
            : AlertSoundKind.closure;
      }
    }
    state = s.copyWith(
      measurement: p.measurement,
      signal: p.signal,
      cause: p.cause,
      clearCause: p.cause == null,
      openEpisode: episode,
      clearEpisode: clearEpisode,
      events: events,
    );
    if (sound != null) _playAlert(sound);
  }

  /// Alerta sonora local. Su fallo es visible y no crea episodios ni cambia
  /// la medición (UX §7, ER08). Una respuesta que llega después de una pausa
  /// confirmada o de pedir el cierre se descarta.
  Future<void> _playAlert(AlertSoundKind kind) async {
    final gen = _generation;
    final epoch = _alertEpoch;
    final r = await ref
        .read(alertSoundPlayerProvider)
        .play(kind, patternId: _patternId);
    if (gen != _generation || epoch != _alertEpoch || !ref.mounted) return;
    if (state.lifecycle != SessionLifecycle.active) return;
    final now = _clock.elapsed;
    final s = state;
    state = s.copyWith(
      soundFailure: r.failure,
      clearSoundFailure: r.played,
      events: [
        ...s.events,
        _event(
          r.played
              ? SessionEventType.soundPlayed
              : SessionEventType.soundFailed,
          s,
          now,
          detail: r.failure ?? kind.name,
        ),
      ],
    );
  }

  // ── Historial ────────────────────────────────────────────────────────

  /// Lleva al historial lo nuevo de [s]: el inicio confirmado, los hechos
  /// añadidos, el cambio de ciclo y, una sola vez, el cierre confirmado.
  void _save(DemoSessionState s) {
    final id = s.sessionId;
    if (id == null) return;
    final sync = ref.read(historySyncProvider.notifier);
    if (id != _savedId) {
      // Sesión nueva: sus hechos empiezan en cero.
      _savedId = id;
      _savedCount = s.events.length;
      _savedLifecycle = s.lifecycle;
      final start = SessionStartRecord(
        sessionId: id,
        sessionNumber: _sessionNumber!,
        startedAt: s.startedWall!,
        calibrationId: s.calibrationId!,
      );
      final events = s.events;
      sync.run((r) => r.recordStart(start, events));
      return;
    }
    final fresh = s.events.sublist(_savedCount);
    if (_savedLifecycle == SessionLifecycle.finalized) return;
    if (s.lifecycle == SessionLifecycle.finalized) {
      _savedCount = s.events.length;
      _savedLifecycle = s.lifecycle;
      final summary = _closingSummary!;
      final end = s.stopRequestedAt! - s.startedAt!;
      sync.run((r) => r.finalize(id, fresh, summary, end));
      return;
    }
    if (fresh.isEmpty && s.lifecycle == _savedLifecycle) return;
    _savedCount = s.events.length;
    _savedLifecycle = s.lifecycle;
    final lifecycle = switch (s.lifecycle) {
      SessionLifecycle.paused => StoredLifecycle.paused,
      SessionLifecycle.stopping => StoredLifecycle.stopping,
      _ => StoredLifecycle.active,
    };
    sync.run((r) => r.appendEvents(id, fresh, lifecycle));
  }

  SessionEvent _event(
    SessionEventType type,
    DemoSessionState s,
    Duration at, {
    Measurement? measurement,
    SignalState? signal,
    OpenEpisode? episode,
    String? detail,
  }) => SessionEvent(
    sequence: ++_sequence,
    type: type,
    offset: at - (s.startedAt ?? at),
    measurement: measurement,
    signal: signal,
    episodeId: episode?.id,
    episodeKind: episode?.kind,
    detail: detail,
  );

  void _cancelTimers() {
    _scriptTimer?.cancel();
    _confirmTimer?.cancel();
  }
}

final demoSessionProvider =
    NotifierProvider<DemoSessionController, DemoSessionState>(
      DemoSessionController.new,
    );
