import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/theme.dart';
import '../../../core/design_system/tokens.dart';
import '../../../core/design_system/vigia_icons.dart';
import '../../../core/design_system/widgets/vigia_button.dart';
import '../../../core/design_system/widgets/vigia_text.dart';
import '../firebase_account.dart';
import 'account_form.dart';
import 'password_rules.dart';

/// Acciones de seguridad de la cuenta (usuario, 2026-11-17): cambiar el
/// correo, cambiar la contraseña y eliminar la cuenta. Cada una pide la
/// contraseña actual y se resuelve en una hoja inferior.
enum AccountAction { email, password, delete }

/// Abre la hoja de [action]. Devuelve el aviso que debe mostrar Cuenta al
/// terminar con éxito, o nulo si se cancela.
Future<String?> showAccountActionSheet(
  BuildContext context,
  AccountAction action,
) {
  final p = VigiaColors.of(context);
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: p.bg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(VigiaRadius.card),
      ),
    ),
    builder: (_) => AccountActionSheet(action: action),
  );
}

class AccountActionSheet extends ConsumerStatefulWidget {
  const AccountActionSheet({super.key, required this.action});

  final AccountAction action;

  @override
  ConsumerState<AccountActionSheet> createState() => _AccountActionSheetState();
}

class _AccountActionSheetState extends ConsumerState<AccountActionSheet> {
  final _current = TextEditingController();
  final _email = TextEditingController();
  final _next = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _currentError;
  String? _fieldError;
  String? _feedback;

  @override
  void dispose() {
    _current.dispose();
    _email.dispose();
    _next.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final auth = ref.read(firebaseAuthProvider);
    final user = auth?.currentUser;
    final current = _current.text;
    final email = _email.text.trim();
    final next = _next.text;
    String? fieldError;
    if (widget.action == AccountAction.email) {
      if (email.isEmpty) {
        fieldError = 'Escribe el correo nuevo.';
      } else if (email.toLowerCase() == user?.email?.toLowerCase()) {
        fieldError = 'Es el mismo correo de tu cuenta.';
      }
    } else if (widget.action == AccountAction.password &&
        !PasswordRules.allMet(next)) {
      fieldError = 'La contraseña nueva no cumple todos los requisitos.';
    }
    final currentError = current.isEmpty
        ? 'Escribe tu contraseña actual.'
        : null;
    setState(() {
      _feedback = null;
      _currentError = currentError;
      _fieldError = fieldError;
    });
    if (currentError != null || fieldError != null) return;
    if (auth == null || user == null) {
      setState(() => _feedback = 'No hay una sesión abierta.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    String? result;
    String? failure;
    try {
      switch (widget.action) {
        case AccountAction.email:
          await requestAccountEmailChange(
            user,
            password: current,
            newEmail: email,
          );
          result =
              'Enviamos un enlace a $email. Tu correo cambiará cuando lo '
              'abras.';
        case AccountAction.password:
          await changeAccountPassword(
            user,
            password: current,
            newPassword: next,
          );
          result = 'Contraseña actualizada.';
        case AccountAction.delete:
          failure = await deleteVigiaAccount(ref, auth, password: current);
          result = failure == null ? 'Cuenta eliminada.' : null;
      }
    } catch (error) {
      failure = accountActionError(error);
    }
    if (!mounted) return;
    if (failure != null) {
      setState(() {
        _busy = false;
        _feedback = failure;
      });
      return;
    }
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final p = VigiaColors.of(context);
    final fill = p.brightness == Brightness.dark
        ? p.surfaceStrong
        : VigiaBrand.neutral;
    final delete = widget.action == AccountAction.delete;
    final (title, description, label, busyLabel) = switch (widget.action) {
      AccountAction.email => (
        'Cambiar correo',
        'Te enviaremos un enlace al correo nuevo. Tu correo cambia cuando lo '
            'abras.',
        'Enviar enlace',
        'Enviando enlace…',
      ),
      AccountAction.password => (
        'Cambiar contraseña',
        'Confirma tu contraseña actual y elige una nueva.',
        'Guardar contraseña',
        'Guardando…',
      ),
      AccountAction.delete => (
        'Eliminar cuenta',
        'Se eliminan tu cuenta y los resúmenes guardados en la nube. Los '
            'registros de este teléfono no se borran. No se puede deshacer.',
        'Eliminar cuenta',
        'Eliminando cuenta…',
      ),
    };

    Widget passwordField({
      required String label,
      required TextEditingController controller,
      required String? error,
      required String hint,
      required bool isNew,
      required VoidCallback onEdit,
    }) => AccountField(
      label: label,
      field: TextField(
        controller: controller,
        enabled: !_busy,
        obscureText: _obscure,
        autocorrect: false,
        enableSuggestions: false,
        autofillHints: [
          isNew ? AutofillHints.newPassword : AutofillHints.password,
        ],
        textInputAction: TextInputAction.done,
        decoration: accountFieldDecoration(
          context,
          label: label,
          hint: hint,
          error: error,
          fillColor: fill,
          icon: VigiaIcon.lock,
          suffix: IconButton(
            tooltip: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
            onPressed: () => setState(() => _obscure = !_obscure),
            icon: VigiaIconView(
              _obscure ? VigiaIcon.eye : VigiaIcon.eyeOff,
              size: 22,
              color: p.inkSecondary,
            ),
          ),
        ),
        onChanged: (_) => setState(onEdit),
        onSubmitted: (_) => _submit(),
      ),
    );

    return PopScope(
      canPop: !_busy,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            VigiaSpace.screenH,
            12,
            VigiaSpace.screenH,
            24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 14,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: p.control,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Semantics(
                header: true,
                child: VigiaText(
                  title,
                  style: VigiaType.heroTitle(28).copyWith(color: p.ink),
                ),
              ),
              VigiaText(
                description,
                style: VigiaType.body.copyWith(
                  color: delete ? p.errorInk : p.inkSecondary,
                ),
              ),
              if (widget.action == AccountAction.email)
                AccountField(
                  label: 'Correo nuevo',
                  field: TextField(
                    controller: _email,
                    enabled: !_busy,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    autofillHints: const [AutofillHints.email],
                    decoration: accountFieldDecoration(
                      context,
                      label: 'Correo nuevo',
                      hint: 'nuevo@correo.com',
                      error: _fieldError,
                      fillColor: fill,
                      icon: VigiaIcon.mail,
                    ),
                    onChanged: (_) {
                      if (_fieldError != null) {
                        setState(() => _fieldError = null);
                      }
                    },
                  ),
                ),
              passwordField(
                label: 'Contraseña actual',
                controller: _current,
                error: _currentError,
                hint: 'Tu contraseña actual',
                isNew: false,
                onEdit: () => _currentError = null,
              ),
              if (widget.action == AccountAction.password) ...[
                passwordField(
                  label: 'Contraseña nueva',
                  controller: _next,
                  error: _fieldError,
                  hint: 'Crea una contraseña',
                  isNew: true,
                  onEdit: () => _fieldError = null,
                ),
                PasswordChecklist(password: _next.text),
              ],
              if (_feedback case final feedback?)
                Semantics(
                  liveRegion: true,
                  child: VigiaText(
                    feedback,
                    style: VigiaType.body.copyWith(color: p.errorInk),
                  ),
                ),
              VigiaButton(
                key: const ValueKey('account-action-submit'),
                label: _busy ? busyLabel : label,
                loading: _busy,
                onPressed: _busy ? null : _submit,
              ),
              VigiaButton(
                key: const ValueKey('account-action-cancel'),
                label: 'Cancelar',
                kind: VigiaButtonKind.secondary,
                quietDisabled: _busy,
                onPressed: _busy ? null : () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
