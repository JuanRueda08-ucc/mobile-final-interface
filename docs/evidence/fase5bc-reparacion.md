# Reparación del bloque integrado 5B + 5C

Codex, 2026-10-13. Autorización expresa del usuario para reproducir y reparar,
con Claude detenido. Esta validación de cambios propios **no es una revisión
independiente** ni acredita uso al conducir.

## Base y alcance

Git inicial limpio, rama `main`, HEAD
`75b727365e27e379b204d4bff177269cb4fea1f8`; incluye, por parentesco,
`9a95ccea007e92f65c2f32943c0c099283a48da1` y
`b08cfec5b8fea7788c547208bbcc0794aa48786f`.
No había cambios ajenos al comenzar. El apagado del equipo no perdió las
reparaciones ni los registros de pruebas. No se hizo amend, push ni PR.

Se conservan las aceptaciones previas no afectadas: edad y consultas de 5B,
modelo, licencias y restricciones de red de los artefactos inspeccionados.
No se reabre MPImage sin evidencia nueva, ni se repiten los ensayos del modelo,
la suite completa, matrices, contraste o goldens. La excepción de reparación
queda registrada en AGENTS.md y CLAUDE.md.

## Defectos reproducidos y reparaciones

| Defecto anterior | Reparación y regresión |
|---|---|
| 5C aceptaba ojos y señales de una respuesta retenida 5000 ms; un aviso podía publicar directamente un cierre | Avisos disparan consultas, sin publicar mediciones. Plazo propio de 750 ms; al aplicar se resta la duración completa del viaje a los presupuestos nativos. Pruebas de 749/750/800 ms y despacho adicional de 40 ms |
| La señal presentada seguía vigente hasta la vigilancia de conexión de 3000 ms | Presupuestos separados: ojos según Tstale y señal según Gmax. Identidad de observación distinta de sequence; el mismo ID no amplía ni revive. Una observación nueva recupera |
| Un temporizador retrasado dejaba leer cierre prolongado a 151 ms | Getters comprueban también el reloj local actual; regresión con `elapseBlocking`, antes del timer, a 151 y 751 ms |
| Una instancia antigua podía reemplazar la instancia vigente | Registro de instancias retiradas y comprobación de identidad antes de aplicar; avisos antiguos no resucitan |
| Las órdenes sin respuesta bloqueaban la UI indefinidamente; recrear consumidores duplicaba llamadas | Plazo de 750 ms para la espera de UI; registro compartido por canal efectivo y operación. Solo la terminación real libera cada RPC. Desvinculación de consumidores al salir/desechar; respuesta tardía no se aplica. Inicio todavía pendiente impide salir a una pantalla incoherente |
| Reentrar o volver del segundo plano abría cámara en una sesión pausada; se podía salir con inicio pendiente | Entrada consulta primero el estado nativo; la cámara sigue el estado verificado. Pausa permanece sin cámara; segundo plano cancela consultas y temporizadores. Dos regresiones de pantalla |
| Los callbacks de puentes con sufijo se registraban en el canal predeterminado | Mensajero y sufijo efectivos también en el registro de callbacks de 5B y 5C; dos pruebas del puente generado |
| El coordinador/política ocular usaba recepción para validar frames antiguos y dependía del tick | Validación de timestamps y edad actual al observar, publicar, consultar e iniciar. Snapshot ejecuta vigilancia; una recepción tardía no borra un silencio vencido antes de evaluarlo |
| Pausa/reanudación reiniciaba activaciones de la sesión y Rrepeat | Se corta el segmento sobre la misma política; se mantienen contadores y límite de repetición de sesión |
| Salida/cancelación y fallos del tono podían dejar recursos de audio vivos | Liberación al cancelar/desvincular. Si startTone devuelve false o lanza, libera; si stopTone lanza, finally libera. Volumen cero libera el tono previo. Cuatro regresiones con handle inyectado, sin mock Android |
| Un error conocido de inferencia no retiraba inmediatamente la observación ocular | Observación inválida compacta `inferenceError`; callback de apertura antigua sigue ignorado. Regresión en FaceAnalysisCore |
| Durante la validación, la primera reparación bloqueaba Volver aun tras confirmar y finalizar una sesión cuya respuesta de inicio se perdió | El resumen de una sesión confirmada/finalizada permite salir. Sigue bloqueada la salida con inicio incierto después de 750 ms; la llamada subyacente permanece registrada hasta terminar |

Los plazos experimentales no se ampliaron: Tstale=750 ms, Gmax=150 ms,
Krecover=1000 ms/6 muestras, Tclose=1500 ms y Rrepeat=5000 ms. Los 3000 ms
vigilan la conexión del motor; no extienden ojos ni señales.

Kotlin entrega presupuestos restantes redondeados hacia abajo; Dart resta
su cronómetro de la RPC, todavía en marcha al aplicar. No compara relojes
Android/Dart. `observationId` crece por observación aceptada de la apertura
vinculada dentro de la instancia; `sequence` crece por snapshot. Un motor nuevo
reinicia su identidad, y el consumidor retira la anterior.

## Evidencia y reproducción

Registros locales en `build/repair-5bc/` (ignorados por Git, conservados):

- `native-before.log`: fallan los seis casos nuevos de vigencia, lectura,
  callback, contadores y parada de audio; pasan los 24 originales.
- `dart-before.log`, `command-before.log`: fallos de transporte/identidad y
  órdenes. `read-before-timer-before.log`: cierre todavía vigente a 151 ms.
- `lifecycle-before-corrected-harness.log`: fallan ambos casos de recorrido
  contra el código de aplicación base copiado a un árbol temporal.
- `suffix-before-fixed-harness.log`, `face-suffix-before.log`: callback perdido.
- `audio-before-portable.log`: cuatro fallos reales de liberación del handle.
- `inference-error-before.log`: no llega la invalidación esperada.
- `summary-exit-before.log`: regresión reproducida contra la reparación
  `5d82d7e`, antes del ajuste final del resumen; no se atribuye al código base.

La copia base de aplicación usa el contrato ampliado y fixtures compatibles
para aislar el comportamiento viejo de controlador/pantalla. Los intentos
iniciales con transiciones de lifecycle inválidas, cancelación de stream
bloqueada por FakeAsync o mock Android incompatible con JDK no se cuentan como
fallos del producto: se corrigió el arnés y se repitió la reproducción.

Las dos fixtures de cierre de pruebas previas ahora contienen ojos válidos y
medición utilizable; las emisiones que representan una inferencia nueva llevan
sequence/observationId nuevos. Se conserva la cobertura de identidad, rechazo,
caducidad, acción y recuperación, incluida la política acotada de 5B.

## Validación de código

- `flutter analyze --no-pub`: app y plugin sin incidencias.
- Dart dirigido: **136/136**, `dart-final.log`. Incluye `test/experimental`,
  controlador/pantalla/puente de presencia facial y reproductores anteriores
  de edad, transporte, canal efectivo, plazo, estado bloqueado y lifecycle.
- Ajuste final del resumen: **28/28** de `test/experimental` y análisis de app
  sin incidencias (`dart-summary-final.log`, `analyze-summary-final.log`);
  control reforzado de inicio todavía incierto: **3/3**, `lifecycle-final.log`.
  Son **137 casos Dart distintos**, con repetición dirigida al último cambio.
- JVM dirigida: **73/73**, `native-final.log`: ExperimentalMonitoringTest,
  ToneAlertSinkTest, FaceAnalysisCoreTest, FaceAnalysisDelayTest y
  FacePublishAgeTest. No se ejecutó toda la suite JVM.
- Pigeon 29.0.8 regenerado en copia temporal: ambos archivos idénticos byte
  por byte (`pigeon-final.log`, script `check-pigeon.ps1`).
- `python -I tools/spec_registry.py check`: 500 comprobaciones, OK.
- `git diff --check`: sin errores de espacios.

Los comandos Flutter usaron CI y supresión de analytics; Gradle usó `--offline`.
No se habilitó red ni permisos para provocar telemetría.

## Límites y aceptaciones conservadas

El incidente de telemetría anterior fue observado por el mantenedor sin
registro original conservado: no se inspeccionó el cuerpo de esa solicitud.
Ausencia de envíos no prueba ausencia de almacenamiento. No se atribuye a debug
o instrumentación una restricción de red comprobada únicamente en release.

El margen de 654–675 ms y el muestreo 18/20 con rostro, 2/20 esperando,
pertenecen a mediciones anteriores del emulador. No son rendimiento físico;
la carga del muestreo sigue siendo una posible causa, no demostrada. D1 sigue
sin medir. Ni ABI/alineación ni un emulador acreditan ejecución física con
páginas de 16 KB.

No se añaden W/Eend, persistencia, servicio, exportación ni reglas de producción.
La cámara de imagen fija no acredita sensor físico, ojos cerrados, calibración
aceptada ni una sesión real con cierre/tono. Las secuencias controladas verifican
la lógica, no la eficacia de la medición ni la seguridad del conductor.

## Commits y Android

- Autorización: `1210ca0ea927f56efd56e5a3bd79657cd2370b37`.
- Reparación de código y regresiones: `5d82d7ebd0fbac7fd4701398cc608fdc96829315`.
- Ajuste del resumen y control de inicio incierto:
  `ad7e91c3586a342c247584aa3f1ae7b8563344a9`.
- Android se recompila por los cambios Kotlin/Pigeon y se verifica por separado
  del APK anterior `b205b972bc5dc58c925f2e2381cc3903e2d8edc3578131ca6e5395e18f0567ad`.

### Primera ejecución release de las reparaciones

Artefacto de `5d82d7e`:
`build/repair-5bc/vigia-normal-fase5bc-repair-release.apk`, 94 615 029 bytes,
SHA-256 `ad59294cc34ae7fcac11d248b012a8552aeb0195dc98d351cc72962ebff2ec33`.
Esta ejecución **precede exclusivamente el ajuste final de Volver**; no acredita
ese cambio. Identidad `com.juanrueda.vigia`, 0.1.0+1, minSdk26/target36, ABI
arm64-v8a/armeabi-v7a/x86_64, modelo y bibliotecas MediaPipe presentes.
Firma v2 válida, certificado debug SHA-256
`dd6dbeb4d913a16de01e08990d232b5b8d1bd988f0d4613a86d42f124f27dead`.
Permisos: CAMERA y permiso interno de receptor; sin INTERNET ni
ACCESS_NETWORK_STATE (`apk-badging.log`, `apk-permissions.log`, `apk-signature.log`).

AVD API36/x86_64 `vigia_pixel`, con capa `-read-only`, sin cargar
ni guardar snapshots, sin ventana ni webcam. Imagen fija previamente documentada
en 5B: `D:/dev/vigia-entrega/evidencia-fase5b/fuentes-camara/lienzo_un_rostro_recorte.png`.
Wi-Fi/datos desactivados en la capa temporal antes de abrir Vigía; instalación
`adb install -r`, sin borrar datos. La capa se descarta al terminar el emulador.

- CameraX → MediaPipe real, rostro y ojos medibles, EAR 0,28/0,26.
  Tono: «Reproducción técnica correcta», sin afirmar audibilidad humana.
- Al inicio aparecieron ANR de Digital Wellbeing/System UI y resultados
  caducados. También se capturó después el estado con medición vigente; no se
  conservó una detección vieja para estabilizar la pantalla.
- Un contraste breve con el APK original en el mismo AVD mostró también
  0,28/0,26 (`baseline-ojos.xml/png`). No es un ensayo comparativo de rendimiento
  ni prueba de causalidad de los ANR, la carga o el muestreo.
- Calibración: rechazada por `insufficientObservations` con
  `open(samples=25, coverage=0.016)` y `open(samples=30, coverage=0.050)`.
  No se consiguió repetir la referencia abierta aceptada de la entrega original.
  Se mantiene el rechazo y sus umbrales. Iniciar permanece bloqueado.
- El intento automático de cancelar llegó cuando la calibración ya estaba
  rechazada: **no cuenta como una cancelación Android validada**. La cancelación
  y liberación de audio están cubiertas por regresiones nativas/Dart.
- Segundo plano, reentrada y salida: aperturas nuevas y cierre con cero
  analizadores; dumpsys tras asentarse confirma `Active Camera Clients: []`.
  La captura inmediata antes de completar la liberación aún tenía cliente;
  no se presenta como cierre instantáneo.
- Registros de las aperturas corregidas: 521/534 y 44/45 resultados aceptados
  (edad máxima aceptada 738 y 529 ms); segunda instalación, 590/592 y 48/50
  (719 y 627 ms). Son contadores del emulador, no latencia desde sensor físico
  ni un margen garantizado. No se detectó FATAL del proceso Vigía.
- Se conservaron fallos de programación de telemetría por ausencia de
  ACCESS_NETWORK_STATE en `android-app.log`; no acreditan envío ni describen
  el cuerpo del incidente histórico. No se inspeccionó almacenamiento interno
  en esta reparación ni se afirma que esté vacío.

Capturas, XML, logcat y dumpsys en `build/repair-5bc/`; emuladores de esta ejecución
cerrados al terminar. La sesión experimental real completa sigue sin demostrarse
en Android. El tono por cierre sostenido y la sesión finalizada se verifican con
secuencias controladas; una imagen que no cierra los ojos no acredita esas rutas.

### APK final del código reparado

Código: `ad7e91c3586a342c247584aa3f1ae7b8563344a9`, incluye `5d82d7e`.
Archivo: `build/repair-5bc/vigia-normal-fase5bc-repair-final-release.apk`.
Bytes: **94 615 029**. SHA-256:
`bce4203d057f23652a7fa1641886d4b3cdc1374581e6b604d1cc31f789b1355f`.
Identidad normal 0.1.0+1, minSdk26/target36, tres ABI y certificado debug
anteriores; firma v2 verificada. Sin INTERNET ni ACCESS_NETWORK_STATE.
Registros: `build-release-final.log`, `apk-final-badging.log`,
`apk-final-permissions.log`, `apk-final-signature.log`, `install-final.log`.

Frente al primer APK reparado solo difieren los tres `libapp.so` de Flutter;
todos los demás ZIP entries son idénticos (`apk-final-delta.log`). No se cambió
Kotlin/Pigeon por el último ajuste de pantalla, ni se repitió la JVM.

Segunda capa temporal del AVD, Wi-Fi/datos desactivados antes de abrir la app.
Instalación y arranque correctos, tras apartar un nuevo ANR de System UI.
`final-medicion.xml/png`: rostro, ojos medibles y EAR 0,28/0,26 en el **APK final**.
Salida: `final-camera-closed.txt` confirma cero clientes; `final-app-closed.log`
confirma cero analizadores, 412/413 resultados aceptados y edad máxima aceptada
390 ms. Sin FATAL de Vigía; se cerró el emulador creado para la prueba.
No se repitió calibración ni sonido en este segundo arranque. La ruta de resumen
con una respuesta perdida se acredita por Flutter, no por una sesión Android real.

## Comandos dirigidos para reproducir

Desde la raíz, con el SDK instalado en `D:/dev/flutter`, CI y supresión de
analytics en el entorno del comando:

```powershell
$env:CI='true'; $env:FLUTTER_SUPPRESS_ANALYTICS='true'
$dart='D:/dev/flutter/bin/cache/dart-sdk/bin/dart.exe'
$flutterTool='D:/dev/flutter/bin/cache/flutter_tools.snapshot'
& $dart $flutterTool analyze --no-pub
& $dart $flutterTool test --no-pub --reporter expanded test/experimental
& ./build/repair-5bc/check-pigeon.ps1
python -I tools/spec_registry.py check
```

Controles de 5B usados además: controlador, pantalla y puente facial de
`test/camera/face_analysis_*_test.dart`; `review_stale_test.dart`,
`review_transport_delay_test.dart`, `review_scope_test.dart`,
`review_stalled_screen_test.dart`, `review_query_lifecycle_adapted_test.dart`,
`review_effective_channel_test.dart`, `review_delivery_age_test.dart` de las
carpetas anteriores de revisión en build. Su ejecución conjunta está registrada
en `dart-final.log`; no se reejecutan por el ajuste limitado a Volver del resumen.

Desde `android`, JAVA_HOME JDK21, GRADLE_USER_HOME `D:/dev/gradle-home` y
TMP/TEMP/java unixdomain.tmpdir en `build/repair-5bc/jtmp`:

```powershell
.\gradlew.bat --offline :monitoring_engine:testDebugUnitTest --tests '*ExperimentalMonitoringTest' --tests '*ToneAlertSinkTest' --tests '*FaceAnalysisCoreTest' --tests '*FaceAnalysisDelayTest' --tests '*FacePublishAgeTest' --console=plain
.\gradlew.bat --offline :app:assembleRelease '-Ptarget-platform=android-arm,android-arm64,android-x64' '-Ptarget=lib/main.dart' '-Pbase-application-name=android.app.Application' '-Pdart-obfuscation=false' '-Ptrack-widget-creation=false' '-Ptree-shake-icons=true' --console=plain
```

Git final del código: rama `main`, commits locales de autorización y corrección,
con documentación de continuidad añadida en un commit posterior. Sin amend,
push, PR ni avance a otro bloque. El hash del commit documental final se informa
con la entrega; los APK corresponden a los commits de código indicados arriba.
