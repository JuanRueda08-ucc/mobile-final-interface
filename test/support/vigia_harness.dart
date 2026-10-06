import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia/app/vigia_app.dart';
import 'package:vigia/features/inicio/inicio_state.dart';

/// Carga Inter desde los assets del proyecto para que las pruebas y los
/// renderizados usen la tipografía real (sin ella, flutter_test usa Ahem).
Future<void> loadVigiaFonts() async {
  final loader = FontLoader('Inter')
    ..addFont(rootBundle.load('assets/fonts/Inter/Inter-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter/Inter-Medium.ttf'));
  await loader.load();
}

/// Configuración de pantalla para una comprobación.
class ScreenConfig {
  const ScreenConfig({
    required this.width,
    this.height = 800,
    this.textScale = 1.0,
    this.dark = false,
    this.reduceMotion = true,
    this.devicePixelRatio = 2.0,
  });

  final double width;
  final double height;
  final double textScale;
  final bool dark;
  final bool reduceMotion;
  final double devicePixelRatio;

  String get id =>
      '${dark ? 'oscuro' : 'claro'}_${width.toInt()}_${(textScale * 100).toInt()}';
}

/// Monta la app con un estado de Inicio y la configuración indicada.
Future<void> pumpVigia(
  WidgetTester tester,
  InicioState state,
  ScreenConfig c,
) async {
  tester.view.devicePixelRatio = c.devicePixelRatio;
  tester.view.physicalSize = Size(c.width, c.height) * c.devicePixelRatio;
  tester.platformDispatcher.textScaleFactorTestValue = c.textScale;
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: c.reduceMotion);
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  await tester.pumpWidget(
    VigiaApp(
      inicioState: state,
      themeMode: c.dark ? ThemeMode.dark : ThemeMode.light,
    ),
  );
  await tester.pumpAndSettle();
}
