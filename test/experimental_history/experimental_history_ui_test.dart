import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:monitoring_engine/monitoring_engine.dart';
import 'package:vigia/app/app_config.dart';
import 'package:vigia/app/bootstrap.dart';
import 'package:vigia/app/vigia_app.dart';
import 'package:vigia/data/experimental_history/experimental_history_database.dart';
import 'package:vigia/data/experimental_history/experimental_history_providers.dart';
import 'package:vigia/data/experimental_history/experimental_history_repository.dart';
import 'package:vigia/features/experimental/experimental_monitoring_controller.dart';
import 'package:vigia/features/camera/front_camera_controller.dart';

import '../support/fake_camera.dart';
import '../support/fake_experimental.dart';
import '../support/fake_journal.dart';
import '../support/history_harness.dart';
import '../support/vigia_harness.dart';

/// Fase 5D · Inicio, Resumen, Historial y detalle de la variante normal leen
/// la misma proyección importada del journal (doble [FakeJournal]; los hechos
/// los fija la prueba, no son una sesión real).
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late ExperimentalHistoryDatabase db;
  late ExperimentalHistoryRepository repo;
  late FakeJournal journal;

  setUp(() {
    db = ExperimentalHistoryDatabase(NativeDatabase.memory());
    repo = ExperimentalHistoryRepository(db);
    journal = FakeJournal();
  });

  tearDown(() => db.close());

  Future<void> pumpReal(WidgetTester tester, {List extra = const []}) async {
    await loadVigiaFonts();
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(400, 2400) * 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      VigiaApp(
        mode: const RealMode(),
        themeMode: ThemeMode.light,
        overrides: [
          experimentalHistoryRepositoryProvider.overrideWithValue(repo),
          experimentalJournalBridgeProvider.overrideWithValue(journal),
          ...extra.cast(),
        ],
      ),
    );
    // La importación usa SQLite real: se deja correr fuera del reloj falso.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pumpAndSettle();
    }
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final f = find.text(text);
    await tester.ensureVisible(f.first);
    await tester.tap(f.first);
    await settle(tester);
  }

  testWidgets(
    'el cierre guardado se ve igual en Inicio, Resumen, Historial y detalle',
    (tester) async {
      journal.completeSession('a1b2c3d4-0000-4000-8000-000000000001');
      await pumpReal(tester);
      expect(journal.pending, isEmpty, reason: 'Inicio importa al montarse');

      // Inicio: último resumen, rotulado experimental.
      expect(find.byKey(const Key('home-latest-experimental')), findsOneWidget);
      expect(find.text('Experimental · Completo · guardado'), findsOneWidget);
      expect(find.text('75,0 %'), findsOneWidget);
      expect(find.textContaining('DEMO'), findsNothing);

      // Resumen.
      await tapText(tester, 'Ver último resumen');
      expect(find.byKey(const Key('experimental-data-banner')), findsOneWidget);
      expect(find.byKey(const Key('summary-saved')), findsOneWidget);
      expect(find.text('75,0 %'), findsOneWidget);
      expect(find.text('60,0 s'), findsWidgets);
      expect(find.text('1 iniciados · 0 fallidos'), findsOneWidget);

      // Detalle.
      await tapText(tester, 'Ver detalle');
      expect(
        find.text('Real · experimental (lab-eye-rules-0.1)'),
        findsOneWidget,
      );
      expect(find.text('75,0 %'), findsOneWidget);
      expect(find.text('Completo · guardado'), findsOneWidget);
      expect(find.textContaining('Cierre ocular prolongado 1'), findsOneWidget);
      expect(find.textContaining('Tono iniciado (aviso 1)'), findsOneWidget);
      expect(find.textContaining('Pausa 1'), findsOneWidget);

      // Historial.
      await tester.tap(find.bySemanticsLabel('Volver').first);
      await settle(tester);
      expect(find.textContaining('Experimental · a1b2c3d4 · '), findsOneWidget);
      expect(
        find.textContaining('Finalizada · Cobertura 75,0 %'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'sesión interrumpida: Inicio y detalle sin final, duración ni cobertura',
    (tester) async {
      journal.completeSession('s-uno');
      journal.started('s-dos', epochMs: journal.startEpochMs + 3600000);
      journal.checkpoint(
        's-dos',
        1000,
        FakeJournal.totals(active: 1000, evaluable: 900),
      );
      journal.closure('s-dos', 1500, 1);
      journal.checkpoint(
        's-dos',
        2000,
        FakeJournal.totals(
          active: 2000,
          evaluable: 1700,
          closures: 1,
          tones: 1,
        ),
      );
      journal.interrupted('s-dos', 2000);
      await pumpReal(tester);

      expect(
        find.byKey(const Key('home-interrupted-experimental')),
        findsOneWidget,
      );
      expect(find.text('Desconocido'), findsOneWidget);
      expect(find.text('No disponible'), findsOneWidget);
      await tapText(tester, 'Revisar registro');
      expect(find.text('Interrumpida'), findsOneWidget);
      expect(find.text('Desconocido'), findsWidgets);
      expect(
        find.text('No disponible'),
        findsNWidgets(2),
        reason: 'duración y cobertura',
      );
      expect(find.text('Evaluable confirmado hasta +00:02'), findsOneWidget);
      expect(find.text('1,7 s'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Volver').first);
      await settle(tester);
      await tapText(tester, 'Interrumpidas');
      expect(find.textContaining('Experimental · s-dos'), findsOneWidget);
      expect(find.textContaining('Experimental · s-uno'), findsNothing);
      expect(
        find.textContaining('Interrumpida · Cobertura No disponible'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'tras finalizar, el resumen espera el cierre durable del journal',
    (tester) async {
      // El motor confirma el cierre, pero su hecho aún no se ha leído.
      journal.started('S1');
      final engine = FakeExperimentalBridge(
        fakeSnapshot(
          lifecycle: EngineSessionLifecycle.active,
          sessionId: 'S1',
          eyesValid: true,
          measurement: EngineMeasurement.usable,
          signal: EngineSignal.noPersistentSignals,
        ),
      );
      final camera = FakeFrontCameraBridge(
        permission: CameraPermissionStatus.granted,
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await pumpReal(
        tester,
        extra: [
          experimentalBridgeProvider.overrideWithValue(engine),
          frontCameraBridgeProvider.overrideWithValue(camera),
        ],
      );
      await tester.ensureVisible(find.byKey(const Key('open-experimental')));
      await tester.tap(find.byKey(const Key('open-experimental')));
      await settle(tester);
      camera.emitFace(FaceAnalysisStatus.oneFace);
      await tester.pump();
      await tester.pump();
      engine.next = fakeSnapshot(
        lifecycle: EngineSessionLifecycle.finalized,
        sessionId: 'S1',
        activeMs: 65000,
        evaluableMs: 50000,
      );
      await tester.tap(find.byKey(const Key('finish')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Finalizar').last);
      await settle(tester);
      expect(find.byKey(const Key('summary')), findsOneWidget);
      expect(find.byKey(const Key('summary-pending')), findsOneWidget);
      expect(
        find.text('00:01:05'),
        findsNothing,
        reason: 'no hay resumen en memoria',
      );

      // El cierre durable llega al journal: la pantalla lo lee sin otro aviso.
      journal.finalized(
        'S1',
        66000,
        FakeJournal.totals(active: 65000, evaluable: 50000, paused: 1000),
      );
      await tester.pump(const Duration(seconds: 1));
      await settle(tester);
      expect(find.byKey(const Key('summary-saved')), findsOneWidget);
      expect(find.text('76,9 %'), findsOneWidget);
      expect(journal.pending, isEmpty);

      await tapText(tester, 'Volver a Inicio');
      expect(find.byKey(const Key('home-latest-experimental')), findsOneWidget);
      expect(find.text('76,9 %'), findsOneWidget);
    },
  );

  testWidgets('sin sesiones guardadas: vacío distinto de cargando', (
    tester,
  ) async {
    await pumpReal(tester);
    expect(find.text('Aún no hay sesiones experimentales'), findsOneWidget);
    await tapText(tester, 'Ver historial experimental');
    expect(find.text('Aún no hay sesiones experimentales'), findsOneWidget);
    expect(find.byKey(const Key('experimental-data-banner')), findsOneWidget);
  });

  testWidgets('un cierre ausente comunica incompleto y permite salir', (
    tester,
  ) async {
    journal.started('sin-cierre');
    await pumpReal(tester);
    // La ruta de resumen también debe explicar un cierre que nunca se escribió.
    final context = tester.element(find.byKey(const Key('open-experimental')));
    GoRouter.of(context).go('/resumen/sin-cierre');
    await settle(tester);
    await tester.pump(const Duration(seconds: 10));
    await settle(tester);
    expect(find.text('Cierre no confirmado'), findsOneWidget);
    expect(
      find.textContaining('Los totales no están disponibles'),
      findsOneWidget,
    );
    await tapText(tester, 'Volver al inicio');
  });

  testWidgets(
    'pérdida conocida: Inicio, Resumen y detalle no dan totales completos',
    (tester) async {
      journal.started('perdida');
      journal.finalized(
        'perdida',
        5000,
        FakeJournal.totals(active: 5000, evaluable: 4000, closures: 1),
        lost: 2,
      );
      await pumpReal(tester);
      expect(find.text('80,0 %'), findsNothing);
      await tapText(tester, 'Ver último resumen');
      expect(find.text('Registro incompleto'), findsOneWidget);
      expect(find.text('80,0 %'), findsNothing);
      expect(find.text('5,0 s'), findsNothing);
      await tapText(tester, 'Ver detalle');
      expect(find.text('80,0 %'), findsNothing);
      expect(find.text('No disponible'), findsWidgets);
    },
  );

  testWidgets('la app DEMO no abre ni muestra el historial experimental', (
    tester,
  ) async {
    journal.completeSession('real-1');
    final (demoDb, demoRepo) =
        await tester.runAsync(openMemoryHistory) ??
        (throw StateError('sin base DEMO'));
    addTearDown(demoDb.close);
    await loadVigiaFonts();
    await tester.pumpWidget(
      VigiaApp(
        mode: const DemoMode(),
        themeMode: ThemeMode.light,
        overrides: [
          ...demoOverrides(
            demoRepo,
            await tester.runAsync(demoRepo.loadPreferences) ??
                (throw StateError('')),
          ),
          // Aunque existiera, la DEMO no lo consulta.
          experimentalHistoryRepositoryProvider.overrideWithValue(repo),
          experimentalJournalBridgeProvider.overrideWithValue(journal),
        ],
      ),
    );
    await settle(tester);
    await tester.tap(find.text('Historial').last);
    await settle(tester);
    expect(find.textContaining('real-1'), findsNothing);
    expect(find.textContaining('Experimental ·'), findsNothing);
    expect(journal.reads, 0, reason: 'la DEMO no lee el journal real');
    expect(await tester.runAsync(repo.importedCount), 0);
  });
}
