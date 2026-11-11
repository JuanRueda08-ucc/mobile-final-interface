import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/design_system/tokens.dart';
import '../../core/design_system/vigia_icons.dart';
import '../../core/design_system/widgets/vigia_blocks.dart';
import '../../core/design_system/widgets/vigia_button.dart';
import '../../data/experimental_history/experimental_history_providers.dart';
import '../../data/experimental_history/experimental_history_repository.dart';
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
    final blocks = switch (latest.isLoading
        ? const AsyncLoading<ExperimentalSessionRecord?>()
        : latest) {
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
        VigiaParagraph(
          sync.status == JournalSyncStatus.idle ||
                  sync.status == JournalSyncStatus.running
              ? 'Leyendo el registro del motor…'
              : 'Aún no hay sesiones experimentales',
          key: const Key('home-no-experimental'),
          secondary: true,
        ),
      ],
      AsyncData(:final value?) when value.isFinalized => <Widget>[
        VigiaParagraph(
          'Experimental · ${ExperimentalHistoryText.record(value)}',
          key: const Key('home-latest-experimental'),
        ),
        VigiaParagraph(formatDateTime(value.startedAt.fields), secondary: true),
        KeyValueRow(
          label: 'Cobertura',
          value: ExperimentalHistoryText.coverage(value.totals),
        ),
        VigiaButton(
          label: 'Ver último resumen',
          kind: VigiaButtonKind.secondary,
          onPressed: () => context.go(VigiaRoutes.resumen(value.sessionId)),
        ),
      ],
      AsyncData(:final value?) when value.isInterrupted => <Widget>[
        const VigiaParagraph(
          'Experimental · Sesión interrumpida',
          key: Key('home-interrupted-experimental'),
        ),
        VigiaParagraph(formatDateTime(value.startedAt.fields), secondary: true),
        const KeyValueRow(label: 'Final', value: 'Desconocido'),
        const KeyValueRow(label: 'Cobertura', value: 'No disponible'),
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
      spacing: VigiaSpace.gap / 2,
      children: [
        const Divider(),
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
