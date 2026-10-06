import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/design_system/theme.dart';
import '../features/inicio/inicio_screen.dart';
import '../features/inicio/inicio_state.dart';

/// Raíz de la app: temas claro y oscuro de B5.2 según el sistema (Ajustes,
/// con la elección persistente del tema, llega en la fase 3).
class VigiaApp extends StatelessWidget {
  const VigiaApp({
    super.key,
    required this.inicioState,
    this.themeMode = ThemeMode.system,
  });

  final InicioState inicioState;
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vigía',
      debugShowCheckedModeBanner: false,
      theme: vigiaLightTheme,
      darkTheme: vigiaDarkTheme,
      themeMode: themeMode,
      home: InicioScreen(state: inicioState),
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
