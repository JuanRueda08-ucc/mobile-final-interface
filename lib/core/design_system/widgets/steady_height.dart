import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../tokens.dart';

/// Contenedor cuyo alto solo crece mientras se muestra.
///
/// Evita que un bloque que cambia de texto (por ejemplo, el estado de la
/// sesión en P06) encoja y estire lo que tiene debajo en cada cambio. Recuerda
/// el alto máximo alcanzado y lo usa como mínimo; el crecimiento se anima (sin
/// animación con movimiento reducido). Se reinicia si cambia [resetKey], el
/// ancho de la pantalla o la escala del texto.
class SteadyHeight extends StatefulWidget {
  const SteadyHeight({super.key, required this.child, this.resetKey});

  final Widget child;
  final Object? resetKey;

  @override
  State<SteadyHeight> createState() => _SteadyHeightState();
}

class _SteadyHeightState extends State<SteadyHeight> {
  double _min = 0;
  double? _width;
  double? _scale;

  @override
  void didUpdateWidget(SteadyHeight old) {
    super.didUpdateWidget(old);
    if (old.resetKey != widget.resetKey) _min = 0;
  }

  void _measured(Size size) {
    if (size.height <= _min + 0.5) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted && size.height > _min + 0.5) {
        setState(() => _min = size.height);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scale = MediaQuery.textScalerOf(context).scale(16);
    if (_width != width || _scale != scale) {
      _width = width;
      _scale = scale;
      _min = 0;
    }
    return AnimatedContainer(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : VigiaMotion.colorDuration,
      curve: VigiaMotion.press,
      constraints: BoxConstraints(minHeight: _min),
      child: _SizeReporter(onSize: _measured, child: widget.child),
    );
  }
}

class _SizeReporter extends SingleChildRenderObjectWidget {
  const _SizeReporter({required this.onSize, super.child});

  final ValueChanged<Size> onSize;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderSizeReporter(onSize);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSizeReporter renderObject,
  ) {
    renderObject.onSize = onSize;
  }
}

class _RenderSizeReporter extends RenderProxyBox {
  _RenderSizeReporter(this.onSize);

  ValueChanged<Size> onSize;

  @override
  void performLayout() {
    super.performLayout();
    onSize(size);
  }
}
