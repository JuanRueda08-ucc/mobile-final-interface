import 'package:flutter/painting.dart';

/// Separación silábica del español para partir palabras largas con guion
/// visible cuando el texto ampliado (p. ej. 200 %) no cabe.
///
/// Reglas (Ortografía de la RAE, simplificadas para el texto de la app):
/// - una consonante entre vocales va con la vocal siguiente (ca-sa);
/// - dos consonantes se separan (ar-co), salvo los grupos inseparables
///   pl, pr, bl, br, cl, cr, dr, tr, fl, fr, gl, gr, kl, kr y los dígrafos ch,
///   ll y rr, que van con la vocal siguiente (re-tra-so, in-te-rrum-pir);
/// - tres consonantes: VC-CCV si las dos últimas son inseparables; si no, VCC-CV;
/// - cuatro consonantes: VCC-CCV;
/// - diptongo (vocal débil átona i/u/ü junto a otra vocal) no se separa;
///   hiato (dos vocales fuertes, o débil acentuada í/ú) sí (mo-ni-to-re-o).
/// Además no se dejan fragmentos de una sola letra a un lado del guion.
List<int> spanishHyphenationPoints(String word) {
  final lower = word.toLowerCase();
  final n = lower.length;
  bool isVowel(int i) => _vowels.contains(lower[i]);
  bool isStrong(int i) => _strong.contains(lower[i]);

  // Núcleos vocálicos: [inicio, fin) de cada grupo de vocales que forma sílaba.
  final nuclei = <List<int>>[];
  var i = 0;
  while (i < n) {
    if (!isVowel(i)) {
      i++;
      continue;
    }
    var start = i;
    i++;
    while (i < n && isVowel(i)) {
      // Hiato: dos fuertes, o una débil acentuada junto a otra vocal.
      final hiatus =
          (isStrong(i - 1) && isStrong(i)) ||
          _accentedWeak.contains(lower[i - 1]) ||
          _accentedWeak.contains(lower[i]);
      if (hiatus) {
        nuclei.add([start, i]);
        start = i;
      }
      i++;
    }
    nuclei.add([start, i]);
  }

  final points = <int>[];
  for (var k = 0; k + 1 < nuclei.length; k++) {
    final cStart = nuclei[k][1], cEnd = nuclei[k + 1][0];
    final cluster = lower.substring(cStart, cEnd);
    int split;
    switch (cluster.length) {
      case 0:
        split = cStart; // hiato
      case 1:
        split = cStart; // V-CV
      case 2:
        split = _inseparable.contains(cluster) ? cStart : cStart + 1;
      case 3:
        split = _inseparable.contains(cluster.substring(1))
            ? cStart + 1
            : cStart + 2;
      default:
        split = cStart + 2;
    }
    if (split >= 2 && n - split >= 2) points.add(split);
  }
  return points;
}

const _vowels = 'aeiouáéíóúü';
const _strong = 'aeoáéóíú';
const _accentedWeak = 'íú';
const _inseparable = {
  'pl',
  'pr',
  'bl',
  'br',
  'cl',
  'cr',
  'dr',
  'tr',
  'fl',
  'fr',
  'gl',
  'gr',
  'kl',
  'kr', //
  'ch', 'll', 'rr',
};

final _letter = RegExp(r'[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]');

/// Divide [text] en líneas que caben en [maxWidth] con el [style] y la escala
/// indicados, sin reducir la fuente:
/// 1. corta entre palabras siempre que es posible;
/// 2. solo si una palabra no cabe sola en una línea, la parte por una frontera
///    silábica y añade un guion visible.
/// Devuelve el texto con saltos `\n` explícitos. Si alguna sílaba no cabe ni
/// sola, ese fragmento se deja para el ajuste normal del motor de texto.
String breakLinesForWidth(
  String text, {
  required TextStyle style,
  required TextScaler textScaler,
  required double maxWidth,
  TextDirection textDirection = TextDirection.ltr,
}) {
  if (!maxWidth.isFinite || text.isEmpty) return text;
  final painter = TextPainter(
    textDirection: textDirection,
    textScaler: textScaler,
    maxLines: 1,
  );
  bool fits(String s) {
    painter.text = TextSpan(text: s, style: style);
    painter.layout();
    return painter.width <= maxWidth;
  }

  final words = text.split(' ').where((w) => w.isNotEmpty).toList();
  // Si cada palabra cabe sola en una línea, el ajuste normal ya corta entre
  // palabras: se devuelve el texto intacto (sin saltos ni guiones añadidos).
  if (words.every(fits)) return text;
  final lines = <String>[];
  var current = '';
  String joined(String a, String b) => a.isEmpty ? b : '$a $b';

  for (final word in words) {
    if (fits(joined(current, word))) {
      current = joined(current, word);
      continue;
    }
    if (current.isNotEmpty && fits(word)) {
      lines.add(current);
      current = word;
      continue;
    }
    // La palabra no cabe sola: separación silábica con guion visible.
    var rest = word;
    while (true) {
      final cut = _bestCut(rest, current, fits);
      if (cut != null) {
        lines.add('${joined(current, rest.substring(0, cut))}-');
        current = '';
        rest = rest.substring(cut);
        if (fits(rest)) {
          current = rest;
          break;
        }
        continue;
      }
      if (current.isNotEmpty) {
        lines.add(current); // probar el corte en una línea nueva
        current = '';
        continue;
      }
      current =
          rest; // sin corte silábico posible: lo resuelve el motor de texto
      break;
    }
  }
  if (current.isNotEmpty) lines.add(current);
  return lines.join('\n');
}

/// Corte silábico más largo de [word] que cabe con guion detrás de [current].
int? _bestCut(String word, String current, bool Function(String) fits) {
  // Solo la parte alfabética inicial se separa; la puntuación final queda unida.
  var end = word.length;
  while (end > 0 && !_letter.hasMatch(word[end - 1])) {
    end--;
  }
  final core = word.substring(0, end);
  final points = spanishHyphenationPoints(core).reversed;
  for (final p in points) {
    final prefix =
        '${current.isEmpty ? '' : '$current '}${word.substring(0, p)}-';
    if (fits(prefix)) return p;
  }
  return null;
}
