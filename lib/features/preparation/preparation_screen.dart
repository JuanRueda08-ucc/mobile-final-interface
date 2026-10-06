import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/design_system/vigia_icons.dart';
import '../../core/design_system/widgets/notice_host.dart';
import '../../core/design_system/widgets/vigia_blocks.dart';
import '../../core/design_system/widgets/vigia_button.dart';
import '../../core/design_system/widgets/vigia_flow_blocks.dart';
import '../../core/design_system/widgets/vigia_scaffold.dart';
import '../calibration/calibration_controller.dart';
import '../monitoring/demo_session_controller.dart';
import 'preparation_controller.dart';
import 'preparation_state.dart';

/// P04 · Preparación («Antes de iniciar»; FL02, RF03–RF05, RF07; B5.2 `vP04`).
///
/// Demostración: las condiciones del equipo son simuladas (panel «Simulación
/// DEMO»); no se abre la cámara ni se pide el permiso de Android. La prueba
/// de sonido reproduce un tono local real y exige «Lo escuché».
class PreparationScreen extends ConsumerStatefulWidget {
  const PreparationScreen({super.key});

  static const startBlockedNotice =
      'Iniciar no disponible: hay condiciones sin cumplir.';
  static const mountChangedNotice =
      'Referencia marcada como no aplicable (RF07). Calibra de nuevo antes de '
      'iniciar.';

  @override
  ConsumerState<PreparationScreen> createState() => _PreparationScreenState();
}

class _PreparationScreenState extends ConsumerState<PreparationScreen>
    with NoticeHost {
  PreparationController get _prep => ref.read(preparationProvider.notifier);

  /// Volver: con la «vista previa» activa (permiso y cámara) abre D01; si no,
  /// vuelve directamente a Inicio (UX §4.1).
  Future<void> _back() async {
    final s = ref.read(preparationProvider);
    if (s.sim.permission && s.sim.camera) {
      final exit = await showVigiaConfirm(
        context,
        id: 'D01',
        title: '¿Salir de la preparación?',
        text: 'Se cerrará la cámara. Todavía no hay una sesión.',
        safeLabel: 'Seguir preparando',
        actionLabel: 'Salir',
        isDemo: true,
      );
      if (!exit || !mounted) return;
    }
    context.go(VigiaRoutes.inicio);
  }

  void _start() {
    if (ref.read(demoSessionProvider.notifier).requestStart()) {
      context.go(VigiaRoutes.monitoreo);
    } else {
      showNotice(PreparationScreen.startBlockedNotice);
    }
  }

  void _calibrate() {
    ref.read(calibrationProvider.notifier).open();
    context.go(VigiaRoutes.calibracion);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(preparationProvider);
    final sim = s.sim;
    final blockers = s.blockers;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: VigiaScaffold(
        title: 'Antes de iniciar',
        isDemo: true,
        onBack: _back,
        notice: notice,
        children: [
          const VigiaParagraph(
            'Prepara con el vehículo detenido y el teléfono en un soporte '
            'estable.',
            secondary: true,
          ),
          if (s.mountChanged && !s.referenceApplicable)
            const StatusCard(
              key: Key('reference-invalidated'),
              tone: StatusTone.pending,
              icon: VigiaIcon.clock,
              tag: 'Calibración',
              title: 'Referencia no aplicable',
              text:
                  'Declaraste un cambio de posición. La referencia anterior ya '
                  'no es aplicable: calibra de nuevo antes de iniciar.',
            ),
          CameraStage(
            stateText: sim.permission && sim.camera
                ? (sim.face
                      ? 'Rostro detectado (simulado)'
                      : 'Rostro no detectado (simulado)')
                : 'Cámara no disponible para la vista previa',
          ),
          CheckGroup(
            rows: [
              CheckRow(
                label: 'Permiso de cámara',
                ok: sim.permission,
                value: sim.permission ? 'Concedido' : 'Cámara sin permiso',
                cause: sim.permission
                    ? null
                    : 'Condición simulada: esta demostración no solicita el '
                          'permiso de Android.',
              ),
              CheckRow(
                label: 'Cámara',
                ok: sim.camera,
                value: sim.camera ? 'Disponible' : 'Cámara no disponible',
              ),
              CheckRow(
                label: 'Modelo',
                ok: sim.model,
                value: sim.model ? 'Cargado' : 'Modelo no disponible',
              ),
              CheckRow(
                label: 'Rostro (informativo)',
                ok: sim.face,
                value: sim.face ? 'Rostro detectado' : 'Rostro no detectado',
                cause: 'Presencia facial no equivale a ojos medibles.',
              ),
              CheckRow(
                label: 'Ojos evaluables',
                ok: s.eyesEvaluable,
                value: s.eyesEvaluable
                    ? 'Ojos evaluables'
                    : 'Ojos no evaluables',
                cause: s.eyesEvaluable
                    ? null
                    : sim.face
                    ? 'Rostro detectado, pero no puedo evaluar los ojos.'
                    : 'Sin rostro no hay medición ocular.',
              ),
              CheckRow(
                label: 'Referencia de calibración',
                ok: s.referenceApplicable,
                value: s.referenceApplicable
                    ? 'Referencia aplicable'
                    : 'Calibración pendiente',
                cause: s.referenceApplicable
                    ? 'Referencia ${s.reference!.id} (calibración simulada).'
                    : s.canCalibrate
                    ? null
                    : 'Calibrar exige permiso, cámara y modelo disponibles.',
                action: s.referenceApplicable
                    ? null
                    : VigiaButton(
                        label: 'Calibrar',
                        kind: VigiaButtonKind.secondary,
                        icon: VigiaIcon.target,
                        onPressed: s.canCalibrate ? _calibrate : null,
                      ),
              ),
              CheckRow(
                label: 'Sonido',
                ok: s.sound == SoundCheck.confirmed,
                value: s.sound == SoundCheck.confirmed
                    ? 'Sonido confirmado'
                    : 'Prueba de sonido pendiente',
                cause: switch (s.sound) {
                  SoundCheck.confirmed => null,
                  SoundCheck.pending =>
                    'Cada sesión nueva necesita una prueba audible.',
                  SoundCheck.playing =>
                    'Reproduciendo… esperando resultado técnico.',
                  SoundCheck.played =>
                    'Reproducción técnica correcta. Falta tu confirmación.',
                  SoundCheck.notHeard =>
                    'No lo escuché: el inicio sigue bloqueado. Revisa la '
                        'salida y el volumen y repite la prueba.',
                  SoundCheck.failed =>
                    'No se pudo reproducir el sonido. '
                        '${s.soundFailure ?? ''}',
                },
              ),
            ],
          ),
          const VigiaSectionTitle('Verifica el soporte'),
          const VigiaParagraph(
            'Si moviste el teléfono o el soporte, decláralo: la referencia '
            'deja de ser aplicable y hay que calibrar de nuevo.',
            secondary: true,
          ),
          VigiaButton(
            label: 'Cambié la posición',
            kind: VigiaButtonKind.secondary,
            onPressed: () {
              _prep.declareMountChanged();
              showNotice(PreparationScreen.mountChangedNotice);
            },
          ),
          if (s.sound != SoundCheck.confirmed)
            VigiaButtonRow(
              buttons: [
                VigiaButton(
                  label: switch (s.sound) {
                    SoundCheck.pending => 'Probar sonido',
                    SoundCheck.failed => 'Reintentar',
                    SoundCheck.playing => 'Reproduciendo…',
                    _ => 'Repetir prueba',
                  },
                  kind: VigiaButtonKind.secondary,
                  icon: VigiaIcon.speaker,
                  onPressed: s.sound == SoundCheck.playing
                      ? null
                      : _prep.testSound,
                ),
                VigiaButton(
                  label: 'Lo escuché',
                  onPressed: s.sound == SoundCheck.played
                      ? _prep.confirmHeard
                      : null,
                ),
                VigiaButton(
                  label: 'No lo escuché',
                  kind: VigiaButtonKind.secondary,
                  onPressed: s.sound == SoundCheck.played
                      ? _prep.notHeard
                      : null,
                ),
              ],
            ),
          VigiaParagraph(
            blockers.isEmpty
                ? 'Las seis condiciones se cumplen. El inicio espera tu '
                      'pulsación y la confirmación del motor simulado.'
                : 'Iniciar no disponible. Falta: '
                      '${blockers.map((b) => b.text).join(' · ')}.',
            secondary: true,
          ),
          VigiaButton(
            label: 'Iniciar monitoreo',
            onPressed: blockers.isEmpty ? _start : null,
          ),
          DemoSimulationPanel(
            title: 'Simulación DEMO',
            text:
                'Solo para la demostración: no hay cámara ni IA. Cambia estas '
                'condiciones para ver cada bloqueo.',
            children: [
              DemoToggle(
                label: 'Permiso de cámara concedido',
                value: sim.permission,
                onChanged: (v) =>
                    _prep.setSimulated(sim.copyWith(permission: v)),
              ),
              DemoToggle(
                label: 'Cámara disponible',
                value: sim.camera,
                onChanged: (v) => _prep.setSimulated(sim.copyWith(camera: v)),
              ),
              DemoToggle(
                label: 'Modelo cargado',
                value: sim.model,
                onChanged: (v) => _prep.setSimulated(sim.copyWith(model: v)),
              ),
              DemoToggle(
                label: 'Rostro detectado',
                value: sim.face,
                onChanged: (v) => _prep.setSimulated(sim.copyWith(face: v)),
              ),
              DemoToggle(
                label: 'Ojos evaluables',
                value: sim.eyes,
                onChanged: (v) => _prep.setSimulated(sim.copyWith(eyes: v)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
