import 'package:drift/drift.dart';
import 'package:monitoring_engine/monitoring_engine.dart';

import '../demo_history/demo_history_repository.dart' show CivilTime;
import 'experimental_history_database.dart';
import 'journal_codec.dart';

/// Ciclo de una sesión experimental en la proyección.
enum ExperimentalLifecycle { active, paused, finalized, interrupted }

/// Filtro del Historial experimental.
enum ExperimentalHistoryFilter { all, finalized, interrupted }

/// Totales confirmados al cerrar la sesión (ms y contadores del motor).
final class ExperimentalTotals {
  const ExperimentalTotals({
    required this.active,
    required this.evaluable,
    required this.notEvaluable,
    required this.paused,
    required this.closureActivations,
    required this.tonesPlayed,
    required this.tonesFailed,
    required this.pauses,
  });

  /// Tiempo con la sesión activa (evaluable + no evaluable), sin pausas.
  final Duration active;
  final Duration evaluable;
  final Duration notEvaluable;
  final Duration paused;
  final int closureActivations;
  final int tonesPlayed;
  final int tonesFailed;
  final int pauses;

  /// Total representado: activo + pausado (no hay tiempo desconocido acotado
  /// en una sesión con cierre confirmado).
  Duration get represented => active + paused;

  /// evaluable / (evaluable + no evaluable); nulo sin denominador (Área 04 §14).
  double? get coverage {
    final d = evaluable + notEvaluable;
    if (d == Duration.zero) return null;
    return evaluable.inMicroseconds / d.inMicroseconds;
  }
}

/// Último prefijo confirmado de una sesión sin cierre (punto de control o
/// pausa). No se extrapola más allá de [through].
final class ExperimentalKnownPrefix {
  const ExperimentalKnownPrefix({
    required this.through,
    required this.active,
    required this.evaluable,
    required this.paused,
  });

  final Duration through;
  final Duration active;
  final Duration evaluable;
  final Duration paused;
}

/// Sesión experimental real tal como la guarda la proyección. Inicio,
/// Resumen, Historial y detalle leen este mismo objeto.
final class ExperimentalSessionRecord {
  const ExperimentalSessionRecord({
    required this.sessionId,
    required this.profileId,
    required this.qualificationStatus,
    required this.modelId,
    required this.calibrationId,
    required this.openEarRight,
    required this.openEarLeft,
    required this.calibrationSamples,
    required this.startedAt,
    required this.lifecycle,
    required this.endedAt,
    required this.endOffset,
    required this.latestDurableOffset,
    required this.recoveredAt,
    required this.complete,
    required this.recordsLost,
    required this.totals,
    required this.known,
  });

  final String sessionId;

  /// `lab-eye-rules-0.1` y `experimental`, leídos de la base.
  final String profileId;
  final String qualificationStatus;
  final String modelId;
  final String calibrationId;
  final double openEarRight;
  final double openEarLeft;
  final int calibrationSamples;

  final CivilTime startedAt;
  final ExperimentalLifecycle lifecycle;

  /// Fin civil confirmado; nulo sin cierre confirmado.
  final CivilTime? endedAt;
  final Duration? endOffset;
  final Duration latestDurableOffset;

  /// Instante en que se detectó la interrupción al reabrir. No es el final.
  final CivilTime? recoveredAt;
  final bool complete;
  final int recordsLost;

  /// Solo con cierre confirmado y registro completo. Los valores recibidos
  /// de un cierre incompleto se conservan en SQLite, sin presentarlos como totales.
  final ExperimentalTotals? totals;
  final ExperimentalKnownPrefix? known;

  bool get isFinalized => lifecycle == ExperimentalLifecycle.finalized;
  bool get isInterrupted => lifecycle == ExperimentalLifecycle.interrupted;
  bool get isOpen =>
      lifecycle == ExperimentalLifecycle.active ||
      lifecycle == ExperimentalLifecycle.paused;

  CivilTime get latestDurableAt => startedAt.plus(latestDurableOffset);
}

/// Tipo de hecho de la línea temporal.
enum ExperimentalMarkKind { closure, playback, pauseStarted, pauseEnded }

final class ExperimentalMark {
  const ExperimentalMark({
    required this.kind,
    required this.offset,
    required this.ordinal,
    this.playbackOrdinal,
    this.status,
    this.errorCode,
  });

  final ExperimentalMarkKind kind;
  final Duration offset;
  final int ordinal;
  final int? playbackOrdinal;
  final String? status;
  final String? errorCode;
}

/// Causa por la que se detuvo una importación (Área 04 §15).
enum ImportStop {
  /// Hash, forma canónica o identidad no coinciden: `recordIntegrityFailed`.
  integrity,

  /// Falta un hecho anterior en la secuencia (pérdida no declarada).
  gap,

  /// Tipo o versión de hecho desconocidos: `schemaUnsupported`.
  schema,

  /// El hecho no encaja con el estado de la sesión (p. ej. sin inicio).
  relation,
}

/// Resultado de importar un lote: lo confirmado y, si se detuvo, por qué.
final class ImportOutcome {
  const ImportOutcome({
    required this.acks,
    required this.applied,
    this.stop,
    this.stopRecordId,
  });

  /// Revisiones (ID, hash) guardadas en Drift o ya guardadas antes: se
  /// pueden confirmar al journal.
  final List<(String, String)> acks;

  /// Hechos nuevos aplicados en esta importación.
  final int applied;
  final ImportStop? stop;
  final String? stopRecordId;
}

class _Stop implements Exception {
  _Stop(this.cause, this.index);
  final ImportStop cause;
  final int index;
}

/// Historial experimental real: proyección Drift del journal nativo.
class ExperimentalHistoryRepository {
  ExperimentalHistoryRepository(this._db);

  final ExperimentalHistoryDatabase _db;

  /// Importa [records] en orden, en una sola transacción. Un registro ya
  /// importado con el mismo hash es un no-op; con otro hash, un error de
  /// integridad. Ante el primer error se guardan los anteriores y se detiene
  /// (los siguientes quedan pendientes en el journal).
  Future<ImportOutcome> importRecords(
    List<JournalRecordMessage> records,
  ) async {
    var limit = records.length;
    _Stop? stop;
    while (true) {
      try {
        final (acks, applied) = await _db.transaction(() async {
          final result = await _apply(records.sublist(0, limit));
          final invalid = stop;
          if (invalid != null) {
            final affected = records[invalid.index].sessionId;
            if (affected != null) {
              await (_db.update(
                _db.experimentalSessions,
              )..where((s) => s.sessionId.equals(affected))).write(
                const ExperimentalSessionsCompanion(
                  integrityStatus: Value('incomplete'),
                ),
              );
            }
          }
          return result;
        });
        return ImportOutcome(
          acks: acks,
          applied: applied,
          stop: stop?.cause,
          stopRecordId: stop == null ? null : records[stop.index].recordId,
        );
      } on _Stop catch (e) {
        // Se deshace el lote y se repite solo con el prefijo válido.
        stop = e;
        limit = e.index;
      }
    }
  }

  Future<(List<(String, String)>, int)> _apply(
    List<JournalRecordMessage> records,
  ) async {
    final acks = <(String, String)>[];
    var applied = 0;
    final maxRow = await _db
        .customSelect(
          'SELECT COALESCE(MAX(journal_sequence), 0) AS m FROM imported_records',
        )
        .getSingle();
    var maxImported = maxRow.read<int>('m');
    for (var i = 0; i < records.length; i++) {
      final r = records[i];
      final Map<String, Object?> payload;
      try {
        payload = JournalCodec.verify(r);
      } on FormatException {
        throw _Stop(ImportStop.integrity, i);
      }
      final prior = await (_db.select(
        _db.importedRecords,
      )..where((t) => t.recordId.equals(r.recordId))).getSingleOrNull();
      if (prior != null) {
        if (prior.payloadHash != r.payloadHash ||
            prior.journalSequence != r.journalSequence) {
          throw _Stop(ImportStop.integrity, i);
        }
        acks.add((r.recordId, r.payloadHash));
        continue;
      }
      if (r.journalSequence <= maxImported) {
        // Secuencia ya usada por otro hecho: no se sobrescribe.
        throw _Stop(ImportStop.integrity, i);
      }
      if (r.journalSequence != maxImported + 1) throw _Stop(ImportStop.gap, i);
      if (r.payloadSchemaVersion != 1) throw _Stop(ImportStop.schema, i);
      await _applyFact(r, payload, i);
      await _db
          .into(_db.importedRecords)
          .insert(
            ImportedRecordsCompanion.insert(
              recordId: r.recordId,
              journalSequence: r.journalSequence,
              payloadHash: r.payloadHash,
              recordType: r.recordType,
            ),
          );
      maxImported = r.journalSequence;
      applied++;
      acks.add((r.recordId, r.payloadHash));
    }
    return (acks, applied);
  }

  Future<void> _applyFact(
    JournalRecordMessage r,
    Map<String, Object?> p,
    int index,
  ) async {
    int req(String k) {
      final v = p[k];
      if (v is! int) throw _Stop(ImportStop.integrity, index);
      return v;
    }

    String str(Map<String, Object?> m, String k) {
      final v = m[k];
      if (v is! String) throw _Stop(ImportStop.integrity, index);
      return v;
    }

    final id = r.sessionId;
    if (id == null) throw _Stop(ImportStop.relation, index);
    final row = await _row(id);
    final open =
        row != null && (row.lifecycle == 'active' || row.lifecycle == 'paused');
    final offset = r.sessionOffsetMs;

    Future<void> update(ExperimentalSessionsCompanion c) async {
      await (_db.update(
        _db.experimentalSessions,
      )..where((s) => s.sessionId.equals(id))).write(c);
    }

    Value<int> durable(int? at) => Value(
      at != null && at > row!.latestDurableOffsetMs
          ? at
          : row!.latestDurableOffsetMs,
    );

    ExperimentalSessionsCompanion known(int through) =>
        ExperimentalSessionsCompanion(
          knownThroughMs: Value(through),
          knownActiveMs: Value(req('activeMs')),
          knownEvaluableMs: Value(req('evaluableMs')),
          knownPausedMs: Value(req('pausedMs')),
          latestDurableOffsetMs: durable(through),
        );

    Future<void> mark(
      String kind,
      int ordinal, {
      int? playback,
      String? status,
      String? error,
    }) => _db
        .into(_db.experimentalSessionMarks)
        .insert(
          ExperimentalSessionMarksCompanion.insert(
            recordId: r.recordId,
            sessionId: id,
            journalSequence: r.journalSequence,
            kind: kind,
            offsetMs: offset ?? (throw _Stop(ImportStop.integrity, index)),
            ordinal: ordinal,
            playbackOrdinal: Value(playback),
            status: Value(status),
            errorCode: Value(error),
          ),
        );

    switch (r.recordType) {
      case 'sessionStarted':
        if (row != null || str(p, 'sessionId') != id) {
          throw _Stop(ImportStop.relation, index);
        }
        final cal = p['calibration'];
        if (cal is! Map<String, Object?>) {
          throw _Stop(ImportStop.integrity, index);
        }
        int calInt(String k) {
          final v = cal[k];
          if (v is! int) throw _Stop(ImportStop.integrity, index);
          return v;
        }

        if (str(p, 'qualificationStatus') != 'experimental') {
          // Este historial solo admite el perfil experimental.
          throw _Stop(ImportStop.schema, index);
        }
        await _db
            .into(_db.experimentalSessions)
            .insert(
              ExperimentalSessionsCompanion.insert(
                sessionId: id,
                profileId: str(p, 'profileId'),
                landmarkSchema: str(p, 'landmarkSchema'),
                modelId: str(p, 'modelId'),
                modelSha256: str(p, 'modelSha256'),
                engineInstanceId: str(p, 'engineInstanceId'),
                calibrationId: str(cal, 'calibrationId'),
                openEarRightE6: calInt('openEarRightE6'),
                openEarLeftE6: calInt('openEarLeftE6'),
                calibrationSamples: calInt('openSamples'),
                calibrationCoverageE6: calInt('openCoverageE6'),
                startedEpochMs: req('startedEpochMs'),
                startOffsetMinutes: req('startOffsetMinutes'),
                lifecycle: 'active',
                latestDurableOffsetMs: 0,
                integrityStatus: 'incomplete',
              ),
            );
      case 'progressCheckpoint':
        if (!open || offset == null) throw _Stop(ImportStop.relation, index);
        await update(
          known(offset).copyWith(recordsLost: Value(req('recordsLost'))),
        );
      case 'pauseStarted' || 'pauseEnded':
        if (!open || offset == null) throw _Stop(ImportStop.relation, index);
        final started = r.recordType == 'pauseStarted';
        await mark(r.recordType, req('pauseOrdinal'));
        await update(
          known(offset)
              .copyWith(lifecycle: Value(started ? 'paused' : 'active')),
        );
      case 'closureDetected':
        if (!open) throw _Stop(ImportStop.relation, index);
        await mark('closure', req('activationOrdinal'));
        await update(
          ExperimentalSessionsCompanion(latestDurableOffsetMs: durable(offset)),
        );
      case 'playbackResult':
        if (!open) throw _Stop(ImportStop.relation, index);
        final status = str(p, 'status');
        if (status != 'started' && status != 'failed') {
          throw _Stop(ImportStop.integrity, index);
        }
        final error = p['errorCode'];
        await mark(
          'playback',
          req('activationOrdinal'),
          playback: req('playbackOrdinal'),
          status: status,
          error: error is String ? error : null,
        );
        await update(
          ExperimentalSessionsCompanion(latestDurableOffsetMs: durable(offset)),
        );
      case 'sessionFinalized':
        // Cierre único: una sesión ya cerrada o interrumpida no se cierra.
        if (!open || offset == null) throw _Stop(ImportStop.relation, index);
        final lost = req('recordsLost');
        await update(
          ExperimentalSessionsCompanion(
            lifecycle: const Value('finalized'),
            endedEpochMs: Value(req('endedEpochMs')),
            endOffsetMinutes: Value(req('endOffsetMinutes')),
            endOffsetMs: Value(req('endOffsetMs')),
            latestDurableOffsetMs: Value(req('endOffsetMs')),
            recordsLost: Value(lost),
            integrityStatus: Value(lost == 0 ? 'complete' : 'incomplete'),
            activeMs: Value(req('activeMs')),
            evaluableMs: Value(req('evaluableMs')),
            nonEvaluableMs: Value(req('nonEvaluableMs')),
            pausedMs: Value(req('pausedMs')),
            closureActivations: Value(req('closureActivations')),
            tonesPlayed: Value(req('tonesPlayed')),
            tonesFailed: Value(req('tonesFailed')),
            pauseCount: Value(req('pauseCount')),
          ),
        );
      case 'interruptionRecovered':
        if (!open) throw _Stop(ImportStop.relation, index);
        await update(
          ExperimentalSessionsCompanion(
            lifecycle: const Value('interrupted'),
            integrityStatus: const Value('incomplete'),
            recoveredEpochMs: Value(req('recoveredEpochMs')),
            latestDurableOffsetMs: durable(req('lastDurableOffsetMs')),
          ),
        );
      default:
        throw _Stop(ImportStop.schema, index);
    }
  }

  // ── Consultas ────────────────────────────────────────────────────────

  /// Sesiones por inicio descendente, desempate por ID (Área 06 §11).
  Future<List<ExperimentalSessionRecord>> sessions({
    ExperimentalHistoryFilter filter = ExperimentalHistoryFilter.all,
  }) async {
    final q = _db.select(_db.experimentalSessions)
      ..orderBy([
        (s) => OrderingTerm.desc(s.startedEpochMs),
        (s) => OrderingTerm.desc(s.sessionId),
      ]);
    switch (filter) {
      case ExperimentalHistoryFilter.all:
        break;
      case ExperimentalHistoryFilter.finalized:
        q.where((s) => s.lifecycle.equals('finalized'));
      case ExperimentalHistoryFilter.interrupted:
        q.where((s) => s.lifecycle.equals('interrupted'));
    }
    return [for (final r in await q.get()) _record(r)];
  }

  Future<ExperimentalSessionRecord?> session(String sessionId) async {
    final r = await _row(sessionId);
    return r == null ? null : _record(r);
  }

  Future<ExperimentalSessionRecord?> latest() async {
    final r =
        await (_db.select(_db.experimentalSessions)
              ..orderBy([
                (s) => OrderingTerm.desc(s.startedEpochMs),
                (s) => OrderingTerm.desc(s.sessionId),
              ])
              ..limit(1))
            .getSingleOrNull();
    return r == null ? null : _record(r);
  }

  Future<List<ExperimentalMark>> marks(String sessionId) async {
    final rows =
        await (_db.select(_db.experimentalSessionMarks)
              ..where((m) => m.sessionId.equals(sessionId))
              ..orderBy([(m) => OrderingTerm.asc(m.journalSequence)]))
            .get();
    return [
      for (final m in rows)
        ExperimentalMark(
          kind: ExperimentalMarkKind.values.byName(m.kind),
          offset: Duration(milliseconds: m.offsetMs),
          ordinal: m.ordinal,
          playbackOrdinal: m.playbackOrdinal,
          status: m.status,
          errorCode: m.errorCode,
        ),
    ];
  }

  /// Número de hechos importados (diagnóstico y pruebas de duplicados).
  Future<int> importedCount() async =>
      (await _db
              .customSelect('SELECT COUNT(*) AS n FROM imported_records')
              .getSingle())
          .read<int>('n');

  Future<ExperimentalSessionRow?> _row(String id) => (_db.select(
    _db.experimentalSessions,
  )..where((s) => s.sessionId.equals(id))).getSingleOrNull();

  static ExperimentalSessionRecord _record(ExperimentalSessionRow r) {
    Duration ms(int v) => Duration(milliseconds: v);
    final lifecycle = ExperimentalLifecycle.values.byName(r.lifecycle);
    final started = CivilTime(r.startedEpochMs, r.startOffsetMinutes);
    return ExperimentalSessionRecord(
      sessionId: r.sessionId,
      profileId: r.profileId,
      qualificationStatus: r.qualificationStatus,
      modelId: r.modelId,
      calibrationId: r.calibrationId,
      openEarRight: r.openEarRightE6 / 1e6,
      openEarLeft: r.openEarLeftE6 / 1e6,
      calibrationSamples: r.calibrationSamples,
      startedAt: started,
      lifecycle: lifecycle,
      endedAt: r.endedEpochMs == null
          ? null
          : CivilTime(r.endedEpochMs!, r.endOffsetMinutes!),
      endOffset: r.endOffsetMs == null ? null : ms(r.endOffsetMs!),
      latestDurableOffset: ms(r.latestDurableOffsetMs),
      // La recuperación se presenta con el offset del inicio: es un dato
      // técnico, no una fecha de fin.
      recoveredAt: r.recoveredEpochMs == null
          ? null
          : CivilTime(r.recoveredEpochMs!, r.startOffsetMinutes),
      complete: r.integrityStatus == 'complete',
      recordsLost: r.recordsLost,
      totals:
          lifecycle == ExperimentalLifecycle.finalized &&
              r.integrityStatus == 'complete'
          ? ExperimentalTotals(
              active: ms(r.activeMs!),
              evaluable: ms(r.evaluableMs!),
              notEvaluable: ms(r.nonEvaluableMs!),
              paused: ms(r.pausedMs!),
              closureActivations: r.closureActivations!,
              tonesPlayed: r.tonesPlayed!,
              tonesFailed: r.tonesFailed!,
              pauses: r.pauseCount!,
            )
          : null,
      known: r.knownThroughMs == null
          ? null
          : ExperimentalKnownPrefix(
              through: ms(r.knownThroughMs!),
              active: ms(r.knownActiveMs!),
              evaluable: ms(r.knownEvaluableMs!),
              paused: ms(r.knownPausedMs!),
            ),
    );
  }
}
