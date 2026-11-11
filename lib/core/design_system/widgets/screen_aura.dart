import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens.dart';

class ScreenAura extends StatelessWidget {
  const ScreenAura({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = VigiaColors.of(context);
    final dark = palette.brightness == Brightness.dark;
    final accent = dark ? VigiaBrand.mistBlue : VigiaBrand.softGreen;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-1.05, -0.84),
          radius: 1.12,
          colors: [
            Color.alphaBlend(
              VigiaBrand.lavender.withValues(alpha: dark ? 0.20 : 0.18),
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
              accent.withValues(alpha: dark ? 0.10 : 0.50),
              accent.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
