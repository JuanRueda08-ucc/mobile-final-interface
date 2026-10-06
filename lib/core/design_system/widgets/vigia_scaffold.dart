import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens.dart';
import '../vigia_icons.dart';
import 'vigia_button.dart';
import 'vigia_text.dart';

/// Rótulo visible de simulación (RF32): «DEMO — datos simulados».
class DemoLabel extends StatelessWidget {
  const DemoLabel({super.key});

  static const text = 'DEMO — datos simulados';

  @override
  Widget build(BuildContext context) {
    final p = VigiaColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: p.surfaceStrong,
        borderRadius: BorderRadius.circular(VigiaRadius.demoLabel),
      ),
      child: Text(text, style: VigiaType.demoLabel.copyWith(color: p.ink)),
    );
  }
}

/// Destino de la barra principal (Inicio, Historial, Ajustes; UX §2.1).
class VigiaNavDestination {
  const VigiaNavDestination(this.label, this.icon);

  final String label;
  final VigiaIcon icon;
}

const vigiaNavDestinations = [
  VigiaNavDestination('Inicio', VigiaIcon.home),
  VigiaNavDestination('Historial', VigiaIcon.history),
  VigiaNavDestination('Ajustes', VigiaIcon.settings),
];

/// Estructura de pantalla de B5.2:
/// - encabezado (mín. 64, título 22/500);
/// - rótulo DEMO opcional;
/// - contenido desplazable (márgenes 12/20/24, separación 16 entre bloques);
/// - barra principal opcional;
/// - aviso temporal sobre el contenido.
class VigiaScaffold extends StatelessWidget {
  const VigiaScaffold({
    super.key,
    required this.title,
    required this.children,
    this.isDemo = false,
    this.navIndex,
    this.onNavSelected,
    this.notice,
    this.onBack,
  });

  final String title;
  final List<Widget> children;
  final bool isDemo;

  /// Índice del destino actual; nulo si la pantalla no muestra barra (P04–P06).
  final int? navIndex;
  final ValueChanged<int>? onNavSelected;

  /// Texto del aviso temporal visible, si lo hay.
  final String? notice;

  /// Acción de «‹ Volver» del encabezado (P04–P07). Nula: sin botón.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final p = VigiaColors.of(context);
    final heading = Semantics(
      header: true,
      child: Text(title, style: VigiaType.appBarTitle.copyWith(color: p.ink)),
    );
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: VigiaSpace.headerMinHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: onBack == null
                    ? Align(alignment: Alignment.centerLeft, child: heading)
                    : Row(
                        children: [
                          VigiaBackButton(onPressed: onBack!),
                          const SizedBox(width: 10),
                          Expanded(child: heading),
                        ],
                      ),
              ),
            ),
            if (isDemo)
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: DemoLabel(),
                ),
              ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: SingleChildScrollView(
                      // Con texto ampliado el margen lateral baja de 20 a 16 para ganar ancho.
                      padding: EdgeInsets.fromLTRB(
                        isLargeText(context) ? 16 : VigiaSpace.screenH,
                        VigiaSpace.screenTop,
                        isLargeText(context) ? 16 : VigiaSpace.screenH,
                        VigiaSpace.screenBottom,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < children.length; i++) ...[
                            if (i > 0) const SizedBox(height: VigiaSpace.gap),
                            children[i],
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (notice != null)
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 12,
                      child: VigiaNotice(text: notice!),
                    ),
                ],
              ),
            ),
            if (navIndex != null)
              VigiaBottomNav(
                currentIndex: navIndex!,
                onSelected: onNavSelected ?? (_) {},
              ),
          ],
        ),
      ),
    );
  }
}

/// «‹ Volver» del encabezado de B5.2: círculo de 48, fondo `sfs`, chevrón 24.
class VigiaBackButton extends StatelessWidget {
  const VigiaBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final p = VigiaColors.of(context);
    return Semantics(
      button: true,
      label: 'Volver',
      excludeSemantics: true,
      onTap: onPressed,
      child: PressScale(
        child: Material(
          color: p.surfaceStrong,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: const Key('vigia-back'),
            onTap: onPressed,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            focusColor: p.focus.withValues(alpha: 0.24),
            child: SizedBox.square(
              dimension: VigiaSpace.minTap,
              child: Center(child: VigiaIconView(VigiaIcon.back, color: p.ink)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Aviso temporal (`toast` de B5.2): fondo tinta, texto fondo, radio 20.
class VigiaNotice extends StatelessWidget {
  const VigiaNotice({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = VigiaColors.of(context);
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        key: const Key('vigia-notice'),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: p.ink,
          borderRadius: BorderRadius.circular(VigiaRadius.toast),
        ),
        child: Text(text, style: VigiaType.toast.copyWith(color: p.bg)),
      ),
    );
  }
}

/// Barra principal (B5.2): pastilla oscura con tres destinos de 56 de alto mínimo.
///
/// Texto al 200 %: B5.2 limitaba la etiqueta al 135 %, lo que incumple RNF03.CA1
/// y UX22.CA1 (OI-04). Aquí la etiqueta escala sin tope. Si las tres etiquetas
/// no caben en horizontal sin cortarse, la barra pasa a una lista vertical
/// dentro de la misma pastilla: cada destino sigue completo y con área táctil
/// ≥ 48.
class VigiaBottomNav extends StatelessWidget {
  const VigiaBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final p = VigiaColors.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.navBg,
        borderRadius: BorderRadius.circular(VigiaRadius.navBar),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          const gap = 4.0;
          final perItem =
              (box.maxWidth - 2 * gap) / vigiaNavDestinations.length;
          final fitsRow = vigiaNavDestinations.every((d) {
            final tp = TextPainter(
              text: TextSpan(text: d.label, style: VigiaType.navLabel),
              textDirection: TextDirection.ltr,
              textScaler: scaler,
              maxLines: 1,
            )..layout();
            return tp.width + 4 <= perItem; // padding horizontal 2 + 2
          });
          final items = [
            for (var i = 0; i < vigiaNavDestinations.length; i++)
              _NavItem(
                destination: vigiaNavDestinations[i],
                selected: i == currentIndex,
                vertical: !fitsRow,
                onTap: () => onSelected(i),
              ),
          ];
          return fitsRow
              ? Row(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0) const SizedBox(width: gap),
                      Expanded(child: items[i]),
                    ],
                  ],
                )
              : Column(
                  key: const Key('nav-vertical'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0) const SizedBox(height: gap),
                      items[i],
                    ],
                  ],
                );
        },
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.vertical,
    required this.onTap,
  });

  final VigiaNavDestination destination;
  final bool selected;
  final bool vertical;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = VigiaColors.of(context);
    final reduce = MediaQuery.disableAnimationsOf(context);
    final fg = selected ? p.navSelectedInk : p.navInk;
    final label = Text(
      destination.label,
      textAlign: vertical ? TextAlign.start : TextAlign.center,
      style: VigiaType.navLabel.copyWith(color: fg),
    );
    final icon = VigiaIconView(destination.icon, size: 22, color: fg);
    // Un solo nodo semántico por destino: etiqueta, estado seleccionado y la
    // misma acción que el toque. `excludeSemantics` evita el doble anuncio del
    // texto y del InkWell, pero también ocultaría su acción, así que `onTap`
    // se expone aquí para que TalkBack pueda activar el destino.
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      onTap: onTap,
      excludeSemantics: true,
      child: PressScale(
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(VigiaRadius.navItem),
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            focusColor: p.focus.withValues(alpha: 0.32),
            child: AnimatedContainer(
              duration: reduce ? Duration.zero : VigiaMotion.colorDuration,
              alignment: vertical ? Alignment.centerLeft : Alignment.center,
              constraints: const BoxConstraints(
                minHeight: VigiaSpace.navItemMinHeight,
                minWidth: VigiaSpace.minTap,
              ),
              padding: vertical
                  ? const EdgeInsets.symmetric(horizontal: 16, vertical: 6)
                  : const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? p.navSelectedBg : Colors.transparent,
                borderRadius: BorderRadius.circular(VigiaRadius.navItem),
              ),
              child: vertical
                  ? Row(
                      children: [
                        icon,
                        const SizedBox(width: 12),
                        Expanded(child: label),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [icon, const SizedBox(height: 2), label],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
