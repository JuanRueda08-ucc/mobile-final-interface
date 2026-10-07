import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import '../data/demo_history/demo_history_database.dart';
import '../data/demo_history/demo_history_repository.dart';
import '../data/demo_history/history_providers.dart';
import '../features/settings/preferences_controller.dart';
import 'app_config.dart';

/// applicationId de la app normal.
const realApplicationId = 'com.juanrueda.vigia';

/// applicationId de la app DEMO (`VIGIA_DEMO=true`, Gradle lo deriva de la
/// misma definición).
const demoApplicationId = 'com.juanrueda.vigia.demo';

/// Nombre de la base DEMO (Área 06 §16). drift_flutter añade `.sqlite` y la
/// guarda en el directorio privado de la app.
const demoHistoryDatabaseName = 'vigia_history_demo_v1';

/// applicationId que corresponde a [mode].
String expectedApplicationId(AppMode mode) =>
    mode is DemoMode ? demoApplicationId : realApplicationId;

/// Comprueba que el modo Dart y la aplicación Android coinciden: el recorrido
/// simulado no puede escribir en la app normal ni al revés. Lanza
/// [StateError] si no coinciden.
void checkApplicationId(AppMode mode, String applicationId) {
  final expected = expectedApplicationId(mode);
  if (applicationId != expected) {
    throw StateError(
      'Modo ${mode.runtimeType} en $applicationId: se esperaba $expected. '
      'Compila con --dart-define=VIGIA_DEMO=true para la app DEMO.',
    );
  }
}

/// Lee el applicationId del proceso Android (`vigia/app`). `null` fuera de
/// Android.
Future<String?> readApplicationId() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
  return const MethodChannel('vigia/app').invokeMethod<String>('applicationId');
}

/// Prepara la ejecución según el modo y devuelve las sustituciones de
/// proveedores.
///
/// - Real y revisión de Inicio (`VIGIA_DEMO_INICIO`): no abren ninguna base ni
///   escriben nada.
/// - DEMO: comprueba el applicationId, abre `vigia_history_demo_v1.sqlite`,
///   marca como interrumpidas las sesiones que quedaron sin cierre (RF19) y
///   carga las preferencias guardadas.
Future<List<Override>> bootstrap(AppMode mode) async {
  final applicationId = await readApplicationId();
  if (applicationId != null) checkApplicationId(mode, applicationId);
  if (mode is! DemoMode) return const [];
  final db = DemoHistoryDatabase(driftDatabase(name: demoHistoryDatabaseName));
  final repo = await DriftDemoHistoryRepository.open(db);
  return demoOverrides(repo, await repo.loadPreferences());
}

/// Sustituciones del recorrido DEMO con su historial y preferencias.
List<Override> demoOverrides(
  DemoHistoryRepository repo,
  StoredPreferences preferences,
) => [
  demoHistoryRepositoryProvider.overrideWithValue(repo),
  initialPreferencesProvider.overrideWithValue(preferences),
];
