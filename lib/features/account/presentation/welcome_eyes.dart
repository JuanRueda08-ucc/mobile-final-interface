import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/design_system/theme.dart';
import '../../../core/design_system/tokens.dart';

/// Ilustración de la bienvenida (P01). Es decorativa y no representa
/// ninguna medición.
///
/// Dos protagonistas dibujados con volumen y trazo grueso:
/// - el símbolo de Vigía, un ojo con rayos sobre una esfera lavanda, que
///   parpadea con su párpado, mueve la pupila y enciende los rayos;
/// - un personaje coral con ojos grandes, cejas, rulo y mejillas.
///
/// Bucle de 7 s: el personaje sonríe y mira alrededor; le da sueño (cejas y
/// párpados caen, «zz»); el símbolo lo mira, parpadea, enciende los rayos,
/// envía ondas y dice «¡Ojo!»; el personaje salta sorprendido y termina
/// sonriendo. Con movimiento reducido se dibuja el instante [stillPhase]
/// (personaje sorprendido y burbuja visible), sin animación.
class WelcomeEyes extends StatefulWidget {
  const WelcomeEyes({super.key});

  /// Fase fija del dibujo estático (movimiento reducido).
  static const stillPhase = 0.72;

  @override
  State<WelcomeEyes> createState() => _WelcomeEyesState();
}

/// Posiciones en fracciones del área (x del ancho, y del alto).
const _markAt = Offset(0.29, 0.56);
const _buddyAt = Offset(0.73, 0.56);

double _smooth(double a, double b, double t) {
  final x = ((t - a) / (b - a)).clamp(0.0, 1.0);
  return x * x * (3 - 2 * x);
}

/// Cierre de un parpadeo de ~0,5 s que empieza en cada fase de [at].
double _blink(List<double> at, double t) {
  var k = 0.0;
  for (final b in at) {
    final d = (t - b) % 1;
    if (d < 0.07) k = math.max(k, math.sin(math.pi * d / 0.07));
  }
  return k;
}

// ── Línea de tiempo (fases 0–1 de un bucle de 7 s) ──────────────────────
double _drowse(double t) =>
    _smooth(0.14, 0.40, t) * (1 - _smooth(0.62, 0.65, t));
double _watch(double t) =>
    _smooth(0.34, 0.42, t) * (1 - _smooth(0.86, 0.95, t));
double _flare(double t) =>
    _smooth(0.47, 0.53, t) * (1 - _smooth(0.74, 0.84, t));
double _signal(double t) => _smooth(0.50, 0.64, t);
double _bubble(double t) =>
    Curves.elasticOut.transform(_smooth(0.57, 0.69, t)) *
    (1 - _smooth(0.88, 0.94, t));
double _surprise(double t) =>
    _smooth(0.62, 0.65, t) * (1 - _smooth(0.76, 0.82, t));
double _happy(double t) =>
    math.max(_smooth(0.78, 0.84, t), 1 - _smooth(0.10, 0.18, t));

/// Salto al despertar (0 → 1 → 0).
double _jump(double t) {
  final x = ((t - 0.62) / 0.09).clamp(0.0, 1.0);
  return math.sin(math.pi * x);
}

class _WelcomeEyesState extends State<WelcomeEyes>
    with TickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  );
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  bool _reduce = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduce = MediaQuery.disableAnimationsOf(context);
    if (_reduce) {
      _loop.stop();
      _enter.value = 1;
    } else {
      if (_enter.value == 0 && !_enter.isAnimating) _enter.forward();
      if (!_loop.isAnimating) _loop.repeat();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = VigiaColors.of(context);
    final dark = p.brightness == Brightness.dark;
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: Listenable.merge([_loop, _enter]),
          builder: (context, _) => CustomPaint(
            size: Size.infinite,
            painter: _ScenePainter(
              phase: _reduce ? WelcomeEyes.stillPhase : _loop.value,
              enter: Curves.easeOutBack.transform(_enter.value),
              line: dark ? VigiaBrand.wordmarkDark : VigiaBrand.ink,
              shadow: dark ? Colors.black : VigiaBrand.wordmarkLight,
              bubbleFill: dark ? VigiaBrand.wordmarkDark : VigiaBrand.ink,
              bubbleInk: dark ? VigiaBrand.ink : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter({
    required this.phase,
    required this.enter,
    required this.line,
    required this.shadow,
    required this.bubbleFill,
    required this.bubbleInk,
  });

  final double phase;
  final double enter;

  /// Trazos fuera de las figuras (rayos, «zz», marcas): legibles en el fondo.
  final Color line;
  final Color shadow;
  final Color bubbleFill;
  final Color bubbleInk;

  static const _ink = VigiaBrand.ink;

  @override
  void paint(Canvas canvas, Size size) {
    if (enter <= 0) return;
    final unit = math.min(size.width, size.height * 1.1);
    final u = unit * 0.21; // Medio ancho del símbolo.
    final r = unit * 0.18; // Radio del personaje.
    final float = math.sin(2 * math.pi * phase) * unit * 0.012;
    final mark = Offset(
      _markAt.dx * size.width,
      _markAt.dy * size.height + float,
    );
    final buddy = Offset(_buddyAt.dx * size.width, _buddyAt.dy * size.height);

    _groundShadow(canvas, Offset(mark.dx, mark.dy + u * 1.15), u * 0.8, 0);
    _groundShadow(
      canvas,
      Offset(buddy.dx, buddy.dy + r * 1.1),
      r * 0.85,
      _jump(phase),
    );
    _waves(canvas, mark, buddy, u, r, unit);
    _mark(canvas, mark, u * enter, buddy);
    _buddy(canvas, buddy, r * enter, mark, unit);
    _speech(canvas, mark, u, unit);
  }

  void _groundShadow(Canvas canvas, Offset c, double w, double lift) {
    canvas.drawOval(
      Rect.fromCenter(
        center: c,
        width: w * 2 * (1 - 0.3 * lift) * enter,
        height: w * 0.32 * (1 - 0.3 * lift) * enter,
      ),
      Paint()
        ..color = shadow.withValues(alpha: 0.12 * (1 - 0.5 * lift))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.12),
    );
  }

  /// Esfera con volumen: brillo arriba a la izquierda y borde más intenso.
  void _sphere(
    Canvas canvas,
    Offset c,
    double radius,
    Color color, {
    double glow = 0,
  }) {
    canvas.drawCircle(
      c,
      radius * (1.12 + 0.18 * glow),
      Paint()
        ..color = color.withValues(alpha: 0.30 + 0.30 * glow)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.28),
    );
    canvas.drawCircle(c, radius, _skin(c, radius, color));
  }

  /// Relleno con volumen de las esferas; los párpados lo reutilizan para
  /// confundirse con la piel.
  Paint _skin(Offset c, double radius, Color color) =>
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.38, -0.5),
          radius: 1.1,
          colors: [
            Color.lerp(color, Colors.white, 0.75)!,
            Color.lerp(color, Colors.white, 0.2)!,
            color,
            Color.lerp(color, const Color(0xFFB0004A), 0.22)!,
          ],
          stops: const [0, 0.35, 0.72, 1],
        ).createShader(Rect.fromCircle(center: c, radius: radius));

  Paint _stroke(double width, [Color color = _ink]) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = width;

  // ── Símbolo de Vigía ──────────────────────────────────────────────────
  void _mark(Canvas canvas, Offset c, double u, Offset buddy) {
    if (u <= 0) return;
    final flare = _flare(phase);
    final watch = _watch(phase);
    final lid = _blink(const [0.06, 0.43, 0.90], phase);
    final lean = _smooth(0.45, 0.52, phase) * (1 - _smooth(0.80, 0.9, phase));

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(0.10 * lean);

    _sphere(canvas, Offset.zero, u * 0.88, VigiaBrand.lavender, glow: flare);

    // Rayos: se alargan y toman color al avisar.
    final rayPaint = _stroke(
      u * 0.10,
      Color.lerp(line, VigiaBrand.coral, flare)!,
    );
    const rays = [
      (Offset(0, -0.56), Offset(0, -0.98)),
      (Offset(-0.40, -0.48), Offset(-0.66, -0.82)),
      (Offset(0.40, -0.48), Offset(0.66, -0.82)),
      (Offset(-0.22, 0.48), Offset(-0.48, 0.92)),
      (Offset(0.22, 0.48), Offset(0.48, 0.92)),
    ];
    for (final (a, b) in rays) {
      final from = a * u;
      final to = from + (b - a) * u * (1 + 0.35 * flare);
      canvas.drawLine(from, to, rayPaint);
    }
    canvas.drawLine(Offset(0, u * 0.52), Offset(0, u * 0.66), rayPaint);
    canvas.drawCircle(
      Offset(0, u * (0.84 + 0.08 * flare)),
      u * 0.05,
      Paint()..color = rayPaint.color,
    );

    // Ojo almendrado: el párpado superior baja al parpadear.
    final left = Offset(-0.98 * u, 0.06 * u);
    final right = Offset(0.98 * u, 0.06 * u);
    final upperY = (-0.82 + 1.42 * lid) * u;
    final upper = Path()
      ..moveTo(left.dx, left.dy)
      ..quadraticBezierTo(0, upperY, right.dx, right.dy);
    final lower = Path()
      ..moveTo(left.dx, left.dy)
      ..quadraticBezierTo(0, 0.62 * u, right.dx, right.dy);
    final eye = Path()
      ..moveTo(left.dx, left.dy)
      ..quadraticBezierTo(0, upperY, right.dx, right.dy)
      ..quadraticBezierTo(0, 0.62 * u, left.dx, left.dy)
      ..close();
    canvas.drawPath(eye, Paint()..color = Colors.white);

    // Iris y pupila: pasean y, mientras vigila, miran al personaje.
    final toBuddy = buddy - (c + Offset.zero);
    final dir = toBuddy / toBuddy.distance;
    final wander = Offset(math.sin(2 * math.pi * phase * 2) * 0.7, 0.1);
    final gaze = Offset.lerp(wander, dir, watch)!;
    canvas.save();
    canvas.clipPath(eye);
    final irisAt = Offset(gaze.dx * u * 0.36, 0.17 * u + gaze.dy * u * 0.08);
    final irisR = u * (0.30 + 0.04 * flare);
    canvas.drawCircle(
      irisAt,
      irisR,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.4),
          colors: [VigiaBrand.mistBlue, Color(0xFF6E7FD6)],
        ).createShader(Rect.fromCircle(center: irisAt, radius: irisR)),
    );
    canvas.drawCircle(irisAt, irisR, _stroke(u * 0.07));
    canvas.drawCircle(irisAt, u * 0.13, Paint()..color = _ink);
    canvas.drawCircle(
      irisAt + Offset(-u * 0.07, -u * 0.08),
      u * 0.055,
      Paint()..color = Colors.white,
    );
    canvas.restore();

    final lidPaint = _stroke(u * 0.11);
    canvas.drawPath(upper, lidPaint);
    // Párpado inferior con dos cortes, como el símbolo.
    final metric = lower.computeMetrics().first;
    for (final (a, b) in const [(0.0, 0.13), (0.23, 0.77), (0.87, 1.0)]) {
      canvas.drawPath(
        metric.extractPath(metric.length * a, metric.length * b),
        lidPaint,
      );
    }
    canvas.restore();
  }

  void _waves(
    Canvas canvas,
    Offset from,
    Offset to,
    double u,
    double r,
    double unit,
  ) {
    final s = _signal(phase);
    if (s <= 0 || s >= 1) return;
    final dir = to - from;
    final angle = math.atan2(dir.dy, dir.dx);
    final start = u * 1.0;
    final reach = dir.distance - r * 0.95;
    for (var i = 0; i < 3; i++) {
      final k = (s * 1.6 - i * 0.3).clamp(0.0, 1.0);
      if (k <= 0 || k >= 1) continue;
      canvas.drawArc(
        Rect.fromCircle(center: from, radius: start + (reach - start) * k),
        angle - 0.45,
        0.9,
        false,
        _stroke(
          math.max(3, unit * 0.016),
          VigiaBrand.coral.withValues(alpha: 0.95 * (1 - k)),
        ),
      );
    }
  }

  // ── Personaje ─────────────────────────────────────────────────────────
  void _buddy(Canvas canvas, Offset c, double r, Offset mark, double unit) {
    if (r <= 0) return;
    final drowse = _drowse(phase);
    final surprise = _surprise(phase);
    final happy = _happy(phase) * (1 - drowse);
    final jump = _jump(phase);
    final breathe = math.sin(2 * math.pi * phase * (drowse > 0.5 ? 2 : 3));
    final sx = 1 + 0.035 * breathe - 0.10 * jump;
    final sy = 1 - 0.035 * breathe + 0.14 * jump;
    final tilt = math.sin(2 * math.pi * phase * 1.5) * 0.10 * drowse;

    canvas.save();
    canvas.translate(c.dx, c.dy - jump * r * 0.45 + r);
    canvas.rotate(tilt);
    canvas.scale(sx, sy);
    canvas.translate(0, -r);

    // Rulo: trazo suelto que sale de la cabeza y se balancea.
    canvas.save();
    canvas.translate(0, -r * 0.9);
    canvas.rotate(math.sin(2 * math.pi * phase * 3) * 0.18 + 0.25 * jump);
    final curl = Path()
      ..moveTo(-r * 0.05, r * 0.05)
      ..cubicTo(-r * 0.10, -r * 0.45, r * 0.42, -r * 0.62, r * 0.38, -r * 0.28)
      ..cubicTo(r * 0.35, -r * 0.05, r * 0.08, -r * 0.14, r * 0.18, -r * 0.40);
    // En el tema oscuro, un contorno claro separa el rulo del fondo.
    if (line != _ink) canvas.drawPath(curl, _stroke(r * 0.16, line));
    canvas.drawPath(curl, _stroke(r * 0.085));
    canvas.restore();

    _sphere(canvas, Offset.zero, r, VigiaBrand.coral);

    // Mejillas.
    for (final side in [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(side * r * 0.56, r * 0.22),
          width: r * 0.34,
          height: r * 0.18,
        ),
        Paint()
          ..color = const Color(0xFFFF4D6D).withValues(alpha: 0.45)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.05),
      );
    }

    // Ojos grandes y algo asimétricos.
    final toMark = mark - c;
    final markDir = toMark / toMark.distance;
    final wander = Offset(
      math.sin(2 * math.pi * phase * 2) * 0.75,
      math.cos(2 * math.pi * phase) * 0.3,
    );
    final gaze = Offset.lerp(wander, markDir, _smooth(0.62, 0.68, phase))!;
    final blink = _blink(const [0.04, 0.86], phase);
    final lid = math.max(drowse, blink * (1 - surprise));
    final eyes = [
      (Offset(-r * 0.30, -r * 0.10), r * (0.27 + 0.06 * surprise)),
      (Offset(r * 0.30, -r * 0.14), r * (0.31 + 0.06 * surprise)),
    ];
    for (var i = 0; i < 2; i++) {
      final (at, e) = eyes[i];
      final side = i == 0 ? -1.0 : 1.0;
      _eye(canvas, at, e, gaze, lid, _skin(Offset.zero, r, VigiaBrand.coral));
      // Cejas: caen con el sueño y saltan con la sorpresa.
      final browAt =
          at + Offset(0, -e * 1.45 - r * 0.22 * surprise + r * 0.06 * drowse);
      canvas.save();
      canvas.translate(browAt.dx, browAt.dy);
      canvas.rotate(side * 0.38 * drowse - side * 0.18 * surprise);
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset.zero,
          width: e * 1.7,
          height: e * (0.7 + 0.4 * surprise),
        ),
        math.pi + 0.35,
        math.pi - 0.7,
        false,
        _stroke(r * 0.085),
      );
      canvas.restore();
    }

    _mouth(canvas, Offset(0, r * 0.40), r, drowse, surprise, happy);
    canvas.restore();

    // Marcas de sorpresa y «zz» fuera del cuerpo, sin la deformación.
    final head = Offset(c.dx, c.dy - jump * r * 0.45);
    if (surprise > 0.05) {
      for (final a in const [-1.25, -0.85, -0.45]) {
        final d = Offset(math.cos(a), math.sin(a));
        canvas.drawLine(
          head + d * r * (1.18 + 0.05 * surprise),
          head + d * r * (1.18 + 0.30 * surprise),
          _stroke(r * 0.07, line.withValues(alpha: surprise)),
        );
      }
    }
    if (drowse > 0.5) {
      for (var i = 0; i < 3; i++) {
        final t = (phase * 3 + i / 3) % 1;
        final z = TextPainter(
          text: TextSpan(
            text: 'z',
            style: VigiaType.heroTitle(r * (0.42 + 0.16 * i)).copyWith(
              color: line.withValues(alpha: ((drowse - 0.5) * 2) * (1 - t)),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        z.paint(
          canvas,
          head + Offset(r * (0.55 + 0.25 * i + 0.2 * t), -r * (1.25 + 0.7 * t)),
        );
      }
    }
  }

  void _eye(
    Canvas canvas,
    Offset at,
    double e,
    Offset gaze,
    double lid,
    Paint skin,
  ) {
    if (lid > 0.93) {
      canvas.drawArc(
        Rect.fromCenter(center: at, width: e * 1.9, height: e * 1.2),
        0.2,
        math.pi - 0.4,
        false,
        _stroke(e * 0.30),
      );
      return;
    }
    final rect = Rect.fromCircle(center: at, radius: e);
    canvas.drawCircle(
      at,
      e,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.4),
          colors: [Colors.white, Color(0xFFE9E6F2)],
        ).createShader(rect),
    );
    final pupil = e * 0.56;
    final pAt = at + gaze * (e - pupil) * 0.85;
    canvas.drawCircle(pAt, pupil, Paint()..color = _ink);
    canvas.drawCircle(
      pAt + Offset(-pupil * 0.38, -pupil * 0.38),
      pupil * 0.32,
      Paint()..color = Colors.white,
    );
    if (lid > 0.02) {
      // Párpado del color del cuerpo que baja. Su borde se curva hacia
      // abajo, como un párpado real, para que a medio cerrar no parezca
      // una mirada de reojo.
      final edge = at.dy - e + 2 * e * lid;
      final sag = e * 0.55 * math.sin(math.pi * lid.clamp(0.0, 1.0));
      final lidPath = Path()
        ..moveTo(rect.left - 2, rect.top - 2)
        ..lineTo(rect.left - 2, edge)
        ..quadraticBezierTo(at.dx, edge + sag, rect.right + 2, edge)
        ..lineTo(rect.right + 2, rect.top - 2)
        ..close();
      canvas.save();
      canvas.clipPath(Path()..addOval(rect.inflate(1.5)));
      canvas.drawPath(lidPath, skin);
      canvas.drawPath(
        Path()
          ..moveTo(rect.left, edge)
          ..quadraticBezierTo(at.dx, edge + sag, rect.right, edge),
        _stroke(e * 0.22),
      );
      canvas.restore();
    }
  }

  void _mouth(
    Canvas canvas,
    Offset at,
    double r,
    double drowse,
    double surprise,
    double happy,
  ) {
    final fill = Paint()..color = _ink;
    final tongue = Paint()..color = const Color(0xFFFF5470);
    if (surprise > 0.2) {
      final m = Rect.fromCenter(
        center: at + Offset(0, r * 0.04),
        width: r * (0.24 + 0.08 * surprise),
        height: r * (0.22 + 0.16 * surprise),
      );
      canvas.drawOval(m, fill);
      canvas.drawOval(
        Rect.fromCenter(
          center: m.bottomCenter - Offset(0, m.height * 0.22),
          width: m.width * 0.6,
          height: m.height * 0.32,
        ),
        tongue,
      );
    } else if (drowse > 0.4) {
      canvas.drawOval(
        Rect.fromCenter(center: at, width: r * 0.14, height: r * 0.12),
        fill,
      );
    } else if (happy > 0.4) {
      final m = Rect.fromCenter(
        center: at - Offset(0, r * 0.08),
        width: r * 0.52,
        height: r * 0.44,
      );
      canvas.drawArc(m, 0, math.pi, true, fill);
      canvas.save();
      canvas.clipPath(Path()..addArc(m, 0, math.pi));
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(m.center.dx + r * 0.05, m.bottom),
          width: m.width * 0.55,
          height: m.height * 0.55,
        ),
        tongue,
      );
      canvas.restore();
    } else {
      canvas.drawArc(
        Rect.fromCenter(
          center: at - Offset(0, r * 0.1),
          width: r * 0.46,
          height: r * 0.30,
        ),
        0.3,
        math.pi - 0.6,
        false,
        _stroke(r * 0.08),
      );
    }
  }

  void _speech(Canvas canvas, Offset mark, double u, double unit) {
    final s = _bubble(phase);
    if (s <= 0.01) return;
    final text = TextPainter(
      text: TextSpan(
        text: '¡Ojo!',
        style: VigiaType.heroTitle(unit * 0.085).copyWith(color: bubbleInk),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final pad = Offset(unit * 0.05, unit * 0.025);
    final box = Size(text.width + pad.dx * 2, text.height + pad.dy * 2);
    // Encima del símbolo, hacia el personaje, con la cola hacia el símbolo.
    final anchor = mark + Offset(u * 0.85, -u * 1.45);
    canvas.save();
    canvas.translate(anchor.dx, anchor.dy);
    canvas.rotate(0.06);
    canvas.scale(s);
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: box.width,
      height: box.height,
    );
    final fill = Paint()..color = bubbleFill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(box.height / 2)),
      fill,
    );
    canvas.drawPath(
      Path()
        ..moveTo(rect.left + box.width * 0.20, rect.bottom - 2)
        ..lineTo(rect.left + box.width * 0.06, rect.bottom + box.height * 0.45)
        ..lineTo(rect.left + box.width * 0.40, rect.bottom - 2)
        ..close(),
      fill,
    );
    text.paint(canvas, Offset(-text.width / 2, -text.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ScenePainter old) =>
      old.phase != phase ||
      old.enter != enter ||
      old.line != line ||
      old.bubbleFill != bubbleFill;
}
