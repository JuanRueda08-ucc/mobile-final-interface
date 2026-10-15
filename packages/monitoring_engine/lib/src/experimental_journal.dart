import 'monitoring_api.g.dart';

/// Lectura y ACK del journal nativo experimental (fase 5D, Área 04 §12).
///
/// La app depende de esta interfaz; las pruebas la sustituyen por un doble.
/// Kotlin es la fuente durable de los hechos; Flutter los importa a su
/// historial y solo después envía el ACK de las revisiones exactas.
abstract interface class ExperimentalJournalBridge {
  /// Hechos sin ACK en orden de secuencia (como mucho [limit], máx. 100).
  Future<JournalBatch> readPendingRecords(int limit);

  /// Confirma los hechos con ese ID **y** ese hash. Devuelve cuántos.
  Future<int> acknowledgeRecords(
    List<String> recordIds,
    List<String> payloadHashes,
  );
}

/// [ExperimentalJournalBridge] sobre los mensajes generados por Pigeon.
class PigeonExperimentalJournalBridge implements ExperimentalJournalBridge {
  PigeonExperimentalJournalBridge({ExperimentalJournalHostApi? host})
    : _host = host ?? ExperimentalJournalHostApi();

  final ExperimentalJournalHostApi _host;

  @override
  Future<JournalBatch> readPendingRecords(int limit) =>
      _host.readPendingRecords(limit);

  @override
  Future<int> acknowledgeRecords(
    List<String> recordIds,
    List<String> payloadHashes,
  ) => _host.acknowledgeRecords(recordIds, payloadHashes);
}
