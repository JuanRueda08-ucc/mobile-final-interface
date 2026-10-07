import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/monitoring/domain/session_model.dart';
import 'demo_history_repository.dart';

/// Repositorio del historial DEMO. Lo fija el arranque de la app
/// com.juanrueda.vigia.demo (`bootstrap.dart`) y, en pruebas, una base en
/// memoria. Sin él no hay recorrido: no se sustituye por una lista en memoria.
final demoHistoryRepositoryProvider = Provider<DemoHistoryRepository>(
  (ref) => throw UnimplementedError(
    'Historial DEMO no abierto: el recorrido necesita su base '
    'vigia_history_demo_v1.sqlite.',
  ),
);

/// Estado de las escrituras del historial.
final class HistorySyncState {
  const HistorySyncState({this.revision = 0, this.pending = 0, this.failure});

  /// Aumenta con cada escritura confirmada: las lecturas se rehacen.
  final int revision;

  /// Escrituras en curso.
  final int pending;

  /// Último fallo de escritura (ER12, «Registro incompleto»).
  final String? failure;
}

/// Serializa las escrituras del historial en su orden de llegada y publica su
/// resultado. Un fallo no se oculta: queda en [HistorySyncState.failure].
class HistorySync extends Notifier<HistorySyncState> {
  Future<void> _tail = Future.value();

  @override
  HistorySyncState build() => const HistorySyncState();

  /// Encola [write] tras las anteriores. Devuelve su resultado o `null` si
  /// falló.
  Future<T?> run<T>(Future<T> Function(DemoHistoryRepository repo) write) {
    final repo = ref.read(demoHistoryRepositoryProvider);
    state = HistorySyncState(
      revision: state.revision,
      pending: state.pending + 1,
      failure: state.failure,
    );
    final result = _tail.then((_) async {
      try {
        final r = await write(repo);
        if (ref.mounted) {
          state = HistorySyncState(
            revision: state.revision + 1,
            pending: state.pending - 1,
            failure: state.failure,
          );
        }
        return r;
      } catch (e) {
        if (ref.mounted) {
          state = HistorySyncState(
            revision: state.revision + 1,
            pending: state.pending - 1,
            failure: 'No se pudo guardar el registro.',
          );
        }
        return null;
      }
    });
    _tail = result;
    return result;
  }
}

final historySyncProvider = NotifierProvider<HistorySync, HistorySyncState>(
  HistorySync.new,
);

/// Revisión del historial: las lecturas dependen de ella.
final _revisionProvider = Provider<int>(
  (ref) => ref.watch(historySyncProvider.select((s) => s.revision)),
);

/// Lista del Historial (P08) con su filtro.
final historyListProvider =
    FutureProvider.family<List<StoredSession>, HistoryFilter>((ref, filter) {
      ref.watch(_revisionProvider);
      return ref.read(demoHistoryRepositoryProvider).sessions(filter: filter);
    });

/// Una sesión guardada por ID (P07, P09).
final storedSessionProvider = FutureProvider.family<StoredSession?, String>((
  ref,
  sessionId,
) {
  ref.watch(_revisionProvider);
  return ref.read(demoHistoryRepositoryProvider).session(sessionId);
});

/// Hechos guardados de una sesión (línea temporal de P09).
final storedEventsProvider = FutureProvider.family<List<SessionEvent>, String>((
  ref,
  sessionId,
) {
  ref.watch(_revisionProvider);
  return ref.read(demoHistoryRepositoryProvider).events(sessionId);
});

/// Sesión más reciente del historial (Inicio: último resumen o registro
/// interrumpido).
final latestStoredSessionProvider = FutureProvider<StoredSession?>((ref) {
  ref.watch(_revisionProvider);
  return ref.read(demoHistoryRepositoryProvider).latestSession();
});
