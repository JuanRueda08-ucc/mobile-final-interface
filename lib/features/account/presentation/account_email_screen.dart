import 'package:flutter/material.dart';

import '../../../core/design_system/theme.dart';
import '../../../core/design_system/vigia_icons.dart';
import '../../../core/design_system/widgets/vigia_button.dart';
import '../../../core/design_system/widgets/vigia_text.dart';
import 'account_form.dart';

enum AccountAccessMode { signIn, signUp }

class AccountEmailScreen extends StatefulWidget {
  const AccountEmailScreen({
    super.key,
    required this.mode,
    required this.initialEmail,
    required this.isSubmitting,
    required this.onSubmit,
    required this.onSwitchMode,
    this.errorText,
    this.onBack,
  });

  final AccountAccessMode mode;
  final String initialEmail;
  final bool isSubmitting;
  final String? errorText;
  final ValueChanged<String> onSubmit;
  final VoidCallback onSwitchMode;
  final VoidCallback? onBack;

  @override
  State<AccountEmailScreen> createState() => _AccountEmailScreenState();
}

class _AccountEmailScreenState extends State<AccountEmailScreen> {
  static final _emailShape = RegExp(
    r'^[^\s@.<>]+(?:\.[^\s@.<>]+)*@[^\s@.<>]+(?:\.[^\s@.<>]+)+$',
  );

  late final TextEditingController _email;
  final _requestGate = AccountRequestGate();
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail);
  }

  @override
  void didUpdateWidget(covariant AccountEmailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialEmail != oldWidget.initialEmail) {
      _email.text = widget.initialEmail;
    }
    if (widget.mode != oldWidget.mode ||
        widget.initialEmail != oldWidget.initialEmail) {
      _validationError = null;
    }
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.isSubmitting) return;
    final email = _email.text.trim();
    if (!_emailShape.hasMatch(email)) {
      setState(
        () => _validationError = 'Ingresa un correo electrónico válido.',
      );
      return;
    }
    _requestGate.run(() {
      if (_validationError != null) setState(() => _validationError = null);
      FocusScope.of(context).unfocus();
      widget.onSubmit(email);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = VigiaColors.of(context);
    final signUp = widget.mode == AccountAccessMode.signUp;
    return AccountForm(
      title: signUp ? 'Crear cuenta' : 'Iniciar sesión',
      description: signUp
          ? 'Verifica tu correo con un código para crear tu cuenta.'
          : 'Accede con un código de un solo uso por correo.',
      isBusy: widget.isSubmitting,
      onBack: widget.onBack,
      action: VigiaButton(
        label: widget.isSubmitting ? 'Enviando código…' : 'Enviar código',
        icon: widget.isSubmitting || isLargeText(context)
            ? null
            : VigiaIcon.arrow,
        onPressed: widget.isSubmitting ? null : _submit,
      ),
      children: [
        TextField(
          controller: _email,
          readOnly: widget.isSubmitting,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autocorrect: false,
          enableSuggestions: false,
          autofillHints: const [AutofillHints.email],
          style: VigiaType.body.copyWith(color: p.ink),
          cursorColor: p.focus,
          decoration: accountFieldDecoration(
            context,
            label: 'Correo electrónico',
            error: _validationError ?? widget.errorText,
          ),
          onChanged: (_) {
            if (_validationError != null) {
              setState(() => _validationError = null);
            }
          },
          onSubmitted: (_) => _submit(),
        ),
        VigiaButton(
          kind: VigiaButtonKind.secondary,
          label: signUp ? 'Iniciar sesión' : 'Crear cuenta',
          onPressed: widget.isSubmitting
              ? null
              : () => _requestGate.run(widget.onSwitchMode),
        ),
      ],
    );
  }
}
