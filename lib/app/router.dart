import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/calibration/calibration_screen.dart';
import '../features/inicio/inicio_screen.dart';
import '../features/monitoring/demo_session_controller.dart';
import '../features/monitoring/domain/session_model.dart';
import '../features/monitoring/monitoring_screen.dart';
import '../features/preparation/preparation_screen.dart';
import '../features/summary/summary_screen.dart';
import '../core/design_system/tokens.dart';
import 'app_config.dart';

/// Rutas del recorrido (UX §2.2): Preparación, Calibración y Monitoreo no
/// muestran la barra principal.
abstract final class VigiaRoutes {
  static const inicio = '/';
  static const preparacion = '/preparacion';
  static const calibracion = '/preparacion/calibracion';
  static const monitoreo = '/monitoreo';
  static const resumen = '/resumen';
}

/// Guardas compartidas (UX §4.2: «Las rutas directas también deben aplicar
/// estos bloqueos»). Devuelve la ruta a la que redirigir, o `null`.
@visibleForTesting
String? vigiaRedirect({
  required AppMode mode,
  required DemoSessionState session,
  required bool hasSummary,
  required String location,
}) {
  if (location == VigiaRoutes.inicio) return null;
  // Sin modo demostración no hay recorrido: solo Inicio (motor no comprobado
  // o variante de revisión).
  if (mode is! DemoMode) return VigiaRoutes.inicio;

  final vigente = session.isVigente;
  if (location.startsWith(VigiaRoutes.preparacion)) {
    // Con sesión vigente no se prepara otra ni se recalibra (UX §4.2).
    return vigente ? VigiaRoutes.inicio : null;
  }
  if (location == VigiaRoutes.monitoreo) {
    if (vigente) return null;
    // Cierre confirmado: abre Resumen; no se reabre el monitoreo cerrado
    // (FL07.4, UX12.CA3).
    if (session.lifecycle == SessionLifecycle.finalized && hasSummary) {
      return VigiaRoutes.resumen;
    }
    return VigiaRoutes.inicio;
  }
  if (location == VigiaRoutes.resumen) {
    return hasSummary ? null : VigiaRoutes.inicio;
  }
  return VigiaRoutes.inicio;
}

final routerProvider = Provider<GoRouter>((ref) {
  final mode = ref.watch(appModeProvider);
  // Las guardas se reevalúan cuando cambia el ciclo de la sesión.
  final refresh = ValueNotifier<int>(0);
  ref.listen(
    demoSessionProvider.select((s) => (s.lifecycle, s.sessionId)),
    (_, _) => refresh.value++,
  );
  final router = GoRouter(
    initialLocation: VigiaRoutes.inicio,
    refreshListenable: refresh,
    redirect: (context, state) => vigiaRedirect(
      mode: mode,
      session: ref.read(demoSessionProvider),
      // Lectura directa: dentro de la notificación del cambio de ciclo, un
      // proveedor derivado podría no estar invalidado todavía.
      hasSummary: ref.read(demoSessionProvider.notifier).lastSummary != null,
      location: state.matchedLocation,
    ),
    routes: [
      GoRoute(
        path: VigiaRoutes.inicio,
        pageBuilder: (context, state) => _page(state, const InicioScreen()),
        routes: [
          GoRoute(
            path: 'preparacion',
            pageBuilder: (context, state) =>
                _page(state, const PreparationScreen()),
            routes: [
              GoRoute(
                path: 'calibracion',
                pageBuilder: (context, state) =>
                    _page(state, const CalibrationScreen()),
              ),
            ],
          ),
          GoRoute(
            path: 'resumen',
            pageBuilder: (context, state) =>
                _page(state, const SummaryScreen()),
          ),
        ],
      ),
      GoRoute(
        path: VigiaRoutes.monitoreo,
        // P06 entra sin animación (B5.2): fondo estable.
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const MonitoringScreen(),
        ),
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

/// Entrada entre pantallas de B5.2: opacidad 0→1 y desplazamiento de 12 px,
/// 260 ms, `cubic-bezier(.22,1,.36,1)`. Con movimiento reducido no hay
/// animación.
Page<void> _page(GoRouterState state, Widget child) => CustomTransitionPage(
  key: state.pageKey,
  child: child,
  transitionDuration: const Duration(milliseconds: 260),
  reverseTransitionDuration: const Duration(milliseconds: 180),
  transitionsBuilder: (context, animation, _, child) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final a = CurvedAnimation(parent: animation, curve: VigiaMotion.press);
    return FadeTransition(
      opacity: a,
      child: AnimatedBuilder(
        animation: a,
        builder: (context, child) => Transform.translate(
          offset: Offset(12 * (1 - a.value), 0),
          child: child,
        ),
        child: child,
      ),
    );
  },
);
