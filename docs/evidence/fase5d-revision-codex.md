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
Código reparado: commit local `be7ab5be658ffc4a43835598357efa6fc7888500`.
APK reparado: `build/review-5d/vigia-normal-fase5d-repaired-release.apk`,
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

Siguen pendientes D1 y la intermitencia de «No evaluable». No se amplía la
fase ni se convierten los pendientes de producción en tareas.
