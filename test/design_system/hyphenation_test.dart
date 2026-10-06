import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia/core/design_system/hyphenation.dart';
import 'package:vigia/core/design_system/theme.dart';

import '../support/vigia_harness.dart';

String syllables(String w) {
  final p = spanishHyphenationPoints(w);
  final out = StringBuffer();
  var prev = 0;
  for (final i in p) {
    out
      ..write(w.substring(prev, i))
      ..write('-');
    prev = i;
  }
  out.write(w.substring(prev));
  return out.toString();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('separación silábica del español', () {
    test('palabras de la interfaz', () {
      // Sin fragmentos de una letra a un lado del guion (mo-ni-to-reo, no -o).
      expect(syllables('Prepara'), 'Pre-pa-ra');
      expect(syllables('sesión'), 'se-sión'); // diptongo «ió»
      expect(syllables('interrumpida'), 'in-te-rrum-pi-da'); // dígrafo rr
      expect(syllables('confirmado'), 'con-fir-ma-do');
      expect(syllables('Desconocido'), 'Des-co-no-ci-do');
      expect(syllables('monitoreo'), 'mo-ni-to-reo');
      expect(syllables('reapertura'), 're-a-per-tu-ra');
      expect(syllables('construir'), 'cons-truir'); // grupo «tr» inseparable
      expect(syllables('Consultando'), 'Con-sul-tan-do');
      expect(syllables('días'), 'dí-as'); // hiato con í
    });
  });

  group('reparto de líneas', () {
    setUpAll(loadVigiaFonts);

    final style = VigiaType.heroTitle(40);
    const x2 = TextScaler.linear(2);

    test('si cada palabra cabe sola, el texto queda intacto', () {
      expect(
        breakLinesForWidth(
          'Prepara tu sesión',
          style: style,
          textScaler: TextScaler.noScaling,
          maxWidth: 240,
        ),
        'Prepara tu sesión',
      );
    });

    test('una palabra que no cabe se parte por sílaba con guion visible', () {
      // Al 200 % «Prepara» (80 px) no cabe en 200 px.
      final out = breakLinesForWidth(
        'Prepara tu sesión',
        style: style,
        textScaler: x2,
        maxWidth: 200,
      );
      final lines = out.split('\n');
      expect(lines.first, endsWith('-'));
      expect(
        out.replaceAll('-\n', '').replaceAll('\n', ' '),
        'Prepara tu sesión',
      );
      // Cada corte cae en una frontera silábica de la palabra (Pre-, Prepa-).
      for (final l in lines.where((l) => l.endsWith('-'))) {
        final fragment = l.split(' ').last.replaceAll('-', '');
        final word = [
          'Prepara',
          'sesión',
        ].firstWhere((w) => w.startsWith(fragment));
        expect(spanishHyphenationPoints(word), contains(fragment.length));
      }
    });
  });
}
