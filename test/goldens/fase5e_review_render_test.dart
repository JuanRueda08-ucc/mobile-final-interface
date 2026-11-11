@Tags(['render'])
library;

import 'dart:ui' show SemanticsAction;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_engine/monitoring_engine.dart';
import 'package:vigia/app/app_config.dart';
import 'package:vigia/app/bootstrap.dart';
import 'package:vigia/app/router.dart';
import 'package:vigia/app/vigia_app.dart';
import 'package:vigia/core/design_system/widgets/vigia_blocks.dart';
import 'package:vigia/data/experimental_history/experimental_history_database.dart';
import 'package:vigia/data/experimental_history/experimental_history_providers.dart';
import 'package:vigia/data/experimental_history/experimental_history_repository.dart';
import 'package:vigia/features/experimental/experimental_monitoring_controller.dart';

import '../support/fake_experimental.dart';
import '../support/fake_journal.dart';
import '../support/vigia_harness.dart';

/// Muestras nuevas de revisión; nunca actualiza los patrones preexistentes.
/// Acciones de accesibilidad reales del árbol Flutter, no TalkBack físico.
void main() {
  setUpAll(loadVigiaVisualAssets);
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  Future<void> settle(WidgetTester t) async {
    for (var i = 0; i < 3; i++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await t.pumpAndSettle();
    }
  }

  ProviderContainer container(WidgetTester t) =>
      ProviderScope.containerOf(t.element(find.byType(Navigator).first));

  Future<void> action(WidgetTester t, String label) async {
    await t.ensureVisible(find.bySemanticsLabel(label).first);
    await t.pumpAndSettle();
    t.semantics.tap(find.semantics.byLabel(label));
    await settle(t);
  }

  Future<void> sample(WidgetTester t, String name) async {
    await t.drag(find.byType(Scrollable).first, const Offset(0, 5000));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('fase5e_review/$name.png'),
    );
  }

  Future<ExperimentalHistoryRepository> pump(
    WidgetTester t,
    FakeExperimentalBridge engine,
    ScreenConfig cfg,
  ) async {
    final db = ExperimentalHistoryDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = ExperimentalHistoryRepository(db);
    t.view.devicePixelRatio = cfg.devicePixelRatio;
    t.view.physicalSize = Size(cfg.width, cfg.height) * cfg.devicePixelRatio;
    t.platformDispatcher.textScaleFactorTestValue = cfg.textScale;
    t.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(t.view.reset);
    addTearDown(t.platformDispatcher.clearAllTestValues);
    await t.pumpWidget(
      VigiaApp(
        mode: const RealMode(),
        overrides: [
          ...realOverrides(repo, await repo.loadPreferences()),
          experimentalBridgeProvider.overrideWithValue(engine),
          experimentalJournalBridgeProvider.overrideWithValue(FakeJournal()),
        ],
      ),
    );
    await settle(t);
    return repo;
  }

  for (final dark in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      final cfg = ScreenConfig(
        width: scale == 2 ? 320 : 360,
        height: scale == 2 ? 2400 : 1000,
        textScale: scale,
        dark: dark,
      );
      testWidgets('P12/P13 semántica ${cfg.id}', (t) async {
        final semantics = t.ensureSemantics();
        final engine = FakeExperimentalBridge();
        final repo = await pump(t, engine, cfg);
        final c = container(t);
        c.read(routerProvider).go(VigiaRoutes.ajustes);
        await settle(t);
        await action(t, dark ? 'Oscuro' : 'Claro');
        await action(t, 'Según Android');
        expect(
          MediaQuery.disableAnimationsOf(t.element(find.text('Movimiento'))),
          isTrue,
          reason: 'Android reduce aunque la preferencia no lo solicite',
        );
        await sample(t, 'P12_${cfg.id}');
        await action(t, 'Sonido');
        await action(t, 'Patrón 2');
        await action(t, 'Probar sonido');
        expect(
          find.textContaining('Esto no confirma que lo hayas oído'),
          findsOneWidget,
        );
        await action(t, 'Guardar');
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is StatusCard && widget.title == 'Patrón guardado',
          ),
          findsOneWidget,
        );
        expect(
          (await t.runAsync(repo.loadPreferences))!.soundPatternId,
          'patron_2',
        );
        expect(engine.current.soundPatternId, 'patron_2');
        expect(engine.current.soundHeard, isFalse);
        await sample(t, 'P13_${cfg.id}');
        await t.pumpWidget(const SizedBox());
        semantics.dispose();
      });
    }

    testWidgets(
      'ruta directa con sesión nativa desconocida ${dark ? 'oscuro' : 'claro'}',
      (t) async {
        final semantics = t.ensureSemantics();
        final cfg = ScreenConfig(
          width: 320,
          height: 2400,
          textScale: 2,
          dark: dark,
        );
        final engine = FakeExperimentalBridge(
          fakeSnapshot(
            lifecycle: EngineSessionLifecycle.paused,
            sessionId: 'vigente',
          ),
        );
        final repo = await pump(t, engine, cfg);
        final c = container(t);
        c.read(routerProvider).go(VigiaRoutes.ajustes);
        await settle(t);
        await action(t, dark ? 'Oscuro' : 'Claro');
        expect(
          t
              .getSemantics(find.bySemanticsLabel('Reducido'))
              .getSemanticsData()
              .hasAction(SemanticsAction.tap),
          isFalse,
        );
        expect(
          (await t.runAsync(repo.loadPreferences))!.reducedMotion,
          isFalse,
        );
        await sample(t, 'P12_sesion_${cfg.id}');
        c.read(routerProvider).go(VigiaRoutes.sonido);
        await settle(t);
        expect(find.text('Probar sonido'), findsNothing);
        await sample(t, 'P13_bloqueado_${cfg.id}');
        await t.pumpWidget(const SizedBox());
        semantics.dispose();
      },
    );
  }
}
