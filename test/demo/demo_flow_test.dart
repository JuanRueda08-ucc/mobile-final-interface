import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia/app/app_config.dart';
import 'package:vigia/app/router.dart';
import 'package:vigia/core/audio/alert_sound.dart';
import 'package:vigia/core/design_system/widgets/vigia_button.dart';
import 'package:vigia/core/design_system/widgets/vigia_scaffold.dart';
import 'package:vigia/demo/inicio_demo.dart';
import 'package:vigia/features/calibration/calibration_controller.dart';
import 'package:vigia/features/calibration/calibration_screen.dart';
import 'package:vigia/features/inicio/inicio_screen.dart';
import 'package:vigia/features/inicio/inicio_state.dart';
import 'package:vigia/features/monitoring/demo_session_controller.dart';
import 'package:vigia/features/monitoring/domain/session_model.dart';
import 'package:vigia/features/monitoring/monitoring_screen.dart';
import 'package:vigia/features/preparation/preparation_controller.dart';
import 'package:vigia/features/preparation/preparation_screen.dart';
import 'package:vigia/features/preparation/preparation_state.dart';
import 'package:vigia/features/summary/summary_screen.dart';

import '../support/demo_harness.dart';
import '../support/vigia_harness.dart';

const _cfg = ScreenConfig(width: 360);

bool _enabled(WidgetTester tester, String label) =>
    tester
        .widget<VigiaButton>(find.widgetWithText(VigiaButton, label).last)
        .onPressed !=
    null;

void _expectDemoLabel() =>
    expect(find.text(DemoLabel.text), findsWidgets, reason: 'rótulo DEMO');

String _sessionValue(WidgetTester tester) =>
    demoContainer(tester).read(demoSessionProvider).sessionId!;

void main() {
  setUpAll(loadVigiaFonts);

  testWidgets('recorrido completo: Inicio → Preparación → Calibración → '
      'Monitoreo → pausa/reanudación → Finalizar → Resumen → Inicio', (
    tester,
  ) async {
    final sound = await pumpDemo(tester, _cfg);
    // P03 demo: sin historial en esta ejecución.
    expect(find.byType(InicioScreen), findsOneWidget);
    _expectDemoLabel();
    expect(find.text('Aún no tienes sesiones'), findsOneWidget);
    await tapLabel(tester, 'Preparar sesión');

    // P04: calibración y sonido pendientes.
    expect(find.byType(PreparationScreen), findsOneWidget);
    _expectDemoLabel();
    expect(find.text('DEMO · sin cámara'), findsOneWidget);
    expect(
      find.text(
        'Iniciar no disponible. Falta: Calibración pendiente · Prueba de '
        'sonido pendiente.',
      ),
      findsOneWidget,
    );
    expect(_enabled(tester, 'Iniciar monitoreo'), isFalse);
    expect(_enabled(tester, 'Lo escuché'), isFalse);
    await tapLabel(tester, 'Calibrar');

    // P05: instrucción, adquisición y aceptación simulada.
    expect(find.text('Ajusta tu mirada'), findsOneWidget);
    _expectDemoLabel();
    await tapLabel(tester, 'Comenzar');
    expect(find.text('Recogiendo referencia'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing); // UX05.CA1
    await tapLabel(tester, 'Aceptar referencia');
    expect(find.text('Calibración completada'), findsOneWidget);
    await tapLabel(tester, 'Usar referencia aceptada');

    // P04: referencia aplicable; prueba de sonido.
    expect(find.text('Referencia aplicable'), findsOneWidget);
    await tapLabel(tester, 'Probar sonido');
    expect(sound.calls, [AlertSoundKind.test]);
    expect(_enabled(tester, 'Lo escuché'), isTrue);
    expect(_enabled(tester, 'Iniciar monitoreo'), isFalse);
    await tapLabel(tester, 'Lo escuché');
    expect(find.text('Sonido confirmado'), findsOneWidget);
    expect(_enabled(tester, 'Iniciar monitoreo'), isTrue);

    // Iniciar: Iniciando sin ID hasta la confirmación (RF08.CA2).
    await tester.ensureVisible(find.text('Iniciar monitoreo'));
    await tester.tap(find.text('Iniciar monitoreo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(MonitoringScreen), findsOneWidget);
    _expectDemoLabel();
    expect(find.text('Iniciando…'), findsOneWidget);
    expect(find.text('Se asigna al confirmar'), findsOneWidget);
    await tester.pump(demoConfirm);
    final id = _sessionValue(tester);
    expect(id, 'S-DEMO-0001');
    expect(find.text(id), findsOneWidget);
    expect(find.text('Preparando la medición'), findsOneWidget);

    // Guion: monitoreo activo y advertencia a los 8 s.
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Monitoreo activo'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Señales persistentes'), findsOneWidget);
    expect(sound.calls.last, AlertSoundKind.warning);
    expect(find.text('Entendido'), findsNothing); // UX08: sin respuesta

    // Pausa: Pausando y después Pausada con el mismo ID.
    await tapLabel(tester, 'Pausar');
    expect(find.text('Pausando…'), findsOneWidget);
    await tester.pump(demoConfirm);
    expect(find.text('Monitoreo pausado'), findsOneWidget);
    expect(find.text('Evaluación suspendida'), findsWidgets);
    expect(find.text('Señales persistentes'), findsNothing); // UX07.CA2
    final pausedTime = tester
        .widget<Text>(
          find
              .descendant(
                of: find.byKey(const Key('monitored-time')),
                matching: find.byType(Text),
              )
              .last,
        )
        .data;
    await tester.pump(const Duration(seconds: 20));
    expect(
      tester
          .widget<Text>(
            find
                .descendant(
                  of: find.byKey(const Key('monitored-time')),
                  matching: find.byType(Text),
                )
                .last,
          )
          .data,
      pausedTime,
    );

    await tapLabel(tester, 'Reanudar');
    expect(find.text('Reanudando'), findsOneWidget);
    await tester.pump(demoConfirm);
    expect(_sessionValue(tester), id);
    expect(find.text('Preparando la medición'), findsOneWidget);

    // D02: cancelar conserva la sesión.
    await tapLabel(tester, 'Finalizar');
    expect(find.byKey(const Key('dialog-D02')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('dialog-D02')),
        matching: find.text(DemoLabel.text),
      ),
      findsOneWidget,
    );
    await tapLabel(tester, 'Continuar sesión');
    expect(find.byKey(const Key('dialog-D02')), findsNothing);
    expect(
      demoContainer(tester).read(demoSessionProvider).lifecycle,
      SessionLifecycle.active,
    );

    // D02: confirmar finaliza una vez y abre Resumen.
    await tapLabel(tester, 'Finalizar');
    await tapLabel(tester, 'Finalizar');
    expect(find.text('Finalizando…'), findsOneWidget);
    expect(_enabled(tester, 'Pausar'), isFalse);
    await tester.pump(demoConfirm);
    await settle(tester);
    expect(find.byType(SummaryScreen), findsOneWidget);
    _expectDemoLabel();
    expect(find.text('Resumen de la sesión'), findsOneWidget);
    expect(find.text(id), findsWidgets);
    // El resumen mostrado es el guardado en el historial.
    final summary = (await demoHistory.session(id))!.summary!;
    expect(find.text(summary.coverageText), findsOneWidget);
    expect(summary.episodes, 1);
    expect(summary.pauses, 1);

    // Volver al inicio: Inicio con el último resumen guardado.
    await tapLabel(tester, 'Volver al inicio');
    expect(find.byType(InicioScreen), findsOneWidget);
    expect(find.text('Último resumen'), findsOneWidget);
    expect(find.text(id), findsOneWidget);
    expect(find.text(summary.coverageText), findsOneWidget);
    _expectDemoLabel();

    // El monitoreo cerrado no se reabre (UX12.CA3).
    demoRouter(tester).go(VigiaRoutes.monitoreo);
    await settle(tester);
    expect(find.byType(MonitoringScreen), findsNothing);
  });

  testWidgets('Ver último resumen abre el resumen de esta ejecución', (
    tester,
  ) async {
    await pumpDemo(tester, _cfg);
    await driveToMonitoring(tester);
    demoContainer(tester).read(demoSessionProvider.notifier).requestFinish();
    await tester.pump(demoConfirm);
    await settle(tester);
    await tapLabel(tester, 'Volver al inicio');
    await tapLabel(tester, 'Ver último resumen');
    expect(find.byType(SummaryScreen), findsOneWidget);
  });

  testWidgets('modo normal: motor no comprobado, preparación bloqueada y '
      'sin rutas del recorrido', (tester) async {
    await pumpDemo(tester, _cfg, mode: const RealMode());
    expect(find.text('Estado del motor no comprobado'), findsOneWidget);
    expect(find.text(DemoLabel.text), findsNothing);
    expect(_enabled(tester, 'Preparar sesión'), isFalse);
    for (final r in [
      VigiaRoutes.preparacion,
      VigiaRoutes.calibracion,
      VigiaRoutes.monitoreo,
      VigiaRoutes.resumen('S-DEMO-0001'),
      VigiaRoutes.historial,
      VigiaRoutes.detalle('S-DEMO-0001'),
      VigiaRoutes.ajustes,
      VigiaRoutes.sonido,
    ]) {
      demoRouter(tester).go(r);
      await settle(tester);
      expect(find.byType(InicioScreen), findsOneWidget, reason: r);
    }
  });

  testWidgets('VIGIA_DEMO_INICIO: la sesión vigente de revisión no es una '
      'sesión iniciada', (tester) async {
    await pumpDemo(
      tester,
      _cfg,
      mode: InicioReviewMode(InicioDemoVariant.sesionVigente.state),
    );
    await tapLabel(tester, 'Volver al monitoreo');
    expect(find.byType(MonitoringScreen), findsNothing);
    expect(
      find.text(InicioScreen.pendingNotices[InicioAction.volverAlMonitoreo]!),
      findsOneWidget,
    );
    demoRouter(tester).go(VigiaRoutes.monitoreo);
    await settle(tester);
    expect(find.byType(InicioScreen), findsOneWidget);
  });

  testWidgets('P04: cada condición simulada falsa bloquea con su causa', (
    tester,
  ) async {
    await pumpDemo(tester, _cfg);
    await driveToReadyPreparation(tester);
    expect(_enabled(tester, 'Iniciar monitoreo'), isTrue);
    for (final (toggle, cause) in [
      ('Permiso de cámara concedido', 'Cámara sin permiso'),
      ('Cámara disponible', 'Cámara no disponible'),
      ('Modelo cargado', 'Modelo no disponible'),
      ('Ojos evaluables', 'Ojos no evaluables'),
      ('Rostro detectado', 'Ojos no evaluables'),
    ]) {
      await tapLabel(tester, toggle);
      expect(
        find.text('Iniciar no disponible. Falta: $cause.'),
        findsOneWidget,
        reason: toggle,
      );
      expect(_enabled(tester, 'Iniciar monitoreo'), isFalse, reason: toggle);
      await tapLabel(tester, toggle);
      expect(_enabled(tester, 'Iniciar monitoreo'), isTrue, reason: toggle);
    }
    // Rostro detectado y ojos no evaluables se muestran por separado (UX03.CA2).
    await tapLabel(tester, 'Ojos evaluables');
    expect(find.text('Rostro detectado'), findsWidgets);
    expect(
      find.text('Rostro detectado, pero no puedo evaluar los ojos.'),
      findsOneWidget,
    );
  });

  testWidgets('P04: No lo escuché conserva el bloqueo; fallo técnico visible', (
    tester,
  ) async {
    final sound = await pumpDemo(tester, _cfg);
    await tapLabel(tester, 'Preparar sesión');
    await tapLabel(tester, 'Probar sonido');
    await tapLabel(tester, 'No lo escuché');
    expect(
      find.textContaining('No lo escuché: el inicio sigue'),
      findsOneWidget,
    );
    expect(_enabled(tester, 'Lo escuché'), isFalse);
    sound.next = const SoundPlayback.failed(
      'El volumen multimedia está en cero.',
    );
    await tapLabel(tester, 'Repetir prueba');
    expect(
      find.text(
        'No se pudo reproducir el sonido. El volumen multimedia está en cero.',
      ),
      findsOneWidget,
    );
    expect(_enabled(tester, 'Lo escuché'), isFalse);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('P05: los tres rechazos muestran causa y Reintentar; Cancelar '
      'vuelve sin referencia', (tester) async {
    await pumpDemo(tester, _cfg);
    await tapLabel(tester, 'Preparar sesión');
    await tapLabel(tester, 'Calibrar');
    await tapLabel(tester, 'Comenzar');
    for (final (option, title) in [
      ('Rechazo: observaciones insuficientes', 'Observaciones insuficientes'),
      ('Rechazo: calidad ocular inválida', 'Calidad ocular inválida'),
      ('Rechazo: referencia inestable', 'Referencia inestable'),
    ]) {
      await tapLabel(tester, option);
      expect(find.text(title), findsOneWidget);
      expect(
        find.textContaining('No se guardó ninguna referencia aceptada.'),
        findsOneWidget,
      );
      expect(find.text('Usar referencia aceptada'), findsNothing);
      await tapLabel(tester, 'Reintentar');
      expect(find.text('Recogiendo referencia'), findsOneWidget);
    }
    await tapLabel(tester, 'Cancelar');
    expect(find.byType(PreparationScreen), findsOneWidget);
    expect(find.text('Calibración pendiente'), findsWidgets);
  });

  testWidgets('Cambié la posición invalida la referencia y exige recalibrar', (
    tester,
  ) async {
    await pumpDemo(tester, _cfg);
    await driveToReadyPreparation(tester);
    expect(_enabled(tester, 'Iniciar monitoreo'), isTrue);
    await tapLabel(tester, 'Cambié la posición');
    expect(find.byKey(const Key('reference-invalidated')), findsOneWidget);
    expect(find.text(PreparationScreen.mountChangedNotice), findsOneWidget);
    expect(_enabled(tester, 'Iniciar monitoreo'), isFalse);
    expect(
      find.text('Iniciar no disponible. Falta: Calibración pendiente.'),
      findsOneWidget,
    );
    // Cancelar la calibración no restaura la referencia invalidada.
    await tapLabel(tester, 'Calibrar');
    await tapLabel(tester, 'Comenzar');
    await tapLabel(tester, 'Cancelar');
    expect(find.byKey(const Key('reference-invalidated')), findsOneWidget);
    await tapLabel(tester, 'Calibrar');
    await tapLabel(tester, 'Comenzar');
    await tapLabel(tester, 'Aceptar referencia');
    await tapLabel(tester, 'Usar referencia aceptada');
    expect(find.byKey(const Key('reference-invalidated')), findsNothing);
    expect(_enabled(tester, 'Iniciar monitoreo'), isTrue);
  });

  testWidgets('D01: salir de la preparación vuelve a Inicio sin sesión', (
    tester,
  ) async {
    await pumpDemo(tester, _cfg);
    await tapLabel(tester, 'Preparar sesión');
    await tester.tap(find.byKey(const Key('vigia-back')));
    await settle(tester);
    expect(find.byKey(const Key('dialog-D01')), findsOneWidget);
    await tapLabel(tester, 'Seguir preparando');
    expect(find.byType(PreparationScreen), findsOneWidget);
    await tester.tap(find.byKey(const Key('vigia-back')));
    await settle(tester);
    await tapLabel(tester, 'Salir');
    expect(find.byType(InicioScreen), findsOneWidget);
    expect(
      demoContainer(tester).read(demoSessionProvider).lifecycle,
      SessionLifecycle.none,
    );
  });

  testWidgets('D05 y Volver al monitoreo conservan el ID sin otro inicio; '
      'las rutas directas respetan la sesión vigente', (tester) async {
    await pumpDemo(tester, _cfg);
    await driveToMonitoring(tester);
    final id = _sessionValue(tester);
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byKey(const Key('vigia-back')));
      await settle(tester);
      expect(find.byKey(const Key('dialog-D05')), findsOneWidget);
      await tapLabel(tester, 'Volver al inicio');
      expect(find.text('Sesión en curso: Activa'), findsOneWidget);
      expect(
        find.text('ID $id. Sigue siendo la misma sesión.'),
        findsOneWidget,
      );
      expect(_enabled(tester, 'Preparar sesión'), isFalse);
      // Ruta directa a Preparación con sesión vigente: vuelve a Inicio.
      demoRouter(tester).go(VigiaRoutes.preparacion);
      await settle(tester);
      expect(find.byType(InicioScreen), findsOneWidget);
      await tapLabel(tester, 'Volver al monitoreo');
      expect(find.byType(MonitoringScreen), findsOneWidget);
      expect(find.text(id), findsOneWidget);
      await tester.pump(const Duration(seconds: 7));
    }
    final events = demoContainer(tester).read(demoSessionProvider).events;
    expect(
      events.where((e) => e.type == SessionEventType.started),
      hasLength(1),
    );
    // Seguir aquí permanece en Monitoreo.
    await tester.tap(find.byKey(const Key('vigia-back')));
    await settle(tester);
    await tapLabel(tester, 'Seguir aquí');
    expect(find.byType(MonitoringScreen), findsOneWidget);
  });

  testWidgets('alerta de cierre ocular visual, con sonido y sin respuesta', (
    tester,
  ) async {
    final sound = await pumpDemo(tester, _cfg);
    await driveToMonitoring(tester);
    await tester.pump(const Duration(seconds: 20));
    expect(find.text('Cierre ocular prolongado'), findsOneWidget);
    expect(find.text('Detente en un lugar seguro'), findsOneWidget);
    expect(find.text('Alerta por cierre prolongado'), findsOneWidget);
    expect(sound.calls.last, AlertSoundKind.closure);
    expect(_enabled(tester, 'Pausar'), isTrue);
    expect(_enabled(tester, 'Finalizar'), isTrue);
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Cierre ocular prolongado'), findsNothing);
    expect(find.text('Monitoreo activo'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    expect(find.text('No puedo evaluar'), findsOneWidget);
    expect(find.text('No evaluable'), findsWidgets);
    expect(find.text('Sin señales persistentes'), findsNothing); // UX07.CA1
  });

  testWidgets('fallo del sonido de alerta: visible, sin cambiar la señal', (
    tester,
  ) async {
    final sound = await pumpDemo(tester, _cfg);
    await driveToMonitoring(tester);
    sound.next = const SoundPlayback.failed(
      'El volumen multimedia está en cero.',
    );
    await tester.pump(const Duration(seconds: 8));
    expect(find.byKey(const Key('sound-failure')), findsOneWidget);
    expect(find.text('Señales persistentes'), findsOneWidget);
  });

  testWidgets('activación semántica de las acciones del recorrido', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpDemo(tester, _cfg);
    await driveToReadyPreparation(tester);
    await tester.ensureVisible(find.text('Iniciar monitoreo'));
    await tester.pump();
    tester.semantics.tap(find.semantics.byLabel('Iniciar monitoreo'));
    await settle(tester);
    await tester.pump(demoConfirm);
    expect(find.byType(MonitoringScreen), findsOneWidget);
    tester.semantics.tap(find.semantics.byLabel('Pausar'));
    await tester.pump();
    await tester.pump(demoConfirm);
    expect(find.text('Monitoreo pausado'), findsOneWidget);
    tester.semantics.tap(find.semantics.byLabel('Reanudar'));
    await tester.pump();
    await tester.pump(demoConfirm);
    tester.semantics.tap(find.semantics.byLabel('Volver'));
    await settle(tester);
    expect(find.byKey(const Key('dialog-D05')), findsOneWidget);
    tester.semantics.tap(find.semantics.byLabel('Seguir aquí'));
    await settle(tester);
    expect(find.byKey(const Key('dialog-D05')), findsNothing);
    handle.dispose();
  });

  testWidgets(
    'el tiempo monitoreado no es región viva (sin anuncio por segundo)',
    (tester) async {
      final handle = tester.ensureSemantics();
      await pumpDemo(tester, _cfg);
      await driveToMonitoring(tester);
      final node = tester.getSemantics(find.byKey(const Key('monitored-time')));
      expect(node.getSemanticsData().flagsCollection.isLiveRegion, isFalse);
      handle.dispose();
    },
  );

  group('movimiento reducido', () {
    testWidgets('los diálogos aparecen sin transición', (tester) async {
      await pumpDemo(tester, _cfg);
      await driveToMonitoring(tester);
      await tester.tap(find.text('Finalizar'));
      await tester.pump(); // un solo fotograma
      expect(find.byKey(const Key('dialog-D02')), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets(
      'el aura del resumen es estática incluso con movimiento normal',
      (tester) async {
        await pumpDemo(
          tester,
          const ScreenConfig(width: 360, reduceMotion: false),
        );
        await tester.pump(const Duration(seconds: 7)); // aura de Inicio termina
        await driveToMonitoring(tester);
        demoContainer(tester)
            .read(demoSessionProvider.notifier)
            .requestFinish();
        await tester.pump(demoConfirm);
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(SummaryScreen), findsOneWidget);
        expect(tester.hasRunningAnimations, isFalse);
      },
    );
  });

  for (final (name, sim) in [
    ('permiso', const SimulatedConditions(permission: false)),
    ('cámara', const SimulatedConditions(camera: false)),
    ('modelo', const SimulatedConditions(model: false)),
  ]) {
    testWidgets('ruta directa a Calibración sin $name vuelve a Preparación', (
      tester,
    ) async {
      await pumpDemo(tester, _cfg);
      await tapLabel(tester, 'Preparar sesión');
      final c = demoContainer(tester);
      c.read(preparationProvider.notifier).setSimulated(sim);
      await settle(tester);
      demoRouter(tester).go(VigiaRoutes.calibracion);
      await settle(tester);
      expect(find.byType(CalibrationScreen), findsNothing);
      expect(find.byType(PreparationScreen), findsOneWidget);
      expect(c.read(preparationProvider).reference, isNull);
    });

    testWidgets('perder $name durante la calibración la detiene sin '
        'referencia', (tester) async {
      await pumpDemo(tester, _cfg);
      await driveToCalibration(tester, acquiring: true);
      final c = demoContainer(tester);
      c.read(preparationProvider.notifier).setSimulated(sim);
      await settle(tester);
      expect(find.byType(CalibrationScreen), findsNothing);
      expect(find.byType(PreparationScreen), findsOneWidget);
      c.read(calibrationProvider.notifier).simulateAccepted();
      expect(c.read(preparationProvider).reference, isNull);
    });
  }

  testWidgets('título «Calibración» a 320/200 % no deja una letra sola', (
    tester,
  ) async {
    await pumpDemo(tester, const ScreenConfig(width: 320, textScale: 2));
    await driveToCalibration(tester);
    final title = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .firstWhere((d) => d.replaceAll(RegExp(r'[-\n]'), '') == 'Calibración');
    for (final line in title.split('\n')) {
      expect(line.replaceAll('-', '').length, greaterThan(1), reason: title);
    }
  });
}
