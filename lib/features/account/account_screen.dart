import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/design_system/theme.dart';
import '../../core/design_system/tokens.dart';
import '../../core/design_system/vigia_icons.dart';
import '../../core/design_system/widgets/screen_aura.dart';
import '../../core/design_system/widgets/trial_version_notice.dart';
import '../../core/design_system/widgets/vigia_button.dart';
import '../../core/design_system/widgets/vigia_scaffold.dart';
import '../../core/design_system/widgets/vigia_text.dart';
import '../experimental/experimental_monitoring_controller.dart';
import 'cloud_sessions.dart';
import 'firebase_account.dart';
import 'presentation/account_actions.dart';

/// Cuenta (rediseño 2026-11-17): identidad arriba, estado de la cuenta en
/// una tarjeta, acciones de seguridad (cambiar correo, cambiar contraseña,
/// eliminar cuenta), aviso de versión de prueba y cierre de sesión.
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

  Future<void> _openAction(AccountAction action) async {
    if (_busy) return;
    final result = await showAccountActionSheet(context, action);
    if (!mounted || result == null) return;
    setState(() => _feedback = result);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(firebaseUserProvider).asData?.value;
    final uid = ref.watch(verifiedFirebaseUidProvider);
    final monitoring = ref.watch(experimentalMonitoringProvider);
    final locked = monitoring.sessionVigente || monitoring.pending != null;
    final p = VigiaColors.of(context);
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
        background: const ScreenAura(),
        onNavSelected: (i) {
          if (i == 0) home();
          if (i == 1) context.go(VigiaRoutes.historial);
          if (i == 2) context.go(VigiaRoutes.ajustes);
        },
        children: [
          _Identity(email: user?.email, verified: uid != null),
          if (uid != null) _StatusCard(uid: uid),
          if (uid != null)
            _GroupCard(
              label: 'Seguridad',
              children: [
                _ActionRow(
                  key: const ValueKey('account-change-email'),
                  icon: VigiaIcon.mail,
                  label: 'Cambiar correo',
                  onTap: () => _openAction(AccountAction.email),
                ),
                _ActionRow(
                  key: const ValueKey('account-change-password'),
                  icon: VigiaIcon.lock,
                  label: 'Cambiar contraseña',
                  onTap: () => _openAction(AccountAction.password),
                ),
                _ActionRow(
                  key: const ValueKey('account-delete'),
                  icon: VigiaIcon.trash,
                  label: 'Eliminar cuenta',
                  danger: true,
                  onTap: locked
                      ? null
                      : () => _openAction(AccountAction.delete),
                ),
              ],
            ),
          if (_feedback case final feedback?)
            Semantics(
              liveRegion: true,
              child: VigiaText(
                feedback,
                style: VigiaType.body.copyWith(color: p.ink),
              ),
            )
          else if (locked)
            VigiaText(
              'Finaliza el monitoreo antes de cerrar sesión.',
              style: VigiaType.body.copyWith(color: p.inkSecondary),
            ),
          const _TrialNotice(),
          VigiaButton(
            label: _busy ? 'Cerrando sesión…' : 'Cerrar sesión',
            kind: VigiaButtonKind.secondary,
            icon: VigiaIcon.logout,
            onPressed: locked || _busy || uid == null ? null : _signOut,
          ),
        ],
      ),
    );
  }
}

/// Avatar con la inicial, correo y estado de verificación.
class _Identity extends StatelessWidget {
  const _Identity({required this.email, required this.verified});

  final String? email;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    final p = VigiaColors.of(context);
    final address = email ?? 'Correo no disponible';
    final initial = (email != null && email!.isNotEmpty)
        ? email!.characters.first.toUpperCase()
        : '?';
    return Column(
      spacing: 10,
      children: [
        ExcludeSemantics(
          child: Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: p.ink, shape: BoxShape.circle),
            child: VigiaText(
              initial,
              style: VigiaType.heroTitle(30).copyWith(color: p.bg),
            ),
          ),
        ),
        Semantics(
          header: true,
          child: VigiaText(
            address,
            textAlign: TextAlign.center,
            style: VigiaType.cardTitle.copyWith(color: p.ink),
          ),
        ),
        if (verified)
          Container(
            padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 14, 6),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(VigiaRadius.toast),
              border: Border.all(color: p.line),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: [
                VigiaIconView(VigiaIcon.check, size: 16, color: p.ink),
                VigiaText(
                  'Correo verificado',
                  style: VigiaType.small.copyWith(color: p.ink),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Tarjeta de estado: sincronización del historial y privacidad.
class _StatusCard extends ConsumerWidget {
  const _StatusCard({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upload = ref.watch(cloudSessionUploadProvider(uid));
    final (title, text) = switch (upload) {
      AsyncValue(isLoading: true) => ('Sincronizando…', null),
      AsyncValue(hasError: true) => (
        'Envío pendiente',
        'Los registros se conservan en este teléfono.',
      ),
      _ => ('Sin envíos pendientes', null),
    };
    return _GroupCard(
      label: 'Estado',
      children: [
        _InfoRow(
          icon: switch (upload) {
            AsyncValue(isLoading: true) => VigiaIcon.refresh,
            AsyncValue(hasError: true) => VigiaIcon.info,
            _ => VigiaIcon.cloud,
          },
          tag: 'Sincronización del historial',
          title: title,
          text: text,
          action: upload.hasError && !upload.isLoading
              ? VigiaButton(
                  label: 'Reintentar envío',
                  kind: VigiaButtonKind.secondary,
                  onPressed: () =>
                      ref.invalidate(cloudSessionUploadProvider(uid)),
                )
              : null,
        ),
        const _InfoRow(
          icon: VigiaIcon.phone,
          tag: 'Privacidad',
          title: 'Solo se guardan resúmenes',
          text:
              'La cámara y la detección quedan en tu teléfono; no se envían '
              'imágenes.',
        ),
      ],
    );
  }
}

/// Grupo de filas dentro de una sola tarjeta, con etiqueta encima.
class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = VigiaColors.of(context);
    final dark = p.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Semantics(
          header: true,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: 6),
            child: VigiaText(
              label,
              style: VigiaType.smallIndicator.copyWith(color: p.inkSecondary),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: dark ? p.surface : Colors.white,
            borderRadius: BorderRadius.circular(VigiaRadius.card),
            border: Border.all(color: p.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) Divider(height: 1, thickness: 1, color: p.line),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.tag,
    required this.title,
    this.text,
    this.action,
  });

  final VigiaIcon icon;
  final String tag;
  final String title;
  final String? text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = VigiaColors.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 14,
        children: [
          ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: VigiaIconView(icon, size: 24, color: p.ink),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 4,
              children: [
                VigiaText(
                  tag,
                  style: VigiaType.small.copyWith(color: p.inkSecondary),
                ),
                VigiaText(
                  title,
                  style: VigiaType.kvValue.copyWith(color: p.ink),
                ),
                if (text != null)
                  VigiaText(
                    text!,
                    style: VigiaType.small.copyWith(color: p.inkSecondary),
                  ),
                if (action != null) ...[const SizedBox(height: 8), action!],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final VigiaIcon icon;
  final String label;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final p = VigiaColors.of(context);
    final color = onTap == null
        ? p.inkSecondary
        : (danger ? p.errorInk : p.ink);
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: VigiaSpace.minTap + 8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                spacing: 14,
                children: [
                  VigiaIconView(icon, size: 24, color: color),
                  Expanded(
                    child: VigiaText(
                      label,
                      style: VigiaType.body.copyWith(color: color),
                    ),
                  ),
                  VigiaIconView(
                    VigiaIcon.chevron,
                    size: 20,
                    color: p.inkSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Aviso de versión de prueba en un recuadro tonal con icono.
class _TrialNotice extends StatelessWidget {
  const _TrialNotice();

  @override
  Widget build(BuildContext context) {
    final p = VigiaColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surfaceStrong,
        borderRadius: BorderRadius.circular(VigiaRadius.tag + 6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: VigiaIconView(VigiaIcon.info, size: 22, color: p.ink),
            ),
          ),
          const Expanded(child: TrialVersionNotice()),
        ],
      ),
    );
  }
}
