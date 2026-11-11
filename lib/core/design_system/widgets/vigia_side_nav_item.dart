import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens.dart';
import '../vigia_icons.dart';
import 'vigia_button.dart';

class VigiaSideNavItem extends StatelessWidget {
  const VigiaSideNavItem({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final VigiaIcon icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = VigiaColors.of(context);
    final dark = p.brightness == Brightness.dark;
    final fill = Color.alphaBlend(
      p.focus.withValues(alpha: dark ? 0.14 : 0.08),
      p.surface,
    );
    void activate() {
      _TapLabel.show(context, label);
      onTap();
    }

    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      ignorePointer: true,
      triggerMode: TooltipTriggerMode.manual,
      waitDuration: const Duration(milliseconds: 250),
      constraints: const BoxConstraints(maxWidth: _labelMaxWidth),
      padding: _labelPadding,
      textStyle: _labelTextStyle(p),
      decoration: _labelDecoration(p),
      positionDelegate: _labelPosition,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        onTap: activate,
        excludeSemantics: true,
        child: PressScale(
          child: Material(
            color: selected ? fill : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(VigiaRadius.tag),
              side: selected
                  ? BorderSide(color: p.focus.withValues(alpha: 0.46))
                  : BorderSide.none,
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: activate,
              hoverColor: p.focus.withValues(alpha: 0.10),
              focusColor: p.focus.withValues(alpha: 0.26),
              highlightColor: p.focus.withValues(alpha: 0.14),
              child: SizedBox.square(
                dimension: VigiaSpace.minTap,
                child: Center(
                  child: VigiaIconView(
                    icon,
                    size: 22,
                    color: selected ? p.focus : p.ink,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const _labelMaxWidth = 224.0;
const _labelPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 8);

TextStyle _labelTextStyle(VigiaPalette p) =>
    VigiaType.navLabel.copyWith(inherit: false, color: p.ink);

BoxDecoration _labelDecoration(VigiaPalette p) => BoxDecoration(
  color: p.surface,
  border: Border.all(color: p.control),
  borderRadius: BorderRadius.circular(VigiaRadius.tag),
);

Offset _labelPosition(TooltipPositionContext context) {
  const gap = 8.0;
  final target = context.target;
  final size = context.tooltipSize;
  final overlay = context.overlaySize;
  final side = context.targetSize.width / 2 + gap;
  final x = target.dx < overlay.width / 2
      ? target.dx + side
      : target.dx - side - size.width;
  return Offset(
    x.clamp(gap, math.max(gap, overlay.width - size.width - gap)),
    (target.dy - size.height / 2).clamp(
      gap,
      math.max(gap, overlay.height - size.height - gap),
    ),
  );
}

// La etiqueta del toque vive en el overlay raíz para seguir visible tras
// cambiar de ruta o cerrar el menú compacto.
class _TapLabel extends StatefulWidget {
  const _TapLabel({
    required this.anchor,
    required this.label,
    required this.dismiss,
  });

  final Rect anchor;
  final String label;
  final VoidCallback dismiss;

  static final _active = Expando<VoidCallback>();

  static void show(BuildContext context, String label) {
    Tooltip.dismissAllToolTips();
    final overlay = Overlay.of(context, rootOverlay: true);
    final box = context.findRenderObject()! as RenderBox;
    final overlayBox = overlay.context.findRenderObject()! as RenderBox;
    final origin = box.localToGlobal(Offset.zero, ancestor: overlayBox);
    final anchor = origin & box.size;
    _active[overlay]?.call();
    late final OverlayEntry entry;
    var dismissed = false;
    void dismiss() {
      if (dismissed) return;
      dismissed = true;
      _active[overlay] = null;
      entry.remove();
      entry.dispose();
    }

    entry = OverlayEntry(
      builder: (_) => _TapLabel(anchor: anchor, label: label, dismiss: dismiss),
    );
    _active[overlay] = dismiss;
    overlay.insert(entry);
  }

  @override
  State<_TapLabel> createState() => _TapLabelState();
}

class _TapLabelState extends State<_TapLabel> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1400), widget.dismiss);
    GestureBinding.instance.pointerRouter.addGlobalRoute(_dismissOnPointerDown);
  }

  void _dismissOnPointerDown(PointerEvent event) {
    if (event is PointerDownEvent) widget.dismiss();
  }

  @override
  void dispose() {
    GestureBinding.instance.pointerRouter.removeGlobalRoute(
      _dismissOnPointerDown,
    );
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = VigiaColors.of(context);
    return Positioned.fill(
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: CustomSingleChildLayout(
            delegate: _TapLabelLayout(widget.anchor),
            child: DecoratedBox(
              decoration: _labelDecoration(p),
              child: Padding(
                padding: _labelPadding,
                child: Text(widget.label, style: _labelTextStyle(p)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TapLabelLayout extends SingleChildLayoutDelegate {
  const _TapLabelLayout(this.anchor);

  final Rect anchor;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen().enforce(
        const BoxConstraints(maxWidth: _labelMaxWidth),
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) => _labelPosition(
    TooltipPositionContext(
      target: anchor.center,
      targetSize: anchor.size,
      tooltipSize: childSize,
      verticalOffset: 0,
      overlaySize: size,
    ),
  );

  @override
  bool shouldRelayout(_TapLabelLayout oldDelegate) =>
      anchor != oldDelegate.anchor;
}
