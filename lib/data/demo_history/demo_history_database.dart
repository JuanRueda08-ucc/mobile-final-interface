// Las restricciones CHECK de Drift se declaran con la propia columna
// (`text().check(origin.equals(...))`), que el analizador ve como getter
// recursivo.
// ignore_for_file: recursive_getters

import 'package:drift/drift.dart';

part 'demo_history_database.g.dart';

/// Base `vigia_history_demo_v1.sqlite` del recorrido **DEMO** (Área 06 §16:
/// bases separadas real/demo). Solo la abre la app com.juanrueda.vigia.demo.
///
/// Es un subconjunto del historial de Área 06 §6, adaptado al motor simulado:
/// - `demo_sessions` sigue a `sessions`: identidad, inicio, ciclo, fin,
///   último desplazamiento durable e integridad. No tiene modelo, política ni
///   instantánea de calibración, porque la demostración no los tiene: no se
///   inventan hashes ni versiones. `origin` identifica para siempre el origen
///   DEMO (RF32).
/// - Los totales del resumen se guardan una sola vez, al confirmar el cierre.
///   En una sesión interrumpida quedan nulos: no se inventa tiempo (RF19).
/// - `demo_session_events` guarda los hechos de la sesión simulada, de donde
///   se calcula el resumen. No es el journal Room del motor real (Área 06 §7).
/// - `preferences` es la fila única de Área 06 §6 (tema y patrón de sonido),
///   más la preferencia de movimiento reducido. Sin alias ni retención: quedan
///   fuera de esta fase.
@DataClassName('DemoSessionRow')
class DemoSessions extends Table {
  TextColumn get sessionId => text()();

  /// Origen permanente: siempre `demo` en esta base (RF32.CA1).
  TextColumn get origin =>
      text().check(origin.equals('demo')).withDefault(const Constant('demo'))();

  /// Número de `S-DEMO-NNNN`: no se reutiliza entre ejecuciones.
  IntColumn get sessionNumber => integer().unique()();

  IntColumn get startedEpochMs => integer()();
  IntColumn get startOffsetMinutes =>
      integer().check(startOffsetMinutes.isBetweenValues(-840, 840))();

  /// active, paused, stopping, finalized o interrupted (Área 06 §6).
  TextColumn get lifecycle => text().check(
    lifecycle.isIn(const [
      'active',
      'paused',
      'stopping',
      'finalized',
      'interrupted',
    ]),
  )();

  /// Fin civil confirmado: nulo salvo en `finalized`.
  IntColumn get endedEpochMs => integer().nullable()();
  IntColumn get endOffsetMinutes => integer().nullable()();

  /// Desplazamiento monotónico del fin del tiempo representado (solicitud de
  /// cierre). Nulo si el final no se confirmó.
  IntColumn get endOffsetMs => integer().nullable()();

  /// Desplazamiento del último hecho guardado (Área 06 §11: último límite
  /// confirmado, no «hasta ahora»).
  IntColumn get latestDurableOffsetMs =>
      integer().check(latestDurableOffsetMs.isBiggerOrEqualValue(0))();

  TextColumn get calibrationId => text()();

  /// complete o incomplete (Área 06 §11).
  TextColumn get integrityStatus =>
      text().check(integrityStatus.isIn(const ['complete', 'incomplete']))();

  // Totales del resumen (RF21), solo en `finalized`.
  IntColumn get evaluableMs => integer().nullable()();
  IntColumn get nonEvaluableMs => integer().nullable()();
  IntColumn get pausedMs => integer().nullable()();
  IntColumn get unknownMs => integer().nullable()();

  /// Tiempo realmente monitoreado: evaluable + no evaluable, sin pausas.
  IntColumn get monitoredMs => integer().nullable()();
  IntColumn get episodeCount => integer().nullable()();
  IntColumn get warningCount => integer().nullable()();
  IntColumn get closureCount => integer().nullable()();
  IntColumn get soundsPlayed => integer().nullable()();
  IntColumn get soundsFailed => integer().nullable()();
  IntColumn get pauseCount => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {sessionId};

  @override
  List<String> get customConstraints => [
    // Fin civil completo o ausente (Área 06 §6).
    'CHECK((ended_epoch_ms IS NULL AND end_offset_minutes IS NULL) OR '
        '(ended_epoch_ms IS NOT NULL AND end_offset_minutes IS NOT NULL))',
    'CHECK(end_offset_ms IS NULL OR latest_durable_offset_ms <= end_offset_ms)',
    // Solo una sesión finalizada tiene fin confirmado y totales.
    "CHECK(lifecycle = 'finalized' OR (ended_epoch_ms IS NULL AND "
        'monitored_ms IS NULL))',
    "CHECK(lifecycle != 'finalized' OR (ended_epoch_ms IS NOT NULL AND "
        'end_offset_ms IS NOT NULL AND monitored_ms IS NOT NULL))',
  ];
}

/// Hecho de una sesión demostrativa (`SessionEvent`), con su desplazamiento
/// monotónico desde el inicio confirmado.
@DataClassName('DemoEventRow')
class DemoSessionEvents extends Table {
  TextColumn get sessionId => text().references(
    DemoSessions,
    #sessionId,
    onDelete: KeyAction.cascade,
  )();
  IntColumn get sequence => integer().check(sequence.isBiggerOrEqualValue(1))();
  TextColumn get type => text()();
  IntColumn get offsetMs => integer().check(offsetMs.isBiggerOrEqualValue(0))();
  TextColumn get measurement => text().nullable()();
  TextColumn get signal => text().nullable()();
  TextColumn get episodeId => text().nullable()();
  TextColumn get episodeKind => text().nullable()();
  TextColumn get detail => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {sessionId, sequence};
}

/// Preferencias (fila única, Área 06 §6).
@DataClassName('PreferencesRow')
class Preferences extends Table {
  IntColumn get singleton =>
      integer().check(singleton.equals(1)).withDefault(const Constant(1))();
  TextColumn get theme =>
      text().check(theme.isIn(const ['system', 'light', 'dark']))();
  TextColumn get soundPatternId => text()();
  BoolColumn get reducedMotion => boolean()();
  IntColumn get updatedEpochMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => {singleton};
}

@DriftDatabase(tables: [DemoSessions, DemoSessionEvents, Preferences])
class DemoHistoryDatabase extends _$DemoHistoryDatabase {
  DemoHistoryDatabase(super.e);

  /// historyDbVersion del almacén DEMO. Sin migraciones todavía: no hay otra
  /// versión distribuida (Área 06 §18).
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // Sin ruta destructiva: una versión desconocida no se borra (Área 06
      // §18). La primera migración real llegará con su prueba.
      throw StateError('Migración del historial DEMO $from→$to no definida');
    },
    beforeOpen: (details) async {
      // Área 06 §6: claves foráneas activas en cada conexión.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
