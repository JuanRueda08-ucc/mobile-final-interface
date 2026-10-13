import 'dart:async';

import 'package:monitoring_engine/monitoring_engine.dart';

/// Resultado de una llamada `getFaceAnalysis` terminada.
final class FaceQueryOutcome {
  const FaceQueryOutcome({required this.elapsed, this.answer, this.error});

  /// Tiempo monotónico desde el inicio de la llamada hasta su terminación,
  /// medido al terminar (no cuando el consumidor lo procesa).
  final Duration elapsed;
  final FaceAnalysisSnapshot? answer;

  /// Excepción del canal, si la llamada falló.
  final Object? error;
}

/// Una llamada real en curso por un canal.
final class FaceQueryTicket {
  FaceQueryTicket._(this.token, this.watch);

  /// Apertura para la que se consultó.
  final int token;

  /// Cronómetro monotónico iniciado justo antes de llamar.
  final Stopwatch watch;

  final _done = Completer<FaceQueryOutcome>();

  /// Se completa cuando la llamada termina de verdad (respuesta o excepción).
  Future<FaceQueryOutcome> get outcome => _done.future;

  bool get finished => _done.isCompleted;
}

/// Coordinador de las consultas `getFaceAnalysis` **por canal** (fase 5B).
///
/// La llamada de Pigeon no se puede cancelar. Para que nunca haya más de una
/// llamada real pendiente por canal, el registro no vive en la pantalla ni en
/// su controlador, sino aquí, indexado por [FrontCameraBridge.queryChannel]:
/// - sobrevive a desechar el controlador y crear otro, y lo comparten puentes
///   distintos sobre el mismo canal;
/// - no guarda ningún `Ref` ni estado de pantalla, solo la llamada;
/// - solo la terminación real de la llamada libera el registro; quién la
///   lanzó y si sigue existiendo no importa. Aplicar o no la respuesta lo
///   decide cada consumidor (ver `FrontCameraController`).
///
/// Mientras no hay llamada pendiente no guarda nada: el registro se vacía al
/// terminar cada llamada.
final class FaceQueryChannel {
  FaceQueryChannel._();

  static final _pending = <Object, FaceQueryTicket>{};

  /// Llamada pendiente en el canal de [bridge], si la hay.
  static FaceQueryTicket? pendingOn(FrontCameraBridge bridge) =>
      _pending[bridge.queryChannel];

  /// Inicia una consulta de [token] si el canal de [bridge] no tiene otra
  /// llamada pendiente; si la tiene, devuelve `null` y no llama.
  ///
  /// [watch] es un cronómetro monotónico sin iniciar (en la app,
  /// `clock.stopwatch()`); se inicia justo antes de llamar.
  static FaceQueryTicket? start(
    FrontCameraBridge bridge,
    int token,
    Stopwatch watch,
  ) {
    final key = bridge.queryChannel;
    if (_pending.containsKey(key)) return null;
    final ticket = FaceQueryTicket._(token, watch..start());
    _pending[key] = ticket;
    Future<FaceAnalysisSnapshot?> call;
    try {
      call = bridge.queryFaceAnalysis(token);
    } catch (e) {
      call = Future.error(e);
    }
    void finish(FaceAnalysisSnapshot? answer, Object? error) {
      ticket.watch.stop();
      if (identical(_pending[key], ticket)) _pending.remove(key);
      ticket._done.complete(
        FaceQueryOutcome(
          elapsed: ticket.watch.elapsed,
          answer: answer,
          error: error,
        ),
      );
    }

    call.then(
      (answer) => finish(answer, null),
      onError: (Object e) => finish(null, e),
    );
    return ticket;
  }
}
