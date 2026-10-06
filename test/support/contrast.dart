import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contraste de texto medido sobre los píxeles realmente dibujados.
///
/// Por qué existe: `textContrastGuideline` de Flutter elige como «color del
/// texto» un tono de suavizado del borde de las letras. En el estado real de
/// Inicio (texto `#595954` sobre `#FBFAF7`, contraste WCAG 6,75:1) informó
/// 3,19:1 usando `#8D8D88`: 376 píxeles de suavizado frente a 2582 del color
/// real. Esta medición, para cada párrafo visible:
/// - toma como fondo el color dominante de su rectángulo;
/// - toma como texto el color sólido más frecuente con contraste ≥ 1,5 frente
///   al fondo (descarta los tonos de suavizado, intermedios y escasos);
/// - exige ≥ 4,5:1, o ≥ 3:1 para texto grande (≥ 24 px, o ≥ 18,66 px en
///   negrita), como WCAG 2.x.
Future<List<String>> textContrastFailures(WidgetTester tester) async {
  final element = find.byType(MaterialApp).evaluate().single;
  final dpr = tester.view.devicePixelRatio;
  final screen = Offset.zero & (tester.view.physicalSize / dpr);
  final bytes = (await tester.runAsync(() async {
    final image = await captureImage(element);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final width = image.width;
    image.dispose();
    return (data!, width);
  }))!;
  final (ByteData rgba, int width) = bytes;

  final failures = <String>[];
  for (final p in tester.renderObjectList<RenderParagraph>(
    find.byType(RichText),
  )) {
    if (!p.attached || !p.hasSize || p.size.isEmpty) continue;
    final rect = MatrixUtils.transformRect(
      p.getTransformTo(null),
      Offset.zero & p.size,
    );
    // Solo párrafos completamente visibles (no desplazados fuera de pantalla).
    if (!screen.contains(rect.topLeft) ||
        !screen.contains(rect.bottomRight - const Offset(0.01, 0.01))) {
      continue;
    }
    final scroll = _viewportRectOf(p);
    if (scroll != null &&
        !(rect.top >= scroll.top - 0.5 && rect.bottom <= scroll.bottom + 0.5)) {
      continue;
    }
    final counts = <int, int>{};
    for (
      var y = (rect.top * dpr).floor();
      y < (rect.bottom * dpr).ceil();
      y++
    ) {
      for (
        var x = (rect.left * dpr).floor();
        x < (rect.right * dpr).ceil();
        x++
      ) {
        final i = (y * width + x) * 4;
        if (i < 0 || i + 3 >= rgba.lengthInBytes) continue;
        final rgb =
            (rgba.getUint8(i) << 16) |
            (rgba.getUint8(i + 1) << 8) |
            rgba.getUint8(i + 2);
        counts[rgb] = (counts[rgb] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) continue;
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final bg = sorted.first.key;
    final fgEntry = sorted
        .skip(1)
        .firstWhere(
          (e) => _ratio(bg, e.key) >= 1.5,
          orElse: () => sorted.first,
        );
    final ratio = _ratio(bg, fgEntry.key);
    final style = p.text.style;
    final size = p.textScaler.scale(style?.fontSize ?? 14);
    final bold = (style?.fontWeight?.value ?? 400) >= 700;
    final large = size >= 24 || (bold && size >= 18.66);
    final min = large ? 3.0 : 4.5;
    if (ratio + 1e-9 < min) {
      failures.add(
        '«${p.text.toPlainText()}»: ${ratio.toStringAsFixed(2)}:1 '
        '(texto ${_hex(fgEntry.key)}, fondo ${_hex(bg)}, mínimo $min)',
      );
    }
  }
  return failures;
}

Rect? _viewportRectOf(RenderObject o) {
  RenderObject? n = o.parent;
  while (n != null) {
    if (n is RenderViewportBase) {
      return MatrixUtils.transformRect(
        n.getTransformTo(null),
        Offset.zero & n.size,
      );
    }
    n = n.parent;
  }
  return null;
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

String _hex(int rgb) =>
    '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
