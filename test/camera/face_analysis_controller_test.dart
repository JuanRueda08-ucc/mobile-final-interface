import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_engine/monitoring_engine.dart';
import 'package:vigia/features/camera/face_query_channel.dart';
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

  /// Tiempo controlado con `fake_async`: abrir, cerrar, avisar.
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
    int? resultAgeMs,
    int? token,
  }) {
    bridge.emitFace(
      status,
      generation: generation,
      sequence: sequence,
      resultId: resultId,
      resultAgeMs: resultAgeMs,
      token: token,
    );
    async.flushMicrotasks();
  }

  const detections = [
    FaceAnalysisStatus.noFace,
    FaceAnalysisStatus.oneFace,
    FaceAnalysisStatus.multipleFaces,
  ];
  const shown = {
    FaceAnalysisStatus.noFace: FacePresencePhase.noFace,
    FaceAnalysisStatus.oneFace: FacePresencePhase.oneFace,
    FaceAnalysisStatus.multipleFaces: FacePresencePhase.multipleFaces,
  };

  group('silencio del motor (3000 ms)', () {
    test('sin ningún mensaje tras abrir: espera, nunca «sin rostro»', () {
      fakeAsync((async) {
        bridge.holdQueries = true;
        open(async);
        async.elapse(const Duration(seconds: 10));
        expect(st().facePhase, FacePresencePhase.waitingResults);
        expect(st().faceSilent, isTrue);
        close(async);
      });
    });

    test('las respuestas del motor mantienen el canal vivo; sin ellas, a los '
        '3000 ms se declara silencio', () {
      fakeAsync((async) {
        open(async);
        send(async, FaceAnalysisStatus.waitingResults);
        async.elapse(const Duration(seconds: 5));
        expect(st().faceSilent, isFalse);
        bridge.holdQueries = true;
        async.elapse(const Duration(milliseconds: 2999));
        expect(st().faceSilent, isFalse);
        async.elapse(const Duration(milliseconds: 201));
        expect(st().faceSilent, isTrue);
        close(async);
      });
    });

    test('el silencio de una apertura anterior no toca la nueva', () {
      fakeAsync((async) {
        open(async);
        send(async, FaceAnalysisStatus.waitingResults);
        close(async);
        async.elapse(const Duration(milliseconds: 1500));
        open(async);
        send(async, FaceAnalysisStatus.waitingResults);
        async.elapse(const Duration(milliseconds: 2000));
        expect(st().faceSilent, isFalse);
        close(async);
      });
    });
  });

  /// Revisión de Codex de la fase 5B (P1, segunda ronda): edad efectiva de
  /// un resultado = edad en el motor al crear la respuesta + tiempo completo
  /// de la consulta medido en Dart. Tstale = 750 ms.
  group('edad efectiva y vigencia (revisión 5B)', () {
    for (final status in detections) {
      test('reproducción de Codex: ${status.name} retenido 5000 ms en el '
          'puente con resultAgeMs=40 no se muestra como vigente', () {
        fakeAsync((async) {
          open(async);
          bridge.holdQueries = true;
          send(async, status, resultAgeMs: 40);
          async.elapse(const Duration(milliseconds: 5000));
          expect(st().facePhase, FacePresencePhase.waitingResults);
          bridge.releaseQueries();
          async.flushMicrotasks();
          expect(st().facePhase, FacePresencePhase.waitingResults);
          expect(st().faceExpired, isTrue);
          close(async);
        });
      });

      test('control positivo: ${status.name} nuevo con transporte corto se '
          'muestra y caduca al llegar su edad a Tstale', () {
        fakeAsync((async) {
          open(async);
          bridge.holdQueries = true;
          send(async, status, resultAgeMs: 40, resultId: 100);
          async.elapse(const Duration(milliseconds: 10));
          bridge.releaseQueries();
          async.flushMicrotasks();
          bridge.holdQueries = false;
          expect(st().facePhase, shown[status]);
          // Edad efectiva 50 ms: le quedan 700 ms. Las consultas periódicas
          // del mismo resultado no alargan el plazo.
          async.elapse(const Duration(milliseconds: 700));
          expect(st().facePhase, shown[status]);
          async.elapse(const Duration(milliseconds: 1));
          expect(st().facePhase, FacePresencePhase.waitingResults);
          expect(st().faceExpired, isTrue);
          close(async);
        });
      });
    }

    test('límites: edad efectiva 750 se muestra; 751 no', () {
      fakeAsync((async) {
        open(async);
        send(async, FaceAnalysisStatus.oneFace, resultAgeMs: 750, resultId: 1);
        expect(st().facePhase, FacePresencePhase.oneFace);
        close(async);
        open(async);
        send(async, FaceAnalysisStatus.oneFace, resultAgeMs: 751, resultId: 1);
        expect(st().facePhase, FacePresencePhase.waitingResults);
        close(async);
      });
    });

    test('caduca mientras espera en el puente: 710 ms de consulta con edad '
        '40 se muestra; 711 no', () {
      fakeAsync((async) {
        open(async);
        bridge.holdQueries = true;
        send(async, FaceAnalysisStatus.oneFace, resultAgeMs: 40, resultId: 5);
        async.elapse(const Duration(milliseconds: 710));
        bridge.releaseQueries();
        async.flushMicrotasks();
        expect(st().facePhase, FacePresencePhase.oneFace);
        close(async);

        bridge.holdQueries = false;
        open(async);
        bridge.holdQueries = true;
        send(async, FaceAnalysisStatus.oneFace, resultAgeMs: 40, resultId: 5);
        async.elapse(const Duration(milliseconds: 711));
        bridge.releaseQueries();
        async.flushMicrotasks();
        expect(st().facePhase, FacePresencePhase.waitingResults);
        expect(st().face!.status, FaceAnalysisStatus.oneFace);
        expect(st().faceExpired, isTrue);
        close(async);
      });
    });

    test('un latido o una consulta del mismo resultado no lo rejuvenece, ni '
        'antes ni después de caducar', () {
      fakeAsync((async) {
        open(async);
        send(async, FaceAnalysisStatus.oneFace, resultAgeMs: 40, resultId: 70);
        // El mismo resultado vuelve a llegar varias veces con edad 40.
        for (var i = 0; i < 3; i++) {
          async.elapse(const Duration(milliseconds: 200));
          send(
            async,
            FaceAnalysisStatus.oneFace,
            resultAgeMs: 40,
            resultId: 70,
          );
        }
        async.elapse(const Duration(milliseconds: 110));
        expect(st().facePhase, FacePresencePhase.oneFace);
        async.elapse(const Duration(milliseconds: 1));
        expect(st().facePhase, FacePresencePhase.waitingResults);
        send(async, FaceAnalysisStatus.oneFace, resultAgeMs: 40, resultId: 70);
        async.elapse(const Duration(milliseconds: 400));
        expect(st().facePhase, FacePresencePhase.waitingResults);
        // Una inferencia nueva sí se muestra.
        send(async, FaceAnalysisStatus.oneFace, resultAgeMs: 30, resultId: 71);
        expect(st().facePhase, FacePresencePhase.oneFace);
        close(async);
      });
    });

    test('un aviso de detección no se muestra por sí solo: sin respuesta a '
        'la consulta, no hay rostro', () {
      fakeAsync((async) {
        open(async);
        bridge.queryError = Exception('sin respuesta');
        send(async, FaceAnalysisStatus.oneFace, resultAgeMs: 0, resultId: 1);
        expect(st().facePhase, FacePresencePhase.loadingModel);
        expect(bridge.queries, greaterThan(1));
        close(async);
      });
    });

    test('inferencias nuevas sucesivas mantienen el rostro', () {
      fakeAsync((async) {
        open(async);
        for (var i = 0; i < 10; i++) {
          send(
            async,
            FaceAnalysisStatus.noFace,
            resultAgeMs: 120,
            resultId: 20 + i,
          );
          async.elapse(const Duration(milliseconds: 300));
          expect(st().facePhase, FacePresencePhase.noFace);
        }
        close(async);
      });
    });

    test('una inferencia aceptada durante la apertura descuenta el tiempo '
        'hasta que se muestra', () {
      fakeAsync((async) {
        bridge.openAnswer = null;
        ctrl().enter();
        async.flushMicrotasks();
        final token = lastToken();
        send(
          async,
          FaceAnalysisStatus.oneFace,
          token: token,
          resultAgeMs: 40,
          resultId: 95,
        );
        async.elapse(const Duration(milliseconds: 600));
        bridge.answerOpen(token, PreviewOpenStatus.opened);
        async.flushMicrotasks();
        expect(st().facePhase, FacePresencePhase.oneFace);
        async.elapse(const Duration(milliseconds: 111));
        expect(st().facePhase, FacePresencePhase.waitingResults);
        close(async);
      });
    });
  });

  /// Revisión de Codex de la fase 5B (P1, primera ronda): orden e identidad.
  group('orden e identidad de los resultados (revisión 5B)', () {
    test('reproducción de Codex 1: el mismo resultado tras caducar no '
        'restaura «Rostro detectado»', () {
      fakeAsync((async) {
        open(async);
        send(async, FaceAnalysisStatus.oneFace);
        async.elapse(const Duration(milliseconds: 3000));
        expect(st().facePhase, FacePresencePhase.waitingResults);
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

    test('un aviso atrasado (sequence menor) no sustituye al resultado '
        'vigente', () {
      fakeAsync((async) {
        open(async);
        send(async, FaceAnalysisStatus.noFace, resultId: 40);
        final accepted = st().face!.sequence;
        bridge.emitRaw(
          FakeFrontCameraBridge.face(
            lastToken(),
            FaceAnalysisStatus.waitingResults,
            sequence: accepted - 1,
          ),
        );
        async.flushMicrotasks();
        expect(st().facePhase, FacePresencePhase.noFace);
        expect(st().face!.sequence, accepted);
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

    test('una apertura nueva empieza su propio orden y no hereda nada', () {
      fakeAsync((async) {
        final old = open(async);
        send(async, FaceAnalysisStatus.oneFace, sequence: 90, resultId: 90);
        close(async);
        final current = open(async);
        expect(current, isNot(old));
        send(
          async,
          FaceAnalysisStatus.multipleFaces,
          token: old,
          sequence: 91,
          resultId: 91,
        );
        expect(st().facePhase, FacePresencePhase.loadingModel);
        send(async, FaceAnalysisStatus.noFace, resultId: 1);
        expect(st().facePhase, FacePresencePhase.noFace);
        close(async);
      });
    });
  });

  /// Revisión de Codex de la fase 5B (tercera ronda): consultas acotadas.
  /// La llamada de Pigeon no se cancela: como máximo una llamada real
  /// pendiente; plazo propio de 750 ms; identidad antes de aplicar.
  group('consultas acotadas (revisión 5B)', () {
    for (final seconds in [120, 240]) {
      test('canal sin respuesta $seconds s: una sola llamada real pendiente y '
          'canal «sin respuesta»', () {
        fakeAsync((async) {
          bridge.holdQueries = true;
          open(async);
          async.elapse(Duration(seconds: seconds));
          expect(bridge.unfinishedQueries, 1);
          expect(bridge.queries, 1);
          expect(st().faceStalled, isTrue);
          expect(st().facePhase, FacePresencePhase.waitingResults);
          close(async);
          // La llamada sigue sin terminar: no se puede cancelar.
          expect(bridge.unfinishedQueries, 1);
        });
      });
    }

    test('el plazo vence a 750 ms desde el inicio, sin esperar al sondeo; '
        'a 749 aún no', () {
      fakeAsync((async) {
        bridge.holdQueries = true;
        open(async);
        async.elapse(const Duration(milliseconds: 749));
        expect(st().faceStalled, isFalse);
        async.elapse(const Duration(milliseconds: 1));
        expect(st().faceStalled, isTrue);
        // Ninguna llamada nueva al vencer ni en los sondeos siguientes.
        async.elapse(const Duration(milliseconds: 1000));
        expect(bridge.queries, 1);
        close(async);
      });
    });

    test('una respuesta tras el plazo no se aplica; libera el canal y la '
        'siguiente consulta válida lo recupera', () {
      fakeAsync((async) {
        bridge.holdQueries = true;
        final token = open(async);
        async.elapse(const Duration(milliseconds: 800));
        expect(st().faceStalled, isTrue);
        bridge.holdQueries = false;
        bridge.releaseQueriesWith(
          FakeFrontCameraBridge.face(
            token,
            FaceAnalysisStatus.oneFace,
            sequence: 50,
            resultId: 1,
            resultAgeMs: 0,
          ),
        );
        async.flushMicrotasks();
        expect(st().facePhase, FacePresencePhase.waitingResults);
        expect(st().face, isNull);
        expect(bridge.unfinishedQueries, 0);
        // Recuperación: el siguiente sondeo hace una consulta nueva que
        // responde a tiempo.
        send(
          async,
          FaceAnalysisStatus.multipleFaces,
          resultAgeMs: 30,
          resultId: 2,
        );
        async.elapse(FrontCameraController.facePollInterval);
        expect(st().faceStalled, isFalse);
        expect(st().facePhase, FacePresencePhase.multipleFaces);
        expect(bridge.queries, greaterThanOrEqualTo(2));
        close(async);
      });
    });

    test('una excepción tras el plazo tampoco cambia la pantalla; libera el '
        'canal y se recupera con una consulta válida', () {
      fakeAsync((async) {
        bridge.holdQueries = true;
        open(async);
        async.elapse(const Duration(milliseconds: 800));
        final before = st();
        bridge.failQueries(PlatformException(code: 'channel-error'));
        async.flushMicrotasks();
        expect(st().facePhase, before.facePhase);
        expect(st().faceStalled, isTrue);
        expect(bridge.unfinishedQueries, 0);
        bridge.holdQueries = false;
        send(async, FaceAnalysisStatus.noFace, resultAgeMs: 10, resultId: 3);
        async.elapse(FrontCameraController.facePollInterval);
        expect(st().faceStalled, isFalse);
        expect(st().facePhase, FacePresencePhase.noFace);
        close(async);
      });
    });

    test('reproducción de Codex adaptada: la respuesta de una consulta '
        'abandonada no cambia la pantalla de una apertura posterior (ni '
        'modelError)', () {
      fakeAsync((async) {
        bridge.holdQueries = true;
        final old = open(async);
        async.elapse(const Duration(milliseconds: 800));
        close(async);
        open(async);
        final after = st();
        expect(bridge.queries, 1); // la apertura nueva no llama: canal ocupado
        bridge.releaseQueriesWith(
          FakeFrontCameraBridge.face(
            old,
            FaceAnalysisStatus.modelError,
            sequence: 1,
            errorCode: 'modelMissing',
          ),
        );
        async.flushMicrotasks();
        expect(st().facePhase, after.facePhase);
        expect(st().facePhase, isNot(FacePresencePhase.modelError));
        expect(st().face, isNull);
        close(async);
      });
    });

    test('la respuesta abandonada con el token vigente tampoco se aplica', () {
      fakeAsync((async) {
        bridge.holdQueries = true;
        final token = open(async);
        async.elapse(const Duration(milliseconds: 750));
        bridge.releaseQueriesWith(
          FakeFrontCameraBridge.face(
            token,
            FaceAnalysisStatus.modelError,
            sequence: 1,
            errorCode: 'modelMissing',
          ),
        );
        async.flushMicrotasks();
        expect(st().facePhase, isNot(FacePresencePhase.modelError));
        expect(st().face, isNull);
        close(async);
      });
    });

    test('reintentos, salidas, segundo plano y reaperturas repetidos con el '
        'canal bloqueado no añaden llamadas', () {
      fakeAsync((async) {
        bridge.holdQueries = true;
        open(async);
        for (var i = 0; i < 20; i++) {
          async.elapse(const Duration(milliseconds: 300));
          ctrl().retry();
          async.flushMicrotasks();
          ctrl().suspend();
          ctrl().resume();
          async.flushMicrotasks();
          close(async);
          open(async);
          bridge.emitFace(FaceAnalysisStatus.oneFace, resultId: 100 + i);
          async.flushMicrotasks();
        }
        async.elapse(const Duration(seconds: 30));
        expect(bridge.queries, 1);
        expect(bridge.unfinishedQueries, 1);
        expect(st().facePhase, isNot(FacePresencePhase.oneFace));
        expect(st().faceStalled, isTrue);
        close(async);
      });
    });

    test('una apertura nueva con el canal ocupado queda «sin respuesta» al '
        'cumplirse el plazo de la llamada pendiente', () {
      fakeAsync((async) {
        bridge.holdQueries = true;
        open(async);
        async.elapse(const Duration(milliseconds: 500));
        close(async);
        open(async);
        async.elapse(const Duration(milliseconds: 249));
        expect(st().faceStalled, isFalse);
        async.elapse(const Duration(milliseconds: 1));
        expect(st().faceStalled, isTrue);
        close(async);
      });
    });

    test('stopped cancela todos los temporizadores, también el del rostro '
        'mostrado', () {
      fakeAsync((async) {
        open(async);
        send(async, FaceAnalysisStatus.oneFace, resultAgeMs: 0, resultId: 1);
        expect(st().facePhase, FacePresencePhase.oneFace);
        send(async, FaceAnalysisStatus.stopped, generation: 2);
        expect(st().facePhase, FacePresencePhase.stopped);
        expect(async.nonPeriodicTimerCount, 0);
        expect(async.periodicTimerCount, 0);
        async.elapse(const Duration(seconds: 5));
        expect(st().facePhase, FacePresencePhase.stopped);
        close(async);
      });
    });

    for (final action in ['salir', 'segundo plano', 'desechar']) {
      test('$action con una llamada bloqueada: sin temporizadores ni '
          'reintentos activos, y su respuesta tardía no cambia nada', () {
        fakeAsync((async) {
          bridge.holdQueries = true;
          final token = open(async);
          send(async, FaceAnalysisStatus.oneFace, resultAgeMs: 0, resultId: 1);
          async.elapse(const Duration(milliseconds: 300));
          switch (action) {
            case 'salir':
              ctrl().leave();
            case 'segundo plano':
              ctrl().suspend();
            case 'desechar':
              container.dispose();
          }
          async.flushMicrotasks();
          expect(async.nonPeriodicTimerCount, 0);
          expect(async.periodicTimerCount, 0);
          final calls = bridge.queries;
          async.elapse(const Duration(seconds: 5));
          expect(bridge.queries, calls);
          bridge.releaseQueriesWith(
            FakeFrontCameraBridge.face(
              token,
              FaceAnalysisStatus.modelError,
              sequence: 99,
            ),
          );
          async.flushMicrotasks();
          if (action != 'desechar') {
            expect(st().facePhase, FacePresencePhase.stopped);
            close(async);
          }
          expect(async.nonPeriodicTimerCount, 0);
          expect(async.periodicTimerCount, 0);
        });
      });
    }
  });

  /// Revisión de Codex de la fase 5B (cuarta ronda): una llamada pendiente
  /// por **canal**, bloqueo visible y plazo comprobado al recibir.
  group('coordinador por canal y plazo al recibir (revisión 5B)', () {
    /// Otro contenedor (otra instancia del controlador) sobre el mismo puente.
    ProviderContainer another() => ProviderContainer(
      overrides: [frontCameraBridgeProvider.overrideWithValue(bridge)],
    );

    test('controlador A con consulta pendiente → desechar → controlador B en '
        'el mismo canal: una sola llamada; la respuesta tardía libera el canal '
        'sin aplicarse y B consulta y se recupera', () {
      fakeAsync((async) {
        bridge.holdQueries = true;
        final old = open(async);
        async.elapse(const Duration(milliseconds: 750));
        container.dispose();
        expect(bridge.unfinishedQueries, 1);

        final b = another();
        addTearDown(b.dispose);
        final ctrlB = b.read(frontCameraProvider.notifier);
        ctrlB.enter();
        async.flushMicrotasks();

        expect(bridge.queries, 1);
        expect(bridge.unfinishedQueries, 1);
        // B vigila el plazo de la llamada pendiente: «sin respuesta».
        expect(b.read(frontCameraProvider).faceStalled, isTrue);

        bridge.holdQueries = false;
        bridge.releaseQueriesWith(
          FakeFrontCameraBridge.face(
            old,
            FaceAnalysisStatus.modelError,
            sequence: 20,
            errorCode: 'modelMissing',
          ),
        );
        async.flushMicrotasks();
        expect(b.read(frontCameraProvider).face, isNull);
        expect(bridge.unfinishedQueries, 0);

        bridge.emitFace(
          FaceAnalysisStatus.oneFace,
          token: b.read(frontCameraProvider).preview!.token,
          resultAgeMs: 20,
          resultId: 1,
        );
        async.elapse(FrontCameraController.facePollInterval);
        expect(b.read(frontCameraProvider).faceStalled, isFalse);
        expect(
          b.read(frontCameraProvider).facePhase,
          FacePresencePhase.oneFace,
        );
        expect(bridge.queries, greaterThanOrEqualTo(2));
        expect(bridge.unfinishedQueries, 0);
        ctrlB.leave();
        async.flushMicrotasks();
      });
    });

    test('recrear el controlador y reintentar varias veces con el canal '
        'bloqueado no añade llamadas', () {
      fakeAsync((async) {
        bridge.holdQueries = true;
        open(async);
        container.dispose();
        for (var i = 0; i < 10; i++) {
          final c = another();
          final ctl = c.read(frontCameraProvider.notifier);
          ctl.enter();
          async.flushMicrotasks();
          ctl.retry();
          async.elapse(const Duration(milliseconds: 400));
          ctl.leave();
          async.flushMicrotasks();
          c.dispose();
        }
        async.elapse(const Duration(seconds: 30));
        expect(bridge.queries, 1);
        expect(bridge.unfinishedQueries, 1);
        bridge.releaseQueriesWith(null);
        async.flushMicrotasks();
        expect(bridge.unfinishedQueries, 0);
      });
    });

    test('canales distintos no se limitan entre sí', () {
      fakeAsync((async) {
        bridge.holdQueries = true;
        open(async);
        final other = FakeFrontCameraBridge(
          permission: CameraPermissionStatus.granted,
        )..holdQueries = true;
        final c = ProviderContainer(
          overrides: [frontCameraBridgeProvider.overrideWithValue(other)],
        );
        c.read(frontCameraProvider.notifier).enter();
        async.flushMicrotasks();
        expect(bridge.queries, 1);
        expect(other.queries, 1);
        c.read(frontCameraProvider.notifier).leave();
        async.flushMicrotasks();
        c.dispose();
        close(async);
        bridge.releaseQueriesWith(null);
        other.releaseQueriesWith(null);
        async.flushMicrotasks();
      });
    });

    test('bloqueo con un aviso previo de carga: se muestra «esperando» con la '
        'causa del canal; un latido antiguo no lo oculta; una consulta válida '
        'lo recupera', () {
      fakeAsync((async) {
        bridge.holdQueries = true;
        open(async);
        send(async, FaceAnalysisStatus.loadingModel);
        expect(st().facePhase, FacePresencePhase.loadingModel);
        async.elapse(const Duration(milliseconds: 749));
        expect(st().faceStalled, isFalse);
        async.elapse(const Duration(milliseconds: 1));
        expect(st().faceStalled, isTrue);
        expect(st().facePhase, FacePresencePhase.waitingResults);
        // Avisos posteriores (latidos de carga) no ocultan el bloqueo.
        send(async, FaceAnalysisStatus.loadingModel);
        bridge.emitFace(
          FaceAnalysisStatus.modelError,
          errorCode: 'modelMissing',
        );
        async.flushMicrotasks();
        expect(st().facePhase, FacePresencePhase.waitingResults);
        // Recuperación: termina la llamada y la siguiente responde a tiempo.
        bridge.holdQueries = false;
        bridge.releaseQueriesWith(null);
        async.flushMicrotasks();
        send(async, FaceAnalysisStatus.noFace, resultAgeMs: 10, resultId: 4);
        async.elapse(FrontCameraController.facePollInterval);
        expect(st().faceStalled, isFalse);
        expect(st().facePhase, FacePresencePhase.noFace);
        close(async);
      });
    });

    for (final (ms, applied) in [(749, true), (750, false), (800, false)]) {
      test(
        'respuesta modelError a $ms ms con el event loop detenido (sin '
        'ejecutar el temporizador): ${applied ? 'se aplica' : 'no se aplica'}',
        () {
          fakeAsync((async) {
            bridge.holdQueries = true;
            final token = open(async);
            async.elapseBlocking(Duration(milliseconds: ms));
            bridge.releaseQueriesWith(
              FakeFrontCameraBridge.face(
                token,
                FaceAnalysisStatus.modelError,
                sequence: 5,
                errorCode: 'modelMissing',
              ),
            );
            async.flushMicrotasks();
            expect(
              st().facePhase,
              applied
                  ? FacePresencePhase.modelError
                  : isNot(FacePresencePhase.modelError),
            );
            close(async);
          });
        },
      );
    }

    test('excepción a 800 ms con el event loop detenido: no cambia nada y '
        'libera el canal', () {
      fakeAsync((async) {
        bridge.holdQueries = true;
        open(async);
        final before = st().facePhase;
        async.elapseBlocking(const Duration(milliseconds: 800));
        bridge.failQueries(PlatformException(code: 'channel-error'));
        async.flushMicrotasks();
        expect(st().facePhase, before);
        expect(bridge.unfinishedQueries, 0);
        close(async);
      });
    });
  });

  /// Revisión 5B (quinta ronda): edad medida al aplicar y consumidores
  /// desvinculados de la llamada pendiente.
  group('edad al aplicar y consumidores desechados (revisión 5B)', () {
    const detections = [
      FaceAnalysisStatus.noFace,
      FaceAnalysisStatus.oneFace,
      FaceAnalysisStatus.multipleFaces,
    ];
    const shown = [
      FacePresencePhase.noFace,
      FacePresencePhase.oneFace,
      FacePresencePhase.multipleFaces,
    ];
    for (final status in detections) {
      for (final (blockMs, visible) in [(40, false), (20, true)]) {
        test('${status.name}: edad 710 ms + consulta 10 ms + despacho '
            '$blockMs ms antes de entregar → '
            '${visible ? 'se muestra' : 'no se publica'}', () {
          fakeAsync((async) {
            bridge.holdQueries = true;
            final token = open(async);
            final published = <FacePresencePhase>[];
            final sub = container.listen(frontCameraProvider, (_, next) {
              if (shown.contains(next.facePhase)) {
                published.add(next.facePhase);
              }
            });
            // Tras la terminación (primera continuación: el coordinador),
            // otra continuación bloquea el isolate sin ejecutar timers.
            bridge.pendingQueries.single.$1.future.then((_) {
              async.elapseBlocking(Duration(milliseconds: blockMs));
            });
            async.elapseBlocking(const Duration(milliseconds: 10));
            bridge.releaseQueriesWith(
              FakeFrontCameraBridge.face(
                token,
                status,
                sequence: 10,
                resultId: 1,
                resultAgeMs: 710,
              ),
            );
            async.flushMicrotasks();
            if (visible) {
              expect(published, hasLength(1));
              expect(st().facePhase, shown[detections.indexOf(status)]);
            } else {
              expect(published, isEmpty);
              expect(st().facePhase, FacePresencePhase.waitingResults);
            }
            sub.close();
            close(async);
          });
        });
      }
    }

    test('diez controladores abiertos y desechados sobre la misma llamada '
        'bloqueada: el ticket no conserva sus suscripciones', () {
      fakeAsync((async) {
        bridge.holdQueries = true;
        open(async);
        final ticket = FaceQueryChannel.pendingOn(bridge)!;
        expect(ticket.listenerCount, 2); // propia y vigilancia del plazo
        container.dispose();
        expect(ticket.listenerCount, 0);
        for (var i = 0; i < 10; i++) {
          final c = ProviderContainer(
            overrides: [frontCameraBridgeProvider.overrideWithValue(bridge)],
          );
          c.read(frontCameraProvider.notifier).enter();
          async.elapse(const Duration(milliseconds: 400));
          expect(ticket.listenerCount, 1); // solo vigila, no consultó
          if (i.isEven) {
            c.read(frontCameraProvider.notifier).leave();
            async.flushMicrotasks();
            expect(ticket.listenerCount, 0);
          }
          c.dispose();
          expect(ticket.listenerCount, 0);
        }
        expect(bridge.queries, 1);
        var calls = 0;
        // Un consumidor externo comprueba que la entrega sigue funcionando.
        ticket.listen((_) => calls++);
        bridge.releaseQueriesWith(null);
        async.flushMicrotasks();
        expect(calls, 1);
        expect(ticket.listenerCount, 0);
        expect(bridge.unfinishedQueries, 0);
        expect(async.periodicTimerCount, 0);
        expect(async.nonPeriodicTimerCount, 0);
      });
    });
  });
}
