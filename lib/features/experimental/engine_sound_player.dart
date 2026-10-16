import 'package:monitoring_engine/monitoring_engine.dart';

import '../../core/audio/alert_sound.dart';
import '../../data/preferences/preferences_store.dart';
import 'experimental_monitoring_screen.dart';

/// Prueba de P13 en la variante normal (fase 5E): el tono de prueba del
/// patrón lo reproduce el motor (`previewSound`), con los mismos tonos y el
/// mismo flujo de audio que usará en la sesión. Es solo un resultado técnico:
/// no cambia el patrón del motor ni aprueba la prueba de ninguna sesión.
class EngineSoundPlayer implements AlertSoundPlayer {
  const EngineSoundPlayer(this._bridge);

  final ExperimentalMonitoringBridge _bridge;

  @override
  Future<SoundPlayback> play(
    AlertSoundKind kind, {
    String patternId = StoredPreferences.defaultSoundPatternId,
  }) async {
    // P13 solo prueba el tono de prueba del patrón.
    if (kind != AlertSoundKind.test) {
      return const SoundPlayback.failed('Solo se prueba el tono de prueba.');
    }
    try {
      final r = await _bridge.previewSound(patternId);
      if (r.accepted) return const SoundPlayback.played();
      return SoundPlayback.failed(
        ExperimentalMonitoringScreen.rejectionText(r.errorCode ?? ''),
      );
    } catch (_) {
      return const SoundPlayback.failed('El motor no respondió.');
    }
  }
}
