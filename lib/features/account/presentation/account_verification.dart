import 'package:flutter/material.dart';

import '../../../core/design_system/theme.dart';
import '../../../core/design_system/tokens.dart';
import '../../../core/design_system/vigia_icons.dart';
import '../../../core/design_system/widgets/motion.dart';
import '../../../core/design_system/widgets/screen_aura.dart';
import '../../../core/design_system/widgets/vigia_button.dart';
import '../../../core/design_system/widgets/vigia_scaffold.dart';
import '../../../core/design_system/widgets/vigia_text.dart';
import 'account_form.dart';

/// Verificación del correo tras el registro (rediseño, 2026-11-15).
///
/// Insignia de correo, el correo destacado, tres pasos y las acciones:
/// «Ya verifiqué mi correo» abajo y, en la tarjeta, reenviar o cambiar de
/// correo.
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
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: PulseOnce(
                trigger: email,
                times: 2,
                child: AccountBadge(
                  icon: VigiaIcon.mail,
                  size: large ? 52 : 64,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              header: true,
              child: VigiaText(
                'Verifica tu correo',
                style: VigiaType.heroTitle(large ? 30 : 40)
                    .copyWith(color: p.ink),
              ),
            ),
            const SizedBox(height: 10),
            VigiaText(
              'Te enviamos un enlace de verificación a:',
              style: VigiaType.body.copyWith(color: secondary),
            ),
            if (email case final email?) ...[
              const SizedBox(height: 10),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Container(
                  key: const Key('verification-email'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: p.brightness == Brightness.dark
                        ? p.surfaceStrong
                        : Colors.white,
                    borderRadius: BorderRadius.circular(VigiaRadius.tag),
                    border: Border.all(color: p.line),
                  ),
                  child: VigiaText(
                    email,
                    style: VigiaType.kvValue.copyWith(color: p.ink),
                  ),
                ),
              ),
            ],
          ],
        ),
        AccountCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 14,
            children: [
              const _Step(1, 'Abre el correo de Vigía.'),
              const _Step(2, 'Toca el enlace de verificación.'),
              const _Step(3, 'Vuelve y pulsa «Ya verifiqué».'),
              VigiaText(
                '¿No llega? Revisa la carpeta de spam o reenvíalo.',
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: VigiaText(
              text,
              style: VigiaType.body.copyWith(color: p.ink),
            ),
          ),
        ),
      ],
    );
  }
}
