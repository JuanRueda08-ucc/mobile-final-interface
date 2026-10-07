import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia/data/demo_history/demo_history_database.dart';
import 'package:vigia/data/demo_history/demo_history_repository.dart';
import 'package:vigia/features/monitoring/domain/session_model.dart';
import 'package:vigia/features/monitoring/domain/session_summary.dart';

import '../support/history_harness.dart';

/// Historial DEMO sobre SQLite real (Drift, sqlite3 del equipo de pruebas):
/// guardado único del cierre, relectura con otra instancia de la base,
/// recuperación de interrumpidas, orden, filtros y origen DEMO.
void main() {
  SessionEvent ev(int seq, SessionEventType type, int ms, {String? ep}) =>
      SessionEvent(
        sequence: seq,
        type: type,
        offset: Duration(milliseconds: ms),
        measurement: type == SessionEventType.measurementChanged
            ? Measurement.usable
            : null,
        episodeId: ep,
        episodeKind: ep == null ? null : EpisodeKind.warning,
      );

  final start = DateTime(2026, 10, 6, 8, 12);
  SessionStartRecord startRecord(String id, int n, {DateTime? at}) =>
      SessionStartRecord(
        sessionId: id,
        sessionNumber: n,
        startedAt: at ?? start,
        calibrationId: 'C-DEMO-0001',
      );

  final firstEvents = [
    ev(1, SessionEventType.started, 0),
    ev(2, SessionEventType.measurementChanged, 2000),
  ];
  final laterEvents = [
    ev(3, SessionEventType.episodeStarted, 8000, ep: 'S-DEMO-0001-E01'),
    ev(4, SessionEventType.episodeEnded, 14000, ep: 'S-DEMO-0001-E01'),
  ];
  final closing = [
    ev(5, SessionEventType.stopRequested, 20000),
    ev(6, SessionEventType.finished, 20700),
  ];
  SessionSummary summary(String id) => SessionSummary.fromEvents(
    sessionId: id,
    startedAt: start,
    finishedAt: start.add(const Duration(seconds: 21)),
    events: [...firstEvents, ...laterEvents, ...closing],
  );

  Future<int> count(DemoHistoryDatabase db, String table) async =>
      (await db.customSelect('SELECT COUNT(*) AS n FROM $table').getSingle())
          .read<int>('n');

  late DemoHistoryDatabase db;
  late DriftDemoHistoryRepository repo;
  setUp(() async => (db, repo) = await openMemoryHistory());
  tearDown(() => db.close());

  test('el cierre se guarda una sola vez, sin duplicar hechos', () async {
    await repo.recordStart(startRecord('S-DEMO-0001', 1), firstEvents);
    await repo.appendEvents('S-DEMO-0001', laterEvents, StoredLifecycle.active);
    // El mismo lote otra vez (reintento): no duplica.
    await repo.appendEvents('S-DEMO-0001', laterEvents, StoredLifecycle.active);
    final s = summary('S-DEMO-0001');
    const end = Duration(seconds: 20);
    expect(await repo.finalize('S-DEMO-0001', closing, s, end), isTrue);
    expect(await repo.finalize('S-DEMO-0001', closing, s, end), isFalse);
    expect(await count(db, 'demo_sessions'), 1);
    expect(await count(db, 'demo_session_events'), 6);

    final stored = (await repo.session('S-DEMO-0001'))!;
    expect(stored.lifecycle, StoredLifecycle.finalized);
    expect(stored.complete, isTrue);
    expect(stored.endOffset, end);
    expect(stored.latestDurableOffset, end);
    final m = stored.summary!;
    expect(m.evaluable, s.evaluable);
    expect(m.notEvaluable, s.notEvaluable);
    expect(m.monitored, const Duration(seconds: 20));
    expect(m.episodes, 1);
    // Los totales guardados coinciden con recalcularlos de los hechos guardados.
    final again = SessionSummary.fromEvents(
      sessionId: 'S-DEMO-0001',
      startedAt: start,
      finishedAt: start,
      events: await repo.events('S-DEMO-0001'),
    );
    expect(
      (again.evaluable, again.notEvaluable, again.paused, again.episodes),
      (m.evaluable, m.notEvaluable, m.paused, m.episodes),
    );
  });

  test(
    'otra instancia de la base lee las mismas sesiones y preferencias',
    () async {
      final dir = await Directory.systemTemp.createTemp('vigia_history_');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/vigia_history_demo_v1.sqlite');

      final first = DemoHistoryDatabase(NativeDatabase(file));
      final r1 = await DriftDemoHistoryRepository.open(first);
      expect(r1.reserveSessionNumber(), 1);
      await r1.recordStart(startRecord('S-DEMO-0001', 1), firstEvents);
      await r1.appendEvents('S-DEMO-0001', laterEvents, StoredLifecycle.paused);
      await r1.finalize(
        'S-DEMO-0001',
        closing,
        summary('S-DEMO-0001'),
        const Duration(seconds: 20),
      );
      await r1.savePreferences(
        const StoredPreferences(
          theme: ThemePreference.dark,
          soundPatternId: 'patron_3',
          reducedMotion: true,
        ),
      );
      await first.close();

      final second = DemoHistoryDatabase(NativeDatabase(file));
      addTearDown(second.close);
      final r2 = await DriftDemoHistoryRepository.open(second);
      final s = (await r2.session('S-DEMO-0001'))!;
      expect(s.isDemo, isTrue);
      expect(s.isFinalized, isTrue);
      expect(s.summary!.episodes, 1);
      expect(formatDateTime(s.startedAt.fields), '06/10/2026 08:12');
      expect(await r2.events('S-DEMO-0001'), hasLength(6));
      expect(
        await r2.loadPreferences(),
        const StoredPreferences(
          theme: ThemePreference.dark,
          soundPatternId: 'patron_3',
          reducedMotion: true,
        ),
      );
      // Los números no se reutilizan entre ejecuciones.
      expect(r2.reserveSessionNumber(), 2);
      expect(r2.reserveCalibrationNumber(), 2);
    },
  );

  test('al reabrir, una sesión sin cierre queda interrumpida sin inventar '
      'tiempo (RF19)', () async {
    await repo.recordStart(startRecord('S-DEMO-0001', 1), firstEvents);
    await repo.appendEvents('S-DEMO-0001', laterEvents, StoredLifecycle.active);

    final reopened = await DriftDemoHistoryRepository.open(db);
    final s = (await reopened.session('S-DEMO-0001'))!;
    expect(s.lifecycle, StoredLifecycle.interrupted);
    expect(s.complete, isFalse);
    expect(s.endedAt, isNull);
    expect(s.endOffset, isNull);
    expect(s.summary, isNull, reason: 'sin duración ni cobertura inventadas');
    // El último límite es el último hecho guardado, no la reapertura.
    expect(s.latestDurableOffset, const Duration(seconds: 14));

    // Un ciclo terminal no vuelve atrás ni se finaliza después.
    await reopened.appendEvents('S-DEMO-0001', [
      ev(9, SessionEventType.pauseStarted, 99000),
    ], StoredLifecycle.active);
    expect((await reopened.session('S-DEMO-0001'))!.isInterrupted, isTrue);
    expect(await reopened.events('S-DEMO-0001'), hasLength(4));
    await expectLater(
      reopened.finalize(
        'S-DEMO-0001',
        closing,
        summary('S-DEMO-0001'),
        const Duration(seconds: 20),
      ),
      throwsStateError,
    );
    // Una sesión finalizada no se marca interrumpida.
    expect(await reopened.markInterrupted(), 0);
  });

  test('orden de inicio descendente con desempate por ID, y filtros', () async {
    await repo.recordStart(startRecord('S-DEMO-0001', 1), firstEvents);
    await repo.recordStart(
      startRecord('S-DEMO-0002', 2, at: start.add(const Duration(hours: 1))),
      firstEvents,
    );
    await repo.recordStart(
      startRecord('S-DEMO-0003', 3, at: start.add(const Duration(hours: 1))),
      firstEvents,
    );
    await repo.markInterrupted();
    await repo.recordStart(startRecord('S-DEMO-0004', 4), firstEvents);
    await repo.finalize(
      'S-DEMO-0004',
      closing,
      summary('S-DEMO-0004'),
      const Duration(seconds: 20),
    );
    final all = await repo.sessions();
    expect(all.map((s) => s.sessionId), [
      'S-DEMO-0003',
      'S-DEMO-0002',
      'S-DEMO-0004',
      'S-DEMO-0001',
    ]);
    expect(
      (await repo.sessions(filter: HistoryFilter.finalized))
          .map((s) => s.sessionId),
      ['S-DEMO-0004'],
    );
    expect(
      await repo.sessions(filter: HistoryFilter.interrupted),
      hasLength(3),
    );
    expect((await repo.latestSession())!.sessionId, 'S-DEMO-0003');
  });

  test('el origen DEMO es obligatorio en el esquema', () async {
    await repo.recordStart(startRecord('S-DEMO-0001', 1), firstEvents);
    await expectLater(
      db.customStatement(
        "UPDATE demo_sessions SET origin = 'real' WHERE session_id = 'S-DEMO-0001'",
      ),
      throwsA(isA<SqliteException>()),
    );
    // Claves foráneas activas: un hecho sin sesión se rechaza.
    await expectLater(
      db
          .into(db.demoSessionEvents)
          .insert(
            DemoSessionEventsCompanion.insert(
              sessionId: 'S-NO-EXISTE',
              sequence: 1,
              type: 'started',
              offsetMs: 0,
            ),
          ),
      throwsA(isA<SqliteException>()),
    );
  });
}
