# monitoring_engine

Plugin Flutter local de Vigía con implementación Android en Kotlin
(`com.juanrueda.monitoring_engine`). Es la base del futuro motor nativo
(`SessionCoordinator`, cámara, inferencia, política, journal, alertas;
Área 04 §3 y Área 08 §4).

Estado en la fase 5A:

- canal de la plantilla (`getPlatformVersion`, VIG-003);
- API Pigeon `FrontCameraHostApi` / `FrontCameraFlutterApi`, con el permiso
  CAMERA y la vista previa de la cámara frontal (CameraX, solo Preview).

**No** analiza imágenes, **no** ejecuta IA, **no** mantiene sesiones ni
reproduce alertas. Detalle: `docs/fase5a-camara-permisos.md` del repositorio.

Regenerar el código de Pigeon (versionado; no editar a mano):

```bash
dart run pigeon --input pigeons/monitoring_api.dart
dart format lib pigeons
```

La app raíz lo consume mediante una dependencia `path`
(`packages/monitoring_engine`). No incluye app de ejemplo.

Pruebas:

```bash
flutter test                                   # Dart, desde este directorio
cd android && ./gradlew :monitoring_engine:testDebugUnitTest   # Kotlin, desde la raíz del repo
```
