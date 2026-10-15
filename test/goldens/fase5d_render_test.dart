@Tags(['render'])
library;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia/app/app_config.dart';
import 'package:vigia/app/vigia_app.dart';
import 'package:vigia/data/experimental_history/experimental_history_database.dart';
import 'package:vigia/data/experimental_history/experimental_history_providers.dart';
import 'package:vigia/data/experimental_history/experimental_history_repository.dart';

import '../support/fake_journal.dart';
import '../support/vigia_harness.dart';

/// Renderizados del historial experimental real (fase 5D) con hechos fijados
/// por la prueba ([FakeJournal]); no son sesiones reales. 360×2400 lógicos,
/// texto 100 %, claro y oscuro.
///
///   flutter test --update-goldens test/goldens/fase5d_render_test.dart
void main() {
  setUpAll(loadVigiaFonts);
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  const finished = 'a1b2c3d4-5e6f-4a7b-8c9d-0e1f2a3b4c5d';
  const interrupted = 'f0e1d2c3-b4a5-4697-8869-7a6b5c4d3e2f';

  void finalizedOnly(FakeJournal j) => j.completeSession(finished);

  void withInterrupted(FakeJournal j) {
    j.completeSession(finished);
    j.started(interrupted, epochMs: j.startEpochMs + 3600000);
    j.checkpoint(
      interrupted,
      1000,
      FakeJournal.totals(active: 1000, evaluable: 900),
    );
    j.closure(interrupted, 41500, 1);
    j.checkpoint(
      interrupted,
      42000,
      FakeJournal.totals(
        active: 42000,
        evaluable: 31700,
        closures: 1,
        tones: 1,
      ),
    );
    j.interrupted(interrupted, 42000);
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final f = find.text(text).first;
    await tester.ensureVisible(f);
    await tester.tap(f);
  }

  // Estado → (hechos, navegación desde Inicio).
  final states =
      <
        String,
        (void Function(FakeJournal), Future<void> Function(WidgetTester))
      >{
        'inicio_ultimo_resumen': (finalizedOnly, (t) async {}),
        'inicio_interrumpida': (withInterrupted, (t) async {}),
        'resumen_guardado': (
          finalizedOnly,
          (t) => tapText(t, 'Ver último resumen'),
        ),
        'historial': (
          withInterrupted,
          (t) => tapText(t, 'Ver historial experimental'),
        ),
        'detalle_finalizada': (
          finalizedOnly,
          (t) async {
            await tapText(t, 'Ver último resumen');
            await t.pumpAndSettle();
            await tapText(t, 'Ver detalle');
          },
        ),
        'detalle_interrumpida': (
          withInterrupted,
          (t) => tapText(t, 'Revisar registro'),
        ),
      };

  for (final MapEntry(key: id, value: (facts, go)) in states.entries) {
    for (final dark in [false, true]) {
      final name = 'F5D_${id}__${dark ? 'oscuro' : 'claro'}_360_100';
      testWidgets(name, (tester) async {
        final db = ExperimentalHistoryDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        final journal = FakeJournal();
        facts(journal);
        tester.view.devicePixelRatio = 2;
        tester.view.physicalSize = const Size(360, 2400) * 2;
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        await tester.pumpWidget(
          VigiaApp(
            mode: const RealMode(),
            themeMode: dark ? ThemeMode.dark : ThemeMode.light,
            overrides: [
              experimentalHistoryRepositoryProvider.overrideWithValue(
                ExperimentalHistoryRepository(db),
              ),
              experimentalJournalBridgeProvider.overrideWithValue(journal),
            ],
          ),
        );
        Future<void> settle() async {
          for (var i = 0; i < 3; i++) {
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 30)),
            );
            await tester.pumpAndSettle();
          }
        }

        await settle();
        await go(tester);
        await settle();
        // Arriba de la pantalla, para que el encuadre no dependa del desplazamiento.
        final scrollables = find.byType(Scrollable);
        if (scrollables.evaluate().isNotEmpty) {
          await tester.drag(scrollables.first, const Offset(0, 4000));
          await tester.pumpAndSettle();
        }
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('fase5d/$name.png'),
        );
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
