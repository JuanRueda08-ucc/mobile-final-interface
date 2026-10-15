import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/design_system/tokens.dart';
import '../../core/design_system/vigia_icons.dart';
import '../../core/design_system/widgets/vigia_blocks.dart';
import '../../core/design_system/widgets/vigia_button.dart';
import '../../data/experimental_history/experimental_history_providers.dart';
import '../monitoring/domain/session_summary.dart';
import 'experimental_history_blocks.dart';

/// Inicio (P03) de la variante normal, fase 5D: última sesión experimental
/// guardada (resumen o registro interrumpido), leída de la misma proyección
/// que Resumen, Historial y detalle. Al montarse pide importar el journal,
/// así que una sesión cerrada o recuperada aparece aunque su último aviso no
/// llegara a Flutter.
class ExperimentalHomeSection extends ConsumerStatefulWidget {
  const ExperimentalHomeSection({super.key});

  @override
  ConsumerState<ExperimentalHomeSection> createState() =>
      _ExperimentalHomeSectionState();
}

class _ExperimentalHomeSectionState
    extends ConsumerState<ExperimentalHomeSection>
    with JournalSyncOnMount {
  @override
  Widget build(BuildContext context) {
    final latest = ref.watch(latestExperimentalSessionProvider);
    final sync = ref.watch(journalSyncProvider);
    final blocks = switch (latest) {
      AsyncError() => <Widget>[
        const StatusCard(
          tone: StatusTone.alert,
          icon: VigiaIcon.close,
          tag: 'Error',
          title: 'No se pudo cargar el historial experimental',
          text: 'Esto no significa que no existan sesiones.',
        ),
      ],
      AsyncData(value: null) => <Widget>[
        StatusCard(
          key: const Key('home-no-experimental'),
          tone: StatusTone.plain,
          icon: VigiaIcon.info,
          tag: 'Historial experimental',
          title:
              sync.status == JournalSyncStatus.idle ||
                  sync.status == JournalSyncStatus.running
              ? 'Leyendo el registro del motor'
              : 'Aún no hay sesiones experimentales',
          text:
              'Las sesiones experimentales finalizadas o interrumpidas '
              'aparecerán aquí. No necesitas cuenta.',
        ),
      ],
      AsyncData(:final value?) when value.isFinalized => <Widget>[
        PaperSummaryCard(
          key: const Key('home-latest-experimental'),
          tag: 'Experimental · ${ExperimentalHistoryText.record(value)}',
          title: 'Sesión ${ExperimentalHistoryText.shortId(value.sessionId)}',
          metrics: [
            PaperMetric(
              ExperimentalHistoryText.coverage(value.totals),
              'Cobertura',
            ),
            PaperMetric(
              '${value.totals!.closureActivations}',
              'Cierres prolongados',
            ),
          ],
          actionLabel: 'Ver último resumen',
          onAction: () => context.go(VigiaRoutes.resumen(value.sessionId)),
        ),
      ],
      AsyncData(:final value?) when value.isInterrupted => <Widget>[
        const StatusCard(
          key: Key('home-interrupted-experimental'),
          tone: StatusTone.alert,
          icon: VigiaIcon.warn,
          tag: 'Experimental · registro',
          title: 'Sesión interrumpida',
          text: 'No hay cierre confirmado. No se reinició la cámara.',
        ),
        KeyValueRow(
          label: 'Sesión',
          value: ExperimentalHistoryText.shortId(value.sessionId),
        ),
        KeyValueRow(
          label: 'Inicio confirmado',
          value: formatTimeOfDay(value.startedAt.fields),
        ),
        KeyValueRow(
          label: 'Último registro confirmado',
          value: formatTimeOfDay(value.latestDurableAt.fields),
        ),
        const KeyValueRow(label: 'Final', value: 'Desconocido'),
        const KeyValueRow(label: 'Duración', value: 'No disponible'),
        VigiaButton(
          label: 'Revisar registro',
          kind: VigiaButtonKind.secondary,
          onPressed: () => context.go(VigiaRoutes.detalle(value.sessionId)),
        ),
      ],
      AsyncData() => const <Widget>[
        StatusCard(
          tone: StatusTone.pending,
          icon: VigiaIcon.clock,
          tag: 'Historial experimental',
          title: 'Registro en curso',
          text: 'La última sesión todavía no tiene cierre guardado.',
        ),
      ],
      _ => const <Widget>[
        StatusCard(
          tone: StatusTone.pending,
          icon: VigiaIcon.clock,
          tag: 'Historial experimental',
          title: 'Cargando historial',
          text: 'Leyendo los registros guardados en el teléfono.',
        ),
      ],
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: VigiaSpace.gap,
      children: [
        const VigiaSectionTitle('Última sesión experimental'),
        ...blocks,
        VigiaButton(
          key: const Key('open-experimental-history'),
          label: 'Ver historial experimental',
          kind: VigiaButtonKind.secondary,
          onPressed: () => context.go(VigiaRoutes.historial),
        ),
      ],
    );
  }
}
