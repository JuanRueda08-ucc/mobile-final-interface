import 'package:flutter/material.dart';

import '../../../core/design_system/theme.dart';
import '../../../core/design_system/tokens.dart';
import '../../../core/design_system/vigia_icons.dart';
import '../../../core/design_system/widgets/vigia_text.dart';

/// Requisitos de la contraseña al crear la cuenta (usuario, 2026-11-16):
/// al menos 8 caracteres, una mayúscula, un número y un símbolo.
///
/// El cliente los comprueba antes de enviar. Para que Firebase también los
/// exija, hay que activar la política de contraseñas del proyecto en la
/// consola (Authentication › Configuración › Política de contraseñas).
abstract final class PasswordRules {
  static const minLength = 8;

  static final _upper = RegExp(r'[A-ZÁÉÍÓÚÑÜ]');
  static final _digit = RegExp(r'[0-9]');
  static final _symbol = RegExp(r'[^A-Za-z0-9ÁÉÍÓÚÑÜáéíóúñü\s]');

  /// Cada requisito con su texto y si [password] lo cumple, en orden.
  static List<(String, bool)> check(String password) => [
    ('Al menos $minLength caracteres', password.length >= minLength),
    ('Una letra mayúscula', _upper.hasMatch(password)),
    ('Un número', _digit.hasMatch(password)),
    ('Un símbolo, como ! @ # \$ ?', _symbol.hasMatch(password)),
  ];

  static bool allMet(String password) => check(password).every((r) => r.$2);
}

/// Lista de requisitos bajo el campo de contraseña del registro. Cada
/// requisito se marca al cumplirse mientras se escribe.
class PasswordChecklist extends StatelessWidget {
  const PasswordChecklist({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final p = VigiaColors.of(context);
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      container: true,
      label: 'Requisitos de la contraseña',
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: 4),
        child: Column(
          key: const Key('password-checklist'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 6,
          children: [
            for (final (text, ok) in PasswordRules.check(password))
              MergeSemantics(
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: reduce
                          ? Duration.zero
                          : VigiaMotion.colorDuration,
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ok ? p.ink : Colors.transparent,
                        border: Border.all(
                          color: ok ? p.ink : p.control,
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: ok
                          ? VigiaIconView(
                              VigiaIcon.check,
                              size: 14,
                              color: p.bg,
                              strokeWidth: 2.4,
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Semantics(
                        label: ok ? 'Cumplido' : 'Pendiente',
                        child: VigiaText(
                          text,
                          style: VigiaType.small.copyWith(
                            color: ok ? p.ink : p.inkSecondary,
                          ),
                        ),
                      ),
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
