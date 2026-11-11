@Tags(['render'])
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia/features/account/firebase_account.dart';
import 'package:vigia/features/account/firebase_account_screen.dart';

import '../support/vigia_harness.dart' show loadVigiaFonts;
import 'presentation/account_test_harness.dart';

class _PendingUser extends Fake implements User {
  @override
  String get email => testEmail;

  @override
  bool get emailVerified => false;
}

class _PendingAuth extends Fake implements FirebaseAuth {
  @override
  Stream<User?> userChanges() => Stream.value(_PendingUser());
}

void main() {
  setUpAll(loadVigiaFonts);

  for (final dark in [false, true]) {
    for (final (width, scale) in [(360.0, 1.0), (320.0, 2.0)]) {
      final config = (width: width, scale: scale, dark: dark);
      testWidgets('Enlace pendiente · ${configName(config)}', (tester) async {
        configureView(tester, config);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [firebaseAuthProvider.overrideWithValue(_PendingAuth())],
            child: accountApp(const FirebaseAccountScreen(), dark: dark),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Verifica tu correo'), findsOneWidget);
        expect(button('Ya verifiqué mi correo').hitTestable(), findsOneWidget);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('firebase/verificacion__${configName(config)}.png'),
        );
        final resend = button('Reenviar correo');
        await tester.ensureVisible(resend);
        expect(resend.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
