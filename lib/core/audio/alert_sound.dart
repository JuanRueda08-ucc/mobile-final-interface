import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sonidos locales de la demostración: prueba de preparación, advertencia y
/// cierre ocular prolongado.
enum AlertSoundKind { test, warning, closure }

/// Patrón de sonido incluido (P13, RF29.CA3). Cada uno son tonos locales de
/// Android (`ToneGenerator`) distintos para prueba, advertencia y cierre. El
/// catálogo definitivo sigue pendiente de design system y audio (UX FL11);
/// estos tres existen de verdad en `MainActivity`, sin recursos inventados.
enum SoundPattern {
  patron1('patron_1', 'Patrón 1'),
  patron2('patron_2', 'Patrón 2'),
  patron3('patron_3', 'Patrón 3');

  const SoundPattern(this.id, this.label);

  final String id;
  final String label;

  static SoundPattern? byId(String id) {
    for (final p in values) {
      if (p.id == id) return p;
    }
    return null;
  }
}

/// Resultado **técnico** de una reproducción (RF04.CA1). No dice si alguien
/// lo oyó: eso lo confirma el usuario con «Lo escuché» (UX04).
final class SoundPlayback {
  const SoundPlayback.played() : played = true, failure = null;
  const SoundPlayback.failed(String this.failure) : played = false;

  final bool played;

  /// Causa técnica del fallo, si la hubo.
  final String? failure;
}

/// Reproductor de sonidos locales.
abstract interface class AlertSoundPlayer {
  Future<SoundPlayback> play(AlertSoundKind kind, {String patternId});
}

/// Reproductor Android: tono local de `ToneGenerator` por el canal
/// `vigia/demo_sound` de `MainActivity`. No usa red, archivos ni micrófono.
///
/// Comprobado aquí solo el resultado técnico que devuelve Android; la
/// audibilidad real en el teléfono queda pendiente de prueba física.
class AndroidToneSoundPlayer implements AlertSoundPlayer {
  const AndroidToneSoundPlayer();

  static const _channel = MethodChannel('vigia/demo_sound');

  @override
  Future<SoundPlayback> play(
    AlertSoundKind kind, {
    String patternId = 'patron_1',
  }) async {
    try {
      final r = await _channel.invokeMapMethod<String, Object?>('play', {
        'kind': kind.name,
        'pattern': patternId,
      });
      if (r?['played'] == true) return const SoundPlayback.played();
      return SoundPlayback.failed(
        (r?['cause'] as String?) ?? 'No se pudo reproducir el sonido.',
      );
    } on MissingPluginException {
      return const SoundPlayback.failed(
        'Sonido no disponible en esta plataforma.',
      );
    } on PlatformException catch (e) {
      return SoundPlayback.failed(e.message ?? 'Error de reproducción.');
    }
  }
}

final alertSoundPlayerProvider = Provider<AlertSoundPlayer>(
  (ref) => const AndroidToneSoundPlayer(),
);
