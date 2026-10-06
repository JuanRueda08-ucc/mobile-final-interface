import 'session_model.dart';

/// Resumen de una sesión (P07, RF21) calculado **solo** desde sus eventos.
///
/// - Evaluable: tiempo activo con medición Utilizable.
/// - No evaluable: tiempo activo con medición Inicializando, Limitada o No
///   disponible.
/// - Pausado: desde la pausa confirmada hasta la reanudación confirmada (o
///   hasta la solicitud de cierre).
/// - Desconocido: cero en la demostración, porque el cierre siempre se
///   confirma; no se inventa un tramo desconocido.
/// - Cobertura: evaluable ÷ (evaluable + no evaluable), sin pausas ni tiempo
///   desconocido en el denominador (UX14). Sin denominador: No disponible.
/// - Episodios: identificadores únicos; los sonidos no suman episodios.
final class SessionSummary {
  const SessionSummary({
    required this.sessionId,
    required this.startedAt,
    required this.finishedAt,
    required this.evaluable,
    required this.notEvaluable,
    required this.paused,
    required this.unknown,
    required this.episodeIds,
    required this.warnings,
    required this.closures,
    required this.soundsPlayed,
    required this.soundsFailed,
    required this.pauses,
  });

  factory SessionSummary.fromEvents({
    required String sessionId,
    required DateTime startedAt,
    required DateTime finishedAt,
    required List<SessionEvent> events,
  }) {
    var evaluable = Duration.zero,
        notEvaluable = Duration.zero,
        paused = Duration.zero;
    var measurement = Measurement.initializing;
    var inPause = false;
    var t = Duration.zero;
    final episodes = <String>{};
    var warnings = 0, closures = 0, played = 0, failed = 0, pauses = 0;
    final sorted = [...events]
      ..sort((a, b) {
        final c = a.offset.compareTo(b.offset);
        return c != 0 ? c : a.sequence - b.sequence;
      });
    for (final e in sorted) {
      final segment = e.offset - t;
      if (!segment.isNegative) {
        if (inPause) {
          paused += segment;
        } else if (measurement == Measurement.usable) {
          evaluable += segment;
        } else {
          notEvaluable += segment;
        }
        t = e.offset;
      }
      switch (e.type) {
        case SessionEventType.measurementChanged:
          measurement = e.measurement!;
        case SessionEventType.pauseStarted:
          inPause = true;
          pauses++;
        case SessionEventType.pauseEnded:
          inPause = false;
        case SessionEventType.episodeStarted:
          if (episodes.add(e.episodeId!)) {
            if (e.episodeKind == EpisodeKind.warning) {
              warnings++;
            } else {
              closures++;
            }
          }
        case SessionEventType.soundPlayed:
          played++;
        case SessionEventType.soundFailed:
          failed++;
        case SessionEventType.stopRequested:
          // Fin del tiempo representado: lo posterior no se mide.
          return SessionSummary(
            sessionId: sessionId,
            startedAt: startedAt,
            finishedAt: finishedAt,
            evaluable: evaluable,
            notEvaluable: notEvaluable,
            paused: paused,
            unknown: Duration.zero,
            episodeIds: episodes,
            warnings: warnings,
            closures: closures,
            soundsPlayed: played,
            soundsFailed: failed,
            pauses: pauses,
          );
        default:
          break;
      }
    }
    throw StateError('La sesión $sessionId no tiene solicitud de cierre.');
  }

  final String sessionId;
  final DateTime startedAt;
  final DateTime finishedAt;
  final Duration evaluable;
  final Duration notEvaluable;
  final Duration paused;
  final Duration unknown;
  final Set<String> episodeIds;
  final int warnings;
  final int closures;
  final int soundsPlayed;
  final int soundsFailed;
  final int pauses;

  int get episodes => episodeIds.length;

  Duration get represented => evaluable + notEvaluable + paused + unknown;

  /// Cobertura en [0, 1], o `null` si no hay denominador (UX14.CA3).
  double? get coverage {
    final d = evaluable + notEvaluable;
    if (d == Duration.zero) return null;
    return evaluable.inMicroseconds / d.inMicroseconds;
  }

  /// «83,3 %» o «No disponible».
  String get coverageText {
    final c = coverage;
    if (c == null) return 'No disponible';
    return '${(c * 100).toStringAsFixed(1).replaceAll('.', ',')} %';
  }
}

/// «12,4 s»: segundos con una cifra decimal y coma.
String formatSeconds(Duration d) =>
    '${(d.inMilliseconds / 1000).toStringAsFixed(1).replaceAll('.', ',')} s';

/// «00:12:40».
String formatClock(Duration d) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
}

/// «08:12».
String formatTimeOfDay(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
