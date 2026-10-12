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

/// Cámara frontal (fase 5A, variante normal; permiso P02 y vista previa de
/// P04).
///
/// Abre la vista previa real de la cámara frontal y gestiona el permiso. No
/// analiza la imagen: no hay detección facial, calibración ni sesión, así que
/// Calibrar e Iniciar monitoreo siguen deshabilitados aunque la vista previa
/// funcione. La cámara se libera al salir y al pasar a segundo plano.
class FrontCameraScreen extends ConsumerStatefulWidget {
  const FrontCameraScreen({super.key});

  static const purpose =
      'Vigía usa la cámara frontal del teléfono para observar señales '
      'faciales relacionadas con somnolencia. El procesamiento se hace en este '
      'teléfono.';
  static const scope =
      'En esta versión solo se muestra la vista previa: no se analiza, no se '
      'graba y no se guarda ninguna imagen.';
  static const settingsFailedNotice =
      'No se pudieron abrir los ajustes del teléfono.';

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
                  'No se analiza ni se guarda ninguna imagen.',
            ),
          const StatusCard(
            key: Key('detection-pending'),
            tone: StatusTone.pending,
            icon: VigiaIcon.clock,
            tag: 'Detección',
            title: 'Detección de fatiga pendiente',
            text:
                'Esta versión todavía no incluye el modelo facial: no evalúa '
                'los ojos ni detecta señales de somnolencia.',
          ),
          const VigiaParagraph(
            'Calibrar e Iniciar monitoreo no están disponibles: falta la '
            'detección de fatiga. La vista previa no basta para empezar.',
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
    return [
      CheckRow(
        label: 'Permiso de cámara',
        ok: granted,
        value: granted
            ? 'Concedido'
            : permissionKnown
            ? 'Cámara sin permiso'
            : 'Comprobando…',
      ),
      CheckRow(
        label: 'Cámara',
        ok: cameraOk,
        value: cameraValue,
        cause: cameraCause,
        action: retry,
      ),
      const CheckRow(
        label: 'Detección de fatiga',
        ok: false,
        value: 'Detección de fatiga pendiente',
        cause: 'Sin modelo facial no hay medición ocular.',
      ),
    ];
  }
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
                      child: _StageTag('Vista previa · sin análisis'),
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
