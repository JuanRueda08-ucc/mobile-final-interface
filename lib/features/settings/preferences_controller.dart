import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/demo_history/demo_history_repository.dart';
import '../../data/demo_history/history_providers.dart';

/// Preferencias leídas al abrir la app (las fija `bootstrap.dart`). Sin base
/// abierta (modo real o revisión de Inicio) son las iniciales y no se guardan.
final initialPreferencesProvider = Provider<StoredPreferences>(
  (ref) => const StoredPreferences(),
);

/// Resultado de la última escritura de preferencias.
enum PreferenceSave { idle, saving, saved, failed }

final class PreferencesState {
  const PreferencesState(this.value, {this.save = PreferenceSave.idle});

  /// Preferencias vigentes: se aplican aunque la escritura falle (B5.2 P12:
  /// «El tema se aplica ahora, pero no quedó guardado»).
  final StoredPreferences value;
  final PreferenceSave save;
}

/// Tema, patrón de sonido y movimiento reducido (RF29, P12–P13), guardados en
/// la fila única de preferencias del historial DEMO.
class PreferencesController extends Notifier<PreferencesState> {
  var _attempt = 0;

  @override
  PreferencesState build() =>
      PreferencesState(ref.read(initialPreferencesProvider));

  void setTheme(ThemePreference theme) =>
      _update(state.value.copyWith(theme: theme));

  void setReducedMotion(bool reduced) =>
      _update(state.value.copyWith(reducedMotion: reduced));

  /// Guarda el patrón de las alertas. A diferencia del tema, solo cambia si
  /// quedó guardado: un fallo deja las alertas con el patrón anterior. La
  /// prueba de sonido de Preparación vuelve a ser obligatoria (RF29.CA3): lo
  /// aplica `PreparationController`.
  Future<bool> setSoundPattern(String patternId) => _update(
    state.value.copyWith(soundPatternId: patternId),
    applyBeforeSave: false,
  );

  Future<bool> _update(
    StoredPreferences next, {
    bool applyBeforeSave = true,
  }) async {
    final attempt = ++_attempt;
    final previous = state.value;
    state = PreferencesState(
      applyBeforeSave ? next : previous,
      save: PreferenceSave.saving,
    );
    var ok = true;
    try {
      await ref.read(demoHistoryRepositoryProvider).savePreferences(next);
    } catch (_) {
      ok = false;
    }
    if (ref.mounted && attempt == _attempt) {
      state = PreferencesState(
        ok || applyBeforeSave ? next : previous,
        save: ok ? PreferenceSave.saved : PreferenceSave.failed,
      );
    }
    return ok;
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
