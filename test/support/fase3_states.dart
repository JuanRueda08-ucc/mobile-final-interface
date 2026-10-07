import 'package:flutter_test/flutter_test.dart';
import 'package:vigia/app/router.dart';

import 'demo_harness.dart';

Future<void> _go(WidgetTester t, String route) async {
  demoRouter(t).go(route);
  await settle(t);
}

/// Estados de la fase 3: historial guardado, detalle, Ajustes y Sonido. Las
/// sesiones se crean con el recorrido real (controlador y repositorio), no con
/// filas escritas a mano; las interrumpidas, cerrando la app a mitad.
final Map<String, Future<void> Function(WidgetTester)> fase3States = {
  'P03_registro_interrumpido': (t) async {
    await interruptDemoSession(t);
  },
  'P08_vacio': (t) => _go(t, VigiaRoutes.historial),
  'P08_lista': (t) async {
    await interruptDemoSession(t);
    await finishDemoSession(t);
    await _go(t, VigiaRoutes.historial);
  },
  'P09_finalizada': (t) async {
    final id = await finishDemoSession(t);
    await _go(t, VigiaRoutes.detalle(id));
  },
  'P09_interrumpida': (t) async {
    final id = await interruptDemoSession(t);
    await _go(t, VigiaRoutes.detalle(id));
  },
  'P09_bloqueado': (t) async {
    final id = await finishDemoSession(t);
    await driveToMonitoring(t);
    await _go(t, VigiaRoutes.detalle(id));
  },
  'P12_ajustes': (t) => _go(t, VigiaRoutes.ajustes),
  'P12_sesion_vigente': (t) async {
    await driveToMonitoring(t);
    await _go(t, VigiaRoutes.ajustes);
  },
  'P13_prueba': (t) async {
    await _go(t, VigiaRoutes.sonido);
    await tapLabel(t, 'Patrón 2');
    await tapLabel(t, 'Probar sonido');
  },
  'P13_guardado': (t) async {
    await _go(t, VigiaRoutes.sonido);
    await tapLabel(t, 'Patrón 2');
    await tapLabel(t, 'Guardar');
  },
};
