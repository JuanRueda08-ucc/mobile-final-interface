import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monitoring_engine/monitoring_engine.dart';
import 'package:vigia/app/app_config.dart';
import 'package:vigia/app/bootstrap.dart';
import 'package:vigia/app/router.dart';
import 'package:vigia/app/vigia_app.dart';
import 'package:vigia/core/design_system/widgets/vigia_scaffold.dart';
import 'package:vigia/data/demo_history/demo_history_database.dart';
import 'package:vigia/data/demo_history/demo_history_repository.dart';
import 'package:vigia/data/experimental_history/experimental_history_database.dart';
import 'package:vigia/data/experimental_history/experimental_history_providers.dart';
import 'package:vigia/data/experimental_history/experimental_history_repository.dart';
import 'package:vigia/features/experimental/experimental_monitoring_controller.dart';
import 'package:vigia/features/settings/preferences_controller.dart';
import 'package:vigia/features/settings/settings_screen.dart';
import 'package:vigia/features/settings/sound_screen.dart';
import 'package:vigia/features/settings/variant_settings.dart';

import '../support/fake_experimental.dart';
import '../support/fake_journal.dart';
import '../support/vigia_harness.dart';

/// Escrituras retenidas hasta que la prueba las libera (o las hace fallar).
class _GatedStore implements PreferencesStore {
  _GatedStore(this.inner);

  final PreferencesStore inner;
  final gates = <Completer<void>>[];

  @override
  Future<StoredPreferences> loadPreferences() => inner.loadPreferences();

  @override
  Future<void> savePreferences(StoredPreferences p) async {
    final gate = Completer<void>();
    gates.add(gate);
    await gate.future;
    await inner.savePreferences(p);
  }
}

/// Fase 5E · Ajustes de la variante normal: preferencias en
/// `vigia_history_real_v1.sqlite` (SQLite real en disco), separadas de la
/// DEMO, y patrón de sonido coherente entre interfaz, base y motor (doble
/// [FakeExperimentalBridge], que imita las reglas del coordinador; las reglas
/// reales se prueban en Kotlin).
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late Directory dir;
  late File file;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('vigia_real_prefs_');
    file = File('${dir.path}/vigia_history_real_v1.sqlite');
  });
  tearDown(() async {
    try {
      await dir.delete(recursive: true);
    } on FileSystemException {
      // Windows puede retener el archivo un instante tras cerrarlo.
    }
  });

  ExperimentalHistoryDatabase openDb() =>
      ExperimentalHistoryDatabase(NativeDatabase(file));

  /// Preferencias leídas con una conexión nueva, cerrada al terminar.
  Future<StoredPreferences> reread() async {
    final db = openDb();
    try {
      return await ExperimentalHistoryRepository(db).loadPreferences();
    } finally {
      await db.close();
    }
  }

  group('Repositorio real (esquema v2)', () {
    test('sin fila: iniciales; guardados sucesivos y entre conexiones dejan '
        'una sola fila', () async {
      expect(await reread(), const StoredPreferences());
      var db = openDb();
      var repo = ExperimentalHistoryRepository(db);
      for (final p in const [
        StoredPreferences(theme: ThemePreference.dark),
        StoredPreferences(theme: ThemePreference.light, reducedMotion: true),
        StoredPreferences(soundPatternId: 'patron_3'),
      ]) {
        await repo.savePreferences(p);
        expect(await repo.loadPreferences(), p);
      }
      await db.close();

      db = openDb();
      repo = ExperimentalHistoryRepository(db);
      const last = StoredPreferences(
        theme: ThemePreference.dark,
        soundPatternId: 'patron_2',
        reducedMotion: true,
      );
      await repo.savePreferences(last);
      final rows = await db
          .customSelect('SELECT singleton FROM preferences')
          .get();
      expect(rows.map((r) => r.read<int>('singleton')), [1]);
      await db.close();
      expect(await reread(), last);
    });

    test('un patrón fuera del catálogo se rechaza y se conserva el '
        'anterior', () async {
      final db = openDb();
      final repo = ExperimentalHistoryRepository(db);
      await repo.savePreferences(
        const StoredPreferences(soundPatternId: 'patron_2'),
      );
      await expectLater(
        repo.savePreferences(
          const StoredPreferences(soundPatternId: 'patron_9'),
        ),
        throwsA(anything),
      );
      await db.close();
      expect((await reread()).soundPatternId, 'patron_2');
    });

    test('migración v1 → v2: conserva los datos de 5D y añade '
        'preferencias', () async {
      // Base con el esquema de 5D: la de v2 sin `preferences`, en versión 1.
      var db = openDb();
      await db.customStatement('DROP TABLE preferences');
      await db.customStatement(
        "INSERT INTO imported_records VALUES ('r-1', 1, 'hash-1', 'started')",
      );
      await db.customStatement('PRAGMA user_version = 1');
      await db.close();

      db = openDb();
      final repo = ExperimentalHistoryRepository(db);
      expect(await repo.loadPreferences(), const StoredPreferences());
      expect(await repo.importedCount(), 1, reason: 'los recibos de 5D siguen');
      await repo.savePreferences(
        const StoredPreferences(theme: ThemePreference.dark),
      );
      final version = await db.customSelect('PRAGMA user_version').getSingle();
      expect(version.read<int>('user_version'), 2);
      await db.close();
      expect((await reread()).theme, ThemePreference.dark);
    });

    test('separación: la base real y la DEMO guardan cada una lo '
        'suyo', () async {
      final demoFile = File('${dir.path}/vigia_history_demo_v1.sqlite');
      final real = openDb();
      await ExperimentalHistoryRepository(
        real,
      ).savePreferences(const StoredPreferences(theme: ThemePreference.light));
      await real.close();
      expect(demoFile.existsSync(), isFalse, reason: 'la real no abre la DEMO');

      final demo = DemoHistoryDatabase(NativeDatabase(demoFile));
      final demoRepo = await DriftDemoHistoryRepository.open(demo);
      await demoRepo.savePreferences(
        const StoredPreferences(
          theme: ThemePreference.dark,
          soundPatternId: 'patron_3',
        ),
      );
      await demo.close();
      expect(
        await reread(),
        const StoredPreferences(theme: ThemePreference.light),
      );
    });
  });

  group('Controlador en la variante normal', () {
    late ExperimentalHistoryDatabase db;
    late ExperimentalHistoryRepository repo;
    late _GatedStore store;
    late FakeExperimentalBridge engine;

    ProviderContainer container({
      StoredPreferences initial = const StoredPreferences(),
      MonitoringSnapshot? engineState,
      bool gated = true,
    }) {
      db = openDb();
      repo = ExperimentalHistoryRepository(db);
      store = _GatedStore(repo);
      engine = FakeExperimentalBridge(engineState);
      return ProviderContainer(
        overrides: [
          appModeProvider.overrideWithValue(const RealMode()),
          ...realOverrides(repo, initial),
          if (gated) preferencesStoreProvider.overrideWithValue(store),
          experimentalBridgeProvider.overrideWithValue(engine),
        ],
      );
    }

    void release(FakeAsync a, int i, {bool fail = false}) {
      a.flushMicrotasks();
      final gate = store.gates[i];
      fail ? gate.completeError(StateError('disco lleno')) : gate.complete();
      a.flushMicrotasks();
    }

    StoredPreferences closeAndReread(ProviderContainer c, FakeAsync a) {
      c.dispose();
      db.close();
      a.flushMicrotasks();
      late StoredPreferences p;
      reread().then((v) => p = v);
      a.flushMicrotasks();
      return p;
    }

    test('sin sustituir el almacén, la normal escribe en su base real', () {
      fakeAsync((a) {
        final c = container(gated: false);
        expect(identical(c.read(preferencesStoreProvider), repo), isTrue);
        c.read(preferencesProvider.notifier).setTheme(ThemePreference.dark);
        a.flushMicrotasks();
        expect(c.read(preferencesProvider).save, PreferenceSave.saved);
        expect(closeAndReread(c, a).theme, ThemePreference.dark);
      });
    });

    test('guardados simultáneos de tema, movimiento y patrón, liberados en '
        'otro orden: memoria, SQLite y motor coinciden', () {
      fakeAsync((a) {
        final c = container();
        final ctl = c.read(preferencesProvider.notifier);
        c.read(experimentalMonitoringProvider.notifier).refresh();
        a.elapse(const Duration(milliseconds: 200));
        ctl.setSoundPattern('patron_2');
        ctl.setTheme(ThemePreference.dark);
        ctl.setReducedMotion(true);
        ctl.setSoundPattern('patron_3');
        a.flushMicrotasks();
        // Tema y movimiento se ven en el acto; el patrón, al guardarse.
        final view = c.read(preferencesProvider).value;
        expect((view.theme, view.reducedMotion), (ThemePreference.dark, true));
        expect(view.soundPatternId, 'patron_1');
        expect(
          engine.calls.where((x) => x.startsWith('soundPattern:')),
          isEmpty,
          reason: 'el motor no recibe un patrón sin guardar',
        );
        for (var i = 0; i < 4; i++) {
          release(a, i);
        }
        a.elapse(const Duration(milliseconds: 300));
        expect(
          c.read(preferencesProvider).value,
          const StoredPreferences(
            theme: ThemePreference.dark,
            reducedMotion: true,
            soundPatternId: 'patron_3',
          ),
        );
        expect(c.read(preferencesProvider).save, PreferenceSave.saved);
        expect(engine.current.soundPatternId, 'patron_3');
        expect(
          c.read(experimentalMonitoringProvider).snapshot!.soundPatternId,
          'patron_3',
        );
        expect(
          closeAndReread(c, a),
          const StoredPreferences(
            theme: ThemePreference.dark,
            reducedMotion: true,
            soundPatternId: 'patron_3',
          ),
        );
      });
    });

    test('un fallo de guardado informa de esa preferencia y conserva las '
        'aceptadas en memoria, SQLite y motor', () {
      fakeAsync((a) {
        final c = container();
        final ctl = c.read(preferencesProvider.notifier);
        c.read(experimentalMonitoringProvider.notifier).refresh();
        ctl.setSoundPattern('patron_2');
        release(a, 0);
        a.elapse(const Duration(milliseconds: 200));
        expect(engine.current.soundPatternId, 'patron_2');

        ctl.setTheme(ThemePreference.dark);
        ctl.setSoundPattern('patron_3');
        release(a, 1);
        release(a, 2, fail: true);
        a.elapse(const Duration(milliseconds: 200));
        final s = c.read(preferencesProvider);
        expect(s.save, PreferenceSave.failed);
        expect(s.failures.keys, [PreferenceField.soundPattern]);
        expect(
          preferenceFailureText(s.failures.values.single, s.value),
          'No se pudo guardar el Patrón 3. Las alertas siguen con el '
          'Patrón 2.',
        );
        expect(s.value.theme, ThemePreference.dark);
        expect(engine.current.soundPatternId, 'patron_2');
        expect(engine.calls, isNot(contains('soundPattern:patron_3')));
        expect(
          closeAndReread(c, a),
          const StoredPreferences(
            theme: ThemePreference.dark,
            soundPatternId: 'patron_2',
          ),
        );
      });
    });

    test('cambiar el patrón invalida la confirmación sonora anterior', () {
      fakeAsync((a) {
        final c = container(
          engineState: fakeSnapshot(
            soundTestId: 'snd-1',
            soundTestPlayed: true,
            soundHeard: true,
            step: CalibrationStep.accepted,
            calibrationId: 'cal-1',
          ),
        );
        final exp = c.read(experimentalMonitoringProvider.notifier);
        exp.refresh();
        a.elapse(const Duration(milliseconds: 200));
        expect(
          exp.soundConfirmedFor(
            c.read(experimentalMonitoringProvider).snapshot,
          ),
          isTrue,
        );
        c.read(preferencesProvider.notifier).setSoundPattern('patron_2');
        release(a, 0);
        a.elapse(const Duration(milliseconds: 200));
        final snap = c.read(experimentalMonitoringProvider).snapshot!;
        expect(snap.soundPatternId, 'patron_2');
        expect((snap.soundTestId, snap.soundHeard), (null, false));
        expect(exp.soundConfirmedFor(snap), isFalse);
        // Sin prueba vigente no se inicia; la siguiente prueba usa el nuevo.
        expect(exp.start(), completion(isFalse));
        exp.testSound();
        a.elapse(const Duration(milliseconds: 100));
        expect(engine.testPatterns, ['patron_2']);
        c.dispose();
        db.close();
        a.flushMicrotasks();
      });
    });

    test('la respuesta tardía de una prueba antigua no confirma el patrón '
        'nuevo', () {
      fakeAsync((a) {
        final c = container();
        final exp = c.read(experimentalMonitoringProvider.notifier);
        exp.refresh();
        a.elapse(const Duration(milliseconds: 200));
        engine.hold = Completer<void>();
        exp.testSound();
        a.flushMicrotasks();
        expect(engine.testPatterns, ['patron_1']);

        // Se guarda otro patrón mientras la prueba del Patrón 1 sigue sin
        // respuesta: el cambio no espera a esa orden.
        c.read(preferencesProvider.notifier).setSoundPattern('patron_2');
        release(a, 0);
        a.elapse(const Duration(milliseconds: 50));
        expect(engine.calls, contains('soundPattern:patron_2'));

        // Llega tarde la prueba antigua, con el Patrón 1 reproducido. El
        // reenvío del patrón queda retenido: se comprueba la ventana en que
        // Flutter ve una prueba válida… de otro patrón.
        engine.patternHold = Completer<void>();
        engine.next = fakeSnapshot(
          soundPatternId: 'patron_1',
          soundTestId: 'snd-old',
          soundTestPlayed: true,
        );
        engine.release();
        a.elapse(const Duration(milliseconds: 50));
        expect(
          exp.soundTestPlayedFor(
            c.read(experimentalMonitoringProvider).snapshot,
          ),
          isFalse,
          reason: 'la prueba es de otro patrón',
        );
        expect(exp.confirmSoundHeard(), completion(isFalse));
        a.flushMicrotasks();
        expect(
          engine.calls.where((x) => x.startsWith('confirmSound:')),
          isEmpty,
        );
        expect(exp.start(), completion(isFalse));
        a.flushMicrotasks();
        expect(engine.calls.where((x) => x.startsWith('start:')), isEmpty);
        // Y el motor vuelve a recibir el patrón guardado.
        engine.patternHold!.complete();
        a.elapse(const Duration(milliseconds: 300));
        expect(engine.current.soundPatternId, 'patron_2');
        expect(engine.current.soundTestId, isNull);
        c.dispose();
        db.close();
        a.flushMicrotasks();
      });
    });

    test('con sesión vigente el motor conserva su patrón; al terminar recibe '
        'el guardado, sin reintentos durante la sesión', () {
      fakeAsync((a) {
        final c = container(
          engineState: fakeSnapshot(
            lifecycle: EngineSessionLifecycle.active,
            sessionId: 'S1',
          ),
        );
        c.read(experimentalMonitoringProvider.notifier).refresh();
        a.elapse(const Duration(milliseconds: 200));
        expect(c.read(settingsLockedProvider), isTrue);
        c.read(preferencesProvider.notifier).setSoundPattern('patron_3');
        release(a, 0);
        a.elapse(const Duration(seconds: 2));
        expect(
          engine.calls.where((x) => x.startsWith('soundPattern:')),
          hasLength(1),
        );
        expect(engine.current.soundPatternId, 'patron_1');

        engine.emit(
          fakeSnapshot(
            sequence: 900,
            lifecycle: EngineSessionLifecycle.finalized,
            sessionId: 'S1',
          ),
        );
        a.elapse(const Duration(milliseconds: 300));
        expect(c.read(settingsLockedProvider), isFalse);
        expect(engine.current.soundPatternId, 'patron_3');
        c.dispose();
        db.close();
        a.flushMicrotasks();
      });
    });

    test('no se inicia con una prueba confirmada de otro patrón mientras el '
        'motor no recibe el guardado', () {
      fakeAsync((a) {
        final c = container(
          initial: const StoredPreferences(soundPatternId: 'patron_2'),
          engineState: fakeSnapshot(
            eyesValid: true,
            step: CalibrationStep.accepted,
            calibrationId: 'cal-1',
            soundTestId: 'snd-1',
            soundTestPlayed: true,
            soundHeard: true,
          ),
        );
        engine.patternHold = Completer<void>();
        final exp = c.read(experimentalMonitoringProvider.notifier);
        exp.refresh();
        a.elapse(const Duration(milliseconds: 200));
        final snap = c.read(experimentalMonitoringProvider).snapshot!;
        expect((snap.soundPatternId, snap.soundHeard), ('patron_1', true));
        expect(exp.soundConfirmedFor(snap), isFalse);
        expect(exp.start(), completion(isFalse));
        a.flushMicrotasks();
        expect(engine.calls.where((x) => x.startsWith('start:')), isEmpty);
        engine.patternHold!.complete();
        a.elapse(const Duration(milliseconds: 200));
        expect(engine.current.soundPatternId, 'patron_2');
        expect(engine.current.soundHeard, isFalse);
        c.dispose();
        db.close();
        a.flushMicrotasks();
      });
    });

    test('un motor nuevo (proceso reabierto) recibe el patrón guardado', () {
      fakeAsync((a) {
        final c = container(
          initial: const StoredPreferences(soundPatternId: 'patron_3'),
        );
        c.read(experimentalMonitoringProvider.notifier).refresh();
        a.elapse(const Duration(milliseconds: 300));
        expect(engine.current.soundPatternId, 'patron_3');
        engine.emit(fakeSnapshot(engine: 'motor-2', sequence: 1));
        a.elapse(const Duration(milliseconds: 300));
        expect(engine.current.engineInstanceId, 'motor-2');
        expect(engine.current.soundPatternId, 'patron_3');
        c.dispose();
        db.close();
        a.flushMicrotasks();
      });
    });
  });

  test('reapertura: el arranque de la normal carga las preferencias de su '
      'base', () async {
    const channel = MethodChannel('vigia/app');
    TestWidgetsFlutterBinding.ensureInitialized();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      channel,
      (call) async => realApplicationId,
    );
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    final opened = <NativeDatabase>[];
    Future<ProviderContainer> launch() async {
      final overrides = await bootstrap(
        const RealMode(),
        openDatabase: (name) {
          final e = NativeDatabase(File('${dir.path}/$name.sqlite'));
          opened.add(e);
          return e;
        },
      );
      return ProviderContainer(
        overrides: [
          appModeProvider.overrideWithValue(const RealMode()),
          ...overrides,
        ],
      );
    }

    var c = await launch();
    final ctl = c.read(preferencesProvider.notifier);
    await Future.wait([
      ctl.setTheme(ThemePreference.light),
      ctl.setSoundPattern('patron_2'),
      ctl.setReducedMotion(true),
    ]);
    c.dispose();
    await opened.last.close();

    c = await launch();
    expect(
      c.read(preferencesProvider).value,
      const StoredPreferences(
        theme: ThemePreference.light,
        soundPatternId: 'patron_2',
        reducedMotion: true,
      ),
    );
    expect(c.read(themeModeProvider), ThemeMode.light);
    c.dispose();
    await opened.last.close();
  });

  group('Ajustes P12 / Sonido P13 en la variante normal', () {
    late ExperimentalHistoryDatabase db;
    late ExperimentalHistoryRepository repo;
    late FakeExperimentalBridge engine;

    setUp(() {
      db = ExperimentalHistoryDatabase(NativeDatabase.memory());
      repo = ExperimentalHistoryRepository(db);
      engine = FakeExperimentalBridge();
    });
    tearDown(() => db.close());

    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 3; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)),
        );
        await tester.pump(const Duration(milliseconds: 200));
      }
      await tester.pumpAndSettle();
    }

    Future<void> pumpReal(WidgetTester tester) async {
      await loadVigiaFonts();
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = const Size(400, 2400) * 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        VigiaApp(
          mode: const RealMode(),
          overrides: [
            ...realOverrides(repo, await repo.loadPreferences()),
            experimentalJournalBridgeProvider.overrideWithValue(FakeJournal()),
            experimentalBridgeProvider.overrideWithValue(engine),
          ],
        ),
      );
      await settle(tester);
    }

    ProviderContainer containerOf(WidgetTester tester) =>
        ProviderScope.containerOf(tester.element(find.byType(Navigator).first));

    Future<void> tapText(WidgetTester tester, String text) async {
      final f = find.text(text);
      await tester.ensureVisible(f.first);
      await tester.tap(f.first);
      await settle(tester);
    }

    testWidgets('Inicio → Ajustes: sin rótulo DEMO; el tema se aplica y se '
        'guarda en la base real', (tester) async {
      await pumpReal(tester);
      await tester.tap(find.bySemanticsLabel('Ajustes').first);
      await settle(tester);
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text(DemoLabel.text), findsNothing);
      expect(
        find.textContaining('Vigía DEMO guarda las suyas'),
        findsOneWidget,
      );

      await tapText(tester, 'Oscuro');
      expect(find.text('Preferencia guardada'), findsOneWidget);
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.dark);
      final saved = await tester.runAsync(repo.loadPreferences);
      expect(saved!.theme, ThemePreference.dark);

      await tapText(tester, 'Reducido');
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark,
      );
      expect(
        (await tester.runAsync(repo.loadPreferences))!.reducedMotion,
        isTrue,
      );
    });

    testWidgets(
      'Sonido: la prueba la reproduce el motor con el patrón elegido; '
      'guardar persiste y llega al motor',
      (tester) async {
        await pumpReal(tester);
        containerOf(tester).read(routerProvider).go(VigiaRoutes.sonido);
        await settle(tester);
        expect(find.byType(SoundScreen), findsOneWidget);
        expect(find.text(DemoLabel.text), findsNothing);

        await tapText(tester, 'Patrón 2');
        await tapText(tester, 'Probar sonido');
        expect(engine.calls, contains('preview:patron_2'));
        expect(
          engine.current.soundPatternId,
          'patron_1',
          reason: 'solo prueba',
        );
        expect(
          find.textContaining('Reproducción de prueba correcta'),
          findsOneWidget,
        );

        engine.rejectPreview = 'alarmVolumeZero';
        await tapText(tester, 'Probar sonido');
        expect(find.text('El volumen de alarma está en cero.'), findsOneWidget);

        await tapText(tester, 'Guardar');
        expect(find.text('Patrón guardado'), findsOneWidget);
        expect(
          (await tester.runAsync(repo.loadPreferences))!.soundPatternId,
          'patron_2',
        );
        expect(engine.calls, contains('soundPattern:patron_2'));
        expect(engine.current.soundPatternId, 'patron_2');
      },
    );

    testWidgets('fallo al guardar el patrón: mensaje específico y el patrón '
        'anterior sigue en la base y en el motor', (tester) async {
      await pumpReal(tester);
      await tester.runAsync(
        () => db.customStatement(
          "CREATE TRIGGER no_prefs BEFORE INSERT ON preferences "
          "BEGIN SELECT RAISE(ABORT, 'disco lleno'); END",
        ),
      );
      containerOf(tester).read(routerProvider).go(VigiaRoutes.sonido);
      await settle(tester);
      await tapText(tester, 'Patrón 3');
      await tapText(tester, 'Guardar');
      expect(find.text('Patrón no guardado'), findsOneWidget);
      expect(
        find.text(
          'No se pudo guardar el Patrón 3. Las alertas siguen con el Patrón 1.',
        ),
        findsOneWidget,
      );
      expect(find.text('Patrón guardado'), findsNothing);
      expect(engine.current.soundPatternId, 'patron_1');
      expect(
        (await tester.runAsync(repo.loadPreferences))!.soundPatternId,
        'patron_1',
      );
    });

    testWidgets('sesión experimental vigente: solo el tema; Sonido bloqueado '
        'y vuelve al monitoreo experimental', (tester) async {
      engine.current = fakeSnapshot(
        lifecycle: EngineSessionLifecycle.paused,
        sessionId: 'S1',
      );
      await pumpReal(tester);
      final c = containerOf(tester);
      c.read(experimentalMonitoringProvider.notifier).refresh();
      await settle(tester);
      c.read(routerProvider).go(VigiaRoutes.ajustes);
      await settle(tester);
      expect(find.text('Sesión en curso'), findsOneWidget);
      expect(
        find.text('Sonido · bloqueado por sesión vigente'),
        findsOneWidget,
      );
      await tapText(tester, 'Reducido');
      expect(c.read(preferencesProvider).value.reducedMotion, isFalse);
      await tapText(tester, 'Oscuro');
      expect(c.read(preferencesProvider).value.theme, ThemePreference.dark);

      c.read(routerProvider).go(VigiaRoutes.sonido);
      await settle(tester);
      expect(find.textContaining('Sonido no está disponible'), findsOneWidget);
      expect(find.text('Probar sonido'), findsNothing);
      expect(
        c.read(routerProvider).routerDelegate.currentConfiguration.uri.path,
        VigiaRoutes.sonido,
      );
      c.read(experimentalMonitoringProvider.notifier).leave();
    });
  });
}
