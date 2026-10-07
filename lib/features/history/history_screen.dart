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
import '../../data/demo_history/history_providers.dart';
import '../monitoring/demo_session_controller.dart';
import '../monitoring/domain/session_summary.dart';
import '../preparation/preparation_controller.dart';

/// Filtro elegido en esta ejecución (UX §2.1: cada sección conserva su
/// posición durante la misma ejecución).
final historyFilterProvider = NotifierProvider<_FilterNotifier, HistoryFilter>(
  _FilterNotifier.new,
);

class _FilterNotifier extends Notifier<HistoryFilter> {
  @override
  HistoryFilter build() => HistoryFilter.all;

  void set(HistoryFilter f) => state = f;
}

/// Texto de estado de una sesión guardada en la lista y el detalle.
String storedLifecycleText(StoredLifecycle l) => switch (l) {
  StoredLifecycle.finalized => 'Finalizada',
  StoredLifecycle.interrupted => 'Interrumpida',
  StoredLifecycle.active || StoredLifecycle.paused => 'En curso',
  StoredLifecycle.stopping => 'Finalizando',
};

/// P08 · Historial (FL09, RF22; B5.2 `vP08`).
///
/// Lista las sesiones guardadas en el historial DEMO, la más reciente primero
/// (inicio descendente, desempate por ID), con fecha, estado y cobertura. Se
/// puede filtrar por estado. Vacío, cargando y error son estados distintos
/// (UX15.CA1). Las interrumpidas no se ocultan ni se presentan como
/// finalizadas (RF22.CA3). Tendencias (P11) no forma parte de este prototipo.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(historyFilterProvider);
    final list = ref.watch(historyListProvider(filter));
    final vigente = ref.watch(demoSessionProvider.select((s) => s.isVigente));
    void home() => context.go(VigiaRoutes.inicio);
    void prepare() {
      ref.read(preparationProvider.notifier).open();
      context.go(VigiaRoutes.preparacion);
    }

    final children = <Widget>[
      if (vigente) ...[
        const StatusCard(
          tone: StatusTone.strong,
          icon: VigiaIcon.activity,
          tag: 'Sesión vigente',
          title: 'Sesión en curso',
          text:
              'El detalle de las sesiones está bloqueado hasta confirmar el '
              'cierre.',
        ),
        VigiaButton(
          label: 'Volver al monitoreo',
          kind: VigiaButtonKind.secondary,
          onPressed: () => context.go(VigiaRoutes.monitoreo),
        ),
      ],
      const VigiaSectionTitle('Mostrar'),
      VigiaOptionGroup(
        options: [
          for (final (f, label) in const [
            (HistoryFilter.all, 'Todas'),
            (HistoryFilter.finalized, 'Finalizadas'),
            (HistoryFilter.interrupted, 'Interrumpidas'),
          ])
            VigiaOption(
              label: label,
              selected: filter == f,
              onSelected: () => ref.read(historyFilterProvider.notifier).set(f),
            ),
        ],
      ),
      ...switch (list) {
        AsyncData(:final value) when value.isEmpty =>
          filter == HistoryFilter.all
              ? [
                  const StatusCard(
                    tone: StatusTone.plain,
                    icon: VigiaIcon.info,
                    tag: 'Historial',
                    title: 'Aún no tienes sesiones',
                    text:
                        'Las sesiones finalizadas o interrumpidas aparecerán '
                        'aquí.',
                  ),
                  VigiaButton(
                    label: 'Preparar primera sesión',
                    onPressed: vigente ? null : prepare,
                  ),
                ]
              : [
                  const StatusCard(
                    tone: StatusTone.plain,
                    icon: VigiaIcon.info,
                    tag: 'Historial',
                    title: 'No hay sesiones con este filtro',
                    text: 'Elige «Todas» para ver todo el historial.',
                  ),
                ],
        AsyncData(:final value) => [
          const VigiaParagraph('Más reciente primero.', secondary: true),
          for (final s in value)
            VigiaButton(
              key: Key('history-${s.sessionId}'),
              label: _rowLabel(s),
              kind: VigiaButtonKind.secondary,
              height: 56,
              onPressed: () => context.go(VigiaRoutes.detalle(s.sessionId)),
            ),
        ],
        AsyncError() => [
          const StatusCard(
            tone: StatusTone.alert,
            icon: VigiaIcon.close,
            tag: 'Error',
            title: 'No se pudo cargar el historial',
            text: 'Esto no significa que no existan sesiones.',
          ),
          VigiaButton(
            label: 'Reintentar',
            kind: VigiaButtonKind.secondary,
            onPressed: () => ref.invalidate(historyListProvider),
          ),
        ],
        _ => const [
          StatusCard(
            tone: StatusTone.pending,
            icon: VigiaIcon.clock,
            tag: 'Carga',
            title: 'Cargando historial',
            text: 'Leyendo los registros del teléfono.',
          ),
        ],
      },
      const VigiaParagraph(
        'Tendencias, valoración, exportación y borrado no forman parte de '
        'este prototipo.',
        secondary: true,
      ),
    ];

    return PopScope(
      canPop: false,
      // Raíz de Historial: Volver lleva a Inicio (UX §4.1).
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) home();
      },
      child: VigiaScaffold(
        title: 'Historial',
        isDemo: true,
        navIndex: 1,
        onNavSelected: (i) {
          if (i == 0) home();
          if (i == 2) context.go(VigiaRoutes.ajustes);
          // Historial: ya estamos aquí; no se crea otra copia (UX §2.1).
        },
        children: children,
      ),
    );
  }

  /// «S-DEMO-0001 · 06/10/2026 08:12 · Finalizada · Cobertura 83,3 %».
  static String _rowLabel(StoredSession s) {
    final coverage = s.summary?.coverageText ?? 'No disponible';
    return '${s.sessionId} · ${formatDateTime(s.startedAt.fields)} · '
        '${storedLifecycleText(s.lifecycle)} · Cobertura $coverage';
  }
}
