@Tags(['render'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_engine/monitoring_engine.dart';
import 'package:vigia/app/app_config.dart';
import 'package:vigia/app/vigia_app.dart';
import 'package:vigia/features/camera/front_camera_controller.dart';

import '../support/fake_camera.dart';
import '../support/vigia_harness.dart';

/// Renderizados de la detección facial en pruebas (fase 5B) en «Cámara
/// frontal», con el doble del motor: no hay cámara ni modelo reales, la
/// textura se dibuja vacía y cada estado lo emite la prueba. 360×2100
/// lógicos, texto 100 %, claro y oscuro.
///
///   flutter test --update-goldens test/goldens/fase5b_render_test.dart
void main() {
  setUpAll(loadVigiaFonts);

  // Estado → resultados que emite el motor (el último es el que se ve).
  final states = <String, List<(FaceAnalysisStatus, String?, bool)>>{
    'cargando_modelo': [],
    'esperando_resultados': [(FaceAnalysisStatus.waitingResults, null, false)],
    'sin_rostro': [(FaceAnalysisStatus.noFace, null, false)],
    'un_rostro': [(FaceAnalysisStatus.oneFace, null, false)],
    'varios_rostros': [(FaceAnalysisStatus.multipleFaces, null, false)],
    'resultado_caducado': [
      (FaceAnalysisStatus.oneFace, null, false),
      (FaceAnalysisStatus.waitingResults, null, true),
    ],
    'modelo_no_disponible': [
      (FaceAnalysisStatus.modelError, 'modelCorrupt', false),
    ],
    'error_de_analisis': [
      (FaceAnalysisStatus.analysisError, 'inferenceFailed', false),
    ],
  };

  for (final MapEntry(key: id, value: emits) in states.entries) {
    for (final dark in [false, true]) {
      final name = 'F5B_camara_${id}__${dark ? 'oscuro' : 'claro'}_360_100';
      testWidgets(name, (tester) async {
        final bridge = FakeFrontCameraBridge(
          permission: CameraPermissionStatus.granted,
        );
        tester.view.devicePixelRatio = 2;
        tester.view.physicalSize = const Size(360, 2100) * 2;
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        await tester.pumpWidget(
          VigiaApp(
            mode: const RealMode(),
            themeMode: dark ? ThemeMode.dark : ThemeMode.light,
            overrides: [frontCameraBridgeProvider.overrideWithValue(bridge)],
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Comprobar cámara'));
        await tester.tap(find.text('Comprobar cámara'));
        await tester.pumpAndSettle();
        for (final (status, code, expired) in emits) {
          bridge.emitFace(status, errorCode: code, expired: expired);
          await tester.pump();
          await tester.pump();
        }
        await tester.drag(find.byType(Scrollable).first, const Offset(0, 4000));
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('fase5b/$name.png'),
        );
        // Cierra la pantalla para no dejar la vigilancia de 3 s pendiente.
        bridge.emitFace(FaceAnalysisStatus.stopped);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
