import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia/app/vigia_app.dart';
import 'package:vigia/core/design_system/widgets/aura_hero.dart';
import 'package:vigia/core/design_system/widgets/vigia_button.dart';
import 'package:vigia/core/design_system/widgets/vigia_scaffold.dart';
import 'package:vigia/demo/inicio_demo.dart';
import 'package:vigia/features/inicio/inicio_state.dart';

import '../support/contrast.dart';
import '../support/vigia_harness.dart';

/// Matriz de la fase 1: 5 variantes DEMO + estado real × claro/oscuro × 320/360/412 × texto 100/200 %.
///
/// En cada combinación comprueba:
/// - que no hay errores de dibujo (desbordes de Flex) ni texto cortado o con
///   elipsis;
/// - que ningún texto se sale del ancho de pantalla;
/// - que cada acción y cada destino de la barra caben completos y son
///   alcanzables por desplazamiento;
/// - las pautas de Flutter de área táctil (≥ 48) y etiquetado;
/// - el contraste WCAG de cada tramo de texto, medido sobre los píxeles
///   dibujados en todas las posiciones de desplazamiento; el registro de
///   cobertura queda en `build/contrast_coverage/<variante>_<config>.txt`.
void main() {
  setUpAll(loadVigiaFonts);

  const widths = [320.0, 360.0, 412.0];
  const scales = [1.0, 2.0];

  // Las cinco variantes DEMO y el estado real del arranque (motor no comprobado).
  final states = <String, InicioState>{
    for (final v in InicioDemoVariant.values) v.id: v.state,
    'real_motor_no_comprobado': const InicioMotorNoComprobado(),
  };

  for (final MapEntry(key: id, value: state) in states.entries) {
    for (final dark in [false, true]) {
      for (final w in widths) {
        for (final scale in scales) {
          final c = ScreenConfig(width: w, textScale: scale, dark: dark);
          testWidgets('$id · ${c.id}', (tester) async {
            await pumpVigia(tester, state, c);
            expect(tester.takeException(), isNull);

            for (final p in tester.renderObjectList<RenderParagraph>(
              find.byType(RichText),
            )) {
              expect(
                p.didExceedMaxLines,
                isFalse,
                reason: 'texto cortado: ${p.text.toPlainText()}',
              );
              final box = MatrixUtils.transformRect(
                p.getTransformTo(null),
                Offset.zero & p.size,
              );
              expect(
                box.right,
                lessThanOrEqualTo(w + 0.5),
                reason: 'texto fuera de pantalla: ${p.text.toPlainText()}',
              );
            }

            // Cada botón es alcanzable desplazando y queda dentro del ancho.
            for (final b in tester.widgetList<VigiaButton>(
              find.byType(VigiaButton),
            )) {
              final f = find.widgetWithText(VigiaButton, b.label).first;
              await tester.ensureVisible(f);
              await tester.pumpAndSettle();
              final r = tester.getRect(f);
              expect(r.height, greaterThanOrEqualTo(48), reason: b.label);
              expect(r.left, greaterThanOrEqualTo(0));
              expect(r.right, lessThanOrEqualTo(w + 0.5));
            }

            // Barra principal: los tres destinos completos (B5.2 limitaba al 135 %).
            final nav = find.byType(VigiaBottomNav);
            for (final d in ['Inicio', 'Historial', 'Ajustes']) {
              final t = find.descendant(of: nav, matching: find.text(d));
              expect(t, findsOneWidget);
              expect(tester.getRect(t).height, greaterThan(0));
            }

            // Volver al principio: las pautas miden la parte visible de cada nodo,
            // y un botón a medio desplazar en el borde no es un defecto de diseño.
            await tester.drag(
              find.byType(SingleChildScrollView),
              const Offset(0, 4000),
            );
            await tester.pumpAndSettle();
            await expectLater(
              tester,
              meetsGuideline(androidTapTargetGuideline),
            );
            await expectLater(
              tester,
              meetsGuideline(labeledTapTargetGuideline),
            );
            // Contraste por tramo sobre los píxeles dibujados, recorriendo todo el
            // contenido desplazable (ver test/support/contrast.dart). Sustituye a
            // textContrastGuideline, que tomaba el suavizado como color del texto.
            // Ningún texto puede quedar sin evaluar.
            final audit = await auditTextContrast(tester);
            writeCoverageLog('${id}_${c.id}', audit);
            expect(audit.problems, isEmpty, reason: audit.log());
          });
        }
      }
    }
  }

  // El cuerpo del aura y su CTA quedan por debajo del viewport inicial a
  // 320 × 800 y 200 %: deben evaluarse tras desplazar.
  for (final MapEntry(key: id, value: state) in states.entries) {
    testWidgets('$id · 320×800 al 200 %: aura completa evaluada al desplazar', (
      tester,
    ) async {
      await pumpVigia(
        tester,
        state,
        const ScreenConfig(width: 320, textScale: 2.0),
      );
      final aura = find.byType(AuraHero);
      if (aura.evaluate().isEmpty) return; // variante sin aura
      final paragraphs = tester.renderObjectList<RenderParagraph>(
        find.descendant(of: aura, matching: find.byType(RichText)),
      );
      final viewport = tester.getRect(find.byType(SingleChildScrollView));
      final initiallyHidden = paragraphs.where((p) {
        final r = MatrixUtils.transformRect(
          p.getTransformTo(null),
          Offset.zero & p.size,
        );
        return r.bottom > viewport.bottom + 0.5;
      });
      final audit = await auditTextContrast(tester);
      for (final p in paragraphs) {
        expect(
          audit.isFullyEvaluated(p),
          isTrue,
          reason: '«${p.text.toPlainText()}» sin evaluar\n${audit.log()}',
        );
      }
      // Documenta que la cobertura procede del desplazamiento.
      expect(initiallyHidden, isNotEmpty);
    });
  }

  testWidgets('al 200 % en 320 la barra pasa a lista vertical sin recortar', (
    tester,
  ) async {
    await pumpVigia(
      tester,
      InicioDemoVariant.sinHistorial.state,
      const ScreenConfig(width: 320, textScale: 2.0),
    );
    expect(find.byKey(const Key('nav-vertical')), findsOneWidget);
  });

  testWidgets('al 100 % en 360 la barra es la pastilla horizontal de B5.2', (
    tester,
  ) async {
    await pumpVigia(
      tester,
      InicioDemoVariant.sinHistorial.state,
      const ScreenConfig(width: 360),
    );
    expect(find.byKey(const Key('nav-vertical')), findsNothing);
  });

  testWidgets(
    'tarjeta de estado: icono a la izquierda al 100 % y encima si una palabra no cabe',
    (tester) async {
      await pumpVigia(
        tester,
        InicioDemoVariant.registroInterrumpido.state,
        const ScreenConfig(width: 360),
      );
      expect(find.byKey(const Key('status-card-stacked')), findsNothing);
      await pumpVigia(
        tester,
        InicioDemoVariant.registroInterrumpido.state,
        const ScreenConfig(width: 320, textScale: 2.0),
      );
      expect(find.byKey(const Key('status-card-stacked')), findsOneWidget);
    },
  );

  group('movimiento del aura (vgA1/vgA2/vgC)', () {
    testWidgets('con movimiento normal se anima 6 s una vez y se detiene', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures();
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      await pumpVigiaUnsettled(tester);
      expect(find.byType(AuraHero), findsOneWidget);
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pump(const Duration(seconds: 3));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pump(const Duration(seconds: 3, milliseconds: 100));
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('con movimiento reducido no hay animación del aura', (
      tester,
    ) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      await pumpVigiaUnsettled(tester);
      expect(find.byType(AuraHero), findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });
}

/// Monta sin esperar a que terminen las animaciones (para medirlas).
Future<void> pumpVigiaUnsettled(WidgetTester tester) async {
  tester.view.physicalSize = const Size(720, 1600);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    VigiaApp(inicioState: InicioDemoVariant.sinHistorial.state),
  );
  await tester.pump();
}

/// Guarda el registro de cobertura del contraste de una combinación.
void writeCoverageLog(String name, ContrastAudit audit) {
  final file = File('build/contrast_coverage/$name.txt')
    ..createSync(recursive: true);
  file.writeAsStringSync(audit.log());
}
