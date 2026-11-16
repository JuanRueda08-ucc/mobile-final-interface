import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:monitoring_engine/monitoring_engine.dart';

import '../../core/design_system/theme.dart';
import '../../core/design_system/tokens.dart';
import '../../core/design_system/vigia_icons.dart';
import '../camera/front_camera_controller.dart';

/// Rediseño de P06 con la referencia del usuario (GIF, 2026-11-15): la
/// cámara ocupa el ancho de la pantalla y encima se dibujan los chips de
/// estado, los recuadros de la cara y los ojos y unas lecturas breves.
///
/// Solo presenta lo que ya decidió el motor: los chips repiten Cámara,
/// Rostro, Ojos medibles y la señal; los recuadros son los del resultado
/// vigente con un rostro ([FaceAnalysisSnapshot.faceBoxes]).

/// Estado de un chip sobre la cámara.
enum StageChipTone { ok, off, alert }

class StageChip {
  const StageChip(this.icon, this.label, this.tone);

  final VigiaIcon icon;
  final String label;
  final StageChipTone tone;
}

/// Recuadros vigentes en coordenadas de pantalla normalizadas (0..1 sobre la
/// imagen ya girada y espejada como la vista previa): `[cara, der., izq.]`.
/// Nulo sin un rostro vigente.
List<Rect>? stageFaceBoxes(FrontCameraState cam) {
  if (cam.facePhase != FacePresencePhase.oneFace) return null;
  final f = cam.face;
  final v = f?.faceBoxes;
  final preview = cam.preview;
  if (f == null || v == null || v.length != 12 || preview == null) {
    return null;
  }
  final turns =
      ((f.frameRotationDegrees ?? preview.rotationDegrees ?? 0) ~/ 90) % 4;
  final mirrored = preview.mirrored ?? true;
  return [
    for (var i = 0; i < 3; i++)
      displayBox(
        Rect.fromLTRB(v[4 * i], v[4 * i + 1], v[4 * i + 2], v[4 * i + 3]),
        quarterTurns: turns,
        mirrored: mirrored,
      ),
  ];
}

/// Inclinación de la cabeza en pantalla (radianes, ±45° como mucho): el
/// ángulo de la línea entre los centros de los ojos, medida de izquierda a
/// derecha en pantalla.
double stageFaceRoll(Offset eyeA, Offset eyeB) {
  final (l, r) = eyeA.dx <= eyeB.dx ? (eyeA, eyeB) : (eyeB, eyeA);
  final d = r - l;
  if (d.distance < 1) return 0;
  return math.atan2(d.dy, d.dx).clamp(-math.pi / 4, math.pi / 4);
}

/// Tamaño del rostro sin girar a partir de su caja recta en pantalla y la
/// inclinación [roll]: deshace `W = w·cos + h·sen`, `H = w·sen + h·cos`.
/// Nunca baja del 60 % de la caja.
Size uprightFaceSize(Size box, double roll) {
  final c = math.cos(roll).abs();
  final s = math.sin(roll).abs();
  final det = c * c - s * s;
  if (det < 0.2) return box * 0.75;
  final w = (box.width * c - box.height * s) / det;
  final h = (box.height * c - box.width * s) / det;
  return Size(math.max(w, box.width * 0.6), math.max(h, box.height * 0.6));
}

/// Lleva un recuadro normalizado del cuadro analizado (sin girar) a la
/// imagen mostrada: gira [quarterTurns] cuartos en sentido horario, como el
/// `RotatedBox` de la vista previa, y después espeja en horizontal.
Rect displayBox(Rect r, {required int quarterTurns, required bool mirrored}) {
  final up = switch (quarterTurns % 4) {
    1 => Rect.fromLTRB(1 - r.bottom, r.left, 1 - r.top, r.right),
    2 => Rect.fromLTRB(1 - r.right, 1 - r.bottom, 1 - r.left, 1 - r.top),
    3 => Rect.fromLTRB(r.top, 1 - r.right, r.bottom, 1 - r.left),
    _ => r,
  };
  return mirrored
      ? Rect.fromLTRB(1 - up.right, up.top, 1 - up.left, up.bottom)
      : up;
}

/// Cámara de P04–P06 con la capa de estado.
class MonitoringStage extends StatelessWidget {
  const MonitoringStage({
    super.key,
    required this.cam,
    required this.height,
    required this.chips,
    this.readouts = const [],
    this.alert = false,
    this.idleTitle,
    this.idleIcon,
  });

  final FrontCameraState cam;
  final double height;
  final List<StageChip> chips;

  /// Líneas breves abajo a la izquierda (EAR, tiempo).
  final List<String> readouts;

  /// Cierre ocular prolongado: borde, recuadros y franja de aviso en coral.
  final bool alert;

  /// Sin vista previa (pausa, permisos): título del panel oscuro. Nulo:
  /// estado de la cámara.
  final String? idleTitle;
  final VigiaIcon? idleIcon;

  static String cameraText(CameraCheckPhase phase) => switch (phase) {
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

  @override
  Widget build(BuildContext context) {
    final preview = cam.preview;
    final live =
        cam.phase == CameraCheckPhase.available &&
        preview != null &&
        idleTitle == null;
    final ring = alert ? VigiaBrand.coral : Colors.transparent;
    // Las etiquetas sobre la imagen no crecen sin límite con el texto
    // ampliado: el espacio sobre la cámara es fijo.
    final scaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3);
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: scaler),
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : VigiaMotion.colorDuration,
        height: height,
        decoration: BoxDecoration(
          color: VigiaBrand.ink,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: ring, width: 4),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (live)
              Semantics(
                key: const Key('camera-preview'),
                container: true,
                label: 'Vista previa de la cámara frontal',
                child: _CoverPreview(
                  preview: preview,
                  boxes: stageFaceBoxes(cam),
                  alert: alert,
                ),
              )
            else
              _IdlePanel(
                icon: idleIcon ?? VigiaIcon.camera,
                text: idleTitle ?? cameraText(cam.phase),
              ),
            // Sombra suave arriba y abajo para leer los chips y las lecturas.
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x8C000000),
                      Color(0x00000000),
                      Color(0x00000000),
                      Color(0x99000000),
                    ],
                    stops: [0, 0.3, 0.62, 1],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              top: 10,
              child: _ChipRow(chips: chips),
            ),
            // Las lecturas acompañan a la imagen; sin ella no se muestran.
            if (live && readouts.isNotEmpty)
              Positioned(
                left: 14,
                right: 14,
                bottom: alert ? 56 : 12,
                child: _Readouts(lines: readouts),
              ),
            if (alert)
              const Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: _AlertBand(),
              ),
          ],
        ),
      ),
    );
  }
}

class _CoverPreview extends StatelessWidget {
  const _CoverPreview({
    required this.preview,
    required this.boxes,
    required this.alert,
  });

  final PreviewOpenResult preview;
  final List<Rect>? boxes;
  final bool alert;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final w = (preview.width ?? 3).toDouble();
      final h = (preview.height ?? 4).toDouble();
      // Cubre todo el escenario y recorta lo que sobra, centrado.
      final scale = math.max(c.maxWidth / w, c.maxHeight / h);
      final shown = Size(w * scale, h * scale);
      final image = Rect.fromLTWH(
        (c.maxWidth - shown.width) / 2,
        (c.maxHeight - shown.height) / 2,
        shown.width,
        shown.height,
      );
      return Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fromRect(
            rect: image,
            child: Transform.flip(
              flipX: preview.mirrored ?? true,
              child: RotatedBox(
                quarterTurns: (preview.rotationDegrees ?? 0) ~/ 90,
                child: Texture(textureId: preview.textureId!),
              ),
            ),
          ),
          Positioned.fill(
            child: _AnimatedBoxes(boxes: boxes, image: image, alert: alert),
          ),
        ],
      );
    },
  );
}

/// Recuadros que se deslizan entre resultados (llegan unas 5 veces por
/// segundo) en lugar de saltar. Sin rostro vigente se desvanecen.
class _AnimatedBoxes extends StatefulWidget {
  const _AnimatedBoxes({
    required this.boxes,
    required this.image,
    required this.alert,
  });

  final List<Rect>? boxes;
  final Rect image;
  final bool alert;

  @override
  State<_AnimatedBoxes> createState() => _AnimatedBoxesState();
}

class _AnimatedBoxesState extends State<_AnimatedBoxes>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );
  List<Rect>? _from;
  List<Rect>? _to;

  /// Últimos recuadros dibujados, para desvanecerlos al perder el rostro.
  List<Rect>? _last;

  @override
  void initState() {
    super.initState();
    _to = widget.boxes;
    _c.value = 1;
  }

  @override
  void didUpdateWidget(_AnimatedBoxes old) {
    super.didUpdateWidget(old);
    final next = widget.boxes;
    if (_same(next, _to)) return;
    _from = _current();
    _to = next;
    if (MediaQuery.disableAnimationsOf(context) ||
        _from == null ||
        next == null) {
      _c.value = 1;
    } else {
      _c.forward(from: 0);
    }
  }

  static bool _same(List<Rect>? a, List<Rect>? b) {
    if (a == null || b == null) return a == b;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  List<Rect>? _current() {
    final to = _to;
    final from = _from;
    if (to == null || from == null || _c.value >= 1) return to;
    final t = Curves.easeOut.transform(_c.value);
    return [for (var i = 0; i < to.length; i++) Rect.lerp(from[i], to[i], t)!];
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, _) {
      final boxes = _current();
      if (boxes != null) _last = boxes;
      final drawn = boxes ?? _last;
      return AnimatedOpacity(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 200),
        opacity: boxes == null ? 0 : 1,
        child: drawn == null
            ? const SizedBox.expand()
            : CustomPaint(
                key: boxes == null ? null : const Key('face-boxes'),
                size: Size.infinite,
                painter: _BoxesPainter(
                  boxes: drawn,
                  image: widget.image,
                  color: widget.alert ? VigiaBrand.coral : VigiaBrand.orange,
                ),
              ),
      );
    },
  );
}

class _BoxesPainter extends CustomPainter {
  _BoxesPainter({
    required this.boxes,
    required this.image,
    required this.color,
  });

  final List<Rect> boxes;
  final Rect image;
  final Color color;

  Rect _onScreen(Rect n) => Rect.fromLTRB(
    image.left + n.left * image.width,
    image.top + n.top * image.height,
    image.left + n.right * image.width,
    image.top + n.bottom * image.height,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final right = _onScreen(boxes[1]);
    final left = _onScreen(boxes[2]);
    // Como en la referencia: el recuadro se inclina con la cabeza. El giro
    // sale de la línea entre los ojos (solo presentación).
    final roll = stageFaceRoll(right.center, left.center);
    final box = _onScreen(boxes[0]);
    final upright = uprightFaceSize(box.size, roll);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = color;
    canvas.save();
    canvas.translate(box.center.dx, box.center.dy);
    canvas.rotate(roll);
    _dashed(
      canvas,
      Path()..addRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: upright.width + 12,
          height: upright.height + 12,
        ),
      ),
      line,
    );
    canvas.restore();
    final eyePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = color.withValues(alpha: 0.9);
    for (final r in [right, left]) {
      // Marca de ojo del ancho del ojo detectado, inclinada igual.
      final side = math.max(14.0, math.max(r.width, r.height) * 0.85);
      canvas.save();
      canvas.translate(r.center.dx, r.center.dy);
      canvas.rotate(roll);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: side, height: side * 0.55),
        eyePaint,
      );
      canvas.restore();
    }
  }

  /// Trazo discontinuo fino (6 de línea, 4 de hueco).
  void _dashed(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 10) {
        canvas.drawPath(
          metric.extractPath(d, math.min(d + 6, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BoxesPainter old) =>
      old.color != color || old.image != image || old.boxes != boxes;
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.chips});

  final List<StageChip> chips;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final c in chips)
        Expanded(
          child: Semantics(
            label:
                '${c.label}: ${switch (c.tone) {
                  StageChipTone.ok => 'correcto',
                  StageChipTone.off => 'no',
                  StageChipTone.alert => 'aviso',
                }}',
            excludeSemantics: true,
            child: _Chip(chip: c),
          ),
        ),
    ],
  );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.chip});

  final StageChip chip;

  @override
  Widget build(BuildContext context) {
    final (fill, ink) = switch (chip.tone) {
      StageChipTone.ok => (VigiaBrand.mistBlue, VigiaBrand.ink),
      StageChipTone.off => (const Color(0x40FFFFFF), Colors.white),
      StageChipTone.alert => (VigiaBrand.coral, VigiaBrand.ink),
    };
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: reduce ? Duration.zero : VigiaMotion.colorDuration,
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0x66FFFFFF)),
          ),
          alignment: Alignment.center,
          child: VigiaIconView(chip.icon, size: 22, color: ink),
        ),
        const SizedBox(height: 3),
        Text(
          chip.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: VigiaType.demoLabel.copyWith(
            color: Colors.white,
            shadows: const [Shadow(blurRadius: 3)],
          ),
        ),
      ],
    );
  }
}

class _Readouts extends StatelessWidget {
  const _Readouts({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final l in lines)
        Text(
          l,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: VigiaType.demoLabel.copyWith(
            color: VigiaBrand.mistBlue,
            fontFeatures: const [FontFeature.tabularFigures()],
            shadows: const [Shadow(blurRadius: 3)],
          ),
        ),
    ],
  );
}

class _AlertBand extends StatelessWidget {
  const _AlertBand();

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('stage-alert'),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: VigiaBrand.coral,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        const VigiaIconView(
          VigiaIcon.eyeClosed,
          size: 22,
          color: VigiaBrand.ink,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Cierre ocular prolongado',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: VigiaType.smallIndicator.copyWith(color: VigiaBrand.ink),
          ),
        ),
      ],
    ),
  );
}

class _IdlePanel extends StatelessWidget {
  const _IdlePanel({required this.icon, required this.text});

  final VigiaIcon icon;
  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: text,
    excludeSemantics: true,
    // Debajo de los chips; con poco alto (texto ampliado) se reduce.
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 76, 16, 8),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 260,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              VigiaIconView(icon, size: 32, color: const Color(0xCCFFFFFF)),
              const SizedBox(height: 8),
              Text(
                text,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: VigiaType.small.copyWith(color: const Color(0xE6FFFFFF)),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
