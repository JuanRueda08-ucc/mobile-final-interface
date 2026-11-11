import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia/features/account/firebase_account.dart';
import 'package:vigia/features/account/firebase_account_screen.dart';

import '../support/vigia_harness.dart' show loadVigiaFonts;
import 'presentation/account_test_harness.dart';

class _SignedOutAuth extends Fake implements FirebaseAuth {
  @override
  Stream<User?> userChanges() => Stream.value(null);
}

class _VerificationUser extends Fake implements User {
  int links = 0;
  bool verified = false;
  bool refreshed = false;

  @override
  String get email => testEmail;

  @override
  bool get emailVerified => verified;

  @override
  Future<void> sendEmailVerification([ActionCodeSettings? settings]) async {
    links++;
  }

  @override
  Future<void> reload() async {
    verified = true;
  }

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async {
    refreshed = forceRefresh;
    return 'token-de-prueba';
  }
}

class _Credential extends Fake implements UserCredential {
  _Credential(this.user);

  @override
  final User user;
}

class _FlowAuth extends Fake implements FirebaseAuth {
  final changes = StreamController<User?>.broadcast();
  final account = _VerificationUser();
  final creation = Completer<void>();
  User? _current;
  String? resetEmail;

  @override
  User? get currentUser => _current;

  @override
  Stream<User?> userChanges() async* {
    yield _current;
    yield* changes.stream;
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    expect(email, testEmail);
    await creation.future;
    _current = account;
    changes.add(account);
    return _Credential(account);
  }

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
    ActionCodeSettings? actionCodeSettings,
  }) async {
    resetEmail = email;
  }
}

void main() {
  setUpAll(loadVigiaFonts);

  for (final config in accountConfigs.where(
    (c) => (c.width == 320 && c.scale == 2) || (c.width == 360 && c.scale == 1),
  )) {
    testWidgets('acceso Firebase en ${configName(config)}', (tester) async {
      configureView(tester, config);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [firebaseAuthProvider.overrideWithValue(_SignedOutAuth())],
          child: accountApp(const FirebaseAccountScreen(), dark: config.dark),
        ),
      );
      await tester.pumpAndSettle();
      expect(button('Iniciar sesión').hitTestable(), findsOneWidget);
      expect(
        tester.widgetList<TextField>(find.byType(TextField)).last.obscureText,
        isTrue,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('firebase/acceso__${configName(config)}.png'),
      );
      final register = find.widgetWithText(TextButton, 'Crear cuenta');
      await tester.ensureVisible(register);
      await tester.tap(register);
      await tester.pumpAndSettle();
      expect(find.text('Crea tu cuenta'), findsOneWidget);
      expect(button('Crear cuenta').hitTestable(), findsOneWidget);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('firebase/registro__${configName(config)}.png'),
      );
      await tester.tap(button('Crear cuenta'));
      await tester.pumpAndSettle();
      expect(find.text('Escribe tu correo.'), findsOneWidget);
      expect(find.text('Escribe tu contraseña.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('registro conserva el envío y la verificación por enlace', (
    tester,
  ) async {
    final auth = _FlowAuth();
    addTearDown(auth.changes.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [firebaseAuthProvider.overrideWithValue(auth)],
        child: accountApp(const FirebaseAccountScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, testEmail);
    await tester.tap(find.widgetWithText(TextButton, 'Crear cuenta'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      testEmail,
    );
    await tester.enterText(find.byType(TextField).last, 'prueba-vigia-8');
    await tester.tap(button('Crear cuenta'));
    await tester.pump();
    expect(button('Creando cuenta…'), findsOneWidget);
    expect(
      tester
          .widgetList<TextField>(find.byType(TextField))
          .every((f) => !f.enabled!),
      isTrue,
    );
    auth.creation.complete();
    await tester.pumpAndSettle();
    expect(auth.account.links, 1);
    expect(find.text('Verifica tu correo'), findsOneWidget);
    await tester.tap(button('Ya verifiqué mi correo'));
    await tester.pumpAndSettle();
    expect(auth.account.refreshed, isTrue);
  });

  testWidgets('recuperación conserva el correo y pide un enlace', (
    tester,
  ) async {
    final auth = _FlowAuth();
    addTearDown(auth.changes.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [firebaseAuthProvider.overrideWithValue(auth)],
        child: accountApp(const FirebaseAccountScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, testEmail);
    await tester.tap(find.widgetWithText(TextButton, 'Olvidé mi contraseña'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    await tester.tap(button('Enviar enlace'));
    await tester.pumpAndSettle();
    expect(auth.resetEmail, testEmail);
    expect(
      find.text('Si el correo tiene una cuenta, recibirás un enlace.'),
      findsOneWidget,
    );
  });
}
