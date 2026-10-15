import 'package:monitoring_engine/monitoring_engine.dart';
import 'package:vigia/data/experimental_history/journal_codec.dart';

/// Doble del journal nativo (fase 5D) para pruebas de Flutter. Construye los
/// hechos con el mismo sobre y hash que `JournalRecord.build` en Kotlin y
/// responde como `ExperimentalJournalHost`: pendientes en orden, ACK exacto.
///
/// **No es una sesión real**: los hechos los fija la prueba. El journal real
/// se prueba en Kotlin (JVM y SQLite en Android).
class FakeJournal implements ExperimentalJournalBridge {
  final records = <JournalRecordMessage>[];
  final acked = <(String, String)>{};
  int reads = 0;
  int ackCalls = 0;

  /// Falla el siguiente ACK (la app «cae» después del commit en Drift).
  bool failNextAck = false;

  /// Falla la siguiente lectura.
  bool failNextRead = false;
  bool ignoreAck = false;

  int _n = 0;
  int startEpochMs = 1760000000000;

  JournalRecordMessage add(
    String type,
    String? sessionId,
    int? offsetMs,
    Map<String, Object?> payload, {
    String? recordId,
    int? sequence,
  }) {
    final seq =
        sequence ?? (records.isEmpty ? 1 : records.last.journalSequence + 1);
    final r = JournalRecordMessage(
      journalSequence: seq,
      recordId: recordId ?? 'rec-${++_n}',
      sessionId: sessionId,
      recordType: type,
      occurredEpochMs: startEpochMs + (offsetMs ?? 0),
      occurredOffsetMinutes: -300,
      sessionOffsetMs: offsetMs,
      payloadSchemaVersion: 1,
      payloadJson: JournalCodec.encode(payload),
      payloadHash: '',
    );
    r.payloadHash = JournalCodec.sha256Hex(
      JournalCodec.encode(JournalCodec.envelope(r, payload)),
    );
    records.add(r);
    return r;
  }

  // ── Hechos de una sesión, como los escribe SessionJournal ────────────

  static Map<String, Object?> totals({
    int active = 0,
    int evaluable = 0,
    int paused = 0,
    int closures = 0,
    int tones = 0,
    int tonesFailed = 0,
    int pauses = 0,
  }) => {
    'activeMs': active,
    'evaluableMs': evaluable,
    'nonEvaluableMs': active - evaluable,
    'pausedMs': paused,
    'closureActivations': closures,
    'tonesPlayed': tones,
    'tonesFailed': tonesFailed,
    'pauseCount': pauses,
  };

  void started(String id, {int epochMs = 1760000000000}) =>
      add('sessionStarted', id, 0, {
        'sessionId': id,
        'engineInstanceId': 'motor-1',
        'startedEpochMs': epochMs,
        'startOffsetMinutes': -300,
        'profileId': 'lab-eye-rules-0.1',
        'qualificationStatus': 'experimental',
        'landmarkSchema': 'mp-eye6-v1',
        'modelId': 'mediapipe/face_landmarker/float16/1',
        'modelSha256':
            '64184e229b263107bc2b804c6625db1341ff2bb731874b0bcc2fe6544e0bc9ff',
        'calibration': {
          'calibrationId': 'cal-$id',
          'openEarRightE6': 301000,
          'openEarLeftE6': 299000,
          'openSamples': 140,
          'openCoverageE6': 970000,
        },
      });

  void checkpoint(String id, int at, Map<String, Object?> t, {int lost = 0}) =>
      add('progressCheckpoint', id, at, {
        ...t,
        'knownThroughOffsetMs': at,
        'recordsLost': lost,
      });

  void closure(String id, int at, int ordinal, {String? toneError}) {
    add('closureDetected', id, at, {
      'activationOrdinal': ordinal,
      'decisionOffsetMs': at,
    });
    add('playbackResult', id, at, {
      'activationOrdinal': ordinal,
      'playbackOrdinal': 1,
      'requestedOffsetMs': at,
      'status': toneError == null ? 'started' : 'failed',
      'errorCode': toneError,
    });
  }

  void pause(String id, int at, int ordinal, Map<String, Object?> t) =>
      add('pauseStarted', id, at, {...t, 'pauseOrdinal': ordinal});

  void resume(String id, int at, int ordinal, Map<String, Object?> t) =>
      add('pauseEnded', id, at, {...t, 'pauseOrdinal': ordinal});

  void finalized(String id, int at, Map<String, Object?> t, {int lost = 0}) =>
      add('sessionFinalized', id, at, {
        ...t,
        'endOffsetMs': at,
        'endedEpochMs': startEpochMs + at,
        'endOffsetMinutes': -300,
        'recordsLost': lost,
      });

  void interrupted(String id, int lastDurable) =>
      add('interruptionRecovered', id, null, {
        'recoveredEpochMs': startEpochMs + 3600000,
        'recoveredByEngineInstanceId': 'motor-2',
        'previousEngineInstanceId': 'motor-1',
        'previousLifecycle': 'active',
        'lastDurableOffsetMs': lastDurable,
      });

  /// Sesión completa: 60 s activos (45 s evaluables), 10 s de pausa, una
  /// activación con su tono.
  void completeSession(String id) {
    started(id);
    checkpoint(id, 1000, totals(active: 1000));
    closure(id, 20000, 1);
    pause(
      id,
      30000,
      1,
      totals(active: 30000, evaluable: 25000, closures: 1, tones: 1, pauses: 1),
    );
    resume(
      id,
      40000,
      1,
      totals(
        active: 30000,
        evaluable: 25000,
        paused: 10000,
        closures: 1,
        tones: 1,
        pauses: 1,
      ),
    );
    finalized(
      id,
      70000,
      totals(
        active: 60000,
        evaluable: 45000,
        paused: 10000,
        closures: 1,
        tones: 1,
        pauses: 1,
      ),
    );
  }

  List<JournalRecordMessage> get pending =>
      records.where((r) => !acked.contains((r.recordId, r.payloadHash))).toList();

  @override
  Future<JournalBatch> readPendingRecords(int limit) async {
    reads++;
    if (failNextRead) {
      failNextRead = false;
      throw StateError('lectura simulada fallida');
    }
    final p = pending;
    final n = limit.clamp(1, 100);
    return JournalBatch(
      batchId: 'batch-$reads',
      records: p.take(n).toList(),
      highWatermark: records.isEmpty ? 0 : records.last.journalSequence,
      hasMore: p.length > n,
    );
  }

  @override
  Future<int> acknowledgeRecords(
    List<String> recordIds,
    List<String> payloadHashes,
  ) async {
    ackCalls++;
    if (ignoreAck) return 0;
    if (failNextAck) {
      failNextAck = false;
      throw StateError('ACK simulado fallido');
    }
    var n = 0;
    for (var i = 0; i < recordIds.length; i++) {
      final match = records.any(
        (r) => r.recordId == recordIds[i] && r.payloadHash == payloadHashes[i],
      );
      if (match && acked.add((recordIds[i], payloadHashes[i]))) n++;
    }
    return n;
  }
}
