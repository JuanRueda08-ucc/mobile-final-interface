import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia/core/audio/alert_sound.dart';
import 'package:vigia/core/clock/monotonic_clock.dart';
import 'package:vigia/features/calibration/calibration_controller.dart';
import 'package:vigia/features/monitoring/demo_session_controller.dart';
import 'package:vigia/features/monitoring/domain/session_model.dart';
import 'package:vigia/features/preparation/preparation_controller.dart';
import 'package:vigia/features/preparation/preparation_state.dart';

import '../support/fake_sound.dart';

/// Pruebas del dominio demostrativo: preparación, calibración y sesión, con
/// tiempo y temporizadores controlados (`fakeAsync`).
void main() {
  late FakeSoundPlayer sound;

  ProviderContainer container() => ProviderContainer(
    overrides: [
      monotonicClockProvider.overrideWith((ref) => PackageClock()),
      alertSoundPlayerProvider.overrideWithValue(sound),
    ],
  );

  setUp(() => sound = FakeSoundPlayer());

  /// Deja la preparación lista: referencia aceptada y sonido confirmado.
  void makeReady(ProviderContainer c, FakeAsync async) {
    final prep = c.read(preparationProvider.notifier);
    if (!c.read(preparationProvider).referenceApplicable) {
      prep.acceptCalibration();
    }
    prep.testSound();
    async.flushMicrotasks();
    prep.confirmHeard();
  }

  const confirm = Duration(milliseconds: 700);
  DemoSessionController session(ProviderContainer c) =>
      c.read(demoSessionProvider.notifier);
  DemoSessionState st(ProviderContainer c) => c.read(demoSessionProvider);

  /// Inicia y confirma una sesión.
  void start(ProviderContainer c, FakeAsync async) {
    makeReady(c, async);
    expect(session(c).requestStart(), isTrue);
    async.elapse(confirm);
    expect(st(c).lifecycle, SessionLifecycle.active);
  }

  group('Preparación (RF04, RF05, RF07)', () {
    test('cada condición falsa bloquea el inicio con su causa (RF05.CA2)', () {
      fakeAsync((async) {
        final c = container();
        makeReady(c, async);
        expect(c.read(preparationProvider).ready, isTrue);
        final prep = c.read(preparationProvider.notifier);
        const ok = SimulatedConditions();
        for (final (sim, cause) in [
          (ok.copyWith(permission: false), 'Cámara sin permiso'),
          (ok.copyWith(camera: false), 'Cámara no disponible'),
          (ok.copyWith(model: false), 'Modelo no disponible'),
          (ok.copyWith(eyes: false), 'Ojos no evaluables'),
          (ok.copyWith(face: false), 'Ojos no evaluables'),
        ]) {
          prep.setSimulated(sim);
          expect(c.read(preparationProvider).blockers.map((b) => b.text), [
            cause,
          ]);
          expect(session(c).requestStart(), isFalse);
          expect(st(c).lifecycle, SessionLifecycle.none);
        }
        prep.setSimulated(ok);
        expect(c.read(preparationProvider).ready, isTrue);
      });
    });

    test(
      'Lo escuché solo tras reproducción correcta; No lo escuché bloquea',
      () {
        fakeAsync((async) {
          final c = container();
          final prep = c.read(preparationProvider.notifier);
          prep.confirmHeard(); // sin reproducción: no hace nada (UX04.CA1)
          expect(c.read(preparationProvider).sound, SoundCheck.pending);
          prep.testSound();
          expect(c.read(preparationProvider).sound, SoundCheck.playing);
          async.flushMicrotasks();
          expect(c.read(preparationProvider).sound, SoundCheck.played);
          expect(sound.calls, [AlertSoundKind.test]);
          prep.notHeard();
          expect(c.read(preparationProvider).sound, SoundCheck.notHeard);
          expect(
            c.read(preparationProvider).blockers,
            contains(PreparationBlocker.sound),
          );
          sound.next = const SoundPlayback.failed('Volumen en cero');
          prep.testSound();
          async.flushMicrotasks();
          expect(c.read(preparationProvider).sound, SoundCheck.failed);
          expect(c.read(preparationProvider).soundFailure, 'Volumen en cero');
          prep.confirmHeard();
          expect(c.read(preparationProvider).sound, SoundCheck.failed);
        });
      },
    );

    test('una preparación nueva exige otra prueba de sonido (UX04.CA3)', () {
      fakeAsync((async) {
        final c = container();
        start(c, async);
        expect(c.read(preparationProvider).sound, SoundCheck.pending);
        c.read(preparationProvider.notifier).open();
        expect(c.read(preparationProvider).blockers, [
          PreparationBlocker.sound,
        ]);
      });
    });

    test('Cambié la posición invalida la referencia y exige recalibrar '
        '(RF07.CA1); cancelar no la restaura (UX05.CA3)', () {
      fakeAsync((async) {
        final c = container();
        makeReady(c, async);
        final prep = c.read(preparationProvider.notifier);
        final first = c.read(preparationProvider).reference!.id;
        prep.declareMountChanged();
        var s = c.read(preparationProvider);
        expect(s.referenceApplicable, isFalse);
        expect(s.mountChanged, isTrue);
        expect(s.blockers, [PreparationBlocker.calibration]);
        expect(session(c).requestStart(), isFalse);

        final cal = c.read(calibrationProvider.notifier);
        cal.begin();
        cal.cancel();
        expect(c.read(preparationProvider).referenceApplicable, isFalse);

        cal.begin();
        cal.simulateAccepted();
        s = c.read(preparationProvider);
        expect(s.referenceApplicable, isTrue);
        expect(s.reference!.id, isNot(first));
        expect(s.mountChanged, isFalse);
        expect(s.ready, isTrue);
      });
    });
  });

  group('Calibración (RF06, FL03)', () {
    test(
      'los tres rechazos no guardan referencia; Reintentar adquiere de nuevo',
      () {
        fakeAsync((async) {
          final c = container();
          final cal = c.read(calibrationProvider.notifier);
          cal.simulateAccepted(); // sin adquisición: ignorado
          expect(c.read(preparationProvider).reference, isNull);
          for (final r in CalibrationRejection.values) {
            cal.begin();
            expect(c.read(calibrationProvider), isA<CalibrationAcquiring>());
            cal.simulateRejected(r);
            final state = c.read(calibrationProvider);
            expect(state, isA<CalibrationRejected>());
            expect((state as CalibrationRejected).cause, r);
            expect(c.read(preparationProvider).reference, isNull);
          }
          cal.begin();
          cal.simulateAccepted();
          expect(c.read(calibrationProvider), isA<CalibrationAccepted>());
          expect(c.read(preparationProvider).referenceApplicable, isTrue);
        });
      },
    );
  });

  group('Sesión demostrativa', () {
    test('diez pulsaciones de inicio crean una sola sesión (RF08.CA1-CA2)', () {
      fakeAsync((async) {
        final c = container();
        makeReady(c, async);
        var accepted = 0;
        for (var i = 0; i < 10; i++) {
          if (session(c).requestStart()) accepted++;
        }
        expect(accepted, 1);
        expect(st(c).lifecycle, SessionLifecycle.starting);
        expect(st(c).pending, PendingOperation.start);
        expect(st(c).sessionId, isNull); // sin ID hasta confirmar
        async.elapse(confirm);
        expect(st(c).lifecycle, SessionLifecycle.active);
        expect(st(c).sessionId, 'S-DEMO-0001');
        expect(
          st(c).events.where((e) => e.type == SessionEventType.started),
          hasLength(1),
        );
        // Con sesión vigente no se inicia otra.
        expect(session(c).requestStart(), isFalse);
      });
    });

    test('pausa y reanudación conservan el ID y no acumulan la pausa', () {
      fakeAsync((async) {
        final c = container();
        start(c, async);
        final id = st(c).sessionId;
        final clock = c.read(monotonicClockProvider);
        async.elapse(const Duration(seconds: 10));
        for (var i = 0; i < 10; i++) {
          session(c).requestPause(); // RF16.CA3: una sola pausa
        }
        expect(st(c).pending, PendingOperation.pause);
        expect(st(c).lifecycle, SessionLifecycle.active);
        async.elapse(confirm);
        expect(st(c).lifecycle, SessionLifecycle.paused);
        final atPause = st(c).monitoredAt(clock.elapsed);
        expect(atPause, const Duration(milliseconds: 10700));
        final eventsAtPause = st(c).events.length;
        final soundsAtPause = sound.calls.length;

        async.elapse(const Duration(seconds: 60)); // pasa por varias alertas
        expect(st(c).monitoredAt(clock.elapsed), atPause);
        expect(st(c).events.length, eventsAtPause); // sin eventos en pausa
        expect(sound.calls.length, soundsAtPause);

        session(c).requestResume();
        expect(st(c).pending, PendingOperation.resume);
        expect(st(c).lifecycle, SessionLifecycle.paused);
        async.elapse(confirm);
        expect(st(c).lifecycle, SessionLifecycle.active);
        expect(st(c).sessionId, id);
        // La medición se reconstruye tras reanudar (RF17.CA3).
        expect(st(c).measurement, Measurement.initializing);
        async.elapse(const Duration(seconds: 5));
        expect(
          st(c).monitoredAt(clock.elapsed),
          atPause + const Duration(seconds: 5),
        );
        expect(
          st(c).events.where((e) => e.type == SessionEventType.pauseStarted),
          hasLength(1),
        );
        expect(
          st(c).events.where((e) => e.type == SessionEventType.pauseEnded),
          hasLength(1),
        );
      });
    });

    test('los eventos simulados son reproducibles y suenan las alertas', () {
      List<String> run() {
        late List<String> out;
        fakeAsync((async) {
          final c = container();
          start(c, async);
          async.elapse(const Duration(seconds: 50));
          out = [for (final e in st(c).events) e.toString()];
        });
        return out;
      }

      final a = run();
      sound = FakeSoundPlayer();
      final b = run();
      expect(a, b);
      expect(sound.calls, [
        AlertSoundKind.test, // prueba de preparación
        AlertSoundKind.warning,
        AlertSoundKind.closure,
      ]);
      expect(a.where((e) => e.contains('episodeStarted')), hasLength(2));
    });

    test('la señal cambia en el instante exacto del guion', () {
      fakeAsync((async) {
        final c = container();
        start(c, async);
        async.elapse(const Duration(milliseconds: 7999));
        expect(st(c).signal, SignalState.noPersistentSignals);
        async.elapse(const Duration(milliseconds: 1));
        expect(st(c).signal, SignalState.warning);
        expect(st(c).openEpisode?.kind, EpisodeKind.warning);
        async.elapse(const Duration(seconds: 12));
        expect(st(c).signal, SignalState.prolongedEyeClosure);
        async.elapse(const Duration(seconds: 10));
        expect(st(c).signal, SignalState.notEvaluable);
        expect(st(c).measurement, Measurement.unavailable);
      });
    });

    test('finalizar se confirma una sola vez y detiene los eventos (RF18)', () {
      fakeAsync((async) {
        final c = container();
        start(c, async);
        async.elapse(const Duration(seconds: 9)); // advertencia abierta
        for (var i = 0; i < 5; i++) {
          session(c).requestFinish();
        }
        expect(st(c).lifecycle, SessionLifecycle.stopping);
        expect(st(c).pending, PendingOperation.finish);
        async.elapse(confirm);
        expect(st(c).lifecycle, SessionLifecycle.finalized);
        final events = st(c).events.length;
        final sounds = sound.calls.length;
        async.elapse(const Duration(minutes: 5));
        expect(st(c).events.length, events);
        expect(sound.calls.length, sounds);
        expect(
          st(c).events.where((e) => e.type == SessionEventType.finished),
          hasLength(1),
        );
        session(c).requestFinish();
        session(c).requestPause();
        session(c).requestResume();
        expect(st(c).lifecycle, SessionLifecycle.finalized);
        expect(st(c).events.length, events);
        // El episodio abierto se cierra con la solicitud de cierre.
        expect(
          st(c).events.where((e) => e.type == SessionEventType.episodeEnded),
          hasLength(1),
        );
      });
    });

    test('el resumen se calcula desde los eventos de esa sesión (RF21)', () {
      fakeAsync((async) {
        final c = container();
        start(c, async);
        async.elapse(const Duration(seconds: 50));
        session(c).requestFinish();
        async.elapse(confirm);
        final s = c.read(lastSummaryProvider)!;
        expect(s.sessionId, 'S-DEMO-0001');
        // Guion: 2 s inicializando, 4 s no disponible y 3 s limitada.
        expect(s.notEvaluable, const Duration(seconds: 9));
        expect(s.evaluable, const Duration(seconds: 41));
        expect(s.paused, Duration.zero);
        expect(s.unknown, Duration.zero);
        expect(s.represented, const Duration(seconds: 50));
        expect(s.coverageText, '82,0 %');
        expect(s.episodes, 2);
        expect((s.warnings, s.closures), (1, 1));
        expect(s.soundsPlayed, 2);
      });
    });

    test('resumen con pausa: la pausa no entra en la cobertura (UX14)', () {
      fakeAsync((async) {
        final c = container();
        start(c, async);
        async.elapse(const Duration(seconds: 10)); // advertencia abierta
        session(c).requestPause();
        async.elapse(confirm); // pausa confirmada en 10,7 s activos
        async.elapse(const Duration(seconds: 20));
        session(c).requestFinish(); // cierre desde Pausada
        async.elapse(confirm);
        final s = c.read(lastSummaryProvider)!;
        expect(s.paused, const Duration(seconds: 20));
        expect(s.notEvaluable, const Duration(seconds: 2));
        expect(s.evaluable, const Duration(milliseconds: 8700));
        expect(s.coverageText, '81,3 %');
        expect(s.pauses, 1);
        expect(s.episodes, 1);
      });
    });

    test('un fallo de sonido es visible y no cambia episodios ni medición', () {
      fakeAsync((async) {
        sound.next = const SoundPlayback.failed(
          'El volumen multimedia está en cero.',
        );
        final c = container();
        makeReady(c, async); // la prueba de preparación usa ese fallo...
        expect(c.read(preparationProvider).sound, SoundCheck.failed);
        sound.next = const SoundPlayback.played(); // ...y se corrige
        start(c, async);
        sound.next = const SoundPlayback.failed(
          'El volumen multimedia está en cero.',
        );
        async.elapse(const Duration(seconds: 9));
        expect(st(c).signal, SignalState.warning);
        expect(st(c).measurement, Measurement.usable);
        expect(st(c).soundFailure, 'El volumen multimedia está en cero.');
        expect(
          st(c).events.where((e) => e.type == SessionEventType.soundFailed),
          hasLength(1),
        );
        session(c).requestFinish();
        async.elapse(confirm);
        final s = c.read(lastSummaryProvider)!;
        expect(s.episodes, 1);
        expect(s.soundsFailed, 1);
      });
    });
  });
}
