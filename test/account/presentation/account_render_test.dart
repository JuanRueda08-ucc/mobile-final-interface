@Tags(['render'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia/features/account/presentation/account_email_screen.dart';

import '../../support/vigia_harness.dart' show loadVigiaVisualAssets;
import 'account_test_harness.dart';

void main() {
  setUpAll(loadVigiaVisualAssets);

  const renderEmail = 'a@example.test';
  final screens = <String, Widget>{
    for (final mode in AccountAccessMode.values)
      (mode == AccountAccessMode.signIn
          ? 'iniciar_sesion'
          : 'crear_cuenta'): AccountEmailScreen(
        mode: mode,
        initialEmail: renderEmail,
        isSubmitting: false,
        onSubmit: ignoreInput,
        onSwitchMode: noop,
        onBack: noop,
      ),
    'verificar_codigo': codeScreen(
      email: renderEmail,
      resendAvailableIn: const Duration(seconds: 30),
    ),
  };

  for (final c in accountConfigs) {
    for (final MapEntry(key: id, value: screen) in screens.entries) {
      final name = '${id}__${configName(c)}';
      testWidgets(name, (tester) async {
        configureView(tester, c, height: c.scale == 2 ? 880 : 640);
        await tester.pumpWidget(accountApp(screen, dark: c.dark));
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('renderizados_datos_de_prueba/$name.png'),
        );
      });
    }
  }
}
