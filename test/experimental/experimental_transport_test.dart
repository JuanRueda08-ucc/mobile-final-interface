import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_engine/monitoring_engine.dart';
import 'package:vigia/features/experimental/experimental_monitoring_controller.dart';
import 'package:vigia/features/experimental/monitoring_query_channel.dart';

import '../support/fake_experimental.dart';

class DelayedBridge extends FakeExperimentalBridge {
  final queries = <Completer<MonitoringSnapshot>>[];
  @override
  Future<MonitoringSnapshot> snapshot() {
    final c = Completer<MonitoringSnapshot>();
    queries.add(c);
    return c.future;
  }
}

void main() {
  test('leer antes de un timer retrasado no conserva la señal caducada', () {
    fakeAsync((time) {
      final bridge = FakeExperimentalBridge();
      final c = ProviderContainer(
        overrides: [experimentalBridgeProvider.overrideWithValue(bridge)],
      );
      c.read(experimentalMonitoringProvider.notifier);
      bridge.emit(
        fakeSnapshot(
          sequence: 2,
          eyesValid: true,
          lifecycle: EngineSessionLifecycle.active,
          measurement: EngineMeasurement.usable,
          signal: EngineSignal.prolongedEyeClosure,
        ),
      );
      time.flushMicrotasks();
      expect(
        c.read(experimentalMonitoringProvider).signal,
        EngineSignal.prolongedEyeClosure,
      );
      time.elapseBlocking(const Duration(milliseconds: 151));
      expect(
        c.read(experimentalMonitoringProvider).signal,
        EngineSignal.notEvaluable,
      );
      time.elapseBlocking(const Duration(milliseconds: 600));
      expect(c.read(experimentalMonitoringProvider).eyesValid, isFalse);
      c.dispose();
      time.flushMicrotasks();
    });
  });
  for (final ms in [749, 750, 800]) {
    test('respuesta a $ms ms antes del timer: frontera de recepción', () {
      fakeAsync((time) {
        final bridge = DelayedBridge();
        final c = ProviderContainer(
          overrides: [experimentalBridgeProvider.overrideWithValue(bridge)],
        );
        c.read(experimentalMonitoringProvider.notifier).refresh();
        time.flushMicrotasks();
        time.elapseBlocking(Duration(milliseconds: ms));
        bridge.queries.single.complete(
          fakeSnapshot(sequence: 2, eyesValid: true, observationId: 1),
        );
        time.flushMicrotasks();
        expect(c.read(experimentalMonitoringProvider).eyesValid, ms == 749);
        c.dispose();
        time.flushMicrotasks();
        expect(time.nonPeriodicTimerCount, 0);
        expect(time.periodicTimerCount, 0);
      });
    });
  }

  test('despacho tardío descuenta la vigencia nativa también de la señal', () {
    fakeAsync((time) {
      final bridge = DelayedBridge();
      final c = ProviderContainer(
        overrides: [experimentalBridgeProvider.overrideWithValue(bridge)],
      );
      c.read(experimentalMonitoringProvider.notifier).refresh();
      time.flushMicrotasks();
      bridge.queries.single.future.then(
        (_) => time.elapseBlocking(const Duration(milliseconds: 40)),
      );
      time.elapseBlocking(const Duration(milliseconds: 10));
      bridge.queries.single.complete(
        fakeSnapshot(
          sequence: 2,
          observationId: 1,
          eyesValid: true,
          eyesValidForMs: 700,
          signalValidForMs: 30,
          lifecycle: EngineSessionLifecycle.active,
          measurement: EngineMeasurement.usable,
          signal: EngineSignal.prolongedEyeClosure,
        ),
      );
      time.flushMicrotasks();
      expect(
        c.read(experimentalMonitoringProvider).signal,
        EngineSignal.notEvaluable,
      );
      expect(c.read(experimentalMonitoringProvider).eyesValid, isTrue);
      c.dispose();
      time.flushMicrotasks();
    });
  });

  test(
    'consultas sin respuesta 120/240 s: una real, plazo propio y recuperación',
    () {
      fakeAsync((time) {
        final bridge = DelayedBridge();
        final c = ProviderContainer(
          overrides: [experimentalBridgeProvider.overrideWithValue(bridge)],
        );
        c.read(experimentalMonitoringProvider.notifier).refresh();
        time.flushMicrotasks();
        time.elapse(const Duration(milliseconds: 749));
        expect(c.read(experimentalMonitoringProvider).queryStalled, isFalse);
        time.elapse(const Duration(milliseconds: 1));
        expect(c.read(experimentalMonitoringProvider).queryStalled, isTrue);
        for (final seconds in [120, 120]) {
          time.elapse(Duration(seconds: seconds));
          expect(bridge.queries, hasLength(1));
          expect(bridge.queries.single.isCompleted, isFalse);
        }
        bridge.queries.single.completeError(StateError('abandonada'));
        time.flushMicrotasks();
        expect(c.read(experimentalMonitoringProvider).available, isFalse);
        time.elapse(const Duration(milliseconds: 100));
        expect(bridge.queries, hasLength(2));
        bridge.queries.last.complete(
          fakeSnapshot(
            sequence: 2,
            eyesValid: true,
            observationId: 2,
            lifecycle: EngineSessionLifecycle.active,
            measurement: EngineMeasurement.usable,
            signal: EngineSignal.noPersistentSignals,
          ),
        );
        time.flushMicrotasks();
        expect(
          c.read(experimentalMonitoringProvider).signal,
          EngineSignal.noPersistentSignals,
        );
        c.dispose();
        time.flushMicrotasks();
      });
    },
  );

  for (final dispose in [false, true]) {
    test(
      '${dispose ? 'desechar' : 'salir'} cancela todos los timers y consumidores de consultas/órdenes',
      () {
        fakeAsync((time) {
          final bridge = DelayedBridge()..hold = Completer<void>();
          final c = ProviderContainer(
            overrides: [experimentalBridgeProvider.overrideWithValue(bridge)],
          );
          final ctrl = c.read(experimentalMonitoringProvider.notifier);
          ctrl.refresh();
          ctrl.testSound();
          time.flushMicrotasks();
          if (dispose) {
            c.dispose();
          } else {
            ctrl.leave();
          }
          time.flushMicrotasks();
          expect(time.nonPeriodicTimerCount, 0);
          expect(time.periodicTimerCount, 0);
          expect(MonitoringQueryChannel.pendingOn(bridge)!.listenerCount, 0);
          expect(
            MonitoringQueryChannel.pendingCommand(
              bridge,
              'testSound',
            )!.listenerCount,
            0,
          );
          bridge.queries.single.completeError(StateError('consulta vieja'));
          bridge.release();
          time.flushMicrotasks();
          expect(MonitoringQueryChannel.pendingOn(bridge), isNull);
          expect(
            MonitoringQueryChannel.pendingCommand(bridge, 'testSound'),
            isNull,
          );
          expect(time.nonPeriodicTimerCount, 0);
          expect(time.periodicTimerCount, 0);
          if (!dispose) c.dispose();
        });
      },
    );
  }
  test(
    'una orden sin respuesta termina para UI a 750 ms, sin duplicar RPC',
    () {
      fakeAsync((time) {
        final bridge = FakeExperimentalBridge()..hold = Completer<void>();
        final c = ProviderContainer(
          overrides: [experimentalBridgeProvider.overrideWithValue(bridge)],
        );
        var completed = false;
        final ctrl = c.read(experimentalMonitoringProvider.notifier);
        ctrl.testSound().then((_) => completed = true);
        time.flushMicrotasks();
        time.elapse(const Duration(milliseconds: 750));
        final doneAtDeadline = completed;
        final pendingAtDeadline = c
            .read(experimentalMonitoringProvider)
            .pending;
        for (var i = 0; i < 10; i++) {
          ctrl.testSound();
          time.elapse(const Duration(seconds: 1));
        }
        final count = bridge.calls.where((s) => s == 'testSound').length;
        c.dispose();
        bridge.release();
        time.flushMicrotasks();
        expect(count, 1);
        expect(doneAtDeadline, isTrue);
        expect(pendingAtDeadline, isNull);
      });
    },
  );

  test('recrear consumidores de una orden no duplica ni retiene callbacks', () {
    fakeAsync((time) {
      final bridge = FakeExperimentalBridge()..hold = Completer<void>();
      for (var i = 0; i < 10; i++) {
        final c = ProviderContainer(
          overrides: [experimentalBridgeProvider.overrideWithValue(bridge)],
        );
        c.read(experimentalMonitoringProvider.notifier).testSound();
        time.flushMicrotasks();
        c.dispose();
        time.flushMicrotasks();
      }
      final count = bridge.calls.where((s) => s == 'testSound').length;
      bridge.release();
      time.flushMicrotasks();
      expect(count, 1);
      expect(time.nonPeriodicTimerCount, 0);
      expect(time.periodicTimerCount, 0);
    });
  });
  test(
    'el mismo observationId no amplía ni revive; otro resultado recupera',
    () {
      fakeAsync((time) {
        final bridge = FakeExperimentalBridge();
        final c = ProviderContainer(
          overrides: [experimentalBridgeProvider.overrideWithValue(bridge)],
        );
        c.read(experimentalMonitoringProvider.notifier);
        MonitoringSnapshot sample(int seq, int id) => fakeSnapshot(
          sequence: seq,
          observationId: id,
          eyesValid: true,
          lifecycle: EngineSessionLifecycle.active,
          measurement: EngineMeasurement.usable,
          signal: EngineSignal.prolongedEyeClosure,
        );
        bridge.emit(sample(2, 7));
        time.flushMicrotasks();
        expect(
          c.read(experimentalMonitoringProvider).signal,
          EngineSignal.prolongedEyeClosure,
        );
        time.elapse(const Duration(milliseconds: 100));
        bridge.emit(sample(3, 7));
        time.flushMicrotasks();
        time.elapse(const Duration(milliseconds: 51));
        expect(
          c.read(experimentalMonitoringProvider).signal,
          EngineSignal.notEvaluable,
        );
        bridge.emit(sample(4, 7));
        time.flushMicrotasks();
        expect(
          c.read(experimentalMonitoringProvider).signal,
          EngineSignal.notEvaluable,
        );
        time.elapse(const Duration(milliseconds: 600));
        bridge.emit(sample(5, 7));
        time.flushMicrotasks();
        expect(c.read(experimentalMonitoringProvider).eyesValid, isFalse);
        bridge.emit(sample(6, 8));
        time.flushMicrotasks();
        expect(
          c.read(experimentalMonitoringProvider).signal,
          EngineSignal.prolongedEyeClosure,
        );
        expect(c.read(experimentalMonitoringProvider).eyesValid, isTrue);
        c.dispose();
        time.flushMicrotasks();
      });
    },
  );
  test('una consulta retenida 5000 ms no publica ojos ni cierre vigente', () {
    fakeAsync((time) {
      final bridge = DelayedBridge();
      final c = ProviderContainer(
        overrides: [experimentalBridgeProvider.overrideWithValue(bridge)],
      );
      final ctrl = c.read(experimentalMonitoringProvider.notifier);
      ctrl.refresh();
      time.flushMicrotasks();
      time.elapse(const Duration(milliseconds: 5000));
      bridge.queries.single.complete(
        fakeSnapshot(
          eyesValid: true,
          earRight: .05,
          earLeft: .05,
          lifecycle: EngineSessionLifecycle.active,
          sessionId: 's1',
          measurement: EngineMeasurement.usable,
          signal: EngineSignal.prolongedEyeClosure,
        ),
      );
      time.flushMicrotasks();
      final s = c.read(experimentalMonitoringProvider);
      c.dispose();
      time.flushMicrotasks();
      expect(s.signal, EngineSignal.notEvaluable);
      expect(s.connected, isFalse);
    });
  });

  test('una instancia retirada no reaparece por un aviso antiguo', () {
    fakeAsync((time) {
      final bridge = FakeExperimentalBridge();
      final c = ProviderContainer(
        overrides: [experimentalBridgeProvider.overrideWithValue(bridge)],
      );
      c.read(experimentalMonitoringProvider.notifier);
      bridge.emit(fakeSnapshot(engine: 'a', sequence: 10));
      time.flushMicrotasks();
      bridge.emit(fakeSnapshot(engine: 'b', sequence: 1));
      time.flushMicrotasks();
      bridge.emit(
        fakeSnapshot(
          engine: 'a',
          sequence: 11,
          eyesValid: true,
          signal: EngineSignal.prolongedEyeClosure,
        ),
      );
      time.flushMicrotasks();
      final s = c.read(experimentalMonitoringProvider);
      c.dispose();
      time.flushMicrotasks();
      expect(s.snapshot!.engineInstanceId, 'b');
      expect(s.signal, EngineSignal.notEvaluable);
    });
  });

  test(
    'un cierre mostrado caduca antes de los 3000 ms de vigilancia del motor',
    () {
      fakeAsync((time) {
        final bridge = FakeExperimentalBridge();
        final c = ProviderContainer(
          overrides: [experimentalBridgeProvider.overrideWithValue(bridge)],
        );
        c.read(experimentalMonitoringProvider.notifier);
        bridge.emit(
          fakeSnapshot(
            eyesValid: true,
            sequence: 2,
            lifecycle: EngineSessionLifecycle.active,
            measurement: EngineMeasurement.usable,
            signal: EngineSignal.prolongedEyeClosure,
          ),
        );
        time.flushMicrotasks();
        time.elapse(const Duration(milliseconds: 751));
        final signal = c.read(experimentalMonitoringProvider).signal;
        c.dispose();
        time.flushMicrotasks();
        expect(signal, EngineSignal.notEvaluable);
      });
    },
  );
}
