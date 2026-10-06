import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens.dart';
import '../vigia_icons.dart';
import 'vigia_button.dart';

/// Tonos de tarjeta de estado de B5.2 (`TNX`). Cada tono tiene texto e icono
/// propios, además del color (RF29.CA1: los avisos no dependen solo del color).
enum StatusTone { plain, strong, warn, close, neutral, pending, pause, alert }

/// Tarjeta de estado (`CARD` de B5.2): icono en círculo, etiqueta, título y texto.
class StatusCard extends StatelessWidget {
  const StatusCard({
    super.key,
    required this.tone,
    required this.tag,
    required this.title,
    this.text,
    required this.icon,
  });

  final StatusTone tone;
  final String tag;
  final String title;
  final String? text;
  final VigiaIcon icon;

  @override
  Widget build(BuildContext context) {
    final p = VigiaColors.of(context);
    final (bg, fg) = switch (tone) {
      StatusTone.plain => (p.surface, p.ink),
      StatusTone.strong => (p.surfaceStrong, p.ink),
      StatusTone.warn => (p.warnBg, p.warnInk),
      StatusTone.close => (p.closeBg, p.closeInk),
      StatusTone.neutral => (p.neutralBg, p.neutralInk),
      StatusTone.pending => (p.pendingBg, p.pendingInk),
      StatusTone.pause => (p.pauseBg, p.pauseInk),
      StatusTone.alert => (p.errorBg, p.errorInk),
    };
    final border = tone == StatusTone.plain
        ? p.line
        : fg.withValues(alpha: 0.22);
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(VigiaSpace.cardPadding),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(VigiaRadius.card),
          border: Border.all(color: border),
        ),
        child: LayoutBuilder(
          builder: (context, box) {
            final iconBox = Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fg.withValues(alpha: 0.12),
              ),
              alignment: Alignment.center,
              child: VigiaIconView(icon, color: fg),
            );
            final texts = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tag, style: VigiaType.cardTag.copyWith(color: fg)),
                const SizedBox(height: 4),
                Text(title, style: VigiaType.cardTitle.copyWith(color: fg)),
                if (text != null) ...[
                  const SizedBox(height: 4),
                  Text(text!, style: VigiaType.body.copyWith(color: fg)),
                ],
              ],
            );
            // Composición de B5.2: icono a la izquierda. Con texto ampliado, si
            // alguna palabra no cabe junto al icono, el icono pasa arriba para
            // no partir palabras (el texto no se reduce).
            final scaler = MediaQuery.textScalerOf(context);
            final besideIcon = box.maxWidth - 44 - 14;
            final stacked =
                !_wordsFit(tag, VigiaType.cardTag, besideIcon, scaler) ||
                !_wordsFit(title, VigiaType.cardTitle, besideIcon, scaler) ||
                (text != null &&
                    !_wordsFit(text!, VigiaType.body, besideIcon, scaler));
            if (stacked) {
              return Column(
                key: const Key('status-card-stacked'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [iconBox, const SizedBox(height: 12), texts],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                iconBox,
                const SizedBox(width: 14),
                Expanded(child: texts),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// ¿Cabe cada palabra de [text] en [width] con el estilo y la escala dados?
bool _wordsFit(String text, TextStyle style, double width, TextScaler scaler) {
  for (final word in text.split(RegExp(r'\s+'))) {
    if (word.isEmpty) continue;
    final tp = TextPainter(
      text: TextSpan(text: word, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    if (tp.width > width) return false;
  }
  return true;
}

/// Fila clave–valor con separador superior (`KV`).
class KeyValueRow extends StatelessWidget {
  const KeyValueRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = VigiaColors.of(context);
    return MergeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: p.line)),
        ),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 12,
          runSpacing: 2,
          children: [
            Text(label, style: VigiaType.kvKey.copyWith(color: p.inkSecondary)),
            Text(value, style: VigiaType.kvValue.copyWith(color: p.ink)),
          ],
        ),
      ),
    );
  }
}

/// Texto de cuerpo (`P`); [secondary] usa 14 px y color secundario.
class VigiaParagraph extends StatelessWidget {
  const VigiaParagraph(this.text, {super.key, this.secondary = false});

  final String text;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    final p = VigiaColors.of(context);
    return Text(
      text,
      style: secondary
          ? VigiaType.small.copyWith(color: p.inkSecondary)
          : VigiaType.body.copyWith(color: p.ink),
    );
  }
}

/// Encabezado de sección (`H3`): 20/500, margen superior 8.
class VigiaSectionTitle extends StatelessWidget {
  const VigiaSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = VigiaColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Semantics(
        header: true,
        child: Text(text, style: VigiaType.h3.copyWith(color: p.ink)),
      ),
    );
  }
}

/// Métrica de la tarjeta de papel: valor grande y clave.
class PaperMetric {
  const PaperMetric(this.value, this.label);

  final String value;
  final String label;
}

/// Tarjeta «papel» del último resumen (`PAPER`): fondo `pp`, métricas tabulares.
class PaperSummaryCard extends StatelessWidget {
  const PaperSummaryCard({
    super.key,
    required this.tag,
    required this.title,
    required this.metrics,
    this.actionLabel,
    this.onAction,
  });

  final String tag;
  final String title;
  final List<PaperMetric> metrics;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = VigiaColors.of(context);
    return Container(
      padding: const EdgeInsets.all(VigiaSpace.cardPadding),
      decoration: BoxDecoration(
        color: p.paper,
        borderRadius: BorderRadius.circular(VigiaRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            tag,
            style: VigiaType.small.copyWith(
              color: p.paperSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(title, style: VigiaType.paperTitle.copyWith(color: p.onPaper)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              for (final m in metrics)
                MergeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        m.value,
                        style: VigiaType.metric.copyWith(color: p.onPaper),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        m.label,
                        style: VigiaType.small.copyWith(
                          color: p.paperSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 12),
            VigiaButton(
              label: actionLabel!,
              onPressed: onAction,
              kind: VigiaButtonKind.onPaper,
            ),
          ],
        ],
      ),
    );
  }
}
