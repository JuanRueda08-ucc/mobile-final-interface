import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia/core/design_system/widgets/vigia_button.dart';

import '../support/contrast.dart';
import '../support/demo_states.dart';
import '../support/demo_harness.dart';
import '../support/vigia_harness.dart';

/// Matriz de la fase 2: estados × claro/oscuro × (360 al 100 %, 320 y 412 al
/// 200 %). Mismas comprobaciones que la matriz de Inicio.
void main() {
  setUpAll(loadVigiaFonts);

  const sizes = [(360.0, 1.0), (320.0, 2.0), (412.0, 2.0)];

  for (final MapEntry(key: id, value: reach) in demoStates.entries) {
    for (final dark in [false, true]) {
      for (final (w, scale) in sizes) {
        final c = ScreenConfig(width: w, textScale: scale, dark: dark);
        testWidgets('$id · ${c.id}', (tester) async {
          await pumpDemo(tester, c);
          await reach(tester);
          expect(tester.takeException(), isNull);

          final dialog = find.byKey(Key('dialog-$id'));
          final isDialog = id.startsWith('D');
          if (isDialog) expect(dialog, findsOneWidget);
          final scope = isDialog ? dialog : find.byType(Scaffold).last;

          for (final p in tester.renderObjectList<RenderParagraph>(
            find.descendant(of: scope, matching: find.byType(RichText)),
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

          for (final b in tester.widgetList<VigiaButton>(
            find.descendant(of: scope, matching: find.byType(VigiaButton)),
          )) {
            // Por instancia: el texto mostrado puede llevar guiones.
            final f = find.byWidget(b);
            await tester.ensureVisible(f);
            await tester.pump();
            final r = tester.getRect(f);
            expect(r.height, greaterThanOrEqualTo(48), reason: b.label);
            expect(r.left, greaterThanOrEqualTo(0), reason: b.label);
            expect(r.right, lessThanOrEqualTo(w + 0.5), reason: b.label);
          }

          // Volver al principio antes de las pautas (miden lo visible), sin
          // arrastrar: el estiramiento de Android escalaría el contenido.
          for (final st in tester.stateList<ScrollableState>(
            find.descendant(of: scope, matching: find.byType(Scrollable)),
          )) {
            st.position.jumpTo(st.position.minScrollExtent);
          }
          await tester.pump();
          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

          final audit = await auditTextContrast(tester);
          final log = File('build/contrast_coverage/fase2_${id}_${c.id}.txt')
            ..createSync(recursive: true);
          log.writeAsStringSync(audit.log());
          // Con un diálogo, el contenido bajo el velo no está activo: se
          // exige el contraste de los párrafos del diálogo.
          final problems = isDialog
              ? audit.problemsOf(
                  tester.renderObjectList<RenderParagraph>(
                    find.descendant(
                      of: dialog,
                      matching: find.byType(RichText),
                    ),
                  ),
                )
              : audit.problems;
          expect(problems, isEmpty, reason: audit.log());
        });
      }
    }
  }
}
