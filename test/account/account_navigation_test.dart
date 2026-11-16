import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_engine/monitoring_engine.dart';
import 'package:vigia/app/app_config.dart';
import 'package:vigia/app/vigia_app.dart';
import 'package:vigia/core/design_system/widgets/trial_version_notice.dart';
import 'package:vigia/features/account/cloud_sessions.dart';
import 'package:vigia/features/account/firebase_account.dart';
import 'package:vigia/features/experimental/experimental_monitoring_controller.dart';

import '../support/fake_experimental.dart';
import '../support/vigia_harness.dart';
import 'presentation/account_test_harness.dart';

class _VerifiedUser extends Fake implements User {
  @override
  String get uid => 'cuenta-pruebas';

  @override
  String get email => testEmail;

  @override
  bool get emailVerified => true;
}

class _Auth extends Fake implements FirebaseAuth {
  final user = _VerifiedUser();
  int signOutCalls = 0;

  @override
  Stream<User?> userChanges() => Stream.value(user);

  @override
  Future<void> signOut() async {
    signOutCalls++;
  }
}

void main() {
  setUpAll(loadVigiaVisualAssets);

  const railKey = Key('vigia-side-nav');
  final rail = find.byKey(railKey);
  final menu = find.byTooltip('Abrir navegación');
  // Con texto ampliado y la barra fija, el correo puede partirse en líneas;
  // su etiqueta semántica conserva el texto completo.
  Finder whole(String text) => find.byWidgetPredicate(
    (w) => w is Text && (w.data == text || w.semanticsLabel == text),
  );
  final email = whole(testEmail);

  Future<void> openRail(WidgetTester tester) async {
    if (menu.evaluate().isNotEmpty) {
      await tester.tap(menu);
      await tester.pumpAndSettle();
    }
  }

  Future<void> navigate(WidgetTester tester, String destination) async {
    await openRail(tester);
    final item = find.descendant(
      of: rail,
      matching: find.byTooltip(destination),
    );
    expect(tester.getSize(item).width, greaterThanOrEqualTo(48));
    expect(tester.getSize(item).height, greaterThanOrEqualTo(48));
    await tester.tap(item);
    await tester.pumpAndSettle();
  }

  Future<_Auth> mount(
    WidgetTester tester,
    ({double width, double scale, bool dark}) config, {
    FakeExperimentalBridge? engine,
    bool uploadFails = false,
  }) async {
    configureView(tester, config, height: 800);
    final auth = _Auth();
    await tester.pumpWidget(
      VigiaApp(
        mode: const RealMode(),
        themeMode: config.dark ? ThemeMode.dark : ThemeMode.light,
        overrides: [
          firebaseAuthProvider.overrideWithValue(auth),
          experimentalBridgeProvider.overrideWithValue(
            engine ?? FakeExperimentalBridge(),
          ),
          cloudSessionUploadProvider.overrideWith((ref, uid) async {
            expect(uid, auth.user.uid);
            if (uploadFails) throw StateError('Sin red');
          }),
          cloudHistoryProvider.overrideWith((ref, uid) async => []),
        ],
      ),
    );
    await tester.pumpAndSettle();
    return auth;
  }

  testWidgets('cerrada solo se ve ≡; abierta, iconos con nombres', (
    tester,
  ) async {
    await mount(tester, (width: 360.0, scale: 1.0, dark: false));
    // Barra (usuario, 2026-11-16): cerrada no hay barra, solo ≡.
    expect(rail, findsNothing);
    expect(menu, findsOneWidget);
    final body = find.byType(SingleChildScrollView);
    final before = tester.getRect(body);
    final barriers = find.byType(ModalBarrier).evaluate().length;
    await tester.tap(menu);
    await tester.pumpAndSettle();
    expect(rail, findsOneWidget);
    for (final label in ['Inicio', 'Historial', 'Ajustes', 'Cuenta']) {
      expect(
        find.descendant(of: rail, matching: find.text(label)),
        findsOneWidget,
      );
    }
    // Se desliza encima: sin capa oscura y la pantalla no se mueve.
    expect(find.byType(ModalBarrier), findsNWidgets(barriers));
    expect(find.byType(Drawer), findsNothing);
    expect(tester.getRect(body), before);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('navegacion/inicio_etiqueta__claro_360_100.png'),
    );
    await tester.tap(find.byTooltip('Cerrar navegación'));
    await tester.pumpAndSettle();
    expect(rail, findsNothing);
    expect(menu, findsOneWidget);
  });

  testWidgets('tocar abre el destino sin mostrar una etiqueta', (tester) async {
    await mount(tester, (width: 320.0, scale: 2.0, dark: true));
    await openRail(tester);
    await tester.tap(find.byTooltip('Cuenta'));
    await tester.pumpAndSettle();
    // Al elegir un destino la barra se esconde.
    expect(rail, findsNothing);
    expect(email, findsOneWidget);
    expect(find.text('Cuenta'), findsOneWidget);
  });

  for (final dark in [false, true]) {
    for (final (width, scale) in [(360.0, 1.0), (320.0, 2.0)]) {
      final config = (width: width, scale: scale, dark: dark);
      testWidgets('navegación normal · ${configName(config)}', (tester) async {
        await mount(tester, config);
        Future<void> capture(String screen) => expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('navegacion/${screen}__${configName(config)}.png'),
        );

        await capture('inicio');
        await navigate(tester, 'Cuenta');
        expect(email, findsOneWidget);
        expect(whole('Correo verificado'), findsOneWidget);
        expect(whole('Sin envíos pendientes'), findsOneWidget);
        await tester.ensureVisible(button('Cerrar sesión'));
        await tester.pumpAndSettle();
        expect(button('Cerrar sesión').hitTestable(), findsOneWidget);
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, 600),
        );
        await tester.pumpAndSettle();
        await capture('cuenta');
        final trialNotice = find.byType(TrialVersionNotice);
        expect(trialNotice, findsOneWidget);
        await tester.ensureVisible(trialNotice);
        await tester.pumpAndSettle();
        expect(find.text('Versión de prueba').hitTestable(), findsOneWidget);
        await capture('cuenta_version');
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, 1500),
        );
        await tester.pumpAndSettle();

        await openRail(tester);
        final accountItem = find.descendant(
          of: rail,
          matching: find.bySemanticsLabel('Cuenta'),
        );
        final semantics = tester.ensureSemantics();
        try {
          await tester.pump();
          expect(
            tester.getSemantics(accountItem),
            isSemantics(
              label: 'Cuenta',
              isButton: true,
              isSelected: true,
              hasSelectedState: true,
              hasTapAction: true,
            ),
          );
        } finally {
          semantics.dispose();
        }
        {
          await capture('cuenta_panel');
          await tester.tap(find.byTooltip('Cuenta'));
          await tester.pumpAndSettle();
          expect(rail, findsNothing);
          expect(email, findsOneWidget);
        }

        await navigate(tester, 'Historial');
        expect(trialNotice, findsNothing);
        await capture('historial');
        await navigate(tester, 'Ajustes');
        expect(find.text('Tema'), findsOneWidget);
        expect(button('Mi cuenta'), findsNothing);
        expect(button('Sonido'), findsOneWidget);
        expect(
          find.textContaining('No incluido en este prototipo'),
          findsNothing,
        );
        await capture('ajustes');
        expect(trialNotice, findsOneWidget);
        await tester.ensureVisible(trialNotice);
        await tester.pumpAndSettle();
        expect(find.text('Acerca de').hitTestable(), findsOneWidget);
        await capture('ajustes_acerca');
        await navigate(tester, 'Inicio');
        expect(trialNotice, findsNothing);
        expect(find.byKey(const Key('open-experimental')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets(
    'Cuenta muestra el fallo de envío y comprueba el motor al salir',
    (tester) async {
      final engine = FakeExperimentalBridge();
      final auth = await mount(
        tester,
        (width: 360.0, scale: 1.0, dark: false),
        engine: engine,
        uploadFails: true,
      );
      await navigate(tester, 'Cuenta');
      expect(find.text('Envío pendiente'), findsOneWidget);
      expect(button('Reintentar envío'), findsOneWidget);
      final exit = button('Cerrar sesión');
      await tester.ensureVisible(exit);
      engine.current = fakeSnapshot(
        lifecycle: EngineSessionLifecycle.active,
        sessionId: 'session-test',
      );
      await tester.tap(exit);
      await tester.pumpAndSettle();
      expect(auth.signOutCalls, 0);
      expect(
        find.text('Finaliza el monitoreo antes de cerrar sesión.'),
        findsOneWidget,
      );
      engine.current = fakeSnapshot();
      await tester.ensureVisible(exit);
      await tester.tap(exit);
      await tester.pumpAndSettle();
      expect(auth.signOutCalls, 1);
    },
  );
}
