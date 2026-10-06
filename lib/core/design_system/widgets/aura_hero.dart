import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../theme.dart';
import '../tokens.dart';
import 'vigia_button.dart';

/// Bloque principal con aura pastel (`HERO` de B5.2).
///
/// Composición de B5.2:
/// - fondo `linear-gradient(165deg, c0 0%, c0 40%, c1 100%)`;
/// - dos manchas difuminadas (`l1`, `l2`);
/// - un núcleo blanco con forma orgánica (`core`).
///
/// Animaciones `vgA1`, `vgA2` y `vgC`: 6 s, ease-in-out, una sola iteración que
/// vuelve a la posición inicial. Con movimiento reducido
/// (`MediaQuery.disableAnimations`) el aura queda estática, sin animación.
/// El aura es decorativa: no representa medición ni estado del motor.
class AuraHero extends StatefulWidget {
  const AuraHero({
    super.key,
    required this.title,
    required this.text,
    this.tag,
    this.ctaLabel,
    this.onCta,
    this.titleSize = 40,
    this.minHeight = 230,
    this.c0 = VigiaAura.lilac,
    this.c1 = VigiaAura.lime,
  });

  final String title;
  final String text;
  final String? tag;
  final String? ctaLabel;
  final VoidCallback? onCta;
  final double titleSize;
  final double minHeight;
  final Color c0;
  final Color c1;

  @override
  State<AuraHero> createState() => _AuraHeroState();
}

class _AuraHeroState extends State<AuraHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: VigiaMotion.auraDuration,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce) {
      _c.stop();
      _c.value = 0;
    } else if (!_started) {
      _started = true;
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final angle = 165 * math.pi / 180;
    final dir = Alignment(math.sin(angle), -math.cos(angle));
    return ClipRRect(
      borderRadius: BorderRadius.circular(VigiaRadius.hero),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: -dir,
            end: dir,
            colors: [widget.c0, widget.c0, widget.c1],
            stops: const [0, 0.4, 1],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ExcludeSemantics(
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (context, _) => _AuraBlobs(
                    phase: reduce ? 0 : _keyframe(_c.value),
                    c0: widget.c0,
                    c1: widget.c1,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(VigiaSpace.heroPadding),
              child: _HeroLayout(
                // Altura mínima del bloque menos el relleno superior e inferior.
                minHeight: widget.minHeight - 2 * VigiaSpace.heroPadding,
                gap: 16,
                body: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.tag != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: VigiaAura.ctaBg,
                          borderRadius: BorderRadius.circular(VigiaRadius.tag),
                        ),
                        child: Text(
                          widget.tag!,
                          style: VigiaType.pill.copyWith(
                            color: VigiaAura.ctaInk,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Semantics(
                      header: true,
                      child: Text(
                        widget.title,
                        style: VigiaType.heroTitle(widget.titleSize)
                            .copyWith(color: VigiaAura.onAura),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 270),
                      child: Text(
                        widget.text,
                        style: VigiaType.body.copyWith(
                          color: VigiaAura.onAuraSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                cta: widget.ctaLabel == null
                    ? null
                    : VigiaButton(
                        label: widget.ctaLabel!,
                        onPressed: widget.onCta,
                        kind: VigiaButtonKind.onAura,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Fotogramas clave 0 % → 50 % → 100 % con ease-in-out en cada tramo (como CSS):
  /// devuelve 0 en los extremos y 1 a mitad de la animación.
  static double _keyframe(double t) {
    final curve = VigiaMotion.auraCurve;
    return t <= 0.5 ? curve.transform(t / 0.5) : curve.transform((1 - t) / 0.5);
  }
}

/// Manchas del aura posicionadas en proporción al bloque, como en B5.2.
class _AuraBlobs extends StatelessWidget {
  const _AuraBlobs({required this.phase, required this.c0, required this.c1});

  /// 0 = posición inicial; 1 = fotograma 50 %.
  final double phase;
  final Color c0;
  final Color c1;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth, h = box.maxHeight;
        final d1 = 0.78 * w, d2 = 0.62 * w;
        double lerp(double a, double b) => a + (b - a) * phase;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // l1 · vgA1: translate(12 %, 6 %) scale(1,04) a mitad de ciclo.
            Positioned(
              left: -0.12 * w,
              top: -0.28 * d1,
              width: d1,
              height: d1,
              child: Transform.translate(
                offset: Offset(lerp(0, 0.12 * d1), lerp(0, 0.06 * d1)),
                child: Transform.scale(
                  scale: lerp(1, 1.04),
                  child: _Blob(color: c0, blur: 10),
                ),
              ),
            ),
            // l2 · vgA2: translate(−10 %, 8 %).
            Positioned(
              right: -0.18 * w,
              top: -0.08 * d2,
              width: d2,
              height: d2,
              child: Transform.translate(
                offset: Offset(lerp(0, -0.10 * d2), lerp(0, 0.08 * d2)),
                child: _Blob(color: c1, blur: 10),
              ),
            ),
            // core · vgC: escala 0,96 → 1,04, desplazamiento (3 %, −4 %) y forma orgánica.
            Positioned(
              left: w / 2 - 62,
              bottom: 0.06 * h,
              width: 124,
              height: 108,
              child: Transform.translate(
                offset: Offset(lerp(0, 0.03 * 124), lerp(0, -0.04 * 108)),
                child: Transform.scale(
                  scale: lerp(0.96, 1.04),
                  child: Opacity(
                    opacity: 0.95,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(
                        sigmaX: 24,
                        sigmaY: 24,
                        tileMode: TileMode.decal,
                      ), // blur(24px)
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: VigiaAura.white,
                          borderRadius: _coreRadius(phase),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// `48% 52% 46% 54% / 56% 44% 56% 44%` ↔ `56% 44% 52% 48% / 46% 58% 42% 54%`.
  static BorderRadius _coreRadius(double t) {
    const w = 124.0, h = 108.0;
    double l(double a, double b) => a + (b - a) * t;
    Radius r(double hx0, double hx1, double vy0, double vy1) =>
        Radius.elliptical(l(hx0, hx1) / 100 * w, l(vy0, vy1) / 100 * h);
    return BorderRadius.only(
      topLeft: r(48, 56, 56, 46),
      topRight: r(52, 44, 44, 58),
      bottomRight: r(46, 52, 56, 42),
      bottomLeft: r(54, 48, 44, 54),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.color, required this.blur});

  final Color color;
  final double blur;

  @override
  Widget build(BuildContext context) {
    // radial-gradient(circle, c 0%, c00 70%) + filter: blur(10px).
    return ImageFiltered(
      imageFilter: ImageFilter.blur(
        sigmaX: blur,
        sigmaY: blur,
        tileMode: TileMode.decal,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // `circle` sin tamaño = farthest-corner: radio = √2/2 del lado (0,7071 en Flutter).
          gradient: RadialGradient(
            radius: 0.7071,
            colors: [color, color.withValues(alpha: 0)],
            stops: const [0, 0.7],
          ),
        ),
      ),
    );
  }
}

/// Disposición del contenido del aura: cuerpo arriba y CTA abajo
/// (`margin-top:auto` de B5.2). Altura = máx(mínimo, cuerpo + separación + CTA).
/// Mide con el layout real de los hijos, sin intrínsecos: el texto con
/// `maxWidth` 270 se mide igual que se dibuja, con cualquier escala de texto.
class _HeroLayout extends MultiChildRenderObjectWidget {
  _HeroLayout({
    required Widget body,
    Widget? cta,
    required this.minHeight,
    required this.gap,
  }) : super(children: [body, ?cta]);

  final double minHeight;
  final double gap;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderHeroLayout(minHeight, gap);

  @override
  void updateRenderObject(BuildContext context, _RenderHeroLayout r) {
    r
      ..minHeight = minHeight
      ..gap = gap;
  }
}

class _HeroParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderHeroLayout extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _HeroParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _HeroParentData> {
  _RenderHeroLayout(this._minHeight, this._gap);

  double _minHeight;
  set minHeight(double v) {
    if (v != _minHeight) {
      _minHeight = v;
      markNeedsLayout();
    }
  }

  double _gap;
  set gap(double v) {
    if (v != _gap) {
      _gap = v;
      markNeedsLayout();
    }
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _HeroParentData) {
      child.parentData = _HeroParentData();
    }
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final width = constraints.maxWidth;
    final body = firstChild!.getDryLayout(BoxConstraints(maxWidth: width));
    final cta = childAfter(firstChild!);
    final ctaH = cta
        ?.getDryLayout(BoxConstraints(minWidth: width, maxWidth: width))
        .height;
    final h = ctaH == null
        ? math.max(_minHeight, body.height)
        : math.max(_minHeight, body.height + _gap + ctaH);
    return constraints.constrain(Size(width, h));
  }

  @override
  void performLayout() {
    final width = constraints.maxWidth;
    final childConstraints = BoxConstraints(maxWidth: width);
    final body = firstChild!;
    body.layout(childConstraints, parentUsesSize: true);
    (body.parentData! as _HeroParentData).offset = Offset.zero;
    var height = body.size.height;
    final cta = childAfter(body);
    if (cta != null) {
      cta.layout(
        BoxConstraints(minWidth: width, maxWidth: width),
        parentUsesSize: true,
      );
      final total = math.max(
        _minHeight,
        body.size.height + _gap + cta.size.height,
      );
      (cta.parentData! as _HeroParentData).offset = Offset(
        0,
        total - cta.size.height,
      );
      height = total;
    } else {
      height = math.max(_minHeight, height);
    }
    size = constraints.constrain(Size(width, height));
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
