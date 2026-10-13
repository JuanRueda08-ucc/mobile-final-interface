import 'dart:async';

import 'package:monitoring_engine/monitoring_engine.dart';

/// Doble de [FrontCameraBridge] (fases 5A y 5B). No abre ninguna cámara ni
/// ejecuta ningún modelo: cada respuesta y cada resultado facial los decide
/// la prueba ([emitFace]), y pueden retenerse para simular respuestas
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
  Object? restartError;

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
  final _faces = StreamController<FaceAnalysisSnapshot>.broadcast();

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

  @override
  Stream<FaceAnalysisSnapshot> get faceAnalysis => _faces.stream;

  /// Respuesta de [restartFaceAnalysis].
  bool restartAnswer = true;

  @override
  Future<bool> restartFaceAnalysis(int token) {
    calls.add('restartFace:$token');
    if (restartError != null) return Future.error(restartError!);
    return Future.value(restartAnswer);
  }

  /// Último `sequence` emitido por el doble (todas las aperturas).
  int _sequence = 0;

  /// Estado actual del «motor» por apertura: lo que respondería una consulta.
  final engineState = <int, FaceAnalysisSnapshot>{};

  /// Retiene las respuestas a consultas en [pendingQueries] (demora del
  /// puente). La respuesta se crea al consultar, como en el motor.
  bool holdQueries = false;
  final pendingQueries =
      <(Completer<FaceAnalysisSnapshot?>, FaceAnalysisSnapshot?)>[];
  Object? queryError;

  @override
  Future<FaceAnalysisSnapshot?> queryFaceAnalysis(int token) {
    calls.add('query:$token');
    if (queryError != null) return Future.error(queryError!);
    final current = engineState[token];
    final answer = current == null
        ? null
        : face(
            token,
            current.status,
            faceCount: current.faceCount,
            expired: current.expired,
            errorCode: current.errorCode,
            generation: current.generation,
            sequence: ++_sequence,
            resultId: current.resultId,
            resultAgeMs: current.resultAgeMs,
          );
    if (holdQueries) {
      final c = Completer<FaceAnalysisSnapshot?>();
      pendingQueries.add((c, answer));
      return c.future;
    }
    return Future.value(answer);
  }

  /// Entrega las respuestas retenidas (creadas cuando se consultó).
  void releaseQueries() {
    final pending = List.of(pendingQueries);
    pendingQueries.clear();
    for (final (c, answer) in pending) {
      c.complete(answer);
    }
  }

  /// Completa las llamadas retenidas con [answer] (en lugar de lo que había
  /// al consultar), como una respuesta tardía cualquiera.
  void releaseQueriesWith(FaceAnalysisSnapshot? answer) {
    final pending = List.of(pendingQueries);
    pendingQueries.clear();
    for (final (c, _) in pending) {
      c.complete(answer);
    }
  }

  /// Hace fallar las llamadas retenidas (excepción tardía del canal).
  void failQueries(Object error) {
    final pending = List.of(pendingQueries);
    pendingQueries.clear();
    for (final (c, _) in pending) {
      c.completeError(error);
    }
  }

  /// Llamadas reales sin terminar (no identificadores lógicos).
  int get unfinishedQueries =>
      pendingQueries.where((q) => !q.$1.isCompleted).length;

  int get queries => calls.where((c) => c.startsWith('query:')).length;

  /// Cada doble es su propio canal.
  @override
  Object get queryChannel => this;

  /// Resultado facial del motor para [token] (por defecto, la apertura
  /// abierta más reciente): actualiza [engineState] y lo avisa.
  ///
  /// [sequence] es creciente por defecto, como en el motor. En una detección,
  /// [resultId] vale 9 por defecto: emitir dos veces sin indicarlo es el
  /// mismo resultado (un latido o una repetición), no una inferencia nueva.
  /// [resultAgeMs] es la edad que el motor informa al crear cada mensaje
  /// (40 ms por defecto en las detecciones).
  void emitFace(
    FaceAnalysisStatus status, {
    int? token,
    int? faceCount,
    bool expired = false,
    String? errorCode,
    int generation = 1,
    int? sequence,
    int? resultId,
    int? resultAgeMs,
  }) {
    final t = token ?? openTokens.last;
    final snapshot = face(
      t,
      status,
      faceCount: faceCount,
      expired: expired,
      errorCode: errorCode,
      generation: generation,
      sequence: sequence ?? ++_sequence,
      resultId: resultId,
      resultAgeMs: resultAgeMs,
    );
    engineState[t] = snapshot;
    _faces.add(snapshot);
  }

  /// Entrega otra vez exactamente el mismo mensaje (mismo `sequence`).
  void emitRaw(FaceAnalysisSnapshot snapshot) => _faces.add(snapshot);

  static FaceAnalysisSnapshot face(
    int token,
    FaceAnalysisStatus status, {
    int? faceCount,
    bool expired = false,
    String? errorCode,
    int generation = 1,
    int sequence = 1,
    int? resultId,
    int? resultAgeMs,
  }) => FaceAnalysisSnapshot(
    token: token,
    sequence: sequence,
    generation: generation,
    status: status,
    resultId: switch (status) {
      FaceAnalysisStatus.noFace ||
      FaceAnalysisStatus.oneFace ||
      FaceAnalysisStatus.multipleFaces => resultId ?? 9,
      _ => null,
    },
    faceCount:
        faceCount ??
        switch (status) {
          FaceAnalysisStatus.noFace => 0,
          FaceAnalysisStatus.oneFace => 1,
          FaceAnalysisStatus.multipleFaces => 2,
          _ => null,
        },
    resultAgeMs: switch (status) {
      FaceAnalysisStatus.noFace ||
      FaceAnalysisStatus.oneFace ||
      FaceAnalysisStatus.multipleFaces => resultAgeMs ?? 40,
      _ => null,
    },
    maxFaces: 2,
    staleAfterMs: 750,
    framesSubmitted: 10,
    resultsAccepted: 9,
    framesDropped: 1,
    resultsDiscarded: 0,
    expired: expired,
    errorCode: errorCode,
  );

  int get restarts => calls.where((c) => c.startsWith('restartFace:')).length;

  int get opens => calls.where((c) => c.startsWith('open:')).length;
  int get requests => calls.where((c) => c == 'request').length;
}
