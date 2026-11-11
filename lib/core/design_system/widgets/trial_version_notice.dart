import 'package:flutter/material.dart';

import '../theme.dart';
import 'vigia_blocks.dart';
import 'vigia_text.dart';

class TrialVersionNotice extends StatelessWidget {
  const TrialVersionNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = VigiaColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        Semantics(
          header: true,
          child: VigiaText(
            'Versión de prueba',
            style: VigiaType.kvValue.copyWith(color: colors.ink),
          ),
        ),
        const VigiaParagraph(
          'La detección usa valores candidatos pendientes de validación. '
          'Vigía no es una ayuda validada para conducir.',
          secondary: true,
        ),
      ],
    );
  }
}
