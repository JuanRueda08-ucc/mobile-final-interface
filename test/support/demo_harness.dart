import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vigia/app/app_config.dart';
import 'package:vigia/app/router.dart';
import 'package:vigia/app/vigia_app.dart';
import 'package:vigia/core/audio/alert_sound.dart';
import 'package:vigia/core/clock/monotonic_clock.dart';
import 'package:vigia/features/calibration/calibration_controller.dart';
import 'package:vigia/features/monitoring/demo_session_controller.dart';
import 'package:vigia/features/preparation/preparation_controller.dart';

import 'fake_sound.dart';
import 'vigia_harness.dart';

/// Retraso de confirmación del motor simulado (igual al de producción).
const demoConfirm = Duration(milliseconds: 700);

/// Monta la app en modo `VIGIA_DEMO=true` con reloj de `package:clock`
/// (controlado por `testWidgets`) y un reproductor de sonido falso.
Future<FakeSoundPlayer> pumpDemo(
  WidgetTester tester,
  ScreenConfig c, {
  AppMode mode = const DemoMode(),
}) async {
  final sound = FakeSoundPlayer();
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
      themeMode: c.dark ? ThemeMode.dark : ThemeMode.light,
      overrides: [
        monotonicClockProvider.overrideWith((ref) => PackageClock()),
        alertSoundPlayerProvider.overrideWithValue(sound),
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
