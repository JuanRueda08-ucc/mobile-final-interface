import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/design_system/theme.dart';
import '../../../core/design_system/tokens.dart';
import '../../../core/design_system/vigia_icons.dart';
import '../../../core/design_system/widgets/vigia_blocks.dart';
import '../../../core/design_system/widgets/vigia_button.dart';
import '../../../core/design_system/widgets/vigia_flow_blocks.dart';
import '../../../core/design_system/widgets/vigia_scaffold.dart';
import '../../../core/design_system/widgets/vigia_text.dart';

class AccountForm extends StatelessWidget {
  const AccountForm({
    super.key,
    required this.title,
    required this.description,
    required this.action,
    required this.children,
    this.afterAction,
    this.bottom,
    this.detail,
    this.isBusy = false,
    this.onBack,
    this.accessCover = false,
  });

  final String title;
  final String description;
  final String? detail;
  final VigiaButton action;
  final List<Widget> children;
  final Widget? afterAction;

  /// Enlace fijo abajo del todo (acceso, 2026-11-16).
  final Widget? bottom;
  final bool isBusy;
  final VoidCallback? onBack;
  final bool accessCover;

  @override
  Widget build(BuildContext context) {
    final p = VigiaColors.of(context);
    final submit = Semantics(
      container: true,
      liveRegion: isBusy,
      child: action,
    );
    return VigiaScaffold(
      title: 'Vigía',
      showBrandMark: true,
      onBack: onBack,
      // Acceso limpio (usuario, 2026-11-16): sin fondo de colores ni
      // tarjeta; título, campos, botón y enlaces con aire.
      contentKey: accessCover ? ValueKey(title) : null,
      // Con texto ampliado el enlace de abajo se desplaza con el resto
      // para dejar sitio al formulario.
      footer: accessCover ? (isLargeText(context) ? null : bottom) : submit,
      children: [
        if (accessCover)
          _AccessCover(title: title, description: description)
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              VigiaHeading(title),
              VigiaParagraph(description),
              if (detail case final text?)
                Text(text, style: VigiaType.kvValue.copyWith(color: p.ink)),
            ],
          ),
        ...children,
        if (accessCover) ...[
          submit,
          ?afterAction,
          if (isLargeText(context)) ?bottom,
        ],
      ],
    );
  }
}

/// Tarjeta del acceso: superficie elevada con borde suave.
class AccountCard extends StatelessWidget {
  const AccountCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = VigiaColors.of(context);
    final dark = p.brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(isLargeText(context) ? 16 : 20),
      decoration: BoxDecoration(
        color: dark ? p.surface : Colors.white,
        borderRadius: BorderRadius.circular(VigiaRadius.card),
        border: Border.all(color: p.line),
        boxShadow: dark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
      ),
      child: child,
    );
  }
}

class _AccessCover extends StatelessWidget {
  const _AccessCover({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final p = VigiaColors.of(context);
    final intro = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: VigiaText(
            title,
            style: VigiaType.heroTitle(isLargeText(context) ? 28 : 34)
                .copyWith(color: p.ink),
          ),
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 8),
          VigiaText(
            description,
            style: VigiaType.body.copyWith(color: p.inkSecondary),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
    if (MediaQuery.disableAnimationsOf(context)) return intro;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: VigiaMotion.press,
      child: intro,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - value)),
          child: child,
        ),
      ),
    );
  }
}

/// Campo del acceso (2026-11-15): la etiqueta va encima, fuera del borde, y
/// el campo lleva el icono centrado y un texto de ejemplo.
class AccountField extends StatelessWidget {
  const AccountField({super.key, required this.label, required this.field});

  final String label;
  final Widget field;

  @override
  Widget build(BuildContext context) {
    final p = VigiaColors.of(context);
    // Con texto ampliado la etiqueta va dentro del borde
    // ([accountFieldDecoration]) para que el formulario quepa.
    if (isLargeText(context)) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: 4),
            child: VigiaText(
              label,
              style: VigiaType.smallIndicator.copyWith(color: p.ink),
            ),
          ),
        ),
        Semantics(label: label, child: field),
      ],
    );
  }
}

InputDecoration accountFieldDecoration(
  BuildContext context, {
  required String label,
  String? error,
  Color? fillColor,
  VigiaIcon? icon,
  Widget? suffix,
  String? helper,
  String? hint,
}) {
  final p = VigiaColors.of(context);
  OutlineInputBorder outline(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(VigiaRadius.tag),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  // Con [hint], la etiqueta va fuera del campo ([AccountField]).
  final outside = hint != null && !isLargeText(context);
  return InputDecoration(
    labelText: outside ? null : label,
    hintText: outside ? hint : null,
    hintStyle: VigiaType.body.copyWith(color: p.inkSecondary),
    contentPadding: outside
        ? const EdgeInsetsDirectional.fromSTEB(4, 16, 12, 16)
        : null,
    labelStyle: VigiaType.body.copyWith(color: p.inkSecondary),
    floatingLabelStyle: VigiaType.body.copyWith(color: p.ink),
    floatingLabelBehavior: FloatingLabelBehavior.always,
    filled: true,
    fillColor: fillColor ?? p.surfaceStrong,
    constraints: const BoxConstraints(minHeight: VigiaSpace.minTap),
    prefixIcon: icon == null
        ? null
        : Padding(
            padding: const EdgeInsetsDirectional.only(start: 16, end: 8),
            child: VigiaIconView(icon, size: 22, color: p.inkSecondary),
          ),
    prefixIconConstraints: const BoxConstraints(minWidth: 46, minHeight: 22),
    suffixIcon: suffix,
    helperText: helper,
    helperStyle: VigiaType.small.copyWith(color: p.inkSecondary),
    helperMaxLines: 2,
    border: outline(p.control),
    enabledBorder: outline(p.control),
    focusedBorder: outline(p.focus, width: 2),
    errorBorder: outline(p.errorInk),
    focusedErrorBorder: outline(p.errorInk, width: 2),
    error: error == null
        ? null
        : _AccountFieldError(key: ValueKey(error), text: error),
  );
}

class _AccountFieldError extends StatefulWidget {
  const _AccountFieldError({super.key, required this.text});

  final String text;

  @override
  State<_AccountFieldError> createState() => _AccountFieldErrorState();
}

class _AccountFieldErrorState extends State<_AccountFieldError> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Scrollable.ensureVisible(context, alignment: 0.5);
    });
  }

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    container: true,
    child: VigiaText(
      widget.text,
      style: VigiaType.small.copyWith(color: VigiaColors.of(context).errorInk),
    ),
  );
}

// El estado inyectado bloquea la operación mientras está en curso. Este
// guard cubre el intervalo anterior al rebuild, incluso si se usa el IME.
class AccountRequestGate {
  bool _dispatched = false;

  void run(VoidCallback action) {
    if (_dispatched) return;
    _dispatched = true;
    SchedulerBinding.instance.addPostFrameCallback((_) => _dispatched = false);
    SchedulerBinding.instance.ensureVisualUpdate();
    action();
  }
}
