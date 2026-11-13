import 'package:flutter/material.dart';

import '../../../core/design_system/theme.dart';
import '../../../core/design_system/tokens.dart';
import '../../../core/design_system/widgets/vigia_button.dart';
import '../../../core/design_system/widgets/vigia_text.dart';
import 'welcome_eyes.dart';

/// P01 · Bienvenida previa al acceso de la variante normal.
///
/// Muestra el nombre de Vigía a todo el ancho, una ilustración con ojos que
/// miran y parpadean ([WelcomeEyes]), y un panel con la finalidad, el
/// procesamiento local, los datos guardados y las acciones «Crear cuenta» e
/// «Iniciar sesión». No solicita cámara ni comienza captura (UX02 §3).
class AccountWelcome extends StatelessWidget {
  const AccountWelcome({
    super.key,
    required this.onRegister,
    required this.onSignIn,
  });

  final VoidCallback onRegister;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final p = VigiaColors.of(context);
    final dark = p.brightness == Brightness.dark;
    final large = isLargeText(context);
    final brandInk = dark ? VigiaBrand.wordmarkDark : VigiaBrand.wordmarkLight;
    final media = MediaQuery.of(context);
    final secondary = VigiaAura.screenSecondary(p.brightness);

    final wordmark = Padding(
      padding: EdgeInsets.fromLTRB(14, media.padding.top + 18, 14, 0),
      child: Semantics(
        header: true,
        label: 'Vigía',
        child: ExcludeSemantics(
          child: FittedBox(
            fit: BoxFit.fitWidth,
            child: Text(
              'Vigía',
              textScaler: TextScaler.noScaling,
              style: VigiaType.heroTitle(120)
                  .copyWith(color: brandInk, height: 1.05, letterSpacing: -4),
            ),
          ),
        ),
      ),
    );

    final panelColor = dark ? p.surface : VigiaBrand.neutral;
    final side = large ? 16.0 : 24.0;
    final purpose = [
      VigiaText(
        '¿Listo para comenzar?',
        textAlign: TextAlign.center,
        style: VigiaType.h1.copyWith(color: p.ink, fontSize: 26),
      ),
      const SizedBox(height: 8),
      VigiaText(
        'Vigía te acompaña en cada trayecto y te avisa si '
        'empiezas a cerrar los ojos.',
        textAlign: TextAlign.center,
        style: VigiaType.body.copyWith(color: p.ink),
      ),
      const SizedBox(height: 8),
      VigiaText(
        'Todo ocurre en tu teléfono. Solo se guardan los resúmenes de tus '
        'sesiones.',
        textAlign: TextAlign.center,
        style: VigiaType.small.copyWith(color: secondary),
      ),
    ];
    final trial = VigiaText(
      'Versión de prueba. No es una ayuda validada para conducir.',
      textAlign: TextAlign.center,
      style: VigiaType.small.copyWith(color: secondary, fontSize: 12.5),
    );
    final actions = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        VigiaButton(label: 'Crear cuenta', onPressed: onRegister),
        VigiaButton(
          label: 'Iniciar sesión',
          kind: VigiaButtonKind.secondary,
          onPressed: onSignIn,
        ),
      ],
    );
    const sheet = BorderRadius.vertical(top: Radius.circular(32));

    return Scaffold(
      backgroundColor: dark ? p.surface : VigiaBrand.neutral,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: dark
                ? [
                    p.bg,
                    Color.alphaBlend(
                      VigiaBrand.mistBlue.withValues(alpha: 0.16),
                      p.bg,
                    ),
                  ]
                : [
                    Color.alphaBlend(
                      VigiaBrand.lavender.withValues(alpha: 0.18),
                      Colors.white,
                    ),
                    Color.alphaBlend(
                      VigiaBrand.mistBlue.withValues(alpha: 0.42),
                      Colors.white,
                    ),
                  ],
          ),
        ),
        // Pantalla alta: la ilustración ocupa el espacio libre. Texto ampliado
        // o pantalla baja: todo se desplaza y la ilustración tiene alto fijo.
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (!large && constraints.maxHeight >= 680) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  wordmark,
                  const Expanded(child: WelcomeEyes()),
                  Container(
                    decoration: BoxDecoration(
                      color: panelColor,
                      borderRadius: sheet,
                    ),
                    padding: EdgeInsets.fromLTRB(
                      side,
                      28,
                      side,
                      media.padding.bottom + 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ...purpose,
                        const SizedBox(height: 22),
                        actions,
                        const SizedBox(height: 14),
                        trial,
                      ],
                    ),
                  ),
                ],
              );
            }
            // Las acciones quedan fijas abajo; el resto se desplaza.
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    key: const Key('welcome-scroll'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        wordmark,
                        const SizedBox(height: 230, child: WelcomeEyes()),
                        Container(
                          decoration: BoxDecoration(
                            color: panelColor,
                            borderRadius: sheet,
                          ),
                          padding: EdgeInsets.fromLTRB(side, 24, side, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ...purpose,
                              const SizedBox(height: 12),
                              trial,
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ColoredBox(
                  color: panelColor,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      side,
                      8,
                      side,
                      media.padding.bottom + 12,
                    ),
                    child: actions,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
