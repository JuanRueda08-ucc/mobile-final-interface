# Vigía · Estado del prototipo

Resumen para retomar el trabajo en una sesión nueva. Plan activo y reglas: `AGENTS.md`. Guías: `docs/fase2-recorrido-demo.md` (recorrido), `docs/fase3-historial-ajustes.md` (app DEMO, historial y Ajustes) `docs/fase5a-camara-permisos.md` (cámara frontal real y permisos) y `docs/fase5b-mediapipe.md` (presencia facial con MediaPipe). Entorno: `docs/toolchain.md`.

**Actualizado:** 2026-10-13 (fase 5B: cuarta corrección, registro por canal y plazo al recibir; pendiente de nueva revisión de Codex).

## Fases

| Fase | Estado | Commits |
|---|---|---|
| 1. Instrucciones, base visual e Inicio (P03) | Aprobada por Codex dentro de su alcance y subida a `origin/main` | hasta `f4f62bc` |
| 2. Recorrido demostrativo (P04–P07, D01/D02/D05) | Aprobada por Codex dentro de su alcance y subida a `origin/main` | `e7a2381`, `a211c5c`, `3ff7707`, `f771d34`, `26fe51a` |
| 3. App DEMO separada, persistencia, Historial y Ajustes | **Aprobada por Codex dentro de su alcance y publicada en `origin/main`** (`486bf725737be06fe25f25227646e55e9240f2d8`, confirmado con `git fetch`). La revisión corrigió P1/P2 (`7c91f46`), el aviso de Ajustes (`f86c6ed`) y los avisos de Sonido (P13, `486bf72`) | `7481d87`, `07528db`, `96bf5e9`, `f9b4828`, `9d54956`, `7c91f46`, `f86c6ed`, `486bf72` |
| 4. Comprobación final y entrega | **Aprobada por Codex (dictamen final favorable) dentro del alcance DEMO**, respaldada por el recorrido en emulador (sección «Fase 4»). Pendientes declarados abajo: D1, TalkBack, revisión visual completa de ambos temas y una observación no reproducida | `cad9f51`, `f696ffe`, `4ea6a56`, `2356cad` y el commit documental de cierre |
| 5A. Cámara frontal real y permisos (variante normal) | **Aprobada por Codex dentro de su alcance (permiso CAMERA y CameraX Preview) y publicada en `origin/main`.** Sin MediaPipe ni detección de fatiga. Pendientes físicos en «Cierre de la fase 5A» | `a3839e3`, `4a9b5a9`, `80969c8` y el commit documental de cierre |
| 5B. MediaPipe Face Landmarker: presencia facial (variante normal) | Revisiones de Codex desfavorables sobre `3be9bf1`, `c5c0503` (vigencia), `a935729` y `8f715dd` (consultas). **Corregidos; pendiente de nueva revisión.** Commits locales en `main`, sin publicar. Sin evaluación ocular, calibración, sesiones ni alertas de fatiga | `3be9bf1`, `c5c0503`, `a935729`, `8f715dd` y el commit de la cuarta corrección |

Las fases 1 a 4 están aprobadas, cada una dentro de su alcance, como prototipo DEMO y con las limitaciones de «No comprobado». La fase 5A añade a la **variante normal** la vista previa real de la cámara frontal y el permiso CAMERA. La fase 5B añade, en esa misma pantalla, **detección facial en pruebas** con MediaPipe Face Landmarker en el teléfono: indica si hay ningún rostro, uno o varios. **No hay detección de fatiga**: no se evalúan los ojos, y no hay calibración, sesiones ni alertas reales. El recorrido DEMO sigue simulado, rotulado «DEMO — datos simulados» y sin permiso CAMERA.

## Fase 3 (aprobada y publicada)

| Commit | Bloque |
|---|---|
| `07528db` | App DEMO separada. Gradle deriva `com.juanrueda.vigia.demo` («Vigía DEMO») de `VIGIA_DEMO`; la normal sigue siendo `com.juanrueda.vigia` («Vigía»). Añade el canal `vigia/app` y la exclusión de copias de seguridad |
| `96bf5e9` | Historial DEMO con Drift/SQLite (`vigia_history_demo_v1.sqlite`) y su repositorio, separado del controlador y de los widgets |
| `f9b4828` | Arranque coherente con el applicationId; el recorrido guarda y lee del repositorio; registro interrumpido; P08, P09, P12 y P13; pruebas y renderizados |

Decisiones y límites (detalle en `docs/fase3-historial-ajustes.md`):

- **Esquema.** Es un subconjunto DEMO de Área 06 §6: sin modelo, política ni hashes inventados; los tiempos se calculan desde los hechos; IDs `S-DEMO-NNNN`.
- **Cierre.** Se guarda una sola vez. Si la app se cierra sin cierre confirmado, al reabrirla la sesión queda **Interrumpida**: no se reanuda, no tiene fin ni totales, y el último registro es el último hecho guardado.
- **Preferencias.** Tema y movimiento reducido se guardan y se aplican; la reducción de movimiento de Android se respeta siempre. El patrón de sonido solo cambia si se guardó y obliga a repetir la prueba de sonido.
- **No implementado:**
  - P10, P11 y P14–P18;
  - exportación, borrado y retención;
  - D03, D04 y D06–D08.
  
  **OI-08 sigue abierto** (RF27.CA2 sin tocar).
- **Referencia de calibración.** Sigue en memoria: tras reabrir la app hay que calibrar de nuevo.

## Correcciones de la revisión de la fase 3 (aprobadas)

1. **P1 · segundo guardado de preferencias.** El INSERT omitía `singleton`, que SQLite trata como rowid (INTEGER PRIMARY KEY). En la segunda escritura proponía `singleton=2` y el CHECK la rechazaba (`SqliteException(275)`) antes de llegar al conflicto. Ahora se fija `singleton=1`.
2. **P2 · operaciones simultáneas.** `PreferencesController` encola las escrituras en el orden pedido, y cada cambio se aplica sobre las últimas preferencias guardadas:
   - tema y movimiento se ven mientras se guardan; el patrón cambia solo al guardarse;
   - un fallo retira su cambio y se informa como «Preferencia no guardada», sin perder lo ya guardado. Antes, un tema no guardado quedaba aplicado;
   - al terminar, memoria, interfaz y SQLite coinciden.

Regresiones:

- `test/history/preferences_persistence_test.dart`, con SQLite en disco, conexiones nuevas y escrituras liberadas por la prueba:
  - patrón y tema en ambos órdenes;
  - combinaciones;
  - fallos;
  - respuesta tardía de la prueba con el patrón anterior;
  - alerta siguiente con el patrón guardado.
- `test/demo/fase3_flow_test.dart`: «Guardar» de Sonido por semántica, tras otra preferencia ya guardada, en claro y oscuro.

**Detección de los defectos.** Con el código anterior, las 7 regresiones de P1/P2 (todas salvo la de respuesta tardía, que ya pasaba) y las 2 semánticas fallaban. Con solo P1 corregido, seguían fallando 4 de P2; la de orden inverso pasaba ya con el código anterior.

**Resultados reales:**

- `flutter analyze`: sin problemas.
- `test/monitoring`, `test/history` y `test/demo/fase3_flow_test.dart`: pasan las 55 pruebas.
- `build/review/fase3_review_test.dart`: pasan 25 de 26. La que falla («guardar patrón y cambiar tema sin esperar») ahora termina con SQLite y la interfaz en `patron_2/dark`. Falla después, en su `requestStart()`: tras cambiar el patrón la prueba de sonido queda pendiente, como exige RF29.CA3, y la reproducción no la repite. La regresión propia cubre ese caso repitiendo la prueba.
- `build/review/fase2_review_test.dart`: no compila. Sus reproductores falsos no aceptan el parámetro `patternId` que la fase 3 añadió a `AlertSoundPlayer.play`. No se modificó ese archivo de Codex.
- No se repitieron, por indicación: la suite completa, el contraste, los renderizados ni las compilaciones Android.

## Corrección del aviso de fallo de preferencias (aprobada)

**Hallazgo de Codex.** Claro → Oscuro → Reducido mientras se guarda → falla Oscuro → se guarda Reducido. Los datos terminaban bien, pero Ajustes decía que había fallado «el último cambio», que sí se guardó.

**Corrección** (`PreferencesController` y `settings_screen.dart`):

- cada cambio lleva la preferencia que toca (tema, movimiento reducido o patrón) y el valor pedido;
- el fallo se guarda por preferencia, y solo si nadie volvió a cambiarla después;
- se borra si esa preferencia se cambia o se guarda otra vez, y al empezar una serie nueva de cambios;
- el aviso se construye con el valor vigente, por ejemplo «No se pudo guardar el tema oscuro. El tema sigue en Claro.»;
- la serialización, la persistencia y la reversión de `7c91f46` no cambian.

**Pruebas** (`test/history/preferences_persistence_test.dart`):

- Oscuro falla y Reducido se guarda: el aviso es del tema y el movimiento reducido queda guardado (memoria y SQLite reabierto);
- Reducido falla y Oscuro se guarda: el aviso es del movimiento;
- un fallo seguido de otro cambio guardado de la misma preferencia, tanto mientras se guarda como después del aviso: no queda aviso que contradiga el valor vigente;
- prueba de widget de Ajustes con el caso de Codex.

**Resultados reales:**

- `flutter analyze`: sin problemas.
- `test/history` y `test/demo/fase3_flow_test.dart`, junto con `build/review/fase3_correcciones_review_test.dart` completo: pasan 71 pruebas.
- **Detección.** Con el `lib/` anterior (guardado temporalmente con `git stash`), la reproducción de Codex «mensaje identifica fallo anterior» falla mostrando «No se pudo guardar el último cambio…». Con la corrección pasa. Las pruebas propias usan la API nueva (`failures`) y no compilan con el código anterior.
- No se repitieron, por indicación: matrices, contraste, renderizados ni compilaciones Android. Los APK existentes siguen siendo anteriores a `7c91f46`.

## Corrección de los avisos de Sonido (P13) (aprobada)

**Hallazgos de Codex.** `sound_screen.dart` actualizaba su aviso con la respuesta de cada guardado, aunque una petición posterior ya la hubiera sustituido. Eso causaba dos problemas:

- el fallo decía «Las alertas siguen usando el patrón anterior», sin nombrar ningún patrón;
- con Patrón 3 → Patrón 1 pendiente → falla el 3, aparecía «Patrón no guardado» para la selección vigente.

**Corrección:**

- P13 ya no guarda el resultado de cada respuesta.
- El aviso de error sale de `PreferencesState.failures`, que ya descarta un fallo si se pidió otro patrón después. Su texto usa el patrón confirmado: «No se pudo guardar el Patrón 3. Las alertas siguen con el Patrón 2.»
- «Patrón guardado» solo aparece si el patrón confirmado es el último que pidió la pantalla y no queda otro cambio de patrón pendiente. Para eso el estado expone `pending`, las preferencias con escrituras en curso.
- La cola, la persistencia y la invalidación de la prueba de sonido no cambian.

**Pruebas de pantalla nuevas** (`test/history/preferences_persistence_test.dart`, grupo «Sonido (P13)»):

- el fallo nombra el patrón pedido y el confirmado;
- un fallo antiguo no se muestra si ya se pidió otro patrón, y al confirmarse ese aparece «Patrón guardado»;
- un éxito antiguo no anuncia como guardada una selección posterior pendiente.

**Resultados reales:**

- `dart format`; `flutter analyze`: sin problemas.
- `test/history/preferences_persistence_test.dart`: pasan las 15 pruebas.
- `test/history` y `test/demo/fase3_flow_test.dart`: pasan las 40 pruebas.
- `build/review/fase3_avisos_review_test.dart` completo: pasan 4/4.
- **Código anterior**, en una copia temporal (`git worktree` de `f86c6ed` en `D:\dev\tmp`, ya eliminada; sin `git stash`):
  - los dos casos P13 de Codex fallan: mensaje genérico y aviso obsoleto;
  - de las 3 pruebas nuevas, fallan 2. La del éxito antiguo pasa también con el código anterior, que ya ocultaba ese aviso mientras la selección difería; se mantiene como protección.
- No se repitieron, por indicación: matrices, contraste, renderizados ni compilaciones Android. Los APK existentes siguen siendo anteriores a `7c91f46`.

## Comprobado (fase 3)

- `flutter analyze`: sin problemas.
- `flutter test`: pasan 534 pruebas, entre ellas:
  - el repositorio sobre SQLite real, con relectura desde otra instancia de la base;
  - el reinicio simulado (desmontar la app y reabrirla sobre la misma base);
  - las preferencias;
  - la separación DEMO/normal;
  - la activación semántica;
  - la matriz de disposición con 10 estados nuevos.
- `python tools/spec_registry.py check`: OK.
- **Renderizados.** Los de la fase 3 están en `test/goldens/fase3/` (44). Cambian P03 «último resumen» y P07 de la fase 2, que ahora leen el dato guardado.
- **APK normal.** `flutter build apk --release`: `package: name='com.juanrueda.vigia'`, `application-label:'Vigía'` (aapt). Atención: ese APK normal se compiló desde el árbol de trabajo antes de los commits de la fase 3. La compilación DEMO posterior lo sobrescribió en la misma ruta, así que ya no existe. Es anterior a las correcciones P1/P2. No acredita una compilación normal actual de la fase 3. Además, el primer intento de compilación normal falló (`java.util` en el script de Gradle, corregido con `import java.util.Base64`), y aapt leyó entonces el APK de la fase 2 que seguía en esa ruta.
- **APK DEMO.** `flutter build apk --release --dart-define=VIGIA_DEMO=true`:
  - `package: name='com.juanrueda.vigia.demo'`, `application-label:'Vigía DEMO'`;
  - `libsqlite3.so` para arm64-v8a, armeabi-v7a y x86_64;
  - `allowBackup=false` con las dos reglas de exclusión;
  - 56 997 370 bytes, SHA-256 `09afe83ff10ea72ac3cd6552045a0e2a07e2df2159a3b8813d87315a71524081`.
  
  Ese APK es **anterior a las correcciones P1/P2**: no las incluye hasta recompilarlo.

## No comprobado

- **Sin teléfono D1:**
  - instalación de las dos apps;
  - reinicio real del proceso Android: el de las pruebas es el desmontaje de la app sobre la misma base;
  - copia de seguridad y transferencia;
  - audio físico de los tres patrones;
  - TalkBack real.
- **Simulación.** Se rotula siempre «DEMO — datos simulados»; no hay cámara ni IA reales.

## Fase 4 · recorrido en emulador (2026-10-12, aprobada)

**Entorno.** AVD `vigia_pixel` (Pixel 8, Android 16 / API 36, `google_apis` x86_64, 1080×2400), creado en `D:\dev\avd` (en `C:` no cabe el disco de 12 GB; variable de usuario `ANDROID_AVD_HOME`). Sin teléfono D1.

**Artefacto probado.** `D:\dev\vigia-entrega\vigia-demo-486bf72-release.apk` (SHA-256 `86821fd612984b01cdaa88754ebe66ab163394dbb1cce3865d9462d03b8ef176`, nombre con el commit `486bf72` = HEAD, árbol limpio). Instalado con `adb install -r` sobre la app que había (compilada con `flutter run --dart-define=VIGIA_DEMO=true`, misma clave de depuración); no se desinstaló nada ni se borró ninguna base. Nombre y paquete: `com.juanrueda.vigia.demo`, «Vigía DEMO». Dos primeros intentos de `flutter run` normal mostraron la variante «Vigía» sin recorrido: no cuentan para esta comprobación.

**Método.** Interacción real por `adb` (toques sobre el árbol de accesibilidad de `uiautomator` y capturas), sin hot reload. El proceso se detuvo con `am force-stop` y se comprobó sin PID antes de reabrir.

| Paso | Resultado |
|---|---|
| 1. Preparación, sonido, Calibración | Seis condiciones; Iniciar bloqueado con «Calibración pendiente · Prueba de sonido pendiente». «Probar sonido» abre y cierra el flujo de audio del emulador y habilita «Lo escuché» («Reproducción técnica correcta»). Calibración «Comenzar» → «Recogiendo referencia» → Aceptar → `C-DEMO-0001` → Usar referencia → Iniciar habilitado |
| 2. Monitoreo | `S-DEMO-0001`. El ciclo de 43 s se vio en el tiempo activo: Advertencia a ~8 s, Cierre ocular prolongado a ~20 s, «Recuperando» y vuelta a «Sin señales persistentes». Pausar: «Monitoreo pausado / Evaluación suspendida», cronómetro detenido (00:08:32 fijo); Reanudar: vuelve a Activo y el tiempo continúa |
| 3. Cierre | D02 «¿Finalizar la sesión?» → Resumen «Completo · guardado»: cobertura 83,5 %, evaluable 446,0 s, no evaluable 88,0 s, pausado 17,8 s, monitoreado 534,0 s, 25 episodios (13 advertencias, 12 cierres), «25 reproducidos · 0 fallidos». Detalle, Historial e Inicio («Último resumen») coinciden |
| 4. Segunda sesión | `S-DEMO-0002` (94,3 s, cobertura 83,0 %, 5 episodios). La calibración seguía aplicable, y la prueba de sonido se exigió de nuevo. Historial: 0002 y 0001, una fila cada una |
| 5. Ajustes | Ráfagas de toques sin pausa en Tema y Movimiento (Claro/Oscuro/Reducido/Según Android): la interfaz termina en el último pedido y muestra «Preferencia guardada». Sonido: Patrón 2 guardado (con tono de prueba), Patrón 3 guardado y Patrón 1 guardado inmediatamente antes de otra ráfaga de tema. Sin errores ni avisos de fallo |
| 6. Reinicio real | Tras detener el proceso: Historial con 0001 y 0002, «Último resumen» 0002, tema Oscuro, movimiento Reducido, Patrón 1 (guardado). Preparación pide Calibración y sonido de nuevo |
| 7. Sesión abierta | `S-DEMO-0003` iniciada, proceso detenido a los ~39 s: al reabrir, Inicio muestra «Sesión interrumpida» (Inicio 19:48; último registro 19:49), «Final: Desconocido», «Duración: No disponible». Detalle: «Último registro confirmado +00:37», cobertura no disponible, 2 episodios confirmados. Segunda reapertura: sigue habiendo un solo registro 0003 interrumpido, sin duplicados (3 filas en Historial, 1 en «Interrumpidas») |

**logcat.** Sin `FATAL`, sin cierres, sin errores de Flutter ni de SQLite. Solo `AppOps: attributionTag not declared in manifest` (ruido del sistema al reproducir audio) y el aviso de depuración «jdwp» de la instalación de depuración previa.

**Sin fallos reproducidos; no hay regresión nueva.** Una observación sin reproducir: en la segunda sesión, un primer toque en «Finalizar» durante el monitoreo no abrió el diálogo; el siguiente sí. No se repitió y no se ha atribuido a la app (puede haber coincidido con la actualización de la pantalla).

**Sonido.** La aceptación técnica (se abrió y cerró la reproducción de audio en el emulador, la app informó «Reproducción de prueba correcta. Esto no confirma que lo hayas oído») **no equivale a haberlo oído**. Los toques sobre «Lo escuché» durante el recorrido fueron parte de la prueba de flujo, no una confirmación de audibilidad. **Audibilidad confirmada por el usuario (2026-10-12):** escuchó los tres patrones, probados desde Ajustes → Sonido, y suenan distintos. Es un testimonio del usuario, sin registro de dispositivo ni de volumen; no sustituye la prueba en el teléfono D1.

**Capturas** (20) en `D:\dev\vigia-entrega\capturas\emulador\`. Corresponden al tema Oscuro del sistema o al guardado en cada momento; no sustituyen la revisión visual en claro y oscuro.

**Corrección documental.** El comando `adb install -r` de `docs/fase3-historial-ajustes.md` carecía de comillas, y Bash descartaba las barras de la ruta Windows. Ahora lleva la ruta entre comillas simples. Se comprobó, sin instalar, que Bash la recibe como un solo argumento y que el archivo existe (57 013 754 bytes, SHA-256 `86821fd6…ef176`). `git diff --check` limpio. La fase 4 sigue pendiente del dictamen final de Codex.

## No comprobado (fase 4)

- **Teléfono D1:** instalación física, audio de los tres patrones en el teléfono, copia de seguridad. La audibilidad registrada arriba es una confirmación del usuario, no una prueba en D1.
- **TalkBack real.**
- **Revisión visual completa de ambos temas.** El recorrido se ejecutó sobre el tema del momento (mayormente Oscuro); el Claro solo se vio en Ajustes.
- **Observación no reproducida.** Un primer toque en «Finalizar» durante el monitoreo de la segunda sesión no abrió el diálogo; el siguiente sí. No se repitió y no se atribuye a la app.
- **Cámara e IA reales:** todavía no implementadas (fuera de este prototipo).

## Artefacto validado disponible

- **Ruta:** `D:\dev\vigia-entrega\vigia-demo-486bf72-release.apk`
- **SHA-256:** `86821fd612984b01cdaa88754ebe66ab163394dbb1cce3865d9462d03b8ef176` (57 013 754 bytes). Es el APK DEMO de `486bf72`, `com.juanrueda.vigia.demo`.
- **Qué se le probó:** únicamente el recorrido en emulador descrito en «Fase 4». No se le atribuye ninguna otra prueba.
- **Qué significa «APK final de entrega» pendiente.** Era la recompilación prevista antes de la entrega. Ya no se requiere: el código de `lib/` y Android no cambió después de `486bf72`; los commits posteriores son solo documentales. Recompilar solo por ellos produciría otro artefacto sin aportar pruebas. Se recompilará únicamente si cambia el código o el usuario lo pide.
- En la misma carpeta está el APK normal de `486bf72` (`vigia-normal-486bf72-release.apk`, SHA-256 `1254bdd55f6381a6628b6f01fbd94bc79e05005b892dba5fd7757f41e4ab230f`). No se probó en este recorrido.

## Cierre de la fase 5A (aprobada)

- **Dictamen:** Codex aprobó la fase 5A dentro de su alcance, que es el permiso CAMERA y la vista previa de CameraX (Preview) en la variante normal. Commits: `a3839e3`, `4a9b5a9` (corrección de los P2) y `80969c8` (descripción del rechazo permanente como inferencia).
- **Artefacto funcional probado:** el APK normal corregido de `4a9b5a9`, `D:\dev\vigia-entrega\vigia-normal-fase5a-p2-release.apk` (SHA-256 `75a721e368ab52f3c2231c452b3e24ea44044765ae58538f5b868ec4cc750ebc`). El commit `80969c8` solo cambió documentación y comentarios (incluidos los del código Pigeon generado), así que no se recompiló.
- **No implementado todavía:** MediaPipe, detección facial y detección de fatiga, calibración real, sesiones y alertas reales.
- **Pendientes de la fase 5A:**
  - teléfono D1 o cualquier cámara física (rostro real);
  - rotación y espejo con un sensor físico;
  - interruptor de privacidad de cámara de Android 12+;
  - TalkBack;
  - además, siguen cubiertos solo con dobles la cámara ocupada por otra app y la cámara desactivada por política, y el descarte del diálogo solo se comprobó en el emulador.

## Fase 5A · cámara frontal real y permisos (2026-10-12; aprobada, ver «Cierre de la fase 5A»)

Detalle, pruebas y limitaciones: `docs/fase5a-camara-permisos.md`.

- **Implementado:**
  - en la variante normal, Inicio → «Comprobar cámara» → **Cámara frontal**;
  - permiso CAMERA con explicación previa, rechazo, «Abrir ajustes» y nueva consulta al volver;
  - vista previa CameraX (solo Preview) a través de una textura de Flutter;
  - «Cámara disponible» solo cuando CameraX informa OPEN; «Detección de fatiga pendiente»; Calibrar e Iniciar deshabilitados.
- **Puente Pigeon:** 29.0.8, en `packages/monitoring_engine/pigeons/monitoring_api.dart`.
- **Dependencias Android exactas:**
  - CameraX 1.6.2;
  - `kotlinx-coroutines-android` 1.11.0.
- **Ciclo de vida:** un propietario único de la cámara. Se libera al salir, en segundo plano y al desconectarse. Los tokens y generaciones descartan las respuestas tardías.
- **Separación DEMO:** manifiestos superpuestos por variante. El APK DEMO final no contiene ninguna mención de cámara; el normal declara `CAMERA` con la cámara no obligatoria.

**Resultados reales:**

- `dart format`; `flutter analyze` (app y plugin): sin problemas.
- `flutter test`: **pasan 596 pruebas**, entre ellas las 29 nuevas de `test/camera` y los 16 renderizados nuevos de `test/goldens/fase5a`. Se actualizaron 4 renderizados de P03 «motor no comprobado», porque esa pantalla cambió.
- Plugin: `flutter test` pasa 3; `./gradlew :monitoring_engine:testDebugUnitTest` pasa 7, de ellas 6 nuevas en `CameraRulesTest`.
- `python tools/spec_registry.py check`: OK.
- **Detección:** sin la comprobación de respuestas antiguas, fallan 2 pruebas dirigidas.
- **Compilación:** `flutter build apk --debug`, y `--release` de ambas variantes.
- **Emulador** (cámara frontal `none` y, temporalmente, `emulated`, la escena sintética del emulador; no es webcam ni D1):
  - rechazo, rechazo permanente, ajustes sin conceder y concediendo;
  - sin cámara frontal;
  - apertura, salida, reapertura, segundo plano, ráfagas de toques, revocación y concesión por diálogo;
  - tema oscuro;
  - DEMO intacto, con su historial conservado.
  - La configuración de la AVD quedó restaurada (`hw.camera.front=none`).

**APK** (compilados en release desde el mismo código que el commit de la fase 5A; firmados con la clave de depuración):

| Variante | Ruta | Bytes | SHA-256 |
|---|---|---|---|
| Normal `com.juanrueda.vigia` | `D:\dev\vigia-entrega\vigia-normal-fase5a-release.apk` | 57 753 213 | `894c8d955b89405fb178215715eb602f5fe8308f91ac152e17fbf2caa25bf16b` |
| DEMO `com.juanrueda.vigia.demo` | `D:\dev\vigia-entrega\vigia-demo-fase5a-release.apk` | 57 752 965 | `f71659994d8b56020c2526d9b18d9d7866a2003867ea4f7ed876e628135b14a6` |

El APK DEMO validado de la fase 4 (`vigia-demo-486bf72-release.apk`) se conserva sin cambios.

**Capturas:** 12, en `D:\dev\vigia-entrega\capturas\fase5a\`.

**No comprobado:**

- D1 y cualquier cámara física: rostro real, giro y espejo del sensor, rotación con la vista abierta;
- cámara ocupada por otra app y desactivada por política, solo cubiertas con dobles;
- interruptor de privacidad de Android 12+;
- descarte del diálogo en un teléfono físico (comprobado solo en el emulador);
- TalkBack.

### Corrección de los P2 de la revisión de Codex (aprobada)

Detalle en `docs/fase5a-camara-permisos.md`, sección «Corrección de la revisión».

1. **Diálogo descartado sin responder.**
   - Ya no se informa como «Android ya no muestra la solicitud».
   - La app solo infiere un rechazo permanente, y pide abrir los ajustes, cuando `shouldShowRequestPermissionRationale` pasa de «sí» a «no». Es una inferencia de la implementación, no un contrato de la API; se comprobó en el AVD con API 36, donde `dumpsys` mostró `USER_FIXED`. Los casos ambiguos quedan en «sin permiso», con la solicitud y «Abrir ajustes» disponibles.
   - Comprobado en una AVD temporal: tras «Atrás», una nueva pulsación vuelve a abrir el diálogo, y las rutas de rechazo y de ajustes se mantienen.
2. **Excepciones del puente.** Terminan en un fallo recuperable con Reintentar. Las operaciones antiguas no tocan el estado y los cierres no dejan excepciones sin capturar.
3. **Controlador desechado.** Invalida sus operaciones y comprueba `ref.mounted` tras cada salto asíncrono: no abre la cámara ni lanza `UnmountedRefException`.
4. **Código generado.** `tools/generate_pigeon.py` regenera y normaliza el código Pigeon (`--check` compara con lo versionado); `git diff --check` queda limpio.

**Resultados:**

- Regresiones nuevas:
  - JVM: 5 pruebas de permiso; en total pasan 11.
  - Dart: 13 de errores y desecho, más 2 de pantalla.
  - 2 renderizados nuevos y 2 regenerados.
- `test/camera` y los renderizados de la fase 5A y de Inicio: pasan 86.
- Revisión de Codex: pasan 11 de 11.
- **Detección con el código anterior:** fallan 12 de las 13 pruebas Dart nuevas y la prueba JVM del diálogo descartado.
- Por indicación, no se repitió la suite completa.

**APK normal nuevo:** `D:\dev\vigia-entrega\vigia-normal-fase5a-p2-release.apk` (SHA-256 `75a721e368ab52f3c2231c452b3e24ea44044765ae58538f5b868ec4cc750ebc`). El anterior se conserva.

**Entorno.** Gradle exige `TMP`/`TEMP` en `D:\dev\tmp\jtmp`: en `C:` quedan 2 GB y fallaba con «Unable to establish loopback connection».

## Fase 5B · MediaPipe Face Landmarker (2026-10-12; corrección P1 pendiente de revisión)

**Autorización:** del usuario, 2026-10-12. Registrada en `AGENTS.md`. La secuencia VIG sigue aplazada. Detalle, evidencia y limitaciones: `docs/fase5b-mediapipe.md`.

- **Implementado (variante normal, pantalla «Cámara frontal»):**
  - `ImageAnalysis` junto a Preview en la **misma** cámara de 5A;
  - MediaPipe Tasks Vision **1.0.0** en LIVE_STREAM, CPU, hasta **2** rostros, en un hilo propio y con un cuadro cada vez;
  - modelo oficial `face_landmarker.task` float16 (`/1/`) empaquetado, verificado por SHA-256 en cada carga (`64184e22…c9ff`, 3 758 596 bytes, Apache 2.0);
  - estados: cargando modelo, esperando resultados, sin rostro, un rostro, varios, detenido, modelo no disponible y error de análisis;
  - caducidad: Tstale 750 ms en el motor y vigilancia de 3000 ms en Flutter, ambos **experimentales**;
  - identidad por token y generación;
  - «Reintentar carga» y «Reintentar».
- **Privacidad:** a Flutter solo llega un resultado compacto. No se guardan, envían ni registran imágenes o puntos faciales.
- **Hallazgos corregidos:**
  1. MediaPipe 1.0.0 trae telemetría de uso (`datatransport`) que pedía `INTERNET` y `ACCESS_NETWORK_STATE`. Se retiran del manifiesto: el APK normal release solo pide `CAMERA`. La **primera** ejecución de la prueba instrumentada, con un APK de pruebas que aún tenía red, envió esas estadísticas una vez. Es un incidente declarado por el mantenedor: la línea HTTP se vio en logcat pero no se guardó. El contenido no se inspeccionó; que no llevara imágenes es una inferencia a partir de la implementación. Contradice la regla de funcionamiento local sin envíos automáticos (Área 06). Detalle en la guía.
  2. En release, R8 rompía la creación del detector. El plugin aporta ahora `consumer-rules.pro`.
  3. La cola del limitador de MediaPipe hacía que se descartaran resultados por antiguos en el emulador. Ahora va un cuadro cada vez.
- **DEMO:** sin CAMERA, sin modelo y sin la biblioteca nativa de MediaPipe en su APK.

**Resultados reales:**

- `dart format` y `flutter analyze` (app y plugin): sin problemas. `spec_registry.py check`: OK.
- `test/camera` y los renderizados de 5A y 5B: pasan 103.
  - Nuevas: 19 de controlador y 6 de pantalla.
  - 16 renderizados nuevos y 18 regenerados de 5A.
- Plugin: 3 pruebas Dart y 36 JVM (25 nuevas).
- Mutaciones temporales: cada guarda probada hace fallar al menos una prueba, salvo la de generación en los resultados, que tiene doble protección (ver la guía).
- **Modelo real en Android** (AVD API 36, x86_64, `am instrument`): 10/10.
  - Un rostro, dos rostros y sin rostro, con fotos de la NASA de dominio público;
  - sintética gris;
  - giro;
  - modelo ausente, alterado e incompatible;
  - reintento;
  - aperturas repetidas.
- **CameraX → MediaPipe en el emulador** (app release, `-camera-front imagefile:`; no es webcam ni D1):
  - «Rostro detectado» con un retrato encuadrado;
  - «Rostro no detectado» con «The Blue Marble» y con la escena sintética;
  - **dos rostros por la cámara: no demostrado**, porque el emulador recorta;
  - ciclo de vida: segundo plano, vuelta, salida y ráfagas. Nunca más de un análisis vivo; 0 hilos y 0 clientes de cámara tras salir.
- AVD sin cambios: `config.ini` con el mismo SHA-256 antes y después.

**APK** (en `D:\dev\vigia-entrega\`; los anteriores se conservan):

| Variante | Archivo | SHA-256 |
|---|---|---|
| Normal | `vigia-normal-fase5b-release.apk` | `639328dedc4658035781411111b1dc12f88c616ef1a93fe5c4c88376d244b9b0` |
| DEMO | `vigia-demo-fase5b-release.apk` | `e565f16e2fc50f805520e70ff38c1c213656814109254430830396849c16d94a` |

**Capturas y evidencia:** `D:\dev\vigia-entrega\capturas\fase5b\` y `D:\dev\vigia-entrega\evidencia-fase5b\`.

**No comprobado:**

- D1 y cualquier cámara física (rostro real, latencia, giro y espejo de un sensor real, dos rostros por la cámara, luz, gafas);
- webcam;
- edad desde la captura (sin conversión de reloj demostrada);
- almacenamiento local de la telemetría en release;
- ejecución en un entorno de 16 KB;
- TalkBack;
- las bibliotecas Android no figuran todavía en la página de licencias de la app.

### Corrección de los P1 de la revisión de Codex (pendiente de nueva revisión)

**Dictamen sobre `3be9bf1`: desfavorable.** Detalle en `docs/fase5b-mediapipe.md`, sección «Corrección de la revisión de Codex (P1)».

1. **Flutter:**
   - el contrato añade `sequence` y `resultId`;
   - Dart descarta mensajes repetidos o atrasados y generaciones anteriores;
   - tras `stopped`, nada de esa apertura reactiva el análisis;
   - el plazo de 3000 ms solo se renueva con una inferencia nueva (`resultId` distinto), no con un latido;
   - no se comparan relojes de Dart y Android.
2. **Kotlin:**
   - la edad se mide con el reloj del momento de aplicar el resultado (`ahora − entrega del cuadro`);
   - un aviso retrasado de 4000 ms ya no se publica, ni con 0 ni con 1 ni con varios rostros;
   - las marcas imposibles se descartan como inválidas;
   - el silencio cuenta desde la aplicación;
   - Tstale sigue en 750 ms y el límite de Flutter en 3000 ms.

**Resultados reales:**

- `flutter analyze` (app y plugin): sin problemas.
- `test/camera` y los renderizados de 5A y 5B: pasan 113, entre ellas 10 regresiones nuevas.
- Reproducciones de Codex en Dart: 2/2.
- JVM: pasan 43, entre ellas 7 nuevas.
- Detección con el código de `3be9bf1` en una copia temporal: fallan las 3 regresiones Dart que admiten la API anterior y 4 de las 5 de despacho retrasado. La quinta es el control positivo.
- Pigeon regenerado y coherente; `spec_registry.py check`: OK.
- Comprobación dirigida CameraX → MediaPipe en el emulador (imagen fija, no D1):
  - «Rostro detectado» estable al entrar, al volver de segundo plano y tras ráfagas;
  - 0 hilos y 0 clientes de cámara al salir;
  - paquete instalado solo con `CAMERA`;
  - edad máxima aceptada de 654–675 ms, ahora con la espera en cola incluida: el margen hasta Tstale es estrecho en el emulador.
- No se repitieron la suite completa, las matrices, el contraste ni los ensayos del modelo.

**APK nuevo** (los anteriores se conservan; hash añadido a `SHA256SUMS.txt`): `D:\dev\vigia-entrega\vigia-normal-fase5b-p1-release.apk`, 94 270 965 bytes, SHA-256 `e525db8a088035a2e1324e1d307de85f381fb8a49fd952024be194c1abacc51b`. El DEMO no se recompiló, porque no ejecuta este código.

**Pendiente de la revisión, no corregido aquí:** el cierre explícito de los `MPImage` (observación de Codex, sin fuga observada).

### Segunda corrección de P1 (pendiente de nueva revisión)

**Dictamen sobre `c5c0503`: desfavorable** por dos P1 de vigencia. Detalle en `docs/fase5b-mediapipe.md`, «Segunda corrección (P1)» y «Política de caducidad».

1. **Kotlin:**
   - la edad (`ahora − entrega del cuadro`) y el silencio se reevalúan con el reloj actual al crear cada mensaje (cambio, latido, consulta) y al leer el estado;
   - `resultAgeMs` es la edad actual;
   - un latido a 2051 con un resultado de 751 ms ya no anuncia ningún rostro.
2. **Flutter:**
   - un rostro solo se muestra a partir de la consulta nueva `getFaceAnalysis`;
   - edad efectiva = `resultAgeMs` + tiempo completo de la consulta, medido con un cronómetro monotónico de Dart iniciado antes de llamar. Sobreestima; no rejuvenece; no se comparan relojes;
   - se descarta si supera 750 ms; si no, vigencia restante = `750 − edad efectiva`. El mismo `resultId` nunca alarga el plazo;
   - los avisos sin consulta (demora sin cota) nunca muestran un rostro, solo disparan una consulta;
   - Dart consulta cada 200 ms (experimental) y abandona una consulta sin respuesta pasados 750 ms;
   - 3000 ms es solo el límite de silencio del motor.

**Resultados reales:**

- `flutter analyze` (app y plugin): sin problemas.
- Dart: pasan 133 (`test/camera`, renderizados de 5A y 5B, y las 5 reproducciones de Codex de las dos rondas), entre ellas 7 con el puente Pigeon real. Los renderizados no cambiaron.
- JVM: pasan 49. El reproductor Kotlin de Codex termina sin error con el núcleo actual.
- Con `c5c0503` en una copia temporal fallan:
  - las 3 reproducciones Dart de Codex y 4 regresiones Dart expresables con la API anterior;
  - 3 de las 4 regresiones JVM de este P1 (la cuarta es el control positivo).
- Pigeon regenerado y coherente; `spec_registry.py check`: OK.
- No se repitieron la suite completa, las matrices, el contraste ni los ensayos del modelo; tampoco se reabrió `MPImage`.
- **CameraX → MediaPipe en el emulador** (imagen fija, no D1):
  - paquete instalado solo con `CAMERA`;
  - liberación correcta: 0 hilos y 0 clientes de cámara al salir;
  - **detección intermitente**: 18 de 20 muestras «Rostro detectado», 2 «Esperando resultados», con una edad máxima aceptada de 691 ms. Es el comportamiento conservador ante una latencia cercana a Tstale; no se amplió el umbral.

**APK nuevo** (los anteriores se conservan; hash añadido a `SHA256SUMS.txt`): `D:\dev\vigia-entrega\vigia-normal-fase5b-p1b-release.apk`, 94 270 965 bytes, SHA-256 `2f435d49c2e34d94b524671acf222734b745fec6d0548e938cdd68272b7deaf1`. El DEMO no se recompiló.

Se mantienen documentados el incidente inicial de telemetría y las limitaciones físicas: D1, dos rostros por la cámara, 16 KB y TalkBack.

### Tercera corrección: consultas acotadas (pendiente de nueva revisión)

**Dictamen sobre `a935729`: desfavorable** por las consultas. Se aceptó y se conserva la corrección de la edad. Detalle en `docs/fase5b-mediapipe.md`, «Consultas acotadas» y «Tercera corrección».

- **Una sola llamada real pendiente.** La llamada de Pigeon no se puede cancelar. El registro sobrevive a salir, volver y reintentar, así que nada lanza otra llamada mientras haya una pendiente.
- **Plazo propio de 750 ms** desde el inicio de cada consulta. Al vencer:
  - se invalida la respuesta para la interfaz;
  - se retira el rostro;
  - el canal pasa a «sin respuesta», con su causa visible;
  - no se crean llamadas nuevas.
- **Recuperación:** cuando la llamada pendiente termina (respuesta o excepción), se libera sin aplicar su contenido, y la siguiente consulta que responde a tiempo recupera el canal. Si el canal no responde nunca, queda una sola llamada pendiente.
- **Identidad antes de aplicar** cualquier respuesta, incluidos `modelError` y las excepciones.
- **Limpieza:** `stopped`, salir, segundo plano y desechar cancelan todos los temporizadores, también el del rostro mostrado.

**Resultados reales:**

- `flutter analyze`: sin problemas.
- Dart: pasan 145, entre ellas 13 regresiones nuevas. El canal sin respuesta deja 1 llamada pendiente a 120 s y a 240 s, contando llamadas reales.
- Con `a935729` fallan 9 de las 13 regresiones nuevas.
- El reproductor de Codex pasa 6 de 9 casos. Las 3 aserciones que fallan suponen la política anterior (una segunda llamada a 750–800 ms); se sustituyen por la nueva.
- Sin cambios en Kotlin ni Pigeon: no se ejecutó la JVM ni se recompiló Android.

**APK:** los existentes, incluido `vigia-normal-fase5b-p1b-release.apk`, son **anteriores a esta corrección**.

### Cuarta corrección: registro por canal y plazo al recibir (pendiente de nueva revisión)

**Dictamen sobre `8f715dd`: desfavorable.** Detalle en `docs/fase5b-mediapipe.md`, «Consultas acotadas» y «Cuarta corrección».

- **Registro por canal.** La llamada pendiente la registra el coordinador compartido `FaceQueryChannel`, indexado por la identidad del canal (`FrontCameraBridge.queryChannel`), no el controlador. Sobrevive a desechar el controlador y crear otro, y lo comparten wrappers Pigeon distintos sobre el mismo canal. No guarda `Ref` ni estado de pantalla, y solo lo libera la terminación real de la llamada.
- **Bloqueo visible.** Con el canal sin respuesta se ve la causa aunque antes llegara «cargando»; los latidos y estados antiguos no lo ocultan.
- **Plazo al recibir.** Se descarta toda respuesta o excepción que terminó en 750 ms o más según el tiempo monotónico, aunque el temporizador no se haya ejecutado.

**Resultados reales:**

- `flutter analyze` (app y plugin): sin problemas.
- Pasan 170 pruebas Dart, entre ellas 12 regresiones nuevas, los reproductores de Codex y sus 9 comprobaciones adaptadas.
- Con `8f715dd` fallan las 7 regresiones de los defectos.
- Kotlin y Pigeon sin cambios: no se ejecutó la JVM ni se compiló Android.

**APK:** todos los existentes son **anteriores** a las correcciones tercera y cuarta.

## Siguiente acción

Nueva revisión de Codex de la fase 5B, con la cuarta corrección. No se avanza a calibración, sesiones ni fatiga. No se avanza a reglas ni alertas de fatiga, calibración ni sesiones sin una nueva autorización expresa. La secuencia VIG del Área 08 sigue aplazada.
