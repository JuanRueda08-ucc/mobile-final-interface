import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/calibration/calibration_screen.dart';
import '../features/history/history_screen.dart';
import '../features/history/session_detail_screen.dart';
import '../features/inicio/inicio_screen.dart';
import '../features/monitoring/demo_session_controller.dart';
import '../features/monitoring/domain/session_model.dart';
import '../features/monitoring/monitoring_screen.dart';
import '../features/preparation/preparation_controller.dart';
import '../features/preparation/preparation_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/sound_screen.dart';
import '../features/summary/summary_screen.dart';
import '../core/design_system/tokens.dart';
import 'app_config.dart';

/// Rutas (UX §2): Inicio, Historial y Ajustes con barra principal; el
/// recorrido (Preparación, Calibración, Monitoreo) sin ella.
abstract final class VigiaRoutes {
  static const inicio = '/';
  static const preparacion = '/preparacion';
  static const calibracion = '/preparacion/calibracion';
  static const monitoreo = '/monitoreo';
  static const historial = '/historial';
  static const ajustes = '/ajustes';
  static const sonido = '/ajustes/sonido';

  /// P07 de una sesión guardada.
  static String resumen(String sessionId) => '/resumen/$sessionId';

  /// P09 de una sesión guardada.
  static String detalle(String sessionId) => '/historial/$sessionId';
}

/// Guardas compartidas (UX §4.2: «Las rutas directas también deben aplicar
/// estos bloqueos»). Devuelve la ruta a la que redirigir, o `null`.
///
/// Detalle de sesión (P09) y Sonido (P13) se abren también con sesión
/// vigente, pero muestran «Sesión en curso» en vez de su contenido (UX11.CA2,
/// B5.2 `vBLK`).
@visibleForTesting
String? vigiaRedirect({
  required AppMode mode,
  required DemoSessionState session,
  required bool canCalibrate,
  required String location,
}) {
  if (location == VigiaRoutes.inicio) return null;
  // Sin modo demostración no hay recorrido: solo Inicio (motor no comprobado
  // o variante de revisión).
  if (mode is! DemoMode) return VigiaRoutes.inicio;

  final vigente = session.isVigente;
  if (location.startsWith(VigiaRoutes.preparacion)) {
    // Con sesión vigente no se prepara otra ni se recalibra (UX §4.2).
    if (vigente) return VigiaRoutes.inicio;
    // Calibrar exige permiso, cámara y modelo, como el botón de P04.
    if (location == VigiaRoutes.calibracion && !canCalibrate) {
      return VigiaRoutes.preparacion;
    }
    return null;
  }
  if (location == VigiaRoutes.monitoreo) {
    if (vigente) return null;
    // Cierre confirmado: abre su Resumen; no se reabre el monitoreo cerrado
    // (FL07.4, UX12.CA3).
    if (session.lifecycle == SessionLifecycle.finalized) {
      return VigiaRoutes.resumen(session.sessionId!);
    }
    return VigiaRoutes.inicio;
  }
  if (location.startsWith('/resumen/') ||
      location.startsWith(VigiaRoutes.historial) ||
      location.startsWith(VigiaRoutes.ajustes)) {
    return null;
  }
  return VigiaRoutes.inicio;
}

final routerProvider = Provider<GoRouter>((ref) {
  final mode = ref.watch(appModeProvider);
  // Las guardas se reevalúan cuando cambia el ciclo de la sesión o la
  // posibilidad de calibrar.
  final refresh = ValueNotifier<int>(0);
  ref.listen(
    demoSessionProvider.select((s) => (s.lifecycle, s.sessionId)),
    (_, _) => refresh.value++,
  );
  ref.listen(
    preparationProvider.select((p) => p.canCalibrate),
    (_, _) => refresh.value++,
  );
  final router = GoRouter(
    initialLocation: VigiaRoutes.inicio,
    refreshListenable: refresh,
    redirect: (context, state) => vigiaRedirect(
      mode: mode,
      session: ref.read(demoSessionProvider),
      canCalibrate: ref.read(preparationProvider).canCalibrate,
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
            path: 'resumen/:id',
            pageBuilder: (context, state) => _page(
              state,
              SummaryScreen(sessionId: state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: 'historial',
            // Destinos de la barra: sin animación de entrada, como B5.2.
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const HistoryScreen(),
            ),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) => _page(
                  state,
                  SessionDetailScreen(sessionId: state.pathParameters['id']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: 'ajustes',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const SettingsScreen(),
            ),
            routes: [
              GoRoute(
                path: 'sonido',
                pageBuilder: (context, state) =>
                    _page(state, const SoundScreen()),
              ),
            ],
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
