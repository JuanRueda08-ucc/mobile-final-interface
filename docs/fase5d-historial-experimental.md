# Fase 5D · Persistencia e Historial de las sesiones experimentales reales

**Autorización:** del usuario, 2026-10-15, sobre la base publicada `7e31975`
(registrada en `AGENTS.md`). Variante normal (`com.juanrueda.vigia`). Pendiente
de cerrar la revisión y reparación de Codex autorizada por el usuario.
Resultados y reproducciones: `docs/evidence/fase5d-revision-codex.md`.

## Alcance

Al finalizar una sesión de «Monitoreo experimental», su resumen se conserva y se
consulta desde **Inicio**, **Resumen**, **Historial** y **detalle**, que leen el
mismo dato. Una sesión abierta cuando el proceso muere se recupera como
**interrumpida**: no se reanuda ni se le atribuye final.

**No incluye:** exportación, borrado (individual, masivo o por retención),
valoraciones, tendencias, órdenes con `commandId`, servicio en primer plano,
backend ni red. No se guardan imágenes, puntos faciales ni series por
observación. El DEMO no cambia.

## Arquitectura (Áreas 04 §11–12 y 06 §7–11, subconjunto)

```
MonitoringCoordinator (Kotlin, actor serial)
  └─ SessionJournal → escritor FIFO acotado → vigia_journal_real_v1.sqlite
                            │ readPendingRecords / acknowledgeRecords (Pigeon)
Flutter: JournalSync ──► vigia_history_real_v1.sqlite (proyección Drift)
  └─ Inicio · Resumen · Historial · detalle (mismas consultas)
```

| Pieza | Archivo | Qué hace |
|---|---|---|
| Formato y hash | `journal/JournalCodec.kt`, `lib/data/experimental_history/journal_codec.dart` | Serialización canónica propia (ver abajo) y SHA-256 del sobre |
| Almacén nativo | `journal/SqliteJournalStore.kt` | `n_sessions` + `n_outbox`; sesión abierta única, hechos inmutables e imborrables (triggers), `synchronous=FULL` |
| Escritor | `journal/SessionJournal.kt` | Hechos de la sesión, cierre único y recuperación |
| Lectura/ACK | `journal/ExperimentalJournalHost.kt` | Lote ≤ 100 en orden; ACK de ID **y** hash exactos |
| Proyección | `lib/data/experimental_history/experimental_history_{database,repository}.dart` | Importación transaccional e idempotente; consultas |
| Sincronización | `experimental_history_providers.dart` (`JournalSync`) | lote → transacción Drift → commit → ACK; una pasada a la vez |
| Pantallas | `lib/features/experimental_history/` | Historial, detalle, Resumen y sección de Inicio |

Rutas Kotlin relativas a `packages/monitoring_engine/android/src/main/kotlin/com/juanrueda/monitoring_engine/`.

### Hechos del journal

`sessionStarted` (versiones, perfil `lab-eye-rules-0.1`/`experimental`, modelo y
referencia compacta de calibración en millonésimas), `progressCheckpoint` (como
mucho 1/s, propuesta del Área 04 §11), `pauseStarted`, `pauseEnded` (al confirmar
la reanudación con Krecover), `closureDetected`, `playbackResult` (resultado
técnico, no audición), `sessionFinalized` y `interruptionRecovered`.

- **Inicio durable:** sin `sessionStarted` confirmado en SQLite, el motor rechaza
  el inicio (`journalWriteFailed`).
- **El tono no espera al journal:** se reproduce antes de encolar. Las
  escrituras del recorrido se ejecutan fuera del cerrojo del motor. Si una
  escritura falla, la sesión sigue, se cuentan los hechos perdidos
  (`recordsLost`) y el registro queda **incompleto**; no se fabrican los hechos
  perdidos. La cola local admite 256 hechos compactos; no es durable ni
  reintenta fallos. Su desborde declara pérdida. Inicio y cierre esperan el
  commit; Finalizar libera cámara/audio antes de la barrera del cierre.
- **Cierre único:** `sessionFinalized` exige la sesión abierta en la misma
  transacción; un segundo cierre se rechaza en Kotlin y en la importación.
- **Recuperación:** el journal se abre la primera vez que hace falta (lectura
  desde Flutter o un inicio); en ese momento las sesiones abiertas por otra
  instancia del motor reciben **una** `interruptionRecovered` y pasan a
  `interrupted`, con su último límite durable y **sin final**. El instante de
  recuperación no es tiempo de sesión. La DEMO, que comparte el plugin, nunca
  abre este journal. La recuperación se vuelve a intentar en lecturas e
  inicios sin sesión viva: un cierre fallido también puede recuperarse como
  interrumpido dentro de la misma instancia, sin bloquear futuros inicios.
- **Desconexión del motor** (plugin desacoplado con la sesión abierta): se
  escribe un último punto de control y la sesión queda abierta para la
  recuperación; no es un cierre confirmado.

### Importación (Flutter)

En una transacción Drift, por orden de secuencia: recalcular forma canónica y
hash; un `recordId` ya importado con el mismo hash es no-op y con otro, error de
integridad; la secuencia debe continuar sin hueco; tipo/versión desconocidos
detienen el lote; un hecho sin su sesión no crea una de relleno. Ante el primer
error se guarda el prefijo válido y el resto queda pendiente en el journal.
Solo tras el commit se envía el ACK. Si el ACK falla, la siguiente lectura es un
no-op. La importación se pide al montar Inicio, Historial, detalle y Resumen, y
al finalizar; el Resumen reintenta cada 1 s, hasta cinco lecturas por solicitud,
e informa «Cierre no confirmado» si falta el cierre durable. Así
que **no depende de que Flutter reciba el último aviso del motor**.

### Formato canónico (desviación declarada)

No es JCS/RFC 8785 completo: solo objetos, listas, cadenas, enteros (|n| ≤ 2⁵³−1),
booleanos y nulos; claves por unidades UTF-16; escapes `"`, `\` y U+0000–U+001F
como `\u00xx`. Las mediciones van como enteros escalados (`…E6`). El hash cubre
el sobre (incluida la secuencia) salvo el propio hash y el estado de ACK. Vector
compartido Kotlin/Dart con hash calculado aparte en Python (`4c3ee8ae…b6aa`).

### Totales y presentación

- **Finalizada completa:** totales del motor al cerrar — activo (= evaluable + no
  evaluable), pausado, activaciones, tonos iniciados/fallidos y pausas.
  Cobertura = evaluable / activo; sin denominador, «No disponible». Total
  representado = activo + pausado.
- **Finalizada incompleta:** conserva el cierre confirmado y los valores
  recibidos en SQLite, pero no presenta totales completos ni cobertura. Se
  conservan los hechos confirmados. Un conflicto de importación retira la
  calificación de completo de la sesión afectada dentro de la transacción.
- **Interrumpida:** inicio, último registro confirmado, «Final: Desconocido»,
  «Duración / Cobertura: No disponible», evaluable confirmado hasta el último
  punto de control (prefijo, rotulado como tal) y hechos confirmados.
- **Rotulado:** cada pantalla lleva «Experimental · datos reales»; las filas,
  «Experimental · <id corto>»; el detalle, «Real · experimental
  (lab-eye-rules-0.1)». La base fija `origin='realExperimental'` y
  `qualification_status='experimental'` con CHECK.
- **Separación DEMO:** otra app, otra base (`vigia_history_demo_v1`), otras
  pantallas. En la variante normal las rutas `/historial`, `/historial/:id` y
  `/resumen/:id` abren las pantallas experimentales; las del recorrido DEMO
  siguen bloqueadas.

## Pruebas y resultados reales

| Conjunto | Resultado |
|---|---|
| JVM `ExperimentalJournalTest` (nuevo) | 12/12: vector, orden y totales, cierre único, tono sin esperar al journal y pérdida declarada, inicio no durable rechazado, segunda sesión, recuperación única (activa y en pausa), desconexión, journal no abierto sin sesión, lectura/ACK exacto |
| JVM completa del plugin | 97/97 |
| Dart `journal_import_test` (nuevo) | 18/18: vector, guardado, lotes > 100, caída antes del ACK, mismo ID con otro hash, cierre duplicado, hecho alterado, hueco, huérfano, tipo desconocido, interrumpida, segunda sesión, pérdida declarada, reapertura en disco, concurrencia y fallo de lectura |
| Dart `experimental_history_ui_test` (nuevo) | 5/5: mismo dato en Inicio/Resumen/detalle/Historial; interrumpida; Resumen que espera el cierre durable sin otro aviso; vacío; DEMO sin historial experimental |
| Renderizados `test/goldens/fase5d/` (nuevos) | 12 (6 estados × claro/oscuro), revisados |
| Suites afectadas (app, experimental, historial, inicio, demo, cámara, renderizados 2/3/5A/5B/Inicio/5D) | todas pasan |
| Renderizados 5C | 4 fallos **idénticos en la base `7e31975`** (comprobado en un worktree limpio, ya eliminado): sesión en cierre prolongado y pausada; no se tocaron |
| Mutaciones temporales | sin recuperación: fallan 4 JVM; sin la guarda de cierre único en la importación: falla la prueba de cierre duplicado |

**Android (AVD `vigia_pixel`, capa de solo lectura, sin red, sin cámara):**

- `JournalSqliteInstrumentedTest` con SQLite real: commit, conexiones nuevas,
  ACK exacto, triggers de inmutabilidad y borrado, sesión abierta única y cierre
  único: OK.
- **Reinicio real del proceso:** `processRestart_step1_leaveOpenSession` y luego,
  en otra invocación de `am instrument` (otro PID),
  `processRestart_step2_recoverInNewProcess`: recupera una vez, sin final, con
  el último límite durable (2000 ms). Control: el paso 2 sin el paso 1 falla
  («hace falta ejecutar antes step1»), y en el mismo proceso falla por PID.
- **Extremo a extremo en la app** con un journal **sintético** (una sesión
  cerrada y otra abierta, escritas por `seed_forAppEndToEnd`; no es una sesión
  con cámara) copiado con `run-as` a la app normal de depuración: al abrir,
  Kotlin registró «sesiones recuperadas como interrumpidas=1»; Inicio mostró la
  interrumpida; Historial, las dos, rotuladas; el detalle finalizado, 45,0/15,0 s
  y «Completo · guardado». Tras `am force-stop` y reabrir: «recuperadas=0», las
  mismas dos filas. Bases extraídas: 10 hechos, 10 con ACK, 10 recibos únicos;
  proyección `finalized/complete` (60000/45000 ms) e `interrupted/incomplete`
  sin totales ni final.
- APK DEMO de depuración: su Historial muestra solo `S-DEMO-0001…0003`; sus datos
  contienen solo `vigia_history_demo_v1.sqlite` (ningún journal real).
- APK release normal instalado sobre esos datos: Historial y detalle
  interrumpido correctos; sin `FATAL`.
- Capturas: `D:\dev\vigia-entrega\capturas\fase5d\`.

`flutter analyze` (app y plugin): sin problemas. `python tools/spec_registry.py
check`: OK. Pigeon regenerado con `tools/generate_pigeon.py`.

Comandos de la prueba de reinicio:

```bash
cd android && ./gradlew :monitoring_engine:assembleDebugAndroidTest
adb install -r -t build/monitoring_engine/outputs/apk/androidTest/debug/monitoring_engine-debug-androidTest.apk
adb shell am instrument -w -e class com.juanrueda.monitoring_engine.JournalSqliteInstrumentedTest#processRestart_step1_leaveOpenSession com.juanrueda.monitoring_engine.test/androidx.test.runner.AndroidJUnitRunner
adb shell am instrument -w -e class com.juanrueda.monitoring_engine.JournalSqliteInstrumentedTest#processRestart_step2_recoverInNewProcess com.juanrueda.monitoring_engine.test/androidx.test.runner.AndroidJUnitRunner
```

## No comprobado / pendientes

- **Sesión real con cámara guardada en Android:** no se ejecutó en esta fase (el
  emulador sin webcam no cierra los ojos y no se usó la cara de nadie). La
  escritura de hechos desde el coordinador está probada en JVM y el camino
  journal → Pigeon → Drift → pantallas, con el journal sintético en Android.
- Muerte del proceso **de la app** con una sesión real abierta: cubierta por la
  recuperación en Android con el journal sintético y el reinicio real del
  proceso de prueba, no con una sesión de cámara.
- Sin reintento tras un fallo de escritura (la cola FIFO local no es un
  reintento ni es durable); sin `commandId` ni tablas de
  lotes/borrado/barreras; formato canónico propio en lugar de JCS.
- Coste medido en el emulador y escrituras del recorrido retiradas del cerrojo
  del coordinador durante la reparación. Inicio/cierre conservan sus barreras
  durables; recursos liberados antes del cierre. No medido en un teléfono.
- Siguen pendientes la **intermitencia de «No evaluable»** y **D1**; no se
  cambiaron umbrales.

## APK

| Variante | Archivo | Bytes | SHA-256 |
|---|---|---|---|
| Normal | `D:\dev\vigia-entrega\vigia-normal-fase5d-release.apk` | 95 221 237 | `7af8088e8fd1fb9e91d5003fc831b312059566d5d5fd215fd1eab4d3b0c36afe` |
| Normal reparada V2 | `build/review-5d/vigia-normal-fase5d-repaired-v2-release.apk` | 95 237 621 | `9b16e67001012f7604cb1a143039199cf7af39c72750ff02c0b480685daa2f48` |

Compilado en release desde el árbol de trabajo con el código de esta fase
(antes del commit), firmado con la clave de depuración; `com.juanrueda.vigia`,
«Vigía», permisos `CAMERA` y el permiso interno
`DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` de AndroidX; sin permisos de red.

**Cierre de la reparación (2026-10-15):** código final en `74a2083`, validación
propia (JVM 103/103, dirigida Flutter 79/79, plugin Dart 3/3; análisis y registro
de especificaciones correctos). Se conservan los goldens preexistentes y los
APK anteriores. La prueba guiada con el APK V2 se detuvo porque el usuario
declaró iluminación insuficiente. Hubo vista previa real y un intento de
calibración rechazado (59 observaciones, cobertura 0,561); **no hubo sesión
real iniciada ni confirmación de audibilidad**. Las bases normales conservadas
están vacías y sanas. AVD y recolectores cerrados; configuración original
intacta. El recorrido completo queda pendiente para buena iluminación.
Detalle y distinción entre pruebas sintéticas, validación propia y webcam:
`docs/evidence/fase5d-revision-codex.md`. No hay aprobación independiente de
las reparaciones ni publicación de estos commits.
