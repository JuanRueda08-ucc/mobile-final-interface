import 'dart:async';

import 'package:monitoring_engine/monitoring_engine.dart';

/// Resultado de una consulta u orden nativa terminada.
final class MonitoringQueryOutcome<T> {
  const MonitoringQueryOutcome({
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

  final T? answer;

  /// Excepción del canal, si la llamada falló.
  final Object? error;
}

/// Suscripción de un consumidor a la terminación de una llamada. Mientras
/// está activa, el ticket guarda su función; [cancel] la suelta.
final class MonitoringQueryListener<T> {
  MonitoringQueryListener._(this._ticket, this._onDone);

  MonitoringQueryTicket<T>? _ticket;
  void Function(MonitoringQueryOutcome<T>)? _onDone;

  /// Desvincula al consumidor: el ticket deja de guardar su función y no la
  /// llamará. Idempotente.
  void cancel() {
    _ticket?._listeners.remove(this);
    _ticket = null;
    _onDone = null;
  }
}

/// Una llamada real en curso por un canal.
final class MonitoringQueryTicket<T> {
  MonitoringQueryTicket._(this.token, this.watch);

  /// Época del consumidor que lanzó la consulta.
  final int token;

  /// Cronómetro monotónico iniciado justo antes de llamar; no se detiene.
  final Stopwatch watch;

  final _listeners = <MonitoringQueryListener<T>>{};
  MonitoringQueryOutcome<T>? _outcome;

  bool get finished => _outcome != null;

  /// Consumidores suscritos todavía (para pruebas y diagnóstico).
  int get listenerCount => _listeners.length;

  /// Llama a [onDone] cuando la llamada termine, en una tarea posterior a la
  /// terminación. No usa `Future.then` sobre un futuro compartido: el ticket
  /// solo guarda las funciones de las suscripciones activas, y cada
  /// consumidor la cancela al salir o desecharse.
  MonitoringQueryListener<T> listen(
    void Function(MonitoringQueryOutcome<T>) onDone,
  ) {
    final l = MonitoringQueryListener<T>._(this, onDone);
    final done = _outcome;
    if (done != null) {
      scheduleMicrotask(() => l._onDone?.call(done));
    } else {
      _listeners.add(l);
    }
    return l;
  }

  void _complete(MonitoringQueryOutcome<T> outcome) {
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

/// Registro de llamadas por canal y operación (fase 5C).
///
/// La llamada de Pigeon no se puede cancelar. Para que nunca haya más de una
/// llamada real pendiente por operación y canal, el registro no vive en la pantalla ni en
/// su controlador, sino aquí, indexado por [ExperimentalMonitoringBridge.queryChannel]
/// (el mensajero efectivo y el sufijo):
/// - sobrevive a desechar el controlador y crear otro, y lo comparten puentes
///   distintos sobre el mismo canal;
/// - no guarda ningún `Ref` ni estado de pantalla: solo la llamada y las
///   suscripciones activas, que cada consumidor cancela al salir;
/// - solo la terminación real de la llamada libera el registro; quién la
///   lanzó y si sigue existiendo no importa. Aplicar o no la respuesta lo
///   decide cada consumidor (ver `ExperimentalMonitoringController`).
///
/// Mientras no hay llamada pendiente no guarda nada: el registro se vacía al
/// terminar cada llamada.
final class MonitoringQueryChannel {
  MonitoringQueryChannel._();

  static final _pending = <Object, MonitoringQueryTicket<dynamic>>{};

  static MonitoringQueryTicket<MonitoringSnapshot>? pendingOn(
    ExperimentalMonitoringBridge bridge,
  ) =>
      _pending[(bridge.queryChannel, 'snapshot')]
          as MonitoringQueryTicket<MonitoringSnapshot>?;

  static MonitoringQueryTicket<MonitoringSnapshot>? start(
    ExperimentalMonitoringBridge bridge,
    int epoch,
    Stopwatch watch,
  ) => _start((bridge.queryChannel, 'snapshot'), epoch, watch, bridge.snapshot);

  static MonitoringQueryTicket<MonitoringCommandResult>? pendingCommand(
    ExperimentalMonitoringBridge bridge,
    String name,
  ) =>
      _pending[(bridge.queryChannel, name)]
          as MonitoringQueryTicket<MonitoringCommandResult>?;

  static MonitoringQueryTicket<MonitoringCommandResult>? startCommand(
    ExperimentalMonitoringBridge bridge,
    String name,
    int epoch,
    Stopwatch watch,
    Future<MonitoringCommandResult> Function() run,
  ) => _start((bridge.queryChannel, name), epoch, watch, run);

  static MonitoringQueryTicket<T>? _start<T>(
    Object key,
    int epoch,
    Stopwatch watch,
    Future<T> Function() run,
  ) {
    if (_pending.containsKey(key)) return null;
    final ticket = MonitoringQueryTicket<T>._(epoch, watch..start());
    _pending[key] = ticket;
    Future<T> call;
    try {
      call = run();
    } catch (e) {
      call = Future<T>.error(e);
    }
    void finish(T? answer, Object? error) {
      if (identical(_pending[key], ticket)) _pending.remove(key);
      ticket._complete(
        MonitoringQueryOutcome<T>(
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
