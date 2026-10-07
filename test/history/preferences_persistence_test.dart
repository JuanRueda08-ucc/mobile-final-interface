import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia/app/bootstrap.dart';
import 'package:vigia/app/vigia_app.dart';
import 'package:vigia/app/router.dart';
import 'package:vigia/app/app_config.dart';
import 'package:vigia/core/audio/alert_sound.dart';
import 'package:vigia/core/clock/monotonic_clock.dart';
import 'package:vigia/data/demo_history/demo_history_database.dart';
import 'package:vigia/data/demo_history/demo_history_repository.dart';
import 'package:vigia/features/monitoring/demo_session_controller.dart';
import 'package:vigia/features/monitoring/domain/session_model.dart';
import 'package:vigia/features/monitoring/domain/session_summary.dart';
import 'package:vigia/features/preparation/preparation_controller.dart';
import 'package:vigia/features/preparation/preparation_state.dart';
import 'package:vigia/features/settings/preferences_controller.dart';

import '../support/fake_sound.dart';

/// Repositorio real sobre disco cuyas escrituras de preferencias esperan a que
/// la prueba las libere (o las haga fallar), para controlar el orden.
class _GatedRepo implements DemoHistoryRepository {
  _GatedRepo(this.inner);

  final DemoHistoryRepository inner;
  final gates = <Completer<void>>[];

  /// Preferencias pedidas a cada escritura, en orden de llegada.
  final requested = <StoredPreferences>[];

  @override
  Future<void> savePreferences(StoredPreferences p) async {
    final gate = Completer<void>();
    gates.add(gate);
    requested.add(p);
    await gate.future; // lanza si la prueba la completa con error
    await inner.savePreferences(p);
  }

  @override
  int reserveSessionNumber() => inner.reserveSessionNumber();
  @override
  int reserveCalibrationNumber() => inner.reserveCalibrationNumber();
  @override
  Future<void> recordStart(SessionStartRecord s, List<SessionEvent> e) =>
      inner.recordStart(s, e);
  @override
  Future<void> appendEvents(
    String id,
    List<SessionEvent> e,
    StoredLifecycle l,
  ) => inner.appendEvents(id, e, l);
  @override
  Future<bool> finalize(
    String id,
    List<SessionEvent> e,
    SessionSummary s,
    Duration end,
  ) => inner.finalize(id, e, s, end);
  @override
  Future<int> markInterrupted() => inner.markInterrupted();
  @override
  Future<List<StoredSession>> sessions({
    HistoryFilter filter = HistoryFilter.all,
  }) => inner.sessions(filter: filter);
  @override
  Future<StoredSession?> session(String id) => inner.session(id);
  @override
  Future<StoredSession?> latestSession() => inner.latestSession();
  @override
  Future<List<SessionEvent>> events(String id) => inner.events(id);
  @override
  Future<StoredPreferences> loadPreferences() => inner.loadPreferences();
}

/// Sonido cuya primera prueba responde cuando la prueba lo decide.
class _LateFirstTest implements AlertSoundPlayer {
  final first = Completer<SoundPlayback>();
  final calls = <String>[];

  @override
  Future<SoundPlayback> play(
    AlertSoundKind kind, {
    String patternId = 'patron_1',
  }) {
    calls.add('${kind.name}:$patternId');
    return calls.length == 1
        ? first.future
        : Future.value(const SoundPlayback.played());
  }
}

void main() {
  late Directory dir;
  late File file;
  setUp(() async {
    dir = await Directory.systemTemp.createTemp('vigia_prefs_');
    file = File('${dir.path}/vigia_history_demo_v1.sqlite');
  });
  tearDown(() => dir.delete(recursive: true));

  /// Abre la base del archivo con una conexión nueva.
  DemoHistoryDatabase openDb() => DemoHistoryDatabase(NativeDatabase(file));

  /// Preferencias leídas con una conexión nueva, cerrada al terminar.
  Future<StoredPreferences> reread() async {
    final db = openDb();
    try {
      return await (await DriftDemoHistoryRepository.open(db))
          .loadPreferences();
    } finally {
      await db.close();
    }
  }

  group('Repositorio: fila única de preferencias (P1)', () {
    test('segundo guardado tras cerrar y abrir otra conexión', () async {
      var db = openDb();
      var repo = await DriftDemoHistoryRepository.open(db);
      await repo.savePreferences(
        const StoredPreferences(theme: ThemePreference.dark),
      );
      await db.close();

      db = openDb();
      repo = await DriftDemoHistoryRepository.open(db);
      await repo.savePreferences(
        const StoredPreferences(
          theme: ThemePreference.dark,
          reducedMotion: true,
          soundPatternId: 'patron_2',
        ),
      );
      await db.close();

      expect(
        await reread(),
        const StoredPreferences(
          theme: ThemePreference.dark,
          reducedMotion: true,
          soundPatternId: 'patron_2',
        ),
      );
    });

    test(
      'varios guardados seguidos en la misma conexión dejan una fila',
      () async {
        final db = openDb();
        final repo = await DriftDemoHistoryRepository.open(db);
        for (final p in const [
          StoredPreferences(theme: ThemePreference.dark),
          StoredPreferences(theme: ThemePreference.light, reducedMotion: true),
          StoredPreferences(soundPatternId: 'patron_3'),
          StoredPreferences(
            theme: ThemePreference.dark,
            soundPatternId: 'patron_2',
          ),
        ]) {
          await repo.savePreferences(p);
          expect(await repo.loadPreferences(), p);
        }
        final rows = await db
            .customSelect('SELECT singleton FROM preferences')
            .get();
        expect(rows.map((r) => r.read<int>('singleton')), [1]);
        await db.close();
      },
    );
  });

  group('Controlador: operaciones simultáneas (P2)', () {
    late DemoHistoryDatabase db;
    late _GatedRepo repo;
    late FakeSoundPlayer sound;

    ProviderContainer container({AlertSoundPlayer? player}) =>
        ProviderContainer(
          overrides: [
            ...demoOverrides(repo, const StoredPreferences()),
            monotonicClockProvider.overrideWith((ref) => PackageClock()),
            alertSoundPlayerProvider.overrideWithValue(player ?? sound),
          ],
        );

    /// Abre la base y deja la prueba de sonido confirmada con el patrón 1.
    ProviderContainer ready(FakeAsync a, {AlertSoundPlayer? player}) {
      db = openDb();
      late DriftDemoHistoryRepository inner;
      DriftDemoHistoryRepository.open(db).then((r) => inner = r);
      a.flushMicrotasks();
      repo = _GatedRepo(inner);
      sound = FakeSoundPlayer();
      final c = container(player: player);
      final p = c.read(preparationProvider.notifier);
      p.open();
      p.acceptCalibration();
      p.testSound();
      a.flushMicrotasks();
      p.confirmHeard();
      expect(c.read(preparationProvider).sound, SoundCheck.confirmed);
      return c;
    }

    /// Libera la escritura pendiente número [i].
    void release(FakeAsync a, int i, {bool fail = false}) {
      a.flushMicrotasks();
      final gate = repo.gates[i];
      fail ? gate.completeError(StateError('disco lleno')) : gate.complete();
      a.flushMicrotasks();
    }

    StoredPreferences value(ProviderContainer c) =>
        c.read(preferencesProvider).value;

    /// Cierra la conexión y relee las preferencias con otra nueva.
    StoredPreferences closeAndReread(ProviderContainer c, FakeAsync a) {
      c.dispose();
      db.close();
      a.flushMicrotasks();
      late StoredPreferences p;
      reread().then((v) => p = v);
      a.flushMicrotasks();
      return p;
    }

    test('patrón 2 y en seguida Oscuro: se conservan los dos', () {
      fakeAsync((a) {
        final c = ready(a);
        final prefs = c.read(preferencesProvider.notifier);
        var patternOk = false;
        prefs.setSoundPattern('patron_2').then((ok) => patternOk = ok);
        prefs.setTheme(ThemePreference.dark);
        // El tema se ve en el acto; el patrón solo al guardarse.
        expect(value(c).theme, ThemePreference.dark);
        expect(value(c).soundPatternId, 'patron_1');
        release(a, 0);
        expect(patternOk, isTrue);
        expect(value(c).soundPatternId, 'patron_2');
        expect(c.read(preparationProvider).sound, SoundCheck.pending);
        release(a, 1);
        // La segunda escritura parte de la primera guardada.
        expect(repo.requested.last.soundPatternId, 'patron_2');
        expect(
          value(c),
          const StoredPreferences(
            theme: ThemePreference.dark,
            soundPatternId: 'patron_2',
          ),
        );
        expect(c.read(preferencesProvider).save, PreferenceSave.saved);
        expect(
          closeAndReread(c, a),
          const StoredPreferences(
            theme: ThemePreference.dark,
            soundPatternId: 'patron_2',
          ),
        );
      });
    });

    test('Oscuro y en seguida patrón 2 (orden inverso)', () {
      fakeAsync((a) {
        final c = ready(a);
        final prefs = c.read(preferencesProvider.notifier);
        prefs.setTheme(ThemePreference.dark);
        prefs.setSoundPattern('patron_2');
        release(a, 0);
        expect(value(c).theme, ThemePreference.dark);
        expect(value(c).soundPatternId, 'patron_1');
        expect(c.read(preferencesProvider).save, PreferenceSave.saving);
        release(a, 1);
        expect(repo.requested.last.theme, ThemePreference.dark);
        expect(
          value(c),
          const StoredPreferences(
            theme: ThemePreference.dark,
            soundPatternId: 'patron_2',
          ),
        );
        expect(c.read(preparationProvider).sound, SoundCheck.pending);
        expect(
          closeAndReread(c, a),
          const StoredPreferences(
            theme: ThemePreference.dark,
            soundPatternId: 'patron_2',
          ),
        );
      });
    });

    test('tema, movimiento y patrón combinados terminan iguales en memoria y '
        'en SQLite', () {
      fakeAsync((a) {
        final c = ready(a);
        final prefs = c.read(preferencesProvider.notifier);
        prefs.setTheme(ThemePreference.dark);
        prefs.setReducedMotion(true);
        prefs.setSoundPattern('patron_3');
        prefs.setTheme(ThemePreference.light);
        // Mientras se guardan, se ven los cambios de tema y movimiento.
        expect(value(c).theme, ThemePreference.light);
        expect(value(c).reducedMotion, isTrue);
        // Liberar en orden inverso no cambia el orden de aplicación.
        for (var i = 0; i < 4; i++) {
          release(a, i);
        }
        const expected = StoredPreferences(
          theme: ThemePreference.light,
          reducedMotion: true,
          soundPatternId: 'patron_3',
        );
        expect(repo.requested.last, expected);
        expect(value(c), expected);
        expect(c.read(preferencesProvider).save, PreferenceSave.saved);
        expect(closeAndReread(c, a), expected);
      });
    });

    test('un fallo no se presenta como guardado ni pierde lo ya aceptado', () {
      fakeAsync((a) {
        final c = ready(a);
        final prefs = c.read(preferencesProvider.notifier);
        prefs.setTheme(ThemePreference.dark);
        var patternOk = true;
        prefs.setSoundPattern('patron_2').then((ok) => patternOk = ok);
        prefs.setReducedMotion(true);
        release(a, 0); // Oscuro guardado
        release(a, 1, fail: true); // patrón 2 no guardado
        expect(patternOk, isFalse);
        expect(value(c).soundPatternId, 'patron_1');
        expect(c.read(preparationProvider).sound, SoundCheck.confirmed);
        release(a, 2); // movimiento guardado sobre Oscuro y patrón 1
        const expected = StoredPreferences(
          theme: ThemePreference.dark,
          reducedMotion: true,
        );
        expect(repo.requested.last, expected);
        expect(value(c), expected);
        expect(c.read(preferencesProvider).save, PreferenceSave.failed);
        expect(closeAndReread(c, a), expected);
      });
    });

    /// Aviso de la preferencia [f] tal como lo mostraría Ajustes.
    String? failureText(ProviderContainer c, PreferenceField f) {
      final st = c.read(preferencesProvider);
      final failure = st.failures[f];
      return failure == null ? null : preferenceFailureText(failure, st.value);
    }

    test('Oscuro falla y Reducido se guarda: el aviso es del tema', () {
      fakeAsync((a) {
        final c = ready(a);
        final prefs = c.read(preferencesProvider.notifier);
        prefs.setTheme(ThemePreference.light);
        release(a, 0); // punto de partida guardado: Claro
        prefs.setTheme(ThemePreference.dark);
        prefs.setReducedMotion(true);
        release(a, 1, fail: true);
        release(a, 2);
        const expected = StoredPreferences(
          theme: ThemePreference.light,
          reducedMotion: true,
        );
        expect(value(c), expected);
        expect(c.read(preferencesProvider).failures.keys, [
          PreferenceField.theme,
        ]);
        expect(
          failureText(c, PreferenceField.theme),
          'No se pudo guardar el tema oscuro. El tema sigue en Claro.',
        );
        expect(failureText(c, PreferenceField.reducedMotion), isNull);
        expect(closeAndReread(c, a), expected);
      });
    });

    test('Reducido falla y Oscuro se guarda: el aviso es del movimiento', () {
      fakeAsync((a) {
        final c = ready(a);
        final prefs = c.read(preferencesProvider.notifier);
        prefs.setReducedMotion(true);
        prefs.setTheme(ThemePreference.dark);
        release(a, 0, fail: true);
        release(a, 1);
        const expected = StoredPreferences(theme: ThemePreference.dark);
        expect(value(c), expected);
        expect(c.read(preferencesProvider).failures.keys, [
          PreferenceField.reducedMotion,
        ]);
        expect(
          failureText(c, PreferenceField.reducedMotion),
          'No se pudo guardar el movimiento reducido. El movimiento sigue '
          'según Android.',
        );
        expect(failureText(c, PreferenceField.theme), isNull);
        expect(closeAndReread(c, a), expected);
      });
    });

    test('un fallo seguido de otro cambio guardado de la misma preferencia no '
        'deja aviso que contradiga el valor vigente', () {
      fakeAsync((a) {
        final c = ready(a);
        final prefs = c.read(preferencesProvider.notifier);
        // Cambio repetido mientras el primero se guarda.
        prefs.setTheme(ThemePreference.dark);
        prefs.setTheme(ThemePreference.light);
        release(a, 0, fail: true);
        expect(c.read(preferencesProvider).failures, isEmpty);
        release(a, 1);
        expect(value(c).theme, ThemePreference.light);
        expect(c.read(preferencesProvider).failures, isEmpty);
        expect(c.read(preferencesProvider).save, PreferenceSave.saved);

        // Cambio repetido después de ver el aviso.
        prefs.setSoundPattern('patron_2');
        release(a, 2, fail: true);
        expect(
          failureText(c, PreferenceField.soundPattern),
          'No se pudo guardar el Patrón 2. Las alertas siguen con el '
          'Patrón 1.',
        );
        prefs.setSoundPattern('patron_3');
        expect(c.read(preferencesProvider).failures, isEmpty);
        release(a, 3);
        expect(value(c).soundPatternId, 'patron_3');
        expect(c.read(preferencesProvider).failures, isEmpty);
        expect(c.read(preferencesProvider).save, PreferenceSave.saved);
        expect(
          closeAndReread(c, a),
          const StoredPreferences(
            theme: ThemePreference.light,
            soundPatternId: 'patron_3',
          ),
        );
      });
    });

    test('un tema que no se guarda vuelve al guardado', () {
      fakeAsync((a) {
        final c = ready(a);
        final prefs = c.read(preferencesProvider.notifier);
        prefs.setTheme(ThemePreference.dark);
        expect(value(c).theme, ThemePreference.dark);
        release(a, 0, fail: true);
        expect(value(c).theme, ThemePreference.system);
        expect(c.read(preferencesProvider).save, PreferenceSave.failed);
        expect(closeAndReread(c, a), const StoredPreferences());
      });
    });

    test('la respuesta tardía de la prueba con el patrón anterior no habilita '
        'Lo escuché; la alerta siguiente usa el patrón guardado', () {
      fakeAsync((a) {
        final player = _LateFirstTest();
        db = openDb();
        late DriftDemoHistoryRepository inner;
        DriftDemoHistoryRepository.open(db).then((r) => inner = r);
        a.flushMicrotasks();
        repo = _GatedRepo(inner);
        final c = container(player: player);
        final prep = c.read(preparationProvider.notifier);
        prep.open();
        prep.acceptCalibration();
        prep.testSound(); // patrón 1, sin respuesta todavía
        c.read(preferencesProvider.notifier).setSoundPattern('patron_2');
        release(a, 0);
        player.first.complete(const SoundPlayback.played());
        a.flushMicrotasks();
        expect(c.read(preparationProvider).sound, SoundCheck.pending);
        prep.confirmHeard();
        expect(c.read(preparationProvider).sound, SoundCheck.pending);
        expect(c.read(demoSessionProvider.notifier).requestStart(), isFalse);

        prep.testSound();
        a.flushMicrotasks();
        prep.confirmHeard();
        expect(c.read(demoSessionProvider.notifier).requestStart(), isTrue);
        a.elapse(const Duration(milliseconds: 700));
        a.elapse(const Duration(seconds: 8)); // advertencia con tono
        expect(player.calls, [
          'test:patron_1',
          'test:patron_2',
          'warning:patron_2',
        ]);
        c.dispose();
        db.close();
        a.flushMicrotasks();
      });
    });
  });

  testWidgets('Ajustes: Oscuro falla y Reducido se guarda; el aviso nombra el '
      'tema y no el último cambio', (tester) async {
    final db = DemoHistoryDatabase(NativeDatabase(file));
    final inner = await DriftDemoHistoryRepository.open(db);
    await inner.savePreferences(
      const StoredPreferences(theme: ThemePreference.light),
    );
    final gated = _GatedRepo(inner);
    await tester.pumpWidget(
      VigiaApp(
        mode: const DemoMode(),
        overrides: [
          ...demoOverrides(gated, await inner.loadPreferences()),
          monotonicClockProvider.overrideWith((ref) => PackageClock()),
          alertSoundPlayerProvider.overrideWithValue(FakeSoundPlayer()),
        ],
      ),
    );
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Navigator).first),
    );
    container.read(routerProvider).go(VigiaRoutes.ajustes);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Oscuro'));
    await tester.pump();
    await tester.ensureVisible(find.text('Reducido'));
    await tester.tap(find.text('Reducido'));
    await tester.pump();
    gated.gates[0].completeError(StateError('tema rechazado'));
    await tester.pumpAndSettle();
    gated.gates[1].complete();
    await tester.pumpAndSettle();

    expect(
      find.text('No se pudo guardar el tema oscuro. El tema sigue en Claro.'),
      findsOneWidget,
    );
    expect(find.textContaining('último cambio'), findsNothing);
    expect(
      find.textContaining('No se pudo guardar el movimiento'),
      findsNothing,
    );
    expect(
      await inner.loadPreferences(),
      const StoredPreferences(
        theme: ThemePreference.light,
        reducedMotion: true,
      ),
    );
    await tester.pumpWidget(const SizedBox());
    await db.close();
  });
}
