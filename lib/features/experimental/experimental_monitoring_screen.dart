import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:monitoring_engine/monitoring_engine.dart';

import '../../app/router.dart';
import '../../core/audio/voice_guide.dart';
import '../../core/design_system/vigia_icons.dart';
import '../../core/design_system/widgets/notice_host.dart';
import '../../core/design_system/widgets/steady_height.dart';
import '../../core/design_system/widgets/vigia_blocks.dart';
import '../../core/design_system/widgets/vigia_button.dart';
import '../../core/design_system/widgets/vigia_flow_blocks.dart';
import '../../core/design_system/widgets/vigia_scaffold.dart';
import '../../core/design_system/widgets/vigia_text.dart';
import '../camera/front_camera_controller.dart';
import '../camera/front_camera_screen.dart';
import '../../data/experimental_history/experimental_history_providers.dart';
import '../experimental_history/experimental_history_blocks.dart';
import '../settings/preferences_controller.dart';
import 'experimental_monitoring_controller.dart';

/// Monitoreo experimental (fase 5C, variante normal).
///
/// Recorrido real con la cámara frontal: un rostro → mediciones oculares →
/// calibración → prueba de sonido → iniciar → cierre ocular sostenido →
/// aviso y tono → finalizar. Las señales las decide el motor nativo con el
/// perfil de laboratorio `lab-eye-rules-0.1` (experimental); esta pantalla
/// no decide nada y no reutiliza el guion DEMO. Fase 5D: el motor registra la
/// sesión en su journal y el resumen final se lee del historial guardado.
class ExperimentalMonitoringScreen extends ConsumerStatefulWidget {
  const ExperimentalMonitoringScreen({super.key});

  static const title = 'Monitoreo';

  static const leaveBlockedNotice = 'Finaliza la sesión antes de salir.';

  /// Texto del motivo técnico por el que los ojos no son medibles.
  /// Voz guía de la calibración (prueba física, 2026-11-15). Se dice al
  /// entrar en cada paso; null: el paso no se narra.
  static String? calibrationVoice(CalibrationStep step) => switch (step) {
    CalibrationStep.openReference => 'Mira al frente con los ojos abiertos.',
    CalibrationStep.closeLeadIn =>
      'Cierra los ojos. Mantenlos cerrados hasta oír el pitido.',
    CalibrationStep.reopen => 'Abre los ojos y mira al frente.',
    CalibrationStep.accepted => 'Calibración aceptada.',
    CalibrationStep.rejected =>
      'Calibración no aceptada. Puedes intentarlo de nuevo.',
    _ => null,
  };

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
    'accountRequired' => 'Inicia sesión con un correo verificado.',
    'sessionActive' => 'Ya hay una sesión en curso.',
    'settingsChangePending' => 'Espera a que termine el guardado de Ajustes.',
    'cameraNotReady' => 'La cámara no está lista.',
    'calibrationInProgress' => 'Hay una calibración en curso.',
    'calibrationNotApplicable' => 'Falta una calibración aceptada.',
    'soundNotConfirmed' => 'Falta confirmar la prueba de sonido.',
    'eyesNotEvaluable' => 'Los ojos no son medibles en este momento.',
    'alarmVolumeZero' => 'El volumen de alarma está en cero.',
    'toneNotStarted' || 'toneUnavailable' => 'Android no inició el tono.',
    'unknownSoundPattern' => 'El patrón de sonido no está incluido.',
    'soundTestNotPlayed' => 'Repite la prueba de sonido.',
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

enum _PreparationStep { framing, calibration, sound }

class _ExperimentalMonitoringScreenState
    extends ConsumerState<ExperimentalMonitoringScreen>
    with NoticeHost, JournalSyncOnMount {
  /// Fase 5D: tras finalizar se espera el cierre guardado de esta sesión.
  @override
  String? get awaitedSessionId => _showSummary
      ? ref.read(experimentalMonitoringProvider).snapshot?.sessionId
      : null;

  late final FrontCameraController _camera;
  late final ExperimentalMonitoringController _exp;
  late final VoiceGuide _voice;
  late final AppLifecycleListener _lifecycle;
  late final ProviderSubscription<ExperimentalState> _subscription;
  bool _observedSession = false;
  bool _openingCamera = false;
  bool _returnToFraming = false;

  /// El resumen se muestra tras finalizar en esta visita; al volver a entrar
  /// se prepara otra sesión.
  bool _showSummary = false;

  /// Prueba física (2026-11-15): en un teléfono lento la señal alternaba
  /// entre «Sin señales persistentes» y «No evaluable» varias veces por
  /// segundo y la pantalla titilaba. Durante la sesión, la señal y «Ojos
  /// medibles» cambian como mucho una vez por segundo: un cambio se muestra
  /// al instante y los siguientes esperan a que pase el segundo (se muestra
  /// entonces el valor vigente). El aviso de cierre prolongado entra y sale
  /// siempre al instante. Es solo presentación: el motor y el registro no
  /// cambian.
  late final _signalShown = _Paced<EngineSignal>(
    _repaint,
    immediate: (v) => v == EngineSignal.prolongedEyeClosure,
  );
  late final _eyesShown = _Paced<bool>(_repaint);

  void _repaint() {
    if (mounted) setState(() {});
  }

  /// Último paso de calibración observado y su sondeo, para narrar solo
  /// los cambios ocurridos con la pantalla abierta.
  (CalibrationStep, int?)? _lastCalibration;
  String? _voiceIssue;

  void _narrate(ExperimentalState s) {
    final snap = s.snapshot;
    if (snap == null) return;
    final now = (snap.calibrationStep, snap.calibrationProbe);
    final before = _lastCalibration;
    _lastCalibration = now;
    if (before == null || before == now) return;
    // «Aceptada» o «rechazada» solo tras una calibración vista en curso.
    final finished =
        now.$1 == CalibrationStep.accepted ||
        now.$1 == CalibrationStep.rejected;
    if (finished && !_inProgress(before.$1)) return;
    final text = ExperimentalMonitoringScreen.calibrationVoice(now.$1);
    if (text == null || !ref.read(calibrationVoiceEnabledProvider)) return;
    _voice.speak(text).then((r) {
      final issue = r.spoken ? null : r.cause;
      if (mounted && issue != _voiceIssue) {
        setState(() => _voiceIssue = issue);
      }
    });
  }

  static bool _inProgress(CalibrationStep step) => switch (step) {
    CalibrationStep.openReference ||
    CalibrationStep.closeLeadIn ||
    CalibrationStep.closedProbe ||
    CalibrationStep.reopen => true,
    _ => false,
  };

  void _feedHeld(ExperimentalState s) {
    if (s.sessionVigente) return;
    _signalShown.reset();
    _eyesShown.reset();
  }

  @override
  void initState() {
    super.initState();
    _camera = ref.read(frontCameraProvider.notifier);
    _exp = ref.read(experimentalMonitoringProvider.notifier);
    _voice = ref.read(voiceGuideProvider);
    _subscription = ref.listenManual(experimentalMonitoringProvider, (_, s) {
      if (!mounted) return;
      _feedHeld(s);
      _narrate(s);
      if (!s.available) return;
      if (s.sessionVigente) _observedSession = true;
      if (_observedSession &&
          s.lifecycle == EngineSessionLifecycle.finalized &&
          !_showSummary) {
        setState(() => _showSummary = true);
        requestJournalSync();
      }
      _syncCamera(s);
    });
    // Sin servicio en primer plano: en segundo plano la cámara se libera y
    // la sesión queda no evaluable hasta volver.
    _lifecycle = AppLifecycleListener(
      onHide: () {
        _voice.stop();
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
    _signalShown.reset();
    _eyesShown.reset();
    _voice.stop();
    _lifecycle.dispose();
    _subscription.close();
    _exp.leave();
    _camera.leave();
    super.dispose();
  }

  Future<void> _back() async {
    final s = ref.read(experimentalMonitoringProvider);
    // El resumen solo se abre tras confirmar una sesión y su finalización.
    // Una respuesta de inicio perdida sigue ocupando el canal, pero ya no
    // deja incierto el recorrido que el motor confirmó y cerró.
    if (s.pending != null || (_exp.unresolvedStart && !_showSummary)) {
      showNotice('Espera la respuesta del motor antes de salir.');
      return;
    }
    if (s.sessionVigente) {
      showNotice(ExperimentalMonitoringScreen.leaveBlockedNotice);
      return;
    }
    if (!_showSummary && _preparationStep(s) != _PreparationStep.framing) {
      if (s.calibrating && !await _exp.cancelCalibration()) {
        _reportLast();
        return;
      }
      if (mounted) setState(() => _returnToFraming = true);
      return;
    }
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
      title: '¿Finalizar la sesión?',
      text: 'Se detendrán el monitoreo, la cámara y los avisos.',
      safeLabel: 'Continuar sesión',
      actionLabel: 'Finalizar',
    );
    if (!confirmed) return;
    if (await _exp.stop()) {
      if (!mounted) return;
      _camera.leave();
      if (mounted) setState(() => _showSummary = true);
      requestJournalSync();
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
    // La validez de la prueba de sonido depende del patrón guardado.
    ref.watch(preferencesProvider.select((p) => p.value.soundPatternId));
    final snap = s.snapshot;
    final finalized =
        _showSummary && s.lifecycle == EngineSessionLifecycle.finalized;
    final preparing = !finalized && !s.sessionVigente;
    final step = _preparationStep(s);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: VigiaScaffold(
        title: ExperimentalMonitoringScreen.title,
        onBack: _back,
        notice: notice,
        contentKey: preparing ? ValueKey(step) : null,
        pinnedContent: preparing && step != _PreparationStep.sound
            ? (context, constraints) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FrontCameraStage(
                  key: const Key('preparation-preview'),
                  state: cam,
                  compact: true,
                  maxHeight: isLargeText(context)
                      ? (constraints.maxHeight * 0.32).clamp(0.0, 205.0)
                      : (constraints.maxHeight * 0.42).clamp(0.0, 280.0),
                ),
              )
            : null,
        footer: preparing
            ? _preparationAction(s, cam, step)
            : s.sessionVigente && snap != null
            ? _sessionControls(s, snap)
            : null,
        children: [
          if (finalized && snap != null) ...[
            ..._summary(snap),
          ] else if (preparing)
            ..._preparation(s, cam, step)
          else if (snap != null)
            ..._session(s, snap, cam),
        ],
      ),
    );
  }

  // ------------------------------------------------------- preparación

  _PreparationStep _preparationStep(ExperimentalState s) {
    if (s.calibrating || s.pending == 'calibrate') {
      return _PreparationStep.calibration;
    }
    if (_returnToFraming) return _PreparationStep.framing;
    return switch (s.snapshot?.calibrationStep) {
      CalibrationStep.accepted => _PreparationStep.sound,
      CalibrationStep.rejected ||
      CalibrationStep.canceled => _PreparationStep.calibration,
      _ => _PreparationStep.framing,
    };
  }

  void _beginCalibration() {
    setState(() => _returnToFraming = false);
    _run(_exp.beginCalibration);
  }

  Widget _preparationAction(
    ExperimentalState s,
    FrontCameraState cam,
    _PreparationStep step,
  ) {
    final snap = s.snapshot;
    final cameraOk = cam.phase == CameraCheckPhase.available;
    final busy = s.pending != null;
    final canCalibrate = cameraOk && s.eyesValid && !busy;
    if (step == _PreparationStep.sound) {
      return VigiaButton(
        key: const Key('start'),
        label: 'Iniciar monitoreo',
        onPressed: canCalibrate && _exp.soundConfirmedFor(snap)
            ? () => _run(_exp.start)
            : null,
      );
    }
    if (s.calibrating || s.pending == 'calibrate') {
      return VigiaButton(
        label: 'Cancelar calibración',
        kind: VigiaButtonKind.secondary,
        onPressed: busy ? null : () => _run(_exp.cancelCalibration),
      );
    }
    return VigiaButton(
      key: const Key('calibrate'),
      label: step == _PreparationStep.calibration
          ? 'Reintentar calibración'
          : snap?.calibrationStep == CalibrationStep.accepted
          ? 'Calibrar de nuevo'
          : 'Calibrar',
      icon: VigiaIcon.target,
      onPressed: canCalibrate ? _beginCalibration : null,
    );
  }

  List<Widget> _preparation(
    ExperimentalState s,
    FrontCameraState cam,
    _PreparationStep step,
  ) {
    return switch (step) {
      _PreparationStep.framing => [
        const VigiaSectionTitle('1 de 3 · Encuadre'),
        CheckGroup(
          rows: _eyeRows(
            s,
            cam,
            compact: true,
            eyesFirst: isLargeText(context),
          ),
        ),
        ..._cameraRecovery(cam),
        if (s.snapshot?.calibrationStep == CalibrationStep.accepted)
          VigiaButton(
            label: 'Continuar a sonido',
            kind: VigiaButtonKind.secondary,
            onPressed: () => setState(() => _returnToFraming = false),
          ),
        const VigiaParagraph(
          'Con el vehículo detenido, fija el teléfono en un soporte y mira al frente antes de calibrar.',
          secondary: true,
        ),
      ],
      _PreparationStep.calibration => [
        const VigiaSectionTitle('2 de 3 · Calibración'),
        if (s.pending == 'calibrate' && !s.calibrating)
          const VigiaParagraph('Esperando confirmación del motor…')
        else
          ..._calibrationStatus(s),
        _voiceToggle(),
        if (!s.calibrating && !s.eyesValid)
          CheckGroup(
            rows: [_eyeRows(s, cam, compact: true, eyesFirst: true).first],
          ),
        ..._cameraRecovery(cam),
      ],
      _PreparationStep.sound => _soundPreparation(s, cam),
    };
  }

  /// Interruptor de la voz guía y, si Android no pudo hablar, la causa.
  Widget _voiceToggle() {
    final on = ref.watch(calibrationVoiceEnabledProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        VigiaButton(
          key: const Key('calibration-voice'),
          label: on ? 'Voz guía activada' : 'Voz guía desactivada',
          kind: VigiaButtonKind.secondary,
          icon: VigiaIcon.speaker,
          onPressed: () {
            if (on) _voice.stop();
            ref.read(calibrationVoiceEnabledProvider.notifier).toggle();
          },
        ),
        if (on && _voiceIssue != null)
          VigiaParagraph(
            'Sin voz: $_voiceIssue Sigue el texto y el tono.',
            secondary: true,
          ),
      ],
    );
  }

  List<Widget> _cameraRecovery(FrontCameraState cam) => switch (cam.phase) {
    CameraCheckPhase.explain || CameraCheckPhase.denied => [
      const VigiaParagraph(FrontCameraScreen.purpose),
      const VigiaParagraph(FrontCameraScreen.scope, secondary: true),
      VigiaButton(
        label: 'Permitir cámara',
        kind: VigiaButtonKind.secondary,
        onPressed: _camera.requestPermission,
      ),
    ],
    CameraCheckPhase.requiresSettings => [
      const VigiaParagraph(
        'Concede el permiso de cámara en los ajustes del teléfono.',
      ),
      VigiaButton(
        label: 'Abrir ajustes',
        kind: VigiaButtonKind.secondary,
        onPressed: () async {
          if (!await _camera.openSettings() && mounted) {
            showNotice(FrontCameraScreen.settingsFailedNotice);
          }
        },
      ),
    ],
    CameraCheckPhase.failed ||
    CameraCheckPhase.inUse ||
    CameraCheckPhase.disabled ||
    CameraCheckPhase.noFrontCamera => [
      VigiaButton(
        label: 'Reintentar cámara',
        kind: VigiaButtonKind.secondary,
        onPressed: _camera.retry,
      ),
    ],
    _ => const [],
  };

  List<Widget> _soundPreparation(ExperimentalState s, FrontCameraState cam) {
    final snap = s.snapshot;
    final busy = s.pending != null;
    // Fase 5E: solo cuenta la prueba del patrón guardado en Ajustes.
    final soundPlayed = _exp.soundTestPlayedFor(snap);
    final soundOk = _exp.soundConfirmedFor(snap);
    final cameraOk = cam.phase == CameraCheckPhase.available;
    return [
      const VigiaSectionTitle('3 de 3 · Sonido e inicio'),
      ..._calibrationStatus(s),
      const VigiaHeading('Prueba de sonido'),
      CheckGroup(
        rows: [
          CheckRow(
            key: const Key('row-sound'),
            label: 'Tono de aviso',
            ok: soundOk,
            value: soundOk
                ? 'Confirmado'
                : soundPlayed
                ? 'Reproducción técnica correcta'
                : snap?.soundFailure != null
                ? 'No se reprodujo'
                : 'Sin probar',
            cause: soundPlayed && !soundOk
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
            onPressed: !busy && soundPlayed && !soundOk
                ? () => _run(_exp.confirmSoundHeard)
                : null,
          ),
        ],
      ),
      if (!cameraOk || !s.eyesValid || !soundOk || busy)
        VigiaParagraph(
          _startBlockers(s, cameraOk, s.eyesValid),
          secondary: true,
        ),
      if (!cameraOk || !s.eyesValid)
        VigiaButton(
          label: 'Volver al encuadre',
          kind: VigiaButtonKind.secondary,
          onPressed: busy ? null : _back,
        ),
    ];
  }

  String _startBlockers(ExperimentalState s, bool cameraOk, bool eyesOk) {
    final missing = <String>[
      if (!cameraOk) 'cámara',
      if (!eyesOk) 'ojos medibles',
      if (s.snapshot?.calibrationStep != CalibrationStep.accepted)
        'calibración',
      if (!_exp.soundConfirmedFor(s.snapshot)) 'prueba de sonido',
    ];
    if (missing.isEmpty) return 'Esperando la respuesta del motor.';
    return 'Para iniciar falta: ${missing.join(', ')}.';
  }

  List<CheckRow> _eyeRows(
    ExperimentalState s,
    FrontCameraState cam, {
    bool compact = false,
    bool eyesFirst = false,
    bool? eyesOk,
  }) {
    final snap = s.snapshot;
    eyesOk ??= s.eyesValid;
    final calibrated = snap?.ratioRight != null;
    final rows = [
      CheckRow(
        compact: compact,
        label: 'Cámara',
        ok: cam.phase == CameraCheckPhase.available,
        value: cam.phase == CameraCheckPhase.available
            ? 'Disponible'
            : 'Cámara no disponible',
        cause: !compact && cam.phase != CameraCheckPhase.available
            ? 'Comprueba el permiso en «Comprobar cámara».'
            : null,
      ),
      CheckRow(
        compact: compact,
        label: 'Rostro',
        ok: cam.facePhase == FacePresencePhase.oneFace,
        value: FrontCameraScreen.presenceLabel(cam.facePhase),
      ),
      CheckRow(
        compact: compact,
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
        compact: compact,
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
            : compact
            ? null
            : 'Medida geométrica de los puntos del ojo, calculada en el '
                  'teléfono.',
      ),
    ];
    return eyesFirst ? [rows[2], rows[0], rows[1], rows[3]] : rows;
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
          titleSize: isLargeText(context) ? 22 : 28,
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
          titleSize: isLargeText(context) ? 22 : 28,
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
          titleSize: isLargeText(context) ? 22 : 28,
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
          titleSize: isLargeText(context) ? 22 : 28,
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

  StatusCard _sessionStatus(
    ExperimentalState s,
    MonitoringSnapshot snap,
    EngineSignal shownSignal,
  ) {
    final paused = s.lifecycle == EngineSessionLifecycle.paused;
    const key = Key('signal');
    if (!s.available) {
      return const StatusCard(
        key: key,
        tone: StatusTone.neutral,
        icon: VigiaIcon.eyeOff,
        tag: 'Sesión',
        title: 'Estado del motor no disponible',
        text: 'Esperando datos actuales del motor.',
      );
    }
    if (paused) {
      return StatusCard(
        key: key,
        tone: StatusTone.pause,
        icon: VigiaIcon.pause,
        tag: 'Sesión',
        title: snap.resumePending ? 'Reanudando…' : 'Monitoreo pausado',
        text: snap.resumePending
            ? 'Centra tu rostro. La medición sigue en pausa.'
            : 'Evaluación suspendida. La cámara está cerrada.',
      );
    }
    if (s.measurement == EngineMeasurement.initializing) {
      return const StatusCard(
        key: key,
        tone: StatusTone.pending,
        icon: VigiaIcon.clock,
        tag: 'Sesión',
        title: 'Inicializando medición',
        text: 'Esperando medición ocular.',
      );
    }
    return switch (shownSignal) {
      EngineSignal.prolongedEyeClosure => StatusCard(
        key: key,
        tone: StatusTone.close,
        icon: VigiaIcon.eyeClosed,
        tag: 'Aviso',
        title: 'Cierre ocular prolongado',
        titleSize: isLargeText(context) ? 20 : 32,
        text: 'Detente en un lugar seguro.',
      ),
      EngineSignal.noPersistentSignals => const StatusCard(
        key: key,
        tone: StatusTone.plain,
        icon: VigiaIcon.activity,
        tag: 'Sesión activa',
        title: 'Sin señales persistentes',
        text: 'Medición ocular en curso.',
      ),
      EngineSignal.notEvaluable => StatusCard(
        key: key,
        tone: StatusTone.neutral,
        icon: VigiaIcon.eyeOff,
        tag: 'Señal',
        title: 'No evaluable',
        text: ExperimentalMonitoringScreen.eyeIssueText(
          snap.measurementCause ?? snap.eyeIssue,
        ),
      ),
    };
  }

  List<Widget> _session(
    ExperimentalState s,
    MonitoringSnapshot snap,
    FrontCameraState cam,
  ) {
    final paused = s.lifecycle == EngineSessionLifecycle.paused;
    final showPreview = !paused || snap.resumePending;
    final operation = switch (s.pending) {
      'pause' => 'Pausando…',
      'resume' => 'Solicitando reanudación…',
      'stop' => 'Finalizando…',
      _ => null,
    };
    final reduce = MediaQuery.disableAnimationsOf(context);
    // La señal caduca con el tiempo sin notificar: se lee en cada dibujo.
    final shownSignal = s.sessionVigente
        ? _signalShown.resolve(s.signal)
        : s.signal;
    final shownEyes = s.sessionVigente
        ? _eyesShown.resolve(s.eyesValid)
        : s.eyesValid;
    final status = _sessionStatus(s, snap, shownSignal);
    return [
      // Alto estable: el estado no encoge al cambiar de frase, así la vista
      // previa no salta. El cambio de tarjeta se funde.
      SteadyHeight(
        resetKey: paused,
        child: AnimatedSwitcher(
          // El aviso entra al instante; el resto de cambios se funde.
          duration: reduce || shownSignal == EngineSignal.prolongedEyeClosure
              ? Duration.zero
              : const Duration(milliseconds: 220),
          // La tarjeta ocupa todo el alto reservado por SteadyHeight.
          layoutBuilder: (current, previous) => Stack(
            fit: StackFit.passthrough,
            alignment: Alignment.topCenter,
            children: [...previous, ?current],
          ),
          child: KeyedSubtree(
            key: ValueKey('${status.tone}|${status.title}'),
            child: status,
          ),
        ),
      ),
      if (operation != null)
        Semantics(liveRegion: true, child: VigiaParagraph(operation)),
      if (showPreview) ...[
        FrontCameraStage(state: cam, compact: true, maxHeight: 240),
        SteadyHeight(
          child: CheckGroup(
            rows: _eyeRows(
              s,
              cam,
              compact: true,
              eyesFirst: true,
              eyesOk: shownEyes,
            ),
          ),
        ),
      ],
      AxesRow(
        session: !s.available
            ? 'Sin confirmar'
            : paused
            ? (snap.resumePending ? 'Reanudando' : 'En pausa')
            : 'Activa',
        measurement: switch (s.measurement) {
          EngineMeasurement.initializing => 'Inicializando',
          EngineMeasurement.usable => 'Utilizable',
          EngineMeasurement.limited => 'Limitada',
          EngineMeasurement.unavailable => 'No disponible',
        },
        signal: !s.available || paused
            ? 'Sin datos'
            : switch (shownSignal) {
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
      const VigiaParagraph(
        'Usa los controles con el vehículo detenido.',
        secondary: true,
      ),
    ];
  }

  Widget _sessionControls(ExperimentalState s, MonitoringSnapshot snap) {
    final paused = s.lifecycle == EngineSessionLifecycle.paused;
    final busy = s.pending != null;
    return VigiaButtonRow(
      key: const Key('session-controls'),
      buttons: [
        VigiaButton(
          key: const Key('pause-resume'),
          label: paused ? 'Reanudar' : 'Pausar',
          kind: VigiaButtonKind.secondary,
          icon: paused ? VigiaIcon.play : VigiaIcon.pause,
          height: 56,
          onPressed: busy || (paused && snap.resumePending)
              ? null
              : (paused ? _resume : _pause),
        ),
        VigiaButton(
          key: const Key('finish'),
          label: 'Finalizar',
          onPressed: busy ? null : _finish,
        ),
      ],
    );
  }

  // ----------------------------------------------------------- resumen

  /// Fase 5D: el resumen se lee del historial guardado (la proyección del
  /// journal nativo), igual que en Inicio, Historial y detalle; no del estado
  /// en memoria del motor.
  List<Widget> _summary(MonitoringSnapshot snap) {
    final id = snap.sessionId;
    final available =
        ref.watch(experimentalHistoryRepositoryProvider) != null && id != null;
    return [
      StatusCard(
        key: const Key('summary'),
        tone: StatusTone.plain,
        icon: VigiaIcon.check,
        tag: 'Sesión finalizada',
        title: 'Monitoreo detenido',
        text: snap.recordStatus == 'incomplete'
            ? 'Cámara, análisis y avisos detenidos. El motor no pudo guardar '
                  'todos los registros de esta sesión.'
            : 'Cámara, análisis y avisos detenidos. El resumen se lee del '
                  'registro guardado en este teléfono.',
      ),
      ...experimentalSummaryBlocks(
        available
            ? ref.watch(experimentalSessionProvider(id))
            : const AsyncData(null),
        ref.watch(journalSyncProvider),
        historyAvailable: available,
      ),
      if (available)
        VigiaButton(
          label: 'Ver detalle',
          kind: VigiaButtonKind.secondary,
          onPressed: () => context.go(VigiaRoutes.detalle(id)),
        ),
      VigiaButton(
        label: 'Volver a Inicio',
        onPressed: () => context.go(VigiaRoutes.inicio),
      ),
      VigiaButton(
        label: 'Preparar otra sesión',
        kind: VigiaButtonKind.secondary,
        onPressed: () {
          setState(() {
            _showSummary = false;
            _returnToFraming = true;
          });
          _observedSession = false;
          _camera.enter();
        },
      ),
    ];
  }
}

/// Valor mostrado que cambia como mucho una vez cada [interval].
///
/// [resolve] se llama al dibujar con el valor vigente. El primer valor y los
/// que cumplen [immediate] (o salen de uno inmediato) se muestran enseguida.
/// Tras cada cambio se espera [interval] y se pide redibujar ([onChange]);
/// entonces, si el vigente difiere, se muestra y se vuelve a esperar.
class _Paced<T> {
  _Paced(this.onChange, {this.immediate});

  final VoidCallback onChange;
  final bool Function(T value)? immediate;
  static const interval = Duration(seconds: 1);

  T? _value;
  Timer? _cooling;

  T resolve(T live) {
    final shown = _value;
    if (shown == live) return live;
    final urgent =
        shown == null ||
        (immediate?.call(live) ?? false) ||
        (immediate?.call(shown) ?? false);
    if (_cooling == null || urgent) {
      _value = live;
      _cooling?.cancel();
      _cooling = Timer(interval, () {
        _cooling = null;
        onChange();
      });
      return live;
    }
    return shown;
  }

  void reset() {
    _cooling?.cancel();
    _cooling = null;
    _value = null;
  }
}
