import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_engine/monitoring_engine.dart';
import 'package:vigia/app/app_config.dart';
import 'package:vigia/app/vigia_app.dart';
import 'package:vigia/features/camera/front_camera_controller.dart';
import 'package:vigia/features/experimental/experimental_monitoring_controller.dart';
import 'package:vigia/features/experimental/experimental_monitoring_screen.dart';

import '../support/fake_camera.dart';
import '../support/fake_experimental.dart';
import '../support/vigia_harness.dart';

void main() {
  setUpAll(loadVigiaFonts);
  Future<void> open(
    WidgetTester tester,
    FakeFrontCameraBridge camera,
    FakeExperimentalBridge engine,
  ) async {
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(360, 2400) * 2;
    addTearDown(tester.view.reset);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(
      VigiaApp(
        mode: const RealMode(),
        overrides: [
          frontCameraBridgeProvider.overrideWithValue(camera),
          experimentalBridgeProvider.overrideWithValue(engine),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-experimental')));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'reentrar con sesión pausada no abre la cámara, tampoco al volver de segundo plano',
    (tester) async {
      final camera = FakeFrontCameraBridge(
        permission: CameraPermissionStatus.granted,
      );
      final engine = FakeExperimentalBridge(
        fakeSnapshot(
          sequence: 2,
          lifecycle: EngineSessionLifecycle.paused,
          sessionId: 's1',
        ),
      );
      await open(tester, camera, engine);
      for (final phase in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(phase);
        await tester.pump();
      }
      final opens = camera.calls.where((x) => x.startsWith('open:')).length;
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 4));
      expect(opens, 0);
    },
  );

  testWidgets('iniciar pendiente impide salir antes de conocer su resultado', (
    tester,
  ) async {
    final camera = FakeFrontCameraBridge(
      permission: CameraPermissionStatus.granted,
    );
    final engine = FakeExperimentalBridge(
      fakeSnapshot(
        sequence: 2,
        eyesValid: true,
        step: CalibrationStep.accepted,
        calibrationId: 'cal1',
        soundHeard: true,
        soundTestPlayed: true,
        soundTestId: 'sound1',
      ),
    );
    await open(tester, camera, engine);
    engine.hold = Completer<void>();
    await tester.tap(find.byKey(const Key('start')));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('Volver').first);
    await tester.pumpAndSettle();
    final stillThere = tester.any(find.byType(ExperimentalMonitoringScreen));
    engine.release();
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 4));
    expect(stillThere, isTrue);
  });
}
