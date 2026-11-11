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

void main() {
  setUpAll(loadVigiaFonts);

  for (final dark in [false, true]) {
    final config = (width: 320.0, scale: 2.0, dark: dark);
    testWidgets('acceso Firebase en ${configName(config)}', (tester) async {
      configureView(tester, config);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [firebaseAuthProvider.overrideWithValue(_SignedOutAuth())],
          child: accountApp(const FirebaseAccountScreen(), dark: dark),
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
      final register = button('Crear cuenta');
      await tester.ensureVisible(register);
      await tester.tap(register);
      await tester.pumpAndSettle();
      expect(find.text('Crea tu cuenta'), findsOneWidget);
      expect(button('Crear cuenta').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
