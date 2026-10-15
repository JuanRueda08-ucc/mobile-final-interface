import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_engine/monitoring_engine.dart';
import 'package:vigia/data/experimental_history/experimental_history_database.dart';
import 'package:vigia/data/experimental_history/experimental_history_providers.dart';
import 'package:vigia/data/experimental_history/experimental_history_repository.dart';
import 'package:vigia/data/experimental_history/journal_codec.dart';

import '../support/fake_journal.dart';

/// Fase 5D · importación idempotente del journal nativo a la proyección
/// Drift (Área 04 §12). Los hechos los construye [FakeJournal] con el mismo
/// sobre y hash que Kotlin; la lógica del journal real se prueba en Kotlin.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late ExperimentalHistoryDatabase db;
  late ExperimentalHistoryRepository repo;
  late FakeJournal journal;
  late ProviderContainer container;

  ProviderContainer containerFor(ExperimentalHistoryRepository r) =>
      ProviderContainer(
        overrides: [
          experimentalHistoryRepositoryProvider.overrideWithValue(r),
          experimentalJournalBridgeProvider.overrideWithValue(journal),
        ],
      );

  setUp(() {
    db = ExperimentalHistoryDatabase(NativeDatabase.memory());
    repo = ExperimentalHistoryRepository(db);
    journal = FakeJournal();
    container = containerFor(repo);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<JournalSyncState> sync() async {
    await container.read(journalSyncProvider.notifier).sync();
    return container.read(journalSyncProvider);
  }

  group('formato', () {
    test('vector de conformidad compartido con Kotlin (hash independiente)', () {
      // Mismo vector que ExperimentalJournalTest.codec_conformanceVector…; el
      // hash se calculó aparte con Python (hashlib).
      final r = JournalRecordMessage(
        journalSequence: 7,
        recordId: 'rec-ñ',
        sessionId: 's-1',
        recordType: 'closureDetected',
        occurredEpochMs: 1760000000000,
        occurredOffsetMinutes: -300,
        sessionOffsetMs: 2600,
        payloadSchemaVersion: 1,
        payloadJson:
            '{"activationOrdinal":1,"decisionOffsetMs":2600,"flag":true,'
            '"list":[1,"x"],"none":null,"note":"a\\"b\\\\c\\u000a"}',
        payloadHash:
            '4c3ee8ae1be6de24332dd239b5d8c6d015e76c0da3c3ba319a9f18821f86b6aa',
      );
      expect(JournalCodec.verify(r)['note'], 'a"b\\c\n');
    });

    test('rechaza decimales, payload no canónico y hash alterado', () {
      expect(() => JournalCodec.encode({'x': 0.5}), throwsFormatException);
      journal.started('s1');
      final ok = journal.records.single;
      expect(() => JournalCodec.verify(ok), returnsNormally);
      final reordered = JournalRecordMessage.decode(ok.encode())
        ..payloadJson = ok.payloadJson.replaceFirst('{', '{ ');
      expect(() => JournalCodec.verify(reordered), throwsFormatException);
      final tampered = JournalRecordMessage.decode(ok.encode())
        ..occurredEpochMs = ok.occurredEpochMs + 1;
      expect(() => JournalCodec.verify(tampered), throwsFormatException);
    });
  });

  group('guardado', () {
    test(
      'sesión finalizada: totales del motor, línea temporal y ACK',
      () async {
        journal.completeSession('s1');
        final s = await sync();
        expect(s.status, JournalSyncStatus.upToDate);
        expect(journal.pending, isEmpty, reason: 'ACK de todo lo guardado');

        final r = (await repo.session('s1'))!;
        expect(r.isFinalized, isTrue);
        expect(r.complete, isTrue);
        expect(r.qualificationStatus, 'experimental');
        expect(r.profileId, 'lab-eye-rules-0.1');
        final t = r.totals!;
        expect(t.active, const Duration(seconds: 60));
        expect(t.evaluable, const Duration(seconds: 45));
        expect(t.notEvaluable, const Duration(seconds: 15));
        expect(t.paused, const Duration(seconds: 10));
        expect(t.represented, const Duration(seconds: 70));
        expect(t.coverage, 0.75);
        expect(t.closureActivations, 1);
        expect(t.tonesPlayed, 1);
        expect(t.pauses, 1);
        expect(r.endOffset, const Duration(seconds: 70));
        expect(r.endedAt, isNotNull);
        expect(r.openEarRight, closeTo(0.301, 1e-9));
        final marks = await repo.marks('s1');
        expect(marks.map((m) => m.kind), [
          ExperimentalMarkKind.closure,
          ExperimentalMarkKind.playback,
          ExperimentalMarkKind.pauseStarted,
          ExperimentalMarkKind.pauseEnded,
        ]);
        expect(marks[1].status, 'started');
      },
    );

    test('lotes de más de 100 hechos se importan en orden', () async {
      journal.started('s1');
      for (var i = 1; i <= 230; i++) {
        journal.checkpoint(
          's1',
          i * 1000,
          FakeJournal.totals(active: i * 1000),
        );
      }
      await sync();
      expect(journal.pending, isEmpty);
      expect(await repo.importedCount(), 231);
      expect(
        (await repo.session('s1'))!.latestDurableOffset,
        const Duration(seconds: 230),
      );
      expect(journal.reads, greaterThanOrEqualTo(3));
    });

    test('sin hechos pendientes no cambia la proyección', () async {
      final s = await sync();
      expect(s.status, JournalSyncStatus.upToDate);
      expect(s.revision, 0);
      expect(await repo.latest(), isNull);
    });
  });

  group('duplicados e idempotencia', () {
    test(
      'caída tras el commit y antes del ACK: reimportar es un no-op',
      () async {
        journal.completeSession('s1');
        journal.failNextAck = true;
        expect((await sync()).status, JournalSyncStatus.failed);
        expect(
          journal.pending,
          hasLength(journal.records.length),
          reason: 'sin ACK el journal los conserva',
        );
        final before = await repo.importedCount();
        final marksBefore = await repo.marks('s1');

        final again = await sync();
        expect(again.status, JournalSyncStatus.upToDate);
        expect(journal.pending, isEmpty);
        expect(await repo.importedCount(), before);
        expect(await repo.marks('s1'), hasLength(marksBefore.length));
        expect((await repo.sessions()).single.sessionId, 's1');
      },
    );

    test(
      'mismo ID con otro hash ya importado: integridad, sin sobrescribir',
      () async {
        journal.started('s1');
        await sync();
        final original = journal.records.single;
        // Se fuerza otra revisión con el mismo recordId y secuencia.
        journal.acked.remove(original.recordId);
        journal.records.clear();
        journal.add(
          'sessionStarted',
          's1',
          0,
          {'sessionId': 's1', 'otro': 1},
          recordId: original.recordId,
          sequence: 1,
        );
        final s = await sync();
        expect(s.status, JournalSyncStatus.stopped);
        expect(s.stop, ImportStop.integrity);
        expect(journal.pending, hasLength(1), reason: 'no se confirma');
        expect((await repo.session('s1'))!.calibrationId, 'cal-s1');
      },
    );

    test(
      'cierre duplicado: el segundo se detiene y el primero se conserva',
      () async {
        journal.completeSession('s1');
        journal.finalized('s1', 99000, FakeJournal.totals(active: 99000));
        final s = await sync();
        expect(s.stop, ImportStop.relation);
        final r = (await repo.session('s1'))!;
        expect(r.endOffset, const Duration(seconds: 70));
        expect(r.totals!.active, const Duration(seconds: 60));
        expect(journal.pending, hasLength(1));
      },
    );

    test(
      'hecho alterado: se guarda el prefijo válido y el resto queda pendiente',
      () async {
        journal.completeSession('s1');
        journal.records[3].payloadJson = journal.records[3].payloadJson
            .replaceFirst('"activationOrdinal":1', '"activationOrdinal":2');
        final s = await sync();
        expect(s.stop, ImportStop.integrity);
        expect(await repo.importedCount(), 3);
        expect(journal.pending.first.journalSequence, 4);
        expect((await repo.session('s1'))!.isFinalized, isFalse);
      },
    );

    test(
      'hueco de secuencia no declarado: no se importa nada posterior',
      () async {
        journal.started('s1');
        journal.checkpoint('s1', 1000, FakeJournal.totals(active: 1000));
        journal.records.removeAt(1); // la secuencia 2 se perdió
        journal.checkpoint(
          's1',
          2000,
          FakeJournal.totals(active: 2000),
          lost: 0,
        );
        // Renumerar el último a 3 sin que exista el 2.
        final last = journal.records.removeLast();
        journal.add(
          'progressCheckpoint',
          's1',
          2000,
          {
            ...FakeJournal.totals(active: 2000),
            'knownThroughOffsetMs': 2000,
            'recordsLost': 0,
          },
          recordId: last.recordId,
          sequence: 3,
        );
        final s = await sync();
        expect(s.stop, ImportStop.gap);
        expect(await repo.importedCount(), 1);
      },
    );

    test('hecho sin sesión: no se crea una sesión de relleno', () async {
      journal.checkpoint('fantasma', 1000, FakeJournal.totals(active: 1000));
      final s = await sync();
      expect(s.stop, ImportStop.relation);
      expect(await repo.sessions(), isEmpty);
    });

    test('tipo desconocido: schemaUnsupported, pendiente', () async {
      journal.started('s1');
      journal.add('episodeOpened', 's1', 10, {'x': 1});
      final s = await sync();
      expect(s.stop, ImportStop.schema);
      expect(journal.pending, hasLength(1));
    });
  });

  group('interrupción y segunda sesión', () {
    test(
      'sesión recuperada: interrumpida, sin final ni duración ni totales',
      () async {
        journal.started('s1');
        journal.checkpoint(
          's1',
          1000,
          FakeJournal.totals(active: 1000, evaluable: 800),
        );
        journal.closure('s1', 2500, 1);
        journal.checkpoint(
          's1',
          3000,
          FakeJournal.totals(
            active: 3000,
            evaluable: 2200,
            closures: 1,
            tones: 1,
          ),
        );
        journal.interrupted('s1', 3000);
        await sync();
        final r = (await repo.session('s1'))!;
        expect(r.isInterrupted, isTrue);
        expect(r.complete, isFalse);
        expect(r.endedAt, isNull);
        expect(r.endOffset, isNull);
        expect(
          r.totals,
          isNull,
          reason: 'sin cobertura ni duración inventadas',
        );
        expect(r.latestDurableOffset, const Duration(seconds: 3));
        expect(r.known!.through, const Duration(seconds: 3));
        expect(r.known!.evaluable, const Duration(milliseconds: 2200));
        expect(r.recoveredAt, isNotNull);
        expect(
          (await repo.marks('s1'))
              .where((m) => m.kind == ExperimentalMarkKind.closure),
          hasLength(1),
        );
        // Una recuperación posterior duplicada no vuelve a aplicarse.
        journal.interrupted('s1', 3000);
        expect((await sync()).stop, ImportStop.relation);
      },
    );

    test(
      'segunda sesión: otra fila, orden descendente y última = la nueva',
      () async {
        journal.completeSession('s1');
        journal.started('s2', epochMs: journal.startEpochMs + 600000);
        journal.finalized(
          's2',
          5000,
          FakeJournal.totals(active: 5000, evaluable: 5000),
        );
        await sync();
        final all = await repo.sessions();
        expect(all.map((s) => s.sessionId), ['s2', 's1']);
        expect((await repo.latest())!.sessionId, 's2');
        expect(
          await repo.sessions(filter: ExperimentalHistoryFilter.interrupted),
          isEmpty,
        );
      },
    );

    test(
      'registro con pérdida declarada: finalizada pero incompleta',
      () async {
        journal.started('s1');
        journal.finalized(
          's1',
          5000,
          FakeJournal.totals(active: 5000),
          lost: 2,
        );
        await sync();
        final r = (await repo.session('s1'))!;
        expect(r.isFinalized, isTrue);
        expect(r.complete, isFalse);
        expect(r.recordsLost, 2);
      },
    );
  });

  group('reapertura', () {
    test(
      'cerrar y reabrir la base conserva todo y reimportar no duplica',
      () async {
        final dir = await Directory.systemTemp.createTemp('vigia_real_');
        addTearDown(() => dir.delete(recursive: true));
        final file = File('${dir.path}/vigia_history_real_v1.sqlite');
        journal.completeSession('s1');
        journal.started('s2', epochMs: journal.startEpochMs + 600000);
        journal.checkpoint('s2', 1000, FakeJournal.totals(active: 1000));

        final first = ExperimentalHistoryDatabase(NativeDatabase(file));
        final c1 = containerFor(ExperimentalHistoryRepository(first));
        journal.failNextAck = true; // caída antes del ACK
        await c1.read(journalSyncProvider.notifier).sync();
        c1.dispose();
        await first.close();

        // «Proceso» nuevo: el motor recupera s2 como interrumpida.
        journal.interrupted('s2', 1000);
        final second = ExperimentalHistoryDatabase(NativeDatabase(file));
        final repo2 = ExperimentalHistoryRepository(second);
        final c2 = containerFor(repo2);
        await c2.read(journalSyncProvider.notifier).sync();
        expect(journal.pending, isEmpty);
        expect(await repo2.importedCount(), journal.records.length);
        final all = await repo2.sessions();
        expect(all.map((s) => (s.sessionId, s.lifecycle)), [
          ('s2', ExperimentalLifecycle.interrupted),
          ('s1', ExperimentalLifecycle.finalized),
        ]);
        expect(
          (await repo2.session('s1'))!.totals!.active,
          const Duration(seconds: 60),
        );
        c2.dispose();
        await second.close();
      },
    );
  });

  group('sincronización', () {
    test('una petición durante otra repite la pasada al terminar', () async {
      journal.started('s1');
      final notifier = container.read(journalSyncProvider.notifier);
      final a = notifier.sync();
      // Llega el cierre mientras se importa.
      journal.finalized('s1', 3000, FakeJournal.totals(active: 3000));
      final b = notifier.sync();
      await Future.wait([a, b]);
      expect((await repo.session('s1'))!.isFinalized, isTrue);
      expect(journal.pending, isEmpty);
    });

    test('fallo de lectura: estado failed sin tocar la proyección', () async {
      journal.completeSession('s1');
      journal.failNextRead = true;
      expect((await sync()).status, JournalSyncStatus.failed);
      expect(await repo.latest(), isNull);
      expect((await sync()).status, JournalSyncStatus.upToDate);
      expect((await repo.latest())!.sessionId, 's1');
    });
  });
}
