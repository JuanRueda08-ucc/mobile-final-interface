import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../preparation/preparation_controller.dart';

/// Causas de rechazo de RF06.CA2 (Área 04 §7.4).
enum CalibrationRejection {
  insufficientObservations(
    'Observaciones insuficientes',
    'No se reunieron observaciones suficientes para una referencia.',
  ),
  invalidEyeQuality(
    'Calidad ocular inválida',
    'No puedo evaluar los ojos durante la adquisición.',
  ),
  unstableReference(
    'Referencia inestable',
    'Las observaciones no fueron estables entre sí.',
  );

  const CalibrationRejection(this.title, this.text);

  final String title;
  final String text;
}

/// Fases de Calibración (P05, FL03).
sealed class CalibrationState {
  const CalibrationState();
}

/// Instrucción inicial: Comenzar o Cancelar.
final class CalibrationInstructions extends CalibrationState {
  const CalibrationInstructions();
}

/// «Recogiendo referencia», sin porcentaje ni cuenta atrás (UX05.CA1).
final class CalibrationAcquiring extends CalibrationState {
  const CalibrationAcquiring(this.attempt);

  final int attempt;
}

/// «Calibración completada» con la referencia guardada (RF06.CA1).
final class CalibrationAccepted extends CalibrationState {
  const CalibrationAccepted(this.referenceId);

  final String referenceId;
}

/// Rechazo con causa; no guarda referencia (RF06.CA2, UX05.CA2).
final class CalibrationRejected extends CalibrationState {
  const CalibrationRejected(this.cause);

  final CalibrationRejection cause;
}

/// Calibración **demostrativa**: no adquiere observaciones. El resultado lo
/// elige quien presenta en el panel «Simulación DEMO», rotulado como tal.
class CalibrationController extends Notifier<CalibrationState> {
  var _attempts = 0;

  @override
  CalibrationState build() => const CalibrationInstructions();

  /// Abrir Calibración desde Preparación.
  void open() => state = const CalibrationInstructions();

  /// «Comenzar» o «Reintentar»: nueva adquisición (FL03.2, FL03.7).
  void begin() {
    if (state is CalibrationAcquiring) return;
    state = CalibrationAcquiring(++_attempts);
  }

  /// Resultado simulado aceptado: guarda la referencia para el montaje actual.
  void simulateAccepted() {
    if (state is! CalibrationAcquiring) return;
    final id = ref.read(preparationProvider.notifier).acceptCalibration();
    state = CalibrationAccepted(id);
  }

  /// Resultado simulado rechazado: no guarda ninguna referencia.
  void simulateRejected(CalibrationRejection cause) {
    if (state is! CalibrationAcquiring) return;
    state = CalibrationRejected(cause);
  }

  /// «Cancelar»: detiene la adquisición sin crear referencia ni restaurar una
  /// invalidada (UX05.CA3). Un resultado posterior de este intento se ignora.
  void cancel() => state = const CalibrationInstructions();
}

final calibrationProvider =
    NotifierProvider<CalibrationController, CalibrationState>(
      CalibrationController.new,
    );
