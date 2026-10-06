import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/design_system/tokens.dart';
import '../../core/design_system/vigia_icons.dart';
import '../../core/design_system/widgets/aura_hero.dart';
import '../../core/design_system/widgets/vigia_blocks.dart';
import '../../core/design_system/widgets/vigia_button.dart';
import '../../core/design_system/widgets/vigia_scaffold.dart';
import 'inicio_state.dart';

/// P03 · Inicio (UX §3, RF19–RF21; composición de B5.2 `vP03`).
///
/// Fase 1 del plan activo: las acciones que llevan a pantallas de fases
/// posteriores muestran un aviso de disponibilidad pendiente. No navegan ni
/// simulan esas pantallas.
class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key, required this.state});

  final InicioState state;

  /// Avisos de disponibilidad pendiente (fase 1).
  static const pendingNotices = <InicioAction, String>{
    InicioAction.prepararSesion:
        'Preparación todavía no está disponible en este prototipo (fase 2).',
    InicioAction.volverAlMonitoreo:
        'Monitoreo todavía no está disponible en este prototipo (fase 2).',
    InicioAction.verUltimoResumen:
        'Resumen todavía no está disponible en este prototipo (fase 2).',
    InicioAction.revisarRegistro: 'Detalle del registro todavía no está disponible en este prototipo (fase 3).',
    InicioAction.consultarEstado:
        'La consulta de estado del motor llega con el monitoreo (fase 2).',
  };

  static const historialNotice =
      'Historial todavía no está disponible en este prototipo (fase 3).';
  static const ajustesNotice =
      'Ajustes todavía no está disponible en este prototipo (fase 3).';

  static const heroText =
      'Prepara el teléfono con el vehículo detenido y el soporte fijo.';

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  String? _notice;
  Timer? _timer;

  void _show(String text) {
    _timer?.cancel();
    setState(() => _notice = text);
    _timer = Timer(VigiaMotion.toastDuration, () {
      if (mounted) setState(() => _notice = null);
    });
  }

  void _act(InicioAction a) => _show(InicioScreen.pendingNotices[a]!);

  void _nav(int index) {
    switch (index) {
      case 1:
        _show(InicioScreen.historialNotice);
      case 2:
        _show(InicioScreen.ajustesNotice);
      default:
        break; // Inicio: ya estamos aquí; no se crea otra copia (UX §2.1).
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VigiaScaffold(
      title: 'Vigía',
      isDemo: widget.state.isDemo,
      navIndex: 0,
      onNavSelected: _nav,
      notice: _notice,
      children: _blocks(widget.state),
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
      ):
        return [
          StatusCard(
            tone: StatusTone.alert,
            icon: VigiaIcon.warn,
            tag: sourceTag,
            title: 'Sesión interrumpida',
            text: 'No hay cierre confirmado. No se reinició la cámara.',
          ),
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
            onPressed: () => _act(InicioAction.revisarRegistro),
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
            onAction: () => _act(InicioAction.verUltimoResumen),
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
