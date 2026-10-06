import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/inicio/inicio_state.dart';
import 'inicio_source.dart';

/// Valor de `--dart-define=VIGIA_DEMO=...` al compilar.
const String vigiaDemoDefine = String.fromEnvironment('VIGIA_DEMO');

/// Modo de la app, fijado al compilar.
sealed class AppMode {
  const AppMode();
}

/// Sin modo demostración: el estado del motor no está comprobado y la
/// preparación queda bloqueada (fase 1). No hay recorrido ni datos simulados.
final class RealMode extends AppMode {
  const RealMode();
}

/// Revisión de una variante fija de Inicio (`VIGIA_DEMO_INICIO`). Sirve para
/// revisar P03; sus acciones no abren el recorrido: una «sesión vigente» de
/// revisión no es una sesión iniciada.
final class InicioReviewMode extends AppMode {
  const InicioReviewMode(this.state);

  final InicioState state;
}

/// Recorrido demostrativo (`VIGIA_DEMO=true`): Inicio → Preparación →
/// Calibración → Monitoreo → Resumen con datos simulados, siempre rotulados
/// «DEMO — datos simulados» (RF32). No usa cámara, IA ni el plugin nativo.
final class DemoMode extends AppMode {
  const DemoMode();
}

/// Resuelve el modo a partir de `VIGIA_DEMO` y `VIGIA_DEMO_INICIO`.
///
/// - `VIGIA_DEMO`: vacío o `false` → sin demostración; `true` → recorrido demo.
///   Otro valor lanza [ArgumentError]: no se interpreta en silencio.
/// - `VIGIA_DEMO_INICIO`: variante de revisión de Inicio
///   ([resolveInicioState]).
/// - Las dos a la vez lanzan [ArgumentError]: una variante de revisión no debe
///   confundirse con una sesión iniciada en el recorrido.
AppMode resolveAppMode({
  String demoDefine = vigiaDemoDefine,
  String inicioDefine = inicioDemoDefine,
}) {
  final demo = switch (demoDefine) {
    '' || 'false' => false,
    'true' => true,
    _ => throw ArgumentError.value(
      demoDefine,
      'VIGIA_DEMO',
      'valor no admitido; usa true o false',
    ),
  };
  if (demo && inicioDefine.isNotEmpty) {
    throw ArgumentError(
      'VIGIA_DEMO=true y VIGIA_DEMO_INICIO no se combinan: el recorrido '
      'demostrativo empieza en su propio Inicio.',
    );
  }
  if (demo) return const DemoMode();
  if (inicioDefine.isEmpty) return const RealMode();
  return InicioReviewMode(resolveInicioState(demoDefine: inicioDefine));
}

/// Modo de esta ejecución. `VigiaApp` lo fija con un override.
final appModeProvider = Provider<AppMode>((ref) => const RealMode());
