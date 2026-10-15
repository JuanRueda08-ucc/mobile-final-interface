import 'package:drift/drift.dart' show QueryExecutor, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia/app/app_config.dart';
import 'package:vigia/app/bootstrap.dart';
import 'package:vigia/demo/inicio_demo.dart';

/// Coherencia entre el modo Dart y la aplicación Android (fase 3). Gradle
/// deriva el applicationId de la misma definición `VIGIA_DEMO`; esta
/// comprobación, en el arranque, impide que una compilación incoherente abra
/// el historial. El applicationId del APK construido se comprueba aparte con
/// `aapt` (docs/fase3-historial-ajustes.md).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('cada modo exige su applicationId', () {
    expect(expectedApplicationId(const DemoMode()), demoApplicationId);
    expect(expectedApplicationId(const RealMode()), realApplicationId);
    expect(
      expectedApplicationId(
        InicioReviewMode(InicioDemoVariant.sinHistorial.state),
      ),
      realApplicationId,
      reason: 'la revisión de Inicio no escribe: va en la app normal',
    );
    expect(demoApplicationId, 'com.juanrueda.vigia.demo');
    expect(realApplicationId, 'com.juanrueda.vigia');
  });

  test('un modo en la aplicación equivocada no arranca', () {
    checkApplicationId(const DemoMode(), demoApplicationId);
    checkApplicationId(const RealMode(), realApplicationId);
    expect(
      () => checkApplicationId(const DemoMode(), realApplicationId),
      throwsStateError,
      reason: 'la simulación no escribe en la app normal',
    );
    expect(
      () => checkApplicationId(const RealMode(), demoApplicationId),
      throwsStateError,
    );
  });

  test('modo real y revisión de Inicio no abren ninguna base', () async {
    // flutter test simula Android: el arranque consulta el applicationId.
    const channel = MethodChannel('vigia/app');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      channel,
      (call) async => realApplicationId,
    );
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    final opened = <String>[];
    QueryExecutor open(String name) {
      opened.add(name);
      return NativeDatabase.memory();
    }

    // Fase 5D: la app normal abre solo su proyección real experimental.
    final real = await bootstrap(const RealMode(), openDatabase: open);
    expect(real, hasLength(1));
    expect(opened, [realHistoryDatabaseName]);
    expect(realHistoryDatabaseName, 'vigia_history_real_v1');
    expect(
      await bootstrap(
        InicioReviewMode(InicioDemoVariant.sinHistorial.state),
        openDatabase: open,
      ),
      isEmpty,
    );
    // El recorrido DEMO en la app normal se rechaza antes de abrir la base.
    await expectLater(
      bootstrap(const DemoMode(), openDatabase: open),
      throwsStateError,
    );
    expect(opened, [realHistoryDatabaseName], reason: 'sin base DEMO');
  });

  test('la app DEMO abre solo su base DEMO, nunca la real', () async {
    const channel = MethodChannel('vigia/app');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      channel,
      (call) async => demoApplicationId,
    );
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    final opened = <String>[];
    final overrides = await bootstrap(
      const DemoMode(),
      openDatabase: (name) {
        opened.add(name);
        return NativeDatabase.memory();
      },
    );
    expect(opened, [demoHistoryDatabaseName]);
    expect(demoHistoryDatabaseName, isNot(realHistoryDatabaseName));
    expect(overrides, isNotEmpty);
    // Y la app normal en el proceso DEMO no arranca.
    await expectLater(bootstrap(const RealMode()), throwsStateError);
  });

  test('el canal vigia/app devuelve el applicationId', () async {
    const channel = MethodChannel('vigia/app');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'applicationId');
          return demoApplicationId;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    expect(
      await channel.invokeMethod<String>('applicationId'),
      demoApplicationId,
    );
  });
}
