import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/design_system/vigia_icons.dart';
import '../../core/design_system/widgets/vigia_blocks.dart';
import '../../core/design_system/widgets/vigia_button.dart';
import '../../core/design_system/widgets/vigia_option.dart';
import '../../core/design_system/widgets/vigia_scaffold.dart';
import '../../data/demo_history/demo_history_repository.dart';
import '../monitoring/demo_session_controller.dart';
import 'preferences_controller.dart';

/// P12 · Ajustes (FL11, RF29; B5.2 `vP12`).
///
/// - Tema Claro, Oscuro o Sistema: se ve en el acto y se guarda (RF29.CA1).
///   Si la escritura falla, vuelve la preferencia guardada y se informa (B5.2
///   la dejaba aplicada sin guardar; aquí memoria y SQLite no divergen).
/// - Movimiento reducido: preferencia guardada que se suma a la de Android;
///   si Android pide reducir el movimiento, se reduce siempre.
/// - Sonido abre P13.
/// - Con sesión vigente solo se puede cambiar el tema (UX §4.2).
///
/// Datos (exportación, borrado y retención), Perfil local y Ayuda no forman
/// parte de este prototipo; se indica así, sin botones que aparenten
/// funcionar. Borrar todo depende además de OI-08 (RF27.CA2), abierto.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider);
    final ctl = ref.read(preferencesProvider.notifier);
    final lock = ref.watch(demoSessionProvider.select((s) => s.isVigente));
    final systemReduce = WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations;
    void home() => context.go(VigiaRoutes.inicio);
    final v = prefs.value;

    return PopScope(
      canPop: false,
      // Raíz de Ajustes: Volver lleva a Inicio (UX §4.1).
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) home();
      },
      child: VigiaScaffold(
        title: 'Ajustes',
        isDemo: true,
        navIndex: 2,
        onNavSelected: (i) {
          if (i == 0) home();
          if (i == 1) context.go(VigiaRoutes.historial);
          // Ajustes: ya estamos aquí; no se crea otra copia (UX §2.1).
        },
        children: [
          if (lock)
            const StatusCard(
              tone: StatusTone.strong,
              icon: VigiaIcon.activity,
              tag: 'Sesión vigente',
              title: 'Sesión en curso',
              text:
                  'Solo puedes cambiar el tema. El resto de ajustes está '
                  'bloqueado.',
            ),
          const VigiaSectionTitle('Tema'),
          VigiaOptionGroup(
            options: [
              for (final (t, label) in const [
                (ThemePreference.light, 'Claro'),
                (ThemePreference.dark, 'Oscuro'),
                (ThemePreference.system, 'Sistema'),
              ])
                VigiaOption(
                  label: label,
                  selected: v.theme == t,
                  onSelected: () => ctl.setTheme(t),
                ),
            ],
          ),
          const VigiaSectionTitle('Movimiento'),
          VigiaOptionGroup(
            options: [
              VigiaOption(
                label: 'Según Android',
                selected: !v.reducedMotion,
                onSelected: lock ? null : () => ctl.setReducedMotion(false),
              ),
              VigiaOption(
                label: 'Reducido',
                selected: v.reducedMotion,
                onSelected: lock ? null : () => ctl.setReducedMotion(true),
              ),
            ],
          ),
          VigiaParagraph(
            systemReduce
                ? 'Android pide reducir el movimiento: Vigía lo reduce '
                      'aunque elijas «Según Android».'
                : 'Reducido quita las animaciones de Vigía. Si Android pide '
                      'reducir el movimiento, se reduce siempre.',
            secondary: true,
          ),
          if (prefs.save == PreferenceSave.saved)
            const StatusCard(
              tone: StatusTone.plain,
              icon: VigiaIcon.check,
              tag: 'Guardado',
              title: 'Preferencia guardada',
            ),
          if (prefs.save == PreferenceSave.failed)
            const StatusCard(
              tone: StatusTone.alert,
              icon: VigiaIcon.close,
              tag: 'Error',
              title: 'Preferencia no guardada',
              text:
                  'No se pudo guardar el último cambio: se mantiene la '
                  'preferencia anterior.',
            ),
          const VigiaSectionTitle('Más ajustes'),
          VigiaButton(
            label: lock ? 'Sonido · bloqueado por sesión vigente' : 'Sonido',
            kind: VigiaButtonKind.secondary,
            height: 56,
            onPressed: lock ? null : () => context.go(VigiaRoutes.sonido),
          ),
          const StatusCard(
            tone: StatusTone.neutral,
            icon: VigiaIcon.info,
            tag: 'Pendiente',
            title: 'No incluido en este prototipo',
            text:
                'Datos (exportación, borrado y retención), Perfil local y '
                'Ayuda todavía no están implementados. Borrar todo depende '
                'además de una decisión abierta (OI-08).',
          ),
          const VigiaParagraph(
            'La alerta por cierre ocular no se puede desactivar y los '
            'umbrales no se pueden editar.',
            secondary: true,
          ),
        ],
      ),
    );
  }
}
