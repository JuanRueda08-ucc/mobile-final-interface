import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/design_system/theme.dart';
import '../../../core/design_system/tokens.dart';
import '../../../core/design_system/vigia_icons.dart';
import '../../../core/design_system/widgets/screen_aura.dart';
import '../../../core/design_system/widgets/vigia_button.dart';
import '../../../core/design_system/widgets/vigia_mark.dart';
import '../../../core/design_system/widgets/vigia_text.dart';

/// P01 · Bienvenida previa al acceso de la variante normal.
///
/// Presenta Vigía, su finalidad, el procesamiento local y los datos que se
/// guardan, con las acciones «Crear cuenta» e «Iniciar sesión». No solicita
/// cámara ni comienza captura (UX02 §3).
///
/// Animación de entrada única (1,6 s): halo y marca, parpadeo del símbolo y
/// aparición escalonada del texto y las acciones. Con movimiento reducido
/// todo aparece en su estado final, sin animación.
class AccountWelcome extends StatefulWidget {
  const AccountWelcome({
    super.key,
    required this.onRegister,
    required this.onSignIn,
  });

  final VoidCallback onRegister;
  final VoidCallback onSignIn;

  static const features = [
    (
      VigiaIcon.eyeClosed,
      'Atiende tus ojos',
      'Mide en el teléfono si tus ojos se cierran demasiado tiempo y '
          'suena un aviso.',
    ),
    (
      VigiaIcon.lock,
      'Procesado en tu teléfono',
      'La cámara y el análisis no salen del dispositivo. No se guardan '
          'imágenes ni video.',
    ),
    (
      VigiaIcon.history,
      'Historial en tu cuenta',
      'Solo se sincronizan los resúmenes de tus sesiones.',
    ),
  ];

  @override
  State<AccountWelcome> createState() => _AccountWelcomeState();
}

class _AccountWelcomeState extends State<AccountWelcome>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else if (!_started) {
      _started = true;
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Aparición escalonada: el elemento [index] entra con opacidad y un
  /// desplazamiento vertical corto.
  Widget _reveal(int index, Widget child) {
    final start = math.min(0.12 + 0.07 * index, 0.6);
    final a = CurvedAnimation(
      parent: _c,
      curve: Interval(
        start,
        math.min(start + 0.4, 1),
        curve: VigiaMotion.press,
      ),
    );
    return AnimatedBuilder(
      animation: a,
      child: child,
      builder: (context, child) => Opacity(
        opacity: a.value,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - a.value)),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = VigiaColors.of(context);
    final dark = p.brightness == Brightness.dark;
    final large = isLargeText(context);
    final brandInk = dark ? VigiaBrand.wordmarkDark : VigiaBrand.wordmarkLight;
    final inset = large ? 16.0 : 24.0;
    var i = 0;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WelcomeMark(animation: _c),
        SizedBox(height: large ? 20 : 28),
        _reveal(
          i++,
          Semantics(
            header: true,
            child: VigiaText(
              'Vigía',
              style: VigiaType.heroTitle(large ? 40 : 56)
                  .copyWith(color: brandInk),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _reveal(
          i++,
          VigiaText(
            'Te avisa con un tono cuando tus ojos permanecen cerrados '
            'demasiado tiempo mientras conduces.',
            style: VigiaType.body.copyWith(
              fontSize: large ? 16 : 18,
              height: 1.4,
              color: VigiaAura.screenSecondary(p.brightness),
            ),
          ),
        ),
        SizedBox(height: large ? 20 : 28),
        for (final (icon, title, text) in AccountWelcome.features) ...[
          _reveal(i++, _FeatureRow(icon: icon, title: title, text: text)),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 4),
        _reveal(
          i++,
          VigiaText(
            'Versión de prueba. No es una ayuda validada para conducir.',
            style: VigiaType.small.copyWith(
              color: VigiaAura.screenSecondary(p.brightness),
            ),
          ),
        ),
      ],
    );
    final actions = _reveal(
      i++,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          VigiaButton(label: 'Crear cuenta', onPressed: widget.onRegister),
          VigiaButton(
            label: 'Iniciar sesión',
            kind: VigiaButtonKind.secondary,
            onPressed: widget.onSignIn,
          ),
        ],
      ),
    );
    return Scaffold(
      backgroundColor: p.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const IgnorePointer(child: ScreenAura()),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    key: const Key('welcome-scroll'),
                    padding: EdgeInsets.fromLTRB(inset, 32, inset, 16),
                    child: content,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(inset, 8, inset, 16),
                  child: actions,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Símbolo de Vigía sobre un halo pastel. Entra con escala y opacidad y
/// parpadea una vez (el ojo se cierra y se abre) al final de la entrada.
class _WelcomeMark extends StatelessWidget {
  const _WelcomeMark({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final enter = CurvedAnimation(
      parent: animation,
      curve: const Interval(0, 0.45, curve: VigiaMotion.press),
    );
    final blink = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.64, 0.84, curve: Curves.easeInOut),
    );
    final glow = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.2, 1, curve: Curves.easeOut),
    );
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final squash = 1 - 0.88 * math.sin(math.pi * blink.value);
          return Opacity(
            opacity: enter.value,
            child: Transform.scale(
              scale: 0.7 + 0.3 * enter.value,
              alignment: Alignment.centerLeft,
              child: Container(
                width: 104,
                height: 104,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      VigiaBrand.lavender,
                      VigiaBrand.mistBlue,
                      VigiaBrand.softGreen,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: VigiaBrand.lavender.withValues(
                        alpha: 0.55 * glow.value,
                      ),
                      blurRadius: 12 + 28 * glow.value,
                      spreadRadius: 2 + 6 * glow.value,
                    ),
                  ],
                ),
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.diagonal3Values(1, squash, 1),
                  child: const VigiaMark(size: 60, ink: VigiaBrand.ink),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.text,
  });

  final VigiaIcon icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = VigiaColors.of(context);
    final dark = p.brightness == Brightness.dark;
    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.surface.withValues(alpha: dark ? 0.72 : 0.78),
          borderRadius: BorderRadius.circular(VigiaRadius.tag + 6),
          border: Border.all(color: p.line.withValues(alpha: 0.6)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 14,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: VigiaBrand.lavender.withValues(alpha: dark ? 0.32 : 0.5),
              ),
              child: VigiaIconView(icon, size: 22, color: p.ink),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  VigiaText(
                    title,
                    style: VigiaType.indicator.copyWith(color: p.ink),
                  ),
                  VigiaText(
                    text,
                    style: VigiaType.small.copyWith(color: p.inkSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
