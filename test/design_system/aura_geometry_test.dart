import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia/core/design_system/theme.dart';
import 'package:vigia/core/design_system/widgets/aura_hero.dart';

/// Geometría del aura de B5.2 (`HERO`): en CSS los porcentajes de `top`/`bottom`
/// se refieren a la ALTURA h del contenedor; `left`/`right`/`width`, a su ancho w.
void main() {
  group('AuraGeometry (280 × 758)', () {
    const size = Size(280, 758);
    final g = AuraGeometry.of(size);

    test('l1: left −12 % w, top −28 % h, ancho 78 % w', () {
      expect(g.l1.left, closeTo(-0.12 * 280, 1e-9)); // −33,6
      expect(
        g.l1.top,
        closeTo(-0.28 * 758, 1e-9),
      ); // −212,24 (no −28 % del diámetro)
      expect(g.l1.width, closeTo(0.78 * 280, 1e-9));
      expect(g.l1.height, closeTo(0.78 * 280, 1e-9)); // aspect-ratio 1
    });

    test('l2: right −18 % w, top −8 % h, ancho 62 % w', () {
      expect(g.l2.right, closeTo(280 + 0.18 * 280, 1e-9));
      expect(g.l2.top, closeTo(-0.08 * 758, 1e-9)); // −60,64
      expect(g.l2.width, closeTo(0.62 * 280, 1e-9));
    });

    test('core: left 50 % − 62, bottom 6 % h, 124 × 108', () {
      expect(g.core.left, closeTo(140 - 62, 1e-9));
      expect(g.core.bottom, closeTo(758 - 0.06 * 758, 1e-9));
      expect(g.core.size, const Size(124, 108));
    });
  });

  testWidgets(
    'el aura montada de 280 × 758 coloca las manchas con la altura h',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(400, 1000);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: vigiaLightTheme,
          home: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 280,
              child: AuraHero(title: 'Título', text: 'Texto', minHeight: 758),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(AuraHero)), const Size(280, 758));

      final tops = tester
          .widgetList<Positioned>(
            find.descendant(
              of: find.byType(AuraHero),
              matching: find.byType(Positioned),
            ),
          )
          .map((p) => p.top)
          .whereType<double>()
          .toList();
      expect(tops, contains(closeTo(-0.28 * 758, 1e-6)));
      expect(tops, contains(closeTo(-0.08 * 758, 1e-6)));
      expect(tops, contains(closeTo(758 - 0.06 * 758 - 108, 1e-6)));
      // Con movimiento reducido el aura sigue sin animarse.
      expect(tester.hasRunningAnimations, isFalse);
    },
  );
}
