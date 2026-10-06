import 'package:flutter_test/flutter_test.dart';
import 'package:vigia/app/inicio_source.dart';
import 'package:vigia/demo/inicio_demo.dart';
import 'package:vigia/features/inicio/inicio_state.dart';

void main() {
  test('sin VIGIA_DEMO_INICIO se usa el estado real, sin rótulo DEMO', () {
    final s = resolveInicioState(demoDefine: '');
    expect(s, isA<InicioSinHistorial>());
    expect(s.isDemo, isFalse);
  });

  test(
    'cada variante DEMO se resuelve por su id y queda marcada como DEMO',
    () {
      for (final v in InicioDemoVariant.values) {
        final s = resolveInicioState(demoDefine: v.id);
        expect(s.runtimeType, v.state.runtimeType, reason: v.id);
        expect(s.isDemo, isTrue, reason: v.id);
        expect(v.b52ViewId, startsWith('P03__'));
      }
    },
  );

  test('una variante desconocida falla en vez de sustituirse en silencio', () {
    expect(
      () => resolveInicioState(demoDefine: 'activa'),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('las cinco variantes de B5.2 existen', () {
    expect(InicioDemoVariant.values.map((v) => v.b52ViewId), [
      'P03__sin_historial__v1',
      'P03__ultimo_resumen__v1',
      'P03__sesion_vigente__v1',
      'P03__registro_interrumpido__v1',
      'P03__motor_desconocido__v1',
    ]);
  });
}
