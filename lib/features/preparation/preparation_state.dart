/// Estado de Preparación (P04, FL02, RF03–RF05, RF07) en la demostración.
///
/// Las cinco condiciones del equipo (permiso, cámara, modelo, rostro y ojos)
/// son **simuladas**: no hay cámara, modelo ni IA. Se controlan desde el
/// panel «Simulación DEMO» y se rotulan así. La referencia de calibración y la
/// prueba de sonido sí siguen el flujo: la referencia procede de una
/// calibración demostrativa aceptada y el sonido se reproduce de verdad en el
/// teléfono (resultado técnico), con confirmación humana.
library;

/// Condiciones simuladas del equipo (demostración).
final class SimulatedConditions {
  const SimulatedConditions({
    this.permission = true,
    this.camera = true,
    this.model = true,
    this.face = true,
    this.eyes = true,
  });

  final bool permission;
  final bool camera;
  final bool model;
  final bool face;
  final bool eyes;

  SimulatedConditions copyWith({
    bool? permission,
    bool? camera,
    bool? model,
    bool? face,
    bool? eyes,
  }) => SimulatedConditions(
    permission: permission ?? this.permission,
    camera: camera ?? this.camera,
    model: model ?? this.model,
    face: face ?? this.face,
    eyes: eyes ?? this.eyes,
  );
}

/// Referencia de calibración demostrativa aceptada (RF06.CA1, en memoria).
final class CalibrationReference {
  const CalibrationReference({
    required this.id,
    required this.mountRevision,
    required this.createdAt,
  });

  final String id;

  /// Revisión de montaje para la que se calibró (Área 04 §4.3).
  final int mountRevision;
  final DateTime createdAt;
}

/// Prueba de sonido de esta preparación (RF04, UX04).
enum SoundCheck {
  /// Sin prueba: cada preparación nueva la exige (UX04.CA3).
  pending,

  /// Reproducción solicitada; esperando el resultado técnico.
  playing,

  /// Resultado técnico correcto; falta «Lo escuché».
  played,

  /// El usuario indicó «No lo escuché»: sigue bloqueado (UX04.CA2).
  notHeard,

  /// La reproducción falló (RF04.CA3).
  failed,

  /// Reproducción correcta y audibilidad confirmada por el usuario.
  confirmed,
}

/// Causas de bloqueo de RF05.CA2, en el orden de B5.2.
enum PreparationBlocker {
  permission('Cámara sin permiso'),
  camera('Cámara no disponible'),
  model('Modelo no disponible'),
  eyes('Ojos no evaluables'),
  calibration('Calibración pendiente'),
  sound('Prueba de sonido pendiente');

  const PreparationBlocker(this.text);

  final String text;
}

final class PreparationState {
  const PreparationState({
    this.sim = const SimulatedConditions(),
    this.reference,
    this.mountRevision = 0,
    this.mountChanged = false,
    this.sound = SoundCheck.pending,
    this.soundFailure,
  });

  final SimulatedConditions sim;

  /// Última referencia aceptada en esta ejecución (puede no ser aplicable).
  final CalibrationReference? reference;

  /// Aumenta con «Cambié la posición» (RF07.CA1).
  final int mountRevision;

  /// El usuario declaró un cambio de posición y aún no recalibró.
  final bool mountChanged;
  final SoundCheck sound;
  final String? soundFailure;

  bool get eyesEvaluable => sim.face && sim.eyes;

  /// Referencia aplicable: existe y corresponde al montaje actual.
  bool get referenceApplicable =>
      reference != null && reference!.mountRevision == mountRevision;

  /// Calibrar exige cámara y modelo disponibles (FL03, entrada).
  bool get canCalibrate => sim.permission && sim.camera && sim.model;

  /// Causas que bloquean Iniciar monitoreo (RF05.CA1–CA2).
  List<PreparationBlocker> get blockers => [
    if (!sim.permission) PreparationBlocker.permission,
    if (!sim.camera) PreparationBlocker.camera,
    if (!sim.model) PreparationBlocker.model,
    if (!eyesEvaluable) PreparationBlocker.eyes,
    if (!referenceApplicable) PreparationBlocker.calibration,
    if (sound != SoundCheck.confirmed) PreparationBlocker.sound,
  ];

  bool get ready => blockers.isEmpty;

  PreparationState copyWith({
    SimulatedConditions? sim,
    CalibrationReference? reference,
    int? mountRevision,
    bool? mountChanged,
    SoundCheck? sound,
    String? soundFailure,
    bool clearSoundFailure = false,
  }) => PreparationState(
    sim: sim ?? this.sim,
    reference: reference ?? this.reference,
    mountRevision: mountRevision ?? this.mountRevision,
    mountChanged: mountChanged ?? this.mountChanged,
    sound: sound ?? this.sound,
    soundFailure: clearSoundFailure ? null : soundFailure ?? this.soundFailure,
  );
}
