import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_engine/monitoring_engine.dart';
import 'package:vigia/app/app_config.dart';
import 'package:vigia/app/vigia_app.dart';
import 'package:vigia/features/account/cloud_sessions.dart';
import 'package:vigia/features/account/firebase_account.dart';
import 'package:vigia/features/experimental/experimental_monitoring_controller.dart';

import '../support/fake_experimental.dart';
import '../support/vigia_harness.dart';
import 'presentation/account_test_harness.dart';

/// Cambiar correo, cambiar contraseña y eliminar la cuenta (usuario,
/// 2026-11-17). Dobles de Firebase: se comprueba el orden y los datos de
/// cada operación, no el servicio alojado.
class _User extends Fake implements User {
  final calls = <String>[];
  String? failReauth;
  bool deleted = false;

  @override
  String get uid => 'cuenta-pruebas';

  @override
  String get email => testEmail;

  @override
  bool get emailVerified => true;

  @override
  Future<UserCredential> reauthenticateWithCredential(
    AuthCredential credential,
  ) async {
    calls.add('reauth');
    if (failReauth case final code?) {
      throw FirebaseAuthException(code: code);
    }
    return _Credential();
  }

  @override
  Future<void> verifyBeforeUpdateEmail(
    String newEmail, [
    ActionCodeSettings? actionCodeSettings,
  ]) async {
    calls.add('email:$newEmail');
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    calls.add('password:$newPassword');
  }

  @override
  Future<void> delete() async {
    calls.add('delete');
    deleted = true;
  }
}

class _Credential extends Fake implements UserCredential {}

class _Auth extends Fake implements FirebaseAuth {
  final user = _User();

  @override
  User? get currentUser => user;

  @override
  Stream<User?> userChanges() => Stream.value(user);
}

void main() {
  setUpAll(loadVigiaVisualAssets);

  Finder key(String value) => find.byKey(ValueKey(value));

  Future<(_Auth, List<String>, FakeExperimentalBridge)> mount(
    WidgetTester tester, {
    bool eraseFails = false,
    ({double width, double scale, bool dark}) config = (
      width: 360.0,
      scale: 1.0,
      dark: false,
    ),
  }) async {
    configureView(tester, config, height: 800);
    final auth = _Auth();
    final erased = <String>[];
    final engine = FakeExperimentalBridge();
    await tester.pumpWidget(
      VigiaApp(
        mode: const RealMode(),
        themeMode: config.dark ? ThemeMode.dark : ThemeMode.light,
        overrides: [
          firebaseAuthProvider.overrideWithValue(auth),
          experimentalBridgeProvider.overrideWithValue(engine),
          cloudSessionUploadProvider.overrideWith((ref, uid) async {}),
          cloudHistoryProvider.overrideWith((ref, uid) async => []),
          cloudSessionsEraserProvider.overrideWithValue((uid) async {
            auth.user.calls.add('erase');
            if (eraseFails) throw StateError('Sin red');
            erased.add(uid);
          }),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Abrir navegación'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('vigia-side-nav')),
        matching: find.byTooltip('Cuenta'),
      ),
    );
    await tester.pumpAndSettle();
    return (auth, erased, engine);
  }

  Future<void> open(WidgetTester tester, String id) async {
    await tester.ensureVisible(key(id));
    await tester.pumpAndSettle();
    await tester.tap(key(id));
    await tester.pumpAndSettle();
  }

  Future<void> fill(WidgetTester tester, String field, String text) async {
    final (hint, label) = switch (field) {
      'email' => ('nuevo@correo.com', 'Correo nuevo'),
      'current' => ('Tu contraseña actual', 'Contraseña actual'),
      _ => ('Crea una contraseña', 'Contraseña nueva'),
    };
    // Con texto ampliado la etiqueta va dentro del campo y no hay ejemplo.
    final input = find.byWidgetPredicate(
      (w) =>
          w is TextField &&
          (w.decoration?.hintText == hint || w.decoration?.labelText == label),
    );
    await tester.ensureVisible(input);
    await tester.enterText(input, text);
    await tester.pump();
  }

  Future<void> submit(WidgetTester tester) async {
    final button = key('account-action-submit');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('Cuenta ofrece las tres acciones de seguridad', (tester) async {
    await mount(tester);
    expect(find.text('Cambiar correo'), findsOneWidget);
    expect(find.text('Cambiar contraseña'), findsOneWidget);
    expect(find.text('Eliminar cuenta'), findsOneWidget);
    expect(find.text('Solo se guardan resúmenes'), findsOneWidget);
  });

  testWidgets('cambiar correo confirma la contraseña y envía el enlace', (
    tester,
  ) async {
    final (auth, _, _) = await mount(tester);
    await open(tester, 'account-change-email');
    await submit(tester);
    expect(find.text('Escribe el correo nuevo.'), findsOneWidget);
    expect(find.text('Escribe tu contraseña actual.'), findsOneWidget);
    expect(auth.user.calls, isEmpty);

    await fill(tester, 'email', testEmail);
    await fill(tester, 'current', 'Clave-actual-1!');
    await submit(tester);
    expect(find.text('Es el mismo correo de tu cuenta.'), findsOneWidget);

    await fill(tester, 'email', 'nuevo@example.test');
    await submit(tester);
    expect(auth.user.calls, ['reauth', 'email:nuevo@example.test']);
    expect(
      find.textContaining('Enviamos un enlace a nuevo@example.test'),
      findsOneWidget,
    );
    expect(key('account-action-submit'), findsNothing);
  });

  testWidgets('una contraseña actual incorrecta no cambia nada', (
    tester,
  ) async {
    final (auth, _, _) = await mount(tester);
    auth.user.failReauth = 'wrong-password';
    await open(tester, 'account-change-email');
    await fill(tester, 'email', 'nuevo@example.test');
    await fill(tester, 'current', 'incorrecta');
    await submit(tester);
    expect(auth.user.calls, ['reauth']);
    expect(find.text('La contraseña actual no es correcta.'), findsOneWidget);
    expect(key('account-action-submit'), findsOneWidget);
  });

  testWidgets('cambiar contraseña exige los requisitos del registro', (
    tester,
  ) async {
    final (auth, _, _) = await mount(tester);
    await open(tester, 'account-change-password');
    expect(find.byKey(const Key('password-checklist')), findsOneWidget);
    await fill(tester, 'current', 'Clave-actual-1!');
    await fill(tester, 'new', 'sinmayuscula1!');
    await submit(tester);
    expect(
      find.text('La contraseña nueva no cumple todos los requisitos.'),
      findsOneWidget,
    );
    expect(auth.user.calls, isEmpty);

    await fill(tester, 'new', 'Nueva-clave-2?');
    await submit(tester);
    expect(auth.user.calls, ['reauth', 'password:Nueva-clave-2?']);
    expect(find.text('Contraseña actualizada.'), findsOneWidget);
  });

  testWidgets('eliminar la cuenta retira la nube antes que el usuario', (
    tester,
  ) async {
    final (auth, erased, _) = await mount(tester);
    await open(tester, 'account-delete');
    expect(find.textContaining('No se puede deshacer'), findsOneWidget);
    await fill(tester, 'current', 'Clave-actual-1!');
    await submit(tester);
    expect(auth.user.calls, ['reauth', 'erase', 'delete']);
    expect(erased, ['cuenta-pruebas']);
    expect(auth.user.deleted, isTrue);
  });

  testWidgets('si falla el borrado en la nube, la cuenta se conserva', (
    tester,
  ) async {
    final (auth, _, _) = await mount(tester, eraseFails: true);
    await open(tester, 'account-delete');
    await fill(tester, 'current', 'Clave-actual-1!');
    await submit(tester);
    expect(auth.user.calls, ['reauth', 'erase']);
    expect(auth.user.deleted, isFalse);
    expect(
      find.text('No se pudo completar la solicitud. Vuelve a intentar.'),
      findsOneWidget,
    );
  });

  testWidgets('no se elimina la cuenta con una sesión de monitoreo abierta', (
    tester,
  ) async {
    final (auth, erased, engine) = await mount(tester);
    engine.current = fakeSnapshot(
      lifecycle: EngineSessionLifecycle.active,
      sessionId: 'session-test',
    );
    await open(tester, 'account-delete');
    await fill(tester, 'current', 'Clave-actual-1!');
    await submit(tester);
    expect(
      find.text('Finaliza el monitoreo antes de eliminar la cuenta.'),
      findsOneWidget,
    );
    expect(auth.user.calls, isEmpty);
    expect(erased, isEmpty);
  });

  for (final dark in [false, true]) {
    for (final (width, scale) in [(360.0, 1.0), (320.0, 2.0)]) {
      final config = (width: width, scale: scale, dark: dark);
      final name =
          '${dark ? 'oscuro' : 'claro'}_${width.round()}_'
          '${(scale * 100).round()}';
      testWidgets('hojas de la cuenta · $name', (tester) async {
        await mount(tester, config: config);
        Future<void> capture(String screen) => expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('navegacion/${screen}__$name.png'),
        );

        await open(tester, 'account-change-password');
        await fill(tester, 'new', 'Nueva-1');
        await tester.pumpAndSettle();
        await capture('cuenta_contrasena');
        await tester.tap(key('account-action-cancel'));
        await tester.pumpAndSettle();
        await open(tester, 'account-delete');
        await capture('cuenta_eliminar');
        expect(tester.takeException(), isNull);
      });
    }
  }
}
