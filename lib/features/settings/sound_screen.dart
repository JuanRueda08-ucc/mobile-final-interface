import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/audio/alert_sound.dart';
import '../../core/design_system/vigia_icons.dart';
import '../../core/design_system/widgets/vigia_blocks.dart';
import '../../core/design_system/widgets/vigia_button.dart';
import '../../core/design_system/widgets/vigia_flow_blocks.dart';
import '../../core/design_system/widgets/vigia_option.dart';
import '../../core/design_system/widgets/vigia_scaffold.dart';
import '../common/session_blocked.dart';
import '../monitoring/demo_session_controller.dart';
import 'preferences_controller.dart';

enum _Test { idle, playing, ok, failed }

/// P13 · Sonido (FL11, RF29.CA3; B5.2 `vP13`).
///
/// Elige uno de los patrones incluidos, lo prueba (resultado técnico, no
/// audibilidad) y lo guarda. Guardar un patrón no aprueba la prueba audible de
/// ninguna sesión: Preparación vuelve a exigir «Probar sonido» y «Lo escuché»
/// (RF29.CA3, UX21.CA1). No hay opción para desactivar la alerta.
///
/// Bloqueado con sesión vigente (UX §4.2). Salir con cambios sin guardar
/// ofrece Descartar cambios / Seguir editando (UX §4.1).
///
/// Los avisos de guardado salen del estado del controlador, no de la
/// respuesta de cada petición: una respuesta antigua (de éxito o de fallo) no
/// describe una selección posterior, y un fallo que el controlador ya descartó
/// no vuelve a mostrarse.
class SoundScreen extends ConsumerStatefulWidget {
  const SoundScreen({super.key});

  @override
  ConsumerState<SoundScreen> createState() => _SoundScreenState();
}

class _SoundScreenState extends ConsumerState<SoundScreen> {
  String? _selected;
  var _test = _Test.idle;
  String? _testFailure;
  var _testAttempt = 0;

  /// Último patrón que esta pantalla pidió guardar.
  String? _requested;

  Future<void> _play(String patternId) async {
    final attempt = ++_testAttempt;
    setState(() => _test = _Test.playing);
    final r = await ref
        .read(alertSoundPlayerProvider)
        .play(AlertSoundKind.test, patternId: patternId);
    if (!mounted || attempt != _testAttempt) return;
    setState(() {
      _test = r.played ? _Test.ok : _Test.failed;
      _testFailure = r.failure;
    });
  }

  void _save(String patternId) {
    setState(() => _requested = patternId);
    // El resultado se lee del estado del controlador (ver build).
    ref.read(preferencesProvider.notifier).setSoundPattern(patternId);
  }

  Future<void> _back(bool dirty) async {
    if (dirty) {
      final discard = await showVigiaConfirm(
        context,
        id: 'sonido-sin-guardar',
        title: 'Cambios sin guardar',
        text: 'El patrón elegido no se guardó.',
        safeLabel: 'Seguir editando',
        actionLabel: 'Descartar cambios',
        isDemo: true,
      );
      if (!discard || !mounted) return;
    }
    context.go(VigiaRoutes.ajustes);
  }

  @override
  Widget build(BuildContext context) {
    final vigente = ref.watch(demoSessionProvider.select((s) => s.isVigente));
    final prefs = ref.watch(preferencesProvider);
    // Patrón confirmado: el patrón solo cambia en el estado al guardarse.
    final saved = prefs.value.soundPatternId;
    final selected = _selected ?? saved;
    final dirty = !vigente && selected != saved;
    final failure = prefs.failures[PreferenceField.soundPattern];
    final patternPending = prefs.pending.contains(PreferenceField.soundPattern);
    // «Guardado» solo para la última petición, ya confirmada y sin otra
    // petición de patrón pendiente.
    final confirmed =
        _requested != null && _requested == saved && !patternPending && !dirty;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back(dirty);
      },
      child: VigiaScaffold(
        title: 'Sonido',
        isDemo: true,
        onBack: () => _back(dirty),
        children: vigente
            ? sessionBlockedBlocks(context, 'Sonido')
            : [
                const VigiaParagraph(
                  'Patrones incluidos. El catálogo definitivo está pendiente '
                  'de design system y audio.',
                  secondary: true,
                ),
                VigiaOptionGroup(
                  options: [
                    for (final p in SoundPattern.values)
                      VigiaOption(
                        label:
                            '${p.label}${p.id == saved ? ' (guardado)' : ''}',
                        selected: p.id == selected,
                        onSelected: () => setState(() {
                          _selected = p.id;
                          _testAttempt++; // descarta una prueba anterior
                          _test = _Test.idle;
                        }),
                      ),
                  ],
                ),
                VigiaButton(
                  label: _test == _Test.playing
                      ? 'Reproduciendo…'
                      : 'Probar sonido',
                  kind: VigiaButtonKind.secondary,
                  icon: VigiaIcon.speaker,
                  onPressed: _test == _Test.playing
                      ? null
                      : () => _play(selected),
                ),
                if (_test == _Test.ok)
                  const VigiaParagraph(
                    'Reproducción de prueba correcta. Esto no confirma que lo '
                    'hayas oído.',
                  ),
                if (_test == _Test.failed)
                  StatusCard(
                    tone: StatusTone.alert,
                    icon: VigiaIcon.close,
                    tag: 'Error',
                    title: 'No se pudo reproducir el sonido',
                    text: _testFailure ?? 'Vuelve a intentarlo.',
                  ),
                if (confirmed)
                  const StatusCard(
                    tone: StatusTone.plain,
                    icon: VigiaIcon.check,
                    tag: 'Guardado',
                    title: 'Patrón guardado',
                    text:
                        'Guardar un patrón no aprueba la prueba audible de una '
                        'sesión. Cada sesión necesita su propia prueba.',
                  ),
                if (failure != null)
                  StatusCard(
                    tone: StatusTone.alert,
                    icon: VigiaIcon.close,
                    tag: 'Error',
                    title: 'Patrón no guardado',
                    // Con el patrón confirmado ahora, no con una copia previa.
                    text: preferenceFailureText(failure, prefs.value),
                  ),
                VigiaButton(
                  label: 'Guardar',
                  onPressed: dirty ? () => _save(selected) : null,
                ),
              ],
      ),
    );
  }
}
