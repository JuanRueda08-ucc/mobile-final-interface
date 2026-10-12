import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_engine/monitoring_engine.dart';
import 'package:vigia/features/camera/front_camera_controller.dart';

import '../support/fake_camera.dart';

/// Fase 5A · controlador de la cámara frontal con un doble del motor
/// ([FakeFrontCameraBridge]). Son pruebas de lógica: no abren ninguna cámara.
void main() {
  late FakeFrontCameraBridge bridge;
  late ProviderContainer container;

  FrontCameraController ctrl() => container.read(frontCameraProvider.notifier);
  FrontCameraState st() => container.read(frontCameraProvider);
  int lastToken() => int.parse(
    bridge.calls.lastWhere((c) => c.startsWith('open:')).split(':')[1],
  );

  setUp(() {
    bridge = FakeFrontCameraBridge();
    container = ProviderContainer(
      overrides: [frontCameraBridgeProvider.overrideWithValue(bridge)],
    );
    addTearDown(container.dispose);
  });

  group('permiso', () {
    test('sin permiso: explica y no solicita ni abre por su cuenta', () async {
      await ctrl().enter();
      expect(st().phase, CameraCheckPhase.explain);
      expect(bridge.requests, 0);
      expect(bridge.opens, 0);
    });

    test('concedido al entrar: abre; «disponible» llega con la apertura, '
        'no con el permiso', () async {
      bridge
        ..permission = CameraPermissionStatus.granted
        ..openAnswer = null;
      final entering = ctrl().enter();
      await pumpEventQueue();
      expect(st().permissionGranted, isTrue);
      expect(st().phase, CameraCheckPhase.opening);
      expect(st().preview, isNull);
      bridge.answerOpen(lastToken(), PreviewOpenStatus.opened);
      await entering;
      expect(st().phase, CameraCheckPhase.available);
      expect(st().preview!.textureId, 7);
      expect(bridge.opens, 1);
    });

    test('solicitud concedida: abre la vista previa', () async {
      bridge.requestAnswer = CameraPermissionStatus.granted;
      await ctrl().enter();
      await ctrl().requestPermission();
      expect(st().phase, CameraCheckPhase.available);
    });

    test(
      'rechazo: «Cámara sin permiso» y se puede volver a solicitar',
      () async {
        bridge.requestAnswer = CameraPermissionStatus.denied;
        await ctrl().enter();
        await ctrl().requestPermission();
        expect(st().phase, CameraCheckPhase.denied);
        expect(bridge.opens, 0);
        await ctrl().requestPermission();
        expect(bridge.requests, 2);
      },
    );

    test('rechazo permanente: exige ajustes; al volver sin permiso el bloqueo '
        'se conserva y con permiso abre', () async {
      bridge.requestAnswer = CameraPermissionStatus.requiresSettings;
      await ctrl().enter();
      await ctrl().requestPermission();
      expect(st().phase, CameraCheckPhase.requiresSettings);

      expect(await ctrl().openSettings(), isTrue);
      ctrl().suspend();
      await ctrl().resume();
      expect(st().phase, CameraCheckPhase.requiresSettings);
      expect(bridge.calls.where((c) => c == 'check').length, 2);

      ctrl().suspend();
      bridge.permission = CameraPermissionStatus.granted;
      await ctrl().resume();
      expect(st().phase, CameraCheckPhase.available);
    });

    test('pulsaciones repetidas comparten una sola solicitud', () async {
      await ctrl().enter();
      final first = ctrl().requestPermission();
      await ctrl().requestPermission();
      await ctrl().requestPermission();
      expect(bridge.requests, 1);
      expect(st().phase, CameraCheckPhase.requesting);
      bridge.answerRequest(CameraPermissionStatus.granted);
      await first;
      expect(st().phase, CameraCheckPhase.available);
      expect(bridge.opens, 1);
    });

    test(
      'revocación: al volver sin permiso no abre y vuelve a explicar',
      () async {
        bridge.permission = CameraPermissionStatus.granted;
        await ctrl().enter();
        expect(st().phase, CameraCheckPhase.available);
        ctrl().suspend();
        bridge.permission = CameraPermissionStatus.denied;
        await ctrl().resume();
        expect(st().phase, CameraCheckPhase.explain);
        expect(st().permissionGranted, isFalse);
        expect(bridge.opens, 1);
        expect(bridge.openTokens, isEmpty);
      },
    );

    test(
      'el motor informa permiso ausente al abrir: no se da por abierta',
      () async {
        bridge
          ..permission = CameraPermissionStatus.granted
          ..openAnswer = PreviewOpenStatus.permissionMissing;
        await ctrl().enter();
        expect(st().phase, CameraCheckPhase.explain);
        expect(st().permissionGranted, isFalse);
      },
    );
  });

  group('estados de la cámara', () {
    for (final (status, phase) in [
      (PreviewOpenStatus.noFrontCamera, CameraCheckPhase.noFrontCamera),
      (PreviewOpenStatus.cameraInUse, CameraCheckPhase.inUse),
      (PreviewOpenStatus.cameraDisabled, CameraCheckPhase.disabled),
      (PreviewOpenStatus.failed, CameraCheckPhase.failed),
    ]) {
      test('$status → $phase, sin vista previa', () async {
        bridge
          ..permission = CameraPermissionStatus.granted
          ..openAnswer = status;
        await ctrl().enter();
        expect(st().phase, phase);
        expect(st().preview, isNull);
        expect(st().permissionGranted, isTrue);
      });
    }

    test('Reintentar tras un fallo abre con un token nuevo', () async {
      bridge
        ..permission = CameraPermissionStatus.granted
        ..openAnswer = PreviewOpenStatus.cameraInUse;
      await ctrl().enter();
      final failedToken = lastToken();
      bridge.openAnswer = PreviewOpenStatus.opened;
      await ctrl().retry();
      expect(st().phase, CameraCheckPhase.available);
      expect(lastToken(), greaterThan(failedToken));
    });
  });

  group('aperturas repetidas, cierre y respuestas antiguas', () {
    setUp(() {
      bridge
        ..permission = CameraPermissionStatus.granted
        ..openAnswer = null;
    });

    test('Reintentar durante la apertura no crea otra', () async {
      final entering = ctrl().enter();
      await pumpEventQueue();
      await ctrl().retry();
      await ctrl().retry();
      expect(bridge.opens, 1);
      bridge.answerOpen(lastToken(), PreviewOpenStatus.opened);
      await entering;
      expect(st().phase, CameraCheckPhase.available);
    });

    test('salir durante la apertura: la respuesta tardía se cierra y no '
        'reactiva la vista', () async {
      final entering = ctrl().enter();
      await pumpEventQueue();
      final token = lastToken();
      ctrl().leave();
      expect(bridge.calls, contains('close:$token'));
      bridge.answerOpen(token, PreviewOpenStatus.opened);
      await entering;
      expect(st().phase, CameraCheckPhase.closed);
      expect(st().preview, isNull);
      expect(bridge.openTokens, isEmpty);
    });

    test('segundo plano durante la apertura y vuelta: la respuesta antigua se '
        'descarta y se abre con otro token', () async {
      final entering = ctrl().enter();
      await pumpEventQueue();
      final old = lastToken();
      ctrl().suspend();
      expect(st().phase, CameraCheckPhase.suspended);
      final resuming = ctrl().resume();
      await pumpEventQueue();
      final fresh = lastToken();
      expect(fresh, isNot(old));
      bridge.answerOpen(old, PreviewOpenStatus.opened);
      await entering;
      expect(st().phase, CameraCheckPhase.opening);
      expect(bridge.openTokens, isEmpty);
      bridge.answerOpen(fresh, PreviewOpenStatus.opened);
      await resuming;
      expect(st().phase, CameraCheckPhase.available);
      expect(st().preview!.token, fresh);
      expect(bridge.openTokens, {fresh});
    });

    test(
      'segundo plano con la vista abierta: libera y reabre al volver',
      () async {
        bridge.openAnswer = PreviewOpenStatus.opened;
        await ctrl().enter();
        final first = lastToken();
        ctrl().suspend();
        expect(bridge.calls.last, 'close:$first');
        expect(st().phase, CameraCheckPhase.suspended);
        expect(bridge.openTokens, isEmpty);
        await ctrl().resume();
        expect(st().phase, CameraCheckPhase.available);
        expect(bridge.opens, 2);
      },
    );

    test(
      'salir con la vista abierta la libera; volver a entrar abre de nuevo',
      () async {
        bridge.openAnswer = PreviewOpenStatus.opened;
        await ctrl().enter();
        ctrl().leave();
        expect(bridge.openTokens, isEmpty);
        await pumpEventQueue();
        expect(st().phase, CameraCheckPhase.closed);
        // Tras salir, un aviso de vuelta no reabre nada.
        await ctrl().resume();
        expect(bridge.opens, 1);
        await ctrl().enter();
        expect(st().phase, CameraCheckPhase.available);
        expect(bridge.opens, 2);
      },
    );

    test('cierre nativo: el de un token antiguo se ignora; el vigente cambia '
        'el estado', () async {
      bridge.openAnswer = PreviewOpenStatus.opened;
      await ctrl().enter();
      final first = lastToken();
      ctrl().suspend();
      await ctrl().resume();
      final current = lastToken();
      bridge.emitClosed(first, PreviewCloseReason.cameraError);
      await pumpEventQueue();
      expect(st().phase, CameraCheckPhase.available);
      bridge.emitClosed(current, PreviewCloseReason.cameraInUse);
      await pumpEventQueue();
      expect(st().phase, CameraCheckPhase.inUse);
      expect(st().preview, isNull);
    });

    test('desechar el controlador libera la cámara', () async {
      bridge.openAnswer = PreviewOpenStatus.opened;
      await ctrl().enter();
      final token = lastToken();
      container.dispose();
      expect(bridge.calls.last, 'close:$token');
    });

    test('los tokens no se repiten entre controladores', () async {
      bridge.openAnswer = PreviewOpenStatus.opened;
      await ctrl().enter();
      final first = lastToken();
      final other = ProviderContainer(
        overrides: [frontCameraBridgeProvider.overrideWithValue(bridge)],
      );
      addTearDown(other.dispose);
      await other.read(frontCameraProvider.notifier).enter();
      expect(lastToken(), greaterThan(first));
    });
  });
}
