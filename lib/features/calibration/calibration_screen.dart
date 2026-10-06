import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/design_system/vigia_icons.dart';
import '../../core/design_system/widgets/vigia_blocks.dart';
import '../../core/design_system/widgets/vigia_button.dart';
import '../../core/design_system/widgets/vigia_flow_blocks.dart';
import '../../core/design_system/widgets/vigia_scaffold.dart';
import 'calibration_controller.dart';

/// P05 · Calibración (FL03, RF06, UX05; B5.2 `vP05`).
///
/// Demostración: no se adquieren observaciones. Durante «Recogiendo
/// referencia» el resultado se elige en el panel «Simulación DEMO»: aceptar o
/// uno de los tres rechazos. No se muestra porcentaje ni cuenta atrás.
class CalibrationScreen extends ConsumerWidget {
  const CalibrationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(calibrationProvider);
    final cal = ref.read(calibrationProvider.notifier);

    /// Cancelar o Volver: detiene la adquisición y vuelve a Preparación sin
    /// sesión ni referencia nueva (FL03.8, UX05.CA3).
    void cancel() {
      cal.cancel();
      context.go(VigiaRoutes.preparacion);
    }

    final cancelButton = VigiaButton(
      label: 'Cancelar',
      kind: VigiaButtonKind.secondary,
      onPressed: cancel,
    );

    final children = switch (state) {
      CalibrationInstructions() => [
        const VigiaHeading('Ajusta tu mirada'),
        const VigiaParagraph(
          'Con el vehículo detenido y el teléfono fijo, mira a la cámara con '
          'expresión neutra. Mantén los ojos visibles y la posición estable.',
        ),
        const VigiaParagraph(
          'La calibración no cuenta como tiempo de sesión.',
          secondary: true,
        ),
        VigiaButton(label: 'Comenzar', onPressed: cal.begin),
        cancelButton,
      ],
      CalibrationAcquiring() => [
        const VigiaHeading('Calibración de referencia'),
        const CameraStage(stateText: 'Mantén la posición'),
        const StatusCard(
          tone: StatusTone.pending,
          icon: VigiaIcon.clock,
          tag: 'En curso',
          title: 'Recogiendo referencia',
          text: 'Mantén la posición. No se muestra porcentaje ni duración.',
        ),
        cancelButton,
        DemoSimulationPanel(
          title: 'Resultado simulado',
          text:
              'Solo para la demostración: no se adquieren observaciones. '
              'Elige el resultado que devolvería el motor.',
          children: [
            VigiaButton(
              label: 'Aceptar referencia',
              kind: VigiaButtonKind.secondary,
              onPressed: cal.simulateAccepted,
            ),
            for (final r in CalibrationRejection.values) ...[
              const SizedBox(height: 8),
              VigiaButton(
                label: 'Rechazo: ${r.title.toLowerCase()}',
                kind: VigiaButtonKind.secondary,
                onPressed: () => cal.simulateRejected(r),
              ),
            ],
          ],
        ),
      ],
      CalibrationAccepted(:final referenceId) => [
        const VigiaHeading('Calibración de referencia'),
        StatusCard(
          tone: StatusTone.strong,
          icon: VigiaIcon.check,
          tag: 'Aceptada',
          title: 'Calibración completada',
          text:
              'Referencia $referenceId guardada en memoria (resultado '
              'simulado; no demuestra detección válida).',
        ),
        VigiaButton(
          label: 'Usar referencia aceptada',
          onPressed: () => context.go(VigiaRoutes.preparacion),
        ),
      ],
      CalibrationRejected(:final cause) => [
        const VigiaHeading('Calibración de referencia'),
        StatusCard(
          tone: StatusTone.alert,
          icon: VigiaIcon.close,
          tag: 'Rechazada',
          title: cause.title,
          text: '${cause.text} No se guardó ninguna referencia aceptada.',
        ),
        VigiaButton(label: 'Reintentar', onPressed: cal.begin),
        cancelButton,
      ],
    };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (state is CalibrationAccepted) {
          context.go(VigiaRoutes.preparacion);
        } else {
          cancel();
        }
      },
      child: VigiaScaffold(
        title: 'Calibración',
        isDemo: true,
        onBack: state is CalibrationAccepted
            ? () => context.go(VigiaRoutes.preparacion)
            : cancel,
        children: children,
      ),
    );
  }
}
