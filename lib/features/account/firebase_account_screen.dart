import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/theme.dart';
import '../../core/design_system/tokens.dart';
import '../../core/design_system/widgets/vigia_blocks.dart';
import '../../core/design_system/widgets/vigia_button.dart';
import 'firebase_account.dart';
import 'presentation/account_form.dart';

class FirebaseAccountScreen extends ConsumerStatefulWidget {
  const FirebaseAccountScreen({super.key});

  @override
  ConsumerState<FirebaseAccountScreen> createState() =>
      _FirebaseAccountScreenState();
}

enum _FormMode { signIn, register, reset }

class _FirebaseAccountScreenState extends ConsumerState<FirebaseAccountScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _feedbackKey = GlobalKey();
  _FormMode _mode = _FormMode.signIn;
  bool _busy = false;
  String? _feedback;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<String?> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _feedback = null;
    });
    String? feedback;
    try {
      feedback = await action();
    } on FirebaseAuthException catch (error) {
      feedback = switch (error.code) {
        'invalid-email' => 'Escribe un correo válido.',
        'weak-password' => 'Elige una contraseña más larga.',
        'invalid-credential' ||
        'user-not-found' ||
        'wrong-password' => 'Comprueba tu correo y contraseña.',
        'network-request-failed' =>
          'Comprueba tu conexión y vuelve a intentar.',
        'too-many-requests' =>
          'Espera unos minutos antes de volver a intentar.',
        'email-already-in-use' =>
          'Si ya tienes cuenta, inicia sesión o restablece tu contraseña.',
        _ => 'No se pudo completar la solicitud. Vuelve a intentar.',
      };
    } catch (_) {
      feedback = 'No se pudo completar la solicitud. Vuelve a intentar.';
    }
    if (!mounted) return;
    setState(() {
      _feedback = feedback;
      _busy = false;
    });
    if (feedback != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_feedbackKey.currentContext case final feedbackContext?) {
          Scrollable.ensureVisible(feedbackContext, alignment: 0.5);
        }
      });
    }
  }

  void _submitForm(FirebaseAuth auth) {
    if (_busy) return;
    final email = _email.text.trim();
    final password = _password.text;
    setState(() {
      _feedback = null;
      _emailError = email.isEmpty ? 'Escribe tu correo.' : null;
      _passwordError = switch (_mode) {
        _FormMode.reset => null,
        _ when password.isEmpty => 'Escribe tu contraseña.',
        _FormMode.register when password.length < 8 =>
          'Usa al menos 8 caracteres.',
        _ => null,
      };
    });
    if (_emailError != null || _passwordError != null) return;
    FocusScope.of(context).unfocus();
    _run(() => _submit(auth, email, password));
  }

  Future<String?> _submit(
    FirebaseAuth auth,
    String email,
    String password,
  ) async {
    switch (_mode) {
      case _FormMode.signIn:
        await auth.signInWithEmailAndPassword(email: email, password: password);
        break;
      case _FormMode.register:
        final result = await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        await result.user!.sendEmailVerification();
        break;
      case _FormMode.reset:
        try {
          await auth.sendPasswordResetEmail(email: email);
        } on FirebaseAuthException catch (error) {
          if (error.code != 'user-not-found') rethrow;
        }
        return 'Si el correo tiene una cuenta, recibirás un enlace.';
    }
    if (mounted) _password.clear();
    return null;
  }

  Future<String?> _signOut(FirebaseAuth auth) async {
    final feedback = await signOutOfVigia(ref, auth);
    if (feedback == null && mounted) {
      _mode = _FormMode.signIn;
      _email.clear();
      _password.clear();
    }
    return feedback;
  }

  VigiaButton _button(
    String label,
    VoidCallback action, {
    bool secondary = false,
  }) => VigiaButton(
    label: label,
    kind: secondary ? VigiaButtonKind.secondary : VigiaButtonKind.primary,
    onPressed: _busy ? null : action,
  );

  void _changeMode(_FormMode mode) {
    FocusScope.of(context).unfocus();
    setState(() {
      _mode = mode;
      _password.clear();
      _feedback = null;
      _emailError = null;
      _passwordError = null;
    });
  }

  Widget _modeLink(String label, _FormMode mode) {
    final p = VigiaColors.of(context);
    return TextButton(
      onPressed: _busy ? null : () => _changeMode(mode),
      style: TextButton.styleFrom(
        foregroundColor: p.ink,
        disabledForegroundColor: p.inkSecondary,
        alignment: AlignmentDirectional.centerStart,
        textStyle: VigiaType.button,
        minimumSize: const Size(VigiaSpace.minTap, VigiaSpace.minTap),
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VigiaRadius.tag),
        ),
      ),
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(firebaseAuthProvider);
    final authState = ref.watch(firebaseUserProvider);
    final user = authState.asData?.value;
    final feedback = _feedback;
    final Widget? message = feedback == null
        ? null
        : Semantics(
            key: _feedbackKey,
            liveRegion: true,
            child: VigiaParagraph(feedback),
          );

    if (auth == null || authState.isLoading || authState.hasError) {
      final failed = authState.hasError;
      return AccountForm(
        title: 'Cuenta de Vigía',
        description: failed
            ? 'No se pudo comprobar tu sesión.'
            : 'Comprobando tu sesión…',
        action: VigiaButton(
          label: failed ? 'Reintentar' : 'Cargando…',
          onPressed: failed ? () => ref.invalidate(firebaseUserProvider) : null,
        ),
        children: const [],
      );
    }
    if (user != null) {
      return AccountForm(
        title: 'Verifica tu correo',
        description: 'Abre el enlace de verificación en tu correo. Después, vuelve a Vigía.',
        detail: user.email,
        isBusy: _busy,
        action: _button(
          'Ya verifiqué mi correo',
          () => _run(() async {
            await user.reload();
            final current = auth.currentUser;
            if (current?.emailVerified == true) {
              await current!.getIdToken(true);
              return null;
            }
            return 'La verificación sigue pendiente.';
          }),
        ),
        children: [
          ?message,
          _button(
            'Reenviar correo',
            () => _run(() async {
              await user.sendEmailVerification();
              return 'Enviamos un nuevo enlace.';
            }),
            secondary: true,
          ),
          _button(
            'Usar otro correo',
            () => _run(() => _signOut(auth)),
            secondary: true,
          ),
        ],
      );
    }

    final (title, description, label, busyLabel) = switch (_mode) {
      _FormMode.signIn => (
        'Inicia sesión',
        'Accede a tu historial de sesiones.',
        'Iniciar sesión',
        'Iniciando sesión…',
      ),
      _FormMode.register => (
        'Crea tu cuenta',
        'Te enviaremos un enlace para verificar tu correo.',
        'Crear cuenta',
        'Creando cuenta…',
      ),
      _FormMode.reset => (
        'Recupera tu contraseña',
        'Te enviaremos un enlace para restablecerla.',
        'Enviar enlace',
        'Enviando enlace…',
      ),
    };
    return AccountForm(
      title: title,
      description: description,
      accessCover: _mode != _FormMode.reset,
      isBusy: _busy,
      action: _button(_busy ? busyLabel : label, () => _submitForm(auth)),
      children: [
        AutofillGroup(
          child: Column(
            spacing: 12,
            children: [
              TextField(
                controller: _email,
                enabled: !_busy,
                keyboardType: TextInputType.emailAddress,
                textInputAction: _mode == _FormMode.reset
                    ? TextInputAction.done
                    : TextInputAction.next,
                autocorrect: false,
                autofillHints: const [AutofillHints.email],
                decoration: accountFieldDecoration(
                  context,
                  label: 'Correo',
                  error: _emailError,
                ),
                onChanged: (_) {
                  if (_emailError != null) setState(() => _emailError = null);
                },
                onSubmitted: _mode == _FormMode.reset
                    ? (_) => _submitForm(auth)
                    : null,
              ),
              if (_mode != _FormMode.reset)
                TextField(
                  controller: _password,
                  enabled: !_busy,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  enableSuggestions: false,
                  autofillHints: [
                    _mode == _FormMode.register
                        ? AutofillHints.newPassword
                        : AutofillHints.password,
                  ],
                  decoration: accountFieldDecoration(
                    context,
                    label: 'Contraseña',
                    error: _passwordError,
                  ),
                  onChanged: (_) {
                    if (_passwordError != null) {
                      setState(() => _passwordError = null);
                    }
                  },
                  onSubmitted: (_) => _submitForm(auth),
                ),
            ],
          ),
        ),
        ?message,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _mode == _FormMode.signIn
              ? [
                  _modeLink('Crear cuenta', _FormMode.register),
                  _modeLink('Olvidé mi contraseña', _FormMode.reset),
                ]
              : [_modeLink('Volver al acceso', _FormMode.signIn)],
        ),
      ],
    );
  }
}
