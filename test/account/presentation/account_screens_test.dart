import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia/core/design_system/widgets/vigia_button.dart';
import 'package:vigia/features/account/presentation/account_email_screen.dart';

import '../../support/vigia_harness.dart' show loadVigiaFonts;
import 'account_test_harness.dart';

void main() {
  final field = find.byType(TextField);

  setUpAll(loadVigiaFonts);

  testWidgets('correo inválido, pegado y envío único por teclado y botón', (
    tester,
  ) async {
    final requests = <String>[];
    var busy = false;
    await tester.pumpWidget(
      accountApp(
        StatefulBuilder(
          builder: (context, setState) => AccountEmailScreen(
            mode: AccountAccessMode.signIn,
            initialEmail: '',
            isSubmitting: busy,
            onSubmit: (email) {
              requests.add(email);
              setState(() => busy = true);
            },
            onSwitchMode: () => fail('Cambio de modo durante el envío'),
          ),
        ),
      ),
    );
    final send = button('Enviar código');
    await tester.enterText(field, 'correo-incompleto');
    await tester.tap(send);
    await tester.pumpAndSettle();
    expect(requests, isEmpty);
    expectLiveError(tester, 'Ingresa un correo electrónico válido.');

    await tester.enterText(field, '');
    await paste(tester, '  $testEmail  ');
    await tester.pumpAndSettle();
    expect(find.text('Ingresa un correo electrónico válido.'), findsNothing);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.tap(send);
    await tester.pumpAndSettle();
    expect(requests, [testEmail]);
    expect(tester.widget<TextField>(field).readOnly, isTrue);
    expectDisabled(tester, 'Enviando código…');
    expectDisabled(tester, 'Crear cuenta');
  });

  testWidgets('cambia de modo, verifica y vuelve con el correo editable', (
    tester,
  ) async {
    var mode = AccountAccessMode.signIn;
    String? destination;
    var initialEmail = '';
    var backCount = 0;
    final verified = <String>[];
    await tester.pumpWidget(
      accountApp(
        StatefulBuilder(
          builder: (context, setState) => destination == null
              ? AccountEmailScreen(
                  mode: mode,
                  initialEmail: initialEmail,
                  isSubmitting: false,
                  onSwitchMode: () =>
                      setState(() => mode = AccountAccessMode.signUp),
                  onBack: () => backCount++,
                  onSubmit: (email) => setState(() => destination = email),
                )
              : codeScreen(
                  email: destination!,
                  onVerify: verified.add,
                  onChangeEmail: () => setState(() {
                    initialEmail = destination!;
                    destination = null;
                  }),
                ),
        ),
      ),
    );
    await tester.tap(find.bySemanticsLabel('Volver'));
    expect(backCount, 1);
    await tester.enterText(field, testEmail);
    await tester.tap(button('Crear cuenta'));
    await tester.pumpAndSettle();
    expect(find.text('Crear cuenta'), findsOneWidget);
    expect(button('Iniciar sesión'), findsOneWidget);
    expect(tester.widget<TextField>(field).controller!.text, testEmail);
    await tester.tap(button('Enviar código'));
    await tester.pumpAndSettle();
    expect(find.textContaining(testEmail), findsOneWidget);

    await tester.enterText(field, '42');
    await tester.tap(button('Verificar código'));
    await tester.pumpAndSettle();
    expect(verified, isEmpty);
    expect(find.text('Ingresa los 6 dígitos del código.'), findsOneWidget);
    await tester.enterText(field, '');
    await paste(tester, testCode);
    await tester.pumpAndSettle();
    await tester.tap(button('Verificar código'));
    await tester.pumpAndSettle();
    expect(verified, [testCode]);

    await tester.tap(button('Cambiar correo'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(field).controller!.text, testEmail);
    await tester.enterText(field, 'otro@example.test');
    await tester.tap(button('Enviar código'));
    await tester.pumpAndSettle();
    expect(find.textContaining('otro@example.test'), findsOneWidget);
    expect(tester.widget<TextField>(field).controller!.text, isEmpty);
  });

  testWidgets('falta de conexión al enviar y reintento con el mismo correo', (
    tester,
  ) async {
    const offline = 'Sin conexión. Revisa Internet e inténtalo de nuevo.';
    final requests = <String>[];
    String? error;
    await tester.pumpWidget(
      accountApp(
        StatefulBuilder(
          builder: (context, setState) => AccountEmailScreen(
            mode: AccountAccessMode.signIn,
            initialEmail: testEmail,
            isSubmitting: false,
            errorText: error,
            onSubmit: (email) => setState(() {
              requests.add(email);
              error = requests.length == 1 ? offline : null;
            }),
            onSwitchMode: noop,
          ),
        ),
      ),
    );
    await tester.tap(button('Enviar código'));
    await tester.pumpAndSettle();
    expectLiveError(tester, offline);
    await tester.tap(button('Enviar código'));
    await tester.pumpAndSettle();
    expect(requests, [testEmail, testEmail]);
    expect(find.text(offline), findsNothing);
  });

  testWidgets('verificación en curso, código incorrecto y código caducado', (
    tester,
  ) async {
    const invalid = 'El código es incorrecto. Revisa los dígitos.';
    const expired = 'El código caducó. Solicita uno nuevo.';
    final verified = <String>[];
    var busy = false;
    String? error;
    late StateSetter update;
    await tester.pumpWidget(
      accountApp(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return codeScreen(
              isVerifying: busy,
              errorText: error,
              onVerify: (code) => setState(() {
                verified.add(code);
                busy = true;
                error = null;
              }),
              onResend: () => fail('Reenvío durante verificación'),
              onChangeEmail: () => fail('Cambio durante verificación'),
            );
          },
        ),
      ),
    );
    final verify = button('Verificar código');
    await tester.enterText(field, '999999');
    await tester.tap(verify);
    await tester.tap(verify);
    await tester.pumpAndSettle();
    expect(verified, ['999999']);
    expect(tester.widget<TextField>(field).readOnly, isTrue);
    expectDisabled(tester, 'Verificando código…');
    expectDisabled(tester, 'Reenviar código');
    expectDisabled(tester, 'Cambiar correo');

    update(() {
      error = invalid;
      busy = false;
    });
    await tester.pumpAndSettle();
    expectLiveError(tester, invalid);
    await tester.enterText(field, testCode);
    await tester.tap(verify);
    update(() {
      error = expired;
      busy = false;
    });
    await tester.pumpAndSettle();
    expect(verified, ['999999', testCode]);
    expectLiveError(tester, expired);
    expect(
      tester.widget<VigiaButton>(button('Reenviar código')).onPressed,
      isNotNull,
    );
  });

  testWidgets('reenvío con espera inyectada, progreso, error y confirmación', (
    tester,
  ) async {
    const offline = 'Sin conexión. Vuelve a intentar el reenvío.';
    const notice = 'Si el envío fue posible, recibirás un código nuevo.';
    var requests = 0;
    var busy = false;
    var wait = const Duration(milliseconds: 200);
    String? error;
    String? confirmation;
    late StateSetter update;
    await tester.pumpWidget(
      accountApp(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return codeScreen(
              isResending: busy,
              resendAvailableIn: wait,
              notice: confirmation,
              errorText: error,
              onResend: () => setState(() {
                requests++;
                busy = true;
                error = null;
              }),
              onVerify: (_) => fail('Verificación durante el reenvío'),
            );
          },
        ),
      ),
    );
    final resend = button('Reenviar código');
    expect(find.text('Podrás reenviar el código en 1 s.'), findsOneWidget);
    expectDisabled(tester, 'Reenviar código');
    await tester.tap(resend);
    await tester.pump(const Duration(seconds: 1));
    expect(requests, 0);
    expectDisabled(tester, 'Reenviar código');
    update(() => wait = Duration.zero);
    await tester.pumpAndSettle();
    await tester.tap(resend);
    await tester.tap(resend);
    await tester.pumpAndSettle();
    expect(requests, 1);
    expectDisabled(tester, 'Reenviando código…');
    expectDisabled(tester, 'Reenviar código');
    expectDisabled(tester, 'Cambiar correo');
    update(() {
      busy = false;
      error = offline;
    });
    await tester.pumpAndSettle();
    expectLiveError(tester, offline);
    await tester.tap(resend);
    update(() {
      busy = false;
      wait = const Duration(seconds: 30);
      confirmation = notice;
    });
    await tester.pumpAndSettle();
    expect(requests, 2);
    expect(find.text(notice), findsOneWidget);
    expect(find.text('Podrás reenviar el código en 30 s.'), findsOneWidget);
    expectDisabled(tester, 'Reenviar código');
  });

  testWidgets('longitud y destinatario se actualizan con el estado inyectado', (
    tester,
  ) async {
    final verified = <String>[];
    await tester.pumpWidget(accountApp(codeScreen(onVerify: verified.add)));
    await tester.enterText(field, testCode);
    await tester.pumpWidget(
      accountApp(
        codeScreen(
          email: 'otro@example.test',
          codeLength: 4,
          onVerify: verified.add,
        ),
      ),
    );
    expect(tester.widget<TextField>(field).controller!.text, isEmpty);
    await tester.enterText(field, '0a1 2-3');
    await tester.tap(button('Verificar código'));
    expect(verified, ['0123']);
  });

  testWidgets('muestra el error del código con teclado y texto al 200 %', (
    tester,
  ) async {
    configureView(tester, (width: 320, scale: 2, dark: true));
    await tester.pumpWidget(
      accountApp(codeScreen(onVerify: (_) => fail('Código vacío')), dark: true),
    );
    await openKeyboard(tester, field);
    await tester.tap(button('Verificar código'));
    await tester.pumpAndSettle();
    expect(
      find.bySemanticsLabel('Ingresa los 6 dígitos del código.'),
      findsOneWidget,
    );
    final message = find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          (widget.data == 'Ingresa los 6 dígitos del código.' ||
              widget.semanticsLabel == 'Ingresa los 6 dígitos del código.'),
    );
    expect(message.hitTestable(), findsOneWidget);
    expect(tester.testTextInput.isVisible, isTrue);
  });

  for (final c in accountConfigs) {
    testWidgets('acciones con teclado abierto · ${configName(c)}', (
      tester,
    ) async {
      configureView(tester, c);
      for (final mode in AccountAccessMode.values) {
        final requests = <String>[];
        await tester.pumpWidget(
          accountApp(
            AccountEmailScreen(
              key: ValueKey(mode),
              mode: mode,
              initialEmail: testEmail,
              isSubmitting: false,
              errorText: 'Sin conexión. Revisa Internet e inténtalo de nuevo.',
              onSubmit: requests.add,
              onSwitchMode: noop,
            ),
            dark: c.dark,
          ),
        );
        await openKeyboard(tester, field);
        await expectReachable(tester, button('Enviar código'), pinned: true);
        await expectReachable(
          tester,
          button(
            mode == AccountAccessMode.signIn
                ? 'Crear cuenta'
                : 'Iniciar sesión',
          ),
        );
        await tester.tap(button('Enviar código'));
        expect(requests, [testEmail]);
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
      }
      final verified = <String>[];
      await tester.pumpWidget(
        accountApp(
          codeScreen(
            errorText: 'El código caducó. Solicita uno nuevo.',
            onVerify: verified.add,
          ),
          dark: c.dark,
        ),
      );
      await openKeyboard(tester, field);
      await tester.enterText(field, testCode);
      await tester.pumpAndSettle();
      await expectReachable(tester, button('Verificar código'), pinned: true);
      await expectReachable(tester, button('Reenviar código'));
      await expectReachable(tester, button('Cambiar correo'));
      await tester.tap(button('Verificar código'));
      expect(verified, [testCode]);
      expect(tester.takeException(), isNull);
    });
  }
}

void expectDisabled(WidgetTester tester, String label) {
  expect(tester.widget<VigiaButton>(button(label)).onPressed, isNull);
}

void expectLiveError(WidgetTester tester, String message) {
  expect(find.text(message), findsOneWidget);
  final announcement = find.bySemanticsLabel(message);
  expect(announcement, findsOneWidget);
  expect(
    tester
        .getSemantics(announcement)
        .getSemanticsData()
        .flagsCollection
        .isLiveRegion,
    isTrue,
  );
}

Future<void> paste(WidgetTester tester, String text) async {
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async => call.method == 'Clipboard.getData' ? {'text': text} : null,
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  await tester
      .state<EditableTextState>(find.byType(EditableText))
      .pasteText(SelectionChangedCause.toolbar);
}

Future<void> openKeyboard(WidgetTester tester, Finder field) async {
  await tester.showKeyboard(field);
  // 300 dp de teclado sobre una ventana lógica de 640 dp.
  tester.view.viewInsets = const FakeViewPadding(bottom: 600);
  await tester.pumpAndSettle();
}

Future<void> expectReachable(
  WidgetTester tester,
  Finder action, {
  bool pinned = false,
}) async {
  if (!pinned) {
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
  }
  final rect = tester.getRect(action);
  expect(rect.width, greaterThanOrEqualTo(48));
  expect(rect.height, greaterThanOrEqualTo(48));
  expect(rect.bottom, lessThanOrEqualTo(340));
  expect(action.hitTestable(), findsOneWidget);
  expect(tester.testTextInput.isVisible, isTrue);
}
