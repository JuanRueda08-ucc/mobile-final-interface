# Vigía · Fase 5B: MediaPipe Face Landmarker (presencia facial)

**Autorizada por el usuario:** 2026-10-12. **Estado:** implementada; **pendiente de la revisión de Codex**. No se ha publicado.

## Alcance

En la **variante normal** (`com.juanrueda.vigia`), la pantalla **Cámara frontal** (`/camara`) analiza la imagen de la cámara frontal en el teléfono y muestra la **presencia facial**: ningún rostro, uno o varios. La función se identifica como «Detección facial en pruebas».

- **Fuera de alcance:** evaluación ocular (EAR, Q, EyeVisibilityGate), calibración, sesiones, reglas y alertas de fatiga. Calibrar e Iniciar monitoreo siguen deshabilitados aunque se detecte un rostro.
- **Privacidad:** no se guardan ni se transmiten imágenes, vídeo ni puntos faciales, y tampoco se registran en logs.
  - Los puntos faciales solo existen dentro de Kotlin, en el resultado de MediaPipe, y se usan para contarlos.
  - A Flutter llega `FaceAnalysisSnapshot`: estado, número de rostros, edad del resultado y contadores.
- **DEMO:** sin cambios. Su APK no lleva ni el modelo ni la biblioteca nativa de MediaPipe, y no declara CAMERA.

## Modelo empaquetado

| Campo (Área 05 §3) | Valor |
|---|---|
| modelId | `mediapipe/face_landmarker/float16/1` |
| Archivo en el repositorio | `packages/monitoring_engine/android/src/main/assets/vigia_models/face_landmarker_float16_v1.task` |
| sourceUrl | `https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/1/face_landmarker.task` (ruta versionada `/1/`) |
| Ruta de la documentación oficial | La página del modelo enlaza `…/float16/latest/face_landmarker.task`. **No se usó `latest`**. Ambas rutas tienen el mismo contenido: MD5 `sOcnSQehZEQE/vZrKN1thQ==` y CRC32C `2FSEdQ==` según los metadatos de Google Cloud Storage |
| Identificación disponible | Etiqueta de ruta `1`, precisión float16, objeto GCS `generation 1683136941916318`, publicado el 2023-05-03. Google no publica un número de versión semántica para este archivo |
| downloadedAt | 2026-10-12 |
| Tamaño | 3 758 596 bytes |
| SHA-256 | `64184e229b263107bc2b804c6625db1341ff2bb731874b0bcc2fe6544e0bc9ff` |
| Contenido | `face_detector.tflite`, `face_landmarks_detector.tflite`, `face_blendshapes.tflite` y `geometry_pipeline_metadata_landmarks.binarypb` |
| Licencia del modelo | **Apache 2.0**, según las tres fichas oficiales (ver la tabla siguiente). La licencia de la biblioteca se verificó por separado (`docs/licenses.md`) |
| taskLibraryVersion | `com.google.mediapipe:tasks-vision:1.0.0` |
| runningMode / delegate | `LIVE_STREAM` / `CPU` |
| maxNumFaces | **2**. Con 1 no se podría afirmar que no hay varios. La documentación indica que el suavizado solo se aplica con `numFaces=1`; aquí no se presupone |
| Confianzas de detección, presencia y seguimiento | 0,5 / 0,5 / 0,5 (Área 05 §7, candidatas). No son una medida ocular |
| Flags de salida | Blendshapes **no**. Matrices **no**: Área 05 §3 las propone para estudiar la postura, que esta fase no evalúa |
| landmarkSchemaVersion | No aplica: esta fase no usa índices de puntos |

**Fichas de modelo que declaran la licencia** (enlazadas desde la página oficial del modelo, descargadas el 2026-10-12):

| Ficha | Licencia | SHA-256 del PDF |
|---|---|---|
| [BlazeFace (Short Range)](https://storage.googleapis.com/mediapipe-assets/MediaPipe%20BlazeFace%20Model%20Card%20(Short%20Range).pdf) | Apache License, Version 2.0 | `cd335c06fc0de7807cd815a0777a697932598bcdb28fa98adaaabf847485f758` |
| [Face Mesh V2](https://storage.googleapis.com/mediapipe-assets/Model%20Card%20MediaPipe%20Face%20Mesh%20V2.pdf) | Apache License, Version 2.0 | `c6add060f4ebfb37b2690136b6c711c7e5fcb7038baa2649ae3338b83979565a` |
| [Blendshape V2](https://storage.googleapis.com/mediapipe-assets/Model%20Card%20Blendshape%20V2.pdf) | Apache License, Version 2.0 | `c8e9cf60a39998f4b341740623917590e050d1c97004e2de4568d84e026445ae` |

**Verificación en cada carga** (`FaceModelLoader`):

1. Lee el asset y comprueba tamaño y SHA-256 **sobre los mismos bytes** que recibe MediaPipe (`setModelAssetBuffer`, búfer directo). No hay ventana entre la comprobación y la carga.
2. Errores explícitos y recuperables con «Reintentar carga» (ER04, «Modelo no disponible»):

| Código | Causa |
|---|---|
| `modelMissing` | Falta el asset |
| `modelCorrupt` | El tamaño o el SHA-256 no coinciden |
| `modelIncompatible` | MediaPipe no puede crear el detector, o falta la biblioteca nativa |
| `modelReadFailed` | Otro error de lectura |

Nunca se sustituye por una simulación.

## Biblioteca

- **`com.google.mediapipe:tasks-vision:1.0.0`**, versión exacta (`packages/monitoring_engine/android/build.gradle.kts`).
  - En Google Maven, el 2026-10-12, las versiones recientes eran 0.10.35 (2026-04-27), 1.0.0 (2026-07-27) y 1.1.0 (2026-10-06).
  - La 1.1.0 se descartó por reciente (6 días) y porque añade `litertlm-android`.
  - La guía oficial de Android pide `latest.release`; no se usa.
- **minSdk y ABI.** El AAR declara minSdk 24, así que el 26 del proyecto no cambia. Trae `.so` para arm64-v8a, armeabi-v7a, x86 y x86_64. Flutter solo empaqueta en release las tres ABI que ya tenía la app (arm64-v8a, armeabi-v7a y x86_64); no cambia nada.
- **16 KB.** Los segmentos LOAD de `libmediapipe_tasks_jni.so` están alineados a 16 384 bytes en las cuatro ABI, y `zipalign -c -P 16` del APK normal da «Verification successful». No se ejecutó en un entorno de páginas de 16 KB.
- **Dependencias transitivas resueltas:**

| Dependencia | Versión |
|---|---|
| `tasks-core` | 1.0.0 |
| `protobuf-javalite` | 4.26.1 |
| `flogger` y `flogger-system-backend` | 0.6 |
| `guava` | 27.0.1-android |
| `com.google.android.datatransport` (`transport-api`) | 3.0.0 |
| `com.google.android.datatransport` (`transport-runtime` y `transport-backend-cct`) | 3.1.0 |
| `firebase-encoders` | 17.0.0 |

### Hallazgo: telemetría de uso de MediaPipe

Al crear cualquier tarea, `tasks-core` 1.0.0 construye siempre `RemoteLoggingClient`, sin opción documentada para desactivarlo. Este cliente envía estadísticas de uso a `firebaselogging.googleapis.com` mediante `datatransport`:

- según los nombres de sus clases (`MediaPipeLogExtension`, `SystemInfo`, `SolutionInvocationReport`): tarea, modo, contadores, latencias, información del sistema y paquete;
- no imágenes. El contenido real enviado no se inspeccionó.

Excluir la dependencia no es viable: la creación del detector fallaría con `NoClassDefFoundError`. Su AAR fusiona en el manifiesto `INTERNET`, `ACCESS_NETWORK_STATE`, un `JobService` y un receptor de alarmas.

**Mitigación aplicada:**

| Dónde | Qué |
|---|---|
| `android/app/src/main/AndroidManifest.xml` | Retira `ACCESS_NETWORK_STATE` en todas las compilaciones. Sin él, `datatransport` falla al programar el evento («Error scheduling event … ACCESS_NETWORK_STATE»), lo captura `SafeLoggingExecutor` y no se intenta ninguna conexión |
| `android/app/src/release/AndroidManifest.xml` | Retira `INTERNET` en release. En debug y profile lo añade Flutter para sus herramientas |
| `android/app/src/demo/AndroidManifest.xml` | Retira además los tres componentes de `datatransport` |
| `src/androidTest/AndroidManifest.xml` del plugin | Retira ambos permisos en el APK de pruebas |

**Comprobado:**

- El APK normal release solo pide `CAMERA` (más el permiso interno `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`); `aapt dump badging` no muestra `INTERNET` ni `ACCESS_NETWORK_STATE`.
- La app DEMO no pide ninguno de los dos.
- Con el APK de pruebas sin permisos: 24 «Error scheduling event», 0 eventos guardados y 0 peticiones.

**Incidente durante la prueba.** La **primera** ejecución de la prueba instrumentada usó un APK de pruebas que todavía tenía los permisos de red. Su `JobService` envió esas estadísticas a `firebaselogging.googleapis.com` desde el emulador: `Status Code: 200`, 2026-10-12 23:14:11 UTC, paquete `com.juanrueda.monitoring_engine.test`. No salieron imágenes de la app (MediaPipe no las incluye en ese registro). Después se añadió el manifiesto de pruebas, se desinstaló ese APK y se repitió todo sin red.

**No comprobado:** si el APK release guarda localmente esos eventos. `datatransport` no deja registros en release y la app no es depurable. Sin permisos de red no puede enviarlos.

### Hallazgo: reglas de R8

En release, la creación del detector fallaba («Field platform_ for n70 not found» y, después, Flogger con «no caller found on the stack»). La prueba instrumentada no lo detectó porque usa debug, sin minificar; lo destapó la prueba de la app release en el emulador.

MediaPipe 1.0.0 no trae reglas propias. El plugin aporta `consumer-rules.pro`:

- conserva `com.google.mediapipe.**`, los mensajes protobuf-lite y Flogger;
- añade `-dontwarn` para dos clases de perfilado que el AAR cita y no incluye.

## Canal nativo

| Pieza | Archivo | Papel |
|---|---|---|
| Manifiesto y verificación | `face/FaceModel.kt` | `FaceModelSpec`, `FaceModelLoader`, códigos de error |
| Núcleo (sin Android) | `face/FaceAnalysisCore.kt` | Estados, identidad, caducidad, un cuadro cada vez y latido |
| MediaPipe | `face/MediaPipeFaceEngine.kt` | Face Landmarker en LIVE_STREAM |
| Sesión Android | `face/FaceAnalysisSession.kt` | `ImageAnalysis`, hilo propio y conversión |
| Propietario de la cámara | `camera/FrontCameraPreview.kt` (de 5A) | Vincula Preview e ImageAnalysis **en la misma llamada**: una sola cámara |
| Puente | `pigeons/monitoring_api.dart` | `FaceAnalysisSnapshot`, `restartFaceAnalysis`, `onFaceAnalysis` |

- **ImageAnalysis.** Se pide 640×480 (relación 4:3, `FALLBACK_RULE_CLOSEST_HIGHER_THEN_LOWER`), en `RGBA_8888` y con `STRATEGY_KEEP_ONLY_LATEST`. En el emulador se entregaron cuadros de 640×480 con giro de 90°.
- **Hilos.** Cada apertura tiene el suyo, `VigiaFaceAnalysis-<token>`, con ejecutor de un solo hilo. En él ocurren la carga del modelo, la conversión, `detectAsync`, el vigilante y el cierre del detector. Los avisos de MediaPipe llegan en su propio hilo, anotan la hora de recepción y pasan al hilo de análisis. Nada de esto ocurre en el hilo principal ni en el isolate de Flutter.
- **Propiedad de los recursos:**
  - `ImageProxy`: se copia a `Bitmap` con `toBitmap()` y se cierra en `finally`, también si el cuadro se descarta;
  - `Bitmap`: se libera (`recycle`) al volver `detectAsync`. MediaPipe 1.0.0 copia los píxeles antes de volver: `AndroidPacketCreator.createImage` → `CreateImageFrameFromBitmap` hace `memcpy`, según el código fuente de v1.0.0;
  - imagen que MediaPipe entrega al listener: es otra copia y se cierra allí;
  - detector: se cierra al detener la sesión, al fallar o al reintentar;
  - hilo: se apaga al cerrar.
- **Sin colas.** Un cuadro cada vez: no se envía otro mientras el anterior no tenga resultado. Si en Tstale no llega, se deja de esperar. Así ningún cuadro espera en la cola del limitador de MediaPipe (`maxInFlight=1`, `maxInQueue=1`, que se activa en LIVE_STREAM).
  - Antes de este cambio, en el emulador se descartaban por antiguos 20 de 55 resultados.
  - Con él, 0 de 80 a 128, con una edad máxima de 355 a 582 ms.
  - Los cuadros pendientes de resultado se acotan a 8.
- **Marcas de tiempo.** La de MediaPipe es el instante de entrega del cuadro al analizador (`elapsedRealtimeNanos`, en ms). Debe ser estrictamente creciente en cada instancia; un cuadro con una marca no creciente se descarta, no se reordena.
- **Giro y espejo, por separado:**
  - giro: `ImageInfo.rotationDegrees` de CameraX (horario) se pasa a `ImageProcessingOptions.rotationDegrees` (horario);
  - comprobado con el modelo real: el retrato girado 90° antihorario se detecta con giro 90 y **no** con 270;
  - la imagen de análisis no se espeja; el espejo solo afecta a la vista previa (5A).
- **Registros.** Solo token, estado, códigos y contadores al cerrar, por ejemplo: «cuadros enviados 128, resultados aceptados 127, … edad máxima aceptada 582 ms; cuadro 640x480 giro 90». Si falla la creación del detector, también el tipo y el mensaje de la excepción de MediaPipe, sin datos de imagen.

## Estados, vigencia e identidad

| Estado (Pigeon → pantalla) | Origen |
|---|---|
| `loadingModel` → «Cargando el modelo…» | Carga y verificación en curso, o la cámara abierta sin noticias aún |
| `waitingResults` → «Esperando resultados…» | Detector listo sin resultado vigente. **No** significa «sin rostro» |
| `noFace` → «Rostro no detectado» (ER05) | Resultado explícito con 0 rostros |
| `oneFace` → «Rostro detectado» | Resultado explícito con 1 rostro. Causa: «Presencia facial no equivale a ojos medibles» |
| `multipleFaces` → «Varios rostros detectados» | Resultado explícito con 2 rostros |
| `stopped` → «Análisis detenido» | Sin cámara abierta (salida, segundo plano, cierre nativo) |
| `modelError` → «Modelo no disponible» + «Reintentar carga» | Ver los códigos de la sección del modelo |
| `analysisError` → «Error de análisis» + «Reintentar» | Error de MediaPipe o excepción de `detectAsync` |

### Política de caducidad

Los valores son **experimentales**: Tstale y Gmax son candidatos del perfil `lab-eye-rules-0.1` (Área 05 §7, `qualificationStatus=experimental`), y el latido y el límite de Flutter son la propuesta de transporte de Área 04 §9. Ninguno está aceptado para producción.

- **Motor (Kotlin), Tstale = 750 ms:**
  - se descarta un resultado cuya edad, desde la entrega del cuadro hasta la recepción, supera 750 ms; con edad igual a 750 ms sigue vigente;
  - sin resultados aceptados durante ≥750 ms (con 750 ya caduca), «sin rostro», «un rostro» y «varios» vuelven a `waitingResults` con `expired=true`;
  - el vigilante corre cada 100 ms, así que reacciona en ≤100 ms;
  - el motor manda un latido a Flutter cada 1000 ms.
- **Flutter, 3000 ms:** sin ningún resultado durante 3000 ms, el último deja de mostrarse como vigente («El último resultado caducó y ya no se muestra»). Cubre un canal que deja de entregar mensajes.
- **Edad medida.** Va desde la entrega al analizador, no desde la captura. No se demostró la conversión entre el reloj del sensor (`ImageInfo.timestamp`) y `elapsedRealtime` (Área 05 §4), así que la latencia de captura a entrega no se incluye.
- **Gmax (150 ms)** no se usa: sin continuidad de medición no hay nada que cortar.

### Identidad

- Cada apertura de 5A tiene su token y su sesión de análisis. Dart descarta resultados de otro token, y también los que llegan tras salir o tras desecharse el controlador.
- En Kotlin, cada carga del modelo es una **generación**: un resultado o error de otra generación, o posterior a la detención, no toca el estado.
- Reintentar solo actúa tras un error, así que no duplica detectores.
- Salir, pasar a segundo plano o desconectarse cierra analizador, detector e hilo. Esto viene del ciclo de vida de 5A, que ya liberaba la cámara.

## Pruebas

### Con dobles (sin cámara ni modelo)

- **JVM, `FaceAnalysisCoreTest.kt`** (25 pruebas; el plugin pasa 36 en total):
  - verificación del modelo: correcto, ausente, alterado, truncado o más largo, error de lectura, y el asset versionado coincide con el manifiesto;
  - estados 0/1/2;
  - sin resultados nunca es «sin rostro»;
  - límites de Tstale para silencio y edad;
  - callbacks de una generación anterior y tras detener;
  - fallos de creación (`UnsatisfiedLinkError`), de `detectAsync` y de cierre;
  - reintento solo tras un error;
  - marcas no crecientes, resultados desconocidos o repetidos, pendientes acotados, un cuadro cada vez y su plazo, y latido.
  - Doble: `FakeEngine`, con reloj y cola de avisos manuales.
- **Dart, `test/camera/face_analysis_controller_test.dart`** (19 pruebas, con `FakeFrontCameraBridge`):
  - estados;
  - un resultado durante la apertura;
  - token antiguo, salida, segundo plano, cierre nativo y desecho;
  - vigilancia de 3000 ms con `fake_async`: límite exacto, latido, sin ningún resultado, y que la de una apertura anterior no toca la nueva;
  - reintento: solo tras un error, una sola petición y fallo del canal.
- **Dart, `test/camera/face_analysis_screen_test.dart`** (6 pruebas de pantalla):
  - «Detección facial en pruebas»;
  - Calibrar e Iniciar deshabilitados con un rostro;
  - ausencia de «%», «seguro», «puedes conducir» y «DEMO»;
  - varios rostros y sin rostro;
  - caducidad visible;
  - «Reintentar carga» y «Reintentar»;
  - salir cierra.
- **Renderizados:**
  - nuevos, `test/goldens/fase5b/`: 8 estados × claro y oscuro (16);
  - se regeneraron los 18 de `test/goldens/fase5a/`, porque la pantalla tiene ahora las filas Modelo y Rostro y la tarjeta de detección facial.
- **Detección de defectos** (mutaciones temporales, restauradas):

| Mutación | Pruebas que fallan |
|---|---|
| Sin filtro de token en Dart | 1 |
| Sin vigilancia de Flutter | 4 |
| Caducidad con `>` en vez de `>=` | 1 JVM |
| Sin descarte por edad | 1 JVM |
| Sin la guarda de generación en los errores | 1 JVM |

  Sin la guarda de generación en los **resultados** no falla ninguna prueba. El resultado antiguo se descarta igualmente, porque su marca de tiempo no está entre los cuadros pendientes de la carga nueva. Es una doble protección.

### Modelo real en Android (`FaceLandmarkerInstrumentedTest`, 10 pruebas)

- **Mismo código que la app:** usa `FaceAnalysisCore`, `MediaPipeFaceEngine` y `FaceModelLoader`, con el modelo empaquetado en LIVE_STREAM. Envía la imagen como cuadros sucesivos cada 30 ms durante 2,5 s. **No usa la cámara.**
- **Material:** `src/androidTest/assets/face_fixtures/FUENTES.md`, con imágenes de dominio público de la NASA tomadas de Wikimedia Commons, con su URL, SHA-1 del original y SHA-256.

| Prueba | Resultado |
|---|---|
| Un rostro (retrato S85-41895) | Solo `ONE_FACE`, `faceCount=1` |
| Dos rostros (foto S65-56188, Gemini 6) | Solo `MULTIPLE_FACES`, `faceCount=2` |
| Sin rostro («The Blue Marble») | Solo `NO_FACE` |
| Sin rostro, imagen sintética gris | Solo `NO_FACE`. Solo acredita esa imagen |
| Giro: retrato girado 90° antihorario con `rotation=90` | `ONE_FACE`. Con 270 (observación): `NO_FACE` |
| Modelo ausente / alterado | `MODEL_ERROR` con `modelMissing` / `modelCorrupt` |
| Bytes que no son un modelo (el hash los acepta) | `MODEL_ERROR` con `modelIncompatible`: MediaPipe los rechaza |
| Fallo de carga y después «Reintentar carga» | `ONE_FACE` |
| 5 aperturas y cierres seguidos | Cada uno detecta y termina en `STOPPED` |

**Ejecución:** en la AVD `vigia_pixel` (Pixel 8, API 36, x86_64), instalando el APK de pruebas y lanzando `am instrument`. `connectedDebugAndroidTest` falla en este equipo antes de ejecutar: UTP intenta crear `D:\tmp` y Windows deniega el acceso a la raíz de `D:`. Pasan 10 de 10, también tras el último cambio del núcleo. Registros en `D:\dev\vigia-entrega\evidencia-fase5b\androidTest-*.txt`.

```bash
cd android && ./gradlew :monitoring_engine:assembleDebugAndroidTest
adb install -r -t build/monitoring_engine/outputs/apk/androidTest/debug/monitoring_engine-debug-androidTest.apk
adb shell am instrument -w com.juanrueda.monitoring_engine.test/androidx.test.runner.AndroidJUnitRunner
```

### CameraX → MediaPipe en el emulador (app normal release)

- **APK:** `vigia-normal-fase5b-release.apk`, idéntico byte a byte al probado.
- **Fuente de cámara:** la opción de línea de órdenes `-camera-front imagefile:<archivo>` del emulador 37.2.12. La cámara frontal emulada entrega esa imagen fija; **no es una webcam ni una cámara física**.
- **AVD:** `config.ini` no se modificó (mismo SHA-256 antes y después; sigue `hw.camera.front=none`), y se usó `-no-snapshot-save`.
- **Lienzos:** el emulador amplía, recorta y comprime la imagen. Por eso las imágenes de prueba se colocaron en lienzos con `tools/fase5b_lienzo_camara.ps1` y `tools/fase5b_apilar_rostros.ps1`, que solo cambian el encuadre. Los lienzos y sus hashes están en `D:\dev\vigia-entrega\evidencia-fase5b\fuentes-camara\`.

| Caso (captura en `D:\dev\vigia-entrega\capturas\fase5b\`) | Fuente | Resultado |
|---|---|---|
| `01` | Retrato original vertical | El emulador recortó el rostro fuera del cuadro → «Rostro no detectado». Es correcto para lo que se ve |
| `02` | Retrato en un lienzo 4:3 al 60 % | Rostro pequeño y comprimido → «Rostro no detectado» (332 cuadros, 246 resultados) |
| `03` | Recorte de cabeza y hombros (`-Recorte "150,20,300,310" -Escala 0.95`) | **«Rostro detectado»** (403 cuadros, 95 resultados aceptados; antes de limitar a un cuadro cada vez) |
| `04`, `05` | Foto de dos rostros, recortada, en un lienzo 4:3 o 3:4 | El emulador solo deja ver uno de los dos → «Rostro detectado». Correcto para el cuadro |
| `06` | Los dos rostros apilados (`-Arriba "50,10,230,240" -Abajo "300,15,230,240"`) | El emulador recortó y amplió de otra manera; los dos quedan parciales → «Rostro detectado» |
| `07` | «The Blue Marble» en un lienzo 4:3 | «Rostro no detectado» (404 cuadros, 204 resultados) |
| Escena sintética `-camera-front emulated` | Patrón del emulador | «Rostro no detectado». Solo acredita esa escena |

**Dos rostros por la vía CameraX: no demostrado.** La cámara de imagen fija del emulador no deja ver los dos a la vez de forma predecible. «Varios rostros» queda acreditado con el modelo real (prueba instrumentada) y en la interfaz con dobles.

**Ciclo de vida** (fuente del caso `03`; evidencia en `evidencia-fase5b\08_ciclo_de_vida\`):

| Paso | Hilos `VigiaFaceAnaly…` | Clientes de cámara | Rostro |
|---|---|---|---|
| Entrar | 1 | 1 | Detectado |
| HOME | 0 | 0 | — |
| Volver | 1 | — | Detectado |
| Salir a Inicio | 0 | 0 | — |
| Ráfaga de 6 entradas y salidas en ~8 s | 0 al terminar | — | — |
| Entrar otra vez | 1 | — | Detectado |

- El registro muestra 9 sesiones de análisis, cada una con su inicio y su fin, y nunca más de un análisis vivo.
- Sin `FATAL` ni avisos de `TransportRuntime`.
- **Antes** de limitar a un cuadro cada vez, al volver del segundo plano la pantalla mostraba «El último resultado caducó» (resultados descartados por antiguos). Es la caducidad funcionando, y motivó el cambio (`08a_ciclo_de_vida_antes_de_la_cola`).

**DEMO** (`vigia-demo-fase5b-release.apk`, instalado con `adb install -r`):

- sin `CAMERA` ni `INTERNET` en `dumpsys package`;
- historial de la fase 4 conservado (S-DEMO-0003 interrumpida);
- ninguna mención de MediaPipe en logcat y ningún cliente de cámara.

**Manifiestos** (`aapt`):

| APK | Permisos | Menciones de cámara o `datatransport` | `libmediapipe_tasks_jni.so` y modelo |
|---|---|---|---|
| Normal | `CAMERA`, más `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` | — | Sí |
| DEMO | `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` | 0 | No |

## APK (release, firmados con la clave de depuración)

| Variante | Ruta | Bytes | SHA-256 |
|---|---|---|---|
| Normal `com.juanrueda.vigia` | `D:\dev\vigia-entrega\vigia-normal-fase5b-release.apk` | 94 270 965 | `639328dedc4658035781411111b1dc12f88c616ef1a93fe5c4c88376d244b9b0` |
| DEMO `com.juanrueda.vigia.demo` | `D:\dev\vigia-entrega\vigia-demo-fase5b-release.apk` | 58 480 726 | `e565f16e2fc50f805520e70ff38c1c213656814109254430830396849c16d94a` |

- Los APK anteriores se conservan.
- Hashes añadidos a `D:\dev\vigia-entrega\SHA256SUMS.txt`.
- El APK normal crece de 57,8 a 94,3 MB: la biblioteca nativa de MediaPipe para tres ABI y el modelo. El DEMO crece de 57,8 a 58,5 MB: no lleva ni la biblioteca ni el modelo, solo el código Java que conservan las reglas de R8.

## Limitaciones y pendientes

- **D1 y cualquier cámara física:**
  - rostro real;
  - latencia en el teléfono: en el emulador, la edad máxima aceptada fue de 355 a 582 ms, cerca de Tstale;
  - consumo y calor;
  - giro y espejo con un sensor real;
  - dos rostros por la cámara;
  - iluminación;
  - gafas.
- **Webcam:** no se usó. El emulador ofrece `webcam0`, pero captaría a quien esté delante del equipo.
- **Edad desde la captura:** sin conversión de reloj demostrada; no se usa.
- **Telemetría de MediaPipe:** bloqueada por permisos, pero sigue en el código. El almacenamiento local en release no está comprobado. La primera ejecución de pruebas envió estadísticas, como se explica arriba.
- **16 KB:** solo se inspeccionó la alineación; no se ejecutó en un entorno de 16 KB (P16K).
- **TalkBack:** la etiqueta de presencia es una región viva, pero no se probó con TalkBack.
- Lo que no hace esta fase sigue sin hacerse: ojos, Q, calibración, sesiones y alertas.

## Reproducir

```bash
flutter test test/camera test/goldens/fase5a_render_test.dart test/goldens/fase5b_render_test.dart
cd android && ./gradlew :monitoring_engine:testDebugUnitTest
flutter build apk --release                          # normal
flutter build apk --release --dart-define=VIGIA_DEMO=true
emulator -avd vigia_pixel -no-snapshot-save -camera-front "imagefile:<lienzo.png>"
```

En Windows, Gradle necesita `TMP`/`TEMP` en `D:\dev\tmp\jtmp` (ver la fase 5A).
