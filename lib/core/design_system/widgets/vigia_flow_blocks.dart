import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens.dart';
import '../vigia_icons.dart';
import 'vigia_button.dart';
import 'vigia_scaffold.dart';
import 'vigia_text.dart';

/// Grupo de filas de comprobación (`groupRows` de B5.2): fondo `sfs`, radio
/// 24 y relleno horizontal 18.
class CheckGroup extends StatelessWidget {
  const CheckGroup({super.key, required this.rows});

  final List<CheckRow> rows;

  @override
  Widget build(BuildContext context) {
    final p = VigiaColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: p.surfaceStrong,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              decoration: BoxDecoration(
                border: i == 0 ? null : Border(top: BorderSide(color: p.line)),
              ),
              child: rows[i],
            ),
        ],
      ),
    );
  }
}

/// Fila de comprobación de P04 (`ROW` de B5.2): marca, nombre, valor, causa y
/// acción opcional. El estado se dice con texto («Cumplida»/«No cumplida») y
/// con el icono, no solo con color.
class CheckRow extends StatelessWidget {
  const CheckRow({
    super.key,
    required this.label,
    required this.ok,
    required this.value,
    this.cause,
    this.action,
  });

  final String label;
  final bool ok;
  final String value;
  final String? cause;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = VigiaColors.of(context);
    final mark = Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ok ? p.ink : p.closeBg,
        border: ok
            ? null
            : Border.all(color: p.closeInk.withValues(alpha: 0.4)),
      ),
      alignment: Alignment.center,
      child: VigiaIconView(
        ok ? VigiaIcon.check : VigiaIcon.close,
        size: 18,
        color: ok ? p.bg : p.closeInk,
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          mark,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MergeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VigiaText(
                        label,
                        style: VigiaType.small.copyWith(
                          color: p.inkSecondary,
                          height: 1.35,
                        ),
                      ),
                      Semantics(
                        label: ok ? 'Cumplida' : 'No cumplida',
                        child: const SizedBox.shrink(),
                      ),
                      VigiaText(
                        value,
                        style: VigiaType.body.copyWith(
                          color: p.ink,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (cause != null)
                        VigiaText(
                          cause!,
                          style: VigiaType.small.copyWith(
                            color: p.inkSecondary,
                            height: 1.4,
                          ),
                        ),
                    ],
                  ),
                ),
                if (action != null) ...[const SizedBox(height: 8), action!],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tres ejes separados de P06 (`AX` de B5.2): Sesión, Medición y Señal
/// (UX §5.1). Rejilla `repeat(auto-fit, minmax(104px, 1fr))`.
class AxesRow extends StatelessWidget {
  const AxesRow({
    super.key,
    required this.session,
    required this.measurement,
    required this.signal,
  });

  final String session;
  final String measurement;
  final String signal;

  @override
  Widget build(BuildContext context) {
    final p = VigiaColors.of(context);
    final cells = [
      ('Sesión', session),
      ('Medición', measurement),
      ('Señal', signal),
    ];
    return LayoutBuilder(
      builder: (context, box) {
        const gap = 8.0, minCell = 104.0;
        final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
        // Con texto ampliado la celda mínima crece con el texto.
        final cell = minCell * (scale > 1 ? scale : 1);
        final columns = ((box.maxWidth + gap) / (cell + gap)).floor().clamp(
          1,
          3,
        );
        final width = (box.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final (k, v) in cells)
              SizedBox(
                width: width,
                child: MergeSemantics(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: p.surfaceStrong,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        VigiaText(
                          k,
                          style: VigiaType.small.copyWith(
                            color: p.inkSecondary,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 2),
                        VigiaText(
                          v,
                          style: VigiaType.body.copyWith(
                            color: p.ink,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Segmento de [DistributionBar].
class DistributionSegment {
  const DistributionSegment(this.label, this.value, this.weight);

  final String label;
  final String value;
  final double weight;
}

/// Reparto de tiempos de P07 (`DIST` de B5.2): barra y leyenda. Cada segmento
/// tiene trama propia (sólido, rayado, control y discontinuo), no solo color.
class DistributionBar extends StatelessWidget {
  const DistributionBar({super.key, required this.segments});

  final List<DistributionSegment> segments;

  @override
  Widget build(BuildContext context) {
    final p = VigiaColors.of(context);
    final total = segments.fold<double>(0, (a, s) => a + s.weight);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 16,
              color: p.surfaceStrong,
              child: total <= 0
                  ? null
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < segments.length; i++)
                          if (segments[i].weight > 0) ...[
                            Expanded(
                              flex: (segments[i].weight * 1000 / total)
                                  .round()
                                  .clamp(1, 1000),
                              child: _Swatch(index: i),
                            ),
                            const SizedBox(width: 2),
                          ],
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < segments.length; i++)
          MergeSemantics(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 12,
                    child: ExcludeSemantics(child: _Swatch(index: i)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: VigiaText(
                      segments[i].label,
                      style: VigiaType.small.copyWith(
                        color: p.ink,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    segments[i].value,
                    style: VigiaType.kvValue.copyWith(color: p.ink),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final p = VigiaColors.of(context);
    return switch (index) {
      0 => DecoratedBox(
        decoration: BoxDecoration(
          color: p.ink,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      1 => CustomPaint(painter: _StripePainter(p.inkSecondary)),
      2 => DecoratedBox(
        decoration: BoxDecoration(
          color: p.control,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      _ => CustomPaint(
        foregroundPainter: DashedRRectPainter(
          color: p.control,
          radius: 4,
          dash: 3,
          gap: 2,
        ),
      ),
    };
  }
}

/// `repeating-linear-gradient(90deg, i2 0 4px, transparent 4px 7px)`.
class _StripePainter extends CustomPainter {
  _StripePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    for (var x = 0.0; x < size.width; x += 7) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 4, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_StripePainter old) => old.color != color;
}

/// Zona de vista previa de P04/P05 (`VIEWER` de B5.2). En la demostración no
/// hay cámara: la zona lo dice expresamente y nunca muestra una imagen.
class CameraStage extends StatelessWidget {
  const CameraStage({super.key, required this.stateText});

  final String stateText;

  @override
  Widget build(BuildContext context) {
    final p = VigiaColors.of(context);
    return Semantics(
      container: true,
      label: 'Vista previa simulada, sin cámara',
      child: Container(
        constraints: const BoxConstraints(minHeight: 208),
        decoration: BoxDecoration(
          color: p.neutralBg,
          borderRadius: BorderRadius.circular(28),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(12),
              ),
              child: VigiaText(
                'DEMO · sin cámara',
                style: VigiaType.demoLabel.copyWith(
                  color: const Color(0xFFFFFFFF),
                ),
              ),
            ),
            const SizedBox(height: 16),
            VigiaText(
              'No se abre ninguna cámara. Las condiciones de esta vista son '
              'simuladas.',
              style: VigiaType.small.copyWith(color: p.neutralInk),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: VigiaText(
                stateText,
                style: VigiaType.small.copyWith(
                  color: p.ink,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fila de botones (`BR` de B5.2): en fila si todos caben sin partir sus
/// palabras; si no, uno debajo de otro, completos.
class VigiaButtonRow extends StatelessWidget {
  const VigiaButtonRow({super.key, required this.buttons});

  final List<VigiaButton> buttons;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(
      builder: (context, box) {
        const gap = 8.0;
        final cell =
            (box.maxWidth - gap * (buttons.length - 1)) / buttons.length;
        final pad = isLargeText(context) ? 32.0 : 44.0;
        final fits = buttons.every((b) {
          var widest = 0.0;
          for (final word in b.label.split(' ')) {
            final tp = TextPainter(
              text: TextSpan(text: word, style: VigiaType.button),
              textDirection: TextDirection.ltr,
              textScaler: scaler,
              maxLines: 1,
            )..layout();
            if (tp.width > widest) widest = tp.width;
            tp.dispose();
          }
          final icon = b.icon == null ? 0 : 30;
          return widest + pad + icon <= cell;
        });
        if (!fits) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < buttons.length; i++) ...[
                if (i > 0) const SizedBox(height: gap),
                buttons[i],
              ],
            ],
          );
        }
        // VigiaText usa LayoutBuilder (sin intrínsecos): la fila alinea por
        // arriba; cada botón conserva su altura mínima.
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < buttons.length; i++) ...[
              if (i > 0) const SizedBox(width: gap),
              Expanded(child: buttons[i]),
            ],
          ],
        );
      },
    );
  }
}

/// Diálogo de confirmación de B5.2 (D01, D02, D05): hoja inferior sobre
/// velo, foco inicial en la acción segura. Devuelve `true` solo si se elige
/// [actionLabel]; Volver o tocar fuera equivalen a la acción segura (UX §3.1).
Future<bool> showVigiaConfirm(
  BuildContext context, {
  required String id,
  required String title,
  required String text,
  required String safeLabel,
  required String actionLabel,
  bool isDemo = false,
}) async {
  final p = VigiaColors.of(context);
  final reduce = MediaQuery.disableAnimationsOf(context);
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar el diálogo',
    barrierColor: p.scrim,
    transitionDuration: reduce
        ? Duration.zero
        : const Duration(milliseconds: 180),
    pageBuilder: (context, _, _) => _ConfirmSheet(
      id: id,
      title: title,
      text: text,
      safeLabel: safeLabel,
      actionLabel: actionLabel,
      isDemo: isDemo,
    ),
    transitionBuilder: (context, animation, _, child) => FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: VigiaMotion.press)),
        child: child,
      ),
    ),
  );
  return result ?? false;
}

class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({
    required this.id,
    required this.title,
    required this.text,
    required this.safeLabel,
    required this.actionLabel,
    required this.isDemo,
  });

  final String id;
  final String title;
  final String text;
  final String safeLabel;
  final String actionLabel;
  final bool isDemo;

  @override
  Widget build(BuildContext context) {
    final p = VigiaColors.of(context);
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Material(
            key: Key('dialog-$id'),
            color: p.surface,
            borderRadius: BorderRadius.circular(VigiaRadius.card),
            child: Semantics(
              scopesRoute: true,
              namesRoute: true,
              explicitChildNodes: true,
              label: title,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isDemo) ...[
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: DemoLabel(),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Semantics(
                      header: true,
                      child: VigiaText(
                        title,
                        style: VigiaType.dialogTitle.copyWith(color: p.ink),
                      ),
                    ),
                    const SizedBox(height: 12),
                    VigiaText(
                      text,
                      style: VigiaType.body.copyWith(color: p.ink),
                    ),
                    const SizedBox(height: 16),
                    Focus(
                      autofocus: true,
                      child: VigiaButton(
                        label: safeLabel,
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ),
                    const SizedBox(height: 12),
                    VigiaButton(
                      label: actionLabel,
                      kind: VigiaButtonKind.secondary,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Título de pantalla (`H` de B5.2): 30/400, margen superior 8.
class VigiaHeading extends StatelessWidget {
  const VigiaHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = VigiaColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Semantics(
        header: true,
        child: VigiaText(text, style: VigiaType.h1.copyWith(color: p.ink)),
      ),
    );
  }
}

/// Panel «Simulación DEMO»: controles que solo existen en la demostración
/// para elegir condiciones o resultados simulados. Se rotula siempre así y
/// se separa del contenido de la pantalla con un borde discontinuo.
class DemoSimulationPanel extends StatelessWidget {
  const DemoSimulationPanel({
    super.key,
    required this.title,
    required this.text,
    required this.children,
  });

  final String title;
  final String text;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = VigiaColors.of(context);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: CustomPaint(
        foregroundPainter: DashedRRectPainter(
          color: p.control,
          radius: VigiaRadius.card,
        ),
        child: Padding(
          padding: EdgeInsets.all(isLargeText(context) ? 16 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(alignment: Alignment.centerLeft, child: DemoLabel()),
              const SizedBox(height: 8),
              Semantics(
                header: true,
                child: VigiaText(
                  title,
                  style: VigiaType.h3.copyWith(color: p.ink),
                ),
              ),
              const SizedBox(height: 4),
              VigiaText(
                text,
                style: VigiaType.small.copyWith(color: p.inkSecondary),
              ),
              const SizedBox(height: 8),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

/// Interruptor de una condición simulada (fila completa de 48 de alto).
class DemoToggle extends StatelessWidget {
  const DemoToggle({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = VigiaColors.of(context);
    return MergeSemantics(
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(12),
        highlightColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: VigiaSpace.minTap),
          child: Row(
            children: [
              Expanded(
                child: VigiaText(
                  label,
                  style: VigiaType.body.copyWith(color: p.ink),
                ),
              ),
              const SizedBox(width: 12),
              Switch(
                value: value,
                onChanged: onChanged,
                activeTrackColor: p.ink,
                activeThumbColor: p.bg,
                inactiveTrackColor: p.surfaceStrong,
                inactiveThumbColor: p.control,
                trackOutlineColor: WidgetStatePropertyAll(p.control),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
