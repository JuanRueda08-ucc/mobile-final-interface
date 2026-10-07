import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/alert_sound.dart';
import '../../core/clock/monotonic_clock.dart';
import 'preparation_state.dart';

/// Controlador de Preparación (P04). Pide acciones y representa su estado; no
/// crea sesiones (eso lo hace el controlador de sesión al confirmar el
/// inicio).
class PreparationController extends Notifier<PreparationState> {
  var _calibrations = 0;
  var _soundAttempt = 0;

  @override
  PreparationState build() => const PreparationState();

  /// Entrar en Preparación desde Inicio: la prueba de sonido vuelve a ser
  /// obligatoria (UX04.CA3). La referencia aceptada se conserva si sigue
  /// siendo aplicable al montaje actual.
  void open() {
    _soundAttempt++;
    state = state.copyWith(sound: SoundCheck.pending, clearSoundFailure: true);
  }

  /// Panel «Simulación DEMO»: cambia una condición simulada del equipo.
  void setSimulated(SimulatedConditions sim) {
    state = state.copyWith(sim: sim);
  }

  /// «Cambié la posición» (RF07.CA1): nueva revisión de montaje; la
  /// referencia anterior deja de ser aplicable y se exige recalibrar.
  void declareMountChanged() {
    state = state.copyWith(
      mountRevision: state.mountRevision + 1,
      mountChanged: true,
    );
  }

  /// Guarda la referencia de una calibración aceptada (RF06.CA1), vinculada
  /// al montaje actual. Devuelve su identificador, o `null` sin guardar nada
  /// si en ese momento falta permiso, cámara o modelo (FL03, entrada).
  String? acceptCalibration() {
    if (!state.canCalibrate) return null;
    _calibrations++;
    final id = 'C-DEMO-${_calibrations.toString().padLeft(4, '0')}';
    state = state.copyWith(
      reference: CalibrationReference(
        id: id,
        mountRevision: state.mountRevision,
        createdAt: ref.read(monotonicClockProvider).wallNow(),
      ),
      mountChanged: false,
    );
    return id;
  }

  /// «Probar sonido» (RF04.CA1): reproduce el tono local y registra el
  /// resultado técnico. Un resultado de una prueba anterior se descarta.
  Future<void> testSound() async {
    if (state.sound == SoundCheck.playing) return;
    final attempt = ++_soundAttempt;
    state = state.copyWith(sound: SoundCheck.playing, clearSoundFailure: true);
    final r = await ref
        .read(alertSoundPlayerProvider)
        .play(AlertSoundKind.test);
    if (!ref.mounted || attempt != _soundAttempt) return;
    state = r.played
        ? state.copyWith(sound: SoundCheck.played)
        : state.copyWith(sound: SoundCheck.failed, soundFailure: r.failure);
  }

  /// «Lo escuché»: solo tras reproducción técnica correcta (UX04.CA1).
  void confirmHeard() {
    if (state.sound != SoundCheck.played) return;
    state = state.copyWith(sound: SoundCheck.confirmed);
  }

  /// «No lo escuché»: conserva el bloqueo (UX04.CA2).
  void notHeard() {
    if (state.sound != SoundCheck.played) return;
    state = state.copyWith(sound: SoundCheck.notHeard);
  }

  /// La preparación se consume al iniciar una sesión: la siguiente exige
  /// otra prueba de sonido (Área 04 §7.2).
  void consume() {
    _soundAttempt++;
    state = state.copyWith(sound: SoundCheck.pending, clearSoundFailure: true);
  }
}

final preparationProvider =
    NotifierProvider<PreparationController, PreparationState>(
      PreparationController.new,
    );
