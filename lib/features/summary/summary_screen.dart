import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/design_system/tokens.dart';
import '../../core/design_system/vigia_icons.dart';
import '../../core/design_system/widgets/aura_hero.dart';
import '../../core/design_system/widgets/notice_host.dart';
import '../../core/design_system/widgets/vigia_blocks.dart';
import '../../core/design_system/widgets/vigia_button.dart';
import '../../core/design_system/widgets/vigia_flow_blocks.dart';
import '../../core/design_system/widgets/vigia_scaffold.dart';
import '../../data/demo_history/demo_history_repository.dart';
import '../../data/demo_history/history_providers.dart';
import '../monitoring/domain/session_summary.dart';

/// P07 · Resumen (FL07, RF21; B5.2 `vP07`).
///
/// Lee la sesión guardada en el historial DEMO, con los totales que se
/// calcularon una sola vez desde sus eventos al confirmar el cierre. Es el
/// mismo dato que muestran Inicio y el detalle del Historial. Mientras el
/// cierre se guarda muestra «Resumen pendiente de completar»; si la escritura
/// falló, «Registro incompleto» (RF21.CA3). Volver lleva a Inicio y no reabre
/// el monitoreo cerrado (UX12.CA3).
class SummaryScreen extends ConsumerStatefulWidget {
  const SummaryScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> with NoticeHost {
  @override
  Widget build(BuildContext context) {
    final stored = ref.watch(storedSessionProvider(widget.sessionId));
    final failure = ref.watch(historySyncProvider.select((s) => s.failure));
    void home() => context.go(VigiaRoutes.inicio);
    final s = stored.value?.summary;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) home();
      },
      child: VigiaScaffold(
        title: 'Resumen',
        isDemo: true,
        onBack: home,
        notice: notice,
        children: s == null
            ? _notReady(stored, failure, home)
            : _summary(s, home),
      ),
    );
  }

  /// Sin totales guardados: pendiente, fallo, interrumpida o inexistente.
  List<Widget> _notReady(
    AsyncValue<StoredSession?> stored,
    String? failure,
    VoidCallback home,
  ) {
    final v = stored.value;
    final card = switch ((stored, v)) {
      (AsyncError(), _) => const StatusCard(
        tone: StatusTone.alert,
        icon: VigiaIcon.close,
        tag: 'Error',
        title: 'No se pudo cargar el historial',
        text: 'Esto no significa que la sesión no exista.',
      ),
      (_, StoredSession(isInterrupted: true)) => const StatusCard(
        tone: StatusTone.alert,
        icon: VigiaIcon.warn,
        tag: 'Interrumpida',
        title: 'Extremo final desconocido',
        text:
            'No hay cierre confirmado: no se calcula duración ni cobertura. '
            'Solo se conservan los registros confirmados.',
      ),
      _ when failure != null => StatusCard(
        tone: StatusTone.alert,
        icon: VigiaIcon.warn,
        tag: 'Incompleto',
        title: 'Registro incompleto',
        text: '$failure No se muestra un resumen definitivo.',
      ),
      (AsyncData(), null) => const StatusCard(
        tone: StatusTone.neutral,
        icon: VigiaIcon.info,
        tag: 'Historial',
        title: 'Sesión no encontrada',
        text: 'Esta sesión no está en el historial de este teléfono.',
      ),
      _ => const StatusCard(
        tone: StatusTone.pending,
        icon: VigiaIcon.clock,
        tag: 'Guardando',
        title: 'Resumen pendiente de completar',
        text: 'Guardando el cierre de la sesión en el historial.',
      ),
    };
    return [
      card,
      KeyValueRow(label: 'Sesión', value: widget.sessionId),
      if (v != null)
        VigiaButton(
          label: 'Ver detalle',
          kind: VigiaButtonKind.secondary,
          onPressed: () => context.go(VigiaRoutes.detalle(widget.sessionId)),
        ),
      VigiaButton(label: 'Volver al inicio', onPressed: home),
    ];
  }

  List<Widget> _summary(SessionSummary s, VoidCallback home) {
    final full = s.coverage != null;
    return [
      const StatusCard(
        tone: StatusTone.strong,
        icon: VigiaIcon.check,
        tag: 'Completo · guardado',
        title: 'Resumen de la sesión',
        text:
            'Calculado desde los eventos simulados de esta sesión y '
            'guardado en el historial DEMO de este teléfono.',
      ),
      AuraHero(
        animate: false,
        minHeight: 170,
        c0: VigiaAura.lilac,
        c1: VigiaAura.pink,
        titleSize: full ? 44 : 32,
        tag: 'Cobertura',
        title: s.coverageText,
        text: 'Cobertura de medición de esta sesión',
      ),
      KeyValueRow(label: 'Sesión', value: s.sessionId),
      KeyValueRow(
        label: 'Inicio confirmado',
        value: formatTimeOfDay(s.startedAt),
      ),
      KeyValueRow(
        label: 'Cierre confirmado',
        value: formatTimeOfDay(s.finishedAt),
      ),
      DistributionBar(
        segments: [
          DistributionSegment(
            'Evaluable',
            formatSeconds(s.evaluable),
            s.evaluable.inMilliseconds.toDouble(),
          ),
          DistributionSegment(
            'No evaluable',
            formatSeconds(s.notEvaluable),
            s.notEvaluable.inMilliseconds.toDouble(),
          ),
          DistributionSegment(
            'Pausado',
            formatSeconds(s.paused),
            s.paused.inMilliseconds.toDouble(),
          ),
          DistributionSegment(
            'Desconocido (acotado)',
            formatSeconds(s.unknown),
            s.unknown.inMilliseconds.toDouble(),
          ),
        ],
      ),
      KeyValueRow(
        label: 'Total representado',
        value: formatSeconds(s.represented),
      ),
      KeyValueRow(
        label: 'Tiempo monitoreado (sin pausas)',
        value: formatSeconds(s.monitored),
      ),
      KeyValueRow(label: 'Episodios', value: '${s.episodes}'),
      KeyValueRow(label: 'Advertencias', value: '${s.warnings}'),
      KeyValueRow(
        label: 'Cierres oculares prolongados',
        value: '${s.closures}',
      ),
      KeyValueRow(
        label: 'Avisos sonoros',
        value: '${s.soundsPlayed} reproducidos · ${s.soundsFailed} fallidos',
      ),
      VigiaParagraph(
        full
            ? 'Cobertura: ${formatSeconds(s.evaluable)} evaluables sobre '
                  '${formatSeconds(s.evaluable + s.notEvaluable)} evaluables '
                  'o no evaluables. Las pausas y el tiempo desconocido no '
                  'entran en el denominador. Los avisos sonoros no cuentan '
                  'como episodios.'
            : 'Sin tiempo evaluable ni no evaluable, la cobertura no está '
                  'disponible.',
        secondary: true,
      ),
      VigiaButton(
        label: 'Ver detalle',
        kind: VigiaButtonKind.secondary,
        onPressed: () => context.go(VigiaRoutes.detalle(s.sessionId)),
      ),
      VigiaButton(label: 'Volver al inicio', onPressed: home),
    ];
  }
}
