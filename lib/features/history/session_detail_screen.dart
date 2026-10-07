import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/design_system/vigia_icons.dart';
import '../../core/design_system/widgets/vigia_blocks.dart';
import '../../core/design_system/widgets/vigia_button.dart';
import '../../core/design_system/widgets/vigia_scaffold.dart';
import '../../data/demo_history/demo_history_repository.dart';
import '../../data/demo_history/history_providers.dart';
import '../common/session_blocked.dart';
import '../monitoring/demo_session_controller.dart';
import '../monitoring/domain/session_model.dart';
import '../monitoring/domain/session_summary.dart';
import 'history_screen.dart';

/// P09 · Detalle de sesión (FL09, RF21–RF23; B5.2 `vP09`).
///
/// Muestra la sesión guardada con el mismo ID elegido en la lista (UX15.CA2):
/// - Finalizada: tiempos, cobertura, episodios y línea temporal, desde los
///   totales guardados al cierre y sus hechos.
/// - Interrumpida: solo lo confirmado; final desconocido, duración y
///   cobertura no disponibles, sin contar el tiempo hasta la reapertura
///   (RF19.CA2, UX13.CA2).
///
/// Con sesión vigente no se abre (UX §4.2): muestra «Sesión en curso».
/// Detalle de episodio (P10), exportación y borrado no forman parte de este
/// prototipo.
class SessionDetailScreen extends ConsumerWidget {
  const SessionDetailScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vigente = ref.watch(demoSessionProvider.select((s) => s.isVigente));
    void back() => context.go(VigiaRoutes.historial);
    final children = vigente
        ? sessionBlockedBlocks(context, 'Detalle de sesión')
        : _content(
            ref.watch(storedSessionProvider(sessionId)),
            ref.watch(storedEventsProvider(sessionId)),
            () {
              ref.invalidate(storedSessionProvider(sessionId));
              ref.invalidate(storedEventsProvider(sessionId));
            },
          );
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) back();
      },
      child: VigiaScaffold(
        title: 'Detalle de sesión',
        isDemo: true,
        onBack: back,
        children: children,
      ),
    );
  }

  List<Widget> _content(
    AsyncValue<StoredSession?> session,
    AsyncValue<List<SessionEvent>> events,
    VoidCallback retry,
  ) {
    if (session is AsyncError || events is AsyncError) {
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
          onPressed: retry,
        ),
      ];
    }
    final s = session.value;
    final ev = events.value;
    if (session is! AsyncData || ev == null) {
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
        KeyValueRow(label: 'Sesión', value: sessionId),
      ];
    }
    final summary = s.summary;
    return [
      KeyValueRow(label: 'Sesión', value: s.sessionId),
      KeyValueRow(
        label: 'Origen',
        value: s.isDemo ? 'DEMO — datos simulados' : 'Desconocido',
      ),
      KeyValueRow(label: 'Estado', value: storedLifecycleText(s.lifecycle)),
      KeyValueRow(
        label: 'Inicio confirmado',
        value: formatDateTime(s.startedAt.fields),
      ),
      if (summary != null)
        ..._finalized(s, summary, ev)
      else if (s.isInterrupted)
        ..._interrupted(s, ev)
      else
        const StatusCard(
          tone: StatusTone.pending,
          icon: VigiaIcon.clock,
          tag: 'Guardando',
          title: 'Resumen pendiente de completar',
          text: 'El cierre de esta sesión todavía se está guardando.',
        ),
      const VigiaParagraph(
        'Detalle de episodio, valoración, exportación y eliminación no forman '
        'parte de este prototipo.',
        secondary: true,
      ),
    ];
  }

  List<Widget> _finalized(
    StoredSession s,
    SessionSummary m,
    List<SessionEvent> ev,
  ) => [
    KeyValueRow(
      label: 'Cierre confirmado',
      value: formatTimeOfDay(s.endedAt!.fields),
    ),
    KeyValueRow(label: 'Tiempo evaluable', value: formatSeconds(m.evaluable)),
    KeyValueRow(
      label: 'Tiempo no evaluable',
      value: formatSeconds(m.notEvaluable),
    ),
    KeyValueRow(label: 'Tiempo pausado', value: formatSeconds(m.paused)),
    KeyValueRow(
      label: 'Desconocido (acotado)',
      value: formatSeconds(m.unknown),
    ),
    KeyValueRow(
      label: 'Total representado',
      value: formatSeconds(m.represented),
    ),
    KeyValueRow(
      label: 'Tiempo monitoreado (sin pausas)',
      value: formatSeconds(m.monitored),
    ),
    KeyValueRow(label: 'Cobertura', value: m.coverageText),
    KeyValueRow(label: 'Episodios', value: '${m.episodes}'),
    KeyValueRow(
      label: 'Avisos sonoros',
      value: '${m.soundsPlayed} reproducidos · ${m.soundsFailed} fallidos',
    ),
    const VigiaParagraph(
      'Las repeticiones del sonido pertenecen al mismo episodio y no suman '
      'episodios.',
      secondary: true,
    ),
    const VigiaSectionTitle('Línea temporal'),
    KeyValueRow(
      label: formatTimeOfDay(s.startedAt.fields),
      value: 'Inicio confirmado',
    ),
    ..._episodeRows(s, ev, interrupted: false),
    KeyValueRow(
      label: 'Pausas',
      value: m.pauses == 0
          ? 'Ninguna'
          : '${m.pauses} · ${formatSeconds(m.paused)} en total',
    ),
    KeyValueRow(
      label: formatTimeOfDay(s.endedAt!.fields),
      value: 'Cierre confirmado',
    ),
    KeyValueRow(label: 'Referencia', value: s.calibrationId),
    const KeyValueRow(
      label: 'Versiones',
      value: 'Modelo y política: simulados',
    ),
  ];

  List<Widget> _interrupted(StoredSession s, List<SessionEvent> ev) {
    final episodes = ev
        .where((e) => e.type == SessionEventType.episodeStarted)
        .map((e) => e.episodeId)
        .toSet()
        .length;
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
      KeyValueRow(label: 'Episodios confirmados', value: '$episodes'),
      const VigiaParagraph(
        'Solo se muestran registros confirmados. El tiempo hasta la reapertura '
        'no cuenta como medición.',
        secondary: true,
      ),
      const VigiaSectionTitle('Línea temporal'),
      KeyValueRow(
        label: formatTimeOfDay(s.startedAt.fields),
        value: 'Inicio confirmado',
      ),
      ..._episodeRows(s, ev, interrupted: true),
      KeyValueRow(
        label: formatTimeOfDay(s.latestDurableAt.fields),
        value:
            'Último registro confirmado · '
            '${formatOffset(s.latestDurableOffset)}',
      ),
      const KeyValueRow(label: 'Final', value: 'Desconocido'),
      KeyValueRow(label: 'Referencia', value: s.calibrationId),
    ];
  }

  /// Un renglón por episodio, en orden: hora, número, categoría y
  /// desplazamiento. En una interrumpida, el que no se cerró dice «sin final».
  List<Widget> _episodeRows(
    StoredSession s,
    List<SessionEvent> ev, {
    required bool interrupted,
  }) {
    final ended = {
      for (final e in ev)
        if (e.type == SessionEventType.episodeEnded) e.episodeId,
    };
    var n = 0;
    return [
      for (final e in ev)
        if (e.type == SessionEventType.episodeStarted)
          KeyValueRow(
            label: formatTimeOfDay(s.startedAt.plus(e.offset).fields),
            value:
                'Episodio ${++n} · '
                '${e.episodeKind == EpisodeKind.warning ? 'Advertencia' : 'Cierre ocular prolongado'}'
                ' · ${formatOffset(e.offset)}'
                '${interrupted && !ended.contains(e.episodeId) ? ' · sin final' : ''}',
          ),
    ];
  }
}
