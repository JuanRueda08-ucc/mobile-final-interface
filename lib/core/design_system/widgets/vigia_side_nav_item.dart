import 'dart:math' as math;

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
    this.expanded = false,
  });

  final String label;
  final VigiaIcon icon;
  final bool selected;
  final VoidCallback onTap;

  /// Barra abierta: el nombre se ve junto al icono y no hace falta la
  /// etiqueta flotante (2026-11-16).
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final p = VigiaColors.of(context);
    final dark = p.brightness == Brightness.dark;
    final fill = Color.alphaBlend(
      p.focus.withValues(alpha: dark ? 0.14 : 0.08),
      p.surface,
    );
    final fg = selected ? p.focus : p.ink;
    final iconView = SizedBox.square(
      dimension: VigiaSpace.minTap,
      child: Center(child: VigiaIconView(icon, size: 22, color: fg)),
    );
    return TooltipVisibility(
      visible: !expanded,
      child: Tooltip(
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
          onTap: onTap,
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
                onTap: onTap,
                hoverColor: p.focus.withValues(alpha: 0.10),
                focusColor: p.focus.withValues(alpha: 0.26),
                highlightColor: p.focus.withValues(alpha: 0.14),
                child: expanded
                    ? ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: VigiaSpace.minTap,
                        ),
                        child: Row(
                          children: [
                            iconView,
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  end: 12,
                                ),
                                child: Text(
                                  label,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: VigiaType.navLabel.copyWith(color: fg),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : iconView,
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
