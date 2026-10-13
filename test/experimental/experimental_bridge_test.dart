import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_engine/monitoring_engine.dart';
import 'package:monitoring_engine/src/monitoring_api.g.dart';
import 'package:vigia/features/experimental/experimental_monitoring_controller.dart';
import 'package:vigia/features/experimental/monitoring_query_channel.dart';

import '../support/fake_experimental.dart';

void main() {
  testWidgets('los avisos siguen el sufijo del host Pigeon', (tester) async {
    final bridge = PigeonExperimentalMonitoringBridge(
      host: ExperimentalMonitoringHostApi(messageChannelSuffix: 'side'),
    );
    final received = <MonitoringSnapshot>[];
    final sub = bridge.updates.listen(received.add);
    final s = fakeSnapshot(sequence: 8);
    const name =
        'dev.flutter.pigeon.monitoring_engine.ExperimentalMonitoringFlutterApi.onMonitoring.side';
    unawaited(
      tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        name,
        ExperimentalMonitoringFlutterApi.pigeonChannelCodec.encodeMessage([s]),
        (_) {},
      ),
    );
    await tester.pump();
    unawaited(sub.cancel());
    await tester.pump();
    ExperimentalMonitoringFlutterApi.setUp(null);
    ExperimentalMonitoringFlutterApi.setUp(null, messageChannelSuffix: 'side');
    expect(received, hasLength(1));
    expect(received.single.sequence, 8);
  });

  testWidgets(
    'default implícito/explícito comparte una RPC y recupera el consumidor vigente',
    (tester) async {
      const channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.monitoring_engine.ExperimentalMonitoringHostApi.getMonitoringSnapshot',
        ExperimentalMonitoringHostApi.pigeonChannelCodec,
      );
      final calls = <Completer<Object?>>[];
      tester.binding.defaultBinaryMessenger
          .setMockDecodedMessageHandler<Object?>(channel, (_) {
            final c = Completer<Object?>();
            calls.add(c);
            return c.future;
          });
      final a = PigeonExperimentalMonitoringBridge();
      final b = PigeonExperimentalMonitoringBridge(
        host: ExperimentalMonitoringHostApi(
          binaryMessenger: ServicesBinding.instance.defaultBinaryMessenger,
        ),
      );
      final ca = ProviderContainer(
        overrides: [experimentalBridgeProvider.overrideWithValue(a)],
      );
      ca.read(experimentalMonitoringProvider.notifier).refresh();
      await tester.pump(const Duration(milliseconds: 800));
      ca.dispose();
      final cb = ProviderContainer(
        overrides: [experimentalBridgeProvider.overrideWithValue(b)],
      );
      cb.read(experimentalMonitoringProvider.notifier).refresh();
      await tester.pump(const Duration(seconds: 240));
      expect(calls, hasLength(1));
      expect(MonitoringQueryChannel.pendingOn(b)!.listenerCount, 1);
      expect(cb.read(experimentalMonitoringProvider).available, isFalse);
      calls.single.complete([
        fakeSnapshot(
          sequence: 500,
          eyesValid: true,
          lifecycle: EngineSessionLifecycle.active,
          measurement: EngineMeasurement.usable,
          signal: EngineSignal.prolongedEyeClosure,
        ),
      ]);
      await tester.pump();
      expect(
        cb.read(experimentalMonitoringProvider).signal,
        EngineSignal.notEvaluable,
      );
      tester.binding.defaultBinaryMessenger
          .setMockDecodedMessageHandler<Object?>(
            channel,
            (_) async => [
              fakeSnapshot(
                sequence: 501,
                eyesValid: true,
                observationId: 2,
                lifecycle: EngineSessionLifecycle.active,
                measurement: EngineMeasurement.usable,
                signal: EngineSignal.noPersistentSignals,
              ),
            ],
          );
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        cb.read(experimentalMonitoringProvider).signal,
        EngineSignal.noPersistentSignals,
      );
      cb.dispose();
      await tester.pump();
      expect(MonitoringQueryChannel.pendingOn(b), isNull);
      tester.binding.defaultBinaryMessenger
          .setMockDecodedMessageHandler<Object?>(channel, null);
      ExperimentalMonitoringFlutterApi.setUp(null);
    },
  );
}
