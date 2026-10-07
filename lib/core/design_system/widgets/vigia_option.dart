import 'package:flutter/widgets.dart';

import '../vigia_icons.dart';
import 'vigia_button.dart';

/// Opción de una elección única (`opt` de B5.2: tema, patrón de sonido,
/// filtros). La elegida es un botón principal con marca de verificación; las
/// demás, secundarios. El estado no depende solo del color: lleva icono y,
/// para TalkBack, «marcada» dentro de un grupo excluyente.
class VigiaOption extends StatelessWidget {
  const VigiaOption({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;

  /// Nulo: opción deshabilitada.
  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      enabled: onSelected != null,
      label: label,
      onTap: onSelected,
      excludeSemantics: true,
      child: VigiaButton(
        label: label,
        kind: selected ? VigiaButtonKind.primary : VigiaButtonKind.secondary,
        icon: selected ? VigiaIcon.check : null,
        height: 48,
        onPressed: onSelected,
      ),
    );
  }
}

/// Opciones apiladas con 8 de separación.
class VigiaOptionGroup extends StatelessWidget {
  const VigiaOptionGroup({super.key, required this.options});

  final List<VigiaOption> options;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          options[i],
        ],
      ],
    );
  }
}
