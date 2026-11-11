import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens.dart';

class ScreenAura extends StatelessWidget {
  const ScreenAura({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = VigiaColors.of(context);
    final dark = palette.brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.92, -0.98),
          radius: 1.08,
          colors: [
            Color.alphaBlend(
              VigiaBrand.lavender.withValues(alpha: dark ? 0.40 : 0.74),
              palette.bg,
            ),
            palette.bg,
          ],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(1.03, -0.91),
            radius: 1.02,
            colors: [
              VigiaBrand.mistBlue.withValues(alpha: dark ? 0.29 : 0.56),
              VigiaBrand.mistBlue.withValues(alpha: 0),
            ],
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(1.12, -0.35),
              radius: 0.91,
              colors: [
                VigiaBrand.softGreen.withValues(alpha: dark ? 0.10 : 0.66),
                VigiaBrand.softGreen.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
