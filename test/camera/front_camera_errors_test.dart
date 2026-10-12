import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_engine/monitoring_engine.dart';
import 'package:vigia/features/camera/front_camera_controller.dart';

import '../support/fake_camera.dart';

/// Fase 5A · corrección de la revisión de Codex (P2): excepciones del puente
/// y controlador desechado. Pruebas de lógica con [FakeFrontCameraBridge].
void main() {
  final channelError = PlatformException(code: 'channel-error');
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

  void expectRecoverableFailure() {
    expect(st().phase, CameraCheckPhase.failed);
    expect(st().bridgeFailure, isTrue);
    expect(st().errorCode, 'channel-error');
    expect(st().preview, isNull);
  }

  group('excepciones del puente', () {
    test(
      'consulta: fallo recuperable y Reintentar consulta de nuevo',
      () async {
        bridge.checkError = channelError;
        await ctrl().enter();
        expectRecoverableFailure();
        bridge
          ..checkError = null
          ..permission = CameraPermissionStatus.granted;
        await ctrl().retry();
        expect(bridge.calls.where((c) => c == 'check'), hasLength(2));
        expect(st().phase, CameraCheckPhase.available);
      },
    );

    test('solicitud: fallo recuperable, sin bloqueo, y Reintentar opera de '
        'nuevo', () async {
      await ctrl().enter();
      bridge.requestError = channelError;
      await ctrl().requestPermission();
      expectRecoverableFailure();
      bridge.requestError = null;
      await ctrl().retry();
      expect(st().phase, CameraCheckPhase.explain);
      bridge.requestAnswer = CameraPermissionStatus.granted;
      await ctrl().requestPermission();
      expect(bridge.requests, 2);
      expect(st().phase, CameraCheckPhase.available);
    });

    test('apertura: fallo recuperable, cierra solo ese token y Reintentar '
        'abre con otro', () async {
      bridge
        ..permission = CameraPermissionStatus.granted
        ..openError = channelError;
      await ctrl().enter();
      final failed = lastToken();
      expectRecoverableFailure();
      expect(bridge.calls, contains('close:$failed'));
      bridge.openError = null;
      await ctrl().retry();
      expect(lastToken(), greaterThan(failed));
      expect(st().phase, CameraCheckPhase.available);
      expect(bridge.openTokens, {lastToken()});
    });

    test('apertura parcial: la excepción tardía cierra su token sin tocar la '
        'apertura nueva', () async {
      bridge
        ..permission = CameraPermissionStatus.granted
        ..openAnswer = null;
      final entering = ctrl().enter();
      await pumpEventQueue();
      final old = lastToken();
      ctrl().suspend();
      final resuming = ctrl().resume();
      await pumpEventQueue();
      final fresh = lastToken();
      // El motor llegó a abrir el token antiguo antes de fallar el canal.
      bridge.openTokens.add(old);
      bridge.failOpen(old, channelError);
      await entering;
      expect(bridge.openTokens, isNot(contains(old)));
      expect(st().phase, CameraCheckPhase.opening);
      expect(bridge.calls, isNot(contains('close:$fresh')));
      bridge.answerOpen(fresh, PreviewOpenStatus.opened);
      await resuming;
      expect(st().phase, CameraCheckPhase.available);
      expect(st().preview!.token, fresh);
      expect(bridge.openTokens, {fresh});
    });

    test('una excepción antigua de solicitud no sobrescribe el intento '
        'posterior', () async {
      await ctrl().enter();
      final requesting = ctrl().requestPermission();
      await pumpEventQueue();
      // La app deja de verse y vuelve: nueva consulta, ya sin la solicitud.
      ctrl().suspend();
      await ctrl().resume();
      expect(st().phase, CameraCheckPhase.explain);
      bridge.failRequest(channelError);
      await requesting;
      expect(st().phase, CameraCheckPhase.explain);
      expect(st().bridgeFailure, isFalse);
    });

    test('un fallo al cerrar no deja excepciones sin capturar ni cambia el '
        'estado', () async {
      bridge
        ..permission = CameraPermissionStatus.granted
        ..closeError = channelError;
      await ctrl().enter();
      ctrl().suspend();
      expect(st().phase, CameraCheckPhase.suspended);
      await ctrl().resume();
      ctrl().leave();
      await pumpEventQueue();
      expect(st().phase, CameraCheckPhase.closed);
    });
  });

  group('controlador desechado', () {
    test(
      'consulta retenida → desechar → concedido: no abre, no usa el Ref',
      () async {
        bridge.holdCheck = true;
        final entering = ctrl().enter();
        await pumpEventQueue();
        container.dispose();
        bridge.permission = CameraPermissionStatus.granted;
        bridge.pendingCheck!.complete(CameraPermissionStatus.granted);
        await expectLater(entering, completes);
        expect(bridge.opens, 0);
      },
    );

    test(
      'consulta retenida → desechar → excepción tardía: sin errores',
      () async {
        bridge.holdCheck = true;
        final entering = ctrl().enter();
        await pumpEventQueue();
        container.dispose();
        bridge.pendingCheck!.completeError(channelError);
        await expectLater(entering, completes);
        expect(bridge.opens, 0);
      },
    );

    test(
      'solicitud retenida → desechar → concedido: no abre ni cambia nada',
      () async {
        await ctrl().enter();
        final requesting = ctrl().requestPermission();
        await pumpEventQueue();
        container.dispose();
        bridge.answerRequest(CameraPermissionStatus.granted);
        await expectLater(requesting, completes);
        expect(bridge.opens, 0);
      },
    );

    test(
      'solicitud retenida → desechar → excepción tardía: sin errores',
      () async {
        await ctrl().enter();
        final requesting = ctrl().requestPermission();
        await pumpEventQueue();
        container.dispose();
        bridge.failRequest(channelError);
        await expectLater(requesting, completes);
        expect(bridge.opens, 0);
      },
    );

    test(
      'apertura retenida → desechar → abierta: se cierra al llegar',
      () async {
        bridge
          ..permission = CameraPermissionStatus.granted
          ..openAnswer = null;
        final entering = ctrl().enter();
        await pumpEventQueue();
        final token = lastToken();
        container.dispose();
        expect(bridge.calls, contains('close:$token'));
        bridge.answerOpen(token, PreviewOpenStatus.opened);
        await expectLater(entering, completes);
        expect(bridge.openTokens, isEmpty);
      },
    );

    test(
      'apertura retenida → desechar → excepción tardía: sin errores',
      () async {
        bridge
          ..permission = CameraPermissionStatus.granted
          ..openAnswer = null;
        final entering = ctrl().enter();
        await pumpEventQueue();
        final token = lastToken();
        container.dispose();
        bridge.failOpen(token, channelError);
        await expectLater(entering, completes);
        expect(bridge.openTokens, isEmpty);
      },
    );

    test(
      'desechar con la vista abierta y cierre fallido: sin errores',
      () async {
        bridge
          ..permission = CameraPermissionStatus.granted
          ..closeError = channelError;
        await ctrl().enter();
        final token = lastToken();
        container.dispose();
        await pumpEventQueue();
        expect(bridge.calls.last, 'close:$token');
      },
    );
  });
}
