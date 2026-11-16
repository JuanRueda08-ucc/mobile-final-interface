import 'package:flutter/material.dart';

import '../../../core/design_system/theme.dart';
import '../../../core/design_system/tokens.dart';
import '../../../core/design_system/widgets/screen_aura.dart';
import '../../../core/design_system/widgets/vigia_button.dart';
import '../../../core/design_system/widgets/vigia_scaffold.dart';
import '../../../core/design_system/widgets/vigia_text.dart';
import 'account_form.dart';

/// Verificación del correo tras el registro (rediseño, 2026-11-15).
///
/// Solo texto: título, el correo destacado y una tarjeta compacta con tres
/// pasos y las acciones de reenviar o cambiar de correo. «Ya verifiqué mi
/// correo» queda fijo abajo. Cabe sin desplazarse en un teléfono normal.
class AccountVerification extends StatelessWidget {
  const AccountVerification({
    super.key,
    required this.email,
    required this.confirm,
    required this.resend,
    required this.useOther,
    this.message,
  });

  final String? email;
  final VigiaButton confirm;
  final VigiaButton resend;
  final VigiaButton useOther;
  final Widget? message;

  @override
  Widget build(BuildContext context) {
    final p = VigiaColors.of(context);
    final large = isLargeText(context);
    final secondary = VigiaAura.screenSecondary(p.brightness);
    return VigiaScaffold(
      title: 'Vigía',
      showBrandMark: true,
      background: const ScreenAura(),
      footer: Semantics(container: true, child: confirm),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: VigiaText(
                'Verifica tu correo',
                style: VigiaType.heroTitle(large ? 30 : 36)
                    .copyWith(color: p.ink),
              ),
            ),
            const SizedBox(height: 8),
            VigiaText(
              'Te enviamos un enlace de verificación a:',
              style: VigiaType.body.copyWith(color: secondary),
            ),
            if (email case final email?) ...[
              const SizedBox(height: 4),
              VigiaText(
                email,
                key: const Key('verification-email'),
                style: VigiaType.indicator.copyWith(
                  color: p.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
        AccountCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              const _Step(1, 'Abre el correo de Vigía.'),
              const _Step(2, 'Toca el enlace de verificación.'),
              const _Step(3, 'Vuelve y pulsa «Ya verifiqué».'),
              Divider(height: 8, color: p.line),
              VigiaText(
                '¿No llega? Revisa la carpeta de spam.',
                style: VigiaType.small.copyWith(color: p.inkSecondary),
              ),
              ?message,
              resend,
              useOther,
            ],
          ),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step(this.number, this.text);

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = VigiaColors.of(context);
    // Número y texto centrados en la misma línea.
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: VigiaBrand.lavender,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            textScaler: TextScaler.noScaling,
            style: VigiaType.smallIndicator.copyWith(
              color: VigiaBrand.wordmarkLight,
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: VigiaText(text, style: VigiaType.body.copyWith(color: p.ink)),
        ),
      ],
    );
  }
}
