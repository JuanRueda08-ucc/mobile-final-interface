@Tags(['render'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/demo_harness.dart';
import '../support/demo_states.dart';
import '../support/vigia_harness.dart';

/// Renderizados de referencia del recorrido demostrativo (fase 2), generados
/// por el motor de dibujo de Flutter en `flutter test`, no en un teléfono:
///
///   flutter test --update-goldens test/goldens/fase2_render_test.dart
///   flutter test test/goldens/fase2_render_test.dart
///
/// 360×800 lógicos al 100 % (claro y oscuro) y 320 lógicos al 200 % sobre
/// 2400 de alto para mostrar el contenido completo. Escala ×2. Movimiento
/// reducido. Tiempo de la sesión controlado por la prueba: los relojes y
/// señales de P06 son reproducibles.
void main() {
  setUpAll(loadVigiaFonts);

  const main = [
    'P03_sesion_vigente',
    'P03_ultimo_resumen',
    'P04_inicial',
    'P04_lista',
    'P04_referencia_invalidada',
    'P05_adquisicion',
    'P05_rechazo',
    'P05_aceptada',
    'P06_iniciando',
    'P06_activa',
    'P06_advertencia',
    'P06_cierre_ocular',
    'P06_no_evaluable',
    'P06_pausada',
    'P07_resumen',
    'D01',
    'D02',
    'D05',
  ];
  final configs = [
    const ScreenConfig(width: 360),
    const ScreenConfig(width: 360, dark: true),
    const ScreenConfig(width: 320, height: 2400, textScale: 2.0),
    const ScreenConfig(width: 320, height: 2400, textScale: 2.0, dark: true),
  ];

  for (final id in main) {
    for (final c in configs) {
      testWidgets('$id · ${c.id}', (tester) async {
        await pumpDemo(tester, c);
        await demoStates[id]!(tester);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('fase2/${id}__${c.id}.png'),
        );
      });
    }
  }
}
