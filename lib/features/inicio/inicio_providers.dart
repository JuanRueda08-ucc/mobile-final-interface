import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_config.dart';
import '../monitoring/demo_session_controller.dart';
import '../monitoring/domain/session_model.dart';
import '../monitoring/domain/session_summary.dart';
import 'inicio_state.dart';

/// Estado de Inicio (P03) según el modo de la ejecución.
///
/// - Real: motor no comprobado, preparación bloqueada.
/// - Revisión: la variante fija de `VIGIA_DEMO_INICIO`.
/// - Demostración: se deriva de la sesión demostrativa y del último resumen
///   de esta ejecución (en memoria), siempre con `isDemo`.
final inicioStateProvider = Provider<InicioState>((ref) {
  return switch (ref.watch(appModeProvider)) {
    RealMode() => const InicioMotorNoComprobado(),
    InicioReviewMode(:final state) => state,
    DemoMode() => demoInicioState(
      ref.watch(demoSessionProvider),
      ref.watch(lastSummaryProvider),
    ),
  };
});

/// Inicio de la demostración a partir de la sesión y el último resumen.
InicioState demoInicioState(DemoSessionState s, SessionSummary? last) {
  final id = s.sessionId;
  if (s.isVigente) {
    // Iniciando sin ID confirmado: no se presenta como sesión activa.
    if (id == null) return const InicioMotorDesconocido(isDemo: true);
    return InicioSesionVigente(
      isDemo: true,
      sessionId: id,
      paused: s.lifecycle == SessionLifecycle.paused,
    );
  }
  if (last != null) {
    return InicioUltimoResumen(
      isDemo: true,
      sessionId: last.sessionId,
      recordStatus: 'Completo · en memoria de esta ejecución',
      coverage: last.coverageText,
      episodes: '${last.episodes}',
    );
  }
  return const InicioSinHistorial(isDemo: true);
}
