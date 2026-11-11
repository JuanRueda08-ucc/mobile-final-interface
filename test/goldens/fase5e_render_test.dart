@Tags(['render'])
library;

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
import 'package:vigia/data/experimental_history/experimental_history_database.dart';
import 'package:vigia/data/experimental_history/experimental_history_providers.dart';
import 'package:vigia/data/experimental_history/experimental_history_repository.dart';
import 'package:vigia/features/experimental/experimental_monitoring_controller.dart';

import '../support/fake_experimental.dart';
import '../support/fake_journal.dart';
import '../support/vigia_harness.dart';

/// Renderizados de Ajustes (P12) y Sonido (P13) en la variante normal
/// (fase 5E). Las preferencias se guardan en una base SQLite en memoria; el
/// motor es un doble ([FakeExperimentalBridge]). 360×800 al 100 % y 320×2400
/// al 200 %, claro y oscuro, movimiento reducido.
///
///   flutter test --update-goldens test/goldens/fase5e_render_test.dart
void main() {
  setUpAll(loadVigiaVisualAssets);
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  const failingInsert =
      'CREATE TRIGGER no_prefs BEFORE INSERT ON preferences '
      "BEGIN SELECT RAISE(ABORT, 'disco lleno'); END";

  Future<void> settle(WidgetTester t) async {
    for (var i = 0; i < 3; i++) {
      await t.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await t.pumpAndSettle();
    }
  }

  ProviderContainer containerOf(WidgetTester t) =>
      ProviderScope.containerOf(t.element(find.byType(Navigator).first));

  Future<void> go(WidgetTester t, String route) async {
    containerOf(t).read(routerProvider).go(route);
    await settle(t);
  }

  Future<void> tap(WidgetTester t, String text) async {
    final f = find.text(text).first;
    await t.ensureVisible(f);
    await t.tap(f);
    await settle(t);
  }

  // Estado → (sesión vigente, preparación).
  final states =
      <
        String,
        (
          bool,
          Future<void> Function(WidgetTester, ExperimentalHistoryDatabase),
        )
      >{
        'P12_ajustes': (false, (t, db) => go(t, VigiaRoutes.ajustes)),
        'P12_error': (
          false,
          (t, db) async {
            await t.runAsync(() => db.customStatement(failingInsert));
            await go(t, VigiaRoutes.ajustes);
            await tap(t, 'Reducido');
          },
        ),
        'P12_sesion_vigente': (true, (t, db) => go(t, VigiaRoutes.ajustes)),
        'P13_prueba': (
          false,
          (t, db) async {
            await go(t, VigiaRoutes.sonido);
            await tap(t, 'Patrón 2');
            await tap(t, 'Probar sonido');
          },
        ),
        'P13_guardado': (
          false,
          (t, db) async {
            await go(t, VigiaRoutes.sonido);
            await tap(t, 'Patrón 3');
            await tap(t, 'Guardar');
          },
        ),
        'P13_error': (
          false,
          (t, db) async {
            await t.runAsync(() => db.customStatement(failingInsert));
            await go(t, VigiaRoutes.sonido);
            await tap(t, 'Patrón 2');
            await tap(t, 'Guardar');
          },
        ),
        'P13_sesion_vigente': (true, (t, db) => go(t, VigiaRoutes.sonido)),
      };
  final configs = [
    const ScreenConfig(width: 360),
    const ScreenConfig(width: 360, dark: true),
    const ScreenConfig(width: 320, height: 2400, textScale: 2.0),
    const ScreenConfig(width: 320, height: 2400, textScale: 2.0, dark: true),
  ];

  for (final MapEntry(key: id, value: (vigente, prepare)) in states.entries) {
    for (final c in configs) {
      final name = 'F5E_${id}__${c.id}';
      testWidgets(name, (tester) async {
        final db = ExperimentalHistoryDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        final repo = ExperimentalHistoryRepository(db);
        final engine = FakeExperimentalBridge(
          vigente
              ? fakeSnapshot(
                  lifecycle: EngineSessionLifecycle.active,
                  sessionId: 'S1',
                )
              : null,
        );
        tester.view.devicePixelRatio = c.devicePixelRatio;
        tester.view.physicalSize = Size(c.width, c.height) * c.devicePixelRatio;
        tester.platformDispatcher.textScaleFactorTestValue = c.textScale;
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        await tester.pumpWidget(
          VigiaApp(
            mode: const RealMode(),
            themeMode: c.dark ? ThemeMode.dark : ThemeMode.light,
            overrides: [
              ...realOverrides(repo, await repo.loadPreferences()),
              experimentalJournalBridgeProvider.overrideWithValue(
                FakeJournal(),
              ),
              experimentalBridgeProvider.overrideWithValue(engine),
            ],
          ),
        );
        await settle(tester);
        final exp = containerOf(
          tester,
        ).read(experimentalMonitoringProvider.notifier);
        if (vigente) {
          // Estado de la sesión conocido por Flutter, como tras el monitoreo.
          exp.refresh();
          await settle(tester);
          exp.leave();
        }
        await prepare(tester, db);
        final scrollables = find.byType(Scrollable);
        if (scrollables.evaluate().isNotEmpty) {
          await tester.drag(scrollables.first, const Offset(0, 4000));
          await tester.pumpAndSettle();
        }
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('fase5e/$name.png'),
        );
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
