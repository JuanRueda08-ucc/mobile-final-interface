import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigia/data/demo_history/demo_history_database.dart';
import 'package:vigia/data/demo_history/demo_history_repository.dart';

/// Historial DEMO real (Drift/SQLite) en memoria para pruebas: mismo esquema
/// y repositorio que la app, sin archivo.
Future<(DemoHistoryDatabase, DriftDemoHistoryRepository)>
openMemoryHistory() async {
  // Cada prueba abre su propia base; no es un error de la app.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final db = DemoHistoryDatabase(NativeDatabase.memory());
  return (db, await DriftDemoHistoryRepository.open(db));
}

/// Resultado de [future] dentro de `fakeAsync`: la base en memoria responde
/// con microtareas, sin temporizadores.
T flushed<T>(FakeAsync async, Future<T> future) {
  late T value;
  var done = false;
  future.then((v) {
    value = v;
    done = true;
  });
  async.flushMicrotasks();
  expect(done, isTrue, reason: 'la base no respondió');
  return value;
}
