import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_engine/monitoring_engine.dart';
import 'package:vigia/features/camera/front_camera_controller.dart';

import '../support/fake_camera.dart';

/// Fase 5B · presencia facial en el controlador, con el doble del motor
/// ([FakeFrontCameraBridge]): **no hay cámara ni modelo reales**; cada
/// resultado lo emite la prueba. La inferencia real se prueba en Android
/// (`FaceLandmarkerInstrumentedTest`) y en el emulador.
void main() {
  late FakeFrontCameraBridge bridge;
  late ProviderContainer container;

  FrontCameraController ctrl() => container.read(frontCameraProvider.notifier);
  FrontCameraState st() => container.read(frontCameraProvider);
  int lastToken() => int.parse(
    bridge.calls.lastWhere((c) => c.startsWith('open:')).split(':')[1],
  );

  setUp(() {
    bridge = FakeFrontCameraBridge(permission: CameraPermissionStatus.granted);
    container = ProviderContainer(
      overrides: [frontCameraBridgeProvider.overrideWithValue(bridge)],
    );
    addTearDown(container.dispose);
  });

  Future<void> emit(
    FaceAnalysisStatus status, {
    int? token,
    bool expired = false,
    String? errorCode,
  }) async {
    bridge.emitFace(
      status,
      token: token,
      expired: expired,
      errorCode: errorCode,
    );
    await pumpEventQueue();
  }

  group('estados', () {
    test('sin cámara abierta el análisis está detenido', () async {
      bridge.permission = CameraPermissionStatus.denied;
      await ctrl().enter();
      expect(st().phase, CameraCheckPhase.explain);
      expect(st().facePhase, FacePresencePhase.stopped);
    });

    test('cámara abierta sin noticias del motor: cargando el modelo, nunca '
        '«sin rostro»', () async {
      await ctrl().enter();
      expect(st().phase, CameraCheckPhase.available);
      expect(st().facePhase, FacePresencePhase.loadingModel);
    });

    test('cada estado del motor se muestra como tal', () async {
      await ctrl().enter();
      const expected = {
        FaceAnalysisStatus.loadingModel: FacePresencePhase.loadingModel,
        FaceAnalysisStatus.waitingResults: FacePresencePhase.waitingResults,
        FaceAnalysisStatus.noFace: FacePresencePhase.noFace,
        FaceAnalysisStatus.oneFace: FacePresencePhase.oneFace,
        FaceAnalysisStatus.multipleFaces: FacePresencePhase.multipleFaces,
        FaceAnalysisStatus.modelError: FacePresencePhase.modelError,
        FaceAnalysisStatus.analysisError: FacePresencePhase.analysisError,
        FaceAnalysisStatus.stopped: FacePresencePhase.stopped,
      };
      for (final MapEntry(key: status, value: phase) in expected.entries) {
        await emit(status);
        expect(st().facePhase, phase, reason: '$status');
      }
    });

    test('resultado caducado en el motor: espera, con la causa, sin rostro '
        'vigente', () async {
      await ctrl().enter();
      await emit(FaceAnalysisStatus.oneFace);
      await emit(FaceAnalysisStatus.waitingResults, expired: true);
      expect(st().facePhase, FacePresencePhase.waitingResults);
      expect(st().faceExpired, isTrue);
      expect(st().face!.faceCount, isNull);
    });

    test('un resultado que llega durante la apertura se conserva y se '
        'muestra al abrir', () async {
      bridge.openAnswer = null;
      final entering = ctrl().enter();
      await pumpEventQueue();
      final token = lastToken();
      bridge.emitFace(FaceAnalysisStatus.loadingModel, token: token);
      bridge.emitFace(FaceAnalysisStatus.waitingResults, token: token);
      await pumpEventQueue();
      expect(st().phase, CameraCheckPhase.opening);
      expect(st().facePhase, FacePresencePhase.stopped);
      bridge.answerOpen(token, PreviewOpenStatus.opened);
      await entering;
      expect(st().facePhase, FacePresencePhase.waitingResults);
    });
  });

  group('identidad de cada apertura', () {
    test('resultados de una apertura anterior no afectan a la nueva', () async {
      await ctrl().enter();
      final old = lastToken();
      await emit(FaceAnalysisStatus.oneFace);
      ctrl().leave();
      await pumpEventQueue();
      await ctrl().enter();
      final current = lastToken();
      expect(current, isNot(old));
      expect(st().facePhase, FacePresencePhase.loadingModel);
      await emit(FaceAnalysisStatus.multipleFaces, token: old);
      await emit(FaceAnalysisStatus.modelError, token: old);
      expect(st().facePhase, FacePresencePhase.loadingModel);
      await emit(FaceAnalysisStatus.noFace, token: current);
      expect(st().facePhase, FacePresencePhase.noFace);
    });

    test('tras salir, un resultado tardío no reactiva nada', () async {
      await ctrl().enter();
      final token = lastToken();
      ctrl().leave();
      await pumpEventQueue();
      await emit(FaceAnalysisStatus.oneFace, token: token);
      expect(st().phase, CameraCheckPhase.closed);
      expect(st().facePhase, FacePresencePhase.stopped);
      expect(st().face, isNull);
    });

    test('segundo plano: análisis detenido; al volver, otra apertura que no '
        'hereda el resultado anterior', () async {
      await ctrl().enter();
      final old = lastToken();
      await emit(FaceAnalysisStatus.oneFace);
      ctrl().suspend();
      expect(st().facePhase, FacePresencePhase.stopped);
      await emit(FaceAnalysisStatus.oneFace, token: old);
      expect(st().face, isNull);
      await ctrl().resume();
      expect(lastToken(), isNot(old));
      expect(st().facePhase, FacePresencePhase.loadingModel);
    });

    test('cierre nativo del token vigente: análisis detenido y sin '
        'resultado', () async {
      await ctrl().enter();
      final token = lastToken();
      await emit(FaceAnalysisStatus.multipleFaces);
      bridge.emitClosed(token, PreviewCloseReason.cameraError);
      await pumpEventQueue();
      expect(st().phase, CameraCheckPhase.failed);
      expect(st().facePhase, FacePresencePhase.stopped);
      await emit(FaceAnalysisStatus.oneFace, token: token);
      expect(st().face, isNull);
    });

    test('controlador desechado: un resultado tardío no lanza', () async {
      await ctrl().enter();
      final token = lastToken();
      container.dispose();
      bridge.emitFace(FaceAnalysisStatus.oneFace, token: token);
      await pumpEventQueue();
    });
  });

  group('vigilancia de Flutter (3000 ms sin noticias)', () {
    test('el último resultado deja de ser vigente al cumplirse el límite, y '
        'vuelve con un resultado nuevo', () {
      fakeAsync((async) {
        ctrl().enter();
        async.flushMicrotasks();
        bridge.emitFace(FaceAnalysisStatus.oneFace);
        async.flushMicrotasks();
        expect(st().facePhase, FacePresencePhase.oneFace);

        async.elapse(const Duration(milliseconds: 2999));
        expect(st().facePhase, FacePresencePhase.oneFace);
        async.elapse(const Duration(milliseconds: 1));
        expect(st().facePhase, FacePresencePhase.waitingResults);
        expect(st().faceExpired, isTrue);

        // Una inferencia nueva (otra identidad) sí restaura la detección.
        bridge.emitFace(FaceAnalysisStatus.oneFace, resultId: 10);
        async.flushMicrotasks();
        expect(st().facePhase, FacePresencePhase.oneFace);
        expect(st().faceExpired, isFalse);
        ctrl().leave();
        async.flushMicrotasks();
      });
    });

    test('inferencias nuevas cada segundo mantienen vigente el resultado', () {
      fakeAsync((async) {
        ctrl().enter();
        async.flushMicrotasks();
        for (var i = 0; i < 5; i++) {
          bridge.emitFace(FaceAnalysisStatus.noFace, resultId: 20 + i);
          async.flushMicrotasks();
          async.elapse(const Duration(milliseconds: 1000));
        }
        expect(st().facePhase, FacePresencePhase.noFace);
        async.elapse(const Duration(milliseconds: 2000));
        expect(st().facePhase, FacePresencePhase.waitingResults);
        ctrl().leave();
        async.flushMicrotasks();
      });
    });

    test('sin ningún resultado tras abrir: espera, nunca «sin rostro»', () {
      fakeAsync((async) {
        ctrl().enter();
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 10));
        expect(st().facePhase, FacePresencePhase.waitingResults);
        ctrl().leave();
        async.flushMicrotasks();
      });
    });

    test('la vigilancia de una apertura anterior no toca la nueva', () {
      fakeAsync((async) {
        ctrl().enter();
        async.flushMicrotasks();
        bridge.emitFace(FaceAnalysisStatus.oneFace);
        async.flushMicrotasks();
        ctrl().leave();
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 1500));
        ctrl().enter();
        async.flushMicrotasks();
        bridge.emitFace(FaceAnalysisStatus.noFace);
        async.flushMicrotasks();
        async.elapse(const Duration(milliseconds: 2000));
        // 3500 ms desde el resultado anterior, 2000 desde el vigente.
        expect(st().facePhase, FacePresencePhase.noFace);
        ctrl().leave();
        async.flushMicrotasks();
      });
    });
  });

  group('reintento del análisis', () {
    test('error de modelo: «Reintentar carga» pide el reinicio del token '
        'vigente', () async {
      await ctrl().enter();
      await emit(FaceAnalysisStatus.modelError, errorCode: 'modelCorrupt');
      expect(st().facePhase, FacePresencePhase.modelError);
      expect(st().face!.errorCode, 'modelCorrupt');
      await ctrl().retryFaceAnalysis();
      expect(bridge.calls.last, 'restartFace:${lastToken()}');
      await emit(FaceAnalysisStatus.loadingModel);
      await emit(FaceAnalysisStatus.waitingResults);
      expect(st().facePhase, FacePresencePhase.waitingResults);
    });

    test('error de inferencia: se puede reintentar', () async {
      await ctrl().enter();
      await emit(
        FaceAnalysisStatus.analysisError,
        errorCode: 'inferenceFailed',
      );
      await ctrl().retryFaceAnalysis();
      expect(bridge.restarts, 1);
    });

    test(
      'sin error no se pide ningún reinicio (no duplica el detector)',
      () async {
        await ctrl().enter();
        await ctrl().retryFaceAnalysis();
        await emit(FaceAnalysisStatus.oneFace);
        await ctrl().retryFaceAnalysis();
        expect(bridge.restarts, 0);
      },
    );

    test(
      'pulsaciones repetidas durante un reinicio: una sola petición',
      () async {
        await ctrl().enter();
        await emit(FaceAnalysisStatus.modelError, errorCode: 'modelMissing');
        final a = ctrl().retryFaceAnalysis();
        final b = ctrl().retryFaceAnalysis();
        await Future.wait([a, b]);
        expect(bridge.restarts, 1);
      },
    );

    test(
      'un fallo del canal al reintentar no bloquea: se puede repetir',
      () async {
        await ctrl().enter();
        await emit(FaceAnalysisStatus.modelError, errorCode: 'modelMissing');
        bridge.restartError = PlatformException(code: 'channel-error');
        await ctrl().retryFaceAnalysis();
        expect(st().facePhase, FacePresencePhase.modelError);
        bridge.restartError = null;
        await ctrl().retryFaceAnalysis();
        expect(bridge.restarts, 2);
      },
    );
  });

  /// Revisión de Codex de la fase 5B (P1): orden, identidad y vigencia de
  /// los resultados en Flutter. Tiempo controlado con `fake_async`.
  group('orden e identidad de los resultados (revisión 5B)', () {
    /// Abre la cámara dentro de `fakeAsync` y devuelve el token.
    int open(FakeAsync async) {
      ctrl().enter();
      async.flushMicrotasks();
      return lastToken();
    }

    void close(FakeAsync async) {
      ctrl().leave();
      async.flushMicrotasks();
    }

    void send(
      FakeAsync async,
      FaceAnalysisStatus status, {
      int generation = 1,
      int? sequence,
      int? resultId,
      int? token,
    }) {
      bridge.emitFace(
        status,
        generation: generation,
        sequence: sequence,
        resultId: resultId,
        token: token,
      );
      async.flushMicrotasks();
    }

    test('reproducción de Codex 1: el mismo resultado tras caducar no '
        'restaura «Rostro detectado»', () {
      fakeAsync((async) {
        open(async);
        send(async, FaceAnalysisStatus.oneFace);
        async.elapse(const Duration(milliseconds: 3000));
        expect(st().facePhase, FacePresencePhase.waitingResults);
        // Mismos generation y resultId: ningún resultado nuevo.
        send(async, FaceAnalysisStatus.oneFace);
        expect(st().facePhase, FacePresencePhase.waitingResults);
        expect(st().faceExpired, isTrue);
        close(async);
      });
    });

    test('reproducción de Codex 2: una generación anterior no revive un '
        'análisis detenido', () {
      fakeAsync((async) {
        open(async);
        send(async, FaceAnalysisStatus.oneFace, generation: 1);
        send(async, FaceAnalysisStatus.stopped, generation: 2);
        expect(st().facePhase, FacePresencePhase.stopped);
        send(async, FaceAnalysisStatus.oneFace, generation: 1);
        expect(st().facePhase, FacePresencePhase.stopped);
        close(async);
      });
    });

    test('tras stopped, nada de esa apertura lo reactiva, ni una generación '
        'posterior con una inferencia nueva', () {
      fakeAsync((async) {
        open(async);
        send(async, FaceAnalysisStatus.stopped, generation: 2);
        send(async, FaceAnalysisStatus.oneFace, generation: 3, resultId: 50);
        send(async, FaceAnalysisStatus.waitingResults, generation: 3);
        expect(st().facePhase, FacePresencePhase.stopped);
        expect(st().face!.status, FaceAnalysisStatus.stopped);
        close(async);
      });
    });

    test('el mismo mensaje entregado otra vez (mismo sequence) se ignora', () {
      fakeAsync((async) {
        final token = open(async);
        final message = FakeFrontCameraBridge.face(
          token,
          FaceAnalysisStatus.oneFace,
          sequence: 7,
          resultId: 30,
        );
        bridge.emitRaw(message);
        async.flushMicrotasks();
        expect(st().facePhase, FacePresencePhase.oneFace);
        send(async, FaceAnalysisStatus.noFace, sequence: 8, resultId: 31);
        bridge.emitRaw(message);
        async.flushMicrotasks();
        expect(st().facePhase, FacePresencePhase.noFace);
        async.elapse(const Duration(milliseconds: 3000));
        bridge.emitRaw(message);
        async.flushMicrotasks();
        expect(st().facePhase, FacePresencePhase.waitingResults);
        close(async);
      });
    });

    test('un mensaje atrasado (sequence menor) no sustituye al vigente', () {
      fakeAsync((async) {
        open(async);
        send(async, FaceAnalysisStatus.noFace, sequence: 5, resultId: 40);
        send(async, FaceAnalysisStatus.oneFace, sequence: 4, resultId: 41);
        expect(st().facePhase, FacePresencePhase.noFace);
        expect(st().face!.sequence, 5);
        close(async);
      });
    });

    test('una generación anterior se ignora aunque traiga un sequence '
        'mayor', () {
      fakeAsync((async) {
        open(async);
        send(async, FaceAnalysisStatus.modelError, generation: 1);
        send(async, FaceAnalysisStatus.waitingResults, generation: 2);
        send(async, FaceAnalysisStatus.oneFace, generation: 1, resultId: 60);
        expect(st().facePhase, FacePresencePhase.waitingResults);
        send(async, FaceAnalysisStatus.oneFace, generation: 2, resultId: 61);
        expect(st().facePhase, FacePresencePhase.oneFace);
        close(async);
      });
    });

    test('un latido de la misma inferencia no amplía su plazo', () {
      fakeAsync((async) {
        open(async);
        send(async, FaceAnalysisStatus.oneFace, resultId: 70);
        async.elapse(const Duration(milliseconds: 2000));
        send(async, FaceAnalysisStatus.oneFace, resultId: 70); // latido
        expect(st().facePhase, FacePresencePhase.oneFace);
        async.elapse(const Duration(milliseconds: 999));
        expect(st().facePhase, FacePresencePhase.oneFace);
        async.elapse(const Duration(milliseconds: 1));
        expect(st().facePhase, FacePresencePhase.waitingResults);
        close(async);
      });
    });

    test('control positivo: una inferencia nueva justo antes del límite '
        'reinicia el plazo desde su llegada', () {
      fakeAsync((async) {
        open(async);
        send(async, FaceAnalysisStatus.oneFace, resultId: 80);
        async.elapse(const Duration(milliseconds: 2900));
        send(async, FaceAnalysisStatus.multipleFaces, resultId: 81);
        async.elapse(const Duration(milliseconds: 2999));
        expect(st().facePhase, FacePresencePhase.multipleFaces);
        async.elapse(const Duration(milliseconds: 1));
        expect(st().facePhase, FacePresencePhase.waitingResults);
        send(async, FaceAnalysisStatus.noFace, resultId: 82);
        expect(st().facePhase, FacePresencePhase.noFace);
        close(async);
      });
    });

    test('una apertura nueva empieza su propio orden y no hereda nada', () {
      fakeAsync((async) {
        final old = open(async);
        send(async, FaceAnalysisStatus.oneFace, sequence: 90, resultId: 90);
        close(async);
        final current = open(async);
        expect(current, isNot(old));
        // Mensajes tardíos de la apertura anterior: ignorados.
        send(
          async,
          FaceAnalysisStatus.multipleFaces,
          token: old,
          sequence: 91,
          resultId: 91,
        );
        expect(st().facePhase, FacePresencePhase.loadingModel);
        // El motor de la apertura nueva vuelve a numerar desde 1.
        send(async, FaceAnalysisStatus.noFace, sequence: 1, resultId: 1);
        expect(st().facePhase, FacePresencePhase.noFace);
        close(async);
      });
    });

    test('una inferencia que llega durante la apertura corre su plazo desde '
        'su llegada, no desde que se muestra', () {
      fakeAsync((async) {
        bridge.openAnswer = null;
        ctrl().enter();
        async.flushMicrotasks();
        final token = lastToken();
        send(async, FaceAnalysisStatus.oneFace, token: token, resultId: 95);
        async.elapse(const Duration(milliseconds: 2000));
        bridge.answerOpen(token, PreviewOpenStatus.opened);
        async.flushMicrotasks();
        expect(st().facePhase, FacePresencePhase.oneFace);
        async.elapse(const Duration(milliseconds: 1000));
        expect(st().facePhase, FacePresencePhase.waitingResults);
        close(async);
      });
    });
  });
}
