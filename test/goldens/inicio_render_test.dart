@Tags(['render'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia/demo/inicio_demo.dart';
import 'package:vigia/features/inicio/inicio_state.dart';

import '../support/vigia_harness.dart';

/// Renderizados de referencia de P03 (fase 1), generados por el motor de dibujo
/// de Flutter en el entorno de pruebas (`flutter test`), no en un teléfono:
///
///   flutter test --update-goldens test/goldens   # regenera los PNG
///   flutter test test/goldens                    # compara con los guardados
///
/// - 360×800 lógicos, texto 100 %, claro y oscuro;
/// - 320 lógicos, texto 200 %, sobre 2400 de alto para mostrar todo el
///   contenido sin recortes.
///
/// Escala ×2 (720×1600 px; 640×4800 px los de 200 %). Fuente Inter cargada desde los assets.
/// Movimiento reducido: el aura se dibuja en su posición inicial, que es
/// también la final de su animación.
void main() {
  setUpAll(loadVigiaFonts);

  final configs = [
    const ScreenConfig(width: 360),
    const ScreenConfig(width: 360, dark: true),
    const ScreenConfig(width: 320, height: 2400, textScale: 2.0),
    const ScreenConfig(width: 320, height: 2400, textScale: 2.0, dark: true),
  ];

  // Cinco variantes DEMO y el estado real del arranque (motor no comprobado).
  final states = <String, InicioState>{
    for (final v in InicioDemoVariant.values) v.id: v.state,
    'real_motor_no_comprobado': const InicioMotorNoComprobado(),
  };

  for (final MapEntry(key: id, value: state) in states.entries) {
    for (final c in configs) {
      final name = 'P03_${id}__${c.id}';
      testWidgets(name, (tester) async {
        await pumpVigia(tester, state, c);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('inicio/$name.png'),
        );
      });
    }
  }
}
