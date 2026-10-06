import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_engine/monitoring_engine.dart';
import 'package:vigia/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('monitoring_engine');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('identifica la base técnica y su alcance, sin contador', (
    tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => 'Android de prueba');

    await tester.pumpWidget(VigiaApp(engine: MonitoringEngine()));
    await tester.pumpAndSettle();

    expect(find.text('Vigía'), findsOneWidget);
    expect(find.text('Base técnica'), findsOneWidget);
    expect(find.textContaining('no usa la cámara'), findsOneWidget);
    expect(find.text('Registrado (Android de prueba)'), findsOneWidget);
    expect(find.text('0'), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('sin plugin registrado lo indica en vez de simular éxito', (
    tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (call) async => throw MissingPluginException(),
        );

    await tester.pumpWidget(VigiaApp(engine: MonitoringEngine()));
    await tester.pumpAndSettle();

    expect(find.text('No registrado'), findsOneWidget);
  });

  testWidgets('un error del plugin se muestra con su código', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          channel,
          (call) async => throw PlatformException(code: 'fallo'),
        );

    await tester.pumpWidget(VigiaApp(engine: MonitoringEngine()));
    await tester.pumpAndSettle();

    expect(find.text('Error del plugin: fallo'), findsOneWidget);
  });
}
