import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/design_system/theme.dart';
import '../../../core/design_system/tokens.dart';
import '../../../core/design_system/widgets/vigia_mark.dart';

/// Ilustración de la bienvenida (P01). Es decorativa y no representa
/// ninguna medición.
///
/// Bucle de 7 s con dos protagonistas: el símbolo de Vigía, que parpadea
/// como un ojo, y un personaje coral. El personaje se adormece; el símbolo
/// parpadea, le envía una señal y dice «¡Ojo!»; el personaje despierta.
/// Con movimiento reducido se dibuja el instante final de esa historia
/// (personaje despierto y burbuja visible), sin animación.
class WelcomeEyes extends StatefulWidget {
  const WelcomeEyes({super.key});

  /// Fase fija del dibujo estático (movimiento reducido).
  static const stillPhase = 0.72;

  @override
  State<WelcomeEyes> createState() => _WelcomeEyesState();
}

/// Posiciones en fracciones del área (x del ancho, y del alto).
const _markAt = Offset(0.66, 0.38);
const _sleeperAt = Offset(0.27, 0.70);

// Línea de tiempo del bucle (fases 0–1).
const _markBlinks = [0.10, 0.47, 0.90];

double _smooth(double a, double b, double t) {
  final x = ((t - a) / (b - a)).clamp(0.0, 1.0);
  return x * x * (3 - 2 * x);
}

/// Cierre de un parpadeo (~0,25 s) que empieza en cada fase de [at].
double _blink(List<double> at, double t) {
  var k = 0.0;
  for (final b in at) {
    final d = (t - b) % 1;
    if (d < 0.036) k = math.max(k, math.sin(math.pi * d / 0.036));
  }
  return k;
}

/// Sueño del personaje: se adormece y despierta cuando llega la señal.
double _drowse(double t) =>
    _smooth(0.16, 0.42, t) * (1 - _smooth(0.62, 0.65, t));

/// Ondas de la señal del símbolo hacia el personaje.
double _signal(double t) => _smooth(0.50, 0.64, t);

double _bubble(double t) =>
    Curves.elasticOut.transform(_smooth(0.58, 0.70, t)) *
    (1 - _smooth(0.88, 0.94, t));

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
    final brandInk = dark ? VigiaBrand.wordmarkDark : VigiaBrand.wordmarkLight;
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            final unit = math.min(size.width, size.height * 0.9);
            final markSize = unit * 0.50;
            return AnimatedBuilder(
              animation: Listenable.merge([_loop, _enter]),
              builder: (context, _) {
                final t = _reduce ? WelcomeEyes.stillPhase : _loop.value;
                final enter = Curves.easeOutBack.transform(_enter.value);
                // El símbolo se inclina un poco hacia el personaje al avisar.
                final lean =
                    _smooth(0.44, 0.52, t) * (1 - _smooth(0.80, 0.9, t));
                final squash = 1 - 0.9 * _blink(_markBlinks, t);
                final float = math.sin(2 * math.pi * t) * unit * 0.012;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _ScenePainter(
                          phase: t,
                          enter: enter,
                          unit: unit,
                          markRadius: markSize / 2,
                          line: brandInk,
                          bubbleFill: dark
                              ? VigiaBrand.wordmarkDark
                              : VigiaBrand.ink,
                          bubbleInk: dark ? VigiaBrand.ink : Colors.white,
                        ),
                      ),
                    ),
                    Positioned(
                      left: _markAt.dx * size.width - markSize / 2,
                      top: _markAt.dy * size.height - markSize / 2 + float,
                      width: markSize,
                      height: markSize,
                      child: Opacity(
                        opacity: _enter.value,
                        child: Transform.rotate(
                          angle: -0.12 * lean,
                          child: Transform.scale(
                            scale: 0.6 + 0.4 * enter,
                            child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.diagonal3Values(1, squash, 1),
                              child: VigiaMark(size: markSize, ink: brandInk),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter({
    required this.phase,
    required this.enter,
    required this.unit,
    required this.markRadius,
    required this.line,
    required this.bubbleFill,
    required this.bubbleInk,
  });

  final double phase;
  final double enter;
  final double unit;
  final double markRadius;
  final Color line;
  final Color bubbleFill;
  final Color bubbleInk;

  @override
  void paint(Canvas canvas, Size size) {
    final mark = Offset(_markAt.dx * size.width, _markAt.dy * size.height);
    final bob = math.sin(2 * math.pi * (phase + 0.3)) * unit * 0.012;
    final sleeper = Offset(
      _sleeperAt.dx * size.width,
      _sleeperAt.dy * size.height + bob,
    );
    final r = unit * 0.17 * enter;

    _glow(canvas, mark);
    _waves(canvas, mark, sleeper, r);
    if (r > 0) {
      _body(canvas, sleeper, r);
      _face(canvas, sleeper, r, mark);
      _zz(canvas, sleeper, r);
    }
    _speech(canvas, mark);
  }

  /// Halo suave detrás del símbolo; crece mientras envía la señal.
  void _glow(Canvas canvas, Offset c) {
    final pulse = math.sin(math.pi * _signal(phase));
    final radius = markRadius * (1.05 + 0.25 * pulse) * enter;
    if (radius <= 0) return;
    canvas.drawCircle(
      c,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            VigiaBrand.lavender.withValues(alpha: 0.75),
            VigiaBrand.mistBlue.withValues(alpha: 0.35),
            VigiaBrand.mistBlue.withValues(alpha: 0),
          ],
          stops: const [0, 0.55, 1],
        ).createShader(Rect.fromCircle(center: c, radius: radius)),
    );
  }

  /// Tres ondas que viajan del símbolo al personaje.
  void _waves(Canvas canvas, Offset from, Offset to, double r) {
    final s = _signal(phase);
    if (s <= 0 || s >= 1) return;
    final dir = to - from;
    final angle = math.atan2(dir.dy, dir.dx);
    final reach = dir.distance - r * 0.9;
    for (var i = 0; i < 3; i++) {
      final k = (s * 1.6 - i * 0.3).clamp(0.0, 1.0);
      if (k <= 0 || k >= 1) continue;
      final radius = markRadius * 0.7 + (reach - markRadius * 0.7) * k;
      canvas.drawArc(
        Rect.fromCircle(center: from, radius: radius),
        angle - 0.42,
        0.84,
        false,
        Paint()
          ..color = VigiaBrand.coral.withValues(alpha: 0.9 * (1 - k))
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = math.max(2.5, unit * 0.014),
      );
    }
  }

  void _body(Canvas canvas, Offset c, double r) {
    const color = VigiaBrand.coral;
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
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
  }

  void _face(Canvas canvas, Offset c, double r, Offset mark) {
    final drowse = _drowse(phase);
    final woke = _smooth(0.62, 0.66, phase) * (1 - _smooth(0.80, 0.88, phase));
    final ink = Paint()
      ..color = VigiaBrand.ink
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(2, r * 0.07);

    // Mirada: pasea antes de dormirse y, al despertar, mira al símbolo.
    final toMark = mark - c;
    final markDir = toMark / toMark.distance;
    final wander = Offset(
      math.sin(2 * math.pi * phase * 2) * 0.6,
      math.cos(2 * math.pi * phase) * 0.2,
    );
    final gaze = Offset.lerp(wander, markDir, _smooth(0.6, 0.66, phase))!;

    final e = r * (0.21 + 0.05 * woke);
    final eyeY = c.dy - r * 0.12;
    final lid = math.max(drowse, 0.0);
    for (final side in [-1.0, 1.0]) {
      final ec = Offset(c.dx + side * r * 0.32, eyeY);
      if (lid > 0.88) {
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
      final at = gaze * (e - pupil) * 0.9;
      canvas.drawCircle(at, pupil, Paint()..color = VigiaBrand.ink);
      canvas.drawCircle(
        at + Offset(-pupil * 0.35, -pupil * 0.35),
        pupil * 0.28,
        Paint()..color = Colors.white,
      );
      canvas.restore();
    }

    final mouth = Offset(c.dx, c.dy + r * 0.32);
    if (drowse > 0.3 || woke > 0.2) {
      // Boca pequeña: dormido o sorprendido al despertar.
      canvas.drawOval(
        Rect.fromCenter(
          center: mouth,
          width: r * (0.16 + 0.08 * woke),
          height: r * (0.14 + 0.16 * woke),
        ),
        Paint()..color = VigiaBrand.ink,
      );
    } else {
      canvas.drawArc(
        Rect.fromCenter(
          center: mouth - Offset(0, r * 0.06),
          width: r * 0.5,
          height: r * 0.32,
        ),
        0.25,
        math.pi - 0.5,
        false,
        ink,
      );
    }
  }

  void _zz(Canvas canvas, Offset c, double r) {
    final drowse = _drowse(phase);
    if (drowse < 0.55) return;
    for (var i = 0; i < 2; i++) {
      final t = (phase * 3 + i * 0.5) % 1;
      final z = TextPainter(
        text: TextSpan(
          text: 'z',
          style: VigiaType.heroTitle(r * (0.55 + 0.25 * i)).copyWith(
            color: line.withValues(alpha: (drowse - 0.55) * 2.2 * (1 - t)),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      z.paint(
        canvas,
        c + Offset(r * (0.75 + 0.3 * i + 0.2 * t), -r * (1.1 + 0.6 * t)),
      );
    }
  }

  void _speech(Canvas canvas, Offset mark) {
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
    // A la izquierda del símbolo, con la cola hacia él.
    final anchor = mark + Offset(-markRadius * 1.25, -markRadius * 0.85);
    canvas.save();
    canvas.translate(anchor.dx, anchor.dy);
    canvas.rotate(-0.1);
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
        ..moveTo(rect.right - box.width * 0.42, rect.bottom - 2)
        ..lineTo(rect.right - box.width * 0.08, rect.bottom + box.height * 0.45)
        ..lineTo(rect.right - box.width * 0.20, rect.bottom - 2)
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
      old.unit != unit ||
      old.line != line ||
      old.bubbleFill != bubbleFill;
}
