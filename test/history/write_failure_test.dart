import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia/core/audio/alert_sound.dart';
import 'package:vigia/core/clock/monotonic_clock.dart';
import 'package:vigia/data/demo_history/demo_history_database.dart';
import 'package:vigia/data/demo_history/demo_history_repository.dart';
import 'package:vigia/data/demo_history/history_providers.dart';
import 'package:vigia/features/monitoring/demo_session_controller.dart';
import 'package:vigia/features/monitoring/domain/session_model.dart';
import 'package:vigia/features/monitoring/domain/session_summary.dart';
import 'package:vigia/features/preparation/preparation_controller.dart';
import 'package:vigia/features/preparation/preparation_state.dart';
import 'package:vigia/features/settings/preferences_controller.dart';

import '../support/fake_sound.dart';
import '../support/history_harness.dart';

/// Repositorio real cuyas escrituras de cierre o preferencias fallan a
/// voluntad (disco lleno, base bloqueada…).
class _FailingRepo implements DemoHistoryRepository {
  _FailingRepo(this.inner);

  final DemoHistoryRepository inner;
  var failFinalize = false;
  var failPreferences = false;

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
  ) => failFinalize
      ? Future.error(StateError('disco lleno'))
      : inner.finalize(id, e, s, end);
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
  @override
  Future<void> savePreferences(StoredPreferences p) => failPreferences
      ? Future.error(StateError('disco lleno'))
      : inner.savePreferences(p);
}

void main() {
  late DemoHistoryDatabase db;
  late _FailingRepo repo;
  setUp(() async {
    final (d, r) = await openMemoryHistory();
    db = d;
    repo = _FailingRepo(r);
  });
  tearDown(() => db.close());

  ProviderContainer container() => ProviderContainer(
    overrides: [
      monotonicClockProvider.overrideWith((ref) => PackageClock()),
      alertSoundPlayerProvider.overrideWithValue(FakeSoundPlayer()),
      demoHistoryRepositoryProvider.overrideWithValue(repo),
    ],
  );

  void ready(ProviderContainer c, FakeAsync async) {
    final p = c.read(preparationProvider.notifier);
    p.acceptCalibration();
    p.testSound();
    async.flushMicrotasks();
    p.confirmHeard();
  }

  test('cierre no guardado: Registro incompleto, sin resumen definitivo y '
      'sin otra sesión (ER12, Área 06 §3)', () {
    fakeAsync((async) {
      final c = container();
      ready(c, async);
      final s = c.read(demoSessionProvider.notifier);
      expect(s.requestStart(), isTrue);
      async.elapse(const Duration(milliseconds: 700));
      async.elapse(const Duration(seconds: 10));
      repo.failFinalize = true;
      s.requestFinish();
      async.elapse(const Duration(milliseconds: 700));
      expect(c.read(historySyncProvider).failure, isNotNull);
      final id = c.read(demoSessionProvider).sessionId!;
      final stored = flushed(async, repo.session(id))!;
      expect(stored.isFinalized, isFalse);
      expect(stored.summary, isNull);
      ready(c, async);
      expect(c.read(preparationProvider).ready, isTrue);
      expect(s.requestStart(), isFalse);
      c.dispose();
    });
  });

  test('tema y patrón no guardados no cambian; el patrón no reinicia la '
      'prueba de sonido', () {
    fakeAsync((async) {
      final c = container();
      ready(c, async);
      final prefs = c.read(preferencesProvider.notifier);
      repo.failPreferences = true;

      prefs.setTheme(ThemePreference.dark);
      async.flushMicrotasks();
      expect(c.read(preferencesProvider).value.theme, ThemePreference.system);
      expect(c.read(preferencesProvider).save, PreferenceSave.failed);

      prefs.setSoundPattern('patron_2');
      async.flushMicrotasks();
      expect(c.read(preferencesProvider).value.soundPatternId, 'patron_1');
      expect(c.read(preferencesProvider).save, PreferenceSave.failed);
      expect(c.read(preparationProvider).sound, SoundCheck.confirmed);

      repo.failPreferences = false;
      prefs.setSoundPattern('patron_2');
      async.flushMicrotasks();
      expect(c.read(preferencesProvider).value.soundPatternId, 'patron_2');
      expect(c.read(preparationProvider).sound, SoundCheck.pending);
      c.dispose();
    });
  });
}
