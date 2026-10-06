import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia/features/calibration/calibration_controller.dart';
import 'package:vigia/features/monitoring/demo_session_controller.dart';
import 'package:vigia/features/preparation/preparation_controller.dart';

import 'demo_harness.dart';

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
