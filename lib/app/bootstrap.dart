import 'package:drift/drift.dart' show QueryExecutor;
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

import '../data/demo_history/demo_history_database.dart';
import '../data/demo_history/demo_history_repository.dart';
import '../data/demo_history/history_providers.dart';
import '../data/experimental_history/experimental_history_database.dart';
import '../data/experimental_history/experimental_history_providers.dart';
import '../data/experimental_history/experimental_history_repository.dart';
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

/// Base de la proyección real experimental (fase 5D), solo en la app normal.
/// El journal nativo es otro archivo (`vigia_journal_real_v1.sqlite`), que
/// solo abre Kotlin.
const realHistoryDatabaseName = 'vigia_history_real_v1';

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
/// - Revisión de Inicio (`VIGIA_DEMO_INICIO`): no abre ninguna base ni
///   escribe nada.
/// - Real (fase 5D), solo en la app Android normal: abre
///   `vigia_history_real_v1.sqlite`, la proyección del journal nativo
///   experimental. La importación la piden las pantallas; el journal es la
///   fuente durable y la recuperación de interrumpidas la decide Kotlin.
/// - DEMO: comprueba el applicationId, abre `vigia_history_demo_v1.sqlite`,
///   marca como interrumpidas las sesiones que quedaron sin cierre (RF19) y
///   carga las preferencias guardadas.
///
/// [openDatabase] sustituye la apertura en las pruebas.
Future<List<Override>> bootstrap(
  AppMode mode, {
  QueryExecutor Function(String name)? openDatabase,
}) async {
  final applicationId = await readApplicationId();
  if (applicationId != null) checkApplicationId(mode, applicationId);
  final open = openDatabase ?? (name) => driftDatabase(name: name);
  if (mode is RealMode) {
    // Fuera de Android (pruebas sin canal) no hay motor ni journal.
    if (applicationId == null && openDatabase == null) return const [];
    final db = ExperimentalHistoryDatabase(open(realHistoryDatabaseName));
    return [
      experimentalHistoryRepositoryProvider.overrideWithValue(
        ExperimentalHistoryRepository(db),
      ),
    ];
  }
  if (mode is! DemoMode) return const [];
  final db = DemoHistoryDatabase(open(demoHistoryDatabaseName));
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
