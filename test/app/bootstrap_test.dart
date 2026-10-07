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
    expect(await bootstrap(const RealMode()), isEmpty);
    expect(
      await bootstrap(InicioReviewMode(InicioDemoVariant.sinHistorial.state)),
      isEmpty,
    );
    // El recorrido DEMO en la app normal se rechaza antes de abrir la base.
    await expectLater(bootstrap(const DemoMode()), throwsStateError);
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
