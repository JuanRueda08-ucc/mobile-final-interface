/// Ejes y eventos de la sesión demostrativa (UX §5.1, Área 04 §4.1).
///
/// Los nombres siguen el contrato público del motor para que la sustitución
/// por el motor real (fase posterior) no cambie la presentación. Todos los
/// valores de esta fase son simulados.
library;

/// Ciclo de la sesión. `none`: no hay sesión vigente.
enum SessionLifecycle { none, starting, active, paused, stopping, finalized }

/// Disponibilidad de la medición.
enum Measurement {
  initializing('Inicializando'),
  usable('Utilizable'),
  limited('Limitada'),
  unavailable('No disponible');

  const Measurement(this.text);

  final String text;
}

/// Resultado que admite la política. Sin porcentajes de fatiga (RF10, UX07).
enum SignalState {
  notEvaluable('No evaluable'),
  noPersistentSignals('Sin señales persistentes'),
  warning('Advertencia'),
  prolongedEyeClosure('Alerta por cierre prolongado');

  const SignalState(this.text);

  final String text;

  bool get isAlert => this == warning || this == prolongedEyeClosure;
}

/// Orden pendiente de confirmación (Iniciando, Pausando, Reanudando,
/// Finalizando; UX §5.3).
enum PendingOperation {
  start('Iniciando'),
  pause('Pausando'),
  resume('Reanudando'),
  finish('Finalizando');

  const PendingOperation(this.text);

  final String text;
}

enum EpisodeKind { warning, prolongedEyeClosure }

enum SessionEventType {
  started,
  measurementChanged,
  signalChanged,
  episodeStarted,
  episodeEnded,
  soundPlayed,
  soundFailed,
  pauseStarted,
  pauseEnded,
  stopRequested,
  finished,
}

/// Hecho de la sesión, con su desplazamiento monotónico desde el inicio
/// confirmado (`sessionOffset`, Área 04 §5). Incluye el tiempo en pausa.
final class SessionEvent {
  const SessionEvent({
    required this.sequence,
    required this.type,
    required this.offset,
    this.measurement,
    this.signal,
    this.episodeId,
    this.episodeKind,
    this.detail,
  });

  final int sequence;
  final SessionEventType type;
  final Duration offset;
  final Measurement? measurement;
  final SignalState? signal;
  final String? episodeId;
  final EpisodeKind? episodeKind;
  final String? detail;

  @override
  String toString() =>
      '#$sequence ${type.name} @${offset.inMilliseconds}ms'
      '${measurement == null ? '' : ' ${measurement!.name}'}'
      '${signal == null ? '' : ' ${signal!.name}'}'
      '${episodeId == null ? '' : ' $episodeId'}';
}
