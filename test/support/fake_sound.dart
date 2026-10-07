import 'dart:async';

import 'package:vigia/core/audio/alert_sound.dart';

/// Reproductor de prueba: registra las peticiones y devuelve [next].
class FakeSoundPlayer implements AlertSoundPlayer {
  final calls = <AlertSoundKind>[];
  SoundPlayback next = const SoundPlayback.played();

  @override
  Future<SoundPlayback> play(AlertSoundKind kind) async {
    calls.add(kind);
    return next;
  }
}

/// Reproductor cuyas alertas responden solo cuando la prueba lo decide; la
/// prueba de sonido responde en el acto.
class DeferredAlertPlayer implements AlertSoundPlayer {
  final pending = <Completer<SoundPlayback>>[];

  @override
  Future<SoundPlayback> play(AlertSoundKind kind) {
    if (kind == AlertSoundKind.test) {
      return Future.value(const SoundPlayback.played());
    }
    final c = Completer<SoundPlayback>();
    pending.add(c);
    return c.future;
  }
}
