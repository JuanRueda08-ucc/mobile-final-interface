import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_config.dart';
import '../../app/router.dart';
import '../../core/audio/alert_sound.dart';
import '../experimental/engine_sound_player.dart';
import '../experimental/experimental_monitoring_controller.dart';
import '../monitoring/demo_session_controller.dart';

// Ajustes de cada variante (P12–P13). Las pantallas y el controlador de
// preferencias son los mismos; cambian la base (`preferencesStoreProvider`),
// la sesión que bloquea y quién reproduce la prueba.

/// Hay una sesión vigente (activa o en pausa) en esta variante: Ajustes solo
/// deja cambiar el tema y Sonido queda bloqueado (UX §4.2).
///
/// En la normal es la sesión experimental del motor tal como la conoce
/// Flutter; el motor además rechaza cambiar el patrón con sesión vigente.
final settingsLockedProvider = Provider<bool>((ref) {
  if (ref.watch(appModeProvider) is RealMode) {
    return ref.watch(
      experimentalMonitoringProvider.select((s) => s.sessionVigente),
    );
  }
  return ref.watch(demoSessionProvider.select((s) => s.isVigente));
});

/// Cada entrada en P12/P13 consulta el motor. Hasta conocerlo se permiten
/// únicamente cambios de tema; una ruta directa no confía en una copia vieja.
final settingsReadyProvider = FutureProvider.autoDispose<void>((ref) async {
  if (ref.read(appModeProvider) is RealMode) {
    await ref.read(experimentalMonitoringProvider.notifier).querySettings();
  }
});

final settingsControlsLockedProvider = Provider.autoDispose<bool>((ref) {
  final ready = ref.watch(settingsReadyProvider);
  return !ready.hasValue || ready.hasError || ref.watch(settingsLockedProvider);
});

/// Reproductor de «Probar sonido» en P13: en la DEMO, el tono local de
/// `MainActivity`; en la normal, el del motor experimental.
final settingsSoundPlayerProvider = Provider<AlertSoundPlayer>((ref) {
  if (ref.watch(appModeProvider) is RealMode) {
    return EngineSoundPlayer(ref.watch(experimentalBridgeProvider));
  }
  return ref.watch(alertSoundPlayerProvider);
});

/// Monitoreo de la variante, para «Volver al monitoreo» del bloqueo.
String monitoringRouteFor(AppMode mode) =>
    mode is RealMode ? VigiaRoutes.experimental : VigiaRoutes.monitoreo;
