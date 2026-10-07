import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/demo_history/demo_history_repository.dart';
import '../../data/demo_history/history_providers.dart';

/// Preferencias leídas al abrir la app (las fija `bootstrap.dart`). Sin base
/// abierta (modo real o revisión de Inicio) son las iniciales y no se guardan.
final initialPreferencesProvider = Provider<StoredPreferences>(
  (ref) => const StoredPreferences(),
);

/// Resultado de las escrituras de preferencias.
enum PreferenceSave { idle, saving, saved, failed }

final class PreferencesState {
  const PreferencesState(this.value, {this.save = PreferenceSave.idle});

  /// Preferencias que ve y aplica la app: las guardadas más los cambios de
  /// tema o movimiento que todavía se están guardando.
  final StoredPreferences value;

  /// `saving` mientras quede alguna escritura; al terminar, `failed` si alguna
  /// de ellas falló y `saved` si no.
  final PreferenceSave save;
}

/// Cambio pedido: se aplica sobre las preferencias vigentes cuando le toca.
final class _Change {
  const _Change(this.apply, {required this.optimistic});

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
/// falla, su cambio se retira (también un tema que ya se veía) y se informa;
/// lo guardado antes se conserva. Al terminar, memoria, interfaz y SQLite
/// coinciden.
class PreferencesController extends Notifier<PreferencesState> {
  /// Últimas preferencias confirmadas por SQLite (o las iniciales).
  late StoredPreferences _saved;

  /// Cambios pedidos y aún no resueltos, en orden.
  final _pending = <_Change>[];
  Future<void> _tail = Future.value();
  var _batchFailed = false;

  @override
  PreferencesState build() {
    _saved = ref.read(initialPreferencesProvider);
    return PreferencesState(_saved);
  }

  Future<bool> setTheme(ThemePreference theme) =>
      _enqueue(_Change((p) => p.copyWith(theme: theme), optimistic: true));

  Future<bool> setReducedMotion(bool reduced) => _enqueue(
    _Change((p) => p.copyWith(reducedMotion: reduced), optimistic: true),
  );

  /// Guarda el patrón de las alertas. Solo cambia si quedó guardado: un fallo
  /// deja las alertas con el patrón anterior. Al cambiar, la prueba de sonido
  /// de Preparación vuelve a ser obligatoria (RF29.CA3): lo aplica
  /// `PreparationController`.
  Future<bool> setSoundPattern(String patternId) => _enqueue(
    _Change((p) => p.copyWith(soundPatternId: patternId), optimistic: false),
  );

  Future<bool> _enqueue(_Change change) {
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
    if (ok) _saved = next;
    _batchFailed |= !ok;
    _pending.remove(change);
    if (ref.mounted) _publish();
    return ok;
  }

  void _publish() {
    var view = _saved;
    for (final c in _pending) {
      if (c.optimistic) view = c.apply(view);
    }
    final PreferenceSave save;
    if (_pending.isNotEmpty) {
      save = PreferenceSave.saving;
    } else {
      save = _batchFailed ? PreferenceSave.failed : PreferenceSave.saved;
      _batchFailed = false;
    }
    state = PreferencesState(view, save: save);
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
