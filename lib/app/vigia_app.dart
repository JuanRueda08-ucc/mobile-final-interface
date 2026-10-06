import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import '../core/design_system/theme.dart';
import '../features/inicio/inicio_state.dart';
import 'app_config.dart';
import 'router.dart';

/// Raíz de la app: temas claro y oscuro de B5.2 según el sistema (Ajustes,
/// con la elección persistente del tema, llega en la fase 3), rutas de
/// go_router y estado de Riverpod.
///
/// - [mode]: modo de la ejecución ([resolveAppMode]).
/// - [inicioState]: atajo de revisión. Con [InicioMotorNoComprobado] es el
///   modo real; con otra variante, [InicioReviewMode].
class VigiaApp extends StatelessWidget {
  const VigiaApp({
    super.key,
    this.mode,
    this.inicioState,
    this.themeMode = ThemeMode.system,
    this.overrides = const [],
  }) : assert(
         (mode == null) != (inicioState == null),
         'Indica mode o inicioState, no ambos',
       );

  final AppMode? mode;
  final InicioState? inicioState;
  final ThemeMode themeMode;

  /// Sustituciones de proveedores (pruebas: reloj, sonido, retrasos).
  final List<Override> overrides;

  AppMode get _mode =>
      mode ??
      switch (inicioState!) {
        InicioMotorNoComprobado() => const RealMode(),
        final s => InicioReviewMode(s),
      };

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [appModeProvider.overrideWithValue(_mode), ...overrides],
      child: _VigiaRouterApp(themeMode: themeMode),
    );
  }
}

class _VigiaRouterApp extends ConsumerWidget {
  const _VigiaRouterApp({required this.themeMode});

  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Vigía',
      debugShowCheckedModeBanner: false,
      theme: vigiaLightTheme,
      darkTheme: vigiaDarkTheme,
      themeMode: themeMode,
      routerConfig: ref.watch(routerProvider),
    );
  }
}

/// Registra la licencia SIL OFL 1.1 de Inter, que se distribuye con la app.
void registerVigiaLicenses() {
  LicenseRegistry.addLicense(() async* {
    final ofl = await rootBundle.loadString('assets/fonts/Inter/OFL.txt');
    yield LicenseEntryWithLineBreaks(const ['Inter (fuente)'], ofl);
  });
}
