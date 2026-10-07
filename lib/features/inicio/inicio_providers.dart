import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_config.dart';
import '../../data/demo_history/demo_history_repository.dart';
import '../../data/demo_history/history_providers.dart';
import '../monitoring/demo_session_controller.dart';
import '../monitoring/domain/session_model.dart';
import '../monitoring/domain/session_summary.dart';
import 'inicio_state.dart';

/// Estado de Inicio (P03) según el modo de la ejecución.
///
/// - Real: motor no comprobado, preparación bloqueada.
/// - Revisión: la variante fija de `VIGIA_DEMO_INICIO`.
/// - Demostración: la sesión vigente o, sin ella, la sesión más reciente del
///   historial guardado (último resumen o registro interrumpido), siempre con
///   `isDemo`.
final inicioStateProvider = Provider<InicioState>((ref) {
  return switch (ref.watch(appModeProvider)) {
    RealMode() => const InicioMotorNoComprobado(),
    InicioReviewMode(:final state) => state,
    DemoMode() => demoInicioState(
      ref.watch(demoSessionProvider),
      ref.watch(latestStoredSessionProvider),
    ),
  };
});

/// Inicio de la demostración a partir de la sesión y del historial.
InicioState demoInicioState(
  DemoSessionState s,
  AsyncValue<StoredSession?> latest,
) {
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
  return switch (latest) {
    AsyncError() => const InicioHistorialPendiente(isDemo: true, failed: true),
    AsyncData(value: null) => const InicioSinHistorial(isDemo: true),
    AsyncData(:final value?) => _fromStored(value),
    _ => const InicioHistorialPendiente(isDemo: true, failed: false),
  };
}

InicioState _fromStored(StoredSession v) {
  final summary = v.summary;
  if (v.isFinalized && summary != null) {
    return InicioUltimoResumen(
      isDemo: true,
      sessionId: v.sessionId,
      recordStatus: v.complete ? 'Completo' : 'Registro incompleto',
      coverage: summary.coverageText,
      episodes: '${summary.episodes}',
    );
  }
  if (v.isInterrupted) {
    return InicioRegistroInterrumpido(
      isDemo: true,
      sourceTag: 'Registro DEMO',
      sessionId: v.sessionId,
      confirmedStart: formatTimeOfDay(v.startedAt.fields),
      lastConfirmedRecord: formatTimeOfDay(v.latestDurableAt.fields),
    );
  }
  // Cierre todavía guardándose: no se presenta un resumen sin totales.
  return const InicioHistorialPendiente(isDemo: true, failed: false);
}
