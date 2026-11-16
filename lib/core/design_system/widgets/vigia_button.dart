import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens.dart';
import '../vigia_icons.dart';
import 'vigia_text.dart';

/// Variantes de botón de B5.2 (`mkBtn`, `heroBtn` y el botón de `PAPER`).
enum VigiaButtonKind {
  /// Fondo negro, texto blanco; 56 de alto.
  primary,

  /// Fondo claro y borde oscuro; 48 de alto.
  secondary,

  /// Acción principal sobre aura, con flecha.
  onAura,

  /// Acción secundaria sobre la tarjeta de papel.
  onPaper,
}

/// Botón de Vigía. Con [onPressed] nulo se muestra deshabilitado con el estilo
/// de B5.2 (fondo `sfs`, texto `i2` y borde discontinuo), con texto e indicación
/// semántica de desactivado, no solo por color.
///
/// Acceso (2026-11-15, a petición del usuario): al pulsar, el botón que
/// espera respuesta usa [loading] (mismos colores e indicador de progreso) y
/// los demás, [quietDisabled] (atenuados, sin borde discontinuo).
class VigiaButton extends StatelessWidget {
  const VigiaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = VigiaButtonKind.primary,
    this.icon,
    this.expand = true,
    this.height,
    this.loading = false,
    this.quietDisabled = false,
  });

  /// Operación en curso: conserva su aspecto, muestra un indicador de
  /// progreso y no admite otra pulsación.
  final bool loading;

  /// Deshabilitado temporal: atenuado, sin el borde discontinuo.
  final bool quietDisabled;

  final String label;
  final VoidCallback? onPressed;
  final VigiaButtonKind kind;
  final VigiaIcon? icon;
  final bool expand;

  TextStyle get labelStyle => switch (kind) {
    VigiaButtonKind.primary ||
    VigiaButtonKind.onAura => VigiaType.primaryButton,
    VigiaButtonKind.secondary ||
    VigiaButtonKind.onPaper => VigiaType.secondaryButton,
  };

  /// Altura mínima explícita (B5.2 usa 56 en los controles de P06).
  final double? height;

  @override
  Widget build(BuildContext context) {
    final p = VigiaColors.of(context);
    final disabled = onPressed == null || loading;
    final styledDisabled = onPressed == null && !loading && !quietDisabled;
    final minHeight =
        height ??
        switch (kind) {
          VigiaButtonKind.primary ||
          VigiaButtonKind.onAura => VigiaSpace.primaryButtonHeight,
          _ => VigiaSpace.secondaryButtonHeight,
        };
    late final Color bg, fg;
    BorderSide side = BorderSide.none;
    var dashed = false;
    if (styledDisabled) {
      bg = p.surfaceStrong;
      fg = p.inkSecondary;
      dashed = true;
    } else {
      switch (kind) {
        case VigiaButtonKind.primary:
          if (p.brightness == Brightness.dark) {
            side = BorderSide(color: p.control);
          }
          bg = VigiaControls.primaryFill;
          fg = VigiaControls.primaryInk;
        case VigiaButtonKind.onAura:
          bg = VigiaControls.primaryFill;
          fg = VigiaControls.primaryInk;
        case VigiaButtonKind.secondary:
        case VigiaButtonKind.onPaper:
          bg = kind == VigiaButtonKind.onPaper
              ? p.paper
              : VigiaControls.secondaryFill;
          fg = VigiaControls.secondaryInk;
          side = const BorderSide(
            color: VigiaControls.secondaryBorder,
            width: 1.5,
          );
      }
    }
    final iconToShow =
        icon ?? (kind == VigiaButtonKind.onAura ? VigiaIcon.arrow : null);
    final content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isLargeText(context) ? 16 : 22,
        vertical: 12,
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: VigiaText(
              label,
              textAlign: TextAlign.center,
              style: labelStyle.copyWith(color: fg),
            ),
          ),
          if (loading) ...[
            const SizedBox(width: 12),
            SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2.2, color: fg),
            ),
          ] else if (iconToShow != null) ...[
            const SizedBox(width: 8),
            VigiaIconView(iconToShow, size: 22, color: fg),
          ],
        ],
      ),
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(VigiaRadius.button),
      side: side,
    );
    Widget surface = Material(
      color: bg,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: disabled ? null : onPressed,
        // B5.2 no usa ondas ni resaltado al pulsar (solo escala); el foco sí es visible.
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        focusColor: p.focus.withValues(alpha: 0.24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: minHeight,
            minWidth: VigiaSpace.minTap,
          ),
          child: Center(widthFactor: expand ? null : 1, child: content),
        ),
      ),
    );
    if (dashed) {
      surface = CustomPaint(
        foregroundPainter: DashedRRectPainter(
          color: p.control,
          radius: VigiaRadius.button,
        ),
        child: surface,
      );
    }
    if (disabled && !styledDisabled && !loading) {
      surface = AnimatedOpacity(
        opacity: 0.45,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : VigiaMotion.colorDuration,
        child: surface,
      );
    }
    return Semantics(
      button: true,
      enabled: !disabled,
      child: PressScale(
        enabled: !disabled,
        child: SizedBox(width: expand ? double.infinity : null, child: surface),
      ),
    );
  }
}

/// Escala 0,98 al pulsar (110 ms, `cubic-bezier(.22,1,.36,1)`), como `[data-vgb]:active`.
/// Con movimiento reducido no hay escala.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final active = widget.enabled && !reduce && _down;
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: active ? VigiaMotion.pressScale : 1,
        duration: reduce ? Duration.zero : VigiaMotion.pressDuration,
        curve: VigiaMotion.press,
        child: widget.child,
      ),
    );
  }
}

/// Borde discontinuo de 1,5 sobre un rectángulo redondeado (estado deshabilitado).
class DashedRRectPainter extends CustomPainter {
  DashedRRectPainter({
    required this.color,
    required this.radius,
    this.dash = 6,
    this.gap = 4,
  });

  final Color color;
  final double radius;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    const w = 1.5;
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(w / 2),
      Radius.circular(radius - w / 2),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..color = color;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += dash + gap) {
        canvas.drawPath(
          metric.extractPath(d, (d + dash).clamp(0, metric.length)),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(DashedRRectPainter old) =>
      old.color != color || old.radius != radius;
}
