# monitoring_engine

Plugin Flutter local de Vigía con implementación Android en Kotlin
(`com.juanrueda.monitoring_engine`). Es la base del futuro motor nativo
(`SessionCoordinator`, cámara, inferencia, política, journal, alertas;
Área 04 §3 y Área 08 §4).

Estado en la fase 5B:

- canal de la plantilla (`getPlatformVersion`, VIG-003);
- API Pigeon `FrontCameraHostApi` / `FrontCameraFlutterApi`, con el permiso
  CAMERA y la vista previa de la cámara frontal (CameraX Preview, fase 5A);
- presencia facial local (fase 5B): `ImageAnalysis` junto a Preview en la
  misma cámara y MediaPipe Face Landmarker 1.0.0 (LIVE_STREAM, CPU, hasta dos
  rostros), con el modelo empaquetado en
  `android/src/main/assets/vigia_models/` y verificado por SHA-256. A Flutter
  solo llega un resultado compacto (`FaceAnalysisSnapshot`).

**No** evalúa los ojos, **no** detecta fatiga, **no** mantiene sesiones ni
reproduce alertas, y **no** guarda ni transmite imágenes o puntos faciales.
Detalle: `docs/fase5a-camara-permisos.md` y `docs/fase5b-mediapipe.md` del
repositorio.

Regenerar el código de Pigeon (versionado; no editar a mano):

```bash
python tools/generate_pigeon.py   # desde la raíz del repositorio
```

La app raíz lo consume mediante una dependencia `path`
(`packages/monitoring_engine`). No incluye app de ejemplo.

Pruebas:

```bash
flutter test                                   # Dart, desde este directorio
cd android && ./gradlew :monitoring_engine:testDebugUnitTest   # Kotlin (JVM), desde la raíz del repo
cd android && ./gradlew :monitoring_engine:connectedDebugAndroidTest   # modelo real en Android (emulador o teléfono)
```
