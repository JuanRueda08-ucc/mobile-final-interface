import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/design_system/vigia_icons.dart';
import '../../core/design_system/widgets/vigia_blocks.dart';
import '../../core/design_system/widgets/vigia_button.dart';
import '../../core/design_system/widgets/vigia_scaffold.dart';
import '../experimental/experimental_monitoring_controller.dart';
import 'cloud_sessions.dart';
import 'firebase_account.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  bool _busy = false;
  String? _feedback;

  Future<void> _signOut() async {
    final auth = ref.read(firebaseAuthProvider);
    if (_busy || auth == null) return;
    setState(() {
      _busy = true;
      _feedback = null;
    });
    String? feedback;
    try {
      feedback = await signOutOfVigia(ref, auth);
    } catch (_) {
      feedback = 'No se pudo cerrar sesión. Vuelve a intentar.';
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _feedback = feedback;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(firebaseUserProvider).asData?.value;
    final uid = ref.watch(verifiedFirebaseUidProvider);
    final monitoring = ref.watch(experimentalMonitoringProvider);
    final locked = monitoring.sessionVigente || monitoring.pending != null;
    void home() => context.go(VigiaRoutes.inicio);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) home();
      },
      child: VigiaScaffold(
        title: 'Cuenta',
        navIndex: 3,
        sideNavigation: true,
        accountDestination: true,
        onNavSelected: (i) {
          if (i == 0) home();
          if (i == 1) context.go(VigiaRoutes.historial);
          if (i == 2) context.go(VigiaRoutes.ajustes);
        },
        children: [
          const VigiaSectionTitle('Correo'),
          VigiaParagraph(user?.email ?? 'Correo no disponible'),
          if (uid != null) ...[
            const StatusCard(
              tone: StatusTone.plain,
              icon: VigiaIcon.check,
              tag: 'Verificación',
              title: 'Correo verificado',
            ),
            _HistorySyncStatus(uid: uid),
          ],
          if (_feedback case final feedback?)
            Semantics(liveRegion: true, child: VigiaParagraph(feedback))
          else if (locked)
            const VigiaParagraph(
              'Finaliza el monitoreo antes de cerrar sesión.',
              secondary: true,
            ),
          VigiaButton(
            label: _busy ? 'Cerrando sesión…' : 'Cerrar sesión',
            kind: VigiaButtonKind.secondary,
            onPressed: locked || _busy || uid == null ? null : _signOut,
          ),
        ],
      ),
    );
  }
}

class _HistorySyncStatus extends ConsumerWidget {
  const _HistorySyncStatus({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upload = ref.watch(cloudSessionUploadProvider(uid));
    final (icon, title) = switch (upload) {
      AsyncValue(isLoading: true) => (VigiaIcon.refresh, 'Sincronizando…'),
      AsyncValue(hasError: true) => (VigiaIcon.info, 'Envío pendiente'),
      _ => (VigiaIcon.check, 'Sin envíos pendientes'),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        StatusCard(
          tone: upload.hasError ? StatusTone.neutral : StatusTone.plain,
          icon: icon,
          tag: 'Sincronización del historial',
          title: title,
          text: upload.hasError
              ? 'Los registros se conservan en este teléfono.'
              : null,
        ),
        if (upload.hasError && !upload.isLoading)
          VigiaButton(
            label: 'Reintentar envío',
            kind: VigiaButtonKind.secondary,
            onPressed: () => ref.invalidate(cloudSessionUploadProvider(uid)),
          ),
      ],
    );
  }
}
