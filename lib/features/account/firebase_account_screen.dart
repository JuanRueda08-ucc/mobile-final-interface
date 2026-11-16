import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/theme.dart';
import '../../core/design_system/tokens.dart';
import '../../core/design_system/vigia_icons.dart';
import '../../core/design_system/widgets/vigia_blocks.dart';
import '../../core/design_system/widgets/vigia_button.dart';
import 'firebase_account.dart';
import 'presentation/account_form.dart';
import 'presentation/account_verification.dart';
import 'presentation/password_rules.dart';
import 'presentation/account_welcome.dart';

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
  // P01: sin sesión, la bienvenida precede a los formularios de acceso.
  bool _welcome = true;
  bool _busy = false;

  /// Botón cuya operación está en curso: muestra el progreso; los demás se
  /// atenúan sin el borde discontinuo (rediseño del acceso, 2026-11-15).
  String? _active;
  bool _obscure = true;
  String? _feedback;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(String id, Future<String?> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _active = id;
      _feedback = null;
    });
    String? feedback;
    try {
      feedback = await action();
    } on FirebaseAuthException catch (error) {
      feedback = switch (error.code) {
        'invalid-email' => 'Escribe un correo válido.',
        'weak-password' || 'password-does-not-meet-requirements' =>
          'La contraseña no cumple todos los requisitos.',
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
      _active = null;
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
        _FormMode.register when !PasswordRules.allMet(password) =>
          'La contraseña no cumple todos los requisitos.',
        _ => null,
      };
    });
    if (_emailError != null || _passwordError != null) return;
    FocusScope.of(context).unfocus();
    _run('submit', () => _submit(auth, email, password));
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
      _welcome = true;
      _email.clear();
      _password.clear();
    }
    return feedback;
  }

  VigiaButton _button(
    String label,
    VoidCallback action, {
    required String id,
    bool secondary = false,
  }) => VigiaButton(
    key: ValueKey('account-$id'),
    label: label,
    kind: secondary ? VigiaButtonKind.secondary : VigiaButtonKind.primary,
    loading: _busy && _active == id,
    quietDisabled: _busy,
    onPressed: _busy ? null : action,
  );

  void _changeMode(_FormMode mode) {
    FocusScope.of(context).unfocus();
    setState(() {
      _mode = mode;
      _welcome = false;
      _obscure = true;
      _password.clear();
      _feedback = null;
      _emailError = null;
      _passwordError = null;
    });
  }

  void _backToWelcome() {
    if (_busy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _welcome = true;
      _password.clear();
      _feedback = null;
      _emailError = null;
      _passwordError = null;
    });
  }

  /// Transición entre la bienvenida y los formularios: fundido con un leve
  /// desplazamiento. Sin animación con movimiento reducido.
  Widget _switch(Widget child) => AnimatedSwitcher(
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 320),
    switchInCurve: VigiaMotion.press,
    switchOutCurve: Curves.easeIn,
    transitionBuilder: (child, animation) => FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.03),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    ),
    child: child,
  );

  Widget _modeLink(String label, _FormMode mode, {bool quiet = false}) {
    final p = VigiaColors.of(context);
    return TextButton(
      onPressed: _busy ? null : () => _changeMode(mode),
      style: TextButton.styleFrom(
        foregroundColor: quiet ? p.inkSecondary : p.ink,
        disabledForegroundColor: p.inkSecondary,
        textStyle: VigiaType.secondaryButton.copyWith(
          fontWeight: quiet ? FontWeight.w500 : FontWeight.w700,
          decoration: quiet ? TextDecoration.underline : null,
        ),
        minimumSize: const Size(VigiaSpace.minTap, VigiaSpace.minTap),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VigiaRadius.tag),
        ),
      ),
      child: Text(label),
    );
  }

  /// Enlace fijo abajo: cambiar entre acceso y registro (usuario,
  /// 2026-11-16: la pregunta encima y el enlace debajo).
  Widget _bottomLink() {
    final p = VigiaColors.of(context);
    Widget prompt(String text, Widget link) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: VigiaType.body.copyWith(color: p.inkSecondary),
        ),
        link,
      ],
    );
    return switch (_mode) {
      _FormMode.signIn => prompt(
        '¿No tienes cuenta?',
        _modeLink('Crear cuenta', _FormMode.register),
      ),
      _FormMode.register => prompt(
        '¿Ya tienes cuenta?',
        _modeLink('Inicia sesión', _FormMode.signIn),
      ),
      _FormMode.reset => Center(
        child: _modeLink('Volver al acceso', _FormMode.signIn),
      ),
    };
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
      return _switch(
        AccountVerification(
          key: const ValueKey('verify'),
          email: user.email,
          message: message,
          confirm: _button(
            'Ya verifiqué mi correo',
            id: 'verified',
            () => _run('verified', () async {
              await user.reload();
              final current = auth.currentUser;
              if (current?.emailVerified == true) {
                await current!.getIdToken(true);
                return null;
              }
              return 'La verificación sigue pendiente.';
            }),
          ),
          resend: _button(
            'Reenviar correo',
            id: 'resend',
            () => _run('resend', () async {
              await user.sendEmailVerification();
              return 'Enviamos un nuevo enlace.';
            }),
            secondary: true,
          ),
          useOther: _button(
            'Usar otro correo',
            id: 'other',
            () => _run('other', () => _signOut(auth)),
            secondary: true,
          ),
        ),
      );
    }

    if (_welcome) {
      return _switch(
        AccountWelcome(
          key: const ValueKey('welcome'),
          onRegister: () => _changeMode(_FormMode.register),
          onSignIn: () => _changeMode(_FormMode.signIn),
        ),
      );
    }

    final (title, description, label, busyLabel) = switch (_mode) {
      _FormMode.signIn => (
        'Inicia sesión',
        '',
        'Iniciar sesión',
        'Iniciando sesión…',
      ),
      _FormMode.register => (
        'Crea tu cuenta',
        '',
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
    final p = VigiaColors.of(context);
    final fieldSurface = p.brightness == Brightness.dark
        ? p.surfaceStrong
        : VigiaBrand.neutral;
    return _switch(
      PopScope(
        key: const ValueKey('form'),
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _backToWelcome();
        },
        child: AccountForm(
          title: title,
          onBack: _busy ? null : _backToWelcome,
          description: description,
          accessCover: true,
          isBusy: _busy,
          action: _button(
            _busy ? busyLabel : label,
            id: 'submit',
            () => _submitForm(auth),
          ),
          afterAction: _mode == _FormMode.signIn
              ? Center(
                  child: _modeLink(
                    'Olvidé mi contraseña',
                    _FormMode.reset,
                    quiet: true,
                  ),
                )
              : null,
          bottom: _bottomLink(),
          children: [
            AutofillGroup(
              child: Column(
                spacing: 14,
                children: [
                  AccountField(
                    label: 'Correo',
                    field: TextField(
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
                        hint: 'tu@correo.com',
                        error: _emailError,
                        fillColor: fieldSurface,
                        icon: VigiaIcon.mail,
                      ),
                      onChanged: (_) {
                        if (_emailError != null) {
                          setState(() => _emailError = null);
                        }
                      },
                      onSubmitted: _mode == _FormMode.reset
                          ? (_) => _submitForm(auth)
                          : null,
                    ),
                  ),
                  if (_mode != _FormMode.reset)
                    AccountField(
                      label: 'Contraseña',
                      field: TextField(
                        controller: _password,
                        enabled: !_busy,
                        obscureText: _obscure,
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
                          hint: _mode == _FormMode.register
                              ? 'Crea una contraseña'
                              : 'Tu contraseña',
                          error: _passwordError,
                          fillColor: fieldSurface,
                          icon: VigiaIcon.lock,
                          suffix: IconButton(
                            tooltip: _obscure
                                ? 'Mostrar contraseña'
                                : 'Ocultar contraseña',
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: VigiaIconView(
                              _obscure ? VigiaIcon.eye : VigiaIcon.eyeOff,
                              size: 22,
                              color: p.inkSecondary,
                            ),
                          ),
                        ),
                        // La lista de requisitos se actualiza al escribir.
                        onChanged: (_) => setState(() => _passwordError = null),
                        onSubmitted: (_) => _submitForm(auth),
                      ),
                    ),
                  if (_mode == _FormMode.register)
                    PasswordChecklist(password: _password.text),
                ],
              ),
            ),
            ?message,
          ],
        ),
      ),
    );
  }
}
