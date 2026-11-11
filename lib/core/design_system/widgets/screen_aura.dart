import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens.dart';

class ScreenAura extends StatelessWidget {
  const ScreenAura({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = VigiaColors.of(context);
    final dark = palette.brightness == Brightness.dark;
    final accent = dark ? VigiaAura.sky : VigiaAura.lime;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-1.05, -0.84),
          radius: 1.12,
          colors: [
            Color.alphaBlend(
              VigiaAura.lilac.withValues(alpha: dark ? 0.30 : 0.78),
              palette.bg,
            ),
            palette.bg,
          ],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(1.06, -0.34),
            radius: 0.92,
            colors: [
              accent.withValues(alpha: dark ? 0.14 : 0.67),
              accent.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
