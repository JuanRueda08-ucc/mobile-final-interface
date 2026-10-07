import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/alert_sound.dart';
import '../../data/demo_history/demo_history_repository.dart';
import '../../data/demo_history/history_providers.dart';

/// Preferencias leídas al abrir la app (las fija `bootstrap.dart`). Sin base
/// abierta (modo real o revisión de Inicio) son las iniciales y no se guardan.
final initialPreferencesProvider = Provider<StoredPreferences>(
  (ref) => const StoredPreferences(),
);

/// Resultado de las escrituras de preferencias.
enum PreferenceSave { idle, saving, saved, failed }

/// Preferencia que toca un cambio.
enum PreferenceField { theme, reducedMotion, soundPattern }

/// Escritura fallida de una preferencia concreta, con el valor pedido. El
/// valor que sigue vigente se lee de [PreferencesState.value] al mostrarlo.
final class PreferenceFailure {
  const PreferenceFailure(this.field, this.requested);

  final PreferenceField field;

  /// [ThemePreference], `bool` (movimiento reducido) o ID de patrón.
  final Object requested;
}

final class PreferencesState {
  const PreferencesState(
    this.value, {
    this.save = PreferenceSave.idle,
    this.failures = const {},
    this.pending = const {},
  });

  /// Preferencias que ve y aplica la app: las guardadas más los cambios de
  /// tema o movimiento que todavía se están guardando.
  final StoredPreferences value;

  /// `saving` mientras quede alguna escritura; al terminar, `failed` si queda
  /// algún fallo en [failures] y `saved` si no.
  final PreferenceSave save;

  /// Fallos de la última serie de cambios, por preferencia. Solo el de una
  /// preferencia cuyo valor pedido no llegó a guardarse ni se volvió a cambiar
  /// después: así un aviso no se atribuye a otro cambio aceptado ni describe
  /// un valor que ya no está vigente.
  final Map<PreferenceField, PreferenceFailure> failures;

  /// Preferencias con alguna escritura todavía sin resolver. P13 no anuncia un
  /// patrón como guardado mientras haya otro cambio de patrón pendiente.
  final Set<PreferenceField> pending;
}

/// Cambio pedido: se aplica sobre las preferencias vigentes cuando le toca.
final class _Change {
  const _Change(
    this.field,
    this.requested,
    this.apply, {
    required this.optimistic,
  });

  final PreferenceField field;
  final Object requested;
  final StoredPreferences Function(StoredPreferences) apply;

  /// Tema y movimiento se ven en el acto; el patrón, solo una vez guardado.
  final bool optimistic;
}

/// Tema, patrón de sonido y movimiento reducido (RF29, P12–P13), guardados en
/// la fila única de preferencias del historial DEMO.
///
/// Las escrituras se hacen una tras otra, en el orden pedido. Cada una aplica
/// **su** cambio sobre las últimas preferencias guardadas, así que un cambio
/// posterior no pisa con una copia antigua otro ya aceptado. Si una escritura
/// falla, su cambio se retira (también un tema que ya se veía) y se informa
/// el fallo de **esa** preferencia; lo guardado antes se conserva. Al
/// terminar, memoria, interfaz y SQLite coinciden.
class PreferencesController extends Notifier<PreferencesState> {
  /// Últimas preferencias confirmadas por SQLite (o las iniciales).
  late StoredPreferences _saved;

  /// Cambios pedidos y aún no resueltos, en orden.
  final _pending = <_Change>[];
  Future<void> _tail = Future.value();

  /// Fallos vigentes de la serie de cambios en curso o recién terminada.
  final _failures = <PreferenceField, PreferenceFailure>{};

  @override
  PreferencesState build() {
    _saved = ref.read(initialPreferencesProvider);
    return PreferencesState(_saved);
  }

  Future<bool> setTheme(ThemePreference theme) => _enqueue(
    _Change(
      PreferenceField.theme,
      theme,
      (p) => p.copyWith(theme: theme),
      optimistic: true,
    ),
  );

  Future<bool> setReducedMotion(bool reduced) => _enqueue(
    _Change(
      PreferenceField.reducedMotion,
      reduced,
      (p) => p.copyWith(reducedMotion: reduced),
      optimistic: true,
    ),
  );

  /// Guarda el patrón de las alertas. Solo cambia si quedó guardado: un fallo
  /// deja las alertas con el patrón anterior. Al cambiar, la prueba de sonido
  /// de Preparación vuelve a ser obligatoria (RF29.CA3): lo aplica
  /// `PreparationController`.
  Future<bool> setSoundPattern(String patternId) => _enqueue(
    _Change(
      PreferenceField.soundPattern,
      patternId,
      (p) => p.copyWith(soundPatternId: patternId),
      optimistic: false,
    ),
  );

  Future<bool> _enqueue(_Change change) {
    // Una serie nueva de cambios deja atrás los avisos de la anterior; volver
    // a cambiar una preferencia deja atrás el aviso de esa preferencia.
    if (_pending.isEmpty) _failures.clear();
    _failures.remove(change.field);
    _pending.add(change);
    _publish();
    final result = _tail.then((_) => _write(change));
    _tail = result;
    return result;
  }

  Future<bool> _write(_Change change) async {
    final next = change.apply(_saved);
    var ok = true;
    try {
      await ref.read(demoHistoryRepositoryProvider).savePreferences(next);
    } catch (_) {
      ok = false;
    }
    _pending.remove(change);
    if (ok) {
      _saved = next;
      _failures.remove(change.field);
    } else if (!_pending.any((c) => c.field == change.field)) {
      // Solo si nadie volvió a cambiar esa preferencia después.
      _failures[change.field] = PreferenceFailure(
        change.field,
        change.requested,
      );
    }
    if (ref.mounted) _publish();
    return ok;
  }

  void _publish() {
    var view = _saved;
    for (final c in _pending) {
      if (c.optimistic) view = c.apply(view);
    }
    final save = _pending.isNotEmpty
        ? PreferenceSave.saving
        : _failures.isEmpty
        ? PreferenceSave.saved
        : PreferenceSave.failed;
    state = PreferencesState(
      view,
      save: save,
      failures: Map.of(_failures),
      pending: {for (final c in _pending) c.field},
    );
  }
}

final preferencesProvider =
    NotifierProvider<PreferencesController, PreferencesState>(
      PreferencesController.new,
    );

/// Tema que aplica la app.
final themeModeProvider = Provider<ThemeMode>(
  (ref) => switch (ref.watch(preferencesProvider).value.theme) {
    ThemePreference.system => ThemeMode.system,
    ThemePreference.light => ThemeMode.light,
    ThemePreference.dark => ThemeMode.dark,
  },
);

/// Aviso de una escritura fallida, con el valor que sigue vigente en [now]:
/// «No se pudo guardar el tema oscuro. El tema sigue en Claro.»
String preferenceFailureText(PreferenceFailure f, StoredPreferences now) {
  String theme(ThemePreference t) => switch (t) {
    ThemePreference.light => 'Claro',
    ThemePreference.dark => 'Oscuro',
    ThemePreference.system => 'Sistema',
  };
  String motion(bool reduced) => reduced ? 'reducido' : 'según Android';
  String pattern(String id) => SoundPattern.byId(id)?.label ?? id;
  return switch (f.field) {
    PreferenceField.theme =>
      'No se pudo guardar el tema '
          '${theme(f.requested as ThemePreference).toLowerCase()}. '
          'El tema sigue en ${theme(now.theme)}.',
    PreferenceField.reducedMotion =>
      'No se pudo guardar el movimiento ${motion(f.requested as bool)}. '
          'El movimiento sigue ${motion(now.reducedMotion)}.',
    PreferenceField.soundPattern =>
      'No se pudo guardar el ${pattern(f.requested as String)}. '
          'Las alertas siguen con el ${pattern(now.soundPatternId)}.',
  };
}
