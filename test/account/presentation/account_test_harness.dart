import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia/core/design_system/theme.dart';
import 'package:vigia/core/design_system/widgets/vigia_button.dart';
import 'package:vigia/features/account/presentation/account_code_screen.dart';

const testEmail = 'ana@example.test';
const testCode = '042681';

final accountConfigs = [
  for (final width in [320.0, 360.0])
    for (final scale in [1.0, 2.0])
      for (final dark in [false, true])
        (width: width, scale: scale, dark: dark),
];

String configName(({double width, double scale, bool dark}) c) =>
    '${c.dark ? 'oscuro' : 'claro'}_${c.width.toInt()}_${(100 * c.scale).toInt()}';

void configureView(
  WidgetTester tester,
  ({double width, double scale, bool dark}) c, {
  double height = 640,
}) {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = Size(c.width, height) * 2;
  tester.platformDispatcher.textScaleFactorTestValue = c.scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
}

Widget accountApp(Widget home, {bool dark = false}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: dark ? vigiaDarkTheme : vigiaLightTheme,
  home: home,
);

Finder button(String label) => find.byWidgetPredicate(
  (widget) => widget is VigiaButton && widget.label == label,
  description: 'Botón «$label»',
);

void noop() {}
void ignoreInput(String _) {}

AccountCodeScreen codeScreen({
  String email = testEmail,
  int codeLength = 6,
  bool isVerifying = false,
  bool isResending = false,
  Duration resendAvailableIn = Duration.zero,
  String? notice,
  String? errorText,
  ValueChanged<String> onVerify = ignoreInput,
  VoidCallback onResend = noop,
  VoidCallback onChangeEmail = noop,
}) => AccountCodeScreen(
  email: email,
  codeLength: codeLength,
  isVerifying: isVerifying,
  isResending: isResending,
  resendAvailableIn: resendAvailableIn,
  notice: notice,
  errorText: errorText,
  onVerify: onVerify,
  onResend: onResend,
  onChangeEmail: onChangeEmail,
);
