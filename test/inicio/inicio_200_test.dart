import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia/core/design_system/hyphenation.dart';
import 'package:vigia/demo/inicio_demo.dart';
import 'package:vigia/features/inicio/inicio_state.dart';

import '../support/vigia_harness.dart';

final _letter = RegExp(r'[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]');

/// Cortes de línea de [p] que parten una palabra sin guion (letra|letra).
List<String> midWordBreaks(RenderParagraph p) {
  final text = p.text.toPlainText();
  // Mismo texto, estilo, escala y ancho que el párrafo dibujado: mismos cortes.
  final painter = TextPainter(
    text: p.text,
    textDirection: p.textDirection,
    textAlign: p.textAlign,
    textScaler: p.textScaler,
  )..layout(maxWidth: p.size.width + 0.01);
  final bad = <String>[];
  var offset = 0;
  while (offset < text.length) {
    final line = painter.getLineBoundary(TextPosition(offset: offset));
    final end = line.end;
    if (end <= offset) {
      offset++;
      continue;
    }
    if (end < text.length &&
        _letter.hasMatch(text[end - 1]) &&
        _letter.hasMatch(text[end])) {
      bad.add('${text.substring(line.start, end)}|${text.substring(end)}');
    }
    offset = end;
  }
  return bad;
}

/// Comprueba que cada guion añadido al final de una línea cae en una
/// frontera silábica de la palabra completa.
void expectSyllabicHyphens(RenderParagraph p) {
  final text = p.text.toPlainText();
  final lines = text.split('\n');
  for (var i = 0; i + 1 < lines.length; i++) {
    if (!lines[i].endsWith('-')) continue;
    final fragment = lines[i].split(' ').last.replaceAll('-', '');
    final rest = lines[i + 1].split(' ').first;
    final word = (fragment + rest).replaceAll(
      RegExp(r'[^\wÁÉÍÓÚÜÑáéíóúüñ]'),
      '',
    );
    expect(
      spanishHyphenationPoints(word),
      contains(fragment.length),
      reason: 'corte no silábico: $fragment-/$rest',
    );
  }
}

void main() {
  setUpAll(loadVigiaFonts);

  final states = <String, InicioState>{
    for (final v in InicioDemoVariant.values) v.id: v.state,
    'real_motor_no_comprobado': resolveRealState(),
  };

  for (final MapEntry(key: id, value: state) in states.entries) {
    for (final dark in [false, true]) {
      final c = ScreenConfig(width: 320, textScale: 2.0, dark: dark);
      testWidgets('200 % · $id · ${c.id}: sin palabras partidas y legible', (
        tester,
      ) async {
        await pumpVigia(tester, state, c);
        expect(tester.takeException(), isNull);

        final paragraphs = tester
            .renderObjectList<RenderParagraph>(find.byType(RichText))
            .toList();
        for (final p in paragraphs) {
          expect(midWordBreaks(p), isEmpty, reason: p.text.toPlainText());
          expectSyllabicHyphens(p);
          expect(p.didExceedMaxLines, isFalse);
        }

        // Cada texto de la pantalla puede leerse completo desplazando.
        final viewport = tester.getRect(find.byType(SingleChildScrollView));
        for (final t in tester.widgetList<Text>(
          find.descendant(
            of: find.byType(SingleChildScrollView),
            matching: find.byType(Text),
          ),
        )) {
          final f = find.byWidget(t);
          await tester.ensureVisible(f);
          await tester.pumpAndSettle();
          final r = tester.getRect(f);
          expect(
            r.top,
            greaterThanOrEqualTo(viewport.top - 0.5),
            reason: t.data,
          );
          expect(
            r.bottom,
            lessThanOrEqualTo(viewport.bottom + 0.5),
            reason: t.data,
          );
          expect(r.right, lessThanOrEqualTo(320.5), reason: t.data);
        }
      });
    }
  }

  testWidgets(
    'regresión: «Prepara tu sesión» no se corta como Prepa/ra o sesió/n',
    (tester) async {
      await pumpVigia(
        tester,
        InicioDemoVariant.sinHistorial.state,
        const ScreenConfig(width: 320, textScale: 2.0),
      );
      final title = paragraphFor(tester, 'Prepara tu sesión');
      expect(midWordBreaks(title), isEmpty);
      expectSyllabicHyphens(title);
      final shown = title.text.toPlainText();
      expect(shown, isNot(contains('sesió\n')));
      expect(shown.split('\n').last, 'sesión');
    },
  );

  testWidgets(
    'regresión: «Sesión interrumpida» no se corta como inte/rrumpida',
    (tester) async {
      await pumpVigia(
        tester,
        InicioDemoVariant.registroInterrumpido.state,
        const ScreenConfig(width: 320, textScale: 2.0),
      );
      final title = paragraphFor(tester, 'Sesión interrumpida');
      final shown = title.text.toPlainText();
      expect(midWordBreaks(title), isEmpty);
      expect(shown, isNot(contains('inte\nrrumpida')));
      // «interrumpida» no cabe entera a 200 %: un único corte silábico con guion.
      expect('-\n'.allMatches(shown).length, 1, reason: shown);
      expectSyllabicHyphens(title);
    },
  );
}

InicioState resolveRealState() => const InicioMotorNoComprobado();

/// Párrafo cuyo texto, sin los saltos y guiones añadidos, es [original].
RenderParagraph paragraphFor(WidgetTester tester, String original) {
  String undo(String s) => s.replaceAll('-\n', '').replaceAll('\n', ' ');
  return tester
      .renderObjectList<RenderParagraph>(find.byType(RichText))
      .singleWhere((p) => undo(p.text.toPlainText()) == original);
}
