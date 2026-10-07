import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import '../core/design_system/theme.dart';
import '../core/design_system/vigia_icons.dart';
import '../core/design_system/widgets/vigia_blocks.dart';
import '../core/design_system/widgets/vigia_scaffold.dart';
import '../features/settings/preferences_controller.dart';
import '../features/inicio/inicio_state.dart';
import 'app_config.dart';
import 'router.dart';

/// Raíz de la app: temas claro y oscuro de B5.2, rutas de go_router y estado
/// de Riverpod.
///
/// - [mode]: modo de la ejecución ([resolveAppMode]).
/// - [inicioState]: atajo de revisión. Con [InicioMotorNoComprobado] es el
///   modo real; con otra variante, [InicioReviewMode].
/// - [themeMode]: tema fijo (renderizados de prueba). Nulo: el de Ajustes
///   ([themeModeProvider]), «Sistema» por defecto.
///
/// Movimiento reducido: se aplica si lo pide Android o si se eligió en
/// Ajustes; las pantallas lo leen con `MediaQuery.disableAnimationsOf`.
class VigiaApp extends StatelessWidget {
  const VigiaApp({
    super.key,
    this.mode,
    this.inicioState,
    this.themeMode,
    this.overrides = const [],
  }) : assert(
         (mode == null) != (inicioState == null),
         'Indica mode o inicioState, no ambos',
       );

  final AppMode? mode;
  final InicioState? inicioState;
  final ThemeMode? themeMode;

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

  final ThemeMode? themeMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduceMotion = ref.watch(
      preferencesProvider.select((p) => p.value.reducedMotion),
    );
    return MaterialApp.router(
      title: 'Vigía',
      debugShowCheckedModeBanner: false,
      theme: vigiaLightTheme,
      darkTheme: vigiaDarkTheme,
      themeMode: themeMode ?? ref.watch(themeModeProvider),
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) {
        if (!reduceMotion) return child!;
        // La preferencia se suma a la del sistema; nunca la anula.
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        );
      },
    );
  }
}

/// Pantalla de arranque fallido: el modo no coincide con la aplicación
/// Android o el historial no se pudo abrir. No ofrece el recorrido.
class VigiaStartupErrorApp extends StatelessWidget {
  const VigiaStartupErrorApp({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vigía',
      debugShowCheckedModeBanner: false,
      theme: vigiaLightTheme,
      darkTheme: vigiaDarkTheme,
      home: VigiaScaffold(
        title: 'Vigía',
        children: [
          StatusCard(
            tone: StatusTone.alert,
            icon: VigiaIcon.warn,
            tag: 'Error',
            title: 'No se pudo abrir Vigía',
            text: message,
          ),
        ],
      ),
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
