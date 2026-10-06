import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reloj de la sesión demostrativa.
///
/// - [elapsed]: tiempo monotónico desde que se creó el reloj. Las duraciones
///   de la sesión se calculan con él, no con la hora civil (Área 04 §5).
/// - [wallNow]: hora civil, solo para presentar «Inicio confirmado» y
///   «Cierre confirmado».
abstract interface class MonotonicClock {
  Duration get elapsed;
  DateTime wallNow();
}

/// Reloj de producción: `Stopwatch` (monotónico).
class StopwatchClock implements MonotonicClock {
  StopwatchClock() : _watch = Stopwatch()..start();

  final Stopwatch _watch;

  @override
  Duration get elapsed => _watch.elapsed;

  @override
  DateTime wallNow() => DateTime.now();
}

/// Reloj de `package:clock`. En las pruebas, `testWidgets` y `fakeAsync`
/// controlan su avance, así que el tiempo de la sesión es reproducible.
class PackageClock implements MonotonicClock {
  PackageClock() : _origin = clock.now();

  final DateTime _origin;

  @override
  Duration get elapsed => clock.now().difference(_origin);

  @override
  DateTime wallNow() => clock.now();
}

final monotonicClockProvider = Provider<MonotonicClock>(
  (ref) => StopwatchClock(),
);
