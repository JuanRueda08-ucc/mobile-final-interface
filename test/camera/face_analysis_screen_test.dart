import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_engine/monitoring_engine.dart';
import 'package:vigia/app/app_config.dart';
import 'package:vigia/app/vigia_app.dart';
import 'package:vigia/core/design_system/widgets/vigia_button.dart';
import 'package:vigia/features/camera/front_camera_controller.dart';

import '../support/fake_camera.dart';
import '../support/vigia_harness.dart';

/// Fase 5B · presencia facial en la pantalla «Cámara frontal», con el doble
/// del motor (sin cámara ni modelo reales; la textura se dibuja vacía).
void main() {
  setUpAll(loadVigiaFonts);

  late FakeFrontCameraBridge bridge;

  // El doble se crea dentro de cada prueba: sus eventos deben programarse en
  // la zona de reloj simulado de `testWidgets`.
  Future<void> pumpCamera(WidgetTester tester) async {
    bridge = FakeFrontCameraBridge(permission: CameraPermissionStatus.granted);
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(360, 1600) * 2;
    addTearDown(tester.view.reset);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(
      VigiaApp(
        mode: const RealMode(),
        overrides: [frontCameraBridgeProvider.overrideWithValue(bridge)],
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Comprobar cámara'));
    await tester.tap(find.text('Comprobar cámara'));
    await tester.pumpAndSettle();
  }

  Future<void> emit(
    WidgetTester tester,
    FaceAnalysisStatus status, {
    String? errorCode,
  }) async {
    bridge.emitFace(status, errorCode: errorCode);
    // El evento se entrega en una microtarea; el segundo fotograma lo dibuja.
    await tester.pump();
    await tester.pump();
  }

  Finder inRow(String rowKey, String text) =>
      find.descendant(of: find.byKey(Key(rowKey)), matching: find.text(text));

  bool enabled(WidgetTester tester, String label) =>
      tester
          .widget<VigiaButton>(find.widgetWithText(VigiaButton, label))
          .onPressed !=
      null;

  /// Ningún texto de la pantalla usa porcentajes, «Seguro» ni «Puedes
  /// conducir» (RF10, UX07), ni el rótulo DEMO.
  void expectNoForbiddenText(WidgetTester tester) {
    final texts = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
        .join('\n');
    expect(texts, isNot(contains('%')));
    expect(texts.toLowerCase(), isNot(contains('seguro')));
    expect(texts.toLowerCase(), isNot(contains('puedes conducir')));
    expect(texts, isNot(contains('DEMO')));
  }

  testWidgets('identifica la detección facial en pruebas; Calibrar e Iniciar '
      'siguen deshabilitados aunque haya un rostro', (tester) async {
    await pumpCamera(tester);
    expect(find.text('Detección facial en pruebas'), findsWidgets);
    expect(inRow('row-model', 'Cargando el modelo…'), findsOneWidget);
    await emit(tester, FaceAnalysisStatus.waitingResults);
    expect(inRow('row-model', 'Cargado'), findsOneWidget);
    expect(inRow('row-face', 'Esperando resultados…'), findsOneWidget);
    await emit(tester, FaceAnalysisStatus.oneFace);
    expect(inRow('row-face', 'Rostro detectado'), findsOneWidget);
    expect(
      inRow('row-face', 'Presencia facial no equivale a ojos medibles.'),
      findsOneWidget,
    );
    expect(find.text('Detección de fatiga pendiente'), findsWidgets);
    expect(enabled(tester, 'Calibrar'), isFalse);
    expect(enabled(tester, 'Iniciar monitoreo'), isFalse);
    expectNoForbiddenText(tester);
    await emit(tester, FaceAnalysisStatus.stopped);
  });

  testWidgets('sin rostro y varios rostros, con su propio texto', (
    tester,
  ) async {
    await pumpCamera(tester);
    await emit(tester, FaceAnalysisStatus.noFace);
    expect(inRow('row-face', 'Rostro no detectado'), findsOneWidget);
    await emit(tester, FaceAnalysisStatus.multipleFaces);
    expect(inRow('row-face', 'Varios rostros detectados'), findsOneWidget);
    expect(enabled(tester, 'Calibrar'), isFalse);
    expectNoForbiddenText(tester);
    await emit(tester, FaceAnalysisStatus.stopped);
  });

  testWidgets('sin noticias durante 3 s: «Esperando resultados…» y la causa, '
      'no el último rostro', (tester) async {
    await pumpCamera(tester);
    await emit(tester, FaceAnalysisStatus.oneFace);
    await tester.pump(const Duration(milliseconds: 3000));
    expect(inRow('row-face', 'Rostro detectado'), findsNothing);
    expect(inRow('row-face', 'Esperando resultados…'), findsOneWidget);
    expect(
      inRow('row-face', 'El último resultado caducó y ya no se muestra.'),
      findsOneWidget,
    );
    await emit(tester, FaceAnalysisStatus.stopped);
  });

  testWidgets('modelo alterado: «Modelo no disponible» y «Reintentar carga» '
      'pide el reinicio (ER04)', (tester) async {
    await pumpCamera(tester);
    await emit(
      tester,
      FaceAnalysisStatus.modelError,
      errorCode: 'modelCorrupt',
    );
    expect(inRow('row-model', 'Modelo no disponible'), findsOneWidget);
    expect(
      inRow(
        'row-model',
        'El archivo del modelo no coincide con el verificado.',
      ),
      findsOneWidget,
    );
    expect(inRow('row-face', 'Sin análisis'), findsOneWidget);
    await tester.ensureVisible(find.text('Reintentar carga'));
    await tester.tap(find.text('Reintentar carga'));
    await tester.pump();
    expect(bridge.restarts, 1);
    await emit(tester, FaceAnalysisStatus.stopped);
  });

  testWidgets('error de inferencia: «Error de análisis» y «Reintentar»', (
    tester,
  ) async {
    await pumpCamera(tester);
    await emit(
      tester,
      FaceAnalysisStatus.analysisError,
      errorCode: 'inferenceFailed',
    );
    expect(inRow('row-face', 'Error de análisis'), findsOneWidget);
    expect(inRow('row-model', 'Cargado'), findsOneWidget);
    await tester.ensureVisible(
      find.descendant(
        of: find.byKey(const Key('row-face')),
        matching: find.text('Reintentar'),
      ),
    );
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('row-face')),
        matching: find.text('Reintentar'),
      ),
    );
    await tester.pump();
    expect(bridge.restarts, 1);
    await emit(tester, FaceAnalysisStatus.stopped);
  });

  testWidgets('volver a Inicio cierra cámara y análisis', (tester) async {
    await pumpCamera(tester);
    final token = bridge.openTokens.single;
    await emit(tester, FaceAnalysisStatus.oneFace);
    await tester.tap(find.bySemanticsLabel('Volver'));
    await tester.pumpAndSettle();
    expect(bridge.calls, contains('close:$token'));
    expect(bridge.openTokens, isEmpty);
  });

  testWidgets('canal sin respuesta tras un aviso de carga: se ve la causa del '
      'canal y el modelo sin estado conocido (revisión 5B)', (tester) async {
    await pumpCamera(tester);
    bridge.holdQueries = true;
    await emit(tester, FaceAnalysisStatus.loadingModel);
    expect(inRow('row-model', 'Cargando el modelo…'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump();
    expect(
      find.descendant(
        of: find.byKey(const Key('row-face')),
        matching: find.textContaining('El motor no responde a las consultas.'),
      ),
      findsOneWidget,
    );
    expect(
      inRow('row-model', 'Estado del modelo no disponible'),
      findsOneWidget,
    );
    expect(find.text('Cargando el modelo…'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    bridge.releaseQueriesWith(null);
    await tester.pump();
  });
}
