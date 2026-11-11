import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monitoring_engine/monitoring_engine.dart';

import '../../app/router.dart';
import '../../core/design_system/widgets/vigia_blocks.dart';
import '../../core/design_system/widgets/vigia_button.dart';
import '../experimental/experimental_monitoring_controller.dart';
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

  Future<String?> _submit(FirebaseAuth auth) async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty) return 'Escribe tu correo.';
    if (_mode != _FormMode.reset && password.isEmpty) {
      return 'Escribe tu contraseña.';
    }
    switch (_mode) {
      case _FormMode.signIn:
        await auth.signInWithEmailAndPassword(email: email, password: password);
        break;
      case _FormMode.register:
        if (password.length < 8) return 'Usa al menos 8 caracteres.';
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
    final state = ref.read(experimentalMonitoringProvider);
    if (state.sessionVigente || state.pending != null) {
      return 'Finaliza el monitoreo antes de cerrar sesión.';
    }
    final snapshot = await ref
        .read(experimentalMonitoringProvider.notifier)
        .queryCurrentSnapshot();
    if (snapshot.lifecycle == EngineSessionLifecycle.active ||
        snapshot.lifecycle == EngineSessionLifecycle.paused ||
        (mounted && ref.read(experimentalMonitoringProvider).pending != null)) {
      return 'Finaliza el monitoreo antes de cerrar sesión.';
    }
    if (!mounted) return null;
    await auth.signOut();
    if (mounted) {
      _mode = _FormMode.signIn;
      _email.clear();
      _password.clear();
    }
    return null;
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

  void _changeMode(_FormMode mode) => setState(() {
    _mode = mode;
    _password.clear();
    _feedback = null;
  });

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(firebaseAuthProvider);
    final authState = ref.watch(firebaseUserProvider);
    final user = authState.asData?.value;
    final verified = user?.emailVerified == true;
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
      void back() => context.go(VigiaRoutes.ajustes);
      return AccountForm(
        title: verified ? 'Tu cuenta' : 'Verifica tu correo',
        description: verified
            ? 'Los resúmenes de las sesiones experimentales se guardan en tu cuenta.'
            : 'Abre el enlace de verificación en tu correo. Después, vuelve a Vigía.',
        detail: user.email,
        onBack: verified ? back : null,
        isBusy: _busy,
        action: verified
            ? _button('Cerrar sesión', () => _run(() => _signOut(auth)))
            : _button(
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
          if (!verified) ...[
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
        ],
      );
    }

    final (title, description, label) = switch (_mode) {
      _FormMode.signIn => (
        'Inicia sesión',
        'Consulta tu historial.',
        'Iniciar sesión',
      ),
      _FormMode.register => (
        'Crea tu cuenta',
        'Usa al menos 8 caracteres en la contraseña.',
        'Crear cuenta',
      ),
      _FormMode.reset => (
        'Recupera tu contraseña',
        'Te enviaremos un enlace para restablecerla.',
        'Enviar enlace',
      ),
    };
    return AccountForm(
      title: title,
      description: description,
      isBusy: _busy,
      action: _button(
        _busy ? 'Un momento…' : label,
        () => _run(() => _submit(auth)),
      ),
      children: [
        AutofillGroup(
          child: Column(
            spacing: 12,
            children: [
              TextField(
                controller: _email,
                enabled: !_busy,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: accountFieldDecoration(context, label: 'Correo'),
              ),
              if (_mode != _FormMode.reset)
                TextField(
                  controller: _password,
                  enabled: !_busy,
                  obscureText: true,
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
                  ),
                  onSubmitted: (_) => _run(() => _submit(auth)),
                ),
            ],
          ),
        ),
        ?message,
        if (_mode == _FormMode.signIn) ...[
          _button(
            'Crear cuenta',
            () => _changeMode(_FormMode.register),
            secondary: true,
          ),
          _button(
            'Olvidé mi contraseña',
            () => _changeMode(_FormMode.reset),
            secondary: true,
          ),
        ] else
          _button(
            'Volver al acceso',
            () => _changeMode(_FormMode.signIn),
            secondary: true,
          ),
      ],
    );
  }
}
