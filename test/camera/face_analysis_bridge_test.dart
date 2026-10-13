import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_engine/monitoring_engine.dart';
import 'package:monitoring_engine/src/monitoring_api.g.dart';
import 'package:vigia/features/camera/front_camera_controller.dart';

import '../support/fake_camera.dart';

/// Fase 5B · edad efectiva con el **puente Pigeon real**
/// ([PigeonFrontCameraBridge] y el códec generado). El host es un doble que
/// responde a la consulta con la edad que el motor calcularía al crear la
/// respuesta, tras una demora controlada; los avisos se entregan como bytes
/// por el canal `FrontCameraFlutterApi.onFaceAnalysis`. Sin cámara ni modelo.
class _Host extends FrontCameraHostApi {
  _Host(this.tester);

  final WidgetTester tester;

  /// Lo que el motor responde a la consulta, y cuánto tarda el puente.
  FaceAnalysisSnapshot? answer;
  Duration delay = Duration.zero;

  @override
  Future<CameraPermissionStatus> checkCameraPermission() async =>
      CameraPermissionStatus.granted;

  @override
  Future<PreviewOpenResult> openFrontPreview(int token) async =>
      FakeFrontCameraBridge.result(token, PreviewOpenStatus.opened);

  @override
  Future<void> closeFrontPreview(int token) async {}

  @override
  Future<FaceAnalysisSnapshot?> getFaceAnalysis(int token) async {
    final a = answer;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return a;
  }
}

const _channel =
    'dev.flutter.pigeon.monitoring_engine.FrontCameraFlutterApi.onFaceAnalysis';

void main() {
  testWidgets('el aviso facial usa el sufijo del host Pigeon', (tester) async {
    final bridge = PigeonFrontCameraBridge(
      host: FrontCameraHostApi(messageChannelSuffix: 'side'),
    );
    final received = <FaceAnalysisSnapshot>[];
    final sub = bridge.faceAnalysis.listen(received.add);
    final s = FakeFrontCameraBridge.face(
      1,
      FaceAnalysisStatus.stopped,
      sequence: 8,
    );
    unawaited(
      tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'dev.flutter.pigeon.monitoring_engine.FrontCameraFlutterApi.onFaceAnalysis.side',
        FrontCameraFlutterApi.pigeonChannelCodec.encodeMessage([s]),
        (_) {},
      ),
    );
    await tester.pump();
    unawaited(sub.cancel());
    await tester.pump();
    FrontCameraFlutterApi.setUp(null);
    FrontCameraFlutterApi.setUp(null, messageChannelSuffix: 'side');
    expect(received, hasLength(1));
    expect(received.single.sequence, 8);
  });
  late _Host host;
  late ProviderContainer container;

  FacePresencePhase phase() => container.read(frontCameraProvider).facePhase;
  int token() => container.read(frontCameraProvider).preview!.token;

  Future<void> setUpBridge(WidgetTester tester) async {
    host = _Host(tester);
    final bridge = PigeonFrontCameraBridge(host: host);
    container = ProviderContainer(
      overrides: [frontCameraBridgeProvider.overrideWithValue(bridge)],
    );
    await container.read(frontCameraProvider.notifier).enter();
  }

  Future<void> tearDownBridge(WidgetTester tester) async {
    container.read(frontCameraProvider.notifier).leave();
    // Deja terminar las consultas del puente aún en curso.
    await tester.pump(const Duration(seconds: 1));
    container.dispose();
    FrontCameraFlutterApi.setUp(null);
  }

  Future<void> deliverWire(WidgetTester tester, FaceAnalysisSnapshot s) async {
    final wire = FrontCameraFlutterApi.pigeonChannelCodec.encodeMessage([s])!;
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      _channel,
      wire,
      (_) {},
    );
    await tester.pump();
  }

  for (final status in [
    FaceAnalysisStatus.noFace,
    FaceAnalysisStatus.oneFace,
    FaceAnalysisStatus.multipleFaces,
  ]) {
    testWidgets('aviso de ${status.name} retenido 5000 ms: el motor ya lo '
        'informa con 5040 ms y no se muestra', (tester) async {
      await setUpBridge(tester);
      final old = FakeFrontCameraBridge.face(
        token(),
        status,
        sequence: 3,
        resultId: 1,
        resultAgeMs: 40,
      );
      await tester.pump(const Duration(milliseconds: 5000));
      // Al consultar, el motor calcula la edad de ese resultado en ese
      // instante (o ya lo retiró): 5040 ms.
      host.answer = FakeFrontCameraBridge.face(
        token(),
        status,
        sequence: 4,
        resultId: 1,
        resultAgeMs: 5040,
      );
      await deliverWire(tester, old);
      await tester.pump();
      expect(phase(), isNot(FacePresencePhase.oneFace));
      expect(phase(), isNot(FacePresencePhase.noFace));
      expect(phase(), isNot(FacePresencePhase.multipleFaces));
      await tearDownBridge(tester);
    });

    testWidgets('control positivo: ${status.name} nuevo con 10 ms de puente '
        'se muestra y caduca a los 700 ms', (tester) async {
      await setUpBridge(tester);
      host
        ..delay = const Duration(milliseconds: 10)
        ..answer = FakeFrontCameraBridge.face(
          token(),
          status,
          sequence: 2,
          resultId: 7,
          resultAgeMs: 40,
        );
      await deliverWire(tester, host.answer!);
      await tester.pump(const Duration(milliseconds: 10));
      final shown = phase();
      expect(shown, isNot(FacePresencePhase.waitingResults));
      expect(shown, isNot(FacePresencePhase.loadingModel));
      // Edad efectiva 50 ms: le quedan 700 ms. Las consultas periódicas del
      // mismo resultado (otra secuencia, misma edad 40) no lo alargan.
      host.answer = FakeFrontCameraBridge.face(
        token(),
        status,
        sequence: 50,
        resultId: 7,
        resultAgeMs: 40,
      );
      await tester.pump(const Duration(milliseconds: 690));
      expect(phase(), shown);
      await tester.pump(const Duration(milliseconds: 20));
      expect(phase(), FacePresencePhase.waitingResults);
      await tearDownBridge(tester);
    });
  }

  testWidgets('la demora del puente cuenta: 711 ms de consulta con edad 40 '
      'no se muestra', (tester) async {
    await setUpBridge(tester);
    host
      ..delay = const Duration(milliseconds: 711)
      ..answer = FakeFrontCameraBridge.face(
        token(),
        FaceAnalysisStatus.oneFace,
        sequence: 2,
        resultId: 9,
        resultAgeMs: 40,
      );
    await deliverWire(tester, host.answer!);
    await tester.pump(const Duration(milliseconds: 711));
    await tester.pump();
    expect(phase(), isNot(FacePresencePhase.oneFace));
    await tearDownBridge(tester);
  });

  /// Revisión 5B (cuarta ronda): el límite es por canal, también entre
  /// wrappers Pigeon distintos.
  testWidgets('dos puentes Pigeon distintos sobre el mismo canal: una sola '
      'llamada pendiente; al terminar, el consumidor vigente consulta', (
    tester,
  ) async {
    final hostA = _GatedHost();
    final hostB = _GatedHost();
    final a = ProviderContainer(
      overrides: [
        frontCameraBridgeProvider.overrideWithValue(
          PigeonFrontCameraBridge(host: hostA),
        ),
      ],
    );
    await a.read(frontCameraProvider.notifier).enter();
    await tester.pump(const Duration(milliseconds: 800));
    a.dispose();
    final b = ProviderContainer(
      overrides: [
        frontCameraBridgeProvider.overrideWithValue(
          PigeonFrontCameraBridge(host: hostB),
        ),
      ],
    );
    await b.read(frontCameraProvider.notifier).enter();
    await tester.pump(const Duration(seconds: 2));
    expect(hostA.calls.length + hostB.calls.length, 1);
    expect(b.read(frontCameraProvider).faceStalled, isTrue);
    // Termina la llamada de A: se libera el canal sin aplicarse en B.
    hostA.calls.single.complete(null);
    await tester.pump(const Duration(milliseconds: 300));
    expect(hostB.calls.length, 1);
    expect(hostA.unfinished + hostB.unfinished, 1);
    b.read(frontCameraProvider.notifier).leave();
    for (final c in hostB.calls) {
      if (!c.isCompleted) c.complete(null);
    }
    await tester.pump(const Duration(seconds: 1));
    b.dispose();
    FrontCameraFlutterApi.setUp(null);
  });

  /// Revisión 5B (quinta ronda): el mensajero nulo y el predeterminado
  /// explícito envían por el mismo canal; la clave es la del mensajero
  /// efectivo. Envío Pigeon generado, retenido por un único manejador.
  testWidgets('mensajero implícito y predeterminado explícito: misma clave y '
      'una sola llamada real pendiente', (tester) async {
    const name =
        'dev.flutter.pigeon.monitoring_engine.FrontCameraHostApi.getFaceAnalysis';
    final held = <Completer<ByteData?>>[];
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMessageHandler(name, (_) {
      final c = Completer<ByteData?>();
      held.add(c);
      return c.future;
    });
    final implicit = PigeonFrontCameraBridge(host: _OpenHost());
    final explicit = PigeonFrontCameraBridge(
      host: _OpenHost(
        binaryMessenger: ServicesBinding.instance.defaultBinaryMessenger,
      ),
    );
    expect(implicit.queryChannel, explicit.queryChannel);
    expect(implicit.queryChannel.hashCode, explicit.queryChannel.hashCode);

    final a = ProviderContainer(
      overrides: [frontCameraBridgeProvider.overrideWithValue(implicit)],
    );
    await a.read(frontCameraProvider.notifier).enter();
    await tester.pump(const Duration(milliseconds: 800));
    a.dispose();
    final b = ProviderContainer(
      overrides: [frontCameraBridgeProvider.overrideWithValue(explicit)],
    );
    await b.read(frontCameraProvider.notifier).enter();
    await tester.pump(const Duration(seconds: 240));
    expect(held, hasLength(1));
    b.read(frontCameraProvider.notifier).leave();
    for (final c in held) {
      c.complete(const StandardMessageCodec().encodeMessage([null]));
    }
    await tester.pump(const Duration(seconds: 1));
    b.dispose();
    messenger.setMockMessageHandler(name, null);
    FrontCameraFlutterApi.setUp(null);
  });

  testWidgets('un canal con otro sufijo es independiente', (tester) async {
    final hostA = _GatedHost();
    final hostC = _GatedHost(messageChannelSuffix: 'otro');
    final a = ProviderContainer(
      overrides: [
        frontCameraBridgeProvider.overrideWithValue(
          PigeonFrontCameraBridge(host: hostA),
        ),
      ],
    );
    final c = ProviderContainer(
      overrides: [
        frontCameraBridgeProvider.overrideWithValue(
          PigeonFrontCameraBridge(host: hostC),
        ),
      ],
    );
    await a.read(frontCameraProvider.notifier).enter();
    await c.read(frontCameraProvider.notifier).enter();
    await tester.pump(const Duration(seconds: 1));
    expect(hostA.calls.length, 1);
    expect(hostC.calls.length, 1);
    a.read(frontCameraProvider.notifier).leave();
    c.read(frontCameraProvider.notifier).leave();
    for (final x in [...hostA.calls, ...hostC.calls]) {
      x.complete(null);
    }
    await tester.pump(const Duration(seconds: 1));
    a.dispose();
    c.dispose();
    FrontCameraFlutterApi.setUp(null);
  });
}

/// Host que retiene cada llamada `getFaceAnalysis` (canal bloqueado).
class _GatedHost extends FrontCameraHostApi {
  _GatedHost({super.messageChannelSuffix});

  final calls = <Completer<FaceAnalysisSnapshot?>>[];

  @override
  Future<CameraPermissionStatus> checkCameraPermission() async =>
      CameraPermissionStatus.granted;

  @override
  Future<PreviewOpenResult> openFrontPreview(int token) async =>
      FakeFrontCameraBridge.result(token, PreviewOpenStatus.opened);

  @override
  Future<void> closeFrontPreview(int token) async {}

  @override
  Future<FaceAnalysisSnapshot?> getFaceAnalysis(int token) {
    final c = Completer<FaceAnalysisSnapshot?>();
    calls.add(c);
    return c.future;
  }

  int get unfinished => calls.where((c) => !c.isCompleted).length;
}

/// Host con permiso y apertura dobles; `getFaceAnalysis` es el envío Pigeon
/// generado, por el mensajero indicado.
class _OpenHost extends FrontCameraHostApi {
  _OpenHost({super.binaryMessenger});

  @override
  Future<CameraPermissionStatus> checkCameraPermission() async =>
      CameraPermissionStatus.granted;

  @override
  Future<PreviewOpenResult> openFrontPreview(int token) async =>
      FakeFrontCameraBridge.result(token, PreviewOpenStatus.opened);

  @override
  Future<void> closeFrontPreview(int token) async {}
}
