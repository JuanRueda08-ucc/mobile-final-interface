import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Resultado técnico de una narración: Android aceptó decir el texto o no
/// (y por qué). No acredita que alguien lo oyera.
class VoiceResult {
  const VoiceResult.spoken() : spoken = true, cause = null;
  const VoiceResult.failed(this.cause) : spoken = false;

  final bool spoken;
  final String? cause;
}

/// Voz guía (prueba física, 2026-11-15): narra instrucciones breves, como
/// los pasos de la calibración, para que no dependan solo del texto y el tono.
abstract interface class VoiceGuide {
  Future<VoiceResult> speak(String text);
  Future<void> stop();
}

/// Síntesis de voz del sistema Android por el canal `vigia/voice` de
/// `MainActivity`. Sin micrófono ni red.
class AndroidVoiceGuide implements VoiceGuide {
  const AndroidVoiceGuide();

  static const _channel = MethodChannel('vigia/voice');

  @override
  Future<VoiceResult> speak(String text) async {
    try {
      final r = await _channel.invokeMapMethod<String, Object?>('speak', {
        'text': text,
      });
      if (r?['spoken'] == true) return const VoiceResult.spoken();
      return VoiceResult.failed(
        (r?['cause'] as String?) ?? 'La voz no está disponible.',
      );
    } on MissingPluginException {
      // Sin canal nativo (pruebas, otras plataformas): silencio sin aviso.
      return const VoiceResult.failed(null);
    } on PlatformException catch (e) {
      return VoiceResult.failed(e.message ?? 'Error de la voz.');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _channel.invokeMethod<void>('stop');
    } on MissingPluginException {
      // Sin voz en esta plataforma: nada que detener.
    } on PlatformException {
      // La voz ya no está disponible: nada que detener.
    }
  }
}

final voiceGuideProvider = Provider<VoiceGuide>(
  (ref) => const AndroidVoiceGuide(),
);

/// Voz guía activada para esta ejecución de la app (por defecto, sí).
class CalibrationVoiceEnabled extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle() => state = !state;
}

final calibrationVoiceEnabledProvider =
    NotifierProvider<CalibrationVoiceEnabled, bool>(
      CalibrationVoiceEnabled.new,
    );
