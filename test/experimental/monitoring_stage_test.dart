import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_engine/monitoring_engine.dart';
import 'package:vigia/core/design_system/vigia_icons.dart';
import 'package:vigia/features/camera/front_camera_controller.dart';
import 'package:vigia/features/experimental/monitoring_stage.dart';

import '../support/fake_camera.dart';

void main() {
  // Rediseño de P06 (2026-11-15): los recuadros llegan normalizados al
  // cuadro analizado sin girar y se dibujan como la vista previa: giro
  // horario por cuartos (RotatedBox) y después espejo horizontal.
  const r = Rect.fromLTRB(0.1, 0.2, 0.3, 0.6);

  test('sin giro ni espejo, el recuadro no cambia', () {
    expect(displayBox(r, quarterTurns: 0, mirrored: false), r);
  });

  test('el espejo refleja en horizontal', () {
    final m = displayBox(r, quarterTurns: 0, mirrored: true);
    expect(m.left, closeTo(0.7, 1e-9));
    expect(m.right, closeTo(0.9, 1e-9));
    expect(m.top, r.top);
    expect(m.bottom, r.bottom);
  });

  test('giro horario de 90°: la esquina superior izquierda pasa a la '
      'superior derecha', () {
    final g = displayBox(
      const Rect.fromLTRB(0, 0, 0.1, 0.1),
      quarterTurns: 1,
      mirrored: false,
    );
    expect(g.right, closeTo(1, 1e-9));
    expect(g.top, closeTo(0, 1e-9));
  });

  test('cuatro giros de 90° vuelven al original; 270° deshace 90°', () {
    var g = r;
    for (var i = 0; i < 4; i++) {
      g = displayBox(g, quarterTurns: 1, mirrored: false);
    }
    expect(g.left, closeTo(r.left, 1e-9));
    expect(g.bottom, closeTo(r.bottom, 1e-9));
    final back = displayBox(
      displayBox(r, quarterTurns: 1, mirrored: false),
      quarterTurns: 3,
      mirrored: false,
    );
    expect(back.left, closeTo(r.left, 1e-9));
    expect(back.top, closeTo(r.top, 1e-9));
    expect(back.right, closeTo(r.right, 1e-9));
    expect(back.bottom, closeTo(r.bottom, 1e-9));
  });

  test('180° equivale a dos giros de 90°', () {
    final a = displayBox(r, quarterTurns: 2, mirrored: false);
    final b = displayBox(
      displayBox(r, quarterTurns: 1, mirrored: false),
      quarterTurns: 1,
      mirrored: false,
    );
    expect(a.left, closeTo(b.left, 1e-9));
    expect(a.top, closeTo(b.top, 1e-9));
  });

  group('MonitoringStage', () {
    final preview = PreviewOpenResult(
      token: 1,
      status: PreviewOpenStatus.opened,
      textureId: 7,
      width: 480,
      height: 640,
      rotationDegrees: 0,
      mirrored: true,
    );

    FrontCameraState cam(FaceAnalysisStatus status) => FrontCameraState(
      phase: CameraCheckPhase.available,
      preview: preview,
      face: FakeFrontCameraBridge.face(1, status),
    );

    Future<void> pump(
      WidgetTester tester,
      FrontCameraState c, {
      bool alert = false,
    }) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MonitoringStage(
            cam: c,
            height: 320,
            alert: alert,
            chips: const [
              StageChip(VigiaIcon.camera, 'Cámara', StageChipTone.ok),
              StageChip(VigiaIcon.eye, 'Ojos', StageChipTone.off),
            ],
            readouts: const ['EAR der. 0,30 · izq. 0,31'],
          ),
        ),
      ),
    );

    testWidgets('con un rostro dibuja los recuadros; sin rostro, no', (
      tester,
    ) async {
      await pump(tester, cam(FaceAnalysisStatus.oneFace));
      expect(find.byKey(const Key('camera-preview')), findsOneWidget);
      expect(find.byKey(const Key('face-boxes')), findsOneWidget);
      expect(stageFaceBoxes(cam(FaceAnalysisStatus.oneFace)), hasLength(3));
      await pump(tester, cam(FaceAnalysisStatus.noFace));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('face-boxes')), findsNothing);
      expect(stageFaceBoxes(cam(FaceAnalysisStatus.noFace)), isNull);
      expect(find.text('EAR der. 0,30 · izq. 0,31'), findsOneWidget);
    });

    test('un resultado caducado no da recuadros', () {
      final stale = FrontCameraState(
        phase: CameraCheckPhase.available,
        preview: preview,
        face: FakeFrontCameraBridge.face(1, FaceAnalysisStatus.oneFace),
        faceStale: true,
      );
      expect(stageFaceBoxes(stale), isNull);
    });

    testWidgets('el aviso se ve sobre la cámara; sin vista previa, el panel '
        'dice el estado', (tester) async {
      await pump(tester, cam(FaceAnalysisStatus.oneFace), alert: true);
      expect(find.byKey(const Key('stage-alert')), findsOneWidget);
      await pump(
        tester,
        const FrontCameraState(phase: CameraCheckPhase.opening),
      );
      expect(find.byKey(const Key('camera-preview')), findsNothing);
      expect(find.text('Abriendo la cámara frontal…'), findsOneWidget);
    });
  });
}
