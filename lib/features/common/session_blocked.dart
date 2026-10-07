import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/design_system/vigia_icons.dart';
import '../../core/design_system/widgets/vigia_blocks.dart';
import '../../core/design_system/widgets/vigia_button.dart';

/// Contenido de una función bloqueada por sesión vigente (B5.2 `vBLK`,
/// UX §4.2, UX11.CA2): también al llegar por ruta directa.
List<Widget> sessionBlockedBlocks(BuildContext context, String feature) => [
  StatusCard(
    tone: StatusTone.strong,
    icon: VigiaIcon.lock,
    tag: 'Bloqueado',
    title: 'Sesión en curso',
    text:
        '$feature no está disponible mientras haya una sesión vigente, '
        'incluida una pausa. El bloqueo se aplica también al llegar por una '
        'ruta directa.',
  ),
  VigiaButton(
    label: 'Volver al monitoreo',
    onPressed: () => context.go(VigiaRoutes.monitoreo),
  ),
  VigiaButton(
    label: 'Volver al inicio',
    kind: VigiaButtonKind.secondary,
    onPressed: () => context.go(VigiaRoutes.inicio),
  ),
];
