import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_config.dart';
import '../../app/router.dart';
import '../../core/design_system/vigia_icons.dart';
import '../../core/design_system/widgets/trial_version_notice.dart';
import '../../core/design_system/widgets/vigia_blocks.dart';
import '../../core/design_system/widgets/vigia_button.dart';
import '../../core/design_system/widgets/vigia_option.dart';
import '../../core/design_system/widgets/vigia_scaffold.dart';
import '../account/firebase_account.dart';
import 'preferences_controller.dart';
import 'variant_settings.dart';

/// P12 · Ajustes (FL11, RF29; B5.2 `vP12`).
///
/// - Tema Claro, Oscuro o Sistema: se ve en el acto y se guarda (RF29.CA1).
///   Si la escritura falla, vuelve la preferencia guardada y se informa (B5.2
///   la dejaba aplicada sin guardar; aquí memoria y SQLite no divergen).
/// - Movimiento reducido: preferencia guardada que se suma a la de Android;
///   si Android pide reducir el movimiento, se reduce siempre.
/// - Sonido abre P13.
/// - Con sesión vigente solo se puede cambiar el tema (UX §4.2).
/// - Fase 5E: la misma pantalla sirve a la variante normal, con sus propias
///   preferencias (`vigia_history_real_v1.sqlite`) y el bloqueo de la sesión
///   experimental. No lleva el rótulo DEMO: no muestra datos simulados.
///
/// La DEMO documenta el alcance original de Datos, Perfil local y Ayuda.
/// Borrar todo depende de la decisión OI-08 (RF27.CA2).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(preferencesProvider);
    final ctl = ref.read(preferencesProvider.notifier);
    final lock = ref.watch(settingsControlsLockedProvider);
    final demo = ref.watch(appModeProvider) is DemoMode;
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
        isDemo: demo,
        navIndex: 2,
        sideNavigation: !demo,
        accountDestination: ref.watch(firebaseAuthProvider) != null,
        onNavSelected: (i) {
          if (i == 0) home();
          if (i == 1) context.go(VigiaRoutes.historial);
          if (i == 3) context.go(VigiaRoutes.cuenta);
          // Ajustes: ya estamos aquí; no se crea otra copia (UX §2.1).
        },
        children: [
          if (ref.watch(settingsReadyProvider).hasError)
            const StatusCard(
              tone: StatusTone.alert,
              icon: VigiaIcon.info,
              tag: 'Motor no disponible',
              title: 'Solo puedes cambiar el tema',
              text: 'No se pudo comprobar si hay una sesión vigente. Vuelve a abrir Ajustes para reintentar.',
            )
          else if (ref.watch(settingsLockedProvider))
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
          if (prefs.save == PreferenceSave.saving)
            const StatusCard(
              tone: StatusTone.plain,
              icon: VigiaIcon.info,
              tag: 'En curso',
              title: 'Guardando preferencia',
              text: 'Esperando confirmación del almacenamiento y del motor.',
            ),
          // Un aviso por preferencia que no se guardó, con su valor vigente.
          for (final f in prefs.failures.values)
            StatusCard(
              tone: StatusTone.alert,
              icon: VigiaIcon.close,
              tag: 'Error',
              title: 'Preferencia no guardada',
              text: preferenceFailureText(f, v),
            ),
          if (!demo)
            const VigiaParagraph(
              'Preferencias de esta app. Vigía DEMO guarda las suyas por '
              'separado.',
              secondary: true,
            ),
          const VigiaSectionTitle('Más ajustes'),
          VigiaButton(
            label: lock ? 'Sonido · bloqueado por sesión vigente' : 'Sonido',
            kind: VigiaButtonKind.secondary,
            height: 56,
            onPressed: lock ? null : () => context.go(VigiaRoutes.sonido),
          ),
          if (demo)
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
          if (!demo) ...[
            const VigiaSectionTitle('Acerca de'),
            const TrialVersionNotice(),
          ],
        ],
      ),
    );
  }
}
