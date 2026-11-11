import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/tokens.dart';
import '../../core/design_system/vigia_icons.dart';
import '../../core/design_system/widgets/aura_hero.dart';
import '../../core/design_system/widgets/vigia_blocks.dart';
import '../../core/design_system/widgets/vigia_flow_blocks.dart';
import '../../data/experimental_history/experimental_history_providers.dart';
import '../../data/experimental_history/experimental_history_repository.dart';
import '../monitoring/domain/session_summary.dart';

/// Textos y bloques comunes del historial experimental real (fase 5D). Inicio,
/// Resumen, Historial y detalle leen el mismo [ExperimentalSessionRecord] de
/// la proyección Drift; ninguno usa el estado en memoria del motor.
abstract final class ExperimentalHistoryText {
  static const bannerText =
      'Sesiones medidas con la cámara de este teléfono, con valores de '
      'laboratorio sin validar (perfil lab-eye-rules-0.1). No son una ayuda '
      'para conducir ni una medida de fatiga. Se guardan solo tiempos y '
      'contadores; no imágenes ni puntos de la cara.';

  /// «a1b2c3d4»: inicio del identificador único, para listas.
  static String shortId(String id) => id.length <= 8 ? id : id.substring(0, 8);

  static String lifecycle(ExperimentalLifecycle l) => switch (l) {
    ExperimentalLifecycle.finalized => 'Finalizada',
    ExperimentalLifecycle.interrupted => 'Interrumpida',
    ExperimentalLifecycle.active ||
    ExperimentalLifecycle.paused => 'Registro en curso',
  };

  static String coverage(ExperimentalTotals? t) {
    final c = t?.coverage;
    if (c == null) return 'No disponible';
    return '${(c * 100).toStringAsFixed(1).replaceAll('.', ',')} %';
  }

  static String record(ExperimentalSessionRecord s) =>
      s.complete ? 'Completo · guardado' : 'Registro incompleto';

  static String decimal(double v) => v.toStringAsFixed(2).replaceAll('.', ',');

  /// Motivo legible de una importación detenida (sin datos personales).
  static String stop(ImportStop? s) => switch (s) {
    ImportStop.integrity =>
      'Un registro del motor no superó la comprobación de integridad.',
    ImportStop.gap => 'Falta un registro anterior del motor.',
    ImportStop.schema => 'Un registro tiene un formato no admitido.',
    ImportStop.relation => 'Un registro no encaja con su sesión.',
    null => 'No se pudo leer el registro del motor.',
  };
}

/// Rótulo permanente de los datos experimentales reales.
class ExperimentalDataBanner extends StatelessWidget {
  const ExperimentalDataBanner({super.key});

  @override
  Widget build(BuildContext context) => const StatusCard(
    key: Key('experimental-data-banner'),
    tone: StatusTone.warn,
    icon: VigiaIcon.warn,
    tag: 'Experimental · datos reales',
    title: 'Sesiones experimentales',
    text: ExperimentalHistoryText.bannerText,
  );
}

/// Pide importar el journal al montarse y, mientras la sesión [sessionId]
/// no tenga cierre ni interrupción guardados, vuelve a pedirlo cada
/// [retry]. No depende de que llegue el último aviso del motor.
mixin JournalSyncOnMount<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  static const retry = Duration(seconds: 1);
  Timer? _syncTimer;
  int _attempts = 0;

  /// Sesión que se espera ver cerrada, o nula si basta con una importación.
  String? get awaitedSessionId => null;

  @override
  void initState() {
    super.initState();
    Future.microtask(_tick);
  }

  /// Vuelve a importar ahora (p. ej. al confirmarse un cierre).
  void requestJournalSync() {
    _syncTimer?.cancel();
    _attempts = 0;
    _tick();
  }

  void _tick() {
    if (!mounted) return;
    _attempts++;
    final notifier = ref.read(journalSyncProvider.notifier);
    if (ref.read(experimentalHistoryRepositoryProvider) == null) return;
    notifier.sync().whenComplete(() {
      if (!mounted) return;
      final id = awaitedSessionId;
      if (id == null) return;
      final s = ref.read(experimentalSessionProvider(id)).value;
      if ((s == null || s.isOpen) && _attempts < 5) {
        _syncTimer?.cancel();
        _syncTimer = Timer(retry, _tick);
      }
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}

/// Resumen (P07) de una sesión experimental guardada: los mismos datos que
/// el Historial y el detalle.
List<Widget> experimentalSummaryBlocks(
  AsyncValue<ExperimentalSessionRecord?> stored,
  JournalSyncState sync, {
  required bool historyAvailable,
}) {
  if (!historyAvailable) {
    return const [
      StatusCard(
        key: Key('summary-unavailable'),
        tone: StatusTone.neutral,
        icon: VigiaIcon.info,
        tag: 'Historial',
        title: 'Historial no disponible',
        text: 'En esta ejecución no se abrió el historial experimental.',
      ),
    ];
  }
  final s = stored.isLoading ? null : stored.value;
  if (stored is AsyncError) {
    return const [
      StatusCard(
        tone: StatusTone.alert,
        icon: VigiaIcon.close,
        tag: 'Error',
        title: 'No se pudo cargar el historial',
        text: 'Esto no significa que la sesión no exista.',
      ),
    ];
  }
  if (s == null || s.isOpen) {
    final failed =
        sync.status == JournalSyncStatus.failed ||
        sync.status == JournalSyncStatus.stopped;
    return [
      if (sync.status == JournalSyncStatus.upToDate)
        const StatusCard(
          key: Key('summary-pending'),
          tone: StatusTone.alert,
          icon: VigiaIcon.warn,
          tag: 'Registro incompleto',
          title: 'Cierre no confirmado',
          text:
              'No hay un cierre guardado en el registro del motor. '
              'Los totales no están disponibles. Puedes volver al inicio; '
              'al reabrir la app se recuperará el registro sin inventar un final.',
        )
      else
        failed
            ? StatusCard(
                key: const Key('summary-pending'),
                tone: StatusTone.alert,
                icon: VigiaIcon.warn,
                tag: 'Registro pendiente',
                title: 'Resumen pendiente de completar',
                text:
                    '${ExperimentalHistoryText.stop(sync.stop)} El registro se '
                    'conserva en el motor y se volverá a leer.',
              )
            : const StatusCard(
                key: Key('summary-pending'),
                tone: StatusTone.pending,
                icon: VigiaIcon.clock,
                tag: 'Guardando',
                title: 'Resumen pendiente de completar',
                text:
                    'Leyendo el cierre confirmado desde el registro del motor.',
              ),
    ];
  }
  if (s.isInterrupted) return experimentalInterruptedBlocks(s);
  if (!s.complete) return experimentalIncompleteBlocks(s);
  final t = s.totals!;
  final full = t.coverage != null;
  return [
    StatusCard(
      key: const Key('summary-saved'),
      tone: s.complete ? StatusTone.strong : StatusTone.alert,
      icon: s.complete ? VigiaIcon.check : VigiaIcon.warn,
      tag: ExperimentalHistoryText.record(s),
      title: 'Resumen de la sesión experimental',
      text: s.complete
          ? 'Calculado por el motor con la cámara y guardado en el historial '
                'de este teléfono.'
          : 'El motor declaró ${s.recordsLost} registros no guardados: los '
                'totales son los del motor, pero la línea temporal puede estar '
                'incompleta.',
    ),
    AuraHero(
      animate: false,
      minHeight: 170,
      c0: VigiaAura.lilac,
      c1: VigiaAura.pink,
      titleSize: full ? 44 : 32,
      tag: 'Cobertura',
      title: ExperimentalHistoryText.coverage(t),
      text: 'Cobertura de medición de esta sesión experimental',
    ),
    KeyValueRow(label: 'Sesión', value: s.sessionId),
    KeyValueRow(
      label: 'Inicio confirmado',
      value: formatTimeOfDay(s.startedAt.fields),
    ),
    KeyValueRow(
      label: 'Cierre confirmado',
      value: formatTimeOfDay(s.endedAt!.fields),
    ),
    DistributionBar(
      segments: [
        DistributionSegment(
          'Evaluable',
          formatSeconds(t.evaluable),
          t.evaluable.inMilliseconds.toDouble(),
        ),
        DistributionSegment(
          'No evaluable',
          formatSeconds(t.notEvaluable),
          t.notEvaluable.inMilliseconds.toDouble(),
        ),
        DistributionSegment(
          'Pausado',
          formatSeconds(t.paused),
          t.paused.inMilliseconds.toDouble(),
        ),
      ],
    ),
    KeyValueRow(
      label: 'Total representado',
      value: formatSeconds(t.represented),
    ),
    KeyValueRow(
      label: 'Tiempo monitoreado (sin pausas)',
      value: formatSeconds(t.active),
    ),
    KeyValueRow(
      label: 'Cierres oculares prolongados',
      value: '${t.closureActivations}',
    ),
    KeyValueRow(
      label: 'Tonos de aviso',
      value: '${t.tonesPlayed} iniciados · ${t.tonesFailed} fallidos',
    ),
    KeyValueRow(label: 'Pausas', value: '${t.pauses}'),
    VigiaParagraph(
      full
          ? 'Cobertura: ${formatSeconds(t.evaluable)} evaluables sobre '
                '${formatSeconds(t.active)} monitoreados. Las pausas no entran '
                'en el denominador. Un tono iniciado no confirma que se oyera.'
          : 'Sin tiempo monitoreado, la cobertura no está disponible.',
      secondary: true,
    ),
  ];
}

/// Un cierre durable no convierte un registro con pérdida en totales completos.
List<Widget> experimentalIncompleteBlocks(ExperimentalSessionRecord s) => [
  StatusCard(
    key: const Key('summary-incomplete'),
    tone: StatusTone.alert,
    icon: VigiaIcon.warn,
    tag: 'Registro incompleto',
    title: s.recordsLost > 0
        ? 'Faltan hechos de la sesión'
        : 'Registro sin verificar',
    text: s.recordsLost > 0
        ? 'El motor declaró ${s.recordsLost} registros no guardados. '
              'El cierre está confirmado, pero no se presentan totales completos. '
              'Los hechos guardados se conservan en el detalle.'
        : 'Un hecho no superó la importación. Se conserva pendiente en el motor. '
              'El cierre guardado se conserva, pero los totales no están disponibles.',
  ),
  KeyValueRow(
    label: 'Cierre confirmado',
    value: formatDateTime(s.endedAt!.fields),
  ),
  const KeyValueRow(label: 'Duración', value: 'No disponible'),
  const KeyValueRow(label: 'Cobertura', value: 'No disponible'),
];

/// Sesión interrumpida: solo lo confirmado, sin final, duración ni cobertura.
List<Widget> experimentalInterruptedBlocks(ExperimentalSessionRecord s) {
  final k = s.known;
  return [
    const StatusCard(
      key: Key('summary-interrupted'),
      tone: StatusTone.alert,
      icon: VigiaIcon.warn,
      tag: 'Interrumpida',
      title: 'Sesión interrumpida',
      text:
          'La sesión quedó sin un cierre confirmado. No se reanudó ni se '
          'reinició la cámara. Solo se conservan los registros confirmados.',
    ),
    KeyValueRow(label: 'Sesión', value: s.sessionId),
    KeyValueRow(
      label: 'Inicio confirmado',
      value: formatDateTime(s.startedAt.fields),
    ),
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
    const VigiaParagraph(
      'El tiempo hasta la reapertura no cuenta como medición.',
      secondary: true,
    ),
  ];
}
