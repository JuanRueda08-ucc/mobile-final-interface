import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/clock/monotonic_clock.dart';
import '../../core/design_system/vigia_icons.dart';
import '../../core/design_system/widgets/notice_host.dart';
import '../../core/design_system/widgets/vigia_blocks.dart';
import '../../core/design_system/widgets/vigia_button.dart';
import '../../core/design_system/widgets/vigia_flow_blocks.dart';
import '../../core/design_system/widgets/vigia_scaffold.dart';
import 'demo_session_controller.dart';
import 'domain/session_model.dart';
import 'domain/session_summary.dart';

/// P06 · Monitoreo y pausa (FL04, FL06, FL07; RF09–RF18; B5.2 `vP06`).
///
/// Fondo estable: sin aura ni transiciones; cada cambio de señal se pinta en
/// cuanto llega. Las alertas no exigen respuesta (UX08). Todo lo que se ve
/// es simulado y lleva el rótulo DEMO (RF32).
class MonitoringScreen extends ConsumerStatefulWidget {
  const MonitoringScreen({super.key});

  static const busyBackNotice =
      'Operación en curso: espera la confirmación para volver.';

  @override
  ConsumerState<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends ConsumerState<MonitoringScreen>
    with NoticeHost {
  DemoSessionController get _session => ref.read(demoSessionProvider.notifier);

  /// Volver: abre D05 y navega sin pausar ni cerrar (UX §4.1). Con una orden
  /// pendiente se permanece en Monitoreo.
  Future<void> _back() async {
    if (ref.read(demoSessionProvider).pending != null) {
      showNotice(MonitoringScreen.busyBackNotice);
      return;
    }
    final go = await showVigiaConfirm(
      context,
      id: 'D05',
      title: '¿Volver al inicio?',
      text: 'La sesión continuará si el motor mantiene la medición.',
      safeLabel: 'Seguir aquí',
      actionLabel: 'Volver al inicio',
      isDemo: true,
    );
    if (go && mounted) context.go(VigiaRoutes.inicio);
  }

  /// Finalizar: D02. Cancelar conserva la sesión; confirmar solicita el
  /// cierre una sola vez (UX12.CA1).
  Future<void> _finish() async {
    final confirmed = await showVigiaConfirm(
      context,
      id: 'D02',
      title: '¿Finalizar la sesión?',
      text: 'Se detendrá el monitoreo.',
      safeLabel: 'Continuar sesión',
      actionLabel: 'Finalizar',
      isDemo: true,
    );
    if (confirmed) _session.requestFinish();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(demoSessionProvider);
    final pending = s.pending;
    final paused = s.lifecycle == SessionLifecycle.paused;
    final busy = pending != null;

    final sessionAxis = switch (s.lifecycle) {
      SessionLifecycle.starting => 'Iniciando',
      SessionLifecycle.paused =>
        pending == PendingOperation.resume ? 'Reanudando' : 'Pausada',
      SessionLifecycle.stopping => 'Finalizando',
      SessionLifecycle.finalized => 'Finalizada',
      _ => pending == PendingOperation.pause ? 'Pausando' : 'Activa',
    };
    final hasId = s.sessionId != null;
    final measuring = hasId && !paused;

    final controls = switch (s.lifecycle) {
      SessionLifecycle.paused => [
        VigiaButton(
          label: 'Reanudar',
          height: 56,
          icon: VigiaIcon.play,
          onPressed: busy ? null : _session.requestResume,
        ),
        VigiaButton(
          label: 'Finalizar',
          height: 56,
          kind: VigiaButtonKind.secondary,
          onPressed: busy ? null : _finish,
        ),
      ],
      SessionLifecycle.active => [
        VigiaButton(
          label: 'Pausar',
          height: 56,
          kind: VigiaButtonKind.secondary,
          icon: VigiaIcon.pause,
          onPressed: busy ? null : _session.requestPause,
        ),
        VigiaButton(
          label: 'Finalizar',
          height: 56,
          onPressed: busy ? null : _finish,
        ),
      ],
      _ => [
        const VigiaButton(
          label: 'Pausar',
          height: 56,
          kind: VigiaButtonKind.secondary,
          onPressed: null,
        ),
        const VigiaButton(label: 'Finalizar', height: 56, onPressed: null),
      ],
    };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: VigiaScaffold(
        title: 'Monitoreo',
        isDemo: true,
        onBack: _back,
        notice: notice,
        children: [
          if (pending != null)
            StatusCard(
              key: const Key('pending-operation'),
              tone: StatusTone.pending,
              icon: VigiaIcon.clock,
              tag: 'Operación en curso',
              title: '${pending.text}…',
              text: pending == PendingOperation.start
                  ? 'Esperando la confirmación del motor simulado. Todavía no '
                        'hay sesión activa ni ID.'
                  : 'Esperando la confirmación del motor simulado. El estado '
                        'actual no cambia hasta confirmar.',
            ),
          if (hasId) _mainCard(s),
          if (s.soundFailure != null && hasId)
            StatusCard(
              key: const Key('sound-failure'),
              tone: StatusTone.alert,
              icon: VigiaIcon.close,
              tag: 'Sonido',
              title: 'Sonido no disponible',
              text:
                  '${s.soundFailure} La medición continúa mientras sea '
                  'válida. No es un nuevo episodio ni un fallo ocular.',
            ),
          AxesRow(
            session: sessionAxis,
            measurement: measuring ? s.measurement.text : '—',
            signal: paused
                ? 'Evaluación suspendida'
                : measuring
                ? s.signal.text
                : '—',
          ),
          KeyValueRow(
            label: 'Sesión',
            value: s.sessionId ?? 'Se asigna al confirmar',
          ),
          if (hasId) _MonitoredTime(state: s),
          const VigiaParagraph(
            'Usa los controles solo con el vehículo detenido. La app no '
            'verifica la velocidad.',
            secondary: true,
          ),
          if (busy)
            const VigiaParagraph(
              'Operación en curso: los demás controles están bloqueados.',
              secondary: true,
            ),
          VigiaButtonRow(buttons: controls),
        ],
      ),
    );
  }

  /// Aviso principal (UX §5.2). En Pausada no se presenta la última señal
  /// como actual (UX07.CA2).
  Widget _mainCard(DemoSessionState s) {
    const key = Key('main-signal');
    if (s.lifecycle == SessionLifecycle.paused) {
      return const StatusCard(
        key: key,
        tone: StatusTone.pause,
        icon: VigiaIcon.pause,
        tag: 'Pausada',
        title: 'Monitoreo pausado',
        text: 'Evaluación suspendida',
        titleSize: 32,
      );
    }
    return switch ((s.measurement, s.signal)) {
      (_, SignalState.prolongedEyeClosure) => const StatusCard(
        key: key,
        tone: StatusTone.close,
        icon: VigiaIcon.eyeClosed,
        tag: 'Cierre ocular · simulado',
        title: 'Cierre ocular prolongado',
        text: 'Detente en un lugar seguro',
        titleSize: 32,
      ),
      (_, SignalState.warning) => const StatusCard(
        key: key,
        tone: StatusTone.warn,
        icon: VigiaIcon.warn,
        tag: 'Advertencia · simulada',
        title: 'Señales persistentes',
        text: 'Planifica una pausa en un lugar seguro',
        titleSize: 32,
      ),
      (Measurement.usable, _) => const StatusCard(
        key: key,
        tone: StatusTone.plain,
        icon: VigiaIcon.activity,
        tag: 'Activo',
        title: 'Monitoreo activo',
        text: 'Sin señales persistentes',
        titleSize: 32,
      ),
      (Measurement.limited, _) => const StatusCard(
        key: key,
        tone: StatusTone.neutral,
        icon: VigiaIcon.clock,
        tag: 'Recuperando',
        title: 'Recuperando medición',
        text: 'Aún no puedo evaluar',
        titleSize: 32,
      ),
      (Measurement.initializing, _) => const StatusCard(
        key: key,
        tone: StatusTone.neutral,
        icon: VigiaIcon.clock,
        tag: 'Inicializando',
        title: 'Preparando la medición',
        text: 'Aún no puedo evaluar',
        titleSize: 32,
      ),
      (Measurement.unavailable, _) => StatusCard(
        key: key,
        tone: StatusTone.neutral,
        icon: VigiaIcon.eyeOff,
        tag: 'No evaluable',
        title: 'No puedo evaluar',
        text: 'Causa emitida por el motor simulado: ${s.cause ?? 'sin causa'}',
        titleSize: 32,
      ),
    };
  }
}

/// «Tiempo monitoreado»: se calcula desde el estado (anclas monotónicas) y
/// se repinta cada segundo. No es región viva: el lector de pantalla no lo
/// anuncia cada segundo (UX22.CA2).
class _MonitoredTime extends ConsumerStatefulWidget {
  const _MonitoredTime({required this.state});

  final DemoSessionState state;

  @override
  ConsumerState<_MonitoredTime> createState() => _MonitoredTimeState();
}

class _MonitoredTimeState extends ConsumerState<_MonitoredTime> {
  Timer? _timer;

  /// Solo avanza en Activa: en pausa y al cerrar el valor está congelado.
  void _sync() {
    final running = widget.state.lifecycle == SessionLifecycle.active;
    if (running && _timer == null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!running) {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_MonitoredTime old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.read(monotonicClockProvider).elapsed;
    return KeyValueRow(
      key: const Key('monitored-time'),
      label: 'Tiempo monitoreado (sin pausas)',
      value: formatClock(widget.state.monitoredAt(now)),
    );
  }
}
