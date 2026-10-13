import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_engine/monitoring_engine.dart';
import 'package:vigia/app/app_config.dart';
import 'package:vigia/app/router.dart';
import 'package:vigia/app/vigia_app.dart';
import 'package:vigia/core/design_system/widgets/vigia_button.dart';
import 'package:vigia/features/camera/front_camera_controller.dart';
import 'package:vigia/features/experimental/experimental_monitoring_controller.dart';
import 'package:vigia/features/experimental/experimental_monitoring_screen.dart';
import 'package:vigia/features/monitoring/demo_session_controller.dart';

import '../support/fake_camera.dart';
import '../support/fake_experimental.dart';
import '../support/vigia_harness.dart';

/// Fase 5C · presentación del recorrido experimental con dobles del motor.
/// **No hay cámara, modelo ni decisiones reales**: cada estado lo fija la
/// prueba. Las señales se deciden en Kotlin (`ExperimentalMonitoringTest`,
/// JVM) y el recorrido real se comprueba en Android.
void main() {
  group('controlador', () {
    late FakeExperimentalBridge bridge;
    late ProviderContainer c;

    setUp(() {
      bridge = FakeExperimentalBridge();
      c = ProviderContainer(
        overrides: [experimentalBridgeProvider.overrideWithValue(bridge)],
      );
      addTearDown(c.dispose);
    });

    ExperimentalState st() => c.read(experimentalMonitoringProvider);
    ExperimentalMonitoringController ctl() =>
        c.read(experimentalMonitoringProvider.notifier);

    test('acepta estados en orden y otra instancia del motor', () {
      fakeAsync((async) {
        ctl();
        bridge.emit(fakeSnapshot(sequence: 5, eyesValid: true));
        async.flushMicrotasks();
        expect(st().snapshot!.sequence, 5);
        bridge.emit(fakeSnapshot(sequence: 4));
        bridge.emit(fakeSnapshot(sequence: 5));
        async.flushMicrotasks();
        expect(st().snapshot!.eyesValid, isTrue, reason: 'atrasados');
        bridge.emit(fakeSnapshot(engine: 'motor-2', sequence: 1));
        async.flushMicrotasks();
        expect(st().snapshot!.engineInstanceId, 'motor-2');
        async.elapse(const Duration(seconds: 4));
      });
    });

    test('3000 ms sin mensajes: sin conexión y sin señal, aunque el último '
        'estado dijera cierre prolongado', () {
      fakeAsync((async) {
        ctl();
        bridge.emit(
          fakeSnapshot(
            lifecycle: EngineSessionLifecycle.active,
            sessionId: 's1',
            signal: EngineSignal.prolongedEyeClosure,
          ),
        );
        async.flushMicrotasks();
        expect(st().signal, EngineSignal.prolongedEyeClosure);
        async.elapse(const Duration(milliseconds: 2999));
        expect(st().connected, isTrue);
        async.elapse(const Duration(milliseconds: 1));
        expect(st().connected, isFalse);
        expect(st().signal, EngineSignal.notEvaluable);
      });
    });

    test(
      'pulsaciones repetidas comparten una orden; el rechazo se conserva',
      () {
        fakeAsync((async) {
          bridge.hold = Completer.sync();
          bridge.rejectNext = 'cameraNotReady';
          for (var i = 0; i < 5; i++) {
            ctl().beginCalibration();
          }
          async.flushMicrotasks();
          expect(bridge.calls.where((x) => x == 'calibrate'), hasLength(1));
          expect(st().pending, 'calibrate');
          bridge.release();
          async.flushMicrotasks();
          expect(st().pending, isNull);
          expect(st().rejection, 'cameraNotReady');
          async.elapse(const Duration(seconds: 4));
        });
      },
    );

    test('iniciar usa la referencia y la prueba de sonido del motor', () {
      fakeAsync((async) {
        ctl();
        bridge.emit(
          fakeSnapshot(
            calibrationId: 'cal-7',
            step: CalibrationStep.accepted,
            soundTestId: 'snd-3',
            soundTestPlayed: true,
            soundHeard: true,
          ),
        );
        async.flushMicrotasks();
        ctl().start();
        async.flushMicrotasks();
        expect(bridge.calls.last, 'start:cal-7:snd-3');
        async.elapse(const Duration(seconds: 4));
      });
    });
  });

  group('pantalla', () {
    setUpAll(loadVigiaFonts);

    late FakeFrontCameraBridge camera;
    late FakeExperimentalBridge engine;

    Future<void> open(WidgetTester tester, MonitoringSnapshot initial) async {
      camera = FakeFrontCameraBridge(
        permission: CameraPermissionStatus.granted,
      );
      engine = FakeExperimentalBridge(initial);
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
      await tester.ensureVisible(find.byKey(const Key('open-experimental')));
      await tester.tap(find.byKey(const Key('open-experimental')));
      await tester.pumpAndSettle();
      camera.emitFace(FaceAnalysisStatus.oneFace);
      await tester.pump();
      await tester.pump();
    }

    Future<void> emit(WidgetTester tester, MonitoringSnapshot s) async {
      engine.emit(s);
      await tester.pump();
      await tester.pump();
    }

    bool enabled(WidgetTester tester, Key key) =>
        tester.widget<VigiaButton>(find.byKey(key)).onPressed != null;

    Future<void> close(WidgetTester tester) async {
      // Si la pantalla ya cerró la cámara, no hay apertura a la que avisar.
      if (tester.any(find.byKey(const Key('camera-preview')))) {
        camera.emitFace(FaceAnalysisStatus.stopped);
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 4));
    }

    testWidgets('rotulado experimental; sin ojos medibles no se calibra ni '
        'inicia; abre la cámara real (doble)', (tester) async {
      await open(tester, fakeSnapshot(sequence: 2, eyeIssue: 'noFace'));
      expect(find.text(ExperimentalMonitoringScreen.title), findsWidgets);
      expect(find.byKey(const Key('experimental-banner')), findsOneWidget);
      expect(find.text('Rostro no detectado.'), findsOneWidget);
      expect(enabled(tester, const Key('calibrate')), isFalse);
      expect(enabled(tester, const Key('start')), isFalse);
      expect(camera.calls.where((x) => x.startsWith('open:')), hasLength(1));
      expect(find.textContaining('DEMO'), findsNothing);
      expect(find.textContaining('%'), findsNothing);
      await close(tester);
    });

    testWidgets('ojos medibles: EAR visible y Calibrar habilitado; pasos de '
        'la calibración', (tester) async {
      await open(tester, fakeSnapshot(sequence: 2));
      await emit(
        tester,
        fakeSnapshot(
          sequence: 3,
          eyesValid: true,
          earRight: 0.29,
          earLeft: 0.31,
        ),
      );
      expect(find.text('Der. 0,29 · Izq. 0,31'), findsOneWidget);
      expect(enabled(tester, const Key('calibrate')), isTrue);
      await tester.tap(find.byKey(const Key('calibrate')));
      await tester.pump();
      expect(engine.calls, contains('calibrate'));
      await emit(
        tester,
        fakeSnapshot(
          sequence: 200,
          eyesValid: true,
          step: CalibrationStep.closeLeadIn,
          probe: 1,
        ),
      );
      expect(find.text('Cierra los ojos'), findsOneWidget);
      expect(find.text('Cancelar calibración'), findsOneWidget);
      await emit(
        tester,
        fakeSnapshot(
          sequence: 201,
          eyesValid: true,
          step: CalibrationStep.rejected,
          calibrationRejection: 'insufficientObservations',
        ),
      );
      expect(
        find.text('No hubo suficientes observaciones válidas de los ojos.'),
        findsOneWidget,
      );
      await close(tester);
    });

    testWidgets('iniciar exige calibración y sonido confirmados; el cierre '
        'prolongado se muestra; pausar y finalizar liberan la cámara', (
      tester,
    ) async {
      final ready = fakeSnapshot(
        sequence: 2,
        eyesValid: true,
        earRight: 0.3,
        earLeft: 0.3,
        step: CalibrationStep.accepted,
        calibrationId: 'cal-1',
        openEarRight: 0.3,
        openEarLeft: 0.3,
        calibrationSamples: 120,
        soundTestId: 'snd-1',
        soundTestPlayed: true,
      );
      await open(tester, ready);
      expect(
        enabled(tester, const Key('start')),
        isFalse,
        reason: 'sin «Lo escuché»',
      );
      engine.next = MonitoringSnapshot.decode(ready.encode())
        ..soundHeard = true;
      await tester.tap(find.text('Lo escuché'));
      await tester.pump();
      await tester.pump();
      expect(enabled(tester, const Key('start')), isTrue);
      engine.next = fakeSnapshot(
        eyesValid: true,
        lifecycle: EngineSessionLifecycle.active,
        sessionId: 'S1',
        measurement: EngineMeasurement.initializing,
      );
      await tester.tap(find.byKey(const Key('start')));
      await tester.pump();
      await tester.pump();
      expect(engine.calls, contains('start:cal-1:snd-1'));
      await emit(
        tester,
        fakeSnapshot(
          sequence: 300,
          eyesValid: true,
          lifecycle: EngineSessionLifecycle.active,
          sessionId: 'S1',
          measurement: EngineMeasurement.usable,
          signal: EngineSignal.prolongedEyeClosure,
          closureActivations: 1,
          tonesPlayed: 1,
        ),
      );
      expect(find.text('Cierre ocular prolongado'), findsOneWidget);
      expect(find.text('1 iniciados · 0 fallidos'), findsOneWidget);
      // Salir con sesión vigente no está permitido.
      await tester.tap(find.bySemanticsLabel('Volver').first);
      await tester.pump();
      expect(
        find.text(ExperimentalMonitoringScreen.leaveBlockedNotice),
        findsOneWidget,
      );
      // Pausar: el motor confirma y la pantalla libera la cámara.
      engine.next = fakeSnapshot(
        lifecycle: EngineSessionLifecycle.paused,
        sessionId: 'S1',
      );
      await tester.tap(find.text('Pausar'));
      await tester.pump();
      await tester.pump();
      expect(engine.calls, contains('pause:S1'));
      expect(camera.calls.where((x) => x.startsWith('close:')), isNotEmpty);
      expect(find.text('Monitoreo pausado'), findsOneWidget);
      // Finalizar (D02): resumen en memoria.
      engine.next = fakeSnapshot(
        lifecycle: EngineSessionLifecycle.finalized,
        sessionId: 'S1',
        activeMs: 65000,
        evaluableMs: 50000,
        closureActivations: 1,
        tonesPlayed: 1,
      );
      await tester.tap(find.byKey(const Key('finish')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Finalizar').last);
      await tester.pumpAndSettle();
      expect(engine.calls, contains('stop:S1'));
      expect(find.byKey(const Key('summary')), findsOneWidget);
      expect(find.text('00:01:05'), findsOneWidget);
      await close(tester);
    });

    testWidgets('sin conexión con el motor no se muestra ninguna señal', (
      tester,
    ) async {
      await open(
        tester,
        fakeSnapshot(
          sequence: 2,
          lifecycle: EngineSessionLifecycle.active,
          sessionId: 'S1',
          signal: EngineSignal.prolongedEyeClosure,
        ),
      );
      expect(find.text('Cierre ocular prolongado'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 3100));
      expect(find.text('Cierre ocular prolongado'), findsNothing);
      expect(find.text('Estado del motor no disponible'), findsWidgets);
      await close(tester);
    });

    test('la ruta experimental solo existe en la variante normal', () {
      for (final mode in <AppMode>[const DemoMode(), const RealMode()]) {
        final r = vigiaRedirect(
          mode: mode,
          session: const DemoSessionState(),
          canCalibrate: true,
          location: VigiaRoutes.experimental,
        );
        expect(r, mode is RealMode ? isNull : VigiaRoutes.inicio);
      }
    });
  });
}
