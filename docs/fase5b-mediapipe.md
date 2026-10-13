# Vigía · Fase 5B: MediaPipe Face Landmarker (presencia facial)

**Autorizada por el usuario:** 2026-10-12. **Estado: pendiente de una nueva revisión de Codex.** No se ha publicado.

- **Primera revisión** (sobre `3be9bf1`): desfavorable por dos P1 de vigencia, corregidos en `c5c0503`.
- **Segunda revisión** (sobre `c5c0503`): desfavorable por otros dos P1 de vigencia, corregidos después. Ver «Corrección de la revisión de Codex (P1)» y «Segunda corrección (P1)».

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

**Incidente durante la prueba.** La **primera** ejecución de la prueba instrumentada usó un APK de pruebas que todavía tenía los permisos de red. Su `JobService` envió esas estadísticas a `firebaselogging.googleapis.com` desde el emulador, paquete `com.juanrueda.monitoring_engine.test`.

- **Evidencia.** El mantenedor vio en logcat, durante la sesión, `Making request to: https://firebaselogging.googleapis.com/v0cc/log/batch?format=json_proto3` y `Status Code: 200` a las 23:14:11–12 UTC del 2026-10-12. Esas líneas **no se guardaron en un archivo**: `androidTest-logcat.txt` solo contiene los estados del modelo. Por eso es un incidente declarado por el mantenedor, no una observación conservada.
- **Contenido: no inspeccionado.** Que no incluyera imágenes, puntos ni datos faciales es una **inferencia** a partir de la implementación (los mensajes de registro de MediaPipe no tienen campos de imagen), no una comprobación del cuerpo enviado.
- **Norma.** Un envío automático así contradice la regla de funcionamiento local sin envíos automáticos (Área 06 §§2 y 19). La mitigación posterior no lo borra.

Después se añadió el manifiesto de pruebas, se desinstaló ese APK y se repitió todo sin red.

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

Los valores son **experimentales**: Tstale y Gmax son candidatos del perfil `lab-eye-rules-0.1` (Área 05 §7, `qualificationStatus=experimental`); el latido, el límite de silencio y el periodo de consulta son la propuesta de transporte de Área 04 §9, o derivan de ella. Ninguno está aceptado para producción.

- **Motor (Kotlin), Tstale = 750 ms.** La edad de un resultado es siempre `ahora − entrega de su cuadro al analizador`, con el reloj monotónico de Android del instante en que se usa:
  - **al aplicarlo** en el hilo de análisis, incluida la espera del aviso en la cola: se descarta si supera 750 ms (con 750 exactos sigue vigente). Vale para cero, uno o varios rostros;
  - **al crear cada mensaje** (cambio, latido o respuesta a una consulta) y **al leer el estado**: si el resultado vigente tiene edad > 750 ms, o silencio ≥ 750 ms desde su aplicación, se retira antes, sin esperar al vigilante. `resultAgeMs` es la edad en ese instante, no la de la aceptación;
  - las marcas imposibles (entrega posterior a la recepción en el hilo de MediaPipe, o recepción posterior a «ahora») se descartan como **inválidas**, no como edad cero;
  - el vigilante corre cada 100 ms, y el motor manda un latido a Flutter cada 1000 ms.
- **Flutter: edad efectiva y Tstale = 750 ms.**
  - **Solo una consulta muestra un rostro.** `getFaceAnalysis(token)` es asíncrona: Kotlin crea la respuesta en el hilo de análisis al atenderla. Dart pone en marcha un cronómetro monotónico (`clock.stopwatch()`) justo antes de llamar y calcula: edad efectiva = `resultAgeMs` + tiempo completo de la consulta. Puede sobreestimar la edad, porque incluye la ida y la vuelta del puente, pero nunca la rejuvenece. **No se comparan relojes de Dart y Android.**
  - Con edad efectiva > 750 ms, el resultado no se muestra. Si se acepta, su vigencia restante es `750 − edad efectiva`, contada en Dart desde la respuesta; al agotarse, «El último resultado caducó y ya no se muestra».
  - Un mensaje del mismo `resultId` nunca alarga ese plazo: se queda el menor de los conocidos. Como `resultId` crece dentro de la apertura, un resultado caducado, sustituido o anterior al mostrado no vuelve a mostrarse. El retiro es conservador: se basa en una sobreestimación de la edad.
  - **Avisos sin consulta** (`onFaceAnalysis`, por `main.post` y el canal): su demora no tiene cota y no se puede medir sin sincronizar relojes. Por eso una detección avisada **nunca** se muestra: solo dispara una consulta. Los estados que no afirman la presencia de nadie (cargando, esperando, errores, detenido) sí se aceptan del aviso, en orden.
  - Con la cámara abierta, Dart consulta cada **200 ms** (experimental, menor que Tstale), para que un rostro estable no se interrumpa entre avisos. Una consulta sin respuesta durante más de 750 ms se abandona, porque su respuesta ya llegaría caducada, y no bloquea las siguientes.
- **Flutter, 3000 ms: límite de silencio del motor.** Sin avisos ni respuestas durante 3000 ms, se declara silencio. **No** autoriza a mostrar un rostro durante ese tiempo: la vigencia de un rostro la fija Tstale.
- **Edad medida.** Va desde la entrega al analizador, no desde la captura. No se demostró la conversión entre el reloj del sensor (`ImageInfo.timestamp`) y `elapsedRealtime` (Área 05 §4), así que la latencia de captura a entrega no se incluye.
- **Gmax (150 ms)** no se usa: sin continuidad de medición no hay nada que cortar.

### Identidad

- Cada apertura de 5A tiene su token y su sesión de análisis. Dart descarta resultados de otro token, y también los que llegan tras salir o tras desecharse el controlador.
- **Orden dentro de una apertura.** El motor numera cada mensaje (`sequence`, estrictamente creciente). Dart descarta:
  - un `sequence` ya visto o menor (repetido o atrasado);
  - una `generation` menor que la última aceptada;
  - **todo** mensaje de la apertura posterior a `stopped`, que es definitivo.

  Cada apertura nueva empieza su propio orden.
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

**Ejecución:** en la AVD `vigia_pixel` (Pixel 8, API 36, x86_64), instalando el APK de pruebas y lanzando `am instrument`. `connectedDebugAndroidTest` falla en este equipo antes de ejecutar: UTP intenta crear `D:\tmp` y Windows deniega el acceso a la raíz de `D:`. Pasan 10 de 10 con el código de `3be9bf1`. **No se repitieron tras la corrección P1**, por indicación: el cambio del núcleo afecta al momento de medir la edad y lo cubren las pruebas JVM y la comprobación dirigida por CameraX. Registros en `D:\dev\vigia-entrega\evidencia-fase5b\androidTest-*.txt`.

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

## Corrección de la revisión de Codex (P1)

**Dictamen sobre `3be9bf1`: desfavorable** por dos P1 de vigencia. Reproducciones de Codex en `build/review-fase5b/` (`review_stale_test.dart`, `ReviewStale.kt`).

1. **Flutter renovaba resultados antiguos.**
   - Problema: cualquier mensaje del token vigente reiniciaba los 3000 ms, de modo que el mismo resultado entregado otra vez tras caducar volvía a mostrar «Rostro detectado». Además, un mensaje de una generación anterior revivía un análisis ya detenido.
   - Corrección: ver «Identidad» y «Política de caducidad».
     - El contrato Pigeon añade `sequence` (orden de publicación) y `resultId` (identidad de la inferencia: única en la apertura, nula sin resultado vigente; un latido repite la de la última aceptada).
     - Dart ordena y filtra los mensajes, trata `stopped` como definitivo, y solo renueva la vigencia con un `resultId` nuevo.
2. **Kotlin publicaba un aviso retrasado como vigente.**
   - Problema: la edad se calculaba con la hora tomada en el hilo de MediaPipe antes de encolar el aviso. Un aviso de un cuadro de 1000 ms, recibido a 1100 ms y aplicado a 5000 ms, se publicaba como `ONE_FACE` con 100 ms.
   - Corrección: la edad y el silencio se miden con el reloj del momento de aplicarlo, y las marcas imposibles se descartan (ver «Política de caducidad»).
   - No cambian Tstale (750 ms) ni el límite de Flutter (3000 ms).

**Regresiones:**

| Archivo | Pruebas nuevas | Qué cubren |
|---|---|---|
| `test/camera/face_analysis_controller_test.dart` | 10 | Las dos reproducciones de Codex; `stopped` definitivo incluso ante una generación posterior; mismo mensaje entregado otra vez; mensaje atrasado; generación anterior con `sequence` mayor; latido de la misma inferencia sin ampliar el plazo (límite exacto 2999/3000 ms); control positivo de una inferencia nueva justo antes del límite; apertura nueva con orden propio; plazo de una inferencia llegada durante la apertura |
| `FaceAnalysisDelayTest.kt` (JVM) | 5 | Reproducción de Codex para 0, 1 y 2 rostros; límite 750/751 ms con despacho retrasado; control positivo de un resultado nuevo tras uno retrasado; silencio desde la aplicación (749/750); entrega «futura» descartada |
| `FaceAnalysisCoreTest.kt` (JVM) | 2 | `sequence` creciente y `resultId`; el latido lleva la última inferencia aceptada |

Además se corrigieron dos pruebas propias que emitían el **mismo** resultado como si fuera nuevo; ahora usan otro `resultId`.

**Detección con el código anterior** (copia temporal `git worktree` de `3be9bf1` en `D:\dev\tmp`, ya eliminada; solo con pruebas que compilan contra la API anterior):

- **Dart:** fallan las 3 regresiones expresables sin `sequence` ni `resultId`: las dos reproducciones y la del latido.
- **JVM:** fallan 4 de las 5 de `FaceAnalysisDelayTest`. La quinta es el control positivo, que pasa en ambas versiones.

**Resultados reales:**

- `dart format` y `flutter analyze` (app y plugin): sin problemas.
- `test/camera` y los renderizados de 5A y 5B: pasan 113. Los renderizados no cambiaron.
- `build/review-fase5b/review_stale_test.dart`: pasa 2/2.
- Plugin: 3 pruebas Dart y 43 JVM pasan.
- `tools/generate_pigeon.py --check` (tras preparar el commit), `git diff --check` y `spec_registry.py check`: OK.
- No se repitieron la suite completa, las matrices, el contraste ni los ensayos del modelo.

**Comprobación dirigida CameraX → MediaPipe** (emulador, `-camera-front imagefile:` con el lienzo del caso 03; `vigia-normal-fase5b-p1-release.apk` instalado con `adb install -r`):

- el paquete instalado solo tiene `CAMERA`, sin `INTERNET` ni `ACCESS_NETWORK_STATE`;
- «Rostro detectado» al entrar, al volver de segundo plano y al reentrar tras una ráfaga de 6 entradas y salidas;
- 0 hilos de análisis y 0 clientes de cámara tras HOME y tras salir; nunca más de un análisis vivo (9 sesiones);
- sin `FATAL` ni avisos de `TransportRuntime`;
- contadores: 45 de 47 y 54 de 55 resultados aceptados, 1 descartado por antiguo, y una **edad máxima aceptada de 654–675 ms**. Ahora incluye la espera en la cola del hilo de análisis: en el emulador el margen hasta Tstale es estrecho;
- AVD sin cambios: `config.ini` con el mismo SHA-256.
- Evidencia en `D:\dev\vigia-entrega\evidencia-fase5b\09_correccion_p1\`; captura `capturas\fase5b\09_correccion_p1_rostro_detectado.png`.

**Observación de la revisión no corregida aquí** (se pidió corregir solo los P1): `MediaPipeFaceEngine.detectAsync` no cierra explícitamente el `MPImage` de entrada, aunque el `Bitmap` subyacente sí se recicla; y el `MPImage` del listener se cierra fuera de un `finally`. En la segunda revisión, Codex examinó el bytecode y el código nativo (copia con `memcpy` antes de volver) y no encontró ninguna fuga ni liberación prematura reproducible. Queda como mejora de robustez, no como defecto.

## Segunda corrección (P1)

**Dictamen sobre `c5c0503`: desfavorable** por otros dos P1 de vigencia. Reproducciones de Codex en `build/review-fase5b-p1/`:

- `review_transport_delay_test.dart`: puente Pigeon real, mensaje retenido 5000 ms;
- `ReviewCoreResidual.kt`: latido a 2051 ms con un resultado de 751 ms.

1. **Kotlin publicaba en un latido un resultado de más de 750 ms.**
   - Problema: la edad solo se comprobaba al aceptar la inferencia. Cuadro 1300, aceptación 1950 (650 ms), latido 2051: se anunciaba `ONE_FACE` (o 0 o 2 rostros) con «650 ms», cuando tenía 751.
   - Corrección: la edad y el silencio se reevalúan con el reloj actual al crear cada mensaje y al leer el estado, y `resultAgeMs` es la edad actual (ver «Política de caducidad»).
2. **Flutter perdía la demora del puente.**
   - Problema: un mensaje retenido 5000 ms con `resultAgeMs=40` se mostraba como vigente, y el plazo de 3000 ms empezaba a su llegada.
   - Corrección: edad efectiva = `resultAgeMs` + tiempo completo de la consulta; un aviso nunca muestra un rostro; el límite de 3000 ms es solo de silencio (ver «Política de caducidad»).
   - El contrato añade la consulta `getFaceAnalysis` y cambia la semántica de `resultAgeMs`; Pigeon se regeneró.

Tstale sigue en 750 ms y el silencio en 3000 ms. **No se reabrió el cierre de los `MPImage`**: no hay evidencia nueva, y el análisis de Codex no encontró fuga.

**Regresiones:**

| Archivo | Pruebas | Qué cubren |
|---|---|---|
| `FacePublishAgeTest.kt` (JVM) | 4 | Reproducción de Codex en el latido para 0, 1 y 2 rostros; límite 750/751 en un latido, que informa 750 y no la edad de aceptación; lectura del estado entre ticks; control positivo con resultados frescos |
| `FaceAnalysisCoreTest.kt` (JVM) | +2 | `snapshotNow`: edad actual, retiro al pasar de 750, numeración compartida y que la consulta no se avisa; límite de silencio 749/750 |
| `FaceAnalysisDelayTest.kt` (JVM) | 1 sustituida | `ageKeepsCountingFromTheFrameAfterApplication`: la edad sigue contando desde el cuadro tras aplicarlo |
| `test/camera/face_analysis_controller_test.dart` | nuevo grupo «edad efectiva y vigencia» | Reproducción de Codex (retenido 5000 ms, 0/1/2 rostros); control positivo con transporte corto y caducidad tras mostrarse (700/701 ms); límites 750/751; caducidad mientras espera en el puente (710/711 ms); latido o consulta del mismo resultado sin rejuvenecer, antes y después de caducar; un aviso de detección no se muestra sin consulta; una consulta sin respuesta no bloquea; inferencias sucesivas mantienen el rostro; descuento del tiempo durante la apertura |
| Mismo archivo | grupo «silencio del motor» y grupo de orden | Silencio de 3000 ms con y sin respuestas, y entre aperturas; reproducciones de la primera ronda, `stopped`, aviso atrasado, generación anterior y reapertura |
| `test/camera/face_analysis_bridge_test.dart` | 7 | **Puente Pigeon real** con el códec generado: aviso retenido 5000 ms (el motor lo informa con 5040) sin rostro, para 0/1/2; control positivo con 10 ms de puente y caducidad a los 700 ms; 711 ms de consulta sin rostro |

**Detección con el código anterior** (copia temporal `git worktree` de `c5c0503`, ya eliminada):

- **Dart:** fallan las 3 reproducciones de Codex con el puente real y las 4 regresiones expresables con la API anterior: retenido 5000 ms para 0/1/2 y caducidad a los 750 ms tras mostrarse.
- **JVM:** fallan 3 de las 4 de `FacePublishAgeTest`. La cuarta es el control positivo.
- El reproductor Kotlin de Codex, compilado con el núcleo actual en un directorio temporal, termina sin error: a 2051 ms publica `WAITING_RESULTS`.

**Resultados reales:**

- `dart format` y `flutter analyze` (app y plugin): sin problemas.
- `test/camera`, los renderizados de 5A y 5B y las 5 reproducciones de Codex de ambas rondas: pasan 133. Los renderizados no cambiaron.
- Plugin: 3 pruebas Dart y 49 JVM pasan.
- Pigeon regenerado: `generate_pigeon.py --check` (tras preparar el commit) y `spec_registry.py check`: OK.
- No se repitieron la suite completa, las matrices, el contraste ni los ensayos del modelo.

**Comprobación dirigida CameraX → MediaPipe** (emulador, `-camera-front imagefile:` con el lienzo del caso 03; `vigia-normal-fase5b-p1b-release.apk` instalado con `adb install -r`):

- el paquete instalado solo tiene `CAMERA`;
- 0 hilos y 0 clientes de cámara tras HOME y al salir; nunca más de un análisis vivo (9 sesiones);
- sin `FATAL` ni `TransportRuntime`; AVD sin cambios.
- **La detección es intermitente en el emulador.** Con la vista sostenida, 18 de 20 muestras dicen «Rostro detectado» y 2 «Esperando resultados» («El último resultado caducó»). Dos de los tres pasos del ciclo de vida cayeron en «Esperando resultados».
  - Contadores de esa sesión: 550 cuadros enviados, 545 aceptados, 4 descartados por antiguos y una edad máxima aceptada de 691 ms.
  - Cerca de Tstale, la edad efectiva supera a veces 750 ms entre inferencias. Es el comportamiento conservador exigido: no se amplía el umbral para disimularlo.
  - El volcado de `uiautomator` añade carga al emulador. En D1 no se ha medido.
- Evidencia en `D:\dev\vigia-entrega\evidencia-fase5b\10_correccion_p1b\` (`pasos.txt`, `logcat.txt`, `muestreo.txt`); captura `capturas\fase5b\10_correccion_p1b_rostro_detectado.png`.

## APK (release, firmados con la clave de depuración)

| Variante | Ruta | Bytes | SHA-256 |
|---|---|---|---|
| Normal `com.juanrueda.vigia` | `D:\dev\vigia-entrega\vigia-normal-fase5b-release.apk` | 94 270 965 | `639328dedc4658035781411111b1dc12f88c616ef1a93fe5c4c88376d244b9b0` |
| DEMO `com.juanrueda.vigia.demo` | `D:\dev\vigia-entrega\vigia-demo-fase5b-release.apk` | 58 480 726 | `e565f16e2fc50f805520e70ff38c1c213656814109254430830396849c16d94a` |
| **Normal corregido (P1)** `com.juanrueda.vigia` | `D:\dev\vigia-entrega\vigia-normal-fase5b-p1-release.apk` | 94 270 965 | `e525db8a088035a2e1324e1d307de85f381fb8a49fd952024be194c1abacc51b` |
| **Normal, segunda corrección (P1)** `com.juanrueda.vigia` | `D:\dev\vigia-entrega\vigia-normal-fase5b-p1b-release.apk` | 94 270 965 | `2f435d49c2e34d94b524671acf222734b745fec6d0548e938cdd68272b7deaf1` |

El APK DEMO no se recompiló en ninguna de las dos correcciones. Los cambios afectan al análisis facial de la variante normal y al contrato del plugin, que la DEMO no ejecuta, así que el APK DEMO de la tabla no incluye este código.

- Los APK anteriores se conservan.
- Hashes añadidos a `D:\dev\vigia-entrega\SHA256SUMS.txt`.
- El APK normal crece de 57,8 a 94,3 MB: la biblioteca nativa de MediaPipe para tres ABI y el modelo. El DEMO crece de 57,8 a 58,5 MB: no lleva ni la biblioteca ni el modelo, solo el código Java que conservan las reglas de R8.

## Limitaciones y pendientes

- **D1 y cualquier cámara física:**
  - rostro real;
  - latencia en el teléfono: en el emulador, la edad máxima aceptada fue de 355 a 691 ms, cerca de Tstale. Con la vigencia estricta de la segunda corrección, la detección es intermitente en el emulador (2 de 20 muestras «Esperando resultados»); en D1 no se ha medido;
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
