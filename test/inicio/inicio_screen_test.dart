import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia/app/inicio_source.dart';
import 'package:vigia/core/design_system/widgets/vigia_button.dart';
import 'package:vigia/core/design_system/widgets/vigia_scaffold.dart';
import 'package:vigia/demo/inicio_demo.dart';
import 'package:vigia/features/inicio/inicio_screen.dart';
import 'package:vigia/features/inicio/inicio_state.dart';

import '../support/vigia_harness.dart';

const _cfg = ScreenConfig(width: 360);

Finder _button(String label) => find.widgetWithText(VigiaButton, label);

bool _enabled(WidgetTester t, String label) =>
    t.widget<VigiaButton>(_button(label)).onPressed != null;

Future<void> _tapAndExpectNotice(
  WidgetTester tester,
  Finder target,
  String notice,
) async {
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pump();
  expect(find.text(notice), findsOneWidget);
  // El aviso desaparece solo (4 s) y no navega a ninguna pantalla simulada.
  await tester.pump(const Duration(seconds: 5));
  expect(find.text(notice), findsNothing);
  expect(find.byType(InicioScreen), findsOneWidget);
}

void main() {
  setUpAll(loadVigiaFonts);

  group('rótulo DEMO (RF32)', () {
    testWidgets('todas las variantes DEMO lo muestran', (tester) async {
      for (final v in InicioDemoVariant.values) {
        await pumpVigia(tester, v.state, _cfg);
        expect(find.text(DemoLabel.text), findsOneWidget, reason: v.id);
      }
    });
  });

  group('arranque real sin VIGIA_DEMO_INICIO (P2)', () {
    testWidgets(
      'muestra «motor no comprobado», sin DEMO y con Preparar bloqueado',
      (tester) async {
        final handle = tester.ensureSemantics();
        await pumpVigia(tester, resolveInicioState(), _cfg);

        expect(find.text('Estado del motor no comprobado'), findsOneWidget);
        expect(find.text(DemoLabel.text), findsNothing);
        // No se presenta «sin historial» como si el motor estuviera disponible.
        expect(find.text('Aún no tienes sesiones'), findsNothing);
        expect(find.text('Prepara tu sesión'), findsNothing);
        expect(_enabled(tester, 'Preparar sesión'), isFalse);

        // Ni el toque ni la acción semántica activan la preparación.
        final prep = _button('Preparar sesión');
        expect(
          tester.getSemantics(prep),
          isSemantics(isButton: true, isEnabled: false, hasEnabledState: true),
        );
        expect(
          tester
              .getSemantics(prep)
              .getSemanticsData()
              .hasAction(SemanticsAction.tap),
          isFalse,
        );
        await tester.tap(prep, warnIfMissed: false);
        await tester.pump();
        expect(find.byKey(const Key('vigia-notice')), findsNothing);
        handle.dispose();
      },
    );
  });

  testWidgets('sin historial: aura, Preparar sesión y tarjeta de historial', (
    tester,
  ) async {
    await pumpVigia(tester, InicioDemoVariant.sinHistorial.state, _cfg);
    expect(find.text('Prepara tu sesión'), findsOneWidget);
    expect(find.text(InicioScreen.heroText), findsOneWidget);
    expect(
      find.text('Historial'),
      findsNWidgets(2),
    ); // etiqueta de tarjeta y barra
    expect(find.text('Aún no tienes sesiones'), findsOneWidget);
    await _tapAndExpectNotice(
      tester,
      _button('Preparar sesión'),
      InicioScreen.pendingNotices[InicioAction.prepararSesion]!,
    );
  });

  testWidgets(
    'último resumen (DS01): 83,3 %, 2 episodios y acceso al resumen',
    (tester) async {
      await pumpVigia(tester, InicioDemoVariant.ultimoResumen.state, _cfg);
      expect(find.text('Último resumen'), findsOneWidget);
      expect(find.text('Completo'), findsOneWidget);
      expect(find.text('S-DEMO-0427'), findsOneWidget);
      expect(find.text('83,3 %'), findsOneWidget);
      expect(find.text('Cobertura'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Episodios'), findsOneWidget);
      await _tapAndExpectNotice(
        tester,
        _button('Ver último resumen'),
        InicioScreen.pendingNotices[InicioAction.verUltimoResumen]!,
      );
    },
  );

  testWidgets(
    'sesión vigente: mismo ID, volver al monitoreo y otro inicio bloqueado',
    (tester) async {
      await pumpVigia(tester, InicioDemoVariant.sesionVigente.state, _cfg);
      expect(find.text('Sesión vigente'), findsOneWidget);
      expect(find.text('Sesión en curso: Activa'), findsOneWidget);
      expect(
        find.text('ID S-DEMO-0427. Sigue siendo la misma sesión.'),
        findsOneWidget,
      );
      expect(_enabled(tester, 'Preparar sesión'), isFalse);
      expect(
        find.textContaining('No disponible: hay una sesión vigente'),
        findsOneWidget,
      );
      expect(
        tester.getSemantics(_button('Preparar sesión')),
        isSemantics(isButton: true, isEnabled: false, hasEnabledState: true),
      );
      await _tapAndExpectNotice(
        tester,
        _button('Volver al monitoreo'),
        InicioScreen.pendingNotices[InicioAction.volverAlMonitoreo]!,
      );
    },
  );

  testWidgets('registro interrumpido (DS02): final desconocido, sin duración', (
    tester,
  ) async {
    await pumpVigia(tester, InicioDemoVariant.registroInterrumpido.state, _cfg);
    expect(find.text('DS02 · simulado'), findsOneWidget);
    expect(find.text('Sesión interrumpida'), findsOneWidget);
    expect(
      find.text('No hay cierre confirmado. No se reinició la cámara.'),
      findsOneWidget,
    );
    expect(find.text('08:12'), findsOneWidget);
    expect(find.text('08:41'), findsOneWidget);
    expect(find.text('Desconocido'), findsOneWidget);
    expect(find.text('No disponible'), findsOneWidget);
    expect(_enabled(tester, 'Preparar sesión'), isTrue);
    await _tapAndExpectNotice(
      tester,
      _button('Revisar registro'),
      InicioScreen.pendingNotices[InicioAction.revisarRegistro]!,
    );
  });

  testWidgets('motor desconocido: consulta de estado e inicio bloqueado', (
    tester,
  ) async {
    await pumpVigia(tester, InicioDemoVariant.motorDesconocido.state, _cfg);
    expect(find.text('Estado del monitoreo no disponible'), findsOneWidget);
    expect(_enabled(tester, 'Preparar sesión'), isFalse);
    expect(
      find.text('No disponible hasta conocer el estado del motor.'),
      findsOneWidget,
    );
    await _tapAndExpectNotice(
      tester,
      _button('Consultar estado'),
      InicioScreen.pendingNotices[InicioAction.consultarEstado]!,
    );
  });

  testWidgets(
    'Historial y Ajustes muestran disponibilidad pendiente (fase 3)',
    (tester) async {
      await pumpVigia(tester, InicioDemoVariant.sinHistorial.state, _cfg);
      final nav = find.byType(VigiaBottomNav);
      await _tapAndExpectNotice(
        tester,
        find.descendant(of: nav, matching: find.text('Historial')),
        InicioScreen.historialNotice,
      );
      await _tapAndExpectNotice(
        tester,
        find.descendant(of: nav, matching: find.text('Ajustes')),
        InicioScreen.ajustesNotice,
      );
      expect(
        tester.getSemantics(
          find.descendant(of: nav, matching: find.text('Inicio')),
        ),
        isSemantics(isButton: true, isSelected: true, hasSelectedState: true),
      );
    },
  );

  testWidgets('Historial y Ajustes se activan con SemanticsAction.tap (P1)', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpVigia(tester, InicioDemoVariant.sinHistorial.state, _cfg);
    final nav = find.byType(VigiaBottomNav);
    for (final (label, notice) in [
      ('Historial', InicioScreen.historialNotice),
      ('Ajustes', InicioScreen.ajustesNotice),
    ]) {
      final node = tester.getSemantics(
        find.descendant(of: nav, matching: find.text(label)),
      );
      final data = node.getSemanticsData();
      expect(data.label, label);
      expect(data.hasAction(SemanticsAction.tap), isTrue, reason: label);
      // Un solo nodo con esa etiqueta dentro de la barra: sin anuncio duplicado.
      expect(
        find
            .descendant(of: nav, matching: find.bySemanticsLabel(label))
            .evaluate()
            .length,
        1,
        reason: label,
      );
      tester.binding.performSemanticsAction(
        SemanticsActionEvent(
          type: SemanticsAction.tap,
          nodeId: node.id,
          viewId: tester.view.viewId,
        ),
      );
      await tester.pump();
      expect(find.text(notice), findsOneWidget, reason: label);
      await tester.pump(const Duration(seconds: 5));
      expect(find.text(notice), findsNothing);
    }
    handle.dispose();
  });

  testWidgets(
    'ninguna variante usa términos prohibidos ni contador de ejemplo',
    (tester) async {
      for (final v in InicioDemoVariant.values) {
        await pumpVigia(tester, v.state, _cfg);
        final texts = tester
            .widgetList<Text>(find.byType(Text))
            .map((t) => t.data ?? '')
            .join(' | ');
        for (final banned in ['Seguro', 'Puedes conducir', 'fatiga']) {
          expect(texts.contains(banned), isFalse, reason: '${v.id}: $banned');
        }
        expect(find.byType(FloatingActionButton), findsNothing);
      }
    },
  );
}
