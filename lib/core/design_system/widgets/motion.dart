import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../tokens.dart';

/// Movimiento de Vigía (prueba física, 2026-11-15: la app se veía plana).
///
/// Todas las animaciones son finitas y desaparecen con movimiento reducido
/// (`MediaQuery.disableAnimations`).

/// Entrada de un bloque de pantalla: fundido y desplazamiento corto hacia
/// arriba, una sola vez al aparecer. [index] escalona la entrada (25 ms por
/// bloque, hasta 6 bloques).
class EntranceItem extends StatefulWidget {
  const EntranceItem({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  static const _step = Duration(milliseconds: 25);
  static const _run = Duration(milliseconds: 260);

  @override
  State<EntranceItem> createState() => _EntranceItemState();
}

class _EntranceItemState extends State<EntranceItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    final delay = EntranceItem._step * math.min(widget.index, 6);
    final total = delay + EntranceItem._run;
    _c = AnimationController(vsync: this, duration: total);
    _t = CurvedAnimation(
      parent: _c,
      curve: Interval(
        delay.inMicroseconds / total.inMicroseconds,
        1,
        curve: VigiaMotion.press,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else if (_c.value == 0 && !_c.isAnimating) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Conserva el estado del contenido (foco, texto, desplazamiento) cuando
  /// se retiran los envoltorios al terminar la entrada.
  final _content = GlobalKey();

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _t,
    child: KeyedSubtree(key: _content, child: widget.child),
    builder: (context, child) => _t.value >= 1
        ? child!
        : Opacity(
            opacity: _t.value,
            child: Transform.translate(
              offset: Offset(0, 14 * (1 - _t.value)),
              child: child,
            ),
          ),
  );
}

/// Late [times] veces (escala 1 → 1,14 → 1) al montarse o al cambiar
/// [trigger]. Para llamar la atención sobre un aviso sin repetir sin fin.
class PulseOnce extends StatefulWidget {
  const PulseOnce({
    super.key,
    required this.child,
    this.trigger,
    this.times = 3,
  });

  final Widget child;
  final Object? trigger;
  final int times;

  @override
  State<PulseOnce> createState() => _PulseOnceState();
}

class _PulseOnceState extends State<PulseOnce>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 520 * widget.times),
  );

  void _start() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else {
      _c.forward(from: 0);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.value == 0 && !_c.isAnimating) _start();
  }

  @override
  void didUpdateWidget(PulseOnce old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) _start();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    child: widget.child,
    builder: (context, child) {
      final beat = math.sin(math.pi * ((_c.value * widget.times) % 1));
      return Transform.scale(
        scale: _c.value >= 1 ? 1 : 1 + 0.14 * beat,
        child: child,
      );
    },
  );
}

/// Cambio de icono con un pequeño rebote de escala y fundido.
class PopSwitcher extends StatelessWidget {
  const PopSwitcher({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 260),
    switchInCurve: Curves.easeOutBack,
    switchOutCurve: Curves.easeIn,
    transitionBuilder: (child, animation) => FadeTransition(
      opacity: animation,
      child: ScaleTransition(scale: animation, child: child),
    ),
    child: child,
  );
}
