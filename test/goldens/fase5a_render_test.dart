@Tags(['render'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_engine/monitoring_engine.dart';
import 'package:vigia/app/app_config.dart';
import 'package:vigia/app/vigia_app.dart';
import 'package:vigia/features/camera/front_camera_controller.dart';

import '../support/fake_camera.dart';
import '../support/vigia_harness.dart';

/// Renderizados de la pantalla «Cámara frontal» (fase 5A), con un doble del
/// motor: no hay cámara real y la textura de la vista previa se dibuja vacía
/// (la imagen real se comprueba en el emulador). 360×1700 lógicos, texto
/// 100 %, claro y oscuro.
///
///   flutter test --update-goldens test/goldens/fase5a_render_test.dart
void main() {
  setUpAll(loadVigiaFonts);

  // Estado → preparación del doble y acción tras entrar.
  final states =
      <
        String,
        (
          void Function(FakeFrontCameraBridge),
          Future<void> Function(WidgetTester, FakeFrontCameraBridge)?,
        )
      >{
        'explicacion_previa': ((b) {}, null),
        'permiso_rechazado': (
          (b) => b.requestAnswer = CameraPermissionStatus.denied,
          (t, b) => _tap(t, 'Permitir cámara'),
        ),
        'rechazo_exige_ajustes': (
          (b) => b.requestAnswer = CameraPermissionStatus.requiresSettings,
          (t, b) => _tap(t, 'Permitir cámara'),
        ),
        'abriendo': (
          (b) => b
            ..permission = CameraPermissionStatus.granted
            ..openAnswer = null,
          null,
        ),
        'camara_disponible': (
          (b) => b.permission = CameraPermissionStatus.granted,
          null,
        ),
        'sin_camara_frontal': (
          (b) => b
            ..permission = CameraPermissionStatus.granted
            ..openAnswer = PreviewOpenStatus.noFrontCamera,
          null,
        ),
        'fallo_del_canal': (
          (b) => b.checkError = PlatformException(code: 'channel-error'),
          null,
        ),
        'camara_ocupada': (
          (b) => b
            ..permission = CameraPermissionStatus.granted
            ..openAnswer = PreviewOpenStatus.cameraInUse,
          null,
        ),
        'cerrada_segundo_plano': (
          (b) => b.permission = CameraPermissionStatus.granted,
          (t, b) async {
            b.emitClosed(b.openTokens.single, PreviewCloseReason.background);
            await t.pumpAndSettle();
          },
        ),
      };

  for (final MapEntry(key: id, value: (setup, after)) in states.entries) {
    for (final dark in [false, true]) {
      final name = 'F5A_camara_${id}__${dark ? 'oscuro' : 'claro'}_360_100';
      testWidgets(name, (tester) async {
        final bridge = FakeFrontCameraBridge();
        setup(bridge);
        tester.view.devicePixelRatio = 2;
        tester.view.physicalSize = const Size(360, 1700) * 2;
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
        await _tap(tester, 'Comprobar cámara');
        if (after != null) await after(tester, bridge);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('fase5a/$name.png'),
        );
      });
    }
  }
}

Future<void> _tap(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
  // Vuelve arriba para que el renderizado empiece por el encabezado.
  await tester.drag(find.byType(Scrollable).first, const Offset(0, 4000));
  await tester.pumpAndSettle();
}
