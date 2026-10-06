import 'package:flutter_test/flutter_test.dart';
import 'package:vigia/app/app_config.dart';
import 'package:vigia/features/inicio/inicio_state.dart';

void main() {
  test(
    'sin definiciones: modo real (motor no comprobado, sin demostración)',
    () {
      expect(resolveAppMode(demoDefine: '', inicioDefine: ''), isA<RealMode>());
      expect(
        resolveAppMode(demoDefine: 'false', inicioDefine: ''),
        isA<RealMode>(),
      );
    },
  );

  test('VIGIA_DEMO=true habilita el recorrido demostrativo', () {
    expect(
      resolveAppMode(demoDefine: 'true', inicioDefine: ''),
      isA<DemoMode>(),
    );
  });

  test('VIGIA_DEMO_INICIO conserva la revisión de variantes de Inicio', () {
    final m = resolveAppMode(demoDefine: '', inicioDefine: 'sesion_vigente');
    expect(m, isA<InicioReviewMode>());
    expect((m as InicioReviewMode).state, isA<InicioSesionVigente>());
    expect(m.state.isDemo, isTrue);
  });

  test('valores no admitidos o combinados no se interpretan en silencio', () {
    expect(
      () => resolveAppMode(demoDefine: 'si', inicioDefine: ''),
      throwsArgumentError,
    );
    expect(
      () => resolveAppMode(demoDefine: 'true', inicioDefine: 'sin_historial'),
      throwsArgumentError,
    );
  });
}
