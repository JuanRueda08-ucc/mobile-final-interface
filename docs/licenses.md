# Vigía · Recursos de terceros incluidos en la app

## Tipografía e identidad

Outfit y Onest se empaquetan como TTF variables. Se obtuvieron de la
[revisión `c30b221` del repositorio oficial de Google Fonts](https://github.com/google/fonts/tree/c30b221beb0c1da59d563feb91ec8656a1fa972a/ofl).
Los archivos conservan sus bytes de origen. Cada licencia SIL Open Font
License 1.1 se incluye como asset y se registra en `LicenseRegistry`.

| Archivo | SHA-256 |
|---|---|
| `assets/fonts/Outfit/Outfit-Variable.ttf` | `fc7287273e66929776e2ba54f144fe699080bec29f61bf649d70d871468aeade` |
| `assets/fonts/Outfit/OFL.txt` | `c676351bf8576b9aba743cd5eaa8c0e7ee0d51f805d720447b4df4ddb6a2e416` |
| `assets/fonts/Onest/Onest-Variable.ttf` | `966c5c29b4755da84b6854d5c21dd4eaa2420225d0e9874de602de176d4a9f31` |
| `assets/fonts/Onest/OFL.txt` | `071195d8806e226faeee60259c28ca67b458227af5195a73f5cfcab06e3003bc` |

El icono de marca de `assets/brand/vigia_mark.png` es un recorte cuadrado
del PNG aprobado por la persona usuaria. «Vigía» se dibuja como texto de
Flutter. El lanzador adaptativo extrae del mismo recorte la máscara de los
trazos blancos y extiende el degradado en una capa de fondo. Los iconos de
interfaz siguen usando los trazos propios del prototipo B5.2 (`IC`) en
`lib/core/design_system/vigia_icons.dart`.

## Fase 5B · modelo facial y MediaPipe (solo en la app normal)

| Recurso | Versión | Origen | Licencia | Archivo / SHA-256 |
|---|---|---|---|---|
| Modelo MediaPipe Face Landmarker (`face_landmarker.task`, float16) | Ruta versionada `float16/1` (GCS `generation 1683136941916318`, 2023-05-03). Sin versión semántica publicada | `https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/1/face_landmarker.task` (descargado el 2026-10-12) | **Apache 2.0**, según las fichas oficiales de BlazeFace (Short Range), Face Mesh V2 y Blendshape V2. Detalle y hashes de los PDF en `docs/fase5b-mediapipe.md` | `packages/monitoring_engine/android/src/main/assets/vigia_models/face_landmarker_float16_v1.task`, 3 758 596 bytes, `64184e229b263107bc2b804c6625db1341ff2bb731874b0bcc2fe6544e0bc9ff` |
| `com.google.mediapipe:tasks-vision` y `tasks-core` | 1.0.0 | Google Maven | Apache 2.0 (POM) | Dependencia Gradle |
| `com.google.protobuf:protobuf-javalite` | 4.26.1 | Maven Central (transitiva de MediaPipe) | BSD-3-Clause (POM padre `protobuf-parent`) | Dependencia Gradle |
| `com.google.flogger:flogger` y `flogger-system-backend` | 0.6 | Maven Central (transitivas) | Apache 2.0 (POM) | Dependencia Gradle |
| `com.google.guava:guava` | 27.0.1-android | Maven Central (transitiva) | Apache 2.0 (POM padre `guava-parent`) | Dependencia Gradle |
| `com.google.android.datatransport` (`transport-api` 3.0.0; `transport-runtime` y `transport-backend-cct` 3.1.0) y `com.google.firebase:firebase-encoders*` | Las indicadas | Google Maven (transitivas de `tasks-core`) | Apache 2.0 (POM) | Dependencia Gradle. Es la telemetría de uso de MediaPipe; sus permisos de red se retiran del manifiesto (ver `docs/fase5b-mediapipe.md`) |

- La licencia del modelo y la de la biblioteca se verificaron por separado (Área 05 §3).
- Las bibliotecas Android de la fase 5A (CameraX 1.6.2, corrutinas 1.11.0) y estas no se registran todavía en `LicenseRegistry`, como tampoco lo estaban las de la 5A: la página de licencias de la app muestra las fuentes locales y los paquetes Dart. **Pendiente** antes de distribuir.
- Las imágenes de prueba de la fase 5B (dominio público, NASA) solo van en el APK de pruebas del plugin, no en la app: `packages/monitoring_engine/android/src/androidTest/assets/face_fixtures/FUENTES.md`.
