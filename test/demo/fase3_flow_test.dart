import 'dart:ui' show CheckedState;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia/app/app_config.dart';
import 'package:vigia/app/router.dart';
import 'package:vigia/core/audio/alert_sound.dart';
import 'package:vigia/core/design_system/widgets/vigia_button.dart';
import 'package:vigia/core/design_system/widgets/vigia_option.dart';
import 'package:vigia/core/design_system/widgets/vigia_scaffold.dart';
import 'package:vigia/data/demo_history/demo_history_repository.dart';
import 'package:vigia/data/demo_history/history_providers.dart';
import 'package:vigia/demo/inicio_demo.dart';
import 'package:vigia/features/history/history_screen.dart';
import 'package:vigia/features/history/session_detail_screen.dart';
import 'package:vigia/features/inicio/inicio_screen.dart';
import 'package:vigia/features/inicio/inicio_state.dart';
import 'package:vigia/features/monitoring/demo_session_controller.dart';
import 'package:vigia/features/monitoring/domain/session_model.dart';
import 'package:vigia/features/monitoring/monitoring_screen.dart';
import 'package:vigia/features/preparation/preparation_controller.dart';
import 'package:vigia/features/preparation/preparation_screen.dart';
import 'package:vigia/features/preparation/preparation_state.dart';
import 'package:vigia/features/settings/preferences_controller.dart';
import 'package:vigia/features/settings/settings_screen.dart';
import 'package:vigia/features/settings/sound_screen.dart';
import 'package:vigia/features/summary/summary_screen.dart';

import '../support/demo_harness.dart';
import '../support/vigia_harness.dart';

const _cfg = ScreenConfig(width: 360);

bool _enabled(WidgetTester tester, String label) =>
    tester
        .widget<VigiaButton>(find.widgetWithText(VigiaButton, label).last)
        .onPressed !=
    null;

Future<void> _go(WidgetTester tester, String route) async {
  demoRouter(tester).go(route);
  await settle(tester);
}

/// Contexto de la pantalla visible (para leer tema y movimiento aplicados).
BuildContext _screen(WidgetTester tester) =>
    tester.element(find.byType(VigiaScaffold).last);

void main() {
  setUpAll(loadVigiaFonts);

  group('Sesión → Resumen → Historial (mismos datos guardados)', () {
    testWidgets('Resumen, detalle, lista e Inicio leen la misma sesión', (
      tester,
    ) async {
      await pumpDemo(tester, _cfg);
      final id = await finishDemoSession(tester);
      final saved = (await demoHistory.session(id))!;
      final m = saved.summary!;

      expect(find.byType(SummaryScreen), findsOneWidget);
      expect(find.text('Completo · guardado'), findsOneWidget);
      expect(find.text(m.coverageText), findsOneWidget);

      await tapLabel(tester, 'Ver detalle');
      expect(find.byType(SessionDetailScreen), findsOneWidget);
      expect(find.text(id), findsOneWidget);
      expect(find.text('DEMO — datos simulados'), findsWidgets);
      expect(find.text(m.coverageText), findsOneWidget);
      expect(find.text(formatSecondsFor(m.monitored)), findsWidgets);

      await tester.tap(find.byKey(const Key('vigia-back')));
      await settle(tester);
      expect(find.byType(HistoryScreen), findsOneWidget);
      expect(find.byKey(Key('history-$id')), findsOneWidget);

      await tapLabel(tester, 'Inicio');
      expect(find.text('Último resumen'), findsOneWidget);
      expect(find.text(id), findsOneWidget);
      expect(find.text(m.coverageText), findsOneWidget);
    });

    testWidgets('finalizar guarda una sola fila y todos sus hechos', (
      tester,
    ) async {
      await pumpDemo(tester, _cfg);
      await driveToMonitoring(tester);
      await tester.pump(const Duration(seconds: 25));
      final s = demoContainer(tester).read(demoSessionProvider.notifier);
      for (var i = 0; i < 5; i++) {
        s.requestFinish();
      }
      await tester.pump(demoConfirm);
      await settle(tester);
      s.requestFinish(); // ya finalizada: nada
      await settle(tester);
      final state = demoContainer(tester).read(demoSessionProvider);
      final all = await demoHistory.sessions();
      expect(all, hasLength(1));
      expect(all.single.isFinalized, isTrue);
      final stored = await demoHistory.events(state.sessionId!);
      expect(
        stored.map((e) => e.sequence),
        state.events.map((e) => e.sequence),
      );
      expect(
        stored.where((e) => e.type == SessionEventType.finished),
        hasLength(1),
      );
    });

    testWidgets('una segunda sesión de la misma ejecución se guarda aparte', (
      tester,
    ) async {
      await pumpDemo(tester, _cfg);
      final a = await finishDemoSession(tester);
      final b = await finishDemoSession(tester);
      expect((a, b), ('S-DEMO-0001', 'S-DEMO-0002'));
      for (final id in [a, b]) {
        final events = await demoHistory.events(id);
        expect(events.first.type, SessionEventType.started, reason: id);
        expect((await demoHistory.session(id))!.isFinalized, isTrue);
      }
    });
  });

  group('Reinicio de la app', () {
    testWidgets('una sesión sin cierre queda Interrumpida: no se reanuda ni '
        'se inventa tiempo (RF19)', (tester) async {
      await pumpDemo(tester, _cfg);
      final id = await interruptDemoSession(tester);

      final session = demoContainer(tester).read(demoSessionProvider);
      expect(session.lifecycle, SessionLifecycle.none);
      expect(find.byType(InicioScreen), findsOneWidget);
      expect(find.text('Sesión interrumpida'), findsOneWidget);
      expect(find.text(id), findsOneWidget);
      expect(_enabled(tester, 'Preparar sesión'), isTrue);
      await _go(tester, VigiaRoutes.monitoreo);
      expect(find.byType(MonitoringScreen), findsNothing);

      final stored = (await demoHistory.session(id))!;
      expect(stored.isInterrupted, isTrue);
      expect(stored.summary, isNull);
      expect(stored.endedAt, isNull);
      // Último hecho guardado: el inicio del cierre ocular (20 s), no los
      // 22 s transcurridos ni la reapertura.
      expect(stored.latestDurableOffset, const Duration(seconds: 20));

      await tapLabel(tester, 'Revisar registro');
      expect(find.byType(SessionDetailScreen), findsOneWidget);
      expect(find.text('Interrumpida'), findsOneWidget);
      expect(find.text('Desconocido'), findsWidgets);
      expect(find.text('No disponible'), findsWidgets);
      expect(find.text('DEMO — datos simulados'), findsWidgets);
      expect(find.textContaining('· sin final'), findsOneWidget);
    });

    testWidgets('el Historial y el último resumen se reconstruyen desde la '
        'base', (tester) async {
      await pumpDemo(tester, _cfg);
      final a = await finishDemoSession(tester);
      final b = await finishDemoSession(tester);
      final coverage = (await demoHistory.session(b))!.summary!.coverageText;
      await restartDemo(tester);

      expect(find.text('Último resumen'), findsOneWidget);
      expect(find.text(b), findsOneWidget);
      expect(find.text(coverage), findsOneWidget);
      await tapLabel(tester, 'Ver último resumen');
      expect(find.byType(SummaryScreen), findsOneWidget);
      expect(find.text(b), findsOneWidget);

      await _go(tester, VigiaRoutes.historial);
      final top = tester.getTopLeft(find.byKey(Key('history-$b'))).dy;
      final bottom = tester.getTopLeft(find.byKey(Key('history-$a'))).dy;
      expect(top, lessThan(bottom), reason: 'más reciente primero');
      // El siguiente ID continúa la numeración guardada.
      final c = await finishDemoSession(tester);
      expect(c, 'S-DEMO-0003');
    });
  });

  group('Historial (P08)', () {
    testWidgets('vacío solo con lectura correcta; Preparar primera sesión', (
      tester,
    ) async {
      await pumpDemo(tester, _cfg);
      await _go(tester, VigiaRoutes.historial);
      expect(find.text('Aún no tienes sesiones'), findsOneWidget);
      await tapLabel(tester, 'Preparar primera sesión');
      expect(find.byType(PreparationScreen), findsOneWidget);
    });

    testWidgets('filtros por estado', (tester) async {
      await pumpDemo(tester, _cfg);
      final interrupted = await interruptDemoSession(tester);
      final finalized = await finishDemoSession(tester);
      await _go(tester, VigiaRoutes.historial);
      expect(find.byKey(Key('history-$interrupted')), findsOneWidget);
      expect(find.byKey(Key('history-$finalized')), findsOneWidget);
      await tapLabel(tester, 'Interrumpidas');
      expect(find.byKey(Key('history-$interrupted')), findsOneWidget);
      expect(find.byKey(Key('history-$finalized')), findsNothing);
      await tapLabel(tester, 'Finalizadas');
      expect(find.byKey(Key('history-$interrupted')), findsNothing);
      expect(find.byKey(Key('history-$finalized')), findsOneWidget);
    });

    testWidgets('con sesión vigente el detalle y Sonido muestran Sesión en '
        'curso, también por ruta directa', (tester) async {
      await pumpDemo(tester, _cfg);
      final id = await finishDemoSession(tester);
      await driveToMonitoring(tester);
      await _go(tester, VigiaRoutes.detalle(id));
      expect(find.text('Sesión en curso'), findsOneWidget);
      expect(find.text('Cobertura'), findsNothing);
      await _go(tester, VigiaRoutes.sonido);
      expect(find.text('Sesión en curso'), findsOneWidget);
      expect(find.text('Guardar'), findsNothing);
      await tapLabel(tester, 'Volver al monitoreo');
      expect(find.byType(MonitoringScreen), findsOneWidget);
    });
  });

  group('Ajustes (P12) y Sonido (P13)', () {
    testWidgets(
      'el tema elegido se aplica, se guarda y vuelve tras reiniciar',
      (tester) async {
        await pumpDemo(tester, _cfg, themeFromPreferences: true);
        await tapLabel(tester, 'Ajustes');
        expect(find.byType(SettingsScreen), findsOneWidget);
        await tapLabel(tester, 'Oscuro');
        expect(Theme.of(_screen(tester)).brightness, Brightness.dark);
        expect(
          (await demoHistory.loadPreferences()).theme,
          ThemePreference.dark,
        );
        await restartDemo(tester, themeFromPreferences: true);
        expect(Theme.of(_screen(tester)).brightness, Brightness.dark);
        await tapLabel(tester, 'Ajustes');
        expect(
          tester
              .widget<VigiaOption>(find.widgetWithText(VigiaOption, 'Oscuro'))
              .selected,
          isTrue,
        );
        await tapLabel(tester, 'Claro');
        expect(Theme.of(_screen(tester)).brightness, Brightness.light);
      },
    );

    testWidgets('movimiento reducido: preferencia guardada y aplicada; la del '
        'sistema se respeta siempre', (tester) async {
      // Sin reducción del sistema, para ver el efecto de la preferencia.
      await pumpDemo(
        tester,
        const ScreenConfig(width: 360, reduceMotion: false),
      );
      expect(MediaQuery.disableAnimationsOf(_screen(tester)), isFalse);
      await _go(tester, VigiaRoutes.ajustes);
      await tapLabel(tester, 'Reducido');
      expect(MediaQuery.disableAnimationsOf(_screen(tester)), isTrue);
      await restartDemo(tester);
      expect(MediaQuery.disableAnimationsOf(_screen(tester)), isTrue);
      // Con la preferencia en «Según Android», manda el sistema.
      await _go(tester, VigiaRoutes.ajustes);
      await tapLabel(tester, 'Según Android');
      expect(MediaQuery.disableAnimationsOf(_screen(tester)), isFalse);
      await tester.pumpWidget(const SizedBox());
      await pumpDemo(
        tester,
        const ScreenConfig(width: 360, reduceMotion: true),
        database: demoDatabase,
      );
      expect(MediaQuery.disableAnimationsOf(_screen(tester)), isTrue);
    });

    testWidgets('guardar otro patrón vuelve a exigir la prueba de sonido y '
        'las alertas lo usan (RF29.CA3)', (tester) async {
      final sound = await pumpDemo(tester, _cfg);
      await driveToReadyPreparation(tester);
      final c = demoContainer(tester);
      expect(c.read(preparationProvider).ready, isTrue);

      await _go(tester, VigiaRoutes.sonido);
      await tapLabel(tester, 'Patrón 2');
      await tapLabel(tester, 'Probar sonido');
      expect(sound.patterns.last, 'patron_2');
      await tapLabel(tester, 'Guardar');
      expect(find.text('Patrón guardado'), findsOneWidget);
      expect((await demoHistory.loadPreferences()).soundPatternId, 'patron_2');
      expect(c.read(preparationProvider).sound, SoundCheck.pending);
      expect(
        c.read(preparationProvider).blockers,
        contains(PreparationBlocker.sound),
      );
      expect(c.read(demoSessionProvider.notifier).requestStart(), isFalse);

      await driveToMonitoring(tester);
      expect(sound.patterns.last, 'patron_2'); // prueba de preparación
      await tester.pump(const Duration(seconds: 8));
      expect(sound.calls.last, AlertSoundKind.warning);
      expect(sound.patterns.last, 'patron_2');
    });

    testWidgets('salir de Sonido sin guardar pregunta; descartar no guarda', (
      tester,
    ) async {
      await pumpDemo(tester, _cfg);
      await _go(tester, VigiaRoutes.sonido);
      await tapLabel(tester, 'Patrón 3');
      await tester.tap(find.byKey(const Key('vigia-back')));
      await settle(tester);
      expect(find.text('Cambios sin guardar'), findsOneWidget);
      await tapLabel(tester, 'Seguir editando');
      expect(find.byType(SoundScreen), findsOneWidget);
      await tester.tap(find.byKey(const Key('vigia-back')));
      await settle(tester);
      await tapLabel(tester, 'Descartar cambios');
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(
        (await demoHistory.loadPreferences()).soundPatternId,
        StoredPreferences.defaultSoundPatternId,
      );
    });

    testWidgets('con sesión vigente solo se cambia el tema', (tester) async {
      await pumpDemo(tester, _cfg);
      await driveToMonitoring(tester);
      await _go(tester, VigiaRoutes.ajustes);
      expect(find.text('Sesión en curso'), findsOneWidget);
      expect(_enabled(tester, 'Oscuro'), isTrue);
      expect(_enabled(tester, 'Reducido'), isFalse);
      expect(
        _enabled(tester, 'Sonido · bloqueado por sesión vigente'),
        isFalse,
      );
      // La sesión sigue con el mismo ID.
      expect(
        demoContainer(tester).read(demoSessionProvider).lifecycle,
        SessionLifecycle.active,
      );
    });
  });

  for (final dark in [false, true]) {
    testWidgets('Sonido: «Guardar» por semántica tras otra preferencia ya '
        'guardada (${dark ? 'oscuro' : 'claro'})', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpDemo(tester, ScreenConfig(width: 360, dark: dark));
      await _go(tester, VigiaRoutes.ajustes);
      // Primera escritura: crea la fila de preferencias.
      tester.semantics.tap(find.semantics.byLabel('Reducido'));
      await settle(tester);
      tester.semantics.tap(find.semantics.byLabel('Sonido'));
      await settle(tester);
      tester.semantics.tap(find.semantics.byLabel(RegExp('^Patrón 2')));
      await settle(tester);
      await tester.ensureVisible(find.text('Guardar'));
      await tester.pump();
      tester.semantics.tap(find.semantics.byLabel('Guardar'));
      await settle(tester);
      expect(find.text('Patrón guardado'), findsOneWidget);
      final saved = await demoHistory.loadPreferences();
      expect((saved.soundPatternId, saved.reducedMotion), ('patron_2', true));
      expect(demoContainer(tester).read(preferencesProvider).value, saved);
      handle.dispose();
    });
  }

  group('Separación DEMO / modo normal', () {
    testWidgets('modo normal: sin historial abierto ni rutas de fase 3', (
      tester,
    ) async {
      await pumpDemo(tester, _cfg, mode: const RealMode());
      expect(
        () => demoContainer(tester).read(demoHistoryRepositoryProvider),
        throwsA(anything),
        reason: 'la app normal no abre la base DEMO',
      );
      await tapLabel(tester, 'Historial');
      expect(find.text(InicioScreen.historialNotice), findsOneWidget);
      expect(find.byType(HistoryScreen), findsNothing);
      await _go(tester, VigiaRoutes.ajustes);
      expect(find.byType(InicioScreen), findsOneWidget);
    });

    testWidgets('VIGIA_DEMO_INICIO: revisión sin historial ni escrituras', (
      tester,
    ) async {
      await pumpDemo(
        tester,
        _cfg,
        mode: InicioReviewMode(InicioDemoVariant.registroInterrumpido.state),
      );
      expect(
        () => demoContainer(tester).read(demoHistoryRepositoryProvider),
        throwsA(anything),
      );
      await tapLabel(tester, 'Revisar registro');
      expect(
        find.text(InicioScreen.pendingNotices[InicioAction.revisarRegistro]!),
        findsOneWidget,
      );
      expect(find.byType(SessionDetailScreen), findsNothing);
    });
  });

  testWidgets('activación semántica: barra, filtros, opciones y detalle', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpDemo(tester, _cfg);
    final id = await finishDemoSession(tester);
    await _go(tester, VigiaRoutes.inicio);

    tester.semantics.tap(find.semantics.byLabel('Historial'));
    await settle(tester);
    expect(find.byType(HistoryScreen), findsOneWidget);

    final todas = tester.getSemantics(find.bySemanticsLabel('Todas'));
    expect(
      todas.getSemanticsData().flagsCollection.isChecked,
      CheckedState.isTrue,
    );
    tester.semantics.tap(find.semantics.byLabel('Interrumpidas'));
    await settle(tester);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Interrumpidas'))
          .getSemanticsData()
          .flagsCollection
          .isChecked,
      CheckedState.isTrue,
    );
    tester.semantics.tap(find.semantics.byLabel('Todas'));
    await settle(tester);

    tester.semantics.tap(find.semantics.byLabel(RegExp('^$id')));
    await settle(tester);
    expect(find.byType(SessionDetailScreen), findsOneWidget);
    tester.semantics.tap(find.semantics.byLabel('Volver'));
    await settle(tester);
    expect(find.byType(HistoryScreen), findsOneWidget);

    tester.semantics.tap(find.semantics.byLabel('Ajustes'));
    await settle(tester);
    expect(find.byType(SettingsScreen), findsOneWidget);
    tester.semantics.tap(find.semantics.byLabel('Oscuro'));
    await settle(tester);
    expect((await demoHistory.loadPreferences()).theme, ThemePreference.dark);
    tester.semantics.tap(find.semantics.byLabel('Sonido'));
    await settle(tester);
    expect(find.byType(SoundScreen), findsOneWidget);
    tester.semantics.tap(find.semantics.byLabel('Volver'));
    await settle(tester);
    tester.semantics.tap(find.semantics.byLabel('Inicio'));
    await settle(tester);
    expect(find.byType(InicioScreen), findsOneWidget);
    handle.dispose();
  });
}

/// Mismo formato que el detalle («13,1 s»).
String formatSecondsFor(Duration d) =>
    '${(d.inMilliseconds / 1000).toStringAsFixed(1).replaceAll('.', ',')} s';
