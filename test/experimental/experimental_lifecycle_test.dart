import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_engine/monitoring_engine.dart';
import 'package:vigia/app/app_config.dart';
import 'package:vigia/app/vigia_app.dart';
import 'package:vigia/features/camera/front_camera_controller.dart';
import 'package:vigia/features/camera/front_camera_screen.dart';
import 'package:vigia/features/experimental/experimental_monitoring_controller.dart';
import 'package:vigia/features/experimental/experimental_monitoring_screen.dart';

import '../support/fake_camera.dart';
import '../support/fake_experimental.dart';
import '../support/vigia_harness.dart';

class LostStartBridge extends FakeExperimentalBridge {
  LostStartBridge(super.initial);
  final reply = Completer<MonitoringCommandResult>();
  @override
  Future<MonitoringCommandResult> startSession(String cal, String sound) =>
      reply.future;
}

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
    'reanudación pendiente muestra la vista para poder centrar el rostro',
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
      expect(find.byType(FrontCameraStage), findsNothing);
      expect(camera.calls.where((x) => x.startsWith('open:')), isEmpty);
      engine.next = fakeSnapshot(
        lifecycle: EngineSessionLifecycle.paused,
        resumePending: true,
        sessionId: 's1',
      );
      await tester.tap(find.text('Reanudar'));
      await tester.pumpAndSettle();
      expect(camera.calls.where((x) => x.startsWith('open:')), hasLength(1));
      expect(find.byType(FrontCameraStage), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 4));
    },
  );

  testWidgets(
    'inicio sin respuesta: sesión confirmada y finalizada permite salir del resumen',
    (tester) async {
      final camera = FakeFrontCameraBridge(
        permission: CameraPermissionStatus.granted,
      );
      final engine = LostStartBridge(
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
      await tester.tap(find.byKey(const Key('start')));
      await tester.pump();
      // El motor inició; se perdió exclusivamente la respuesta de la orden.
      engine.emit(
        fakeSnapshot(
          sequence: 20,
          lifecycle: EngineSessionLifecycle.active,
          sessionId: 's1',
        ),
      );
      await tester.pump(const Duration(milliseconds: 800));
      engine.next = fakeSnapshot(
        lifecycle: EngineSessionLifecycle.finalized,
        sessionId: 's1',
      );
      await tester.tap(find.byKey(const Key('finish')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Finalizar').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('summary')), findsOneWidget);
      expect(engine.reply.isCompleted, isFalse);
      await tester.tap(find.bySemanticsLabel('Volver').first);
      await tester.pumpAndSettle();
      final exited = !tester.any(find.byType(ExperimentalMonitoringScreen));
      await tester.pumpWidget(const SizedBox());
      engine.reply.complete(
        MonitoringCommandResult(accepted: true, snapshot: engine.current),
      );
      await tester.pump();
      expect(exited, isTrue);
    },
  );

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
    // Sigue incierto tras el timeout: no hay una sesión confirmada/finalizada.
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
