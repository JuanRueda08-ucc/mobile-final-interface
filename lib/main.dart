import 'package:flutter/material.dart';

import 'app/inicio_source.dart';
import 'app/vigia_app.dart';

/// Vigía · prototipo, fase 1 del plan activo (`AGENTS.md`): base visual B5.2 e
/// Inicio (P03). No usa cámara, no ejecuta IA, no crea sesiones ni emite alertas.
///
/// Variantes DEMO de Inicio: `--dart-define=VIGIA_DEMO_INICIO=<variante>`
/// (`sin_historial`, `ultimo_resumen`, `sesion_vigente`,
/// `registro_interrumpido`, `motor_desconocido`).
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerVigiaLicenses();
  runApp(VigiaApp(inicioState: resolveInicioState()));
}
