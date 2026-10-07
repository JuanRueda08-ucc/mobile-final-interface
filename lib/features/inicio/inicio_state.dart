/// Estado que muestra Inicio (P03, UX §2.3 y §3).
///
/// Solo es un modelo: no contiene datos. En el recorrido DEMO se deriva de la
/// sesión y del historial guardado; los de revisión están en `lib/demo/`.
/// Todos los estados DEMO llevan [isDemo] y el rótulo «DEMO — datos
/// simulados».
sealed class InicioState {
  const InicioState({required this.isDemo});

  /// `true` si el estado procede del conjunto DEMO (datos simulados).
  final bool isDemo;
}

/// Sin sesión vigente y sin sesiones guardadas (DS00).
final class InicioSinHistorial extends InicioState {
  const InicioSinHistorial({required super.isDemo});
}

/// Sin sesión vigente; hay un último resumen (DS01).
final class InicioUltimoResumen extends InicioState {
  const InicioUltimoResumen({
    required super.isDemo,
    required this.sessionId,
    required this.recordStatus,
    required this.coverage,
    required this.episodes,
  });

  final String sessionId;

  /// Estado del registro: «Completo», «Pendiente de completar», etc. (RF21.CA3).
  final String recordStatus;

  /// Cobertura ya formateada, o «No disponible» si no hay denominador.
  final String coverage;
  final String episodes;
}

/// Hay una sesión vigente con estado confirmado por el motor (RF20, UX01.CA2).
final class InicioSesionVigente extends InicioState {
  const InicioSesionVigente({
    required super.isDemo,
    required this.sessionId,
    required this.paused,
  });

  final String sessionId;
  final bool paused;
}

/// Proceso anterior terminado sin cierre confirmado (RF19, DS02).
final class InicioRegistroInterrumpido extends InicioState {
  const InicioRegistroInterrumpido({
    required super.isDemo,
    required this.sourceTag,
    required this.confirmedStart,
    required this.lastConfirmedRecord,
    this.sessionId,
  });

  /// Etiqueta de la tarjeta (en DEMO: «DS02 · simulado»).
  final String sourceTag;

  /// Sesión guardada que Revisar registro abre; nula en la vista de revisión.
  final String? sessionId;
  final String confirmedStart;
  final String lastConfirmedRecord;
}

/// El historial aún no responde (lectura o guardado en curso) o falló su
/// lectura (ER13). No se presenta como «Aún no tienes sesiones» (UX15.CA1).
final class InicioHistorialPendiente extends InicioState {
  const InicioHistorialPendiente({required super.isDemo, required this.failed});

  final bool failed;
}

/// Estado del motor todavía desconocido (RF20.CA2, UX01.CA3, ER10).
final class InicioMotorDesconocido extends InicioState {
  const InicioMotorDesconocido({required super.isDemo});
}

/// Estado real del arranque mientras no exista conexión con el motor
/// (fase 1): el estado del motor **no está comprobado**, así que no se puede
/// preparar ni iniciar una sesión (RF05, UX01.CA3). No es un dato simulado y
/// no se presenta como «sin historial» ni como motor disponible.
final class InicioMotorNoComprobado extends InicioState {
  const InicioMotorNoComprobado() : super(isDemo: false);
}

/// Acciones de Inicio. Con `VIGIA_DEMO=true` abren el recorrido; en la vista
/// de revisión (`VIGIA_DEMO_INICIO`) muestran un aviso.
enum InicioAction {
  prepararSesion,
  volverAlMonitoreo,
  verUltimoResumen,
  revisarRegistro,
  consultarEstado,
}
