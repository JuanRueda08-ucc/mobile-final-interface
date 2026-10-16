/// Preferencias guardadas (Área 06 §6 y §9; P12–P13).
///
/// Cada variante las guarda en su propia base (Área 06 §16): la DEMO en
/// `vigia_history_demo_v1.sqlite` y la normal en `vigia_history_real_v1.sqlite`
/// (fase 5E). Ninguna lee ni escribe las de la otra.
enum ThemePreference { system, light, dark }

final class StoredPreferences {
  const StoredPreferences({
    this.theme = ThemePreference.system,
    this.soundPatternId = defaultSoundPatternId,
    this.reducedMotion = false,
  });

  /// Patrón inicial del catálogo local (Área 06 §9).
  static const defaultSoundPatternId = 'patron_1';

  final ThemePreference theme;
  final String soundPatternId;
  final bool reducedMotion;

  StoredPreferences copyWith({
    ThemePreference? theme,
    String? soundPatternId,
    bool? reducedMotion,
  }) => StoredPreferences(
    theme: theme ?? this.theme,
    soundPatternId: soundPatternId ?? this.soundPatternId,
    reducedMotion: reducedMotion ?? this.reducedMotion,
  );

  @override
  bool operator ==(Object other) =>
      other is StoredPreferences &&
      other.theme == theme &&
      other.soundPatternId == soundPatternId &&
      other.reducedMotion == reducedMotion;

  @override
  int get hashCode => Object.hash(theme, soundPatternId, reducedMotion);
}

/// Fila única de preferencias de una variante. `PreferencesController` es su
/// único escritor; sin fila guardada se leen las iniciales.
abstract interface class PreferencesStore {
  Future<StoredPreferences> loadPreferences();
  Future<void> savePreferences(StoredPreferences preferences);
}
