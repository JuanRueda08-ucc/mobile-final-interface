import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monitoring_engine/monitoring_engine.dart';

import 'experimental_history_repository.dart';

/// Historial experimental real (variante normal). Lo fija el arranque
/// (`bootstrap.dart`); sin él (pruebas que no lo necesitan, otras
/// plataformas) Inicio no muestra historial y no se importa nada.
final experimentalHistoryRepositoryProvider =
    Provider<ExperimentalHistoryRepository?>((ref) => null);

/// Lectura y ACK del journal nativo. Las pruebas lo sustituyen.
final experimentalJournalBridgeProvider = Provider<ExperimentalJournalBridge>(
  (ref) => PigeonExperimentalJournalBridge(),
);

/// Resultado de la última importación.
enum JournalSyncStatus {
  /// Todavía no se importó en esta ejecución.
  idle,
  running,

  /// El journal no tiene hechos pendientes.
  upToDate,

  /// Un hecho no superó la validación: se conserva pendiente en el journal.
  stopped,

  /// No se pudo leer el journal, guardar en Drift o enviar el ACK.
  failed,
}

final class JournalSyncState {
  const JournalSyncState({
    this.revision = 0,
    this.status = JournalSyncStatus.idle,
    this.stop,
  });

  /// Aumenta cuando cambia la proyección: las lecturas se rehacen.
  final int revision;
  final JournalSyncStatus status;
  final ImportStop? stop;
}

/// Importa el journal nativo a la proyección Drift (Área 04 §12):
/// lote → transacción Drift → commit → ACK de las revisiones exactas.
///
/// - Una sola importación a la vez; una petición durante otra la repite al
///   terminar (no se pierde un cierre que llegó mientras tanto).
/// - No depende de los avisos del motor: lee del journal durable, así que
///   un cierre cuyo mensaje no llegó a Flutter se importa igual.
/// - Si el ACK falla, Drift ya tiene los hechos; la próxima lectura los
///   devuelve y su importación es un no-op.
class JournalSync extends Notifier<JournalSyncState> {
  static const batchLimit = 100;

  /// Límite de lotes por pasada: evita un bucle si el journal no avanza.
  static const maxBatches = 50;

  Future<void>? _running;
  bool _again = false;

  @override
  JournalSyncState build() => const JournalSyncState();

  Future<void> sync() {
    final running = _running;
    if (running != null) {
      _again = true;
      return running;
    }
    final f = _loop();
    _running = f;
    return f;
  }

  Future<void> _loop() async {
    try {
      do {
        _again = false;
        await _pass();
      } while (_again && ref.mounted);
    } finally {
      _running = null;
    }
  }

  Future<void> _pass() async {
    final repo = ref.read(experimentalHistoryRepositoryProvider);
    if (repo == null || !ref.mounted) return;
    final bridge = ref.read(experimentalJournalBridgeProvider);
    _set(JournalSyncStatus.running, null, false);
    var changed = false;
    String? previousBatch;
    try {
      for (var i = 0; i < maxBatches; i++) {
        final batch = await bridge.readPendingRecords(batchLimit);
        if (batch.records.isEmpty) {
          _set(JournalSyncStatus.upToDate, null, changed);
          return;
        }
        final fingerprint = batch.records
            .map((r) => '${r.recordId}:${r.payloadHash}')
            .join('|');
        if (fingerprint == previousBatch) throw StateError('ACK sin avance');
        previousBatch = fingerprint;
        final outcome = await repo.importRecords(batch.records);
        changed = changed || outcome.applied > 0 || outcome.stop != null;
        if (outcome.acks.isNotEmpty) {
          await bridge.acknowledgeRecords(
            [for (final a in outcome.acks) a.$1],
            [for (final a in outcome.acks) a.$2],
          );
        }
        if (outcome.stop != null) {
          _set(JournalSyncStatus.stopped, outcome.stop, changed);
          return;
        }
        if (!batch.hasMore) {
          // Un ACK perdido o que no confirma nada no debe anunciar al día.
          final remaining = await bridge.readPendingRecords(1);
          if (remaining.records.isEmpty) {
            _set(JournalSyncStatus.upToDate, null, changed);
            return;
          }
        }
      }
      // Ceder el turno y continuar: 5000 hechos no es el fin del journal.
      _set(JournalSyncStatus.running, null, changed);
      _again = true;
      await Future<void>.delayed(Duration.zero);
    } catch (_) {
      _set(JournalSyncStatus.failed, null, changed);
    }
  }

  void _set(JournalSyncStatus status, ImportStop? stop, bool changed) {
    if (!ref.mounted) return;
    state = JournalSyncState(
      revision: state.revision + (changed ? 1 : 0),
      status: status,
      stop: stop,
    );
  }
}

final journalSyncProvider = NotifierProvider<JournalSync, JournalSyncState>(
  JournalSync.new,
);

final _revisionProvider = Provider<int>(
  (ref) => ref.watch(journalSyncProvider.select((s) => s.revision)),
);

ExperimentalHistoryRepository _repo(Ref ref) {
  final repo = ref.read(experimentalHistoryRepositoryProvider);
  if (repo == null) throw StateError('Historial experimental no abierto');
  return repo;
}

final experimentalHistoryListProvider =
    FutureProvider.family<
      List<ExperimentalSessionRecord>,
      ExperimentalHistoryFilter
    >((ref, filter) {
      ref.watch(_revisionProvider);
      return _repo(ref).sessions(filter: filter);
    });

final experimentalSessionProvider =
    FutureProvider.family<ExperimentalSessionRecord?, String>((ref, id) {
      ref.watch(_revisionProvider);
      return _repo(ref).session(id);
    });

final experimentalMarksProvider =
    FutureProvider.family<List<ExperimentalMark>, String>((ref, id) {
      ref.watch(_revisionProvider);
      return _repo(ref).marks(id);
    });

final latestExperimentalSessionProvider =
    FutureProvider<ExperimentalSessionRecord?>((ref) {
      ref.watch(_revisionProvider);
      return _repo(ref).latest();
    });
