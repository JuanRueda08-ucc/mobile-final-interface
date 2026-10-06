import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia/core/design_system/widgets/vigia_button.dart';
import 'package:vigia/features/calibration/calibration_controller.dart';
import 'package:vigia/features/monitoring/demo_session_controller.dart';
import 'package:vigia/features/preparation/preparation_controller.dart';

import '../support/contrast.dart';
import '../support/demo_harness.dart';
import '../support/vigia_harness.dart';

/// Estados principales del recorrido demostrativo y cómo alcanzarlos.
final Map<String, Future<void> Function(WidgetTester)> demoStates = {
  'P03_sin_historial': (t) async {},
  'P03_sesion_vigente': (t) async {
    await driveToMonitoring(t);
    demoRouter(t).go('/');
    await settle(t);
  },
  'P03_ultimo_resumen': (t) async {
    await driveToMonitoring(t);
    demoContainer(t).read(demoSessionProvider.notifier).requestFinish();
    await t.pump(demoConfirm);
    await settle(t);
    demoRouter(t).go('/');
    await settle(t);
  },
  'P04_inicial': (t) async {
    demoContainer(t).read(preparationProvider.notifier).open();
    await tapLabel(t, 'Preparar sesión');
  },
  'P04_lista': driveToReadyPreparation,
  'P04_referencia_invalidada': (t) async {
    await driveToReadyPreparation(t);
    demoContainer(t).read(preparationProvider.notifier).declareMountChanged();
    await settle(t);
  },
  'P04_bloqueos': (t) async {
    await driveToReadyPreparation(t);
    final prep = demoContainer(t).read(preparationProvider.notifier);
    prep.setSimulated(
      demoContainer(t)
          .read(preparationProvider)
          .sim
          .copyWith(permission: false, eyes: false),
    );
    await settle(t);
  },
  'P05_instruccion': (t) => driveToCalibration(t),
  'P05_adquisicion': (t) => driveToCalibration(t, acquiring: true),
  'P05_rechazo': (t) => driveToCalibration(
    t,
    rejected: CalibrationRejection.insufficientObservations,
  ),
  'P05_aceptada': (t) => driveToCalibration(t, accepted: true),
  'P06_iniciando': (t) async {
    await driveToReadyPreparation(t);
    demoContainer(t).read(demoSessionProvider.notifier).requestStart();
    demoRouter(t).go('/monitoreo');
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
  },
  'P06_activa': (t) async {
    await driveToMonitoring(t);
    await t.pump(const Duration(seconds: 3));
  },
  'P06_advertencia': (t) async {
    await driveToMonitoring(t);
    await t.pump(const Duration(seconds: 8));
  },
  'P06_cierre_ocular': (t) async {
    await driveToMonitoring(t);
    await t.pump(const Duration(seconds: 20));
  },
  'P06_no_evaluable': (t) async {
    await driveToMonitoring(t);
    await t.pump(const Duration(seconds: 30));
  },
  'P06_pausada': (t) async {
    await driveToMonitoring(t);
    demoContainer(t).read(demoSessionProvider.notifier).requestPause();
    await t.pump(demoConfirm);
  },
  'P07_resumen': (t) async {
    await driveToMonitoring(t);
    await t.pump(const Duration(seconds: 12));
    final s = demoContainer(t).read(demoSessionProvider.notifier);
    s.requestPause();
    await t.pump(demoConfirm);
    await t.pump(const Duration(seconds: 5));
    s.requestFinish();
    await t.pump(demoConfirm);
    await settle(t);
  },
  'D01': (t) async {
    await driveToReadyPreparation(t);
    await t.tap(find.byKey(const Key('vigia-back')));
    await settle(t);
  },
  'D02': (t) async {
    await driveToMonitoring(t);
    await tapLabel(t, 'Finalizar');
  },
  'D05': (t) async {
    await driveToMonitoring(t);
    await t.tap(find.byKey(const Key('vigia-back')));
    await settle(t);
  },
};

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
