@Tags(['render'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_engine/monitoring_engine.dart';
import 'package:vigia/app/app_config.dart';
import 'package:vigia/app/vigia_app.dart';
import 'package:vigia/core/design_system/widgets/vigia_button.dart';
import 'package:vigia/features/camera/front_camera_controller.dart';
import 'package:vigia/features/experimental/experimental_monitoring_controller.dart';

import '../support/fake_camera.dart';
import '../support/fake_experimental.dart';
import '../support/vigia_harness.dart';

void main() {
  setUpAll(loadVigiaFonts);

  for (final dark in [false, true]) {
    for (final (width, scale) in [(360.0, 1.0), (320.0, 2.0)]) {
      final id =
          '${dark ? 'oscuro' : 'claro'}_${width.toInt()}_${(scale * 100).toInt()}';
      testWidgets('Inicio y encuadre experimental · $id', (tester) async {
        final camera = FakeFrontCameraBridge(
          permission: CameraPermissionStatus.granted,
        );
        final engine = FakeExperimentalBridge(
          fakeSnapshot(sequence: 2, eyeIssue: 'eyeOutsideFrame'),
        );
        tester.view.devicePixelRatio = 2;
        tester.view.physicalSize = Size(width, 800) * 2;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pumpWidget(
          VigiaApp(
            mode: const RealMode(),
            themeMode: dark ? ThemeMode.dark : ThemeMode.light,
            overrides: [
              frontCameraBridgeProvider.overrideWithValue(camera),
              experimentalBridgeProvider.overrideWithValue(engine),
            ],
          ),
        );
        await tester.pumpAndSettle();
        final entry = find.byKey(const Key('open-experimental'));
        expect(entry.hitTestable(), findsOneWidget);
        expect(camera.calls, isEmpty, reason: 'Inicio no abre la cámara');
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('experimental_entry/inicio__$id.png'),
        );
        await tester.tap(entry);
        await tester.pumpAndSettle();
        camera.emitFace(FaceAnalysisStatus.oneFace);
        await tester.pump();
        await tester.pump();

        final preview = find.byKey(const Key('camera-preview'));
        final calibrate = find.byKey(const Key('calibrate'));
        final eyes = find.byKey(const Key('row-eyes'));
        final previewRect = tester.getRect(preview);
        expect(previewRect.height, greaterThan(120));
        expect(calibrate.hitTestable(), findsOneWidget);
        expect(
          tester.getBottomRight(eyes).dy,
          lessThan(tester.getTopLeft(calibrate).dy),
        );
        expect(tester.widget<VigiaButton>(calibrate).onPressed, isNull);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('experimental_entry/encuadre__$id.png'),
        );

        engine.emit(
          fakeSnapshot(
            sequence: 3,
            eyesValid: true,
            earRight: 0.29,
            earLeft: 0.31,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.widget<VigiaButton>(calibrate).onPressed, isNotNull);
        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -300),
        );
        await tester.pumpAndSettle();
        expect(
          tester.getRect(preview),
          previewRect,
          reason: 'la vista previa queda fija',
        );
        expect(calibrate.hitTestable(), findsOneWidget);
        engine.emit(fakeSnapshot(sequence: 4, eyesValid: true));
        await tester.pump();
        await tester.pump();
        expect(tester.widget<VigiaButton>(calibrate).onPressed, isNotNull);
        engine.next = fakeSnapshot(
          eyesValid: true,
          step: CalibrationStep.openReference,
        );
        await tester.tap(calibrate);
        await tester.pumpAndSettle();
        expect(engine.calls.where((call) => call == 'calibrate'), hasLength(1));
        expect(
          camera.calls.where((call) => call.startsWith('open:')),
          hasLength(1),
        );
        expect(preview, findsOneWidget);
        expect(find.text('Cancelar calibración'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 4));
      });
    }
  }
}
