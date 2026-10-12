import 'dart:async';

import 'package:monitoring_engine/monitoring_engine.dart';

/// Doble de [FrontCameraBridge] (fase 5A). No abre ninguna cámara: cada
/// respuesta la decide la prueba, y puede retenerse para simular respuestas
/// tardías. Registra las llamadas en [calls].
class FakeFrontCameraBridge implements FrontCameraBridge {
  FakeFrontCameraBridge({this.permission = CameraPermissionStatus.denied});

  /// Respuesta de [checkPermission].
  CameraPermissionStatus permission;

  /// Respuesta de la siguiente solicitud; nula: se retiene en [pendingRequest].
  CameraPermissionStatus? requestAnswer;

  /// Estado de apertura por defecto; nulo: se retiene en [pendingOpens].
  PreviewOpenStatus? openAnswer = PreviewOpenStatus.opened;

  /// Errores que devolverán las operaciones mientras no sean nulos (por
  /// ejemplo, `PlatformException(code: 'channel-error')`).
  Object? checkError;
  Object? requestError;
  Object? openError;
  Object? closeError;

  /// Retiene la siguiente consulta en [pendingCheck].
  bool holdCheck = false;
  Completer<CameraPermissionStatus>? pendingCheck;

  bool settingsOpened = false;
  final calls = <String>[];
  final pendingOpens = <int, Completer<PreviewOpenResult>>{};
  Completer<CameraPermissionStatus>? pendingRequest;

  /// Tokens abiertos y no cerrados, según el doble.
  final openTokens = <int>{};
  final _closures = StreamController<PreviewClosedEvent>.broadcast();

  static PreviewOpenResult result(int token, PreviewOpenStatus status) =>
      PreviewOpenResult(
        token: token,
        status: status,
        textureId: status == PreviewOpenStatus.opened ? 7 : null,
        width: status == PreviewOpenStatus.opened ? 480 : null,
        height: status == PreviewOpenStatus.opened ? 640 : null,
        rotationDegrees: status == PreviewOpenStatus.opened ? 0 : null,
        mirrored: status == PreviewOpenStatus.opened ? true : null,
      );

  @override
  Future<CameraPermissionStatus> checkPermission() {
    calls.add('check');
    if (checkError != null) return Future.error(checkError!);
    if (holdCheck) return (pendingCheck = Completer()).future;
    return Future.value(permission);
  }

  @override
  Future<CameraPermissionStatus> requestPermission() {
    calls.add('request');
    if (requestError != null) return Future.error(requestError!);
    final answer = requestAnswer;
    if (answer != null) {
      if (answer == CameraPermissionStatus.granted) permission = answer;
      return Future.value(answer);
    }
    return (pendingRequest = Completer()).future;
  }

  /// Hace fallar la solicitud retenida.
  void failRequest(Object error) {
    pendingRequest!.completeError(error);
    pendingRequest = null;
  }

  /// Responde la solicitud retenida.
  void answerRequest(CameraPermissionStatus status) {
    if (status == CameraPermissionStatus.granted) permission = status;
    pendingRequest!.complete(status);
    pendingRequest = null;
  }

  @override
  Future<bool> openAppSettings() async {
    calls.add('settings');
    settingsOpened = true;
    return true;
  }

  @override
  Future<PreviewOpenResult> openPreview(int token) {
    calls.add('open:$token');
    if (openError != null) return Future.error(openError!);
    final answer = openAnswer;
    if (answer != null) {
      if (answer == PreviewOpenStatus.opened) openTokens.add(token);
      return Future.value(result(token, answer));
    }
    return (pendingOpens[token] = Completer()).future;
  }

  /// Hace fallar una apertura retenida.
  void failOpen(int token, Object error) {
    pendingOpens.remove(token)!.completeError(error);
  }

  /// Responde una apertura retenida.
  void answerOpen(int token, PreviewOpenStatus status) {
    if (status == PreviewOpenStatus.opened) openTokens.add(token);
    pendingOpens.remove(token)!.complete(result(token, status));
  }

  @override
  Future<void> closePreview(int token) {
    calls.add('close:$token');
    openTokens.remove(token);
    if (closeError != null) return Future.error(closeError!);
    return Future.value();
  }

  /// Cierre decidido por el lado nativo.
  void emitClosed(int token, PreviewCloseReason reason) {
    openTokens.remove(token);
    _closures.add(PreviewClosedEvent(token: token, reason: reason));
  }

  @override
  Stream<PreviewClosedEvent> get closures => _closures.stream;

  int get opens => calls.where((c) => c.startsWith('open:')).length;
  int get requests => calls.where((c) => c == 'request').length;
}
