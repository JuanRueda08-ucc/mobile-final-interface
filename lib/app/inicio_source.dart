import '../demo/inicio_demo.dart';
import '../features/inicio/inicio_state.dart';

/// Variante DEMO pedida al compilar (`--dart-define=VIGIA_DEMO_INICIO=...`).
const String inicioDemoDefine = String.fromEnvironment('VIGIA_DEMO_INICIO');

/// Resuelve el estado inicial de Inicio.
///
/// - Con `VIGIA_DEMO_INICIO` se usa la variante DEMO indicada (datos simulados,
///   rotulados).
/// - Sin ella se usa el estado real. En la fase 1 la app no se conecta todavía
///   con el motor, así que el estado del motor **no está comprobado**: Inicio
///   lo muestra explícitamente y mantiene bloqueada la preparación
///   ([InicioMotorNoComprobado]). No se presenta «sin historial» como si el
///   motor estuviera disponible. Ese estado real no lleva rótulo DEMO.
///
/// Un valor de variante desconocido no se sustituye en silencio: lanza
/// [ArgumentError] con los valores admitidos.
InicioState resolveInicioState({String demoDefine = inicioDemoDefine}) {
  if (demoDefine.isEmpty) {
    return const InicioMotorNoComprobado();
  }
  final variant = InicioDemoVariant.parse(demoDefine);
  if (variant == null) {
    throw ArgumentError.value(
      demoDefine,
      'VIGIA_DEMO_INICIO',
      'variante desconocida; admitidas: ${InicioDemoVariant.values.map((v) => v.id).join(', ')}',
    );
  }
  return variant.state;
}
