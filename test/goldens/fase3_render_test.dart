@Tags(['render'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/demo_harness.dart';
import '../support/demo_states.dart';
import '../support/vigia_harness.dart';

/// Renderizados de referencia de la fase 3 (historial guardado, detalle,
/// Ajustes y Sonido), generados por el motor de dibujo de Flutter en
/// `flutter test`, no en un teléfono:
///
///   flutter test --update-goldens test/goldens/fase3_render_test.dart
///   flutter test test/goldens/fase3_render_test.dart
///
/// 360×800 lógicos al 100 % (claro y oscuro) y 320 lógicos al 200 % sobre
/// 2400 de alto para mostrar el contenido completo. Escala ×2. Movimiento
/// reducido. Las sesiones guardadas salen del recorrido real sobre una base
/// SQLite en memoria; el tiempo lo controla la prueba.
void main() {
  setUpAll(loadVigiaFonts);

  const main = [
    'P03_registro_interrumpido',
    'P03_ultimo_resumen',
    'P08_vacio',
    'P08_lista',
    'P09_finalizada',
    'P09_interrumpida',
    'P09_bloqueado',
    'P12_ajustes',
    'P12_sesion_vigente',
    'P13_prueba',
    'P13_guardado',
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
          matchesGoldenFile('fase3/${id}__${c.id}.png'),
        );
      });
    }
  }
}
