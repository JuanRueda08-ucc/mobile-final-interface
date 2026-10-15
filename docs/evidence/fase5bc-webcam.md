# Prueba guiada de 5B + 5C con webcam

2026-10-14 (fecha local; registros Android del 2026-10-15 UTC).
**Prueba guiada terminada; validación propia de la reparación.**

## Preparación y privacidad

Autorización expresa del usuario para usar la webcam del computador mediante
el emulador, procesamiento local, sin guardar imágenes, vídeo ni puntos faciales.
Se usa únicamente información de accesibilidad y registros de texto.

Git inicial: `main` limpio, HEAD
`b6582a85c4076fd17f4ef7573e1242b33ece9098`. No había cambios ajenos.

Herramientas instaladas: SDK Android en `D:/dev/android-sdk`.
`emulator -list-avds`: `vigia_pixel`, API36/x86_64.
`emulator -webcam-list`: «HD User Facing», `webcam0`, NV12.
Una sola instancia, visible, `emulator-5554`:

```text
-avd vigia_pixel -port 5554 -read-only -no-snapshot-load -no-snapshot-save
-no-boot-anim -camera-back none -camera-front webcam0 -scale 0.29
```

Sin wipe-data. Datos en capa temporal; instalación `adb install -r` del APK
reparado, SHA-256
`bce4203d057f23652a7fa1641886d4b3cdc1374581e6b604d1cc31f789b1355f`.
Permisos inspeccionados de nuevo: sin INTERNET/ACCESS_NETWORK_STATE.
Wi-Fi y datos desactivados en esa capa. Configuración y posición de ventana
anteriores respaldadas en `build/webcam-5bc/` para comprobar/restaurar al cierre.

El usuario **confirmó movimiento en directo**, no la imagen fija anterior.
`vigia_pixel` es el dispositivo virtual; la app instalada es la normal reparada,
no la DEMO. Webcam física a través del emulador no equivale a D1 ni valida
conducción real.

## Primera calibración y confirmaciones humanas

Se separan confirmaciones del usuario y estados observados:

- Usuario: confirmó posición preparada, después «Referencia aceptada» y
  audición personal del tono solicitado con «Probar tono».
- Registro nativo: dos cierres, sus reaperturas y `ACCEPTED` a
  `10-15 02:39:09.818` (reloj UTC del AVD; fecha local anterior).
- Accesibilidad: referencia abierta 0,29/0,28 y **115 observaciones válidas**;
  el estado de sonido ya figuraba «Confirmado». Codex no pulsó «Lo escuché».

Intentos anteriores observados en el mismo APK/webcam, sin atribuir acciones
humanas que no estén confirmadas:

| Resultado | Datos del motor |
|---|---|
| invalidEyeQuality | open: 59 válidas, cobertura 0,460 |
| insufficientObservations | cierre 1: 9 válidas, cobertura 0,706 |
| invalidEyeQuality | open: 68 válidas, cobertura 0,709 |
| insufficientObservations | cierre 1: 6 válidas, cobertura 0,338 |
| unstableReference | reapertura 1 no confirmada |
| unstableReference | relativeMAD 0,112/0,160; límite 0,15 |

Cambiar la fuente por webcam **no eliminó los rechazos**. Los umbrales
permanecen iguales: abierta ≥60 muestras/8 s y cobertura ≥0,80; cierre ≥6/1 s
y cobertura ≥0,80; intervalos válidos consecutivos ≤150 ms; Tstale=750 ms.
Las coberturas de cierre 0,706/0,338 corresponden a 706/338 ms de spans
válidos, por debajo de los 800 ms exigidos, aun alcanzando el mínimo de muestras.
Todavía no se dispone de la distribución de intervalos/edades de esos intentos;
no se atribuye su causa a la webcam, a la carga ni al usuario sin medición.

La herramienta estándar `uiautomator dump` no consigue reposo con esta pantalla
dinámica. Se preparó un lector de accesibilidad con espera de reposo cero,
sin cambiar la app ni sus temporizadores. El primer arnés no generaba XML por
una ruta temporal duplicada; se corrigió el arnés. Sus ejecuciones no cuentan
como regresiones o pruebas del producto. No se tomaron capturas de pantalla.

## Primera sesión y defecto de reanudación

El usuario confirmó personalmente «Lo escuché», el inicio con «Sin señales
persistentes» intercalado con «No evaluable», cierres voluntarios coincidentes
con avisos audibles, y su cese al abrir los ojos. Codex no confirmó el sonido
en su nombre. Confirmó también pausa con cámara apagada y una primera
reanudación que llegó a «Activa».

En la segunda reanudación informó cámara física encendida, vista oculta y
«Reanudando» sin terminar. Coincide con los registros: apertura 3 a
02:50:20, `PAUSED/reanudando=true`, rechazos `eyeOutsideFrame`,
`insufficientEyeResolution` y `noFace`, sin transición a ACTIVE antes de
finalizar. No se atribuyen esos rechazos exclusivamente a la vista oculta.

Defecto reproducido en Flutter: la condición de renderizado ocultaba
`FrontCameraStage` durante todo PAUSED, incluido `resumePending`, aunque
la sincronización abría la cámara para recuperar observaciones. La regresión
`reanudación pendiente muestra la vista para poder centrar el rostro` falla
antes del ajuste (cero vistas, pese a una apertura). El cambio muestra la
vista durante la recuperación; pausa normal sigue sin cámara y el motor
conserva Krecover/Gmax/Q. No fuerza ACTIVE ni oculta «No evaluable».

El usuario finalizó y confirmó el resumen: activo 1:43, evaluable 0:57,
pausa 8:24, cuatro activaciones y cuatro tonos iniciados, cero fallidos.
Son contadores del motor; no se afirma confirmación individual de los cuatro.
Finalización nativa a 02:53:58.717; cierre del análisis 3 a 02:53:58.987,
cero analizadores vivos. Dumpsys confirma cámara sin clientes y audio sin
tracks activos de Vigía (el historial de tracks no es actividad actual).

## Reparación y diagnóstico temporal

Commit local de código: `a7198626ac01751fa5c534605f71020e41f2d6f5`.
Flutter: análisis sin incidencias y 29/29 pruebas experimentales.
JVM seleccionada: 70/70 (experimental 30, core 30, demora 5, publicación 4,
diagnóstico 1). Registro de especificaciones: 500 comprobaciones, OK.
Logs antes/después en `build/webcam-5bc/`. Validación propia, no revisión
independiente; se conservan las aceptaciones anteriores no afectadas.

Se añade diagnóstico optativo `VigiaTiming`, desactivado por defecto y
habilitable solo en esta capa temporal mediante `log.tag.VigiaTiming`.
Registra entrada al analizador, recepción del callback, aplicación, validez
y motivos Q; no imágenes, EAR ni coordenadas/puntos faciales. Los tres
instantes proceden del reloj monotónico nativo. Entrada→callback incluye
conversión, inferencia y planificación; no se presenta como inferencia pura
ni como tiempo del sensor. Una prueba con entrada 1000/recepción 1100/
aplicación 5000 ms comprueba los datos y que el resultado permanece caducado;
callbacks de instancias anteriores o cerradas no añaden observaciones.

## APK actualizado y repetición Android

Nuevo APK compilado offline e instalado con `adb install -r`:
`build/webcam-5bc/vigia-normal-webcam-fix-release.apk`, **94 615 029 bytes**,
SHA-256 `4e7bdd90b7fbc9ac4c575529c6118c8d4ba8c0282cc306a75f168e7f11729497`.
Código `a7198626ac01751fa5c534605f71020e41f2d6f5`, identidad normal
`com.juanrueda.vigia` 0.1.0+1, minSdk26/target36; ABI armeabi-v7a, arm64-v8a,
x86_64. Firma v2 verificada, certificado debug SHA-256
`dd6dbeb4d913a16de01e08990d232b5b8d1bd988f0d4613a86d42f124f27dead`.
Solo CAMERA y permiso interno del receptor; sin INTERNET/ACCESS_NETWORK_STATE.
No se acredita ejecución en páginas de 16 KB con esa inspección.

### Primera medición temporal del APK actualizado

Prefijo reproducible de **463 observaciones, todas válidas**, apertura 1:
`timing-first463.log/json`, resumido con `timing_stats.py` (texto, sin puntos).
Entre sus 462 intervalos, **59** entre entradas y **53** entre aplicaciones
superan Gmax=150 ms. Intervalo de entrada p50=103,109 ms, p95=191,725 ms,
máximo=403,564 ms; intervalo de aplicación máximo=384,201 ms. Edad entrada→
aplicación p50=81,959 ms, p95=169,728 ms, máximo=367,040 ms: ningún resultado
supera Tstale. Entrada→callback p95=166,125 ms; callback→aplicación
p95=10,691 ms y máximo=46,536 ms. No son tiempos de inferencia pura.

Cobertura agregada de spans sobre el intervalo entre primera y última muestra:
0,7769. **No es la cobertura de un intento de calibración**, cuyos límites
son distintos. Tramo máximo con Q válida y ambos intervalos ≤150 ms:
5807,299 ms; las consultas/ticks del motor pueden cortar antes si detectan
silencio intermedio, por lo que tampoco acredita un Krecover concreto.

En este APK el motor registra rechazos `open(samples=67, coverage=0.688)`,
`probe2(samples=7, coverage=0.538)` y
`probe1(samples=9, coverage=0.731)`. Los recuentos mínimos por sí solos no
completan los 6400/800 ms de spans válidos requeridos. Hay huecos medidos
incluso sin rechazo geométrico y sin resultados de más de 750 ms; esto explica
pérdidas por Gmax y coberturas insuficientes, sin demostrar la causa de esos
huecos. Carga del emulador, instrumentación y muestreo son posibilidades,
no causas demostradas. No se ha identificado un error de cálculo de cobertura.
Las muestras posteriores incluyen `noFace` y rechazos geométricos: no se
mezclan con este prefijo para atribuir todos los huecos al rendimiento.

### Tres reanudaciones correctas

El usuario confirmó: «lo pausé y lo reanudé 3 veces y las 3 veces reanudó
correctamente». El registro del APK actualizado lo corrobora:

| Solicitud registrada | Apertura | ACTIVE / reanudando=false | Demora observada |
|---|---|---|---|
| 03:09:38.378 | 2 | 03:09:41.485 | 3,107 s |
| 03:09:44.309 | 3 | 03:09:45.986 | 1,677 s |
| 03:09:48.611 | 4 | 03:09:50.834 | 2,223 s |

Son tiempos de esta ejecución del emulador, no garantía de rendimiento físico.
Las aperturas 1/2/3/4 se cerraron con cero analizadores vivos; máximos de edad
aceptada registrados 536/167/137/129 ms, sin descartes por Tstale. La última
pausa se registró a 03:09:54.196. La observación de ausencia de cliente de
cámara y tracks de audio activos se repitió durante esa pausa.

La nueva calibración figura ACCEPTED a 03:08:46.630 en el motor, y hubo sesión
con dos activaciones/dos tonos iniciados/cero fallidos. No se atribuye al
usuario confirmación personal de esos dos tonos o cierres: sus confirmaciones
de audición/cierre/reapertura pertenecen a la primera sesión descrita arriba.
Se conserva la alternancia por `gap`/`resultsDelayed` y algunos rechazos Q;
la corrección de vista no se presenta como estabilización de las mediciones.

### Finalización y liberación

El usuario confirmó «Aparece el resumen y la webcam se apagó». Se observó
FINALIZED a 03:11:50.692 y el resumen por accesibilidad: activo 0:50, evaluable
0:39, pausa 2:07, dos activaciones, dos tonos iniciados/cero fallidos.
`session-new-summary.txt`, `camera-new-final.txt` y `audio-new-final.txt`
conservan las comprobaciones de texto: cámara `Active Camera Clients: []`,
analizadores vivos cero desde la última pausa y cero tracks de audio activos
(el único track listado pertenece al sistema). El historial de audio no se
confunde con un generador activo de Vigía.

Se detuvo el recolector de logcat propio y se cerró únicamente el AVD de la
prueba (`adb -s emulator-5554 emu kill`). Comprobación posterior: sin dispositivos
en adb ni proceso qemu del AVD, ni procesos del emulador/recolector propios.
Las propiedades de diagnóstico no persistentes y el auxiliar de accesibilidad
se limitaron al sistema invitado/capa temporal descartada. No se reabrió la
webcam al terminar ni se guardó un snapshot.

Los hashes finales coinciden con los iniciales, incluida la posición de ventana:

| Archivo original | SHA-256 final, igual al inicial |
|---|---|
| `D:/dev/avd/vigia_pixel.ini` | `5151dd628050f8a74589a950c3ec6791f3a703ad567ddc409a25b2c85cb5ffe4` |
| `D:/dev/avd/vigia_pixel.avd/config.ini` | `596540b705010cf7fa87877d9e2101854325d1936c7e3d80d86cc54a3ea191e0` |
| `D:/dev/avd/vigia_pixel.avd/emulator-user.ini` | `6950b98e59a50e8f72ebe4e7d6ff8ceb9c00d783e1618e7de2054cd90f929822` |

No fue necesario sobrescribirlos. Se preservaron los datos originales mediante
`-read-only`, sin wipe-data ni cambios de configuración persistente. No se
guardaron imágenes, vídeo ni puntos faciales; evidencia nueva exclusivamente
de texto. No hay FATAL en el registro filtrado conservado de la nueva ejecución.

## Resultado y límites

Reparación de la vista durante reanudación reproducida antes, regresión pasada
después y **tres reanudaciones Android correctas**, confirmadas por el usuario y
el motor. Recorrido real completado con participación humana: calibración,
sonido confirmado personalmente, sesión, cierres con avisos, reapertura, pausa,
reanudación y finalización. Las confirmaciones de sonido/cierres pertenecen a
la primera sesión; la repetición del nuevo APK acredita las transiciones y los
contadores descritos, sin atribuir confirmaciones humanas adicionales.

Continúan rechazos por cobertura y alternancia «No evaluable». Se midieron
huecos por encima de Gmax aun con Q válida, sin identificar error de cálculo;
su origen no quedó demostrado. No se ampliaron umbrales ni se conservaron
señales antiguas para disimularlo. No se acredita estabilidad general ni
rendimiento D1, captura física con reloj convertido, conducción real o política
validada. No se repitieron suites completas, matrices, contraste, goldens ni
ensayos del modelo. Solo un build normal justificado por los cambios.

Git: `main`, base `b6582a85c4076fd17f4ef7573e1242b33ece9098` ancestro del código
`a7198626ac01751fa5c534605f71020e41f2d6f5`, seguido por documentación local.
Sin cambios ajenos al comenzar, sin amend, push ni PR; sin avance de bloque.
El hash documental de cierre y Git final se informan con la entrega.

## Consolidación y publicación autorizadas

Tras cerrar la prueba en `2734d3bee3e8f775bbedcb877fd113d2185a668a`, el usuario
autorizó publicar el hito experimental. Se conserva la distinción de sesiones,
confirmaciones humanas, observaciones del motor y límites anteriores. Gmax=150 ms
corta continuidad/cobertura ocular ante huecos; Tstale=750 ms retira datos por
edad/silencio, sin permitir puentear esos huecos. La intermitencia continúa sin
causa demostrada. D1 y validación física siguen pendientes; no hay revisión
independiente de nuestras reparaciones.

Se copia el mismo APK, sin recompilar, a
`D:/dev/vigia-entrega/vigia-normal-fase5bc-webcam-release.apk` y se actualiza
`SHA256SUMS.txt`, conservando entradas anteriores. SHA-256 de origen y copia:
`4e7bdd90b7fbc9ac4c575529c6118c8d4ba8c0282cc306a75f168e7f11729497`.
No se repiten pruebas ni se modifica código.

Fetch de `origin`: `main` remoto en
`33a5edef093ad42fe53f9edc0318f294fd176eb0`, ancestro de los 14 commits locales,
sin cambios inesperados que integrar. Se autoriza publicar `main` sin force ni
PR. El resultado y hashes finales de publicación se informan en la entrega.
