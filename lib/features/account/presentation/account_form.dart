import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/design_system/theme.dart';
import '../../../core/design_system/tokens.dart';
import '../../../core/design_system/widgets/screen_aura.dart';
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
      background: accessCover ? const ScreenAura() : null,
      contentKey: accessCover ? ValueKey(title) : null,
      footer: accessCover ? null : submit,
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
        if (accessCover) ...[submit, ?afterAction],
      ],
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
            style: VigiaType.heroTitle(isLargeText(context) ? 30 : 40)
                .copyWith(color: p.ink),
          ),
        ),
        const SizedBox(height: 10),
        VigiaText(
          description,
          style: VigiaType.body.copyWith(
            color: VigiaAura.screenSecondary(p.brightness),
          ),
        ),
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

InputDecoration accountFieldDecoration(
  BuildContext context, {
  required String label,
  String? error,
  Color? fillColor,
}) {
  final p = VigiaColors.of(context);
  OutlineInputBorder outline(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(VigiaRadius.tag),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return InputDecoration(
    labelText: label,
    labelStyle: VigiaType.body.copyWith(color: p.inkSecondary),
    floatingLabelStyle: VigiaType.body.copyWith(color: p.ink),
    floatingLabelBehavior: FloatingLabelBehavior.always,
    filled: true,
    fillColor: fillColor ?? p.surfaceStrong,
    constraints: const BoxConstraints(minHeight: VigiaSpace.minTap),
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
