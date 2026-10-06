import 'session_model.dart';

/// Estado simulado de medición y señal en un instante.
final class ScriptPoint {
  const ScriptPoint(this.measurement, this.signal, [this.cause]);

  final Measurement measurement;
  final SignalState signal;

  /// Causa mostrada con «No puedo evaluar» (siempre rotulada como simulada).
  final String? cause;

  bool sameAs(ScriptPoint o) =>
      measurement == o.measurement && signal == o.signal && cause == o.cause;
}

/// Guion **reproducible** de la sesión demostrativa.
///
/// No procede de la cámara ni de la IA: es una secuencia fija, indexada por el
/// tiempo **activo** de la sesión (sin pausas), para enseñar en la
/// presentación todos los estados de P06. Los instantes son de demostración;
/// no son W, C, Tclose, Eend, Rrepeat, Tstale ni Krecover, que siguen
/// pendientes en el Área 05.
///
/// - 0–2 s: Inicializando (No evaluable).
/// - Después, un ciclo de 43 s que se repite:
///   - 0 s: Utilizable, sin señales persistentes;
///   - 6 s: advertencia;
///   - 12 s: sin señales persistentes;
///   - 18 s: cierre ocular prolongado;
///   - 22 s: sin señales persistentes;
///   - 28 s: no evaluable (medición no disponible);
///   - 32 s: recuperando medición (limitada, no evaluable);
///   - 35 s: sin señales persistentes.
///
/// Tras reanudar una pausa, la medición vuelve a Inicializando durante
/// [recoveryAfterResume]: las ventanas anteriores a la pausa no se reutilizan
/// (RF17.CA3).
abstract final class DemoScript {
  static const initialization = Duration(seconds: 2);
  static const cycle = Duration(seconds: 43);
  static const recoveryAfterResume = Duration(seconds: 2);
  static const simulatedCause = 'Ojos no evaluables (simulado)';

  static const _initializing = ScriptPoint(
    Measurement.initializing,
    SignalState.notEvaluable,
  );

  static const steps = <(Duration, ScriptPoint)>[
    (
      Duration.zero,
      ScriptPoint(Measurement.usable, SignalState.noPersistentSignals),
    ),
    (
      Duration(seconds: 6),
      ScriptPoint(Measurement.usable, SignalState.warning),
    ),
    (
      Duration(seconds: 12),
      ScriptPoint(Measurement.usable, SignalState.noPersistentSignals),
    ),
    (
      Duration(seconds: 18),
      ScriptPoint(Measurement.usable, SignalState.prolongedEyeClosure),
    ),
    (
      Duration(seconds: 22),
      ScriptPoint(Measurement.usable, SignalState.noPersistentSignals),
    ),
    (
      Duration(seconds: 28),
      ScriptPoint(
        Measurement.unavailable,
        SignalState.notEvaluable,
        simulatedCause,
      ),
    ),
    (
      Duration(seconds: 32),
      ScriptPoint(Measurement.limited, SignalState.notEvaluable),
    ),
    (
      Duration(seconds: 35),
      ScriptPoint(Measurement.usable, SignalState.noPersistentSignals),
    ),
  ];

  /// Estado en el tiempo activo [active]. [recoverUntil]: fin del periodo de
  /// inicialización tras reanudar, si lo hay.
  static ScriptPoint at(Duration active, {Duration? recoverUntil}) {
    if (active < initialization) return _initializing;
    if (recoverUntil != null && active < recoverUntil) return _initializing;
    final p = (active - initialization).inMicroseconds % cycle.inMicroseconds;
    var point = steps.first.$2;
    for (final (at, s) in steps) {
      if (at.inMicroseconds <= p) point = s;
    }
    return point;
  }

  /// Siguiente instante activo, estrictamente posterior a [active], en que el
  /// guion puede cambiar.
  static Duration next(Duration active, {Duration? recoverUntil}) {
    final candidates = <Duration>[];
    if (active < initialization) candidates.add(initialization);
    if (recoverUntil != null && active < recoverUntil) {
      candidates.add(recoverUntil);
    }
    final base = active < initialization
        ? Duration.zero
        : active - initialization;
    final cycles = base.inMicroseconds ~/ cycle.inMicroseconds;
    for (var c = cycles; c <= cycles + 1; c++) {
      for (final (at, _) in steps) {
        final t = initialization + cycle * c + at;
        if (t > active) candidates.add(t);
      }
    }
    candidates.sort();
    return candidates.first;
  }
}
