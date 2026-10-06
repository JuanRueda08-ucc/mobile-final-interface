import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia/app/inicio_source.dart';
import 'package:vigia/core/design_system/theme.dart';
import 'package:vigia/core/design_system/widgets/aura_hero.dart';

import '../support/contrast.dart';
import '../support/vigia_harness.dart';

/// Regresiones del comprobador de contraste (test/support/contrast.dart),
/// a partir de los casos reproducidos en la revisión de la fase 1.
void main() {
  setUpAll(loadVigiaFonts);

  double ratio(Color a, Color b) {
    final la = a.computeLuminance(), lb = b.computeLuminance();
    return (math.max(la, lb) + .05) / (math.min(la, lb) + .05);
  }

  Future<void> fixture(WidgetTester t, Widget body) async {
    t.view.devicePixelRatio = 2;
    t.view.physicalSize = const Size(720, 1600);
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Align(alignment: Alignment.topLeft, child: body),
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  Text simple(String s, Color c) => Text(
    s,
    style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: c, height: 1.45),
  );

  group('controles uniformes', () {
    for (final fg in const [
      Color(0xffbbbbbb),
      Color(0xff888888),
      Color(0xff000000),
    ]) {
      testWidgets('texto ${fg.toARGB32().toRadixString(16)} sobre blanco', (
        t,
      ) async {
        await fixture(
          t,
          SizedBox(
            width: 320,
            child: simple('Texto uniforme de contraste', fg),
          ),
        );
        final out = await textContrastFailures(t);
        if (ratio(fg, Colors.white) < 4.5) {
          expect(out, hasLength(1));
          expect(out.single, isNot(startsWith('SIN EVALUAR')));
        } else {
          expect(out, isEmpty);
        }
      });
    }
  });

  testWidgets('un tramo de 1,16:1 no se compensa con otro tramo correcto', (
    t,
  ) async {
    const bad = Color(0xffeeeeee);
    expect(ratio(bad, Colors.white), closeTo(1.16, 0.01));
    await fixture(
      t,
      const SizedBox(
        width: 320,
        child: Text.rich(
          TextSpan(
            style: TextStyle(fontFamily: 'Inter', fontSize: 14, height: 1.45),
            children: [
              TextSpan(
                text: 'Texto negro correcto muy frecuente\n',
                style: TextStyle(color: Colors.black),
              ),
              TextSpan(
                text: 'Texto de contraste insuficiente',
                style: TextStyle(color: bad),
              ),
            ],
          ),
        ),
      ),
    );
    final out = await textContrastFailures(t);
    expect(out, hasLength(1));
    expect(out.single, startsWith('«Texto de contraste insuficiente»: 1.1'));
  });

  testWidgets('sobre fondo variable se usa el fondo bajo los glifos (1,92:1)', (
    t,
  ) async {
    const bad = Color(0xffbbbbbb);
    expect(ratio(bad, Colors.white), closeTo(1.92, 0.01));
    await fixture(
      t,
      SizedBox(
        width: 320,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.white, Colors.black, Colors.black],
              stops: [0, .75, .751, 1],
            ),
          ),
          child: simple('Texto claro sobre fondo variable', bad),
        ),
      ),
    );
    final out = await textContrastFailures(t);
    expect(out, hasLength(1));
    // 1,9196:1, presentado truncado a centésimas.
    expect(out.single, contains('1.91:1'));
    expect(out.single, contains('texto #BBBBBB, fondo #FFFFFF'));
  });

  testWidgets('aura blanco/negro: se conserva el mínimo local cercano a 1:1', (
    t,
  ) async {
    t.view.devicePixelRatio = 2;
    t.view.physicalSize = const Size(720, 1600);
    addTearDown(t.view.reset);
    t.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(t.platformDispatcher.clearAllTestValues);
    const body =
        'Texto secundario sobre el fondo del aura con varias líneas para '
        'medir el contraste efectivo local.';
    await t.pumpWidget(
      MaterialApp(
        theme: vigiaLightTheme,
        home: const Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 320,
              child: AuraHero(
                title: 'Título',
                text: body,
                c0: Colors.white,
                c1: Colors.black,
                minHeight: 230,
              ),
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    final audit = ContrastAudit();
    await audit.measure(t);
    final bodyFailure = audit.failures.where((f) => f.startsWith('«Texto'));
    expect(bodyFailure, hasLength(1), reason: audit.log());
    final worst = double.parse(
      RegExp(r': ([\d.]+):1').firstMatch(bodyFailure.single)!.group(1)!,
    );
    expect(worst, lessThan(1.2), reason: bodyFailure.single);
    expect(audit.unevaluated, isEmpty, reason: audit.log());
  });

  testWidgets(
    'falso positivo de Flutter: el estado real a 360 cumple con la medición propia',
    (t) async {
      final handle = t.ensureSemantics();
      await pumpVigia(t, resolveInicioState(), const ScreenConfig(width: 360));
      final guideline = await textContrastGuideline.evaluate(t);
      final audit = await auditTextContrast(t);
      handle.dispose();
      // La pauta de Flutter falla por el suavizado; la medición por píxel, no.
      expect(guideline.passed, isFalse);
      expect(audit.problems, isEmpty, reason: audit.log());
    },
  );

  testWidgets('el par #595954 / #FBFAF7 aislado cumple (6,75:1)', (t) async {
    await fixture(
      t,
      ColoredBox(
        color: const Color(0xfffbfaf7),
        child: SizedBox(
          width: 320,
          child: simple(
            'No disponible hasta comprobar el estado del motor.',
            const Color(0xff595954),
          ),
        ),
      ),
    );
    expect(await textContrastFailures(t), isEmpty);
  });

  group('contenido fuera del viewport inicial', () {
    testWidgets(
      'un párrafo insuficiente bajo el viewport se detecta al desplazar',
      (t) async {
        await fixture(
          t,
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                simple('Texto visible correcto', Colors.black),
                const SizedBox(height: 1000),
                simple(
                  'Texto oculto de contraste insuficiente',
                  const Color(0xffbbbbbb),
                ),
              ],
            ),
          ),
        );
        // Sin desplazar no se aprueba: queda expresamente sin evaluar.
        final before = await textContrastFailures(t);
        expect(before, hasLength(1));
        expect(before.single, startsWith('SIN EVALUAR «Texto oculto'));
        expect(before.single, contains('fuera de la zona visible'));

        final audit = await auditTextContrast(t);
        expect(audit.unevaluated, isEmpty, reason: audit.log());
        expect(audit.failures, hasLength(1));
        expect(audit.failures.single, startsWith('«Texto oculto de contraste'));
      },
    );

    testWidgets(
      'un párrafo cortado por el borde se evalúa entero al desplazar',
      (t) async {
        // Párrafo a caballo del borde inferior: su última línea, insuficiente,
        // empieza fuera de la vista.
        await fixture(
          t,
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 760),
                SizedBox(
                  width: 320,
                  child: Text.rich(
                    const TextSpan(
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        height: 1.45,
                      ),
                      children: [
                        TextSpan(
                          text: 'Primera línea correcta\nSegunda línea correcta\n',
                          style: TextStyle(color: Colors.black),
                        ),
                        TextSpan(
                          text: 'Última línea insuficiente',
                          style: TextStyle(color: Color(0xffcccccc)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 600),
              ],
            ),
          ),
        );
        final p = t.renderObject<RenderParagraph>(find.byType(RichText).last);
        final first = ContrastAudit();
        await first.measure(t);
        expect(first.isFullyEvaluated(p), isFalse);
        expect(first.failures, isEmpty);

        final audit = await auditTextContrast(t);
        expect(audit.isFullyEvaluated(p), isTrue, reason: audit.log());
        expect(
          audit.failures.single,
          startsWith('«Última línea insuficiente»'),
        );
      },
    );
  });

  testWidgets(
    'texto translúcido: una variación real de pocos niveles no se aprueba por '
    'tolerancia (4,48:1)',
    (t) async {
      // Reproducción independiente de la revisión de 03b4bb2: la tolerancia de
      // tres niveles hacia la mediana devolvía OK con 4,51:1.
      const bg = Color(0xfff95afd), stroke = Color(0xff3a2288);
      expect(ratio(stroke, bg), closeTo(4.4828, 0.0001));
      await fixture(
        t,
        SizedBox(
          width: 200,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xfffe57f8), Color(0xfffe57f8), bg, bg],
                stops: [0, .8, .801, 1],
              ),
            ),
            child: Text(
              'MMMMMMMMMM',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                height: 1.45,
                color: const Color(0xff191873).withValues(alpha: .85),
              ),
            ),
          ),
        ),
      );
      // Comprobación independiente sobre la captura: hay interiores de glifo
      // #3A2288 sobre #F95AFD.
      final (data, width) = (await t.runAsync(() async {
        final image = await captureImage(
          find.byType(MaterialApp).evaluate().single,
        );
        final d = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
        final w = image.width;
        image.dispose();
        return (d, w);
      }))!;
      var interior = 0;
      for (var y = 0; y < 70; y++) {
        for (var x = 330; x < 365; x++) {
          final i = (y * width + x) * 4;
          if (data.getUint8(i) == 0x3a &&
              data.getUint8(i + 1) == 0x22 &&
              data.getUint8(i + 2) == 0x88) {
            interior++;
          }
        }
      }
      expect(interior, greaterThan(100));

      final audit = ContrastAudit();
      await audit.measure(t);
      expect(audit.unevaluated, isEmpty, reason: audit.log());
      expect(audit.failures, hasLength(1), reason: audit.log());
      final worst = double.parse(
        RegExp(r': ([\d.]+):1').firstMatch(audit.failures.single)!.group(1)!,
      );
      expect(worst, lessThan(4.5), reason: audit.failures.single);
      expect(audit.failures.single, contains('fondo #F95AFD'));
    },
  );

  group('regiones no evaluables se informan', () {
    testWidgets('texto tapado por otra capa queda sin evaluar', (t) async {
      await fixture(
        t,
        SizedBox(
          width: 320,
          height: 40,
          child: Stack(
            children: [
              simple('Texto tapado', Colors.black),
              const Positioned.fill(child: ColoredBox(color: Colors.white)),
            ],
          ),
        ),
      );
      final out = await textContrastFailures(t);
      expect(out, hasLength(1));
      expect(out.single, startsWith('SIN EVALUAR «Texto tapado»'));
      expect(out.single, contains('tapados'));
    });

    testWidgets('texto con pintura `foreground` queda sin evaluar', (t) async {
      await fixture(
        t,
        Text(
          'Texto con pintura',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            foreground: Paint()..color = Colors.black,
          ),
        ),
      );
      final out = await textContrastFailures(t);
      expect(out.single, startsWith('SIN EVALUAR «Texto con pintura»'));
      expect(out.single, contains('foreground'));
    });
  });
}
