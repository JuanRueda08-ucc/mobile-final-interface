import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monitoring_engine/monitoring_engine.dart';

import '../../app/router.dart';
import '../../core/design_system/vigia_icons.dart';
import '../../core/design_system/widgets/notice_host.dart';
import '../../core/design_system/widgets/vigia_blocks.dart';
import '../../core/design_system/widgets/vigia_button.dart';
import '../../core/design_system/widgets/vigia_flow_blocks.dart';
import '../../core/design_system/widgets/vigia_scaffold.dart';
import '../camera/front_camera_controller.dart';
import '../camera/front_camera_screen.dart';
import 'experimental_monitoring_controller.dart';

/// Monitoreo experimental (fase 5C, variante normal).
///
/// Recorrido real con la cámara frontal: un rostro → mediciones oculares →
/// calibración → prueba de sonido → iniciar → cierre ocular sostenido →
/// aviso y tono → finalizar. Las señales las decide el motor nativo con el
/// perfil de laboratorio `lab-eye-rules-0.1` (experimental); esta pantalla
/// no decide nada y no reutiliza el guion DEMO. Sin persistencia: el resumen
/// final solo vive en memoria.
class ExperimentalMonitoringScreen extends ConsumerStatefulWidget {
  const ExperimentalMonitoringScreen({super.key});

  static const title = 'Monitoreo experimental';

  static const experimentalText =
      'Prototipo experimental con valores de laboratorio sin validar (perfil '
      'lab-eye-rules-0.1). No es una ayuda para conducir ni detecta fatiga: '
      'solo observa cierres oculares. Las imágenes se procesan en este '
      'teléfono; no se graban, no se guardan y no se envían.';

  static const leaveBlockedNotice =
      'Finaliza la sesión experimental antes de salir.';

  /// Texto del motivo técnico por el que los ojos no son medibles.
  static String eyeIssueText(String? code) => switch (code) {
    'noFace' => 'Rostro no detectado.',
    'ambiguousFace' => 'Varios rostros: no se sabe cuál es el tuyo.',
    'invalidGeometry' => 'Los puntos de los ojos no son utilizables.',
    'eyeOutsideFrame' => 'Un ojo queda fuera de la imagen.',
    'insufficientEyeResolution' =>
      'Los ojos se ven demasiado pequeños: acerca el teléfono.',
    'excessivePerspective' => 'El rostro está demasiado girado.',
    'staleResult' => 'El último resultado llegó tarde y no se usa.',
    'invalidTimestamp' => 'Resultado con una marca de tiempo no válida.',
    'inferenceError' => 'El análisis se detuvo por un error.',
    'cameraClosed' => 'La cámara está cerrada.',
    'noResults' => 'Sin resultados del análisis.',
    'resultsDelayed' => 'Los resultados llegan con retraso.',
    'gap' => 'Hubo un hueco entre observaciones.',
    null => 'Sin observaciones todavía.',
    _ => 'Ojos no medibles ($code).',
  };

  static String rejectionText(String code) => switch (code) {
    'sessionActive' => 'Ya hay una sesión en curso.',
    'cameraNotReady' => 'La cámara no está lista.',
    'calibrationInProgress' => 'Hay una calibración en curso.',
    'calibrationNotApplicable' => 'Falta una calibración aceptada.',
    'soundNotConfirmed' => 'Falta confirmar la prueba de sonido.',
    'eyesNotEvaluable' => 'Los ojos no son medibles en este momento.',
    'alarmVolumeZero' => 'El volumen de alarma está en cero.',
    'toneNotStarted' || 'toneUnavailable' => 'Android no inició el tono.',
    _ => 'El motor rechazó la orden ($code).',
  };

  static String calibrationRejectionText(String? code) => switch (code) {
    'insufficientObservations' =>
      'No hubo suficientes observaciones válidas de los ojos.',
    'invalidEyeQuality' =>
      'Los ojos no se pudieron medir con calidad suficiente.',
    'unstableReference' =>
      'La referencia no fue estable o el cierre no se distinguió de los ojos '
          'abiertos.',
    _ => 'Calibración no aceptada.',
  };

  static String decimal(double? v) =>
      v == null ? '—' : v.toStringAsFixed(2).replaceAll('.', ',');

  static String duration(int ms) {
    final s = ms ~/ 1000;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(s ~/ 3600)}:${two(s % 3600 ~/ 60)}:${two(s % 60)}';
  }

  @override
  ConsumerState<ExperimentalMonitoringScreen> createState() =>
      _ExperimentalMonitoringScreenState();
}

class _ExperimentalMonitoringScreenState
    extends ConsumerState<ExperimentalMonitoringScreen>
    with NoticeHost {
  late final FrontCameraController _camera;
  late final ExperimentalMonitoringController _exp;
  late final AppLifecycleListener _lifecycle;
  late final ProviderSubscription<ExperimentalState> _subscription;
  bool _observedSession = false;
  bool _openingCamera = false;

  /// El resumen se muestra tras finalizar en esta visita; al volver a entrar
  /// se prepara otra sesión.
  bool _showSummary = false;

  @override
  void initState() {
    super.initState();
    _camera = ref.read(frontCameraProvider.notifier);
    _exp = ref.read(experimentalMonitoringProvider.notifier);
    _subscription = ref.listenManual(experimentalMonitoringProvider, (_, s) {
      if (!mounted || !s.available) return;
      if (s.sessionVigente) _observedSession = true;
      if (_observedSession && s.lifecycle == EngineSessionLifecycle.finalized) {
        setState(() => _showSummary = true);
      }
      _syncCamera(s);
    });
    // Sin servicio en primer plano: en segundo plano la cámara se libera y
    // la sesión queda no evaluable hasta volver.
    _lifecycle = AppLifecycleListener(
      onHide: () {
        _exp.leave();
        _camera.suspend();
      },
      onShow: _exp.refresh,
    );
    Future.microtask(() {
      _exp.refresh();
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _subscription.close();
    _exp.leave();
    _camera.leave();
    super.dispose();
  }

  Future<void> _back() async {
    final s = ref.read(experimentalMonitoringProvider);
    if (s.pending != null || _exp.unresolvedStart) {
      showNotice('Espera la respuesta del motor antes de salir.');
      return;
    }
    if (s.sessionVigente) {
      showNotice(ExperimentalMonitoringScreen.leaveBlockedNotice);
      return;
    }
    if (s.calibrating) await _exp.cancelCalibration();
    if (mounted) context.go(VigiaRoutes.inicio);
  }

  Future<void> _run(Future<bool> Function() action) async {
    await action();
    if (!mounted) return;
    final s = ref.read(experimentalMonitoringProvider);
    final code = s.rejection;
    if (code != null) {
      showNotice(ExperimentalMonitoringScreen.rejectionText(code));
    } else if (s.bridgeError) {
      showNotice('No se pudo comunicar con el motor. Reintenta.');
    }
  }

  Future<void> _pause() async {
    if (await _exp.pause() && mounted) _camera.leave();
    _reportLast();
  }

  Future<void> _resume() async {
    await _exp.resume();
    _reportLast();
  }

  Future<void> _finish() async {
    final confirmed = await showVigiaConfirm(
      context,
      id: 'D02',
      title: '¿Finalizar la sesión experimental?',
      text: 'Se detendrán el monitoreo, la cámara y los avisos.',
      safeLabel: 'Continuar sesión',
      actionLabel: 'Finalizar',
    );
    if (!confirmed) return;
    if (await _exp.stop()) {
      if (!mounted) return;
      _camera.leave();
      if (mounted) setState(() => _showSummary = true);
    }
    _reportLast();
  }

  void _reportLast() {
    if (!mounted) return;
    final code = ref.read(experimentalMonitoringProvider).rejection;
    if (code != null) {
      showNotice(ExperimentalMonitoringScreen.rejectionText(code));
    }
  }

  void _syncCamera(ExperimentalState s) {
    final paused =
        s.lifecycle == EngineSessionLifecycle.paused &&
        !(s.snapshot?.resumePending ?? false);
    if (paused || _showSummary) {
      _camera.leave();
      return;
    }
    final cam = ref.read(frontCameraProvider);
    if (!_openingCamera &&
        (cam.phase == CameraCheckPhase.closed ||
            cam.phase == CameraCheckPhase.suspended)) {
      _openingCamera = true;
      _camera.enter().whenComplete(() => _openingCamera = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cam = ref.watch(frontCameraProvider);
    final s = ref.watch(experimentalMonitoringProvider);
    final snap = s.snapshot;
    final finalized =
        _showSummary && s.lifecycle == EngineSessionLifecycle.finalized;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: VigiaScaffold(
        title: ExperimentalMonitoringScreen.title,
        onBack: _back,
        notice: notice,
        children: [
          const StatusCard(
            key: Key('experimental-banner'),
            tone: StatusTone.warn,
            icon: VigiaIcon.warn,
            tag: 'Experimental',
            title: 'Prototipo experimental',
            text: ExperimentalMonitoringScreen.experimentalText,
          ),
          if (finalized && snap != null)
            ..._summary(snap)
          else ...[
            if (s.lifecycle != EngineSessionLifecycle.paused)
              FrontCameraStage(state: cam),
            if (s.sessionVigente && snap != null)
              ..._session(s, snap)
            else
              ..._preparation(s, cam),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------- preparación

  List<Widget> _preparation(ExperimentalState s, FrontCameraState cam) {
    final snap = s.snapshot;
    final cameraOk = cam.phase == CameraCheckPhase.available;
    final eyesOk = s.eyesValid;
    final step = snap?.calibrationStep ?? CalibrationStep.idle;
    final accepted = step == CalibrationStep.accepted;
    final busy = s.pending != null;
    final canCalibrate = cameraOk && eyesOk && !s.calibrating && !busy;
    final soundOk = snap?.soundHeard ?? false;
    final canStart = accepted && soundOk && eyesOk && cameraOk && !busy;
    return [
      CheckGroup(rows: _eyeRows(s, cam)),
      const VigiaHeading('Calibración'),
      const VigiaParagraph(
        'Con el vehículo detenido: mira al frente con los ojos abiertos y, '
        'cuando se indique, ciérralos dos veces. Un pitido indica que vuelvas '
        'a abrirlos.',
        secondary: true,
      ),
      ..._calibrationStatus(s),
      if (s.calibrating)
        VigiaButton(
          label: 'Cancelar calibración',
          kind: VigiaButtonKind.secondary,
          onPressed: busy ? null : () => _run(_exp.cancelCalibration),
        )
      else
        VigiaButton(
          key: const Key('calibrate'),
          label: accepted ? 'Calibrar de nuevo' : 'Calibrar',
          kind: accepted ? VigiaButtonKind.secondary : VigiaButtonKind.primary,
          icon: VigiaIcon.target,
          onPressed: canCalibrate ? () => _run(_exp.beginCalibration) : null,
        ),
      const VigiaHeading('Prueba de sonido'),
      CheckGroup(
        rows: [
          CheckRow(
            key: const Key('row-sound'),
            label: 'Tono de aviso',
            ok: soundOk,
            value: soundOk
                ? 'Confirmado'
                : (snap?.soundTestPlayed ?? false)
                ? 'Reproducción técnica correcta'
                : snap?.soundFailure != null
                ? 'No se reprodujo'
                : 'Sin probar',
            cause: (snap?.soundTestPlayed ?? false) && !soundOk
                ? 'Esto no confirma que lo hayas oído. Confírmalo si lo '
                      'escuchaste.'
                : snap?.soundFailure != null
                ? ExperimentalMonitoringScreen.rejectionText(
                    snap!.soundFailure!,
                  )
                : null,
          ),
        ],
      ),
      VigiaButtonRow(
        buttons: [
          VigiaButton(
            label: 'Probar tono',
            kind: VigiaButtonKind.secondary,
            icon: VigiaIcon.speaker,
            onPressed: busy || s.calibrating
                ? null
                : () => _run(_exp.testSound),
          ),
          VigiaButton(
            label: 'Lo escuché',
            kind: VigiaButtonKind.secondary,
            onPressed: !busy && (snap?.soundTestPlayed ?? false) && !soundOk
                ? () => _run(_exp.confirmSoundHeard)
                : null,
          ),
        ],
      ),
      VigiaButton(
        key: const Key('start'),
        label: 'Iniciar monitoreo experimental',
        onPressed: canStart ? () => _run(_exp.start) : null,
      ),
      if (!canStart)
        VigiaParagraph(_startBlockers(s, cameraOk, eyesOk), secondary: true),
    ];
  }

  String _startBlockers(ExperimentalState s, bool cameraOk, bool eyesOk) {
    final missing = <String>[
      if (!cameraOk) 'cámara',
      if (!eyesOk) 'ojos medibles',
      if (s.snapshot?.calibrationStep != CalibrationStep.accepted)
        'calibración',
      if (!(s.snapshot?.soundHeard ?? false)) 'prueba de sonido',
    ];
    if (missing.isEmpty) return 'Esperando la respuesta del motor.';
    return 'Para iniciar falta: ${missing.join(', ')}.';
  }

  List<CheckRow> _eyeRows(ExperimentalState s, FrontCameraState cam) {
    final snap = s.snapshot;
    final eyesOk = s.eyesValid;
    final calibrated = snap?.ratioRight != null;
    return [
      CheckRow(
        label: 'Cámara',
        ok: cam.phase == CameraCheckPhase.available,
        value: cam.phase == CameraCheckPhase.available
            ? 'Disponible'
            : 'Cámara no disponible',
        cause: cam.phase == CameraCheckPhase.available
            ? null
            : 'Comprueba el permiso en «Comprobar cámara».',
      ),
      CheckRow(
        label: 'Rostro',
        ok: cam.facePhase == FacePresencePhase.oneFace,
        value: FrontCameraScreen.presenceLabel(cam.facePhase),
      ),
      CheckRow(
        key: const Key('row-eyes'),
        label: 'Ojos medibles',
        ok: eyesOk,
        value: !s.available
            ? 'Estado del motor no disponible'
            : eyesOk
            ? 'Sí'
            : 'No',
        cause: s.available && !eyesOk
            ? ExperimentalMonitoringScreen.eyeIssueText(
                s.eyesFresh || !(snap?.eyesValid ?? false)
                    ? snap?.eyeIssue
                    : 'staleResult',
              )
            : null,
      ),
      CheckRow(
        key: const Key('row-ear'),
        label: 'Apertura ocular (EAR)',
        ok: eyesOk,
        value: eyesOk
            ? 'Der. ${ExperimentalMonitoringScreen.decimal(snap?.earRight)} · '
                  'Izq. ${ExperimentalMonitoringScreen.decimal(snap?.earLeft)}'
            : 'Sin medición',
        cause: eyesOk && calibrated
            ? 'Respecto a tu referencia: der. '
                  '${ExperimentalMonitoringScreen.decimal(snap?.ratioRight)} · '
                  'izq. ${ExperimentalMonitoringScreen.decimal(snap?.ratioLeft)}. '
                  'Medida geométrica, no un porcentaje de cierre.'
            : 'Medida geométrica de los puntos del ojo, calculada en el '
                  'teléfono.',
      ),
    ];
  }

  List<Widget> _calibrationStatus(ExperimentalState s) {
    final snap = s.snapshot;
    if (snap == null) return const [];
    final secs = (snap.stepElapsedMs ?? 0) ~/ 1000;
    final total = (snap.stepDurationMs ?? 0) ~/ 1000;
    final probe = '${snap.calibrationProbe} de 2';
    return switch (snap.calibrationStep) {
      CalibrationStep.idle => const [],
      CalibrationStep.openReference => [
        StatusCard(
          key: const Key('calibration-step'),
          tone: StatusTone.pending,
          icon: VigiaIcon.target,
          tag: 'Calibración · referencia',
          title: 'Mira al frente con los ojos abiertos',
          text:
              '$secs de $total s · ${snap.stepValidSamples ?? 0} '
              'observaciones válidas.',
        ),
      ],
      CalibrationStep.closeLeadIn => [
        StatusCard(
          key: const Key('calibration-step'),
          tone: StatusTone.pending,
          icon: VigiaIcon.eyeClosed,
          tag: 'Calibración · cierre $probe',
          title: 'Cierra los ojos',
          text: 'Mantenlos cerrados hasta oír el pitido.',
        ),
      ],
      CalibrationStep.closedProbe => [
        StatusCard(
          key: const Key('calibration-step'),
          tone: StatusTone.pending,
          icon: VigiaIcon.eyeClosed,
          tag: 'Calibración · cierre $probe',
          title: 'Mantén los ojos cerrados',
          text: 'Midiendo el cierre.',
        ),
      ],
      CalibrationStep.reopen => [
        StatusCard(
          key: const Key('calibration-step'),
          tone: StatusTone.pending,
          icon: VigiaIcon.target,
          tag: 'Calibración · reapertura $probe',
          title: 'Abre los ojos y mira al frente',
          text: 'Comprobando que los ojos vuelven a estar abiertos.',
        ),
      ],
      CalibrationStep.accepted => [
        StatusCard(
          key: const Key('calibration-accepted'),
          tone: StatusTone.strong,
          icon: VigiaIcon.check,
          tag: 'Calibración',
          title: 'Referencia aceptada',
          text:
              'Ojos abiertos: der. '
              '${ExperimentalMonitoringScreen.decimal(snap.openEarRight)} · izq. '
              '${ExperimentalMonitoringScreen.decimal(snap.openEarLeft)} '
              '(${snap.calibrationSamples ?? 0} observaciones). Vale para '
              'esta ejecución de la app; no se guarda.',
        ),
      ],
      CalibrationStep.rejected => [
        StatusCard(
          key: const Key('calibration-rejected'),
          tone: StatusTone.alert,
          icon: VigiaIcon.close,
          tag: 'Calibración',
          title: 'Calibración no aceptada',
          text: ExperimentalMonitoringScreen.calibrationRejectionText(
            snap.calibrationRejection,
          ),
        ),
      ],
      CalibrationStep.canceled => [
        const StatusCard(
          tone: StatusTone.neutral,
          icon: VigiaIcon.info,
          tag: 'Calibración',
          title: 'Calibración cancelada',
        ),
      ],
    };
  }

  // ------------------------------------------------------------ sesión

  List<Widget> _session(ExperimentalState s, MonitoringSnapshot snap) {
    final paused = s.lifecycle == EngineSessionLifecycle.paused;
    final busy = s.pending != null;
    final signal = s.signal;
    final card = !s.available
        ? const StatusCard(
            key: Key('signal'),
            tone: StatusTone.neutral,
            icon: VigiaIcon.eyeOff,
            tag: 'Señal',
            title: 'Estado del motor no disponible',
            text: 'No llegan noticias del motor: no se muestra ninguna señal.',
          )
        : paused
        ? StatusCard(
            key: const Key('signal'),
            tone: StatusTone.pause,
            icon: VigiaIcon.pause,
            tag: 'Sesión',
            title: snap.resumePending ? 'Reanudando…' : 'Monitoreo pausado',
            text: snap.resumePending
                ? 'La pausa sigue abierta hasta reunir observaciones válidas '
                      'de los ojos.'
                : 'Evaluación suspendida. La cámara está cerrada.',
          )
        : switch (signal) {
            EngineSignal.prolongedEyeClosure => const StatusCard(
              key: Key('signal'),
              tone: StatusTone.close,
              icon: VigiaIcon.eyeClosed,
              tag: 'Aviso',
              title: 'Cierre ocular prolongado',
              titleSize: 32,
              text:
                  'Los ojos llevan cerrados más de lo configurado. Cuando '
                  'puedas, detente y descansa.',
            ),
            EngineSignal.noPersistentSignals => const StatusCard(
              key: Key('signal'),
              tone: StatusTone.plain,
              icon: VigiaIcon.activity,
              tag: 'Señal',
              title: 'Sin señales persistentes',
              text:
                  'Evaluando cierres oculares prolongados. No es una medida de '
                  'fatiga.',
            ),
            EngineSignal.notEvaluable => StatusCard(
              key: const Key('signal'),
              tone: StatusTone.neutral,
              icon: VigiaIcon.eyeOff,
              tag: 'Señal',
              title: 'No evaluable',
              text: ExperimentalMonitoringScreen.eyeIssueText(
                snap.measurementCause ?? snap.eyeIssue,
              ),
            ),
          };
    return [
      Semantics(liveRegion: true, child: card),
      AxesRow(
        session: paused
            ? (snap.resumePending ? 'Reanudando' : 'En pausa')
            : 'Activa',
        measurement: switch (s.measurement) {
          EngineMeasurement.initializing => 'Inicializando',
          EngineMeasurement.usable => 'Utilizable',
          EngineMeasurement.limited => 'Limitada',
          EngineMeasurement.unavailable => 'No disponible',
        },
        signal: switch (signal) {
          EngineSignal.notEvaluable => 'No evaluable',
          EngineSignal.noPersistentSignals => 'Sin señales',
          EngineSignal.prolongedEyeClosure => 'Cierre prolongado',
        },
      ),
      KeyValueRow(
        label: 'Tiempo activo',
        value: ExperimentalMonitoringScreen.duration(snap.activeMs),
      ),
      KeyValueRow(
        label: 'Tiempo evaluable',
        value: ExperimentalMonitoringScreen.duration(snap.evaluableMs),
      ),
      KeyValueRow(
        label: 'Cierres prolongados',
        value: '${snap.closureActivations}',
      ),
      KeyValueRow(
        label: 'Tonos de aviso',
        value: '${snap.tonesPlayed} iniciados · ${snap.tonesFailed} fallidos',
      ),
      if (!paused) CheckGroup(rows: _eyeRows(s, ref.read(frontCameraProvider))),
      VigiaButtonRow(
        buttons: [
          paused
              ? VigiaButton(
                  label: 'Reanudar',
                  kind: VigiaButtonKind.secondary,
                  icon: VigiaIcon.play,
                  onPressed: busy || snap.resumePending ? null : _resume,
                )
              : VigiaButton(
                  label: 'Pausar',
                  kind: VigiaButtonKind.secondary,
                  icon: VigiaIcon.pause,
                  onPressed: busy ? null : _pause,
                ),
          VigiaButton(
            key: const Key('finish'),
            label: 'Finalizar',
            onPressed: busy ? null : _finish,
          ),
        ],
      ),
    ];
  }

  // ----------------------------------------------------------- resumen

  List<Widget> _summary(MonitoringSnapshot snap) => [
    const StatusCard(
      key: Key('summary'),
      tone: StatusTone.plain,
      icon: VigiaIcon.check,
      tag: 'Sesión experimental',
      title: 'Sesión finalizada',
      text:
          'Cámara, análisis y avisos detenidos. Este resumen no se guarda: '
          'desaparece al cerrar la app.',
    ),
    KeyValueRow(
      label: 'Tiempo activo',
      value: ExperimentalMonitoringScreen.duration(snap.activeMs),
    ),
    KeyValueRow(
      label: 'Tiempo evaluable',
      value: ExperimentalMonitoringScreen.duration(snap.evaluableMs),
    ),
    KeyValueRow(
      label: 'Tiempo en pausa',
      value: ExperimentalMonitoringScreen.duration(snap.pausedMs),
    ),
    KeyValueRow(
      label: 'Cierres prolongados',
      value: '${snap.closureActivations}',
    ),
    KeyValueRow(
      label: 'Tonos de aviso',
      value: '${snap.tonesPlayed} iniciados · ${snap.tonesFailed} fallidos',
    ),
    VigiaButton(
      label: 'Volver a Inicio',
      onPressed: () => context.go(VigiaRoutes.inicio),
    ),
    VigiaButton(
      label: 'Preparar otra sesión',
      kind: VigiaButtonKind.secondary,
      onPressed: () {
        setState(() => _showSummary = false);
        _observedSession = false;
        _camera.enter();
      },
    ),
  ];
}
