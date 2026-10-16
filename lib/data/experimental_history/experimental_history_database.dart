// Las restricciones CHECK de Drift se declaran con la propia columna
// (`text().check(origin.equals(...))`), que el analizador ve como getter
// recursivo.
// ignore_for_file: recursive_getters

import 'package:drift/drift.dart';

part 'experimental_history_database.g.dart';

/// Base `vigia_history_real_v1.sqlite` de la variante normal (fase 5D; Área
/// 06 §16: bases separadas real/demo). Es la **proyección** Drift del journal
/// nativo: Flutter no decide nada aquí, solo importa hechos confirmados.
///
/// - `experimental_sessions`: una fila por sesión experimental real.
///   `origin` y `qualification_status` la identifican para siempre como
///   experimental (`realExperimental` / `experimental`). Los totales finales
///   solo existen con cierre confirmado; una interrumpida conserva el último
///   prefijo confirmado (`known_*`) sin final ni duración.
/// - `experimental_session_marks`: activaciones, tonos y pausas confirmados.
/// - `imported_records`: recibo de cada hecho importado (ID, secuencia y
///   hash), para que reimportar sea un no-op y un cambio, un error.
///
/// Sin imágenes, puntos faciales ni series por observación.
@DataClassName('ExperimentalSessionRow')
class ExperimentalSessions extends Table {
  TextColumn get sessionId => text()();

  /// Origen permanente: datos reales experimentales (nunca DEMO).
  TextColumn get origin => text()
      .check(origin.equals('realExperimental'))
      .withDefault(const Constant('realExperimental'))();

  /// Calificación permanente del perfil: experimental.
  TextColumn get qualificationStatus => text()
      .check(qualificationStatus.equals('experimental'))
      .withDefault(const Constant('experimental'))();
  TextColumn get profileId => text()();
  TextColumn get landmarkSchema => text()();
  TextColumn get modelId => text()();
  TextColumn get modelSha256 => text()();
  TextColumn get engineInstanceId => text()();

  // Referencia compacta de la calibración usada (millonésimas).
  TextColumn get calibrationId => text()();
  IntColumn get openEarRightE6 => integer()();
  IntColumn get openEarLeftE6 => integer()();
  IntColumn get calibrationSamples => integer()();
  IntColumn get calibrationCoverageE6 => integer()();

  IntColumn get startedEpochMs => integer()();
  IntColumn get startOffsetMinutes =>
      integer().check(startOffsetMinutes.isBetweenValues(-840, 840))();

  /// active, paused, finalized o interrupted.
  TextColumn get lifecycle => text().check(
    lifecycle.isIn(const ['active', 'paused', 'finalized', 'interrupted']),
  )();

  /// Cierre confirmado: solo en `finalized`.
  IntColumn get endedEpochMs => integer().nullable()();
  IntColumn get endOffsetMinutes => integer().nullable()();
  IntColumn get endOffsetMs => integer().nullable()();

  /// Último límite confirmado en el journal (ms desde el inicio).
  IntColumn get latestDurableOffsetMs =>
      integer().check(latestDurableOffsetMs.isBiggerOrEqualValue(0))();

  /// Recuperación tras la muerte del proceso: no es el final de la sesión.
  IntColumn get recoveredEpochMs => integer().nullable()();

  /// complete o incomplete (Área 06 §11).
  TextColumn get integrityStatus =>
      text().check(integrityStatus.isIn(const ['complete', 'incomplete']))();

  /// Hechos que el motor declaró perdidos (escrituras fallidas).
  IntColumn get recordsLost => integer().withDefault(const Constant(0))();

  // Totales finales (solo `finalized`).
  IntColumn get activeMs => integer().nullable()();
  IntColumn get evaluableMs => integer().nullable()();
  IntColumn get nonEvaluableMs => integer().nullable()();
  IntColumn get pausedMs => integer().nullable()();
  IntColumn get closureActivations => integer().nullable()();
  IntColumn get tonesPlayed => integer().nullable()();
  IntColumn get tonesFailed => integer().nullable()();
  IntColumn get pauseCount => integer().nullable()();

  // Último prefijo confirmado (punto de control o pausa), hasta `knownThroughMs`.
  IntColumn get knownThroughMs => integer().nullable()();
  IntColumn get knownActiveMs => integer().nullable()();
  IntColumn get knownEvaluableMs => integer().nullable()();
  IntColumn get knownPausedMs => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {sessionId};

  @override
  List<String> get customConstraints => [
    "CHECK(lifecycle = 'finalized' OR (ended_epoch_ms IS NULL AND "
        'end_offset_ms IS NULL AND active_ms IS NULL))',
    "CHECK(lifecycle != 'finalized' OR (ended_epoch_ms IS NOT NULL AND "
        'end_offset_minutes IS NOT NULL AND end_offset_ms IS NOT NULL AND '
        'active_ms IS NOT NULL AND evaluable_ms IS NOT NULL AND '
        'non_evaluable_ms IS NOT NULL AND paused_ms IS NOT NULL))',
    'CHECK(end_offset_ms IS NULL OR latest_durable_offset_ms <= end_offset_ms)',
    'CHECK(active_ms IS NULL OR (active_ms >= 0 AND evaluable_ms >= 0 AND '
        'non_evaluable_ms >= 0 AND paused_ms >= 0 AND '
        'evaluable_ms + non_evaluable_ms = active_ms))',
    "CHECK(lifecycle != 'interrupted' OR integrity_status = 'incomplete')",
  ];
}

/// Hecho confirmado de la línea temporal: activación de cierre prolongado,
/// intento de tono o pausa.
@DataClassName('ExperimentalMarkRow')
class ExperimentalSessionMarks extends Table {
  TextColumn get recordId => text()();
  TextColumn get sessionId => text().references(
    ExperimentalSessions,
    #sessionId,
    onDelete: KeyAction.cascade,
  )();
  IntColumn get journalSequence => integer()();

  /// closure, playback, pauseStarted o pauseEnded.
  TextColumn get kind => text().check(
    kind.isIn(const ['closure', 'playback', 'pauseStarted', 'pauseEnded']),
  )();
  IntColumn get offsetMs => integer().check(offsetMs.isBiggerOrEqualValue(0))();
  IntColumn get ordinal => integer().check(ordinal.isBiggerOrEqualValue(1))();

  /// Intento de tono dentro de la activación.
  IntColumn get playbackOrdinal => integer().nullable()();

  /// Resultado técnico del tono: started o failed (no acredita audición).
  TextColumn get status => text().nullable()();
  TextColumn get errorCode => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {recordId};
}

/// Recibo de importación (Área 04 §11.1 `imported_records`).
@DataClassName('ImportedRecordRow')
class ImportedRecords extends Table {
  TextColumn get recordId => text()();
  IntColumn get journalSequence => integer().unique()();
  TextColumn get payloadHash => text()();
  TextColumn get recordType => text()();

  @override
  Set<Column<Object>> get primaryKey => {recordId};
}

/// Preferencias de la variante normal (fase 5E; fila única de Área 06 §6).
/// Son las de esta app: la DEMO tiene las suyas en su propia base. Retención,
/// alias y explicación vista no forman parte de este prototipo.
@DataClassName('RealPreferencesRow')
class RealPreferences extends Table {
  @override
  String get tableName => 'preferences';

  IntColumn get singleton =>
      integer().check(singleton.equals(1)).withDefault(const Constant(1))();
  TextColumn get theme =>
      text().check(theme.isIn(const ['system', 'light', 'dark']))();

  /// Solo patrones del catálogo local incluido (Área 06 §9: sin inventar IDs).
  TextColumn get soundPatternId => text().check(
    soundPatternId.isIn(const ['patron_1', 'patron_2', 'patron_3']),
  )();
  BoolColumn get reducedMotion => boolean()();
  IntColumn get updatedEpochMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => {singleton};
}

@DriftDatabase(
  tables: [
    ExperimentalSessions,
    ExperimentalSessionMarks,
    ImportedRecords,
    RealPreferences,
  ],
)
class ExperimentalHistoryDatabase extends _$ExperimentalHistoryDatabase {
  ExperimentalHistoryDatabase(super.e);

  /// historyDbVersion de la base real.
  /// - 1: fase 5D (sesiones, marcas y recibos).
  /// - 2: fase 5E, añade `preferences`; no toca las tablas de 5D.
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from == 1 && to == 2) {
        await m.createTable(realPreferences);
        return;
      }
      // Sin ruta destructiva (Área 06 §18).
      throw StateError('Migración del historial real $from→$to no definida');
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
