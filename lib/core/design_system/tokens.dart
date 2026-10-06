import 'dart:ui' show Brightness;

import 'package:flutter/animation.dart';

/// Tokens visuales de Vigía tomados del prototipo B5.2 (tokens B4.2).
///
/// Fuente: `docs/source/Vigia B5.2 Completo (standalone).html`, constantes
/// `PAL` (claro/oscuro), `AU` (aura), `F()` (tipografía), `mkBtn`, `CARD`,
/// `HERO`, `PAPER`, `KV` y la barra principal. Los nombres cortos de B5.2 se
/// conservan en comentarios para poder contrastarlos con el HTML.
class VigiaPalette {
  const VigiaPalette({
    required this.brightness,
    required this.bg,
    required this.surface,
    required this.surfaceStrong,
    required this.ink,
    required this.inkSecondary,
    required this.line,
    required this.border,
    required this.control,
    required this.focus,
    required this.paper,
    required this.onPaper,
    required this.paperSecondary,
    required this.scrim,
    required this.warnBg,
    required this.warnInk,
    required this.closeBg,
    required this.closeInk,
    required this.neutralBg,
    required this.neutralInk,
    required this.pauseBg,
    required this.pauseInk,
    required this.pendingBg,
    required this.pendingInk,
    required this.errorBg,
    required this.errorInk,
    required this.navBg,
    required this.navInk,
    required this.navSelectedBg,
    required this.navSelectedInk,
  });

  final Brightness brightness;
  final Color bg; // bg
  final Color surface; // sf
  final Color surfaceStrong; // sfs
  final Color ink; // ink
  final Color inkSecondary; // i2
  final Color line; // ln
  final Color border; // bd
  final Color control; // ctl
  final Color focus; // fc
  final Color paper; // pp
  final Color onPaper; // onp
  final Color paperSecondary; // pps
  final Color scrim; // scrim
  final Color warnBg; // wb  (advertencia)
  final Color warnInk; // wt
  final Color closeBg; // cb  (cierre ocular)
  final Color closeInk; // ct
  final Color neutralBg; // nb  (no evaluable / estado)
  final Color neutralInk; // nt
  final Color pauseBg; // pb
  final Color pauseInk; // pt
  final Color pendingBg; // ob  (operación pendiente)
  final Color pendingInk; // ot
  final Color errorBg; // eb  (alerta técnica / registro)
  final Color errorInk; // et
  final Color navBg; // dk  (barra principal)
  final Color navInk; // dkt
  final Color navSelectedBg; // dks
  final Color navSelectedInk; // dkst

  static const light = VigiaPalette(
    brightness: Brightness.light,
    bg: Color(0xFFFBFAF7),
    surface: Color(0xFFFFFFFF),
    surfaceStrong: Color(0xFFF0EEEB),
    ink: Color(0xFF111111),
    inkSecondary: Color(0xFF595954),
    line: Color(0xFFD6D4CE),
    border: Color(0xFF74746C),
    control: Color(0xFF74746C),
    focus: Color(0xFF57439A),
    paper: Color(0xFFFFFFFF),
    onPaper: Color(0xFF111111),
    paperSecondary: Color(0xFF595954),
    scrim: Color(0x7A000000), // rgba(0,0,0,.48)
    warnBg: Color(0xFFFFE4A8),
    warnInk: Color(0xFF3A2800),
    closeBg: Color(0xFFFFD5CE),
    closeInk: Color(0xFF821D17),
    neutralBg: Color(0xFFEAE6E0),
    neutralInk: Color(0xFF38342F),
    pauseBg: Color(0xFFE8DFFA),
    pauseInk: Color(0xFF3F285F),
    pendingBg: Color(0xFFDCEBF7),
    pendingInk: Color(0xFF233C50),
    errorBg: Color(0xFFFFE0D8),
    errorInk: Color(0xFF78231C),
    navBg: Color(0xFF111111),
    navInk: Color(0xFFFAFAF7),
    navSelectedBg: Color(0xFFFFFFFF),
    navSelectedInk: Color(0xFF111111),
  );

  /// Tema oscuro «grafito violeta» de B4.2.
  static const dark = VigiaPalette(
    brightness: Brightness.dark,
    bg: Color(0xFF24232B),
    surface: Color(0xFF302E39),
    surfaceStrong: Color(0xFF3B3845),
    ink: Color(0xFFF7F5FA),
    inkSecondary: Color(0xFFCEC9D5),
    line: Color(0xFF555061),
    border: Color(0xFF9A95A8),
    control: Color(0xFF9A95A8),
    focus: Color(0xFFDEC9FF),
    paper: Color(0xFFF7F5F0),
    onPaper: Color(0xFF111111),
    paperSecondary: Color(0xFF595954),
    scrim: Color(0xA30A0810), // rgba(10,8,16,.64)
    warnBg: Color(0xFF4A3606),
    warnInk: Color(0xFFFFE4A8),
    closeBg: Color(0xFF5A1F1A),
    closeInk: Color(0xFFFFE3DD),
    neutralBg: Color(0xFF433F4F),
    neutralInk: Color(0xFFF7F5FA),
    pauseBg: Color(0xFF3A2D52),
    pauseInk: Color(0xFFECDDFF),
    pendingBg: Color(0xFF2B3A4E),
    pendingInk: Color(0xFFDAEFFF),
    errorBg: Color(0xFF4A2622),
    errorInk: Color(0xFFFFE3DC),
    navBg: Color(0xFF3B3845),
    navInk: Color(0xFFCEC9D5),
    navSelectedBg: Color(0xFFF7F5FA),
    navSelectedInk: Color(0xFF24232B),
  );
}

/// Colores del aura pastel (B5.2 `AU`); iguales en ambos temas.
abstract final class VigiaAura {
  static const lilac = Color(0xFFCDB4FF);
  static const lime = Color(0xFFE7FFA6);
  static const sky = Color(0xFFBEEBFF);
  static const pink = Color(0xFFFFD1E8);
  static const white = Color(0xFFFFFEFA);

  /// Texto sobre aura (`color.on-aura`, `color.on-aura-secondary`).
  static const onAura = Color(0xFF111111);
  static const onAuraSecondary = Color(0xFF4E4C50);

  /// Botón principal sobre aura (`heroBtn`): colores fijos en ambos temas.
  static const ctaBg = Color(0xFF111111);
  static const ctaInk = Color(0xFFFFFFFF);

  /// Borde del botón secundario sobre papel (`PAPER`).
  static const paperButtonBorder = Color(0xFF74746C);
}

/// Medidas de B5.2 en unidades lógicas.
abstract final class VigiaSpace {
  static const screenH = 20.0; // padding horizontal del contenido
  static const screenTop = 12.0;
  static const screenBottom = 24.0;
  static const gap = 16.0; // separación entre bloques
  static const cardPadding = 20.0;
  static const heroPadding = 24.0;
  static const minTap = 48.0;
  static const primaryButtonHeight = 56.0;
  static const secondaryButtonHeight = 48.0;
  static const headerMinHeight = 64.0;
  static const navItemMinHeight = 56.0;
}

abstract final class VigiaRadius {
  static const hero = 32.0;
  static const card = 28.0;
  static const button = 28.0;
  static const navBar = 36.0;
  static const navItem = 28.0;
  static const toast = 20.0;
  static const tag = 14.0;
  static const demoLabel = 12.0;
}

/// Movimiento de B5.2.
abstract final class VigiaMotion {
  /// `cubic-bezier(.22,1,.36,1)` de botones y barra (110 ms al pulsar).
  static const Curve press = Cubic(0.22, 1, 0.36, 1);
  static const pressDuration = Duration(milliseconds: 110);
  static const colorDuration = Duration(milliseconds: 180);

  /// Aura de `HERO`: `vgA1`/`vgA2`/`vgC`, 6 s, ease-in-out, una iteración.
  static const auraDuration = Duration(seconds: 6);
  static const Curve auraCurve = Cubic(0.42, 0, 0.58, 1); // ease-in-out CSS
  static const pressScale = 0.98;
  static const toastDuration = Duration(seconds: 4);
}
