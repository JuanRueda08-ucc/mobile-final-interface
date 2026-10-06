import 'package:flutter/material.dart';

import 'app/app_config.dart';
import 'app/vigia_app.dart';

/// Vigía · prototipo, fase 2 del plan activo (`AGENTS.md`).
///
/// - Sin definiciones: estado real; el motor **no está comprobado** y la
///   preparación queda bloqueada. No usa cámara ni IA ni crea sesiones.
/// - `--dart-define=VIGIA_DEMO=true`: recorrido demostrativo Inicio →
///   Preparación → Calibración → Monitoreo → Resumen, con datos simulados
///   rotulados «DEMO — datos simulados».
/// - `--dart-define=VIGIA_DEMO_INICIO=<variante>`: revisión de variantes de
///   Inicio (`sin_historial`, `ultimo_resumen`, `sesion_vigente`,
///   `registro_interrumpido`, `motor_desconocido`). No inicia sesiones.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerVigiaLicenses();
  runApp(VigiaApp(mode: resolveAppMode()));
}
