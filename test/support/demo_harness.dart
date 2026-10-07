import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vigia/app/app_config.dart';
import 'package:vigia/app/bootstrap.dart';
import 'package:vigia/app/router.dart';
import 'package:vigia/app/vigia_app.dart';
import 'package:vigia/core/audio/alert_sound.dart';
import 'package:vigia/core/clock/monotonic_clock.dart';
import 'package:vigia/data/demo_history/demo_history_database.dart';
import 'package:vigia/data/demo_history/demo_history_repository.dart';
import 'package:vigia/features/calibration/calibration_controller.dart';
import 'package:vigia/features/monitoring/demo_session_controller.dart';
import 'package:vigia/features/preparation/preparation_controller.dart';

import 'fake_sound.dart';
import 'history_harness.dart';
import 'vigia_harness.dart';

/// Reloj de prueba: tiempo monotónico de `package:clock` (controlado por
/// `testWidgets`) y hora civil fija desde las 08:12, para que «Inicio
/// confirmado» y «Cierre confirmado» sean reproducibles en los renderizados.
class FixedWallClock implements MonotonicClock {
  final _inner = PackageClock();

  @override
  Duration get elapsed => _inner.elapsed;

  @override
  DateTime wallNow() => DateTime(2026, 10, 6, 8, 12).add(_inner.elapsed);
}

/// Retraso de confirmación del motor simulado (igual al de producción).
const demoConfirm = Duration(milliseconds: 700);

/// Historial, base y pantalla de la última app montada con [pumpDemo].
late DriftDemoHistoryRepository demoHistory;
late DemoHistoryDatabase demoDatabase;
late ScreenConfig demoConfig;

/// Abre un historial DEMO en memoria que se cierra al terminar la prueba.
Future<DemoHistoryDatabase> openTestHistory(WidgetTester tester) async {
  final (db, _) = await openMemoryHistory();
  addTearDown(db.close);
  return db;
}

/// Monta la app en modo `VIGIA_DEMO=true` con reloj de `package:clock`
/// (controlado por `testWidgets`), un reproductor de sonido falso y un
/// historial DEMO real en memoria.
///
/// - [database]: reabre esa base (otra instancia del repositorio, como al
///   reabrir la app): se aplica la recuperación de sesiones interrumpidas.
/// - [themeFromPreferences]: el tema sale de Ajustes y no de [c].
Future<FakeSoundPlayer> pumpDemo(
  WidgetTester tester,
  ScreenConfig c, {
  AppMode mode = const DemoMode(),
  DemoHistoryDatabase? database,
  bool themeFromPreferences = false,
}) async {
  final sound = FakeSoundPlayer();
  final db = demoDatabase = database ?? await openTestHistory(tester);
  demoConfig = c;
  demoHistory = await DriftDemoHistoryRepository.open(db);
  final preferences = await demoHistory.loadPreferences();
  tester.view.devicePixelRatio = c.devicePixelRatio;
  tester.view.physicalSize = Size(c.width, c.height) * c.devicePixelRatio;
  tester.platformDispatcher.textScaleFactorTestValue = c.textScale;
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: c.reduceMotion);
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  await tester.pumpWidget(
    VigiaApp(
      mode: mode,
      themeMode: themeFromPreferences
          ? null
          : (c.dark ? ThemeMode.dark : ThemeMode.light),
      overrides: [
        monotonicClockProvider.overrideWith((ref) => FixedWallClock()),
        alertSoundPlayerProvider.overrideWithValue(sound),
        // Real/revisión: como en la app, sin historial abierto.
        if (mode is DemoMode) ...demoOverrides(demoHistory, preferences),
      ],
    ),
  );
  await settle(tester);
  return sound;
}

/// Avanza lo justo para terminar transiciones de página y diálogos, sin
/// `pumpAndSettle` (Monitoreo tiene temporizadores).
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

ProviderContainer demoContainer(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(Navigator).first));

GoRouter demoRouter(WidgetTester tester) =>
    demoContainer(tester).read(routerProvider);

/// Pulsa el botón con [label] después de hacerlo visible.
Future<void> tapLabel(WidgetTester tester, String label) async {
  final f = find.text(label).last;
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f);
  await settle(tester);
}

/// Lleva el recorrido hasta Preparación lista para iniciar, con la lógica de
/// la app (sin pulsaciones).
Future<void> driveToReadyPreparation(WidgetTester tester) async {
  final c = demoContainer(tester);
  c.read(preparationProvider.notifier).open();
  c.read(preparationProvider.notifier).acceptCalibration();
  await c.read(preparationProvider.notifier).testSound();
  c.read(preparationProvider.notifier).confirmHeard();
  demoRouter(tester).go(VigiaRoutes.preparacion);
  await settle(tester);
}

/// Sesión activa confirmada en Monitoreo.
Future<void> driveToMonitoring(WidgetTester tester) async {
  await driveToReadyPreparation(tester);
  final c = demoContainer(tester);
  expect(c.read(demoSessionProvider.notifier).requestStart(), isTrue);
  demoRouter(tester).go(VigiaRoutes.monitoreo);
  await settle(tester);
  await tester.pump(demoConfirm);
}

/// Calibración en una fase concreta.
Future<void> driveToCalibration(
  WidgetTester tester, {
  bool acquiring = false,
  CalibrationRejection? rejected,
  bool accepted = false,
}) async {
  final c = demoContainer(tester);
  c.read(preparationProvider.notifier).open();
  demoRouter(tester).go(VigiaRoutes.preparacion);
  await settle(tester);
  c.read(calibrationProvider.notifier).open();
  demoRouter(tester).go(VigiaRoutes.calibracion);
  await settle(tester);
  final cal = c.read(calibrationProvider.notifier);
  if (acquiring || rejected != null || accepted) cal.begin();
  if (rejected != null) cal.simulateRejected(rejected);
  if (accepted) cal.simulateAccepted();
  await settle(tester);
}

/// Cierra la app y la vuelve a abrir sobre la misma base, con otra instancia
/// del repositorio (como al reabrir el proceso): el estado en memoria se
/// pierde y se aplica la recuperación de sesiones interrumpidas.
Future<FakeSoundPlayer> restartDemo(
  WidgetTester tester, {
  bool themeFromPreferences = false,
}) async {
  await tester.pumpWidget(const SizedBox());
  return pumpDemo(
    tester,
    demoConfig,
    database: demoDatabase,
    themeFromPreferences: themeFromPreferences,
  );
}

/// Sesión completa con una pausa: 12 s activos, 5 s en pausa, cierre.
Future<String> finishDemoSession(WidgetTester tester) async {
  await driveToMonitoring(tester);
  await tester.pump(const Duration(seconds: 12));
  final s = demoContainer(tester).read(demoSessionProvider.notifier);
  s.requestPause();
  await tester.pump(demoConfirm);
  await tester.pump(const Duration(seconds: 5));
  s.requestFinish();
  await tester.pump(demoConfirm);
  await settle(tester);
  return demoContainer(tester).read(demoSessionProvider).sessionId!;
}

/// Sesión que queda sin cierre: 22 s activos (cierre ocular abierto) y la app
/// se cierra. Devuelve su ID.
Future<String> interruptDemoSession(WidgetTester tester) async {
  await driveToMonitoring(tester);
  await tester.pump(const Duration(seconds: 22));
  final id = demoContainer(tester).read(demoSessionProvider).sessionId!;
  await restartDemo(tester);
  return id;
}
