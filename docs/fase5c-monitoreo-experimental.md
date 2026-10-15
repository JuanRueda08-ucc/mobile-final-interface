# Fase 5C · Monitoreo experimental (recorrido real)

**Autorización:** del usuario, 2026-10-13, como bloque funcional integrado junto con la quinta corrección de 5B. Pendiente de una única revisión de Codex. Variante normal (`com.juanrueda.vigia`); el DEMO no cambia.

## Alcance

Recorrido visible, en Inicio → **«Monitoreo experimental»**:

1. Cámara frontal (la misma de 5A/5B: CameraX Preview + ImageAnalysis, sin otra cámara).
2. Un rostro (MediaPipe Face Landmarker de 5B).
3. Mediciones oculares en Kotlin: EAR de cada ojo y Q geométrica.
4. Calibración Kcal con muestras reales.
5. Prueba de sonido técnica + «Lo escuché».
6. Iniciar → cierre ocular sostenido (Tclose) → aviso visual y tono local → Pausar/Reanudar → Finalizar.

**No incluye:** advertencia por acumulación (W), episodios/Eend, persistencia, historial, exportación, backend, servicio en primer plano ni funciones ajenas al recorrido. No se reutiliza el guion DEMO. No es detección de fatiga ni una ayuda para conducir, y así se rotula en la pantalla.

## Arquitectura

| Pieza | Archivo | Qué hace |
|---|---|---|
| Adaptador MediaPipe | `face/MediaPipeFaceEngine.kt` | Con exactamente un rostro copia sus puntos a un `FloatArray` que no sale de Kotlin |
| Núcleo de análisis | `face/FaceAnalysisCore.kt` | Al aplicar un resultado (vigencia Tstale de 5B) crea una `EyeObservation`; los descartados por antiguos o con marca imposible se entregan como inválidos |
| Geometría y Q | `monitoring/EyeGeometry.kt` | EAR en píxeles (`mp-eye6-v1`), Q geométrica |
| Kcal | `monitoring/Calibration.kt` | Calibración guiada por tiempo monotónico |
| Política | `monitoring/SessionPolicy.kt` | Krecover, C, Tclose, Rrepeat, vigilancia de recepción |
| Coordinador | `monitoring/MonitoringCoordinator.kt` | Una sola sesión; órdenes con precondiciones comprobadas en Kotlin; tono; resumen en memoria |
| Android | `monitoring/ExperimentalMonitoringHost.kt` | `ToneGenerator` (flujo de alarma), vigilante cada 50 ms, host Pigeon y registro técnico |
| Contrato | `pigeons/monitoring_api.dart` | `ExperimentalMonitoringHostApi`, `ExperimentalMonitoringFlutterApi`, `MonitoringSnapshot` |
| Flutter | `lib/features/experimental/` | Controlador (orden, conexión 3000 ms, una orden a la vez) y pantalla; **no decide señales** |

Rutas Kotlin relativas a `packages/monitoring_engine/android/src/main/kotlin/com/juanrueda/monitoring_engine/`.

- **Decisión nativa con tiempo monotónico.** Las observaciones usan la entrega del cuadro al analizador (`elapsedRealtimeNanos`), y el coordinador decide y reproduce el tono sin pasar por Flutter.
- **Privacidad.** A Flutter solo llegan EAR, ratios, códigos y contadores. No se envían, guardan ni registran imágenes ni puntos faciales. El registro técnico (`VigiaMonitoring`) solo contiene fases, códigos y contadores.
- **Red.** Sin cambios: el APK normal solo pide `CAMERA` (comprobado con `dumpsys package`).

## Parámetros (perfil `lab-eye-rules-0.1`, `qualificationStatus=experimental`)

Valores **candidatos** del Área 05 §7, en `monitoring/ExperimentalProfile.kt`. No son una política de producción ni valores fisiológicos validados.

| Grupo | Valores usados |
|---|---|
| Q | minEyeWidthPx 24, maxWidthRatio 1,8 |
| Kcal | 8000 ms abiertos, ≥60 muestras, cobertura ≥0,80, openEAR p80 en [0,10; 0,60], relativeMAD ≤0,15; 2 cierres de 1000 ms con ≥6 muestras, cobertura ≥0,80 y mediana de ratio ≤0,50; reapertura 2000 ms con ratios ≥0,75 |
| C / reapertura | thetaClosed 0,55 (igualdad cumple), thetaOpen 0,75 |
| Tiempo | Tclose 1500 ms, Gmax 150 ms, Tstale 750 ms |
| Krecover | ≥1000 ms y ≥6 muestras válidas, gaps ≤ Gmax |
| Rrepeat (cierre) | 5000 ms |

**Pendientes / no implementados (declarados):**

- **Q incompleta:** luz, nitidez (ROI 96×48) y postura (matriz facial) **no se implementan**. Una observación que pasa la Q actual no prueba que los ojos sean visibles (gafas oscuras, reflejos).
- **Parámetros de prototipo, ausentes del Área 05:** aviso previo al cierre de 1500 ms (`PROBE_LEAD_IN_MS`), espera máxima de la reapertura de 6000 ms (`REOPEN_TIMEOUT_MS`), pitido de guía al pedir la reapertura (la persona tiene los ojos cerrados), vigilante cada 50 ms y publicación del estado ocular como mucho cada 200 ms.
- **Reloj de captura:** no se ha demostrado la conversión captura→monotónico. Se usa la entrega al analizador (`submitAt` en términos del Área 04 §5), no `captureAt`.
- **Medición:** noFace, ambiguousFace y staleResult → `unavailable`; fallos oculares, gaps y retraso → `limited`.
- **Pausa:** libera la cámara; reanudar deja la pausa abierta hasta Krecover.
- **Segundo plano:** sin servicio en primer plano, la cámara se libera y la sesión queda no evaluable hasta volver.
- **Sin W, episodios ni Eend.** El resumen cuenta activaciones de H y tonos (iniciados/fallidos); no se guarda.
- **Audio:** `ToneGenerator` en `STREAM_ALARM`; un volumen de alarma en cero se informa como fallo. La reproducción técnica no acredita que se oiga.
- **Sin manifiestos** de modelo y política (Área 05 §3).

## Pruebas

### Lógica con secuencias controladas (sin imágenes reales)

`packages/monitoring_engine/android/src/test/kotlin/.../ExperimentalMonitoringTest.kt`, **24 pruebas JVM**:

- EAR con los ejemplos del Área 05 (0,30 y 0,05) y cálculo en píxeles frente a coordenadas normalizadas;
- Q: geometría ausente o no finita, fuera de imagen, resolución (24 inclusivo), asimetría;
- conteo de rostros;
- Kcal:
  - aceptación cooperativa;
  - gaps de 200 ms (sin cobertura);
  - sin rostro y varios rostros;
  - fallo ocular → `invalidEyeQuality`;
  - datos caducados o ausentes;
  - fuera de rango, dispersión, sin cierre y sin reapertura → `unstableReference`;
  - fórmulas p80 y relativeMAD;
- política de sesión:
  - Krecover (5 muestras/900 ms no; 6/1000 sí);
  - Tclose 1400 ms no y 1500 ms sí;
  - igualdad con thetaClosed;
  - guiño unilateral;
  - la pérdida del rostro corta y exige Krecover;
  - gap > Gmax;
  - silencio de 150 ms (no corta), 151 ms (`limited`) y ≥750 ms (`unavailable`);
  - observación caducada;
  - Rrepeat a 2600/7600/12600 ms;
- coordinador:
  - recorrido completo con tono y liberación al finalizar;
  - una sola sesión y precondiciones de inicio en Kotlin (sin calibración, sin «Lo escuché», sin rostro, observación antigua);
  - la pausa corta, no evalúa y no suena; reanudar espera Krecover;
  - la pérdida de rostro y otra apertura nunca cuentan como cierre;
  - cámara cerrada durante la calibración → rechazo; cancelar nunca acepta;
  - el tono fallido se cuenta.

Flutter (`test/experimental/experimental_monitoring_test.dart`, 9):

- orden de estados;
- 3000 ms sin mensajes → sin señal;
- una orden por ráfaga y rechazo visible;
- inicio con los IDs del motor;
- pantalla: rotulado, botones bloqueados, EAR, pasos y rechazo de la calibración, inicio, cierre prolongado, salida bloqueada con sesión, pausa (cierra la cámara) y finalizar (resumen);
- ruta solo en la variante normal.

Renderizados: `test/goldens/fase5c/`, 11 estados × claro/oscuro (22). Se regeneraron los 4 de P03 «motor no comprobado», que ahora muestran la entrada «Monitoreo experimental».

### Detección con imágenes reales (MediaPipe real, sin cámara)

`EyeMeasurementInstrumentedTest`, 4 pruebas, en el AVD por `am instrument`, con el retrato de la NASA de 5B (dominio público, **ojos abiertos**):

| Caso | Resultado real |
|---|---|
| Miniatura de 500 px | Q rechaza por `insufficientEyeResolution` (anchos 18,4/18,8 px); EAR 0,307/0,302 |
| Retrato ampliado ×2 (bilineal) | Q válida; EAR der. 0,316, izq. 0,311; anchos 36,7/37,7 px |
| El mismo, girado 90° con `rotationDegrees=90` | EAR 0,310/0,308 (≈ derecho) |
| Dos rostros / sin rostro | `ambiguousFace` / `noFace` |

**Hallazgo corregido con esta prueba:** al principio la escala en píxeles intercambiaba ancho y alto según el giro y la imagen girada daba EAR 0,22. Las coordenadas de MediaPipe se normalizan al cuadro entregado; ahora se usa su tamaño sin intercambio.

No hay fotos reales con ojos cerrados: **la medición de ojos cerrados con imágenes reales no está acreditada.**

## Recorrido en Android (emulador, 2026-10-13)

- **Entorno:**
  - AVD `vigia_pixel` (API 36, x86_64), `-camera-front imagefile:` con `lienzo_un_rostro_recorte.png` de 5B (imagen fija, ojos abiertos; no es webcam ni D1);
  - APK `D:\dev\vigia-entrega\vigia-normal-fase5c-release.apk` instalado con `adb install -r`;
  - interacción por toques `adb` y volcados de `uiautomator`.
- **Evidencia:** `D:\dev\vigia-entrega\evidencia-fase5c\`. Las capturas `previo-escala_*` son anteriores a la corrección de escala y no valen como resultado.

| Paso | Resultado real |
|---|---|
| Inicio → Monitoreo experimental | Cámara disponible, «Rostro detectado», ojos medibles, EAR der. 0,28 · izq. 0,26 |
| Calibrar | Referencia abierta aceptada (≈17 observaciones válidas por segundo: 53 en 3 s). Comprobación de cierre 1: ratio 1,000/1,000 → **rechazada** `unstableReference` (`probe1NotClosed`). Correcto: la imagen no cierra los ojos |
| Prueba de sonido | `ToneGenerator` iniciado (AudioTrack entregó cuadros); «Reproducción técnica correcta». «Lo escuché» tocado como paso del flujo, **no como confirmación de audibilidad** |
| Iniciar | Deshabilitado: «Para iniciar falta: calibración» |
| Cancelar calibración | `CANCELED`; sigue cancelada 12 s después |
| Volver a Inicio | CameraX `DISCONNECT`, 0 hilos de análisis, coordinador sin cámara |
| Segundo plano y vuelta | Cámara liberada y reabierta (apertura nueva), ojos medibles de nuevo |
| logcat | Sin `FATAL`; edad máxima aceptada 286 ms; cuadro 640×480, giro 90 |

**No demostrado en Android:** ojos cerrados, calibración aceptada, inicio de sesión, cierre prolongado con aviso y tono, pausa/reanudación y finalización con sesión. La fuente disponible (imagen fija con ojos abiertos) no permite cerrar los ojos, y no se sustituyó por una simulación. Esas rutas solo están cubiertas por las secuencias controladas JVM y las pruebas Flutter con dobles. No se usó la webcam: captaría a quien esté delante del equipo.

## Recorrido reproducible

**En un teléfono con cámara frontal (o en el emulador con `-camera-front webcam0`, si quien esté delante acepta usar su cara):**

1. Instalar: `adb install -r "D:\dev\vigia-entrega\vigia-normal-fase5c-release.apk"`.
2. Inicio → «Monitoreo experimental». Conceder la cámara si se pide (o antes, desde «Comprobar cámara»).
3. Con buena luz y el rostro a unos 40–60 cm, esperar «Ojos medibles: Sí». Si dice que los ojos son pequeños, acercar el teléfono.
4. «Calibrar»:
   - mirar al frente 8 s;
   - al leer «Cierra los ojos», cerrarlos hasta oír el pitido;
   - abrirlos y mirar al frente;
   - se repite una segunda vez.
   - Resultado esperado: «Referencia aceptada».
5. «Probar tono» → «Lo escuché» (solo si se oyó).
6. «Iniciar monitoreo experimental». Esperar «Sin señales persistentes» (≥1 s de observaciones válidas).
7. Cerrar los ojos ≥1,5 s: tono y «Cierre ocular prolongado»; abrirlos: vuelve «Sin señales persistentes».
8. Tapar la cámara o salir del encuadre: «No evaluable» y ningún tono.
9. «Pausar»: la cámara se cierra. «Reanudar»: «Reanudando…» hasta reunir observaciones válidas.
10. «Finalizar» → confirmar: resumen en memoria (no se guarda) y cámara cerrada.

Registro técnico: `adb logcat -s VigiaMonitoring`.

**Comandos:**

```bash
cd android && ./gradlew :monitoring_engine:testDebugUnitTest
flutter test test/experimental test/goldens/fase5c_render_test.dart
cd android && ./gradlew :monitoring_engine:assembleDebugAndroidTest
adb install -r -t build/monitoring_engine/outputs/apk/androidTest/debug/monitoring_engine-debug-androidTest.apk
adb shell am instrument -w com.juanrueda.monitoring_engine.test/androidx.test.runner.AndroidJUnitRunner
```

En Windows, Gradle necesita `TMP`/`TEMP` en `D:\dev\tmp\jtmp`, y en Git Bash `MSYS_NO_PATHCONV=1` para las rutas `/sdcard`.

## APK

| Variante | Archivo | Bytes | SHA-256 |
|---|---|---|---|
| Normal | `D:\dev\vigia-entrega\vigia-normal-fase5c-release.apk` | 94 516 725 | `b205b972bc5dc58c925f2e2381cc3903e2d8edc3578131ca6e5395e18f0567ad` |

Compilado en release desde el árbol de trabajo con el código de este bloque y firmado con la clave de depuración. El DEMO se recompiló solo para comprobarlo (`com.juanrueda.vigia.demo`, sin `CAMERA` ni archivos de MediaPipe) y no se archivó: su código no cambió.

## Reparación autorizada y validación propia (2026-10-13)

El APK y los resultados de las secciones anteriores pertenecen a la entrega
original del mantenedor. Las 741 pruebas, renderizados y 14 ensayos con MediaPipe
no se repitieron. Codex reprodujo y corrigió los defectos del bloque integrado
desde `75b7273`; código reparado en
`5d82d7ebd0fbac7fd4701398cc608fdc96829315`.

- Ojos: se comprueban timestamp, edad del frame y silencio al observar, leer,
  publicar y consultar, incluyendo el inicio de sesión.
- Puente: `sequence` ordena snapshots; `observationId` identifica una observación
  nueva dentro de la instancia. Kotlin entrega presupuestos restantes para ojos
  y señal; Dart descuenta la consulta completa, incluido el despacho. No mezcla
  relojes de distinto origen ni renueva un ID retirado.
- Avisos espontáneos solicitan un snapshot; no publican ojos ni señales.
  Poll de 100 ms y plazo independiente de 750 ms. Una llamada real pendiente
  por operación/canal efectivo: el timeout no la libera. Los consumidores y
  todos sus temporizadores se cancelan al salir o desecharse. Las órdenes tienen
  el mismo plazo de espera de UI; un inicio aún pendiente impide abandonar un
  estado cuyo resultado se desconoce.
- Los getters comprueban también la edad actual cuando el timer se retrasa.
  Tstale=750 ms y Gmax=150 ms permanecen iguales. Los 3000 ms solo vigilan
  conexión, sin mantener una señal vieja.
- Entrada y vuelta del segundo plano consultan el estado antes de abrir cámara;
  una pausa permanece sin cámara. Error de inferencia retira inmediatamente la
  observación. Reanudar conserva contadores y Rrepeat de la sesión.
- Audio: cancelación/desvinculación detienen el tono; inicio fallido y excepción
  en parada liberan el generador. No se acredita audibilidad con una prueba técnica.

Análisis app/plugin sin incidencias; Dart dirigido 136/136; JVM seleccionada
73/73; Pigeon regenerado en copia temporal, idéntico; registro de especificaciones
500 comprobaciones, OK. No se modificaron goldens, umbrales ni fuentes originales.
Detalle de cada fallo, regresión, comandos y límites:
`docs/evidence/fase5bc-reparacion.md`; logs en `build/repair-5bc/`.
Esta validación propia no es una revisión independiente.

Durante esa validación se reparó además la salida del resumen cuando el motor
había confirmado y finalizado una sesión, pero la respuesta de inicio se perdió
(`ad7e91c3586a342c247584aa3f1ae7b8563344a9`). El inicio todavía incierto sigue
bloqueando la salida después del timeout. Pasan 28/28 pruebas experimentales
tras el ajuste y 3/3 del control de lifecycle reforzado: 137 casos Dart distintos,
sin repetir todos los controles de 5B por un cambio limitado a esta pantalla.

La nueva ejecución release de `5d82d7e` mostró CameraX → MediaPipe y EAR 0,28/0,26,
tono técnico y cámara/análisis liberados al salir o suspender. **La referencia
abierta no se aceptó:** cobertura 0,016 y 0,050 (`insufficientObservations`),
conservando los umbrales. No se llegó a la comprobación de ojos cerrados.
Hubo estados caducados y ANR de servicios del sistema al inicio del AVD;
su causa y el rendimiento físico no están demostrados. Estos resultados no
sustituyen los ensayos anteriores de la guía por una aprobación general.
El ajuste de salida del resumen está probado con Flutter; no se logró producir
una sesión real en Android para ejecutar ese caso con la cámara.

**Artefacto final del código reparado** (sin sustituir el original):
`build/repair-5bc/vigia-normal-fase5bc-repair-final-release.apk`,
94 615 029 bytes; SHA-256
`bce4203d057f23652a7fa1641886d4b3cdc1374581e6b604d1cc31f789b1355f`.
Código `ad7e91c3586a342c247584aa3f1ae7b8563344a9`, firmado debug v2, identidad
normal, sin INTERNET/ACCESS_NETWORK_STATE. En un nuevo arranque del AVD con capa
temporal se verificaron instalación, rostro/ojos medibles (0,28/0,26) y salida
con cámara/análisis cerrados. No se repitió la calibración ni se obtuvo sesión
real. Archivo, firma, permisos, comandos y límites completos en el informe.

## Prueba guiada con webcam (2026-10-14, en curso)

Con consentimiento expreso, webcam física mediante el AVD `vigia_pixel`,
capa temporal sin alterar datos/configuración originales, sin guardar imágenes,
vídeo ni puntos faciales. El usuario confirmó movimiento en directo y, con el
APK reparado anterior (`bce4203d…`), referencia aceptada (115 observaciones
abiertas), tono oído y confirmado personalmente, sesión, cierre voluntario con
avisos, reapertura con cese de tonos, pausa y primera reanudación activa,
finalización y resumen. Continúa la intermitencia de «No evaluable»; no se
amplían umbrales para estabilizarla. Los rechazos por cobertura también se
repitieron con webcam: cambiar la fuente no garantiza la calibración.

La segunda reanudación dejó la cámara encendida mientras la app ocultaba su
vista durante `PAUSED/resumePending`. Reparación local `a7198626ac01751fa5c534605f71020e41f2d6f5`:
mostrar la vista al recuperar, manteniendo la espera de observaciones válidas
antes de ACTIVE. Regresión de widget reproducida antes y pasada después;
Flutter 29/29, análisis limpio, JVM dirigida 70/70. Se añade un diagnóstico
optativo de tiempos/motivos Q, sin imágenes ni puntos, para medir los huecos
antes de atribuir su causa. Validación Android de ese cambio aún en curso.

Resultados, confirmaciones humanas, artefactos y límites en
`docs/evidence/fase5bc-webcam.md`. Webcam mediante emulador no es D1 ni valida
conducción real. La comprobación de nuestras reparaciones no equivale a una
revisión independiente; las aceptaciones anteriores no afectadas se conservan.
