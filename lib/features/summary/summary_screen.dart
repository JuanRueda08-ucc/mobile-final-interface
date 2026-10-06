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
import '../monitoring/demo_session_controller.dart';
import '../monitoring/domain/session_summary.dart';

/// P07 · Resumen (FL07, RF21; B5.2 `vP07`).
///
/// Calculado desde los eventos de la sesión ([SessionSummary.fromEvents]).
/// En esta fase vive en memoria: no se presenta como guardado; el historial
/// persistente llega en la fase 3. Volver lleva a Inicio y no reabre el
/// monitoreo cerrado (UX12.CA3).
class SummaryScreen extends ConsumerStatefulWidget {
  const SummaryScreen({super.key});

  static const detailNotice =
      'Detalle de sesión llega con el Historial en la fase 3.';

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> with NoticeHost {
  @override
  Widget build(BuildContext context) {
    final s = ref.watch(lastSummaryProvider);
    if (s == null) return const SizedBox.shrink(); // la guarda redirige
    final full = s.coverage != null;
    void home() => context.go(VigiaRoutes.inicio);
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
        children: [
          const StatusCard(
            tone: StatusTone.strong,
            icon: VigiaIcon.check,
            tag: 'Completo · en memoria',
            title: 'Resumen de la sesión',
            text:
                'Calculado desde los eventos simulados de esta sesión. Se '
                'conserva solo durante esta ejecución; el historial '
                'persistente llega en la fase 3.',
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
          KeyValueRow(label: 'Episodios', value: '${s.episodes}'),
          KeyValueRow(label: 'Advertencias', value: '${s.warnings}'),
          KeyValueRow(
            label: 'Cierres oculares prolongados',
            value: '${s.closures}',
          ),
          KeyValueRow(
            label: 'Avisos sonoros',
            value:
                '${s.soundsPlayed} reproducidos · ${s.soundsFailed} fallidos',
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
            onPressed: () => showNotice(SummaryScreen.detailNotice),
          ),
          VigiaButton(label: 'Volver al inicio', onPressed: home),
        ],
      ),
    );
  }
}
