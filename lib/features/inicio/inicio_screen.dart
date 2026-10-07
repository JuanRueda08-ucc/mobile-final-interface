import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_config.dart';
import '../../app/router.dart';
import '../../core/design_system/vigia_icons.dart';
import '../../core/design_system/widgets/aura_hero.dart';
import '../../core/design_system/widgets/notice_host.dart';
import '../../core/design_system/widgets/vigia_blocks.dart';
import '../../core/design_system/widgets/vigia_button.dart';
import '../../core/design_system/widgets/vigia_scaffold.dart';
import '../../data/demo_history/history_providers.dart';
import '../preparation/preparation_controller.dart';
import 'inicio_providers.dart';
import 'inicio_state.dart';

/// P03 · Inicio (UX §3, RF19–RF21; composición de B5.2 `vP03`).
///
/// - Con `VIGIA_DEMO=true` sus acciones abren el recorrido demostrativo:
///   Preparar sesión, Volver al monitoreo (consulta el estado; no crea otro
///   inicio), Ver último resumen y Revisar registro (detalle guardado), y la
///   barra abre Historial y Ajustes.
/// - Con `VIGIA_DEMO_INICIO` es una vista de revisión: sus acciones y la barra
///   muestran un aviso, porque la variante no es una sesión iniciada.
/// - Sin definiciones (motor no comprobado) no hay historial ni ajustes que
///   abrir en este prototipo: la barra muestra un aviso.
class InicioScreen extends ConsumerStatefulWidget {
  const InicioScreen({super.key});

  /// Avisos de la vista de revisión (`VIGIA_DEMO_INICIO`) y de las funciones
  /// de la fase 3.
  static const pendingNotices = <InicioAction, String>{
    InicioAction.prepararSesion:
        'Vista de revisión de Inicio: no abre la preparación. El recorrido '
        'demostrativo se abre con VIGIA_DEMO=true.',
    InicioAction.volverAlMonitoreo:
        'Vista de revisión de Inicio: esta sesión vigente es una variante '
        'simulada, no una sesión iniciada.',
    InicioAction.verUltimoResumen:
        'Vista de revisión de Inicio: este resumen es una variante simulada, '
        'sin sesión que abrir.',
    InicioAction.revisarRegistro:
        'Vista de revisión de Inicio: este registro interrumpido es una '
        'variante simulada, sin detalle guardado que abrir.',
    InicioAction.consultarEstado:
        'Vista de revisión de Inicio: no hay motor que consultar; el estado '
        'mostrado es una variante simulada.',
  };

  static const historialNotice =
      'Historial no está disponible sin motor ni recorrido DEMO en este '
      'prototipo.';
  static const ajustesNotice =
      'Ajustes no está disponible sin motor ni recorrido DEMO en este '
      'prototipo.';

  static const heroText =
      'Prepara el teléfono con el vehículo detenido y el soporte fijo.';

  @override
  ConsumerState<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends ConsumerState<InicioScreen> with NoticeHost {
  void _act(InicioAction a, {String? sessionId}) {
    if (ref.read(appModeProvider) is DemoMode) {
      switch (a) {
        case InicioAction.prepararSesion:
          ref.read(preparationProvider.notifier).open();
          context.go(VigiaRoutes.preparacion);
          return;
        case InicioAction.volverAlMonitoreo:
          // Consulta el estado y abre el mismo ID; no ejecuta otro inicio.
          context.go(VigiaRoutes.monitoreo);
          return;
        case InicioAction.verUltimoResumen:
          context.go(VigiaRoutes.resumen(sessionId!));
          return;
        case InicioAction.revisarRegistro:
          context.go(VigiaRoutes.detalle(sessionId!));
          return;
        case InicioAction.consultarEstado:
          break;
      }
    }
    showNotice(InicioScreen.pendingNotices[a]!);
  }

  void _nav(int index) {
    final mode = ref.read(appModeProvider);
    switch (index) {
      case 1 when mode is DemoMode:
        context.go(VigiaRoutes.historial);
      case 2 when mode is DemoMode:
        context.go(VigiaRoutes.ajustes);
      case 1:
        showNotice(InicioScreen.historialNotice);
      case 2:
        showNotice(InicioScreen.ajustesNotice);
      default:
        break; // Inicio: ya estamos aquí; no se crea otra copia (UX §2.1).
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inicioStateProvider);
    return VigiaScaffold(
      title: 'Vigía',
      isDemo: state.isDemo,
      navIndex: 0,
      onNavSelected: _nav,
      notice: notice,
      children: _blocks(state),
    );
  }

  List<Widget> _blocks(InicioState s) {
    switch (s) {
      case InicioSesionVigente(:final sessionId, :final paused):
        return [
          AuraHero(
            tag: 'Sesión vigente',
            title: 'Sesión en curso: ${paused ? 'Pausada' : 'Activa'}',
            titleSize: 32,
            minHeight: 220,
            text: 'ID $sessionId. Sigue siendo la misma sesión.',
            ctaLabel: 'Volver al monitoreo',
            onCta: () => _act(InicioAction.volverAlMonitoreo),
          ),
          const VigiaButton(
            label: 'Preparar sesión',
            onPressed: null,
            kind: VigiaButtonKind.secondary,
          ),
          const VigiaParagraph(
            'No disponible: hay una sesión vigente. No se puede iniciar otra ni recalibrar.',
            secondary: true,
          ),
          const VigiaParagraph(
            'Detalle, tendencias, valoración, exportación, borrado, retención, alias y ayuda guiada '
            'quedan bloqueados hasta confirmar el cierre.',
            secondary: true,
          ),
        ];
      case InicioRegistroInterrumpido(
        :final sourceTag,
        :final confirmedStart,
        :final lastConfirmedRecord,
        :final sessionId,
      ):
        return [
          StatusCard(
            tone: StatusTone.alert,
            icon: VigiaIcon.warn,
            tag: sourceTag,
            title: 'Sesión interrumpida',
            text: 'No hay cierre confirmado. No se reinició la cámara.',
          ),
          if (sessionId != null) KeyValueRow(label: 'Sesión', value: sessionId),
          KeyValueRow(label: 'Inicio confirmado', value: confirmedStart),
          KeyValueRow(
            label: 'Último registro confirmado',
            value: lastConfirmedRecord,
          ),
          const KeyValueRow(label: 'Final', value: 'Desconocido'),
          const KeyValueRow(label: 'Duración', value: 'No disponible'),
          const VigiaParagraph(
            'El tiempo hasta la reapertura no se cuenta como medición.',
            secondary: true,
          ),
          VigiaButton(
            label: 'Revisar registro',
            kind: VigiaButtonKind.secondary,
            onPressed: () =>
                _act(InicioAction.revisarRegistro, sessionId: sessionId),
          ),
          VigiaButton(
            label: 'Preparar sesión',
            onPressed: () => _act(InicioAction.prepararSesion),
          ),
        ];
      case InicioMotorNoComprobado():
        return [
          const StatusCard(
            tone: StatusTone.neutral,
            icon: VigiaIcon.lock,
            tag: 'Estado del motor',
            title: 'Estado del motor no comprobado',
            text:
                'Esta versión del prototipo todavía no se conecta con el motor de '
                'monitoreo. No se puede preparar ni iniciar una sesión.',
          ),
          const VigiaButton(label: 'Preparar sesión', onPressed: null),
          const VigiaParagraph(
            'No disponible hasta comprobar el estado del motor.',
            secondary: true,
          ),
        ];
      case InicioMotorDesconocido():
        return [
          const StatusCard(
            tone: StatusTone.neutral,
            icon: VigiaIcon.eyeOff,
            tag: 'Estado',
            title: 'Estado del monitoreo no disponible',
            text: 'Consultando el estado de la sesión. No se puede iniciar otra mientras tanto.',
          ),
          VigiaButton(
            label: 'Consultar estado',
            kind: VigiaButtonKind.secondary,
            onPressed: () => _act(InicioAction.consultarEstado),
          ),
          const VigiaButton(label: 'Preparar sesión', onPressed: null),
          const VigiaParagraph(
            'No disponible hasta conocer el estado del motor.',
            secondary: true,
          ),
        ];
      case InicioUltimoResumen(
        :final sessionId,
        :final recordStatus,
        :final coverage,
        :final episodes,
      ):
        return [
          _prepareHero(),
          const VigiaSectionTitle('Último resumen'),
          PaperSummaryCard(
            tag: recordStatus,
            title: sessionId,
            metrics: [
              PaperMetric(coverage, 'Cobertura'),
              PaperMetric(episodes, 'Episodios'),
            ],
            actionLabel: 'Ver último resumen',
            onAction: () =>
                _act(InicioAction.verUltimoResumen, sessionId: sessionId),
          ),
        ];
      case InicioHistorialPendiente(:final failed):
        return [
          _prepareHero(),
          if (failed) ...[
            const StatusCard(
              tone: StatusTone.alert,
              icon: VigiaIcon.close,
              tag: 'Error',
              title: 'No se pudo cargar el historial',
              text: 'Esto no significa que no existan sesiones.',
            ),
            VigiaButton(
              label: 'Reintentar',
              kind: VigiaButtonKind.secondary,
              onPressed: () => ref.invalidate(latestStoredSessionProvider),
            ),
          ] else
            const StatusCard(
              tone: StatusTone.pending,
              icon: VigiaIcon.clock,
              tag: 'Historial',
              title: 'Cargando historial',
              text: 'Leyendo los registros guardados en el teléfono.',
            ),
        ];
      case InicioSinHistorial():
        return [
          _prepareHero(),
          const StatusCard(
            tone: StatusTone.plain,
            icon: VigiaIcon.info,
            tag: 'Historial',
            title: 'Aún no tienes sesiones',
            text: 'Las sesiones finalizadas o interrumpidas aparecerán aquí. No necesitas cuenta.',
          ),
        ];
    }
  }

  Widget _prepareHero() => AuraHero(
    title: 'Prepara tu sesión',
    text: InicioScreen.heroText,
    ctaLabel: 'Preparar sesión',
    onCta: () => _act(InicioAction.prepararSesion),
  );
}
