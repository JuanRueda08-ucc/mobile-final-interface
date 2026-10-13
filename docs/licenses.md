# Vigía · Recursos de terceros incluidos en la app

| Recurso | Versión | Origen | Licencia | Archivos en el repositorio | SHA-256 |
|---|---|---|---|---|---|
| Fuente Inter | 4.1 (`Version 4.001;git-9221beed3`) | Publicación oficial `rsms/inter` v4.1: `https://github.com/rsms/inter/releases/download/v4.1/Inter-4.1.zip` (descargada el 2026-10-06; zip SHA-256 `9883fdd4a49d4fb66bd8177ba6625ef9a64aa45899767dde3d36aa425756b11e`) | SIL Open Font License 1.1 | `assets/fonts/Inter/Inter-Regular.ttf` (peso 400) | `40d692fce188e4471e2b3cba937be967878f631ad3ebbbdcd587687c7ebe0c82` |
| | | | | `assets/fonts/Inter/Inter-Medium.ttf` (peso 500) | `97ad806f526e41546d46365bb3a393145f75b7b1568913db74549ad8b8dba872` |
| | | | | `assets/fonts/Inter/OFL.txt` (texto de la licencia, copiado de `LICENSE.txt` del zip) | `262481e844521b326f5ecd053e59b98c8b2da78c8ee1bdbb6e8174305e54935a` |

- Solo se incluyen los pesos 400 y 500, que son los que usa el diseño B5.2. Los archivos TTF están sin modificar.
- La API de GitHub no publica un *digest* para ese zip; la procedencia se apoya en la descarga HTTPS desde la publicación oficial del repositorio y en los hashes anteriores.
- La licencia se distribuye con la app: `OFL.txt` se declara como asset y se registra en `LicenseRegistry` (`registerVigiaLicenses`, `lib/app/vigia_app.dart`).
- No se cargan fuentes remotas. El HTML B5.2 trae Inter en WOFF2, un formato que Flutter no admite, por eso se usan los TTF oficiales.

**Iconos:** son los trazos SVG propios del prototipo B5.2 (`IC`), redibujados con `CustomPaint` en `lib/core/design_system/vigia_icons.dart`. No hay bibliotecas de iconos de terceros.

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
- Las bibliotecas Android de la fase 5A (CameraX 1.6.2, corrutinas 1.11.0) y estas no se registran todavía en `LicenseRegistry`, como tampoco lo estaban las de la 5A: la página de licencias de la app solo muestra Inter y los paquetes Dart. **Pendiente** antes de distribuir.
- Las imágenes de prueba de la fase 5B (dominio público, NASA) solo van en el APK de pruebas del plugin, no en la app: `packages/monitoring_engine/android/src/androidTest/assets/face_fixtures/FUENTES.md`.
