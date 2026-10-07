import 'package:flutter/material.dart';

import 'app/app_config.dart';
import 'app/bootstrap.dart';
import 'app/vigia_app.dart';

/// Vigía · prototipo, fase 3 del plan activo (`AGENTS.md`).
///
/// - Sin definiciones (com.juanrueda.vigia, «Vigía»): estado real; el motor
///   **no está comprobado** y la preparación queda bloqueada. No usa cámara ni
///   IA, no crea sesiones y no escribe ningún dato.
/// - `--dart-define=VIGIA_DEMO=true` (com.juanrueda.vigia.demo, «Vigía DEMO»):
///   recorrido demostrativo con datos simulados rotulados «DEMO — datos
///   simulados», con historial y preferencias en
///   `vigia_history_demo_v1.sqlite`.
/// - `--dart-define=VIGIA_DEMO_INICIO=<variante>`: revisión de variantes de
///   Inicio (`sin_historial`, `ultimo_resumen`, `sesion_vigente`,
///   `registro_interrumpido`, `motor_desconocido`). No inicia sesiones ni
///   escribe datos.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerVigiaLicenses();
  final mode = resolveAppMode();
  try {
    final overrides = await bootstrap(mode);
    runApp(VigiaApp(mode: mode, overrides: overrides));
  } catch (e) {
    // Sin historial coherente no se ofrece el recorrido (Área 06 §18: no se
    // borra ni se recrea la base en silencio).
    runApp(VigiaStartupErrorApp(message: '$e'));
  }
}
