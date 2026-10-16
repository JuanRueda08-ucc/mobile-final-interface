import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monitoring_engine/monitoring_engine.dart';

import '../../data/preferences/preferences_store.dart';
import '../experimental/experimental_bridge_provider.dart';

final realSettingsWriterProvider = Provider<RealSettingsWriter>((ref) {
  final writer = RealSettingsWriter(ref.read(experimentalBridgeProvider));
  ref.onDispose(writer.dispose);
  return writer;
});

class RealSettingsWriter {
  RealSettingsWriter(this.bridge);
  final ExperimentalMonitoringBridge bridge;
  bool pending = false;
  int _settingsSequence = 0;
  final _snapshots = StreamController<MonitoringSnapshot>.broadcast();
  Stream<MonitoringSnapshot> get snapshots => _snapshots.stream;
  void _publish(MonitoringSnapshot s) {
    if (!_snapshots.isClosed) _snapshots.add(s);
  }

  void dispose() => _snapshots.close();

  Future<bool> save(
    StoredPreferences previous,
    StoredPreferences next,
    Future<void> Function() persist,
  ) async {
    pending = true;

    final id = 'settings-${identityHashCode(this)}-${++_settingsSequence}';
    var durable = false;
    var cleanupRequired = true;
    try {
      final r = await bridge.beginSettingsChange(id, next.soundPatternId);
      _publish(r.snapshot);
      if (!r.accepted) {
        cleanupRequired = false;
        return false;
      }
      await persist();
      durable = true;
    } catch (_) {
      // Puede haberse perdido la respuesta después de reservar. Finalizar por
      // ID también es seguro si la orden no llegó al motor.
    } finally {
      final pattern = durable ? next.soundPatternId : previous.soundPatternId;
      if (cleanupRequired) {
        // Una respuesta perdida no permite anunciar éxito ni liberar start
        // anticipadamente. La finalización nativa es idempotente por ID.
        while (true) {
          try {
            final r = await bridge.finishSettingsChange(id, pattern);
            _publish(r.snapshot);
            if (r.accepted && r.snapshot.soundPatternId == pattern) break;
            if (r.errorCode == 'unknownSettingsChange') {
              if (r.snapshot.soundPatternId == pattern) break;
              // Motor reiniciado: aplicar el patrón durable, también al
              // restaurar una escritura fallida, antes de liberar Ajustes.
              final again = await bridge.beginSettingsChange(id, pattern);
              _publish(again.snapshot);
            }
          } catch (_) {
            // Conserva la reserva y el estado «guardando» hasta reconciliar.
          }
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      }
      pending = false;
    }
    return durable;
  }
}
