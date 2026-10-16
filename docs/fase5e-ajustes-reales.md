# Fase 5E · Ajustes de la variante real

**Autorización:** del usuario, 2026-10-15, sobre `56e2f8f` (`main` limpio al
empezar; registrada en `AGENTS.md`). Variante normal (`com.juanrueda.vigia`).
Pendiente de la revisión y reparación de Codex. La validación descrita aquí es
**propia**, no una revisión independiente.

## Alcance

P12 (Ajustes) y P13 (Sonido) pasan a la variante normal, reutilizando las
pantallas, los componentes B5.2 y el `PreferencesController` de la fase 3. No
se duplicaron controladores ni repositorios: cambia **dónde** se guardan las
preferencias y **quién** reproduce la prueba de sonido.

- Tema Sistema / Claro / Oscuro: se aplica en el acto y se guarda.
- Movimiento reducido: se guarda y se suma a la reducción de Android, que se
  respeta siempre (sin cambios respecto de la fase 3).
- Sonido: selección, prueba y guardado de los tres patrones incluidos.
- El motor experimental usa el patrón guardado para la prueba de sonido y el
  aviso de cierre prolongado.
- Cambiar el patrón invalida la prueba y su confirmación («Lo escuché»).
- Una respuesta tardía de una prueba antigua no confirma el patrón nuevo.
- Fallos de guardado: aviso por preferencia, con el valor que sigue vigente;
  las preferencias aceptadas no se pierden (mecanismo de la fase 3).

**No incluye:** exportación, borrado, retención, alias, perfil, ayuda, backend
ni red. No se tocaron cámara, calibración, reglas oculares ni parámetros de
`lab-eye-rules-0.1`. La DEMO conserva su comportamiento.

## Datos: separación real / DEMO (Área 06 §6 y §16)

| Variante | Base | Tabla |
|---|---|---|
| DEMO | `vigia_history_demo_v1.sqlite` | `preferences` (sin cambios) |
| Normal | `vigia_history_real_v1.sqlite` | `preferences` (nueva, esquema **v2**) |

- `lib/data/preferences/preferences_store.dart`: modelo `StoredPreferences` e
  interfaz `PreferencesStore`, que implementan el repositorio DEMO y
  `ExperimentalHistoryRepository`.
- `preferencesStoreProvider` elige por variante: en la normal, la base real o,
  si no está abierta, un almacén que **falla** cada escritura (se informa; no
  se finge un guardado ni se usa la DEMO).
- Esquema real v2: fila única (`singleton = 1`), `theme` con CHECK, y
  `sound_pattern_id` con CHECK al catálogo `patron_1…3` (Área 06 §9: no se
  inventan IDs). Retención, alias y explicación vista no se incluyen.
- **Migración v1 → v2:** solo `CREATE TABLE preferences`; las tablas de 5D no
  cambian. Otras versiones siguen sin ruta (sin migración destructiva).
- El arranque normal (`bootstrap.dart`) abre la base real y carga sus
  preferencias; un fallo de apertura o migración muestra el error de arranque
  existente (no se borra ni recrea la base).

## Motor: patrón de sonido

Contrato Pigeon (`packages/monitoring_engine/pigeons/monitoring_api.dart`,
regenerado con `tools/generate_pigeon.py`):

| Orden | Efecto |
|---|---|
| `testSound(patternId)` | Fija el patrón (si cambia, invalida la prueba anterior) y reproduce su tono de prueba. Devuelve un `soundTestId` nuevo |
| `setSoundPattern(patternId)` | Si cambia, invalida `soundTestId`, reproducción y confirmación. Con sesión vigente: `sessionActive` (la sesión conserva su patrón) |
| `previewSound(patternId)` | Tono de prueba para P13; no cambia el patrón ni la prueba de la sesión. Rechazado con sesión o calibración en curso |
| `MonitoringSnapshot.soundPatternId` | Patrón de la prueba y de los avisos de la sesión |

Un patrón fuera del catálogo se rechaza (`unknownSoundPattern`) sin sustituirlo
por otro. `SoundPattern.kt` reproduce los mismos tonos de `ToneGenerator` que
`MainActivity` usa en la DEMO (prueba y cierre); `patron_1` conserva los tonos
anteriores del motor. El pitido de guía de la calibración sigue con
`patron_1`: la calibración no cambia.

En Flutter (`ExperimentalMonitoringController`):

- al confirmarse un guardado de patrón, y siempre que el estado del motor
  informe otro patrón fuera de sesión, se envía `setSoundPattern`. Va por su
  propio canal de orden: no espera a otra orden en curso ni la bloquea;
- la prueba lleva el patrón guardado;
- «Lo escuché» e «Iniciar» solo se aceptan si el motor informa el patrón
  guardado (`soundTestPlayedFor` / `soundConfirmedFor`). Así, una prueba de
  otro patrón —respuesta tardía o estado anterior al reenvío— no se confirma
  ni inicia una sesión. Kotlin lo vuelve a comprobar por `soundTestId`;
- un motor nuevo (proceso reabierto) arranca con `patron_1` y recibe el
  guardado con su primer estado.

## Bloqueos (UX §4.2)

`settingsLockedProvider`: en la normal, la sesión experimental vigente (activa
o en pausa) que conoce Flutter. Con ella, Ajustes solo deja cambiar el tema y
Sonido muestra el bloqueo con «Volver al monitoreo» hacia el monitoreo
experimental. La salida del monitoreo con sesión vigente ya estaba bloqueada;
el motor rechaza además cambiar el patrón durante la sesión, que es la
garantía si el estado de Flutter no estuviera al día.

## Navegación

Inicio e Historial de la variante normal abren Ajustes desde la barra (antes,
un aviso de «no disponible»). Ajustes no lleva el rótulo DEMO; indica que la
app DEMO guarda sus preferencias por separado.

## Validación propia

| Comprobación | Resultado |
|---|---|
| `flutter analyze` (app y plugin) | Sin problemas |
| JVM `:monitoring_engine:testDebugUnitTest` | 111/111 (8 nuevas de patrón) |
| `test/history/real_preferences_test.dart` (nuevo) | 17/17 |
| Pruebas existentes ajustadas | `bootstrap_test` (la normal devuelve 2 sustituciones), `fase3_flow_test` y `demo_flow_test` (la normal tiene Ajustes; sin base no se finge guardado), contenedores DEMO de `preferences_persistence_test` y `write_failure_test` (fijan el modo DEMO) |
| Mutaciones temporales | Detectadas 6/6 (guardas de confirmación e inicio, reenvío al guardar y al recibir estado, bloqueo por sesión, almacén real) |
| Renderizados `test/goldens/fase5e/` (nuevos) | 28: P12 y P13 (normal, error y sesión vigente; prueba y guardado de P13) × claro/oscuro × 360 al 100 % / 320 al 200 %, revisados; sin desbordes |
| Suite Flutter completa | 823 pasan / 7 fallan: los 6 goldens 5C que ya fallaban en la base (no se actualizaron) y `demo_flow_test` «modo normal…», que exigía que la normal no tuviera Ajustes; actualizada y en verde (23/23). Los 28 renderizados 5E se generaron después (28/28) |
| `spec_registry.py check` | OK (500) |
| Migración de una base v1 auténtica | Copia de `build/review-5d/preserved-normal/…/vigia_history_real_v1.sqlite` (v1, 3 tablas): pasa a v2 con `preferences`, sin tocar las demás; el original conserva su SHA-256 `b615396c…bd01` |
| Android (AVD `vigia_pixel` en `-read-only`, sin cámara) | APK release instalado con `adb install -r`; arranque sin error (base del dispositivo migrada), ráfaga Oscuro/Claro/Oscuro + Reducido → «Preferencia guardada»; P13: prueba por el motor «correcta» y Patrón 3 guardado. `force-stop` (sin PID) y reapertura con otro PID: Oscuro, Reducido y Patrón 3 conservados. Sin `FATAL` ni errores de Flutter. Capturas en `D:\dev\vigia-entrega\capturas\fase5e\` |

Pruebas nuevas (SQLite real en disco salvo las de pantalla):

- guardados sucesivos y entre conexiones (una fila), CHECK del catálogo,
  migración v1 → v2 con datos de 5D conservados, separación de archivos real
  y DEMO;
- guardados simultáneos de tema, movimiento y patrón; fallo con aviso
  específico y preferencias aceptadas en memoria, SQLite y motor;
- reapertura: `bootstrap` sobre los mismos archivos carga lo guardado;
- motor: envío al confirmarse el guardado, invalidación de la confirmación,
  respuesta tardía de una prueba antigua, inicio rechazado con la prueba de
  otro patrón, sesión vigente sin reintentos y envío al terminar, motor nuevo;
- pantallas: Inicio → Ajustes sin rótulo DEMO, tema aplicado y guardado;
  prueba de P13 por el motor y su fallo; guardado y fallo del patrón; bloqueo
  con sesión.

## APK

`D:\dev\vigia-entrega\vigia-normal-fase5e-release.apk`, 95 319 541 bytes,
SHA-256 `ab582248785dbac59fe174ef11f9d1b1e2fdf93ab7326d94a9a98ccbadc133c0`
(añadido a `SHA256SUMS.txt`). `com.juanrueda.vigia`, «Vigía», solo `CAMERA`,
firma de depuración verificada con `apksigner`. Compilado del árbol de trabajo
idéntico al commit de código de 5E (`4a84774`). No se recompiló la DEMO: su código solo
cambió por la reorganización del modelo de preferencias, cubierta por sus
pruebas.

## No comprobado

- **Recorrido real completo con cámara** (calibración, sesión, aviso con el
  patrón guardado y persistencia): aplazado por el usuario hasta disponer de
  un Android físico. La iluminación no está demostrada como causa de los
  rechazos de calibración; no se cambiaron umbrales.
- Audibilidad de los tres patrones en el flujo de alarma del motor (las
  pruebas comprueban el tono pedido, no lo que se oye) y en D1.
- TalkBack real.
- El bloqueo de Ajustes usa el último estado del motor conocido por Flutter;
  sin consulta propia desde Ajustes. El motor sigue rechazando el cambio de
  patrón con sesión vigente.
