import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia/core/design_system/theme.dart';
import 'package:vigia/features/account/presentation/password_rules.dart';

void main() {
  // Usuario (2026-11-16): al crear la cuenta, la contraseña lleva al menos
  // 8 caracteres, una mayúscula, un número y un símbolo.
  test('cada requisito se cumple por separado', () {
    bool met(String password, int rule) =>
        PasswordRules.check(password)[rule].$2;
    expect(met('abcdefgh', 0), isTrue);
    expect(met('abcdefg', 0), isFalse);
    expect(met('abcÑ', 1), isTrue);
    expect(met('abc', 1), isFalse);
    expect(met('abc7', 2), isTrue);
    expect(met('abc', 2), isFalse);
    expect(met('abc-', 3), isTrue);
    expect(met('abc ñ', 3), isFalse);
  });

  test('solo una contraseña con todo es válida', () {
    expect(PasswordRules.allMet('Prueba-vigia-8'), isTrue);
    expect(PasswordRules.allMet('prueba-vigia-8'), isFalse);
    expect(PasswordRules.allMet('Prueba-vigia'), isFalse);
    expect(PasswordRules.allMet('Prueba vigia 8'), isFalse);
    expect(PasswordRules.allMet('Pv-8'), isFalse);
  });

  testWidgets('la lista marca lo cumplido al escribir', (tester) async {
    Future<void> show(String password) => tester.pumpWidget(
      MaterialApp(
        theme: vigiaLightTheme,
        home: Scaffold(body: PasswordChecklist(password: password)),
      ),
    );
    await show('');
    expect(find.text('Al menos 8 caracteres'), findsOneWidget);
    expect(find.bySemanticsLabel('Cumplido'), findsNothing);
    await show('Prueba-vigia-8');
    final handle = tester.ensureSemantics();
    await tester.pump();
    expect(find.bySemanticsLabel(RegExp('Cumplido')), findsNWidgets(4));
    handle.dispose();
  });
}
