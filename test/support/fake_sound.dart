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
