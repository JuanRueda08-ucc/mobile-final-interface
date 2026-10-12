import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_engine/monitoring_engine.dart';
import 'package:vigia/app/app_config.dart';
import 'package:vigia/app/router.dart';
import 'package:vigia/app/vigia_app.dart';
import 'package:vigia/core/design_system/widgets/vigia_button.dart';
import 'package:vigia/features/camera/front_camera_controller.dart';
import 'package:vigia/features/camera/front_camera_screen.dart';
import 'package:vigia/features/inicio/inicio_state.dart';
import 'package:vigia/features/monitoring/demo_session_controller.dart';

import '../support/fake_camera.dart';
import '../support/vigia_harness.dart';

/// Fase 5A · pantalla «Cámara frontal» y su acceso desde Inicio, con un doble
/// del motor. No hay cámara real: la vista previa es una textura vacía.
void main() {
  setUpAll(loadVigiaFonts);

  late FakeFrontCameraBridge bridge;

  Future<void> pumpReal(WidgetTester tester) async {
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
  }

  Future<void> openCamera(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Comprobar cámara'));
    await tester.tap(find.text('Comprobar cámara'));
    await tester.pumpAndSettle();
  }

  bool enabled(WidgetTester tester, String label) =>
      tester
          .widget<VigiaButton>(find.widgetWithText(VigiaButton, label))
          .onPressed !=
      null;

  setUp(() => bridge = FakeFrontCameraBridge());

  testWidgets('Inicio normal ofrece «Comprobar cámara» sin pedir permiso', (
    tester,
  ) async {
    await pumpReal(tester);
    expect(find.text('Comprobar cámara'), findsOneWidget);
    expect(bridge.calls, isEmpty);
    await openCamera(tester);
    expect(find.text('Cámara frontal'), findsWidgets);
    // Entrar consulta el permiso, pero no lo solicita hasta la pulsación.
    expect(bridge.calls, ['check']);
    expect(find.text('Permitir cámara'), findsOneWidget);
    expect(find.text('Cámara sin permiso'), findsWidgets);
  });

  testWidgets('permiso concedido y cámara abierta: «Cámara disponible», '
      '«Detección de fatiga pendiente» y Calibrar/Iniciar deshabilitados', (
    tester,
  ) async {
    bridge.requestAnswer = CameraPermissionStatus.granted;
    await pumpReal(tester);
    await openCamera(tester);
    await tester.tap(find.text('Permitir cámara'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('camera-preview')), findsOneWidget);
    expect(find.byType(Texture), findsOneWidget);
    expect(find.text('Cámara disponible'), findsOneWidget);
    expect(find.text('Detección de fatiga pendiente'), findsWidgets);
    expect(find.textContaining('DEMO'), findsNothing);
    expect(enabled(tester, 'Calibrar'), isFalse);
    expect(enabled(tester, 'Iniciar monitoreo'), isFalse);
  });

  testWidgets('sin cámara frontal: lo dice y no muestra vista previa', (
    tester,
  ) async {
    bridge
      ..permission = CameraPermissionStatus.granted
      ..openAnswer = PreviewOpenStatus.noFrontCamera;
    await pumpReal(tester);
    await openCamera(tester);
    expect(find.text('Cámara frontal no encontrada'), findsWidgets);
    expect(find.byType(Texture), findsNothing);
    expect(find.text('Cámara disponible'), findsNothing);
  });

  testWidgets('rechazo o diálogo descartado: se puede volver a solicitar y '
      'los ajustes son una alternativa, sin afirmar bloqueo', (tester) async {
    bridge.requestAnswer = CameraPermissionStatus.denied;
    await pumpReal(tester);
    await openCamera(tester);
    await tester.tap(find.text('Permitir cámara'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Android ya no muestra'), findsNothing);
    expect(enabled(tester, 'Permitir cámara'), isTrue);
    expect(enabled(tester, 'Abrir ajustes'), isTrue);
    await tester.ensureVisible(find.text('Permitir cámara'));
    await tester.tap(find.text('Permitir cámara'));
    await tester.pumpAndSettle();
    expect(bridge.requests, 2);
  });

  testWidgets('fallo del canal: lo dice y Reintentar consulta de nuevo', (
    tester,
  ) async {
    bridge.checkError = PlatformException(code: 'channel-error');
    await pumpReal(tester);
    await openCamera(tester);
    expect(find.text('Estado de la cámara no disponible'), findsOneWidget);
    expect(find.text('Permiso sin comprobar'), findsOneWidget);
    bridge.checkError = null;
    await tester.ensureVisible(find.text('Reintentar'));
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(bridge.calls.where((c) => c == 'check'), hasLength(2));
    expect(find.text('Permitir cámara'), findsOneWidget);
  });

  testWidgets('rechazo permanente: «Abrir ajustes»', (tester) async {
    bridge.requestAnswer = CameraPermissionStatus.requiresSettings;
    await pumpReal(tester);
    await openCamera(tester);
    await tester.tap(find.text('Permitir cámara'));
    await tester.pumpAndSettle();
    expect(find.text('Abrir ajustes'), findsOneWidget);
    await tester.tap(find.text('Abrir ajustes'));
    await tester.pumpAndSettle();
    expect(bridge.settingsOpened, isTrue);
  });

  testWidgets('volver a Inicio libera la cámara', (tester) async {
    bridge.permission = CameraPermissionStatus.granted;
    await pumpReal(tester);
    await openCamera(tester);
    expect(bridge.openTokens, hasLength(1));
    await tester.tap(find.bySemanticsLabel('Volver'));
    await tester.pumpAndSettle();
    expect(find.text('Comprobar cámara'), findsOneWidget);
    expect(bridge.openTokens, isEmpty);
  });

  testWidgets('segundo plano libera la cámara y al volver se reabre', (
    tester,
  ) async {
    bridge.permission = CameraPermissionStatus.granted;
    await pumpReal(tester);
    await openCamera(tester);
    final binding = tester.binding;
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await tester.pumpAndSettle();
    expect(bridge.openTokens, isEmpty);
    // Oculta, la app no dibuja cuadros: se comprueba el estado, no el árbol.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(FrontCameraScreen)),
    );
    expect(
      container.read(frontCameraProvider).phase,
      CameraCheckPhase.suspended,
    );
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(bridge.openTokens, hasLength(1));
    expect(find.byType(Texture), findsOneWidget);
    expect(bridge.opens, 2);
  });

  group('separación DEMO', () {
    test('la ruta de cámara solo existe en la variante normal', () {
      const none = DemoSessionState();
      expect(
        vigiaRedirect(
          mode: const RealMode(),
          session: none,
          canCalibrate: false,
          location: VigiaRoutes.camara,
        ),
        isNull,
      );
      expect(
        vigiaRedirect(
          mode: const DemoMode(),
          session: none,
          canCalibrate: true,
          location: VigiaRoutes.camara,
        ),
        VigiaRoutes.inicio,
      );
      expect(
        vigiaRedirect(
          mode: const InicioReviewMode(InicioSinHistorial(isDemo: true)),
          session: none,
          canCalibrate: false,
          location: VigiaRoutes.camara,
        ),
        VigiaRoutes.inicio,
      );
    });

    testWidgets('las vistas de revisión de Inicio no ofrecen la cámara', (
      tester,
    ) async {
      await pumpVigia(
        tester,
        const InicioMotorDesconocido(isDemo: true),
        const ScreenConfig(width: 360),
      );
      expect(find.text('Comprobar cámara'), findsNothing);
    });
  });
}
