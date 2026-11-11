import 'package:flutter/material.dart';

import 'tokens.dart';

/// Familias variables empaquetadas con la app.
const vigiaHeadingFont = 'Outfit';
const vigiaBodyFont = 'Onest';

/// Escala B5.2 en px lógicos. El sistema aplica su TextScaler sobre estos tamaños.
abstract final class VigiaType {
  // Flutter 3.47 aplica FontWeight directamente al eje wght de fuentes variables.
  static const _heading = TextStyle(
    fontFamily: vigiaHeadingFont,
    fontWeight: FontWeight(622),
  );
  static const _base = TextStyle(
    fontFamily: vigiaBodyFont,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );
  static const _medium = TextStyle(
    fontFamily: vigiaBodyFont,
    fontWeight: FontWeight.w500,
  );

  static TextStyle heroTitle(double size) => _heading.copyWith(
    fontSize: size,
    height: 1.1,
    letterSpacing: -0.01 * size,
  );

  static final appBarTitle = _heading.copyWith(fontSize: 22, height: 1.2);
  static final wordmark = _heading.copyWith(
    fontSize: 24,
    height: 1.12,
    letterSpacing: -0.5,
  );
  static final h1 = _heading.copyWith(fontSize: 30, height: 1.15);
  static final h3 = _heading.copyWith(fontSize: 20, height: 1.3);

  static final body = _base.copyWith(fontSize: 16);
  static final small = _base.copyWith(fontSize: 14);
  static final indicator = _medium.copyWith(fontSize: 16, height: 1.35);
  static final smallIndicator = _medium.copyWith(fontSize: 14, height: 1.4);

  static final cardTag = _medium.copyWith(fontSize: 14, height: 1.35);
  static final cardTitle = appBarTitle;

  static final secondaryButton = _medium.copyWith(fontSize: 16, height: 1.25);
  static final primaryButton = secondaryButton.copyWith(
    fontWeight: const FontWeight(550),
  );

  static final pill = smallIndicator;
  static final demoLabel = _medium.copyWith(fontSize: 12, height: 1.35);
  static final kvKey = _base.copyWith(fontSize: 14, height: 1.4);
  static final kvValue = smallIndicator.copyWith(
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static final paperTitle = h3;
  static final metric = _medium.copyWith(
    fontSize: 30,
    height: 1.15,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static TextStyle heroMetric(double size) =>
      metric.copyWith(fontSize: size, height: 1.1, letterSpacing: -0.01 * size);

  static final navLabel = _medium.copyWith(fontSize: 14, height: 1.25);
  static final dialogTitle = _heading.copyWith(fontSize: 24, height: 1.25);
  static final toast = kvKey;

  static TextTheme material(Color ink) {
    final text = Typography.material2021().black.apply(
      fontFamily: vigiaBodyFont,
      bodyColor: ink,
      displayColor: ink,
    );
    return text.copyWith(
      displayLarge: text.displayLarge?.merge(_heading),
      displayMedium: text.displayMedium?.merge(_heading),
      displaySmall: text.displaySmall?.merge(_heading),
      headlineLarge: text.headlineLarge?.merge(_heading),
      headlineMedium: text.headlineMedium?.merge(_heading),
      headlineSmall: text.headlineSmall?.merge(_heading),
      titleLarge: text.titleLarge?.merge(_heading),
      titleMedium: text.titleMedium?.merge(_heading),
      titleSmall: text.titleSmall?.merge(_heading),
      bodyLarge: text.bodyLarge?.copyWith(fontWeight: FontWeight.w400),
      bodyMedium: text.bodyMedium?.copyWith(fontWeight: FontWeight.w400),
      bodySmall: text.bodySmall?.copyWith(fontWeight: FontWeight.w400),
      labelLarge: text.labelLarge?.merge(_medium),
      labelMedium: text.labelMedium?.merge(_medium),
      labelSmall: text.labelSmall?.merge(_medium),
    );
  }
}

/// Acceso a la paleta B5.2 desde el árbol de widgets.
class VigiaColors extends ThemeExtension<VigiaColors> {
  const VigiaColors(this.palette);

  final VigiaPalette palette;

  static VigiaPalette of(BuildContext context) =>
      Theme.of(context).extension<VigiaColors>()!.palette;

  @override
  VigiaColors copyWith({VigiaPalette? palette}) =>
      VigiaColors(palette ?? this.palette);

  @override
  VigiaColors lerp(VigiaColors? other, double t) =>
      t < 0.5 || other == null ? this : other; // Paletas discretas: sin interpolación.
}

ThemeData buildVigiaTheme(VigiaPalette p) {
  final scheme = ColorScheme(
    brightness: p.brightness,
    primary: p.ink,
    onPrimary: p.bg,
    secondary: p.surfaceStrong,
    onSecondary: p.ink,
    error: p.errorInk,
    onError: p.errorBg,
    surface: p.bg,
    onSurface: p.ink,
    surfaceContainerHighest: p.surfaceStrong,
    outline: p.control,
    outlineVariant: p.line,
    scrim: p.scrim,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: p.brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.bg,
    fontFamily: vigiaBodyFont,
    focusColor: p.focus.withValues(alpha: 0.24),
    splashFactory:
        NoSplash.splashFactory, // B5.2 usa escala 0,98 al pulsar, no ondas.
    textTheme: VigiaType.material(p.ink),
    extensions: [VigiaColors(p)],
  );
}

final ThemeData vigiaLightTheme = buildVigiaTheme(VigiaPalette.light);
final ThemeData vigiaDarkTheme = buildVigiaTheme(VigiaPalette.dark);
