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
  final bool isBusy;
  final VoidCallback? onBack;
  final bool accessCover;

  @override
  Widget build(BuildContext context) {
    final p = VigiaColors.of(context);
    return VigiaScaffold(
      title: 'Vigía',
      onBack: onBack,
      background: accessCover ? const ScreenAura() : null,
      contentKey: accessCover ? ValueKey(title) : null,
      footer: Semantics(container: true, liveRegion: isBusy, child: action),
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
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: ExcludeSemantics(
            child: CustomPaint(
              size: const Size(112, 56),
              painter: _EyeMark(ink: p.ink),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          header: true,
          child: VigiaText(
            title,
            style: VigiaType.heroTitle(isLargeText(context) ? 32 : 46)
                .copyWith(color: p.ink),
          ),
        ),
        const SizedBox(height: 10),
        VigiaParagraph(description, secondary: true),
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

class _EyeMark extends CustomPainter {
  const _EyeMark({required this.ink});

  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final line = Paint()
      ..color = ink
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final eye = Path()
      ..moveTo(10, center.dy)
      ..cubicTo(37, 1, 75, 1, 102, center.dy)
      ..cubicTo(75, 55, 37, 55, 10, center.dy)
      ..close();
    canvas.drawPath(eye, line);
    canvas.drawCircle(center, 13, line);
    canvas.drawCircle(center, 5, Paint()..color = ink);
    line.color = ink.withValues(alpha: 0.45);
    canvas.drawLine(Offset(0, center.dy), Offset(6, center.dy), line);
    canvas.drawLine(Offset(106, center.dy), Offset(112, center.dy), line);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, 6), line);
    canvas.drawLine(Offset(center.dx, 50), Offset(center.dx, 56), line);
  }

  @override
  bool shouldRepaint(_EyeMark oldDelegate) => oldDelegate.ink != ink;
}

InputDecoration accountFieldDecoration(
  BuildContext context, {
  required String label,
  String? error,
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
    fillColor: p.surfaceStrong,
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
