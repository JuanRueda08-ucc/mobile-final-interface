import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Iconos lineales de B5.2 (constante `IC`): trazos SVG en una caja de 24×24,
/// grosor 1,75, extremos y uniones redondeados. Se reutilizan las rutas exactas.
enum VigiaIcon {
  arrow('M5 12h14M13 6l6 6-6 6'),
  home('M3 11l9-8 9 8M5 10v10h5v-6h4v6h5V10'),
  history('M3 12a9 9 0 1 0 3-6.7L3 8M3 3v5h5M12 7v5l3 2'),
  settings('M4 6h10M18 6h2M4 12h4M12 12h8M4 18h12M14 4v4M8 10v4M16 16v4'),
  warn('M12 3.5L2.5 20h19L12 3.5zM12 10v4.5M12 17.5v.5'),
  eyeOff(
    'M3 3l18 18M10.6 6.2A9.8 9.8 0 0 1 12 6c4 0 7 3 9 6-.8 1.3-1.8 2.5-3 3.5'
    'M6.5 7.6C4.9 8.8 3.7 10.3 3 12c2 3 5 6 9 6 1.3 0 2.5-.3 3.6-.8M9.9 9.9a3 3 0 0 0 4.2 4.2',
  ),
  info('M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM12 11v5M12 8v.5'),
  clock('M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM12 7v5l3 2'),
  check('M5 12.5l4.5 4.5L19 7.5'),
  close('M6 6l12 12M18 6L6 18'),
  refresh('M20 11a8 8 0 1 0-2.3 5.7M20 4v7h-7'),
  lock('M6 11h12v9H6zM8.5 11V8a3.5 3.5 0 0 1 7 0v3');

  const VigiaIcon(this.svgPath);

  final String svgPath;
}

/// Dibuja un [VigiaIcon] con el color de texto actual (como `currentColor`).
class VigiaIconView extends StatelessWidget {
  const VigiaIconView(
    this.icon, {
    super.key,
    this.size = 24,
    this.color,
    this.strokeWidth = 1.75,
  });

  final VigiaIcon icon;
  final double size;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final c =
        color ??
        DefaultTextStyle.of(context).style.color ??
        const Color(0xFF111111);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _SvgStrokePainter(_pathCache(icon), c, strokeWidth),
        ),
      ),
    );
  }
}

final Map<VigiaIcon, Path> _cache = {};
Path _pathCache(VigiaIcon icon) => _cache[icon] ??= parseSvgPath(icon.svgPath);

class _SvgStrokePainter extends CustomPainter {
  _SvgStrokePainter(this.path, this.color, this.strokeWidth);

  final Path path;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 24;
    canvas.scale(scale);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_SvgStrokePainter old) =>
      old.path != path || old.color != color || old.strokeWidth != strokeWidth;
}

/// Analizador mínimo de rutas SVG para los comandos usados por B5.2:
/// M, L, H, V, C, A y Z, absolutos y relativos (con repetición implícita).
Path parseSvgPath(String d) {
  final tokens = RegExp(
    r'[MmLlHhVvCcAaZz]|-?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?',
  ).allMatches(d).map((m) => m.group(0)!).toList();
  final path = Path();
  var i = 0;
  var cmd = '';
  var x = 0.0, y = 0.0, startX = 0.0, startY = 0.0;
  bool isCmd(String t) => RegExp(r'^[A-Za-z]$').hasMatch(t);
  double n() => double.parse(tokens[i++]);

  while (i < tokens.length) {
    if (isCmd(tokens[i])) {
      cmd = tokens[i++];
    } else if (cmd == 'M') {
      cmd = 'L'; // pares extra tras M son líneas
    } else if (cmd == 'm') {
      cmd = 'l';
    }
    final rel = cmd == cmd.toLowerCase();
    switch (cmd.toUpperCase()) {
      case 'M':
        x = (rel ? x : 0) + n();
        y = (rel ? y : 0) + n();
        path.moveTo(x, y);
        startX = x;
        startY = y;
      case 'L':
        x = (rel ? x : 0) + n();
        y = (rel ? y : 0) + n();
        path.lineTo(x, y);
      case 'H':
        x = (rel ? x : 0) + n();
        path.lineTo(x, y);
      case 'V':
        y = (rel ? y : 0) + n();
        path.lineTo(x, y);
      case 'C':
        final ox = rel ? x : 0.0, oy = rel ? y : 0.0;
        final x1 = ox + n(), y1 = oy + n(), x2 = ox + n(), y2 = oy + n();
        x = ox + n();
        y = oy + n();
        path.cubicTo(x1, y1, x2, y2, x, y);
      case 'A':
        final rx = n(), ry = n(), rot = n(), large = n() != 0, sweep = n() != 0;
        x = (rel ? x : 0) + n();
        y = (rel ? y : 0) + n();
        path.arcToPoint(
          Offset(x, y),
          radius: Radius.elliptical(rx, ry),
          rotation: rot * math.pi / 180,
          largeArc: large,
          clockwise: sweep,
        );
      case 'Z':
        path.close();
        x = startX;
        y = startY;
      default:
        throw FormatException('Comando SVG no admitido: $cmd');
    }
  }
  return path;
}
