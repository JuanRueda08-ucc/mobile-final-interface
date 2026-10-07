import 'package:drift/drift.dart';

import '../../features/monitoring/domain/session_model.dart';
import '../../features/monitoring/domain/session_summary.dart';
import 'demo_history_database.dart';

/// Ciclo guardado de una sesión (Área 06 §6). `interrupted`: el proceso
/// terminó sin cierre confirmado (RF19).
enum StoredLifecycle { active, paused, stopping, finalized, interrupted }

/// Fecha civil guardada: epoch UTC en ms y offset de la zona en ese instante
/// (Área 06 §4). Se presenta con su propio offset, no con el de hoy.
final class CivilTime {
  const CivilTime(this.epochMs, this.offsetMinutes);

  factory CivilTime.of(DateTime t) =>
      CivilTime(t.millisecondsSinceEpoch, t.timeZoneOffset.inMinutes);

  final int epochMs;
  final int offsetMinutes;

  /// Campos civiles (año…minuto) en la zona guardada.
  DateTime get fields => DateTime.fromMillisecondsSinceEpoch(
    epochMs,
    isUtc: true,
  ).add(Duration(minutes: offsetMinutes));

  /// La hora civil a [offset] del inicio, con el offset del inicio.
  CivilTime plus(Duration offset) =>
      CivilTime(epochMs + offset.inMilliseconds, offsetMinutes);
}

/// Sesión guardada en el historial DEMO.
final class StoredSession {
  const StoredSession({
    required this.sessionId,
    required this.isDemo,
    required this.startedAt,
    required this.lifecycle,
    required this.endedAt,
    required this.endOffset,
    required this.latestDurableOffset,
    required this.calibrationId,
    required this.complete,
    required this.summary,
  });

  final String sessionId;

  /// Origen DEMO leído de la base (`origin = 'demo'`), no supuesto.
  final bool isDemo;
  final CivilTime startedAt;
  final StoredLifecycle lifecycle;

  /// Fin civil confirmado; nulo si no hubo cierre confirmado.
  final CivilTime? endedAt;
  final Duration? endOffset;

  /// Último hecho guardado, desde el inicio confirmado.
  final Duration latestDurableOffset;
  final String calibrationId;

  /// Integridad `complete` (Área 06 §11).
  final bool complete;

  /// Totales guardados al confirmar el cierre; nulo si no se confirmó.
  final SessionSummary? summary;

  bool get isInterrupted => lifecycle == StoredLifecycle.interrupted;
  bool get isFinalized => lifecycle == StoredLifecycle.finalized;

  /// Hora civil del último registro confirmado.
  CivilTime get latestDurableAt => startedAt.plus(latestDurableOffset);
}

/// Filtro de estado del Historial (P08).
enum HistoryFilter { all, finalized, interrupted }

/// Datos de una sesión al confirmar su inicio.
final class SessionStartRecord {
  const SessionStartRecord({
    required this.sessionId,
    required this.sessionNumber,
    required this.startedAt,
    required this.calibrationId,
  });

  final String sessionId;
  final int sessionNumber;
  final DateTime startedAt;
  final String calibrationId;
}

/// Preferencias guardadas (Área 06 §6).
enum ThemePreference { system, light, dark }

final class StoredPreferences {
  const StoredPreferences({
    this.theme = ThemePreference.system,
    this.soundPatternId = defaultSoundPatternId,
    this.reducedMotion = false,
  });

  /// Patrón inicial del catálogo local (Área 06 §9).
  static const defaultSoundPatternId = 'patron_1';

  final ThemePreference theme;
  final String soundPatternId;
  final bool reducedMotion;

  StoredPreferences copyWith({
    ThemePreference? theme,
    String? soundPatternId,
    bool? reducedMotion,
  }) => StoredPreferences(
    theme: theme ?? this.theme,
    soundPatternId: soundPatternId ?? this.soundPatternId,
    reducedMotion: reducedMotion ?? this.reducedMotion,
  );

  @override
  bool operator ==(Object other) =>
      other is StoredPreferences &&
      other.theme == theme &&
      other.soundPatternId == soundPatternId &&
      other.reducedMotion == reducedMotion;

  @override
  int get hashCode => Object.hash(theme, soundPatternId, reducedMotion);
}

/// Historial DEMO: lo usan el controlador de sesión (escritura) y las
/// pantallas P03, P07, P08, P09 y P12 (lectura). Los widgets no ven Drift.
abstract interface class DemoHistoryRepository {
  /// Siguiente número de `S-DEMO-NNNN`, sin reutilizar los ya guardados.
  int reserveSessionNumber();

  /// Siguiente número de `C-DEMO-NNNN` para una referencia de calibración.
  int reserveCalibrationNumber();

  /// Inicio confirmado: crea la sesión `active` con sus primeros hechos.
  Future<void> recordStart(SessionStartRecord start, List<SessionEvent> events);

  /// Añade hechos nuevos y actualiza el ciclo y el último desplazamiento
  /// durable. Un hecho ya guardado (mismo ID de sesión y secuencia) no se
  /// duplica.
  Future<void> appendEvents(
    String sessionId,
    List<SessionEvent> events,
    StoredLifecycle lifecycle,
  );

  /// Cierre confirmado: guarda fin y totales **una sola vez**. Devuelve
  /// `false` (sin escribir) si la sesión ya estaba finalizada.
  Future<bool> finalize(
    String sessionId,
    List<SessionEvent> lastEvents,
    SessionSummary summary,
    Duration endOffset,
  );

  /// Al abrir la app: las sesiones que quedaron activas, pausadas o cerrando
  /// pasan a `interrupted`, sin fin ni totales (RF19.CA2). Devuelve cuántas.
  Future<int> markInterrupted();

  /// Sesiones en orden de inicio descendente, desempate por ID (Área 06 §4).
  Future<List<StoredSession>> sessions({HistoryFilter filter});
  Future<StoredSession?> session(String sessionId);
  Future<StoredSession?> latestSession();
  Future<List<SessionEvent>> events(String sessionId);

  Future<StoredPreferences> loadPreferences();
  Future<void> savePreferences(StoredPreferences preferences);
}

/// Implementación con Drift/SQLite.
class DriftDemoHistoryRepository implements DemoHistoryRepository {
  DriftDemoHistoryRepository._(this._db);

  /// Abre el repositorio: lee los contadores y aplica la recuperación de
  /// sesiones interrumpidas antes de que la app pueda iniciar otra.
  static Future<DriftDemoHistoryRepository> open(DemoHistoryDatabase db) async {
    final repo = DriftDemoHistoryRepository._(db);
    await repo.markInterrupted();
    final maxSession = await db
        .customSelect('SELECT MAX(session_number) AS n FROM demo_sessions')
        .getSingle();
    repo._nextSession = (maxSession.read<int?>('n') ?? 0) + 1;
    final calibrations = await db
        .customSelect('SELECT calibration_id FROM demo_sessions')
        .get();
    var maxCal = 0;
    for (final r in calibrations) {
      final n = int.tryParse(
        r.read<String>('calibration_id').replaceFirst('C-DEMO-', ''),
      );
      if (n != null && n > maxCal) maxCal = n;
    }
    repo._nextCalibration = maxCal + 1;
    return repo;
  }

  final DemoHistoryDatabase _db;
  var _nextSession = 1;
  var _nextCalibration = 1;

  @override
  int reserveSessionNumber() => _nextSession++;

  @override
  int reserveCalibrationNumber() => _nextCalibration++;

  @override
  Future<void> recordStart(
    SessionStartRecord start,
    List<SessionEvent> events,
  ) => _db.transaction(() async {
    final t = CivilTime.of(start.startedAt);
    await _db
        .into(_db.demoSessions)
        .insert(
          DemoSessionsCompanion.insert(
            sessionId: start.sessionId,
            sessionNumber: start.sessionNumber,
            startedEpochMs: t.epochMs,
            startOffsetMinutes: t.offsetMinutes,
            lifecycle: StoredLifecycle.active.name,
            latestDurableOffsetMs: _latest(events, 0),
            calibrationId: start.calibrationId,
            integrityStatus: 'incomplete',
          ),
        );
    await _insertEvents(start.sessionId, events);
  });

  @override
  Future<void> appendEvents(
    String sessionId,
    List<SessionEvent> events,
    StoredLifecycle lifecycle,
  ) => _db.transaction(() async {
    final row = await _row(sessionId);
    if (row == null) throw StateError('Sesión $sessionId no guardada');
    final current = StoredLifecycle.values.byName(row.lifecycle);
    // Un ciclo terminal no vuelve atrás (Área 06 §6).
    if (current == StoredLifecycle.finalized ||
        current == StoredLifecycle.interrupted) {
      return;
    }
    await _insertEvents(sessionId, events);
    await (_db.update(
      _db.demoSessions,
    )..where((s) => s.sessionId.equals(sessionId))).write(
      DemoSessionsCompanion(
        lifecycle: Value(lifecycle.name),
        // El último límite durable no retrocede.
        latestDurableOffsetMs: Value(
          _latest(events, row.latestDurableOffsetMs),
        ),
      ),
    );
  });

  @override
  Future<bool> finalize(
    String sessionId,
    List<SessionEvent> lastEvents,
    SessionSummary summary,
    Duration endOffset,
  ) => _db.transaction(() async {
    final row = await _row(sessionId);
    if (row == null) throw StateError('Sesión $sessionId no guardada');
    if (row.lifecycle == StoredLifecycle.finalized.name) return false;
    if (row.lifecycle == StoredLifecycle.interrupted.name) {
      throw StateError('Sesión $sessionId interrumpida: no se finaliza');
    }
    await _insertEvents(sessionId, lastEvents);
    final end = CivilTime.of(summary.finishedAt);
    final n =
        await (_db.update(_db.demoSessions)..where(
              (s) =>
                  s.sessionId.equals(sessionId) &
                  s.lifecycle.equals(StoredLifecycle.finalized.name).not(),
            ))
            .write(
              DemoSessionsCompanion(
                lifecycle: Value(StoredLifecycle.finalized.name),
                endedEpochMs: Value(end.epochMs),
                endOffsetMinutes: Value(end.offsetMinutes),
                endOffsetMs: Value(endOffset.inMilliseconds),
                // Con cierre confirmado, el último límite durable es el fin del
                // tiempo representado (la solicitud de cierre); la confirmación
                // posterior no lo extiende.
                latestDurableOffsetMs: Value(endOffset.inMilliseconds),
                integrityStatus: const Value('complete'),
                evaluableMs: Value(summary.evaluable.inMilliseconds),
                nonEvaluableMs: Value(summary.notEvaluable.inMilliseconds),
                pausedMs: Value(summary.paused.inMilliseconds),
                unknownMs: Value(summary.unknown.inMilliseconds),
                monitoredMs: Value(summary.monitored.inMilliseconds),
                episodeCount: Value(summary.episodes),
                warningCount: Value(summary.warnings),
                closureCount: Value(summary.closures),
                soundsPlayed: Value(summary.soundsPlayed),
                soundsFailed: Value(summary.soundsFailed),
                pauseCount: Value(summary.pauses),
              ),
            );
    return n == 1;
  });

  @override
  Future<int> markInterrupted() =>
      (_db.update(_db.demoSessions)..where(
            (s) => s.lifecycle.isIn([
              StoredLifecycle.active.name,
              StoredLifecycle.paused.name,
              StoredLifecycle.stopping.name,
            ]),
          ))
          .write(
            DemoSessionsCompanion(
              lifecycle: Value(StoredLifecycle.interrupted.name),
              integrityStatus: const Value('incomplete'),
            ),
          );

  @override
  Future<List<StoredSession>> sessions({
    HistoryFilter filter = HistoryFilter.all,
  }) async {
    final q = _db.select(_db.demoSessions)
      ..orderBy([
        (s) => OrderingTerm.desc(s.startedEpochMs),
        (s) => OrderingTerm.desc(s.sessionId),
      ]);
    switch (filter) {
      case HistoryFilter.all:
        break;
      case HistoryFilter.finalized:
        q.where((s) => s.lifecycle.equals(StoredLifecycle.finalized.name));
      case HistoryFilter.interrupted:
        q.where((s) => s.lifecycle.equals(StoredLifecycle.interrupted.name));
    }
    return [for (final r in await q.get()) _stored(r)];
  }

  @override
  Future<StoredSession?> session(String sessionId) async {
    final r = await _row(sessionId);
    return r == null ? null : _stored(r);
  }

  @override
  Future<StoredSession?> latestSession() async {
    final r =
        await (_db.select(_db.demoSessions)
              ..orderBy([
                (s) => OrderingTerm.desc(s.startedEpochMs),
                (s) => OrderingTerm.desc(s.sessionId),
              ])
              ..limit(1))
            .getSingleOrNull();
    return r == null ? null : _stored(r);
  }

  @override
  Future<List<SessionEvent>> events(String sessionId) async {
    final rows =
        await (_db.select(_db.demoSessionEvents)
              ..where((e) => e.sessionId.equals(sessionId))
              ..orderBy([(e) => OrderingTerm.asc(e.sequence)]))
            .get();
    return [
      for (final r in rows)
        SessionEvent(
          sequence: r.sequence,
          type: SessionEventType.values.byName(r.type),
          offset: Duration(milliseconds: r.offsetMs),
          measurement: r.measurement == null
              ? null
              : Measurement.values.byName(r.measurement!),
          signal: r.signal == null
              ? null
              : SignalState.values.byName(r.signal!),
          episodeId: r.episodeId,
          episodeKind: r.episodeKind == null
              ? null
              : EpisodeKind.values.byName(r.episodeKind!),
          detail: r.detail,
        ),
    ];
  }

  @override
  Future<StoredPreferences> loadPreferences() async {
    final r = await _db.select(_db.preferences).getSingleOrNull();
    if (r == null) return const StoredPreferences();
    return StoredPreferences(
      theme: ThemePreference.values.byName(r.theme),
      soundPatternId: r.soundPatternId,
      reducedMotion: r.reducedMotion,
    );
  }

  @override
  Future<void> savePreferences(StoredPreferences p) => _db
      .into(_db.preferences)
      .insertOnConflictUpdate(
        PreferencesCompanion.insert(
          // Fila única explícita: sin ella, SQLite trata `singleton` (INTEGER
          // PRIMARY KEY) como rowid y propone 2 en la segunda escritura, que
          // el CHECK rechaza antes de llegar al conflicto.
          singleton: const Value(1),
          theme: p.theme.name,
          soundPatternId: p.soundPatternId,
          reducedMotion: p.reducedMotion,
          updatedEpochMs: DateTime.now().millisecondsSinceEpoch,
        ),
      );

  // ── Auxiliares ───────────────────────────────────────────────────────

  Future<DemoSessionRow?> _row(String sessionId) => (_db.select(
    _db.demoSessions,
  )..where((s) => s.sessionId.equals(sessionId))).getSingleOrNull();

  Future<void> _insertEvents(String sessionId, List<SessionEvent> events) =>
      _db.batch((b) {
        b.insertAll(_db.demoSessionEvents, [
          for (final e in events)
            DemoSessionEventsCompanion.insert(
              sessionId: sessionId,
              sequence: e.sequence,
              type: e.type.name,
              offsetMs: e.offset.inMilliseconds,
              measurement: Value(e.measurement?.name),
              signal: Value(e.signal?.name),
              episodeId: Value(e.episodeId),
              episodeKind: Value(e.episodeKind?.name),
              detail: Value(e.detail),
            ),
        ], mode: InsertMode.insertOrIgnore);
      });

  static int _latest(List<SessionEvent> events, int current) {
    var latest = current;
    for (final e in events) {
      if (e.offset.inMilliseconds > latest) latest = e.offset.inMilliseconds;
    }
    return latest;
  }

  StoredSession _stored(DemoSessionRow r) {
    final started = CivilTime(r.startedEpochMs, r.startOffsetMinutes);
    final ended = r.endedEpochMs == null
        ? null
        : CivilTime(r.endedEpochMs!, r.endOffsetMinutes!);
    final lifecycle = StoredLifecycle.values.byName(r.lifecycle);
    return StoredSession(
      sessionId: r.sessionId,
      isDemo: r.origin == 'demo',
      startedAt: started,
      lifecycle: lifecycle,
      endedAt: ended,
      endOffset: r.endOffsetMs == null
          ? null
          : Duration(milliseconds: r.endOffsetMs!),
      latestDurableOffset: Duration(milliseconds: r.latestDurableOffsetMs),
      calibrationId: r.calibrationId,
      complete: r.integrityStatus == 'complete',
      summary: lifecycle == StoredLifecycle.finalized && ended != null
          ? SessionSummary(
              sessionId: r.sessionId,
              startedAt: started.fields,
              finishedAt: ended.fields,
              evaluable: Duration(milliseconds: r.evaluableMs!),
              notEvaluable: Duration(milliseconds: r.nonEvaluableMs!),
              paused: Duration(milliseconds: r.pausedMs!),
              unknown: Duration(milliseconds: r.unknownMs!),
              episodes: r.episodeCount!,
              warnings: r.warningCount!,
              closures: r.closureCount!,
              soundsPlayed: r.soundsPlayed!,
              soundsFailed: r.soundsFailed!,
              pauses: r.pauseCount!,
            )
          : null,
    );
  }
}
