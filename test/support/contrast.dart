import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contraste de texto medido sobre los píxeles realmente dibujados, por tramo
/// de estilo y contra el fondo efectivo situado bajo cada glifo.
///
/// Por qué no se usa `textContrastGuideline` de Flutter: elige como «color del
/// texto» un tono de suavizado del borde de las letras. En el estado real de
/// Inicio (texto `#595954` sobre `#FBFAF7`, 6,75:1) informó 3,19:1 con
/// `#8D8D88`. Un histograma global del párrafo tampoco sirve: puede escoger un
/// color favorable y ocultar un tramo o una zona de fondo desfavorables.
///
/// Método, en cada posición medida:
/// 1. Se capturan cuatro imágenes de la pantalla cambiando solo el color de los
///    párrafos: original, texto transparente (fondo efectivo de cada píxel),
///    texto negro y texto blanco (cobertura de glifo realmente visible).
/// 2. Cada párrafo se vuelve a dibujar aislado, con el mismo diseño y la misma
///    posición subpíxel, para conocer la cobertura esperada `e` de sus glifos.
/// 3. Para cada palabra de cada tramo ([TextSpan] con texto), en los píxeles de
///    trazo (`e ≥ 0,5`), el color efectivo del texto es el dibujado en los
///    píxeles interiores del glifo y `fondo + (dibujado − fondo) / e` en los de
///    borde (deshace el suavizado). Se compara con el fondo de ese mismo píxel,
///    sin tolerancia ni color típico, y se conserva el peor valor sin redondear;
///    el redondeo solo se aplica al presentarlo.
/// 4. Umbral WCAG 2.x: 4,5:1, o 3:1 para texto grande (≥ 24 px, o ≥ 18,66 px en
///    negrita), según el estilo resuelto del tramo.
///
/// Una palabra solo cuenta como evaluada si está entera dentro de la zona
/// visible (pantalla y ventanas de desplazamiento), su diseño aislado coincide
/// con el dibujado y sus glifos no están tapados ni recortados. Si no, queda
/// «sin evaluar» con el motivo, y [ContrastAudit.problems] la informa.
class ContrastAudit {
  final _spans = <(RenderParagraph, int), _SpanRecord>{};
  final _positions = <String>[];

  /// Tramos con contraste por debajo del mínimo.
  List<String> get failures => [
    for (final s in _spans.values)
      if (s.worst + 1e-9 < s.minimum)
        '«${s.text}»: ${_shown(s.worst)}:1 '
            '(texto ${_hex(s.worstFg)}, fondo ${_hex(s.worstBg)}, '
            'mínimo ${s.minimum})',
  ];

  /// Tramos con alguna palabra que no se pudo evaluar de forma fiable.
  List<String> get unevaluated => [
    for (final s in _spans.values)
      if (s.missing.isNotEmpty)
        'SIN EVALUAR «${s.text}»: ${s.missing.map((i) => '«${s.words[i].text}» '
            '(${s.reasons[i] ?? 'no medida'})').join(', ')}',
  ];

  /// Fallos y regiones sin evaluar: ninguno de los dos se da por aprobado.
  List<String> get problems => [...failures, ...unevaluated];

  /// `true` si todas las palabras de todos los tramos de [p] se evaluaron.
  bool isFullyEvaluated(RenderParagraph p) {
    final spans = _spans.entries.where((e) => identical(e.key.$1, p));
    return spans.isNotEmpty && spans.every((e) => e.value.missing.isEmpty);
  }

  /// Registro de cobertura legible: cada tramo, su resultado y lo no evaluado.
  String log() {
    final b = StringBuffer()
      ..writeln('posiciones medidas (${_positions.length}):')
      ..writeAll([
        for (var i = 0; i < _positions.length; i++) '  #$i ${_positions[i]}\n',
      ])
      ..writeln('tramos: ${_spans.length}');
    for (final s in _spans.values) {
      final status = s.missing.isNotEmpty
          ? 'SIN EVALUAR'
          : (s.worst + 1e-9 < s.minimum ? 'FALLA' : 'OK');
      b.writeln(
        '[$status] «${s.text.replaceAll('\n', '⏎')}» '
        'palabras ${s.words.length - s.missing.length}/${s.words.length}, '
        'píxeles de trazo ${s.samples} (excluidos ${s.excluded}), '
        'peor ${s.worst.isFinite ? '${_shown(s.worst)}:1' : '—'} '
        '(texto ${_hex(s.worstFg)}, fondo ${_hex(s.worstBg)}), '
        'mínimo ${s.minimum}',
      );
      for (final MapEntry(key: pos, value: r) in s.regions.entries) {
        b.writeln('    región evaluada en #$pos: ${_rect(r)}');
      }
      for (final i in s.missing) {
        b.writeln(
          '    sin evaluar «${s.words[i].text}»: ${s.reasons[i] ?? 'no medida'}',
        );
      }
    }
    return b.toString();
  }

  /// Mide la pantalla en su posición actual y acumula el resultado.
  /// [label] describe la posición en el registro de cobertura.
  Future<void> measure(WidgetTester tester, {String label = 'actual'}) async {
    _positions.add(label);
    final position = _positions.length - 1;
    final dpr = tester.view.devicePixelRatio;
    final screen = Offset.zero & (tester.view.physicalSize / dpr);
    final paragraphs = tester
        .renderObjectList<RenderParagraph>(find.byType(RichText))
        .where((p) => p.attached)
        .toList();

    // Registro de tramos y párrafos que se pueden recolorear.
    final measurable = <RenderParagraph, Offset>{};
    final originals = <RenderParagraph, InlineSpan>{};
    for (final p in paragraphs) {
      final spans = _register(p);
      String? problem;
      final origin = p.hasSize
          ? MatrixUtils.getAsTranslation(p.getTransformTo(null))
          : null;
      if (!p.hasSize || p.size.isEmpty) {
        problem = 'párrafo sin tamaño';
      } else if (origin == null) {
        problem = 'transformación no traslacional (giro o escala)';
      } else if (_hasForegroundPaint(p.text)) {
        problem = 'el estilo usa `foreground` (pintura o sombreado)';
      }
      if (problem != null) {
        for (final s in spans) {
          s.markAll(problem);
        }
        continue;
      }
      measurable[p] = origin!;
      originals[p] = p.text;
    }

    Future<(Uint8List, int)> capture() async {
      await tester.pump();
      return (await tester.runAsync(() async {
        final element = find.byType(MaterialApp).evaluate().single;
        final image = await captureImage(element);
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        final width = image.width;
        image.dispose();
        return (data!.buffer.asUint8List(), width);
      }))!;
    }

    void recolor(Color? color) {
      for (final p in measurable.keys) {
        p.text = color == null
            ? originals[p]!
            : _recolored(originals[p]!, color);
      }
    }

    final (painted, width) = await capture();
    recolor(Colors.transparent);
    final (background, _) = await capture();
    recolor(const Color(0xFF000000));
    final (black, _) = await capture();
    recolor(const Color(0xFFFFFFFF));
    final (white, _) = await capture();
    recolor(null);
    await tester.pump();

    final px = _Pixels(painted, background, black, white, width);
    for (final MapEntry(key: p, value: origin) in measurable.entries) {
      final clip = _visibleRect(p, screen);
      // Skia ajusta la cobertura de los glifos según la luminancia del color,
      // así que cada máscara se compara con su propio dibujo aislado.
      final (iso, isoBlack, isoWhite) = (await tester.runAsync(
        () async => (
          await _Isolated.render(p, _opaque(originals[p]!), origin, dpr),
          await _Isolated.render(
            p,
            _recolored(originals[p]!, const Color(0xFF000000)),
            origin,
            dpr,
          ),
          await _Isolated.render(
            p,
            _recolored(originals[p]!, const Color(0xFFFFFFFF)),
            origin,
            dpr,
          ),
        ),
      ))!;
      for (final s in _register(p)) {
        // Se mide en cada posición en que la palabra esté entera a la vista
        // y se conserva el peor valor; el motivo se guarda mientras falte.
        for (var i = 0; i < s.words.length; i++) {
          final reason = _measureWord(
            s,
            i,
            p,
            origin,
            clip,
            (iso, isoBlack, isoWhite),
            px,
            dpr,
            position,
          );
          if (reason == null) {
            s.missing.remove(i);
            s.reasons.remove(i);
          } else if (s.missing.contains(i)) {
            s.reasons[i] = reason;
          }
        }
      }
      iso.dispose();
      isoBlack.dispose();
      isoWhite.dispose();
    }
  }

  List<_SpanRecord> _register(RenderParagraph p) {
    final out = <_SpanRecord>[];
    var index = 0;
    var offset = 0;
    void walk(InlineSpan span, TextStyle inherited) {
      if (span is TextSpan) {
        final style = span.style == null
            ? inherited
            : inherited.merge(span.style);
        final text = span.text;
        if (text != null && text.isNotEmpty) {
          final words = [
            for (final m in RegExp(r'\S+').allMatches(text))
              _Word(m.group(0)!, offset + m.start, offset + m.end),
          ];
          if (words.isNotEmpty) {
            final size = p.textScaler.scale(style.fontSize ?? 14);
            final bold = (style.fontWeight?.value ?? 400) >= 700;
            final large = size >= 24 || (bold && size >= 18.66);
            out.add(
              _spans.putIfAbsent((
                p,
                index,
              ), () => _SpanRecord(text, words, large ? 3.0 : 4.5)),
            );
          }
          index++;
          offset += text.length;
        }
        for (final c in span.children ?? const <InlineSpan>[]) {
          walk(c, style);
        }
      } else {
        offset += 1; // PlaceholderSpan: un carácter de sustitución.
      }
    }

    walk(p.text, const TextStyle());
    return out;
  }

  /// Devuelve `null` si la palabra quedó evaluada, o el motivo si no.
  String? _measureWord(
    _SpanRecord s,
    int i,
    RenderParagraph p,
    Offset origin,
    Rect clip,
    (_Isolated, _Isolated, _Isolated) isolated,
    _Pixels px,
    double dpr,
    int position,
  ) {
    final (iso, isoBlack, isoWhite) = isolated;
    final w = s.words[i];
    final sel = TextSelection(baseOffset: w.start, extentOffset: w.end);
    final boxes = [
      for (final b in p.getBoxesForSelection(sel))
        if (b.right - b.left > 0.01) b.toRect(),
    ];
    if (boxes.isEmpty) return 'sin caja de texto';
    final isoBoxes = [
      for (final b in iso.painter.getBoxesForSelection(sel))
        if (b.right - b.left > 0.01) b.toRect(),
    ];
    if (isoBoxes.length != boxes.length ||
        [
          for (var k = 0; k < boxes.length; k++)
            (boxes[k].topLeft - isoBoxes[k].topLeft).distance +
                (boxes[k].bottomRight - isoBoxes[k].bottomRight).distance,
        ].any((d) => d > 0.5)) {
      return 'el diseño aislado no coincide con el dibujado';
    }
    for (final b in boxes) {
      final g = b.shift(origin);
      if (g.left < clip.left - 0.01 ||
          g.top < clip.top - 0.01 ||
          g.right > clip.right + 0.01 ||
          g.bottom > clip.bottom + 0.01) {
        return 'fuera de la zona visible';
      }
    }

    var worst = double.infinity;
    var worstFg = 0, worstBg = 0;
    final visibility = <double>[];
    final samples = <(int, int, double?)>[];
    for (final b in boxes) {
      final g = b.shift(origin);
      for (var y = (g.top * dpr).floor(); y < (g.bottom * dpr).ceil(); y++) {
        for (var x = (g.left * dpr).floor(); x < (g.right * dpr).ceil(); x++) {
          final e = iso.coverage(x, y);
          if (e < 0.5) continue;
          // Visibilidad: cobertura en pantalla frente a la esperada con la
          // misma máscara (negra o blanca).
          final (k, useBlack) = px.visibleCoverage(x, y);
          final expected = (useBlack ? isoBlack : isoWhite).coverage(x, y);
          final v = expected >= 0.1 ? k / expected : null;
          if (v != null) visibility.add(v);
          samples.add((x, y, v));
        }
      }
    }
    if (samples.isEmpty || visibility.isEmpty) return 'sin píxeles de trazo';
    final sorted = [...visibility]..sort();
    final opacity = sorted[sorted.length ~/ 2];
    if (opacity < 0.02) return 'glifos tapados o invisibles';
    final hidden = visibility.where((v) => v < 0.5 * opacity).length;
    if (hidden > 0.02 * visibility.length) {
      return 'glifos tapados o recortados en parte ($hidden de ${visibility.length} píxeles)';
    }
    // Color efectivo del texto en cada píxel de trazo visible, sin tolerancia
    // ni sustitución por un color típico:
    // - en los píxeles interiores del glifo (cobertura completa) el color
    //   dibujado es el color efectivo exacto, sin extrapolar;
    // - en los de borde se deshace el suavizado,
    //   `fondo + (dibujado − fondo) / e`, con la cobertura aislada corregida
    //   por la visibilidad medida en ese píxel.
    // Con el mismo fondo, el color efectivo es el mismo (también si el texto
    // es translúcido), así que los fondos con píxeles interiores se evalúan
    // con su medición exacta; los demás, con cada valor de borde. Los píxeles
    // tolerados como tapados (≤ 2 %) se excluyen y se cuentan en el registro.
    final interior = <int, List<int>>{}; // fondo → colores dibujados exactos
    final edge = <int, List<int>>{}; // fondo → colores extrapolados
    var used = 0;
    for (final (x, y, v) in samples) {
      final r = v == null ? 1.0 : v / opacity;
      if (r < 0.5) continue;
      used++;
      final bg = px.background(x, y);
      final e = iso.coverage(x, y) * r;
      if (e >= _interiorCoverage) {
        (interior[bg] ??= []).add(px.paintedAt(x, y));
      } else {
        (edge[bg] ??= []).add(px.effectiveText(x, y, e.clamp(0.25, 1.0)));
      }
    }
    s.excluded += samples.length - used;
    void consider(int fg, int bg) {
      final r = _ratio(fg, bg);
      if (r < worst) {
        worst = r;
        worstFg = fg;
        worstBg = bg;
      }
    }

    for (final MapEntry(key: bg, value: fgs) in interior.entries) {
      for (final fg in fgs) {
        consider(fg, bg);
      }
    }
    for (final MapEntry(key: bg, value: fgs) in edge.entries) {
      if (interior.containsKey(bg)) continue;
      for (final fg in fgs) {
        consider(fg, bg);
      }
    }
    s.samples += used;
    final region = boxes
        .map((b) => b.shift(origin))
        .reduce((a, b) => a.expandToInclude(b));
    s.regions[position] =
        s.regions[position]?.expandToInclude(region) ?? region;
    if (worst < s.worst) {
      s.worst = worst;
      s.worstFg = worstFg;
      s.worstBg = worstBg;
    }
    return null;
  }
}

/// Recorre todo el contenido desplazable y mide el contraste en cada posición.
///
/// Cada [Scrollable] con contenido fuera de la vista se recorre de principio a
/// fin en pasos de media ventana, de modo que cada línea de altura ≤ media
/// ventana queda entera a la vista en alguna posición. Al terminar vuelve a la
/// posición inicial.
Future<ContrastAudit> auditTextContrast(WidgetTester tester) async {
  final audit = ContrastAudit();
  await audit.measure(tester, label: 'inicial');
  for (final state in tester.stateList<ScrollableState>(
    find.byType(Scrollable),
  )) {
    final pos = state.position;
    if (!pos.hasContentDimensions ||
        pos.maxScrollExtent <= pos.minScrollExtent) {
      continue;
    }
    final start = pos.pixels;
    final step = pos.viewportDimension / 2;
    final offsets = <double>{
      for (var o = pos.minScrollExtent; o < pos.maxScrollExtent; o += step) o,
      pos.maxScrollExtent,
    };
    for (final o in offsets) {
      if ((o - start).abs() < 0.01) continue; // ya medida
      pos.jumpTo(o);
      await tester.pump();
      await audit.measure(
        tester,
        label:
            '${state.widget.runtimeType} desplazado ${o.toStringAsFixed(1)} '
            'de ${pos.maxScrollExtent.toStringAsFixed(1)}',
      );
    }
    pos.jumpTo(start);
    await tester.pump();
  }
  return audit;
}

/// Medición de la posición actual, sin desplazar: fallos y regiones sin evaluar.
Future<List<String>> textContrastFailures(WidgetTester tester) async {
  final audit = ContrastAudit();
  await audit.measure(tester);
  return audit.problems;
}

/// Cobertura a partir de la cual un píxel es interior del glifo: su color
/// dibujado es el color efectivo del texto, sin suavizado que deshacer.
const _interiorCoverage = 0.99;

class _Word {
  _Word(this.text, this.start, this.end);
  final String text;
  final int start;
  final int end;
}

class _SpanRecord {
  _SpanRecord(this.text, this.words, this.minimum)
    : missing = {for (var i = 0; i < words.length; i++) i};

  final String text;
  final List<_Word> words;
  final double minimum;
  final Set<int> missing;
  final reasons = <int, String>{};
  double worst = double.infinity;
  int worstFg = 0;
  int worstBg = 0;
  int samples = 0;

  /// Píxeles de trazo tolerados como tapados y excluidos de la medición.
  int excluded = 0;

  /// Región de pantalla evaluada (coordenadas lógicas) en cada posición.
  final regions = <int, Rect>{};

  void markAll(String reason) {
    for (final i in missing) {
      reasons[i] = reason;
    }
  }
}

class _Pixels {
  _Pixels(this.painted, this.bg, this.black, this.white, this.width);
  final Uint8List painted, bg, black, white;
  final int width;

  int _rgb(Uint8List d, int x, int y) {
    final i = (y * width + x) * 4;
    if (x < 0 || x >= width || i < 0 || i + 3 >= d.length) return 0;
    return (d[i] << 16) | (d[i + 1] << 8) | d[i + 2];
  }

  int background(int x, int y) => _rgb(bg, x, y);

  int paintedAt(int x, int y) => _rgb(painted, x, y);

  /// Cobertura del glifo visible en pantalla (0 = tapado), con la máscara
  /// negra o blanca que más se aleja del fondo en ese píxel; indica cuál usó.
  (double, bool) visibleCoverage(int x, int y) {
    final b = _rgb(bg, x, y), k = _rgb(black, x, y), w = _rgb(white, x, y);
    var best = 0.0, cov = 0.0, useBlack = true;
    for (final sh in const [16, 8, 0]) {
      final bc = (b >> sh) & 255, kc = (k >> sh) & 255, wc = (w >> sh) & 255;
      if (bc > best) {
        best = bc.toDouble();
        cov = (bc - kc) / bc;
        useBlack = true;
      }
      if (255 - bc > best) {
        best = (255 - bc).toDouble();
        cov = (wc - bc) / (255 - bc);
        useBlack = false;
      }
    }
    return (cov.clamp(0.0, 1.0), useBlack);
  }

  /// Color efectivo del texto con cobertura completa: deshace el suavizado.
  int effectiveText(int x, int y, double e) {
    final b = _rgb(bg, x, y), d = _rgb(painted, x, y);
    var out = 0;
    for (final sh in const [16, 8, 0]) {
      final bc = (b >> sh) & 255, dc = (d >> sh) & 255;
      final v = (bc + (dc - bc) / e).round().clamp(0, 255);
      out |= v << sh;
    }
    return out;
  }
}

/// Párrafo dibujado aislado sobre transparente, en la misma posición subpíxel:
/// con colores opacos, su alfa es la cobertura esperada de cada glifo.
class _Isolated {
  _Isolated(this.painter, this._alpha, this._x0, this._y0, this._w, this._h);

  final TextPainter painter;
  final Uint8List _alpha;
  final int _x0, _y0, _w, _h;

  double coverage(int x, int y) {
    final lx = x - _x0, ly = y - _y0;
    if (lx < 0 || ly < 0 || lx >= _w || ly >= _h) return 0;
    return _alpha[(ly * _w + lx) * 4 + 3] / 255;
  }

  void dispose() => painter.dispose();

  static Future<_Isolated> render(
    RenderParagraph p,
    InlineSpan text,
    Offset origin,
    double dpr,
  ) async {
    final widthMatters = p.softWrap || p.overflow == TextOverflow.ellipsis;
    final painter =
        TextPainter(
          text: text,
          textAlign: p.textAlign,
          textDirection: p.textDirection,
          textScaler: p.textScaler,
          maxLines: p.maxLines,
          ellipsis: p.overflow == TextOverflow.ellipsis ? '…' : null,
          locale: p.locale,
          strutStyle: p.strutStyle,
          textWidthBasis: p.textWidthBasis,
          textHeightBehavior: p.textHeightBehavior,
        )..layout(
          minWidth: p.constraints.minWidth,
          maxWidth: widthMatters ? p.constraints.maxWidth : double.infinity,
        );
    final x0 = (origin.dx * dpr).floor() - 2,
        y0 = (origin.dy * dpr).floor() - 2;
    final w = (p.size.width * dpr).ceil() + 6,
        h = (p.size.height * dpr).ceil() + 6;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..translate(-x0.toDouble(), -y0.toDouble())
      ..scale(dpr);
    painter.paint(canvas, origin);
    final picture = recorder.endRecording();
    final image = await picture.toImage(w, h);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    picture.dispose();
    return _Isolated(painter, data!.buffer.asUint8List(), x0, y0, w, h);
  }
}

/// Zona visible del párrafo: pantalla ∩ ventanas de desplazamiento antecesoras.
Rect _visibleRect(RenderObject o, Rect screen) {
  var clip = screen;
  for (RenderObject? n = o.parent; n != null; n = n.parent) {
    if (n is RenderViewportBase) {
      clip = clip.intersect(
        MatrixUtils.transformRect(n.getTransformTo(null), Offset.zero & n.size),
      );
    }
  }
  return clip;
}

bool _hasForegroundPaint(InlineSpan span) {
  var found = false;
  span.visitChildren((s) {
    if (s is TextSpan && s.style?.foreground != null) found = true;
    return !found;
  });
  return found;
}

/// Mismos colores con alfa 1: el alfa del dibujo aislado es entonces la
/// cobertura del glifo para ese color.
InlineSpan _opaque(
  InlineSpan span, [
  Color inherited = const Color(0xFF000000),
]) {
  if (span is! TextSpan) return span;
  final color = (span.style?.color ?? inherited).withAlpha(255);
  return TextSpan(
    text: span.text,
    style: (span.style ?? const TextStyle()).copyWith(color: color),
    children: span.children?.map((c) => _opaque(c, color)).toList(),
    locale: span.locale,
    spellOut: span.spellOut,
  );
}

InlineSpan _recolored(InlineSpan span, Color color) {
  if (span is! TextSpan) return span;
  return TextSpan(
    text: span.text,
    style: (span.style ?? const TextStyle()).copyWith(
      color: color,
      decorationColor: span.style?.decorationColor == null ? null : color,
    ),
    children: span.children?.map((c) => _recolored(c, color)).toList(),
    recognizer: span.recognizer,
    mouseCursor: span.mouseCursor,
    onEnter: span.onEnter,
    onExit: span.onExit,
    semanticsLabel: span.semanticsLabel,
    locale: span.locale,
    spellOut: span.spellOut,
  );
}

double _lum(int rgb) {
  double c(int v) {
    final s = v / 255;
    return s <= 0.03928
        ? s / 12.92
        : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * c((rgb >> 16) & 255) +
      0.7152 * c((rgb >> 8) & 255) +
      0.0722 * c(rgb & 255);
}

double _ratio(int a, int b) {
  final la = _lum(a), lb = _lum(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// Presentación del contraste truncada a centésimas (la decisión ya se tomó
/// con el valor exacto): un valor que falla nunca se muestra igual al mínimo.
String _shown(double ratio) => ((ratio * 100).floor() / 100).toStringAsFixed(2);

String _hex(int rgb) =>
    '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';

String _rect(Rect r) =>
    '(${r.left.toStringAsFixed(1)}, ${r.top.toStringAsFixed(1)}) – '
    '(${r.right.toStringAsFixed(1)}, ${r.bottom.toStringAsFixed(1)})';
