import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme.dart';
import '../tokens.dart';
import '../vigia_icons.dart';
import 'vigia_button.dart';
import 'vigia_mark.dart';
import 'vigia_side_nav_item.dart';
import 'vigia_text.dart';
import 'motion.dart';

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
/// - encabezado (mín. 64, título 22);
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
    this.sideNavigation = false,
    this.accountDestination = false,
    this.notice,
    this.onBack,
    this.background,
    this.showBrandMark = false,
    this.pinnedContent,
    this.footer,
    this.contentKey,
  });

  final String title;
  final List<Widget> children;
  final bool isDemo;

  /// Índice del destino actual; nulo si la pantalla no muestra barra (P04–P06).
  final int? navIndex;
  final ValueChanged<int>? onNavSelected;
  final bool sideNavigation;
  final bool accountDestination;

  /// Texto del aviso temporal visible, si lo hay.
  final String? notice;

  /// Acción de «‹ Volver» del encabezado (P04–P07). Nula: sin botón.
  final VoidCallback? onBack;

  /// Fondo decorativo detrás de toda la pantalla, incluida su área segura.
  final Widget? background;

  final bool showBrandMark;

  /// Contenido que permanece visible sobre el cuerpo desplazable.
  final LayoutWidgetBuilder? pinnedContent;

  /// Acción del paso actual, fuera del desplazamiento.
  final Widget? footer;

  /// Reinicia el desplazamiento cuando cambia el paso del recorrido.
  final Key? contentKey;

  @override
  Widget build(BuildContext context) {
    final p = VigiaColors.of(context);
    // El texto ampliado puede partir por sílabas si una palabra no cabe.
    final brandInk = p.brightness == Brightness.dark
        ? VigiaBrand.wordmarkDark
        : VigiaBrand.wordmarkLight;
    final titleText = VigiaText(
      title,
      style: showBrandMark
          ? VigiaType.wordmark.copyWith(color: brandInk)
          : VigiaType.appBarTitle.copyWith(color: p.ink),
    );
    final heading = Semantics(
      header: true,
      child: showBrandMark
          ? Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 7,
              children: [
                VigiaMark(size: 31, ink: brandInk),
                Flexible(child: titleText),
              ],
            )
          : titleText,
    );
    final inset = isLargeText(context) ? 16.0 : VigiaSpace.screenH;
    final scroll = Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            key: contentKey,
            padding: EdgeInsets.fromLTRB(
              inset,
              VigiaSpace.screenTop,
              inset,
              VigiaSpace.screenBottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: VigiaSpace.gap,
              // Entrada escalonada de los bloques al abrir la pantalla.
              children: [
                for (final (i, child) in children.indexed)
                  EntranceItem(
                    key: child.key == null ? null : ValueKey(child.key),
                    index: i,
                    child: child,
                  ),
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
    );
    final pinned = pinnedContent;
    final side = sideNavigation && navIndex != null;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Barra lateral (usuario, 2026-11-16): cerrada solo se ve ≡; al
        // tocarlo entra deslizando un panel con iconos y nombres, sin
        // oscurecer la pantalla. Otro toque lo esconde.
        void select(int index) => onNavSelected?.call(index);
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: VigiaSpace.headerMinHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: side
                    // Hueco para ≡, que dibuja la barra encima.
                    ? Row(
                        children: [
                          const SizedBox(width: 56),
                          Expanded(child: heading),
                        ],
                      )
                    : onBack == null
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
              child: pinned == null
                  ? scroll
                  : LayoutBuilder(
                      builder: (context, constraints) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          pinned(context, constraints),
                          Expanded(child: scroll),
                        ],
                      ),
                    ),
            ),
            if (footer case final action?)
              ColoredBox(
                color: p.bg,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: action,
                ),
              ),
            if (navIndex != null && !side)
              VigiaBottomNav(
                currentIndex: navIndex!,
                onSelected: onNavSelected ?? (_) {},
              ),
          ],
        );
        final body = SafeArea(
          child: side
              ? _SideRail(
                  currentIndex: navIndex!,
                  accountDestination: accountDestination,
                  maxWidth: constraints.maxWidth,
                  onSelected: select,
                  content: content,
                )
              : content,
        );
        return Scaffold(
          backgroundColor: p.bg,
          body: background == null
              ? body
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    IgnorePointer(child: background),
                    body,
                  ],
                ),
        );
      },
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

/// Barra lateral: ≡ arriba a la izquierda; al tocarlo, un panel con los
/// destinos (icono y nombre) entra deslizando sobre la pantalla, sin capa
/// oscura. Otro toque en ≡, fuera del panel o en un destino lo esconde.
class _SideRail extends StatefulWidget {
  const _SideRail({
    required this.currentIndex,
    required this.accountDestination,
    required this.maxWidth,
    required this.onSelected,
    required this.content,
  });

  final int currentIndex;
  final bool accountDestination;
  final double maxWidth;
  final ValueChanged<int> onSelected;
  final Widget content;

  @override
  State<_SideRail> createState() => _SideRailState();
}

class _SideRailState extends State<_SideRail>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  );
  late final Animation<Offset> _slide = Tween(
    begin: const Offset(-1, 0),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _c, curve: VigiaMotion.press));

  bool get _open =>
      _c.status == AnimationStatus.forward ||
      _c.status == AnimationStatus.completed;

  void _toggle() {
    final reduce = MediaQuery.disableAnimationsOf(context);
    setState(() {
      if (_open) {
        reduce ? _c.value = 0 : _c.reverse();
      } else {
        reduce ? _c.value = 1 : _c.forward();
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = VigiaColors.of(context);
    final destinations = [
      ...vigiaNavDestinations,
      if (widget.accountDestination)
        const VigiaNavDestination('Cuenta', VigiaIcon.account),
    ];
    final width = (widget.maxWidth * 0.68).clamp(200.0, 260.0);
    final panel = SlideTransition(
      position: _slide,
      child: Semantics(
        container: true,
        label: 'Navegación principal',
        explicitChildNodes: true,
        child: ClipRRect(
          borderRadius: const BorderRadius.horizontal(
            right: Radius.circular(28),
          ),
          // Vidrio sobre el aura: el fondo se ve difuminado, sin tapar el
          // color de la pantalla.
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              key: const Key('vigia-side-nav'),
              width: width,
              decoration: BoxDecoration(
                color: p.bg.withValues(alpha: 0.62),
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(28),
                ),
                border: Border.all(color: p.line.withValues(alpha: 0.6)),
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 72, 12, 16),
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 6,
                    children: [
                      for (var i = 0; i < destinations.length; i++)
                        VigiaSideNavItem(
                          key: ValueKey('nav-${destinations[i].label}'),
                          label: destinations[i].label,
                          icon: destinations[i].icon,
                          selected: i == widget.currentIndex,
                          expanded: true,
                          onTap: () {
                            _c.value = 0;
                            setState(() {});
                            widget.onSelected(i);
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(child: widget.content),
        AnimatedBuilder(
          animation: _c,
          builder: (context, child) => _c.value == 0
              ? const Positioned(left: 0, top: 0, child: SizedBox.shrink())
              : Positioned.fill(
                  child: Stack(
                    children: [
                      // Tocar fuera cierra; sin capa oscura.
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _toggle,
                          child: const SizedBox.expand(),
                        ),
                      ),
                      Positioned(left: 0, top: 0, bottom: 0, child: panel),
                    ],
                  ),
                ),
        ),
        Positioned(
          left: 12,
          top: 8,
          child: IconButton(
            tooltip: _open ? 'Cerrar navegación' : 'Abrir navegación',
            constraints: const BoxConstraints.tightFor(width: 48, height: 48),
            onPressed: _toggle,
            icon: VigiaIconView(
              _open ? VigiaIcon.close : VigiaIcon.menu,
              color: p.ink,
            ),
          ),
        ),
      ],
    );
  }
}
