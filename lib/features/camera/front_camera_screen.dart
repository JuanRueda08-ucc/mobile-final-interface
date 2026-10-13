import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/design_system/theme.dart';
import '../../core/design_system/vigia_icons.dart';
import '../../core/design_system/widgets/notice_host.dart';
import '../../core/design_system/widgets/vigia_blocks.dart';
import '../../core/design_system/widgets/vigia_button.dart';
import '../../core/design_system/widgets/vigia_flow_blocks.dart';
import '../../core/design_system/widgets/vigia_scaffold.dart';
import '../../core/design_system/widgets/vigia_text.dart';
import 'front_camera_controller.dart';

/// Cámara frontal (variante normal; permiso P02 y vista previa de P04).
///
/// - Fase 5A: vista previa real de la cámara frontal y permiso.
/// - Fase 5B: **detección facial en pruebas**. El motor analiza la imagen en
///   el teléfono y la pantalla muestra el estado del modelo y la presencia
///   facial (filas «Modelo» y «Rostro (informativo)» de P04 en B5.2).
///
/// No evalúa los ojos ni la fatiga: no hay calibración ni sesión, así que
/// Calibrar e Iniciar monitoreo siguen deshabilitados aunque se detecte un
/// rostro. La cámara y el modelo se liberan al salir y en segundo plano.
class FrontCameraScreen extends ConsumerStatefulWidget {
  const FrontCameraScreen({super.key});

  static const purpose =
      'Vigía usa la cámara frontal del teléfono para observar señales '
      'faciales relacionadas con somnolencia. El procesamiento se hace en este '
      'teléfono.';
  static const scope =
      'En esta versión la imagen se analiza en el teléfono solo para saber si '
      'hay un rostro: no se graba, no se guarda y no se envía ninguna imagen.';
  static const settingsFailedNotice =
      'No se pudieron abrir los ajustes del teléfono.';

  /// Causa visible de «Modelo no disponible» según el código del motor.
  static String modelCause(String? code) => switch (code) {
    'modelMissing' => 'El modelo facial no está en la aplicación.',
    'modelCorrupt' => 'El archivo del modelo no coincide con el verificado.',
    'modelIncompatible' => 'El modelo no se pudo iniciar en este teléfono.',
    _ => 'No se pudo leer el modelo facial.',
  };

  /// Texto de presencia sobre la vista previa (`VIEWER` de B5.2).
  static String presenceLabel(FacePresencePhase phase) => switch (phase) {
    FacePresencePhase.stopped => 'Análisis detenido',
    FacePresencePhase.loadingModel => 'Cargando el modelo…',
    FacePresencePhase.waitingResults => 'Esperando resultados…',
    FacePresencePhase.noFace => 'Rostro no detectado',
    FacePresencePhase.oneFace => 'Rostro detectado',
    FacePresencePhase.multipleFaces => 'Varios rostros detectados',
    FacePresencePhase.modelError => 'Modelo no disponible',
    FacePresencePhase.analysisError => 'Error de análisis',
  };

  @override
  ConsumerState<FrontCameraScreen> createState() => _FrontCameraScreenState();
}

class _FrontCameraScreenState extends ConsumerState<FrontCameraScreen>
    with NoticeHost {
  late final FrontCameraController _camera;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _camera = ref.read(frontCameraProvider.notifier);
    // Ir a los ajustes del teléfono u otra app libera la cámara; al volver se
    // consulta de nuevo el permiso.
    _lifecycle = AppLifecycleListener(
      onHide: _camera.suspend,
      onShow: _camera.resume,
    );
    Future.microtask(_camera.enter);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _camera.leave();
    super.dispose();
  }

  void _back() => context.go(VigiaRoutes.inicio);

  Future<void> _openSettings() async {
    if (!await _camera.openSettings() && mounted) {
      showNotice(FrontCameraScreen.settingsFailedNotice);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(frontCameraProvider);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: VigiaScaffold(
        title: 'Cámara frontal',
        onBack: _back,
        notice: notice,
        children: [
          const VigiaParagraph(
            'Comprueba la cámara con el vehículo detenido y el teléfono en un '
            'soporte estable.',
            secondary: true,
          ),
          FrontCameraStage(state: s),
          ..._permissionBlocks(s),
          CheckGroup(rows: _rows(s)),
          if (s.phase == CameraCheckPhase.available)
            const StatusCard(
              key: Key('camera-available'),
              tone: StatusTone.strong,
              icon: VigiaIcon.check,
              tag: 'Cámara',
              title: 'Cámara disponible',
              text:
                  'La vista previa es real y se procesa solo en este teléfono. '
                  'No se graba, no se guarda ni se envía ninguna imagen.',
            ),
          const StatusCard(
            key: Key('face-detection-testing'),
            tone: StatusTone.neutral,
            icon: VigiaIcon.info,
            tag: 'Detección facial',
            title: 'Detección facial en pruebas',
            text:
                'El modelo facial funciona en este teléfono, sin Internet, y '
                'solo indica si ve un rostro, varios o ninguno. No guarda ni '
                'envía imágenes ni puntos faciales.',
          ),
          const StatusCard(
            key: Key('detection-pending'),
            tone: StatusTone.pending,
            icon: VigiaIcon.clock,
            tag: 'Detección',
            title: 'Detección de fatiga pendiente',
            text:
                'Esta versión todavía no evalúa los ojos ni detecta señales de '
                'somnolencia. Un rostro detectado no es una evaluación de '
                'fatiga.',
          ),
          const VigiaParagraph(
            'Calibrar e Iniciar monitoreo no están disponibles: falta la '
            'detección de fatiga. Detectar un rostro no basta para empezar.',
            secondary: true,
          ),
          const VigiaButton(
            label: 'Calibrar',
            kind: VigiaButtonKind.secondary,
            icon: VigiaIcon.target,
            onPressed: null,
          ),
          const VigiaButton(label: 'Iniciar monitoreo', onPressed: null),
        ],
      ),
    );
  }

  /// Explicación del permiso y sus acciones (P02, FL01, UX02).
  List<Widget> _permissionBlocks(FrontCameraState s) {
    switch (s.phase) {
      case CameraCheckPhase.explain:
      case CameraCheckPhase.requesting:
      case CameraCheckPhase.denied:
        return [
          const VigiaHeading('Permiso de cámara'),
          const VigiaParagraph(FrontCameraScreen.purpose),
          const VigiaParagraph(FrontCameraScreen.scope),
          const VigiaParagraph(
            'Sin este permiso no se puede preparar ni iniciar una sesión.',
            secondary: true,
          ),
          if (s.phase == CameraCheckPhase.denied)
            const StatusCard(
              key: Key('permission-denied'),
              tone: StatusTone.alert,
              icon: VigiaIcon.close,
              tag: 'Permiso',
              title: 'Cámara sin permiso',
              text: 'No se abre la cámara y no se crea ninguna sesión.',
            ),
          VigiaButton(
            label: s.phase == CameraCheckPhase.requesting
                ? 'Esperando respuesta…'
                : 'Permitir cámara',
            onPressed: s.phase == CameraCheckPhase.requesting
                ? null
                : _camera.requestPermission,
          ),
          // Sin respuesta o con un rechazo que Android aún podría volver a
          // preguntar no se afirma que la solicitud esté bloqueada: se ofrece
          // repetirla y, como alternativa, los ajustes del teléfono.
          if (s.phase == CameraCheckPhase.denied) ...[
            const VigiaParagraph(
              'Si la solicitud de Android no aparece, puedes conceder el '
              'permiso en los ajustes del teléfono.',
              secondary: true,
            ),
            VigiaButton(
              label: 'Abrir ajustes',
              kind: VigiaButtonKind.secondary,
              onPressed: _openSettings,
            ),
          ],
          VigiaButton(
            label: 'Ahora no',
            kind: VigiaButtonKind.secondary,
            onPressed: _back,
          ),
        ];
      case CameraCheckPhase.requiresSettings:
        return [
          const VigiaHeading('Permiso de cámara'),
          const VigiaParagraph(FrontCameraScreen.purpose),
          const StatusCard(
            key: Key('permission-settings'),
            tone: StatusTone.alert,
            icon: VigiaIcon.close,
            tag: 'Permiso',
            title: 'Cámara sin permiso',
            text:
                'Android ya no muestra la solicitud. Abre los ajustes del '
                'teléfono y concede el permiso de cámara. Al volver se '
                'consultará de nuevo.',
          ),
          VigiaButton(label: 'Abrir ajustes', onPressed: _openSettings),
          VigiaButton(
            label: 'Ahora no',
            kind: VigiaButtonKind.secondary,
            onPressed: _back,
          ),
        ];
      default:
        return const [];
    }
  }

  List<CheckRow> _rows(FrontCameraState s) {
    final granted = s.permissionGranted;
    final permissionKnown = s.permission != null;
    final (cameraOk, cameraValue, cameraCause) = switch (s.phase) {
      CameraCheckPhase.available => (true, 'Disponible', null),
      CameraCheckPhase.opening => (false, 'Abriendo la cámara…', null),
      CameraCheckPhase.checking => (false, 'Comprobando…', null),
      CameraCheckPhase.noFrontCamera => (
        false,
        'Cámara frontal no encontrada',
        'Este teléfono no ofrece una cámara frontal a la aplicación.',
      ),
      CameraCheckPhase.inUse => (
        false,
        'Cámara no disponible: otra aplicación la está usando',
        'Cierra la otra aplicación y reintenta.',
      ),
      CameraCheckPhase.disabled => (
        false,
        'Cámara no disponible',
        'La cámara está desactivada en este teléfono.',
      ),
      CameraCheckPhase.failed when s.bridgeFailure => (
        false,
        'Estado de la cámara no disponible',
        'No se pudo comunicar con el motor de la cámara. Reintenta.',
      ),
      CameraCheckPhase.failed => (false, 'Cámara no disponible', null),
      CameraCheckPhase.suspended => (
        false,
        'Cámara cerrada',
        'La aplicación pasó a segundo plano. Se reabre al volver.',
      ),
      _ => (
        false,
        'Cámara no disponible',
        granted ? null : 'Necesita el permiso de cámara.',
      ),
    };
    final retry = switch (s.phase) {
      CameraCheckPhase.inUse ||
      CameraCheckPhase.failed ||
      CameraCheckPhase.disabled ||
      CameraCheckPhase.noFrontCamera => VigiaButton(
        label: 'Reintentar',
        kind: VigiaButtonKind.secondary,
        icon: VigiaIcon.refresh,
        onPressed: _camera.retry,
      ),
      _ => null,
    };
    final (modelOk, modelValue, modelCause, modelAction) = _modelRow(s);
    final (faceOk, faceValue, faceCause, faceAction) = _faceRow(s);
    return [
      CheckRow(
        label: 'Permiso de cámara',
        ok: granted,
        value: granted
            ? 'Concedido'
            : permissionKnown
            ? 'Cámara sin permiso'
            : s.phase == CameraCheckPhase.checking
            ? 'Comprobando…'
            : 'Permiso sin comprobar',
      ),
      CheckRow(
        label: 'Cámara',
        ok: cameraOk,
        value: cameraValue,
        cause: cameraCause,
        action: retry,
      ),
      CheckRow(
        key: const Key('row-model'),
        label: 'Modelo',
        ok: modelOk,
        value: modelValue,
        cause: modelCause,
        action: modelAction,
      ),
      CheckRow(
        key: const Key('row-face'),
        label: 'Rostro (informativo)',
        ok: faceOk,
        value: faceValue,
        cause: faceCause,
        action: faceAction,
      ),
      const CheckRow(
        label: 'Detección de fatiga',
        ok: false,
        value: 'Detección de fatiga pendiente',
        cause: 'Esta versión no evalúa los ojos.',
      ),
    ];
  }

  /// Fila «Modelo» (B5.2 P04; ER04 «Modelo no disponible» con «Reintentar
  /// carga»).
  (bool, String, String?, Widget?) _modelRow(FrontCameraState s) =>
      s.faceStalled && s.facePhase != FacePresencePhase.stopped
      // Sin respuesta del motor no se sabe el estado del modelo.
      ? (
          false,
          'Estado del modelo no disponible',
          'El motor no responde a las consultas.',
          null,
        )
      : switch (s.facePhase) {
          FacePresencePhase.stopped => (
            false,
            'Modelo sin cargar',
            'Se carga al abrir la cámara y se libera al cerrarla.',
            null,
          ),
          FacePresencePhase.loadingModel => (
            false,
            'Cargando el modelo…',
            null,
            null,
          ),
          FacePresencePhase.modelError => (
            false,
            'Modelo no disponible',
            FrontCameraScreen.modelCause(s.face?.errorCode),
            VigiaButton(
              label: 'Reintentar carga',
              kind: VigiaButtonKind.secondary,
              icon: VigiaIcon.refresh,
              onPressed: _camera.retryFaceAnalysis,
            ),
          ),
          _ => (true, 'Cargado', null, null),
        };

  /// Fila «Rostro (informativo)». Solo un resultado vigente del motor dice
  /// si hay rostro; sin él, se espera (nunca «no detectado» por silencio).
  (bool, String, String?, Widget?) _faceRow(FrontCameraState s) =>
      switch (s.facePhase) {
        FacePresencePhase.stopped => (
          false,
          'Análisis detenido',
          'Solo se analiza con la cámara abierta.',
          null,
        ),
        FacePresencePhase.loadingModel => (
          false,
          'Esperando el modelo…',
          null,
          null,
        ),
        FacePresencePhase.waitingResults => (
          false,
          'Esperando resultados…',
          s.faceStalled
              ? 'El motor no responde a las consultas. Se volverá a '
                    'consultar cuando responda.'
              : s.faceExpired
              ? 'El último resultado caducó y ya no se muestra.'
              : null,
          null,
        ),
        FacePresencePhase.noFace => (
          false,
          'Rostro no detectado',
          'Revisa el encuadre: el rostro debe verse completo.',
          null,
        ),
        FacePresencePhase.oneFace => (
          true,
          'Rostro detectado',
          'Presencia facial no equivale a ojos medibles.',
          null,
        ),
        FacePresencePhase.multipleFaces => (
          false,
          'Varios rostros detectados',
          'Con más de un rostro en la imagen no se sabe cuál es el tuyo.',
          null,
        ),
        FacePresencePhase.modelError => (
          false,
          'Sin análisis',
          'Falta el modelo facial.',
          null,
        ),
        FacePresencePhase.analysisError => (
          false,
          'Error de análisis',
          'El análisis facial se detuvo.',
          VigiaButton(
            label: 'Reintentar',
            kind: VigiaButtonKind.secondary,
            icon: VigiaIcon.refresh,
            onPressed: _camera.retryFaceAnalysis,
          ),
        ),
      };
}

/// Zona de vista previa real (`VIEWER` de B5.2). Con la cámara abierta muestra
/// la textura del motor, girada y espejada según su respuesta; si no, dice
/// el estado sin mostrar ninguna imagen.
class FrontCameraStage extends StatelessWidget {
  const FrontCameraStage({super.key, required this.state});

  final FrontCameraState state;

  @override
  Widget build(BuildContext context) {
    final p = VigiaColors.of(context);
    final preview = state.preview;
    if (state.phase == CameraCheckPhase.available && preview != null) {
      final w = (preview.width ?? 3).toDouble();
      final h = (preview.height ?? 4).toDouble();
      return Semantics(
        key: const Key('camera-preview'),
        container: true,
        label: 'Vista previa de la cámara frontal',
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400),
            child: AspectRatio(
              aspectRatio: w / h,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Fondo mientras llega el primer cuadro de la cámara.
                    const ColoredBox(color: Color(0xFF111111)),
                    Transform.flip(
                      flipX: preview.mirrored ?? true,
                      child: RotatedBox(
                        quarterTurns: (preview.rotationDegrees ?? 0) ~/ 90,
                        child: Texture(textureId: preview.textureId!),
                      ),
                    ),
                    const Positioned(
                      left: 12,
                      top: 12,
                      child: _StageTag('Detección facial en pruebas'),
                    ),
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: Semantics(
                        key: const Key('presence-label'),
                        liveRegion: true,
                        child: _StageTag(
                          FrontCameraScreen.presenceLabel(state.facePhase),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    final text = switch (state.phase) {
      CameraCheckPhase.checking => 'Comprobando el permiso de cámara…',
      CameraCheckPhase.opening => 'Abriendo la cámara frontal…',
      CameraCheckPhase.suspended => 'Cámara cerrada mientras la app no se ve',
      CameraCheckPhase.noFrontCamera => 'Cámara frontal no encontrada',
      CameraCheckPhase.explain ||
      CameraCheckPhase.requesting ||
      CameraCheckPhase.denied ||
      CameraCheckPhase.requiresSettings => 'Cámara sin permiso',
      _ => 'Cámara no disponible para la vista previa',
    };
    return Semantics(
      container: true,
      label: 'Vista previa no disponible',
      child: Container(
        constraints: const BoxConstraints(minHeight: 208),
        decoration: BoxDecoration(
          color: p.neutralBg,
          borderRadius: BorderRadius.circular(28),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _StageTag('Cámara frontal'),
            const SizedBox(height: 16),
            VigiaText(
              'No se muestra ninguna imagen hasta que la cámara esté abierta.',
              style: VigiaType.small.copyWith(color: p.neutralInk),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: VigiaText(
                text,
                style: VigiaType.small.copyWith(
                  color: p.ink,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageTag extends StatelessWidget {
  const _StageTag(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFF111111),
      borderRadius: BorderRadius.circular(12),
    ),
    child: VigiaText(
      text,
      style: VigiaType.demoLabel.copyWith(color: const Color(0xFFFFFFFF)),
    ),
  );
}
