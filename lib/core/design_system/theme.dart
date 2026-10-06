import 'package:flutter/material.dart';

import 'tokens.dart';

/// Familia tipográfica local (assets/fonts/Inter, SIL OFL 1.1). Sin carga remota.
const String vigiaFontFamily = 'Inter';

/// Escala tipográfica de B5.2 (`F(n)` en px lógicos; la escala de texto del
/// sistema se aplica encima mediante `TextScaler`, sin topes).
abstract final class VigiaType {
  static const _base = TextStyle(fontFamily: vigiaFontFamily, height: 1.45);

  /// `HERO` título: 40 px (32 en sesión vigente), peso 400, interlínea 1,1, −0,01 em.
  static TextStyle heroTitle(double size) => _base.copyWith(
    fontSize: size,
    height: 1.1,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.01 * size,
  );

  /// Encabezado de la pantalla (barra superior): 22/500.
  static final appBarTitle = _base.copyWith(
    fontSize: 22,
    height: 1.2,
    fontWeight: FontWeight.w500,
  );

  /// `H`: 30/400.
  static final h1 = _base.copyWith(
    fontSize: 30,
    height: 1.15,
    fontWeight: FontWeight.w400,
  );

  /// `H3`: 20/500.
  static final h3 = _base.copyWith(
    fontSize: 20,
    height: 1.3,
    fontWeight: FontWeight.w500,
  );

  /// `P`: 16 cuerpo; 14 secundario.
  static final body = _base.copyWith(fontSize: 16);
  static final small = _base.copyWith(fontSize: 14, height: 1.45);

  /// Tarjeta de estado: etiqueta 14, título 22/500, texto 16.
  static final cardTag = _base.copyWith(fontSize: 14, height: 1.35);
  static final cardTitle = _base.copyWith(
    fontSize: 22,
    height: 1.2,
    fontWeight: FontWeight.w500,
  );

  /// Botones: 16/500.
  static final button = _base.copyWith(
    fontSize: 16,
    height: 1.25,
    fontWeight: FontWeight.w500,
  );

  /// Pastilla de etiqueta del aura: 14/500.
  static final pill = _base.copyWith(
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w500,
  );

  /// Rótulo DEMO: 12/500.
  static final demoLabel = _base.copyWith(
    fontSize: 12,
    height: 1.35,
    fontWeight: FontWeight.w500,
  );

  /// `KV`: clave 14, valor 14/500 tabular.
  static final kvKey = _base.copyWith(fontSize: 14, height: 1.4);
  static final kvValue = _base.copyWith(
    fontSize: 14,
    height: 1.4,
    fontWeight: FontWeight.w500,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// `PAPER`: título 20/500 tabular; métrica 30/400 tabular; clave 14.
  static final paperTitle = _base.copyWith(
    fontSize: 20,
    height: 1.3,
    fontWeight: FontWeight.w500,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
  static final metric = _base.copyWith(
    fontSize: 30,
    height: 1.15,
    fontWeight: FontWeight.w400,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// Barra principal: 14/500, interlínea 1,25.
  static final navLabel = _base.copyWith(
    fontSize: 14,
    height: 1.25,
    fontWeight: FontWeight.w500,
  );

  /// Título de diálogo: 24/400, interlínea 1,25.
  static final dialogTitle = _base.copyWith(
    fontSize: 24,
    height: 1.25,
    fontWeight: FontWeight.w400,
  );

  /// Aviso temporal (toast): 14.
  static final toast = _base.copyWith(fontSize: 14, height: 1.4);
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
    fontFamily: vigiaFontFamily,
    focusColor: p.focus.withValues(alpha: 0.24),
    splashFactory:
        NoSplash.splashFactory, // B5.2 usa escala 0,98 al pulsar, no ondas.
    textTheme: Typography.material2021().black.apply(
      fontFamily: vigiaFontFamily,
      bodyColor: p.ink,
      displayColor: p.ink,
    ),
    extensions: [VigiaColors(p)],
  );
}

final ThemeData vigiaLightTheme = buildVigiaTheme(VigiaPalette.light);
final ThemeData vigiaDarkTheme = buildVigiaTheme(VigiaPalette.dark);
