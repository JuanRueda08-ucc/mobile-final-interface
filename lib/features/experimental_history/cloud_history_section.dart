import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/widgets/vigia_blocks.dart';
import '../../core/design_system/widgets/vigia_button.dart';
import '../../data/experimental_history/experimental_history_repository.dart';
import '../account/cloud_sessions.dart';
import '../monitoring/domain/session_summary.dart';
import 'experimental_history_blocks.dart';

class CloudHistorySection extends ConsumerWidget {
  const CloudHistorySection({
    super.key,
    required this.uid,
    required this.filter,
    required this.localIds,
  });

  final String uid;
  final ExperimentalHistoryFilter filter;
  final Set<String> localIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(cloudHistoryProvider(uid));
    final upload = ref.watch(cloudSessionUploadProvider(uid));
    final remote = (history.asData?.value ?? const <CloudSession>[]).where((s) {
      if (localIds.contains(s.id)) return false;
      return switch (filter) {
        ExperimentalHistoryFilter.all => true,
        ExperimentalHistoryFilter.finalized =>
          s.lifecycle == ExperimentalLifecycle.finalized,
        ExperimentalHistoryFilter.interrupted =>
          s.lifecycle == ExperimentalLifecycle.interrupted,
      };
    });
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        const VigiaSectionTitle('Resúmenes de tu cuenta'),
        if (upload.hasError || history.hasError) ...[
          const VigiaParagraph(
            'No se pudo sincronizar. Los registros del teléfono siguen disponibles.',
          ),
          VigiaButton(
            label: 'Reintentar sincronización',
            kind: VigiaButtonKind.secondary,
            onPressed: () {
              ref.invalidate(cloudSessionUploadProvider(uid));
              ref.invalidate(cloudHistoryProvider(uid));
            },
          ),
        ] else if (history.isLoading || upload.isLoading)
          const VigiaParagraph('Sincronizando…', secondary: true)
        else ...[
          if (remote.isEmpty)
            const VigiaParagraph(
              'Aquí aparecen las sesiones guardadas en otros dispositivos.',
              secondary: true,
            ),
          for (final session in remote)
            ExpansionTile(
              key: ValueKey(session.id),
              title: Text(formatDateTime(session.startedAt.fields)),
              subtitle: Text(
                ExperimentalHistoryText.lifecycle(session.lifecycle),
              ),
              children: [
                KeyValueRow(
                  label: 'Último registro',
                  value: formatDateTime(
                    session.startedAt.plus(session.durable).fields,
                  ),
                ),
                if (session.active case final active?)
                  KeyValueRow(
                    label: 'Tiempo activo',
                    value: formatSeconds(active),
                  ),
                if (session.evaluable case final evaluable?)
                  KeyValueRow(
                    label: 'Tiempo evaluable',
                    value: formatSeconds(evaluable),
                  ),
                if (session.closures case final closures?)
                  KeyValueRow(label: 'Cierres sostenidos', value: '$closures'),
                if (!session.complete)
                  const VigiaParagraph(
                    'El registro tiene cobertura incompleta.',
                  ),
              ],
            ),
          VigiaButton(
            label: 'Actualizar resúmenes',
            kind: VigiaButtonKind.secondary,
            onPressed: () => ref.invalidate(cloudHistoryProvider(uid)),
          ),
        ],
      ],
    );
  }
}
