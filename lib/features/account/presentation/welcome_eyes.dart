import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/design_system/theme.dart';
import '../../../core/design_system/tokens.dart';

/// Ilustración de la bienvenida (P01): personajes con ojos en los pasteles
/// de Vigía. Es decorativa y no representa ninguna medición.
///
/// Bucle de 6 s: los personajes flotan, miran juntos y parpadean cada uno a
/// su ritmo. El pequeño se adormece, los demás lo miran, aparece «¡Ojo!» y
/// se despierta. Con movimiento reducido se dibuja el instante final de esa
/// historia (todos atentos y la burbuja visible), sin animación.
class WelcomeEyes extends StatefulWidget {
  const WelcomeEyes({super.key});

  /// Fase fija del dibujo estático (movimiento reducido).
  static const stillPhase = 0.72;

  @override
  State<WelcomeEyes> createState() => _WelcomeEyesState();
}

class _WelcomeEyesState extends State<WelcomeEyes>
    with TickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
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
            painter: _EyesPainter(
              phase: _reduce ? WelcomeEyes.stillPhase : _loop.value,
              enter: _enter.value,
              line: dark ? VigiaBrand.wordmarkDark : VigiaBrand.ink,
              bubbleFill: dark ? VigiaBrand.wordmarkDark : VigiaBrand.ink,
              bubbleInk: dark ? VigiaBrand.ink : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _Blob {
  const _Blob(
    this.color,
    this.x,
    this.y,
    this.r, {
    required this.blinks,
    this.mouth = _Mouth.smile,
    this.brow = false,
  });

  final Color color;

  /// Centro en fracciones del ancho (x) y del alto (y).
  final double x;
  final double y;

  /// Radio en fracciones de la dimensión de referencia.
  final double r;

  /// Fases del bucle en que parpadea.
  final List<double> blinks;
  final _Mouth mouth;
  final bool brow;
}

enum _Mouth { smile, open, small }

const _sleeper = 4;

const _blobs = [
  _Blob(
    VigiaBrand.lavender,
    0.80,
    0.24,
    0.25,
    blinks: [0.12, 0.47],
    mouth: _Mouth.open,
    brow: true,
  ),
  _Blob(VigiaBrand.softGreen, 0.10, 0.22, 0.21, blinks: [0.30, 0.90]),
  _Blob(
    VigiaBrand.mistBlue,
    0.20,
    0.74,
    0.27,
    blinks: [0.05, 0.40],
    brow: true,
  ),
  _Blob(VigiaBrand.orange, 0.86, 0.76, 0.22, blinks: [0.22, 0.97]),
  _Blob(VigiaBrand.coral, 0.52, 0.57, 0.12, blinks: [], mouth: _Mouth.small),
];

class _EyesPainter extends CustomPainter {
  _EyesPainter({
    required this.phase,
    required this.enter,
    required this.line,
    required this.bubbleFill,
    required this.bubbleInk,
  });

  final double phase;
  final double enter;
  final Color line;
  final Color bubbleFill;
  final Color bubbleInk;

  static double _smooth(double a, double b, double t) {
    final x = ((t - a) / (b - a)).clamp(0.0, 1.0);
    return x * x * (3 - 2 * x);
  }

  /// Cierre del párpado (0 abierto, 1 cerrado) en un parpadeo de ~0,2 s.
  static double _blink(List<double> at, double t) {
    var k = 0.0;
    for (final b in at) {
      final d = (t - b) % 1;
      if (d < 0.035) k = math.max(k, math.sin(math.pi * d / 0.035));
    }
    return k;
  }

  /// Sueño del personaje pequeño: se adormece y despierta con «¡Ojo!».
  double get _drowse =>
      _smooth(0.22, 0.48, phase) * (1 - _smooth(0.58, 0.62, phase));

  /// Atención de los demás hacia el que se duerme.
  double get _attention =>
      _smooth(0.42, 0.52, phase) * (1 - _smooth(0.86, 0.96, phase));

  double get _bubble =>
      Curves.elasticOut.transform(_smooth(0.54, 0.66, phase)) *
      (1 - _smooth(0.86, 0.92, phase));

  @override
  void paint(Canvas canvas, Size size) {
    final unit = math.min(size.width, size.height * 0.85);
    final sleeper = _blobs[_sleeper];
    final sleeperCenter = Offset(
      sleeper.x * size.width,
      sleeper.y * size.height,
    );

    _strokes(canvas, size, unit);

    for (var i = 0; i < _blobs.length; i++) {
      final b = _blobs[i];
      final grow = Curves.easeOutBack.transform(
        ((enter - 0.12 * i) / 0.55).clamp(0.0, 1.0),
      );
      if (grow <= 0) continue;
      final bob = math.sin(2 * math.pi * (phase + i * 0.21)) * 0.012;
      final c = Offset(b.x * size.width, (b.y + bob) * size.height);
      final r = b.r * unit * grow;
      _body(canvas, c, r, b.color);

      // Mirada: un recorrido común y, durante el aviso, hacia el pequeño.
      var gaze = Offset(
        math.sin(2 * math.pi * phase) * 0.7,
        math.cos(4 * math.pi * phase) * 0.25,
      );
      if (i != _sleeper) {
        final to = sleeperCenter - c;
        final dir = to / (to.distance == 0 ? 1 : to.distance);
        gaze = Offset.lerp(gaze, dir, _attention)!;
      }
      final lid = i == _sleeper
          ? math.max(_drowse, 0.0)
          : _blink(b.blinks, phase);
      _face(canvas, c, r, b, gaze, lid, awake: i == _sleeper);
    }

    // «zz» del que se duerme.
    if (_drowse > 0.55) {
      final t = (phase * 3) % 1;
      final z = TextPainter(
        text: TextSpan(
          text: 'z',
          style: TextStyle(
            fontSize: sleeper.r * unit * 0.9,
            fontWeight: FontWeight.w700,
            color: line.withValues(alpha: (_drowse - 0.55) * 2.2 * (1 - t)),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      z.paint(
        canvas,
        sleeperCenter +
            Offset(sleeper.r * unit * 0.9, -sleeper.r * unit * (1.2 + t)),
      );
    }

    _speech(canvas, size, unit);
  }

  void _body(Canvas canvas, Offset c, double r, Color color) {
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c + Offset(0, r * 0.08),
      r,
      Paint()
        ..color = color.withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.18),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 1.05,
          colors: [
            Color.lerp(color, Colors.white, 0.55)!,
            color,
            Color.lerp(color, VigiaBrand.ink, 0.10)!,
          ],
          stops: const [0, 0.55, 1],
        ).createShader(rect),
    );
  }

  void _face(
    Canvas canvas,
    Offset c,
    double r,
    _Blob b,
    Offset gaze,
    double lid, {
    required bool awake,
  }) {
    final ink = Paint()
      ..color = VigiaBrand.ink
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(2, r * 0.07);
    final e = r * 0.21;
    final eyeY = c.dy - r * 0.12;
    for (final side in [-1.0, 1.0]) {
      final ec = Offset(c.dx + side * r * 0.32 + gaze.dx * r * 0.08, eyeY);
      if (lid > 0.88) {
        // Ojo cerrado: curva hacia abajo.
        canvas.drawArc(
          Rect.fromCenter(center: ec, width: e * 1.8, height: e * 1.1),
          0.15,
          math.pi - 0.3,
          false,
          ink,
        );
        continue;
      }
      canvas.save();
      canvas.translate(ec.dx, ec.dy);
      canvas.scale(1, 1 - lid);
      canvas.drawCircle(Offset.zero, e, Paint()..color = Colors.white);
      final pupil = e * 0.56;
      canvas.drawCircle(
        Offset(gaze.dx, gaze.dy) * (e - pupil) * 0.9,
        pupil,
        Paint()..color = VigiaBrand.ink,
      );
      canvas.drawCircle(
        Offset(gaze.dx, gaze.dy) * (e - pupil) * 0.9 +
            Offset(-pupil * 0.35, -pupil * 0.35),
        pupil * 0.28,
        Paint()..color = Colors.white,
      );
      canvas.restore();
    }

    if (b.brow) {
      final lift = _attention * r * 0.08;
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(c.dx - r * 0.32, eyeY - e * 1.5 - lift),
          width: e * 2.2,
          height: e * 1.2,
        ),
        math.pi + 0.35,
        math.pi - 0.7,
        false,
        ink,
      );
    }

    final mouthY = c.dy + r * 0.32;
    switch (awake && _drowse > 0.3 ? _Mouth.small : b.mouth) {
      case _Mouth.smile:
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(c.dx, mouthY - r * 0.06),
            width: r * 0.5,
            height: r * 0.32,
          ),
          0.25,
          math.pi - 0.5,
          false,
          ink,
        );
      case _Mouth.open:
        final m = Rect.fromCenter(
          center: Offset(c.dx, mouthY),
          width: r * 0.42,
          height: r * (0.18 + 0.12 * _attention),
        );
        canvas.drawArc(m, 0, math.pi, true, Paint()..color = VigiaBrand.ink);
        canvas.drawArc(
          Rect.fromCenter(
            center: m.bottomCenter - Offset(0, m.height * 0.25),
            width: m.width * 0.5,
            height: m.height * 0.5,
          ),
          math.pi,
          math.pi,
          true,
          Paint()..color = VigiaBrand.coral,
        );
      case _Mouth.small:
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(c.dx, mouthY),
            width: r * 0.18,
            height: r * (0.18 + 0.1 * (1 - _drowse)),
          ),
          Paint()..color = VigiaBrand.ink,
        );
    }
  }

  /// Trazos a mano: un bucle que une a los personajes.
  void _strokes(Canvas canvas, Size size, double unit) {
    final w = size.width;
    final h = size.height;
    final reveal = _smooth(0.3, 1, enter);
    if (reveal <= 0) return;
    final path = Path()
      ..moveTo(0.30 * w, 0.40 * h)
      ..cubicTo(0.36 * w, 0.30 * h, 0.44 * w, 0.24 * h, 0.47 * w, 0.30 * h)
      ..cubicTo(0.50 * w, 0.36 * h, 0.40 * w, 0.40 * h, 0.42 * w, 0.32 * h)
      ..cubicTo(0.45 * w, 0.20 * h, 0.58 * w, 0.12 * h, 0.66 * w, 0.16 * h);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * reveal),
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(1.5, unit * 0.006),
    );
  }

  void _speech(Canvas canvas, Size size, double unit) {
    final s = _bubble;
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
    final anchor = Offset(0.56 * size.width, 0.40 * size.height);
    canvas.save();
    canvas.translate(anchor.dx, anchor.dy);
    canvas.rotate(-0.12);
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
        ..moveTo(rect.left + box.width * 0.22, rect.bottom - 2)
        ..lineTo(rect.left + box.width * 0.12, rect.bottom + box.height * 0.4)
        ..lineTo(rect.left + box.width * 0.40, rect.bottom - 2)
        ..close(),
      fill,
    );
    text.paint(canvas, Offset(-text.width / 2, -text.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_EyesPainter old) =>
      old.phase != phase ||
      old.enter != enter ||
      old.line != line ||
      old.bubbleFill != bubbleFill;
}
