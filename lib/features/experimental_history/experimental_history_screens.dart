import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/design_system/vigia_icons.dart';
import '../../core/design_system/widgets/notice_host.dart';
import '../../core/design_system/widgets/vigia_blocks.dart';
import '../../core/design_system/widgets/vigia_button.dart';
import '../../core/design_system/widgets/vigia_option.dart';
import '../../core/design_system/widgets/vigia_scaffold.dart';
import '../../data/experimental_history/experimental_history_providers.dart';
import '../../data/experimental_history/experimental_history_repository.dart';
import '../account/firebase_account.dart';
import '../monitoring/domain/session_summary.dart';
import 'cloud_history_section.dart';
import 'experimental_history_blocks.dart';

/// Filtro elegido en esta ejecución (UX §2.1).
final experimentalHistoryFilterProvider =
    NotifierProvider<_FilterNotifier, ExperimentalHistoryFilter>(
      _FilterNotifier.new,
    );

class _FilterNotifier extends Notifier<ExperimentalHistoryFilter> {
  @override
  ExperimentalHistoryFilter build() => ExperimentalHistoryFilter.all;

  void set(ExperimentalHistoryFilter f) => state = f;
}

/// P08 · Historial de la variante normal (fase 5D; composición de B5.2
/// `vP08`). Lista las sesiones experimentales reales guardadas, la más
/// reciente primero, con fecha, estado y cobertura. Las interrumpidas no se
/// ocultan ni se presentan como finalizadas. Vacío, cargando y error son
/// estados distintos. Sin exportación, borrado ni tendencias.
class ExperimentalHistoryScreen extends ConsumerStatefulWidget {
  const ExperimentalHistoryScreen({super.key});

  @override
  ConsumerState<ExperimentalHistoryScreen> createState() =>
      _ExperimentalHistoryScreenState();
}

class _ExperimentalHistoryScreenState
    extends ConsumerState<ExperimentalHistoryScreen>
    with JournalSyncOnMount, NoticeHost {
  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(experimentalHistoryFilterProvider);
    final available = ref.watch(experimentalHistoryRepositoryProvider) != null;
    final sync = ref.watch(journalSyncProvider);
    final uid = ref.watch(verifiedFirebaseUidProvider);
    void home() => context.go(VigiaRoutes.inicio);
    final list = available
        ? ref.watch(experimentalHistoryListProvider(filter))
        : null;

    final children = <Widget>[
      const ExperimentalDataBanner(),
      if (sync.status == JournalSyncStatus.stopped ||
          sync.status == JournalSyncStatus.failed)
        StatusCard(
          key: const Key('history-sync-problem'),
          tone: StatusTone.alert,
          icon: VigiaIcon.warn,
          tag: 'Registro pendiente',
          title: 'Hay registros sin importar',
          text:
              '${ExperimentalHistoryText.stop(sync.stop)} Se conservan en el '
              'motor; la lista puede estar incompleta.',
        ),
      const VigiaSectionTitle('Mostrar'),
      VigiaOptionGroup(
        options: [
          for (final (f, label) in const [
            (ExperimentalHistoryFilter.all, 'Todas'),
            (ExperimentalHistoryFilter.finalized, 'Finalizadas'),
            (ExperimentalHistoryFilter.interrupted, 'Interrumpidas'),
          ])
            VigiaOption(
              label: label,
              selected: filter == f,
              onSelected: () =>
                  ref.read(experimentalHistoryFilterProvider.notifier).set(f),
            ),
        ],
      ),
      ...switch (list) {
        null => const [
          StatusCard(
            tone: StatusTone.neutral,
            icon: VigiaIcon.info,
            tag: 'Historial',
            title: 'Historial no disponible',
            text: 'En esta ejecución no se abrió el historial experimental.',
          ),
        ],
        AsyncData(:final value) when value.isEmpty && !list.isLoading => [
          StatusCard(
            tone: StatusTone.plain,
            icon: VigiaIcon.info,
            tag: 'Historial',
            title: filter == ExperimentalHistoryFilter.all
                ? (uid == null
                      ? 'Aún no hay sesiones experimentales'
                      : 'Sin sesiones en este teléfono')
                : (uid == null
                      ? 'No hay sesiones con este filtro'
                      : 'Sin sesiones locales con este filtro'),
            text: filter == ExperimentalHistoryFilter.all
                ? 'Las sesiones experimentales finalizadas o interrumpidas '
                      'aparecerán aquí.'
                : 'Elige «Todas» para ver todo el historial.',
          ),
        ],
        AsyncData(:final value) when !list.isLoading => [
          const VigiaParagraph('Más reciente primero.', secondary: true),
          for (final s in value)
            VigiaButton(
              key: Key('history-${s.sessionId}'),
              label: rowLabel(s),
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
            onPressed: () => ref.invalidate(experimentalHistoryListProvider),
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
      if (uid != null)
        CloudHistorySection(
          key: ValueKey(uid),
          uid: uid,
          filter: filter,
          localIds: {
            for (final row
                in list?.asData?.value ?? const <ExperimentalSessionRecord>[])
              if (row.accountId == uid) row.sessionId,
          },
        ),
      const VigiaParagraph(
        'Tendencias, valoración, exportación y borrado no forman parte de '
        'este prototipo.',
        secondary: true,
      ),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) home();
      },
      child: VigiaScaffold(
        title: 'Historial',
        navIndex: 1,
        sideNavigation: true,
        accountDestination: ref.watch(firebaseAuthProvider) != null,
        notice: notice,
        onNavSelected: (i) {
          if (i == 0) home();
          if (i == 2) context.go(VigiaRoutes.ajustes);
          if (i == 3) context.go(VigiaRoutes.cuenta);
        },
        children: children,
      ),
    );
  }

  /// «Experimental · a1b2c3d4 · 15/10/2026 08:12 · Finalizada · Cobertura 75,0 %».
  static String rowLabel(ExperimentalSessionRecord s) =>
      'Experimental · ${ExperimentalHistoryText.shortId(s.sessionId)} · '
      '${formatDateTime(s.startedAt.fields)} · '
      '${ExperimentalHistoryText.lifecycle(s.lifecycle)} · '
      'Cobertura ${ExperimentalHistoryText.coverage(s.totals)}';
}

/// P09 · Detalle de una sesión experimental guardada (fase 5D; B5.2 `vP09`).
class ExperimentalSessionDetailScreen extends ConsumerStatefulWidget {
  const ExperimentalSessionDetailScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<ExperimentalSessionDetailScreen> createState() =>
      _ExperimentalSessionDetailScreenState();
}

class _ExperimentalSessionDetailScreenState
    extends ConsumerState<ExperimentalSessionDetailScreen>
    with JournalSyncOnMount {
  @override
  Widget build(BuildContext context) {
    void back() => context.go(VigiaRoutes.historial);
    final available = ref.watch(experimentalHistoryRepositoryProvider) != null;
    final children = <Widget>[
      const ExperimentalDataBanner(),
      if (!available)
        const StatusCard(
          tone: StatusTone.neutral,
          icon: VigiaIcon.info,
          tag: 'Historial',
          title: 'Historial no disponible',
          text: 'En esta ejecución no se abrió el historial experimental.',
        )
      else
        ..._content(
          ref.watch(experimentalSessionProvider(widget.sessionId)),
          ref.watch(experimentalMarksProvider(widget.sessionId)),
        ),
    ];
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) back();
      },
      child: VigiaScaffold(
        title: 'Detalle de sesión',
        onBack: back,
        children: children,
      ),
    );
  }

  List<Widget> _content(
    AsyncValue<ExperimentalSessionRecord?> session,
    AsyncValue<List<ExperimentalMark>> marks,
  ) {
    if (session is AsyncError || marks is AsyncError) {
      return [
        const StatusCard(
          tone: StatusTone.alert,
          icon: VigiaIcon.close,
          tag: 'Error',
          title: 'No se pudo cargar la sesión',
          text: 'Esto no significa que la sesión no exista.',
        ),
        VigiaButton(
          label: 'Reintentar',
          kind: VigiaButtonKind.secondary,
          onPressed: () {
            ref.invalidate(experimentalSessionProvider(widget.sessionId));
            ref.invalidate(experimentalMarksProvider(widget.sessionId));
          },
        ),
      ];
    }
    final s = session.value;
    final m = marks.value;
    if (session is! AsyncData ||
        session.isLoading ||
        marks.isLoading ||
        m == null) {
      return const [
        StatusCard(
          tone: StatusTone.pending,
          icon: VigiaIcon.clock,
          tag: 'Carga',
          title: 'Cargando sesión',
          text: 'Leyendo el registro del teléfono.',
        ),
      ];
    }
    if (s == null) {
      return [
        const StatusCard(
          tone: StatusTone.neutral,
          icon: VigiaIcon.info,
          tag: 'Historial',
          title: 'Sesión no encontrada',
          text: 'Esta sesión no está en el historial de este teléfono.',
        ),
        KeyValueRow(label: 'Sesión', value: widget.sessionId),
      ];
    }
    return [
      KeyValueRow(label: 'Sesión', value: s.sessionId),
      KeyValueRow(
        label: 'Origen',
        value: 'Real · ${s.qualificationStatus} (${s.profileId})',
      ),
      KeyValueRow(
        label: 'Estado',
        value: ExperimentalHistoryText.lifecycle(s.lifecycle),
      ),
      KeyValueRow(
        label: 'Inicio confirmado',
        value: formatDateTime(s.startedAt.fields),
      ),
      if (s.isFinalized && s.complete) ..._finalized(s, s.totals!, m),
      if (s.isFinalized && !s.complete) ...[
        ...experimentalIncompleteBlocks(s),
        const VigiaSectionTitle('Hechos confirmados'),
        ..._markRows(s, m),
      ],
      if (s.isInterrupted) ..._interrupted(s, m),
      if (s.isOpen)
        const StatusCard(
          tone: StatusTone.pending,
          icon: VigiaIcon.clock,
          tag: 'Registro en curso',
          title: 'Sin cierre guardado todavía',
          text:
              'El motor no ha confirmado el cierre de esta sesión. Si la app '
              'se cerró, al reabrirla se registrará como interrumpida.',
        ),
      const VigiaSectionTitle('Referencia y versiones'),
      KeyValueRow(label: 'Calibración', value: s.calibrationId),
      KeyValueRow(
        label: 'Ojos abiertos (EAR)',
        value:
            'Der. ${ExperimentalHistoryText.decimal(s.openEarRight)} · '
            'Izq. ${ExperimentalHistoryText.decimal(s.openEarLeft)} · '
            '${s.calibrationSamples} observaciones',
      ),
      KeyValueRow(label: 'Modelo', value: s.modelId),
      KeyValueRow(
        label: 'Perfil',
        value: '${s.profileId} · ${s.qualificationStatus}',
      ),
      const VigiaParagraph(
        'Detalle de episodio, valoración, exportación y eliminación no forman '
        'parte de este prototipo.',
        secondary: true,
      ),
    ];
  }

  List<Widget> _finalized(
    ExperimentalSessionRecord s,
    ExperimentalTotals t,
    List<ExperimentalMark> m,
  ) => [
    KeyValueRow(
      label: 'Cierre confirmado',
      value: formatDateTime(s.endedAt!.fields),
    ),
    KeyValueRow(label: 'Registro', value: ExperimentalHistoryText.record(s)),
    KeyValueRow(label: 'Tiempo evaluable', value: formatSeconds(t.evaluable)),
    KeyValueRow(
      label: 'Tiempo no evaluable',
      value: formatSeconds(t.notEvaluable),
    ),
    KeyValueRow(label: 'Tiempo pausado', value: formatSeconds(t.paused)),
    KeyValueRow(
      label: 'Total representado',
      value: formatSeconds(t.represented),
    ),
    KeyValueRow(label: 'Cobertura', value: ExperimentalHistoryText.coverage(t)),
    KeyValueRow(
      label: 'Cierres oculares prolongados',
      value: '${t.closureActivations}',
    ),
    KeyValueRow(
      label: 'Tonos de aviso',
      value: '${t.tonesPlayed} iniciados · ${t.tonesFailed} fallidos',
    ),
    const VigiaParagraph(
      'Un tono iniciado es un resultado técnico: no confirma que se oyera. '
      'Las repeticiones del tono pertenecen a la misma activación.',
      secondary: true,
    ),
    const VigiaSectionTitle('Línea temporal'),
    KeyValueRow(
      label: formatTimeOfDay(s.startedAt.fields),
      value: 'Inicio confirmado',
    ),
    ..._markRows(s, m),
    KeyValueRow(
      label: formatTimeOfDay(s.endedAt!.fields),
      value: 'Cierre confirmado · ${formatOffset(s.endOffset!)}',
    ),
  ];

  List<Widget> _interrupted(
    ExperimentalSessionRecord s,
    List<ExperimentalMark> m,
  ) {
    final closures = m
        .where((e) => e.kind == ExperimentalMarkKind.closure)
        .length;
    final tones = m
        .where(
          (e) =>
              e.kind == ExperimentalMarkKind.playback && e.status == 'started',
        )
        .length;
    final k = s.known;
    return [
      KeyValueRow(
        label: 'Último registro confirmado',
        value:
            '${formatTimeOfDay(s.latestDurableAt.fields)} · '
            '${formatOffset(s.latestDurableOffset)}',
      ),
      const KeyValueRow(label: 'Final', value: 'Desconocido'),
      const KeyValueRow(label: 'Duración', value: 'No disponible'),
      const KeyValueRow(label: 'Cobertura', value: 'No disponible'),
      if (k != null)
        KeyValueRow(
          label: 'Evaluable confirmado hasta ${formatOffset(k.through)}',
          value: formatSeconds(k.evaluable),
        ),
      KeyValueRow(label: 'Cierres prolongados confirmados', value: '$closures'),
      KeyValueRow(label: 'Tonos iniciados confirmados', value: '$tones'),
      const VigiaParagraph(
        'Solo se muestran registros confirmados. La sesión no se reanudó y el '
        'tiempo hasta la reapertura no cuenta como medición.',
        secondary: true,
      ),
      const VigiaSectionTitle('Línea temporal'),
      KeyValueRow(
        label: formatTimeOfDay(s.startedAt.fields),
        value: 'Inicio confirmado',
      ),
      ..._markRows(s, m),
      KeyValueRow(
        label: formatTimeOfDay(s.latestDurableAt.fields),
        value:
            'Último registro confirmado · '
            '${formatOffset(s.latestDurableOffset)}',
      ),
      const KeyValueRow(label: 'Final', value: 'Desconocido'),
    ];
  }

  /// Un renglón por hecho confirmado: activación, tono o pausa.
  List<Widget> _markRows(
    ExperimentalSessionRecord s,
    List<ExperimentalMark> m,
  ) => [
    for (final e in m)
      KeyValueRow(
        label: formatTimeOfDay(s.startedAt.plus(e.offset).fields),
        value: '${_markText(e)} · ${formatOffset(e.offset)}',
      ),
  ];

  static String _markText(ExperimentalMark e) => switch (e.kind) {
    ExperimentalMarkKind.closure => 'Cierre ocular prolongado ${e.ordinal}',
    ExperimentalMarkKind.playback =>
      e.status == 'started'
          ? 'Tono iniciado (aviso ${e.ordinal})'
          : 'Tono fallido (aviso ${e.ordinal})',
    ExperimentalMarkKind.pauseStarted => 'Pausa ${e.ordinal}',
    ExperimentalMarkKind.pauseEnded => 'Reanudada ${e.ordinal}',
  };
}

/// P07 · Resumen guardado de una sesión experimental (fase 5D). Lee la
/// proyección, no el estado en memoria del motor.
class ExperimentalSummaryScreen extends ConsumerStatefulWidget {
  const ExperimentalSummaryScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<ExperimentalSummaryScreen> createState() =>
      _ExperimentalSummaryScreenState();
}

class _ExperimentalSummaryScreenState
    extends ConsumerState<ExperimentalSummaryScreen>
    with JournalSyncOnMount {
  @override
  String? get awaitedSessionId => widget.sessionId;

  @override
  Widget build(BuildContext context) {
    void home() => context.go(VigiaRoutes.inicio);
    final available = ref.watch(experimentalHistoryRepositoryProvider) != null;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) home();
      },
      child: VigiaScaffold(
        title: 'Resumen',
        onBack: home,
        children: [
          const ExperimentalDataBanner(),
          ...experimentalSummaryBlocks(
            available
                ? ref.watch(experimentalSessionProvider(widget.sessionId))
                : const AsyncData(null),
            ref.watch(journalSyncProvider),
            historyAvailable: available,
          ),
          VigiaButton(
            label: 'Ver detalle',
            kind: VigiaButtonKind.secondary,
            onPressed: () => context.go(VigiaRoutes.detalle(widget.sessionId)),
          ),
          VigiaButton(label: 'Volver al inicio', onPressed: home),
        ],
      ),
    );
  }
}
