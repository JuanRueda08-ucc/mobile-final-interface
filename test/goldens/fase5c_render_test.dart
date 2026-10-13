@Tags(['render'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_engine/monitoring_engine.dart';
import 'package:vigia/app/app_config.dart';
import 'package:vigia/app/vigia_app.dart';
import 'package:vigia/features/camera/front_camera_controller.dart';
import 'package:vigia/features/experimental/experimental_monitoring_controller.dart';

import '../support/fake_camera.dart';
import '../support/fake_experimental.dart';
import '../support/vigia_harness.dart';

/// Renderizados del «Monitoreo experimental» (fase 5C) con dobles del motor:
/// no hay cámara, modelo ni decisiones reales; la textura se dibuja vacía y
/// cada estado lo fija la prueba. 360×2400 lógicos, texto 100 %, claro y
/// oscuro.
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
  };

  for (final MapEntry(key: id, value: snap) in states.entries) {
    for (final dark in [false, true]) {
      final name = 'F5C_${id}__${dark ? 'oscuro' : 'claro'}_360_100';
      testWidgets(name, (tester) async {
        final camera = FakeFrontCameraBridge(
          permission: CameraPermissionStatus.granted,
        );
        final engine = FakeExperimentalBridge(snap);
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
        camera.emitFace(face);
        await tester.pump();
        await tester.pump();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('fase5c/$name.png'),
        );
        camera.emitFace(FaceAnalysisStatus.stopped);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 4));
      });
    }
  }
}
