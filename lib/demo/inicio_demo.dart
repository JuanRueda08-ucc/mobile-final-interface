import '../features/inicio/inicio_state.dart';

/// DATOS DEMO — SIMULADOS. Solo sirven para revisar las variantes de Inicio (P03)
/// de B5.2. No proceden de la cámara, de la IA ni de sesiones reales, y no
/// representan detección. Todos los estados se marcan `isDemo: true`, lo que
/// muestra el rótulo «DEMO — datos simulados» (RF32).
///
/// Se seleccionan al compilar o ejecutar con
/// `--dart-define=VIGIA_DEMO_INICIO=<variante>`. Sin esa definición, la app usa
/// el estado real (ver `lib/app/inicio_source.dart`).
enum InicioDemoVariant {
  sinHistorial('sin_historial', 'P03__sin_historial__v1'),
  ultimoResumen('ultimo_resumen', 'P03__ultimo_resumen__v1'),
  sesionVigente('sesion_vigente', 'P03__sesion_vigente__v1'),
  registroInterrumpido(
    'registro_interrumpido',
    'P03__registro_interrumpido__v1',
  ),
  motorDesconocido('motor_desconocido', 'P03__motor_desconocido__v1');

  const InicioDemoVariant(this.id, this.b52ViewId);

  /// Valor de `VIGIA_DEMO_INICIO`.
  final String id;

  /// Identificador de la vista equivalente en el HTML B5.2.
  final String b52ViewId;

  static InicioDemoVariant? parse(String value) {
    for (final v in values) {
      if (v.id == value) return v;
    }
    return null;
  }

  /// Datos simulados de cada variante (valores de B5.2 / DS00, DS01 y DS02).
  InicioState get state => switch (this) {
    sinHistorial => const InicioSinHistorial(isDemo: true),
    ultimoResumen => const InicioUltimoResumen(
      isDemo: true,
      sessionId: 'S-DEMO-0427',
      recordStatus: 'Completo',
      coverage: '83,3 %',
      episodes: '2',
    ),
    sesionVigente => const InicioSesionVigente(
      isDemo: true,
      sessionId: 'S-DEMO-0427',
      paused: false,
    ),
    registroInterrumpido => const InicioRegistroInterrumpido(
      isDemo: true,
      sourceTag: 'DS02 · simulado',
      confirmedStart: '08:12',
      lastConfirmedRecord: '08:41',
    ),
    motorDesconocido => const InicioMotorDesconocido(isDemo: true),
  };
}
