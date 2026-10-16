# Revisión y reparación de 5D por Codex

2026-10-15. Autorización expresa del usuario para revisar y reparar 5D;
Claude detenido. Las comprobaciones de las reparaciones propias son
**validación propia**, no una revisión independiente.

## Base y conservación

Git inicial: `main`, árbol limpio, dos commits locales sobre `origin/main`.
Cadena comprobada por parentesco:

- Base publicada: `7e31975dc11ca4814eaba61afa3ec06294b8ed71`.
- Implementación: `eae1c78d34c1f3385f4e8d4cfd6e5ae0ded3ed03`.
- Documentación / HEAD inicial: `2000f76ba935e1e21780e5b9e0fdec06077661c5`.

Fetch posterior confirma `origin/main` en la misma base. Sin cambios ajenos
al empezar. Sin amend, push ni PR. El BOM de los mensajes previos se conserva.
Contratos consultados: Área 04 §11–12 y Área 06 §7–11; fuentes sin modificar.

## Defectos reproducidos y reparaciones

1. **Apertura fallida del journal.** Se almacenaba `journalOpened=true` antes
   de obtener el escritor. Tras una excepción, el siguiente inicio podía
   aceptarse sin `sessionStarted`. La regresión JVM falla en el código
   recibido. Se conserva la posibilidad de reabrir y el inicio devuelve
   `journalWriteFailed` si no consigue confirmar su escritura.
2. **Cierre fallido y bloqueo posterior.** La fila quedaba abierta, pero la
   recuperación solo se intentaba una vez y descartaba todas las filas de la
   misma instancia, incluso una sesión abandonada. La regresión JVM falla
   antes. Ahora las lecturas/inicios pueden reintentar la recuperación; solo
   se excluye la sesión que el escritor todavía posee. Una fila abandonada
   se recupera una vez como interrumpida, sin final, incluso en el mismo proceso.
3. **Resumen sin cierre durable.** Se quedaba en «Guardando» con relecturas
   indefinidas si el cierre no existía. Reproducción de widget contra el
   archivo original: falla. Ahora comunica «Cierre no confirmado», sin
   totales, permite salir y limita a cinco las consultas automáticas por
   solicitud. Sigue pudiendo importar un cierre sin recibir su aviso.
4. **Totales con pérdida conocida.** Inicio mostraba 80,0 % aunque faltaban
   dos hechos. Fallan antes las regresiones de repositorio y widget. Los
   valores recibidos se conservan en SQLite; la proyección pública y las
   cuatro pantallas no ofrecen totales completos de ese registro. El cierre
   confirmado y los hechos confirmados se conservan.
5. **Importación detenida anunciada como completa.** Con 5001 hechos quedaba
   uno pendiente tras el límite de 50 lotes; un ACK sin avance también podía
   anunciar «al día». Ambas regresiones fallan antes. Se continúa por tandas,
   cediendo ejecución; se comprueba el avance antes de anunciar consolidación.
   Un conflicto tardío detenía el lote pero dejaba su sesión como completa:
   otra regresión falla antes. Ahora la marca de incompleto de la sesión
   afectada se guarda junto con el prefijo válido, sin sobrescribir sus datos
   ni afectar otras sesiones.
6. **E/S bajo el cerrojo de análisis y decisiones.** Medición dirigida de
   SQLite real y regresión con escritor bloqueado. En Android las escrituras
   del recorrido pasan a un escritor FIFO separado, con límite de 256 hechos
   compactos. La cola no es durable ni reintenta fallos; el desborde cuenta
   pérdida. El inicio espera confirmación; finalizar libera cámara/audio
   antes de la barrera que vacía la cola y confirma el cierre. No cambian
   Gmax, Tstale, calibración ni reglas oculares.

Los resultados previos a reparar están en `build/review-5d/`:
`jvm-before.xml`, `ui-before.txt`, `loss-before.txt`, `sync-before.txt` y
`conflict-before.txt`. Los errores iniciales de dos selectores/dobles del
arnés se corrigieron antes de obtener las reproducciones citadas; no se
presentan como fallos del producto.

## SQLite real, procesos e interoperabilidad

AVD aislado `vigia_review`, API 36/x86_64, creado dentro de
`build/review-5d/avd/`; cámaras desactivadas para las pruebas automáticas.
No se usan los datos del AVD anterior ni se siembran sesiones en la app normal.

- Cuatro pruebas SQLite pasan: commit/reapertura/ACK y restricciones;
  rollback de inicio y cierre; pérdida de monitoreo seguida de cierre;
  cola asíncrona y barrera durable. Secuencias contiguas, IDs únicos y
  conservación de hechos; ACK exacto por ID y hash.
- Cuatro invocaciones separadas de `am instrument` pasan: inicio abierto →
  recuperación en otro PID; pérdida sin poder guardar su marca → recuperación
  en otro PID. Se exige PID distinto. La recuperación es idempotente y no
  inventa final ni extiende el último límite durable.
- Si ni siquiera se persistió la pérdida antes de morir, no es posible
  reconstruir su número. La ausencia de cierre basta para recuperar
  `interrupted/incomplete`: último prefijo confirmado, sin totales ni final.
- Un vector **sintético**, escrito y releído por Kotlin/SQLite Android, se
  conserva en `test/fixtures/fase5d_native_records.json`. Dart verifica los
  tres hashes, guarda en Drift, cierra/reabre y reimporta sin duplicados.
  No es evidencia de cámara ni un recurso de la aplicación.
- Una regresión con trigger SQLite en Drift falla durante la transacción:
  no quedan recibos ni sesión parciales, y no hay ACK. Tras retirar el fallo,
  el mismo lote se importa. Se cubren el commit anterior al ACK y su relectura.

## Coste observado en el emulador

200 checkpoints sintéticos, `synchronous=FULL`, sin cámara:

| Operación | p50 | p95 | Máximo |
|---|---:|---:|---:|
| Escritura síncrona anterior, ms | 27,6200 | 77,5109 | 185,3498 |
| Encolado con la reparación, ms | 0,0709 | 0,2845 | 0,9844 |

Vaciar esa ráfaga artificial de 200 hechos y cerrar: **3818,5554 ms**.
No es una sesión a la cadencia normal de un checkpoint por segundo, ni una
medición de inferencia. El cierre todavía espera durabilidad después de
liberar recursos. Estas mediciones son del emulador; **no son D1** ni se
atribuyen a un teléfono. Regresión JVM: con el escritor bloqueado siguen
las observaciones y el tono; liberar cámara precede a esperar el cierre.
Otra regresión agota la cola: conserva 256 hechos y declara 44 perdidos.

## Validación y renderizados

- JVM del plugin: **103/103** (102 iniciales y la regresión adicional de fecha
  de cierre descrita abajo).
- Dart del plugin: **3/3**, análisis limpio.
- Historial experimental: **30/30**, incluidos vector Kotlin y conflictos.
- Pasada dirigida final: **79/79** (recorrido experimental, historial,
  interoperabilidad y 20 renderizados de 5D). Se ajustó una aserción antigua
  que pedía totales de un cierre conflictivo, comprobando además que los
  valores originales siguen en SQLite.
- Análisis de la app limpio; registro de especificaciones: **500, OK**.
- Suite Flutter completa ejecutada: **797 pasan / 6 fallan**, todos los
  fallos en goldens 5C. Esta pasada precede al último refuerzo de integridad;
  las pruebas dirigidas se repiten sobre el resultado final.

Se conservan los cuatro goldens conocidos de cierre/pausa, sin actualizarlos.
En esta ejecución fallan además los dos de «sin señales». Los seis fallan
también en un worktree limpio del commit publicado `7e31975`, con el mismo
toolchain. Los ocho renderizados **nuevos** `F5D_revision_*` cubren Inicio,
Resumen y detalle incompletos y cierre ausente, en claro y oscuro. No se ha
actualizado ningún patrón 5C para ocultar diferencias.

## APK y prueba guiada

APK anterior conservado en `build/review-5d/vigia-normal-fase5d-before.apk`,
SHA-256 `7af8088e8fd1fb9e91d5003fc831b312059566d5d5fd215fd1eab4d3b0c36afe`.
Primera reparación: commit local `be7ab5be658ffc4a43835598357efa6fc7888500`.
Primer APK reparado (conservado; solo vista previa):
`build/review-5d/vigia-normal-fase5d-repaired-release.apk`,
**95 237 621 bytes**, SHA-256
`0b6252249f042d2bceb17159d47f5a6e9a1b017c6dd1833569c53b6bb3edde1c`.
Compilación release satisfactoria. `com.juanrueda.vigia`, «Vigía», versión
0.1.0/1, minSdk 26, target/compile 36, tres ABI. Firma debug v2 válida;
certificado SHA-256
`dd6dbeb4d913a16de01e08990d232b5b8d1bd988f0d4613a86d42f124f27dead`.
Permisos: CAMERA y el interno de AndroidX; sin red, micrófono ni ubicación.
El listado del APK no contiene fixtures, semillas ni bases precargadas.

Preparación guiada: AVD aislado sin sesiones en la app normal. El primer
arranque visible se cerró al inicializar OpenGL; el reintento usa
`-gpu swiftshader -feature -Vulkan`, sin modificar el AVD original. Un intento
de instalar antes de estar disponibles los servicios Android falló y se
repite esperando `sys.boot_completed=1`; no es un fallo de Vigía.
Resultado humano de la sesión todavía pendiente: **no se acredita aún una
sesión de cámara de 5D**.

El APK extraído de la instalación tiene el mismo SHA-256 que el entregable.
Inicio mostró «Aún no hay sesiones experimentales» antes de abrir la cámara;
no se sembraron fixtures en esta app. El usuario confirmó expresamente
«Sí, veo movimiento en directo». La cámara figura abierta en Android y el
análisis nativo iniciado. Todavía no hay calibración aceptada ni sesión
iniciada: la lectura actual indica «Rostro no detectado» y se ha pedido al
usuario centrar el rostro. No se atribuyen audibilidad ni gestos al usuario.

### Ajuste detectado al validar nuestra propia cola

La primera reparación calculaba la fecha civil del cierre dentro del
escritor, después de vaciar las operaciones anteriores. Regresión con reloj
y escritor bloqueado: se pide finalizar en 2000, el disco se libera en 9000,
y el hecho guardaba 9000. `close-time-before.txt` registra el fallo sobre
nuestra reparación, no sobre la implementación recibida. Ahora se captura
la fecha al pedir finalizar, igual que el offset monotónico del motor; esperar
al disco no cambia el instante del hecho. JVM completa: 103/103.

Se conserva el APK `0b625224…`, que solo se usó para comprobar la vista previa,
y se genera otro APK antes de iniciar una sesión. La vista previa se cerró
temporalmente para liberar carga; el AVD se reabre con `QT_OPENGL=desktop`,
`-gpu host -feature -Vulkan`. No se modifican los archivos originales del AVD
ni se inventa que la nueva versión haya sido probada por una persona.

### APK utilizado para el recorrido guiado

Corrección del instante: `74a20836b88a7a42ffae0aa71473f9c54d9b1e6c`.
APK nuevo: `build/review-5d/vigia-normal-fase5d-repaired-v2-release.apk`,
95 237 621 bytes, SHA-256
`9b16e67001012f7604cb1a143039199cf7af39c72750ff02c0b480685daa2f48`.
Firma v2 válida, mismo certificado debug, identidad normal y mismos permisos
CAMERA/interno de AndroidX. El APK extraído después de instalar tiene el
mismo hash. El anterior se conserva. No se modificó el formato de las bases
ni se borraron datos para instalarlo.

El usuario confirmó «Ya detecta un rostro». Se dejó visible «Calibrar» y se
pidió que lo pulsara cuando se habilite y siguiera el asistente. Pendiente
el resultado; todavía no se afirma calibración aceptada, audibilidad ni
una sesión real guardada.

### Cierre de esta ejecución: iluminación insuficiente

El usuario indicó: «en el momento no tengo buena iluminacion para testear
\"calibrar\"». La prueba guiada queda pendiente hasta disponer de iluminación
adecuada. No se sustituye por una simulación ni se cambian umbrales.

Antes del cierre, el motor del APK V2 registró un intento de referencia:
`OPEN_REFERENCE` a 16:02:42.552 UTC y `REJECTED/insufficientObservations` a
16:02:50.558, `open(samples=59, coverage=0.561)`. Son observaciones del motor,
no una confirmación humana de cada gesto. No hubo calibración aceptada.
La iluminación insuficiente es la condición declarada por el usuario;
no se demuestra que explique por sí sola todos los huecos de recepción.

No se realizó la prueba de tono ni se confirmó audibilidad; tampoco se
inició una sesión, se probó una alerta ocular en sesión ni se completaron
pausa/reanudación, finalización, consulta de una sesión real y reapertura.
Esos pasos **no están acreditados por webcam en 5D**. Los registros sintéticos
y las regresiones SQLite anteriores mantienen su alcance propio.

Se salió de la vista previa, se detuvo la app y se conservaron las bases en
`build/review-5d/preserved-normal/`: `integrity_check=ok` en ambas, cero
sesiones y cero hechos nativos, cero sesiones proyectadas. El disco del AVD
aislado también se conserva; no se borraron los datos del AVD original.
Cámara sin clientes antes de cerrar el AVD. Emulador y recolectores propios
terminados; adb sin dispositivos y sin procesos emulator/qemu al comprobar.
Los tres archivos originales (INI del AVD, config y posición de ventana)
conservan los hashes iniciales; no hizo falta sobrescribirlos. Las variables
Qt y los modos GPU solo se aplicaron al proceso de prueba.

Se conservan los tres APK y `build/review-5d/SHA256SUMS.txt`. Siguiente paso
humano: preparar buena iluminación y retomar **Calibrar**, con el APK V2 y el
AVD aislado, comprobando primero la vista previa. Después: probar tono →
confirmación personal de audición → iniciar → señal ocular → pausa/reanudación
→ finalizar → Historial → detener proceso y reabrir. Una acción humana cada vez.

Siguen pendientes D1 y la intermitencia de «No evaluable». No se amplía la
fase ni se convierten los pendientes de producción en tareas.

### Reanudación guiada del 15 de octubre: calibración rechazada y tono confirmado

Git inicial limpio en `main`, HEAD
`14734d8938bdcea1407526aab6433eae42e3fa7e` (seis commits locales sobre
`origin/main`). Se leyeron continuidad, evidencia e instrucciones. Claude
permanece detenido. Se utilizó el **APK V2 existente**, sin recompilar:
`build/review-5d/vigia-normal-fase5d-repaired-v2-release.apk`, SHA-256
`9b16e67001012f7604cb1a143039199cf7af39c72750ff02c0b480685daa2f48`.
La extracción del APK instalado produjo el mismo hash. Firma v2 verificada,
certificado debug SHA-256
`dd6dbeb4d913a16de01e08990d232b5b8d1bd988f0d4613a86d42f124f27dead`;
paquete `com.juanrueda.vigia`, versión 0.1.0/1 y CAMERA concedido. Se mantienen
solo CAMERA y el permiso interno del receptor, sin red ni micrófono.

Se abrió el AVD aislado **persistente** `vigia_review`, con webcam0,
Qt desktop/GPU host y sin cargar/guardar snapshots. No se reinstaló ni se
borraron datos. El usuario confirmó «Sí, veo movimiento en directo» y,
después, que tenía toda su cara en pantalla pero la calibración se rechazaba
con pocas observaciones. La interfaz mostró un rostro, ojos medibles y
«Calibrar» habilitado antes del primer intento. Estas observaciones pertenecen
a webcam real en un emulador; no a D1 ni a una fixture.

**Diez intentos registrados, todos rechazados en OPEN_REFERENCE con
`insufficientObservations`.** La referencia requiere 8 s, al menos 60 muestras
válidas y cobertura ≥0,80 (6400 ms de spans válidos con huecos ≤150 ms).
Los horarios siguientes son UTC del **16 de octubre** (noche del 15 en Bogotá).

| Inicio UTC | Muestras válidas nativas | Cobertura nativa | Huecos de entrada >150 ms / intervalos observados | Hueco máximo ms | Edad máxima entrada→aplicación ms |
|---|---:|---:|---:|---:|---:|
| 01:01:21.364 | 33 | 0,085 | 28/33 | 486,420 | 424,883 |
| 01:01:31.456 | 38 | 0,122 | 30/38 | 358,891 | 347,710 |
| 01:01:41.218 | 43 | 0,196 | 30/43 | 384,525 | 347,885 |
| 01:02:17.598 | 40 | 0,062 | 36/40 | 359,002 | 317,873 |
| 01:02:37.884 | 30 | 0,029 | 28/30 | 536,150 | 535,292 |
| 01:02:49.174 | 26 | 0,000 | 26/26 | 543,903 | 493,614 |
| 01:02:58.346 | 27 | 0,037 | 25/27 | 561,320 | 519,042 |
| 01:03:26.538 | 42 | 0,173 | 30/41 | 359,124 | 356,895 |
| 01:03:36.896 | 42 | 0,219 | 28/42 | 295,093 | 267,598 |
| 01:04:19.919 | 22 | 0,015 | 21/22 | 780,153 | 573,150 |

Muestras y cobertura proceden del resultado nativo. Las columnas temporales
proceden de los diagnósticos comprendidos entre los mensajes OPEN_REFERENCE
y REJECTED: **son ventanas del log, no los límites monotónicos exactos del
paso**. Pueden incluir una observación adicional o perder una de frontera;
no se recalcula con ellas la cobertura nativa. En esas diez ventanas no se
registraron resultados de edad >750 ms ni observaciones Q inválidas. El hueco
de 780 ms es un intervalo entre entradas, no una edad de resultado.
En el conjunto de la apertura sí hubo ocho resultados descartados por
antiguos; la edad máxima aceptada fue 748 ms. Gmax=150 ms y Tstale=750 ms son
condiciones distintas. Los huecos explican la baja cobertura observada; no
se establece su causa raíz ni se atribuye a iluminación.

Se inspeccionó de forma dirigida la carga: en una instantánea Vigía consumía
142 % de CPU sobre cuatro vCPU; había 646680 KiB de swap ocupada en el
invitado. Renderizador NVIDIA GTX 1650 mediante el traductor del emulador.
Se redujeron temporalmente tamaño/densidad de pantalla de 1080×2400/420 a
720×1600/280. El último intento siguió rechazado (22 / 0,015). No fue una
comparación controlada y no demuestra una causa de rendimiento. El análisis
siguió recibiendo cuadros de 640×480. No había sesión ni hechos que escribir
en el journal; esta ejecución no mide coste de escrituras durante monitoreo
ni identifica un defecto nuevo de 5D. No se cambiaron umbrales ni código.

**Prueba sonora:** el usuario respondió «Sí, lo oigo» tras pulsar «Probar tono»
y luego «Ya lo pulsé» al pedirle pulsar «Lo escuché». La accesibilidad mostró
«Tono de aviso / Cumplida / Confirmado». Es confirmación auditiva humana de
esta prueba, sin atribuirle confirmación de alertas en sesión. «Iniciar
monitoreo experimental» continuaba deshabilitado: «Para iniciar falta:
calibración». No se inició sesión ni se obtuvieron señal ocular en sesión,
pausa/reanudación, finalización, Resumen o detalle real. La coincidencia de
las cuatro vistas y la conservación de una sesión real tras morir el
proceso **siguen sin comprobarse por webcam en 5D**.

Se volvió a Inicio y a Historial: ambos vacíos. `am force-stop` eliminó el
PID 2368 (consulta `pidof` sin resultado); la reapertura creó el PID 4060.
Inicio e Historial continuaban vacíos y se recuperaron cero sesiones.
Copias SQLite en reposo antes y después de reabrir: `integrity_check=ok`
en ambas bases; `n_sessions=0`, `n_outbox=0`, `experimental_sessions=0`,
`experimental_session_marks=0` e `imported_records=0`. Se comprueba ausencia
de sesiones ficticias tras calibraciones rechazadas, no persistencia de una
sesión real finalizada ni reimportación de sus hechos.

Artefactos locales de esta ejecución en **`build/webcam-5d-resume/`**:
`session.log`, `calibration-windows.json`, `calibration-{1..10}.log`,
`calibration_windows.py`, `ui-sound-confirmed.txt`, `home-*-*.txt`,
`history-{before-stop,reopened}.txt`, `pid-*.txt`, `database-counts.json`,
`check_databases.py`, `db-{before,after}-reopen/`, `installed-hash.txt`,
`apk-signature.txt`, `package.txt`, `camera-final.txt`, `audio-final.txt` y
`original-config-{before,after}.json`. Solo texto, APK y bases de tiempos/
contadores; no se capturaron imágenes ni se sembraron fixtures. En el
arranque apareció un aviso transitorio de System UI sin respuesta; no
persistió al leer Inicio. Un primer sondeo de accesibilidad tras reabrir
falló por XML ausente y se repitió después del arranque; no se considera un
fallo demostrado de Vigía.

**Cierre:** análisis vivos=0, cámara `Active Camera Clients: []`, sin
reproductores activos de Vigía. Resolución/densidad restauradas a sus valores
físicos sin overrides, propiedad temporal `log.tag.VigiaTiming` restaurada
a vacía. App detenida y AVD cerrado sin snapshot; recolector ya terminado,
adb sin dispositivos y sin procesos emulator/qemu. Los tres hashes originales
(INI/config/posición de ventana) permanecen iguales. Se conserva el disco del
AVD aislado, las copias de bases y todos los APK anteriores.

No se repitieron suites ni se modificaron goldens: esta continuación solo
añade evidencia documental. Las regresiones sintéticas y validaciones propias
de reparación descritas arriba mantienen su alcance; no sustituyen los pasos
reales bloqueados. Siguiente comprobación pendiente: conseguir una referencia
con continuidad suficiente en el entorno de prueba, sin reducir umbrales,
antes de repetir el recorrido de persistencia. Siguen pendientes D1,
intermitencia y revisión independiente; Claude permanece detenido.
