import 'dart:async';

import 'package:monitoring_engine/monitoring_engine.dart';

/// Resultado de una llamada `getFaceAnalysis` terminada.
final class FaceQueryOutcome {
  const FaceQueryOutcome({
    required this.finishedIn,
    required this.watch,
    this.answer,
    this.error,
  });

  /// Tiempo monotónico desde el inicio de la llamada hasta su terminación.
  /// Sirve para el plazo de recepción, no para la edad del resultado.
  final Duration finishedIn;

  /// Cronómetro de la llamada, iniciado justo antes de llamar y que **sigue
  /// corriendo** tras la terminación: la edad de la respuesta se mide con
  /// `watch.elapsed` en el momento de aplicarla, de modo que incluye el
  /// despacho hasta el consumidor.
  final Stopwatch watch;

  final FaceAnalysisSnapshot? answer;

  /// Excepción del canal, si la llamada falló.
  final Object? error;
}

/// Suscripción de un consumidor a la terminación de una llamada. Mientras
/// está activa, el ticket guarda su función; [cancel] la suelta.
final class FaceQueryListener {
  FaceQueryListener._(this._ticket, this._onDone);

  FaceQueryTicket? _ticket;
  void Function(FaceQueryOutcome)? _onDone;

  /// Desvincula al consumidor: el ticket deja de guardar su función y no la
  /// llamará. Idempotente.
  void cancel() {
    _ticket?._listeners.remove(this);
    _ticket = null;
    _onDone = null;
  }
}

/// Una llamada real en curso por un canal.
final class FaceQueryTicket {
  FaceQueryTicket._(this.token, this.watch);

  /// Apertura para la que se consultó.
  final int token;

  /// Cronómetro monotónico iniciado justo antes de llamar; no se detiene.
  final Stopwatch watch;

  final _listeners = <FaceQueryListener>{};
  FaceQueryOutcome? _outcome;

  bool get finished => _outcome != null;

  /// Consumidores suscritos todavía (para pruebas y diagnóstico).
  int get listenerCount => _listeners.length;

  /// Llama a [onDone] cuando la llamada termine, en una tarea posterior a la
  /// terminación. No usa `Future.then` sobre un futuro compartido: el ticket
  /// solo guarda las funciones de las suscripciones activas, y cada
  /// consumidor la cancela al salir o desecharse.
  FaceQueryListener listen(void Function(FaceQueryOutcome) onDone) {
    final l = FaceQueryListener._(this, onDone);
    final done = _outcome;
    if (done != null) {
      scheduleMicrotask(() => l._onDone?.call(done));
    } else {
      _listeners.add(l);
    }
    return l;
  }

  void _complete(FaceQueryOutcome outcome) {
    _outcome = outcome;
    // La entrega va en una microtarea propia: la edad la mide cada consumidor
    // al aplicar, con el cronómetro en marcha.
    scheduleMicrotask(() {
      final ls = _listeners.toList();
      _listeners.clear();
      for (final l in ls) {
        final f = l._onDone;
        l._ticket = null;
        l._onDone = null;
        f?.call(outcome);
      }
    });
  }
}

/// Coordinador de las consultas `getFaceAnalysis` **por canal** (fase 5B).
///
/// La llamada de Pigeon no se puede cancelar. Para que nunca haya más de una
/// llamada real pendiente por canal, el registro no vive en la pantalla ni en
/// su controlador, sino aquí, indexado por [FrontCameraBridge.queryChannel]
/// (el mensajero efectivo y el sufijo):
/// - sobrevive a desechar el controlador y crear otro, y lo comparten puentes
///   distintos sobre el mismo canal;
/// - no guarda ningún `Ref` ni estado de pantalla: solo la llamada y las
///   suscripciones activas, que cada consumidor cancela al salir;
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
      if (identical(_pending[key], ticket)) _pending.remove(key);
      ticket._complete(
        FaceQueryOutcome(
          finishedIn: ticket.watch.elapsed,
          watch: ticket.watch,
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
