import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design_system/theme.dart';
import '../../../core/design_system/vigia_icons.dart';
import '../../../core/design_system/widgets/vigia_blocks.dart';
import '../../../core/design_system/widgets/vigia_button.dart';
import '../../../core/design_system/widgets/vigia_scaffold.dart';
import '../../../core/design_system/widgets/vigia_text.dart';
import 'account_form.dart';

class AccountCodeScreen extends StatefulWidget {
  const AccountCodeScreen({
    super.key,
    required this.email,
    required this.codeLength,
    required this.isVerifying,
    required this.isResending,
    required this.resendAvailableIn,
    required this.onVerify,
    required this.onResend,
    required this.onChangeEmail,
    this.notice,
    this.errorText,
  }) : assert(codeLength > 0);

  final String email;
  final int codeLength;
  final bool isVerifying;
  final bool isResending;
  final Duration resendAvailableIn;
  final String? notice;
  final String? errorText;
  final ValueChanged<String> onVerify;
  final VoidCallback onResend;
  final VoidCallback onChangeEmail;

  @override
  State<AccountCodeScreen> createState() => _AccountCodeScreenState();
}

class _AccountCodeScreenState extends State<AccountCodeScreen> {
  final _code = TextEditingController();
  final _requestGate = AccountRequestGate();
  String? _validationError;

  bool get _busy => widget.isVerifying || widget.isResending;

  @override
  void didUpdateWidget(covariant AccountCodeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.email != oldWidget.email ||
        widget.codeLength != oldWidget.codeLength) {
      _code.clear();
      _validationError = null;
    }
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _verify() {
    if (_busy) return;
    final code = _code.text;
    if (code.length != widget.codeLength) {
      setState(
        () => _validationError =
            'Ingresa los ${widget.codeLength} dígitos del código.',
      );
      return;
    }
    _requestGate.run(() {
      FocusScope.of(context).unfocus();
      widget.onVerify(code);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = VigiaColors.of(context);
    final canResend = widget.resendAvailableIn <= Duration.zero;
    final seconds =
        (widget.resendAvailableIn.inMicroseconds /
                Duration.microsecondsPerSecond)
            .ceil();
    return AccountForm(
      title: 'Verificar código',
      description:
          'Ingresa el código de ${widget.codeLength} dígitos para este correo.',
      detail: widget.email,
      isBusy: _busy,
      action: VigiaButton(
        label: switch ((widget.isVerifying, widget.isResending)) {
          (true, _) => 'Verificando código…',
          (_, true) => 'Reenviando código…',
          _ => 'Verificar código',
        },
        icon: _busy || isLargeText(context) ? null : VigiaIcon.arrow,
        onPressed: _busy ? null : _verify,
      ),
      children: [
        TextField(
          controller: _code,
          readOnly: _busy,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(widget.codeLength),
          ],
          style: VigiaType.kvValue.copyWith(
            color: p.ink,
            fontSize: 20,
            letterSpacing: 3,
          ),
          cursorColor: p.focus,
          decoration: accountFieldDecoration(
            context,
            label: 'Código',
            error: _validationError ?? widget.errorText,
          ),
          onChanged: (_) {
            if (_validationError != null) {
              setState(() => _validationError = null);
            }
          },
          onSubmitted: (_) => _verify(),
        ),
        if (widget.notice case final notice?) VigiaNotice(text: notice),
        if (!canResend && !widget.isResending)
          VigiaParagraph('Podrás reenviar el código en $seconds s.'),
        VigiaButton(
          kind: VigiaButtonKind.secondary,
          label: 'Reenviar código',
          onPressed: _busy || !canResend
              ? null
              : () => _requestGate.run(() {
                  FocusScope.of(context).unfocus();
                  widget.onResend();
                }),
        ),
        VigiaButton(
          kind: VigiaButtonKind.secondary,
          label: 'Cambiar correo',
          onPressed: _busy
              ? null
              : () => _requestGate.run(widget.onChangeEmail),
        ),
      ],
    );
  }
}
