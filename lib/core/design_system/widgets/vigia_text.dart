import 'package:flutter/widgets.dart';

import '../hyphenation.dart';

/// Texto de Vigía legible con cualquier escala de texto.
///
/// Mide su ancho real y reparte el texto con [breakLinesForWidth]: corta entre
/// palabras y, solo si una palabra no cabe sola, la parte por sílabas con
/// guion visible. No reduce la fuente ni la ajusta con FittedBox. Los lectores
/// de pantalla reciben el texto original, sin guiones ni saltos añadidos.
class VigiaText extends StatelessWidget {
  const VigiaText(this.text, {super.key, required this.style, this.textAlign});

  final String text;
  final TextStyle style;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final shown = breakLinesForWidth(
          text,
          style: DefaultTextStyle.of(context).style.merge(style),
          textScaler: MediaQuery.textScalerOf(context),
          maxWidth: box.maxWidth,
          textDirection: Directionality.of(context),
        );
        return Text(
          shown,
          style: style,
          textAlign: textAlign,
          semanticsLabel: shown == text ? null : text,
        );
      },
    );
  }
}

/// `true` con texto ampliado (≥ 150 %): se reorganizan márgenes y disposición
/// para ganar ancho, sin reducir el tamaño del texto.
bool isLargeText(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(16) / 16 >= 1.5;
