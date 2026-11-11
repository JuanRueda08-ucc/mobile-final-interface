@Tags(['render'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_engine/monitoring_engine.dart';
import 'package:vigia/app/app_config.dart';
import 'package:vigia/app/vigia_app.dart';
import 'package:vigia/core/design_system/widgets/vigia_blocks.dart';
import 'package:vigia/features/camera/front_camera_controller.dart';
import 'package:vigia/features/experimental/experimental_monitoring_controller.dart';

import '../support/fake_camera.dart';
import '../support/fake_experimental.dart';
import '../support/vigia_harness.dart';

/// Renderizados del «Monitoreo experimental» (fase 5C) con dobles del motor:
/// no hay cámara, modelo ni decisiones reales; la textura se dibuja vacía y
/// cada estado lo fija la prueba. Preparación conserva sus referencias
/// históricas. P06 se verifica en un viewport realista, claro y oscuro,
/// a 360 dp/100 % y 320 dp/200 %.
///
///   flutter test --update-goldens test/goldens/fase5c_render_test.dart
void main() {
  setUpAll(loadVigiaFonts);

  const session = 'S-1';
  final states = <String, MonitoringSnapshot>{
    'preparacion_sin_ojos': fakeSnapshot(
      sequence: 2,
      eyeIssue: 'insufficientEyeResolution',
    ),
    'preparacion_ojos_medibles': fakeSnapshot(
      sequence: 2,
      eyesValid: true,
      earRight: 0.29,
      earLeft: 0.31,
    ),
    'calibracion_referencia': fakeSnapshot(
      sequence: 2,
      eyesValid: true,
      earRight: 0.29,
      earLeft: 0.31,
      step: CalibrationStep.openReference,
      stepElapsedMs: 4200,
      stepDurationMs: 8000,
      stepValidSamples: 61,
    ),
    'calibracion_cierre': fakeSnapshot(
      sequence: 2,
      eyesValid: true,
      earRight: 0.29,
      earLeft: 0.31,
      step: CalibrationStep.closeLeadIn,
      probe: 1,
    ),
    'calibracion_rechazada': fakeSnapshot(
      sequence: 2,
      eyesValid: true,
      earRight: 0.29,
      earLeft: 0.31,
      step: CalibrationStep.rejected,
      calibrationRejection: 'unstableReference',
    ),
    'listo_para_iniciar': fakeSnapshot(
      sequence: 2,
      eyesValid: true,
      earRight: 0.29,
      earLeft: 0.31,
      ratioRight: 0.97,
      ratioLeft: 1.02,
      step: CalibrationStep.accepted,
      calibrationId: 'cal-1',
      openEarRight: 0.30,
      openEarLeft: 0.30,
      calibrationSamples: 118,
      soundTestId: 'snd-1',
      soundTestPlayed: true,
      soundHeard: true,
    ),
    'sesion_inicializando': fakeSnapshot(
      sequence: 2,
      lifecycle: EngineSessionLifecycle.active,
      sessionId: session,
      measurement: EngineMeasurement.initializing,
      measurementCause: null,
      eyeIssue: 'noResults',
      activeMs: 2000,
    ),
    'sesion_sin_senales': fakeSnapshot(
      sequence: 2,
      eyesValid: true,
      earRight: 0.28,
      earLeft: 0.30,
      ratioRight: 0.93,
      ratioLeft: 1.0,
      lifecycle: EngineSessionLifecycle.active,
      sessionId: session,
      measurement: EngineMeasurement.usable,
      signal: EngineSignal.noPersistentSignals,
      activeMs: 64000,
      evaluableMs: 58000,
    ),
    'sesion_cierre_prolongado': fakeSnapshot(
      sequence: 2,
      eyesValid: true,
      earRight: 0.07,
      earLeft: 0.08,
      ratioRight: 0.23,
      ratioLeft: 0.27,
      lifecycle: EngineSessionLifecycle.active,
      sessionId: session,
      measurement: EngineMeasurement.usable,
      signal: EngineSignal.prolongedEyeClosure,
      activeMs: 95000,
      evaluableMs: 88000,
      closureActivations: 1,
      tonesPlayed: 1,
    ),
    'sesion_rostro_perdido': fakeSnapshot(
      sequence: 2,
      eyeIssue: 'noFace',
      lifecycle: EngineSessionLifecycle.active,
      sessionId: session,
      measurement: EngineMeasurement.unavailable,
      measurementCause: 'noFace',
      activeMs: 120000,
      evaluableMs: 100000,
      closureActivations: 1,
      tonesPlayed: 1,
    ),
    'sesion_pausada': fakeSnapshot(
      sequence: 2,
      lifecycle: EngineSessionLifecycle.paused,
      sessionId: session,
      activeMs: 130000,
      evaluableMs: 101000,
      pausedMs: 12000,
      closureActivations: 1,
      tonesPlayed: 1,
    ),
    'sesion_reanudando': fakeSnapshot(
      sequence: 2,
      lifecycle: EngineSessionLifecycle.paused,
      sessionId: session,
      resumePending: true,
      eyeIssue: 'noFace',
    ),
  };

  for (final MapEntry(key: id, value: snap) in states.entries) {
    final isMonitoring = id.startsWith('sesion_');
    final configs = [
      for (final dark in [false, true]) ...[
        ScreenConfig(width: 360, height: isMonitoring ? 800 : 2400, dark: dark),
        if (isMonitoring) ScreenConfig(width: 320, textScale: 2, dark: dark),
      ],
    ];
    for (final config in configs) {
      final name = '${isMonitoring ? 'P06' : 'F5C'}_${id}__${config.id}';
      testWidgets(name, (tester) async {
        final camera = FakeFrontCameraBridge(
          permission: CameraPermissionStatus.granted,
        );
        final engine = FakeExperimentalBridge(snap);
        tester.view.devicePixelRatio = 2;
        tester.view.physicalSize = Size(config.width, config.height) * 2;
        tester.platformDispatcher.textScaleFactorTestValue = config.textScale;
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        await tester.pumpWidget(
          VigiaApp(
            mode: const RealMode(),
            themeMode: config.dark ? ThemeMode.dark : ThemeMode.light,
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
        final face = snap.eyeIssue == 'noFace'
            ? FaceAnalysisStatus.noFace
            : FaceAnalysisStatus.oneFace;
        if (tester.any(find.byType(Texture))) camera.emitFace(face);
        if (isMonitoring) {
          engine.emit(
            MonitoringSnapshot.decode(snap.encode())
              ..sequence = snap.sequence + 1
              ..observationId = null,
          );
        }
        await tester.pump();
        await tester.pump();
        if (isMonitoring) {
          final status = find.byKey(const Key('signal'));
          final controls = find.byKey(const Key('session-controls'));
          final preview = find.byKey(const Key('camera-preview'));
          expect(tester.widget<StatusCard>(status).title, switch (id) {
            'sesion_inicializando' => 'Inicializando medición',
            'sesion_sin_senales' => 'Sin señales persistentes',
            'sesion_cierre_prolongado' => 'Cierre ocular prolongado',
            'sesion_rostro_perdido' => 'No evaluable',
            'sesion_pausada' => 'Monitoreo pausado',
            'sesion_reanudando' => 'Reanudando…',
            _ => throw StateError(id),
          });
          expect(
            tester.getBottomRight(status).dy,
            lessThan(tester.getTopLeft(controls).dy),
          );
          expect(find.byKey(const Key('finish')).hitTestable(), findsOneWidget);
          final paused = snap.lifecycle == EngineSessionLifecycle.paused;
          expect(
            preview,
            paused && !snap.resumePending ? findsNothing : findsOneWidget,
          );
          if (tester.any(preview)) {
            expect(
              tester.getTopLeft(preview).dy,
              greaterThan(tester.getBottomRight(status).dy),
            );
          }
          expect(tester.takeException(), isNull);
        }
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('${isMonitoring ? 'p06' : 'fase5c'}/$name.png'),
        );
        if (isMonitoring) {
          final controls = find.byKey(const Key('session-controls'));
          final rect = tester.getRect(controls);
          await tester.drag(
            find.byType(SingleChildScrollView).first,
            const Offset(0, -450),
          );
          await tester.pumpAndSettle();
          expect(
            tester.getRect(controls),
            rect,
            reason: 'los controles quedan fijos',
          );
        }
        if (tester.any(find.byType(Texture))) {
          camera.emitFace(FaceAnalysisStatus.stopped);
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 4));
      });
    }
  }
}
