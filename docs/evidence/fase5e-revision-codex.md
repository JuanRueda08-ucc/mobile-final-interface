# Revisión y reparación de 5E por Codex

Revisión del trabajo de Claude iniciada el 2026-10-15 y cerrada el
2026-10-16 (America/Bogota). Claude permanece detenido. El usuario autorizó
reproducir y reparar sin autorizaciones entre hallazgos, conservar trabajo y
artefactos anteriores y crear commits locales, sin amend, push ni PR.
Las comprobaciones de las reparaciones son **validación propia de Codex**;
no constituyen una revisión independiente de esas reparaciones.

## Git y conservación de 5D

Git inicial limpio, rama `main`, nueve commits por delante de la referencia
local `origin/main`. No había cambios ajenos. Cadena exacta de padres:

| Papel | Commit completo | Padre |
|---|---|---|
| Base declarada | `56e2f8f5aec57cb33befb21137380d03b0bed3cf` | `14734d8938bdcea1407526aab6433eae42e3fa7e` |
| Implementación Claude | `4a84774b6431c87953daee7e66a827f3badb719f` | `56e2f8f5aec57cb33befb21137380d03b0bed3cf` |
| Documentación Claude / HEAD inicial | `60c89afdcbbd8c992bfa4a3d42cffe85636e3327` | `4a84774b6431c87953daee7e66a827f3badb719f` |
| Reparaciones y regresiones Codex | `6e89972626b3a24b714cf39871062d73317aa326` | `60c89afdcbbd8c992bfa4a3d42cffe85636e3327` |

La referencia local `origin/main` permanece en
`7e31975dc11ca4814eaba61afa3ec06294b8ed71`; no se consultó ni modificó el
remoto. Las reparaciones 5D `be7ab5be658ffc4a43835598357efa6fc7888500` y
`74a20836b88a7a42ffae0aa71473f9c54d9b1e6c` son ancestros de la base y
siguen conservadas. El diff de 5E añade preferencias al repositorio y al
esquema, sin sustituir el importador. El journal nativo, su escritor, el
codec, los vectores y las regresiones de importación 5D permanecen iguales
a la base; el coordinador conserva el instante anterior a las escrituras.
Las reparaciones presentes solo cambian la coordinación de Ajustes/sonido.

La copia preservada de la proyección 5D sigue en versión 1, con sus tres
tablas, `integrity_check=ok` y SHA-256
`b615396c6abba8a1ed3c9282386dea3a38bbea89c3b236453cc01d7cca98bd01`.
No se migró ni sobrescribió esa copia ni se modificaron datos del AVD.

## Hallazgos reproducidos antes de reparar

Los tres casos nuevos fallaron sobre el código de Claude. Salida original:
`build/review-5e/reproduccion-real.txt`.

1. **P1 — guardado antes de aceptación nativa.** El controlador escribía
   SQLite y publicaba el patrón nuevo; solo después otro listener enviaba
   `setSoundPattern`. Un rechazo podía dejar el patrón guardado/mostrado
   distinto del aplicado. La regresión recibió `PreferenceSave.saved`
   donde debía recibir fallo. El caso con una sesión nativa en pausa,
   desconocida para Flutter, publicó `patron_3` aunque la sesión conservaba
   `patron_1`. Rechazar únicamente en Kotlin no protegía SQLite.
2. **P1 — inicio con la confirmación antigua durante el guardado.** Retener
   la escritura del patrón nuevo dejaba vigentes el patrón y la prueba
   antiguos. `start()` envió realmente `start:cal-1:snd-1` durante esa
   ventana. La comprobación por igualdad de patrón después de guardar no
   cerraba esta carrera.
3. **P2 — bloqueo limitado a la copia Flutter y a los widgets.** El
   controlador permitía guardar movimiento reducido con sesión vigente;
   tampoco había consulta propia al entrar en P12/P13. Esto incumplía
   «solo tema» si el estado estaba desactualizado o se llamaba directamente
   al controlador. No se encontró un desbloqueo en el widget cuando ya
   conocía la sesión; el defecto estaba en la autoridad y la consulta.

El dictamen sobre la implementación de Claude es **desfavorable por estos
defectos reproducidos**. Están reparados en el commit indicado; la evidencia
siguiente valida los cambios propios sin atribuirles aprobación independiente.

## Reparación

`RealSettingsWriter` coordina las escrituras reales de sonido y movimiento
con una reserva del coordinador Kotlin, identificada por operación:

1. `beginSettingsChange` comprueba la sesión bajo el mismo cerrojo que
   `startSession`, acepta el patrón candidato y reserva Ajustes. Un rechazo
   o error anterior a la reserva no escribe SQLite.
2. Durante la reserva Kotlin rechaza iniciar, probar/confirmar el tono de
   sesión y cambiar el patrón por la vía ordinaria. Dart bloquea también
   prueba, confirmación e inicio mientras el patrón esté pendiente, incluso
   antes de que la reserva haya respondido.
3. Se escribe SQLite. Si falla, `finishSettingsChange` restaura el patrón
   durable anterior; si pasa, confirma el nuevo. Solo después el controlador
   publica el resultado aceptado. Las operaciones siguientes siguen en cola
   y parten de las preferencias aceptadas, conservando tema y movimiento.
4. La finalización es idempotente por ID. Una respuesta perdida no publica
   «guardado» antes de reconciliar. Si el motor se reinicia durante el
   commit o la restauración, se aplica el patrón durable antes de terminar.
   Si el canal no se recupera, la operación sigue pendiente, el inicio queda
   bloqueado y la interfaz muestra que espera almacenamiento/motor; no se
   anuncia un éxito supuesto. No hay garantía de disponibilidad con un canal
   permanentemente perdido; reiniciar el proceso carga lo durable de SQLite.

Tema no necesita reserva y sigue permitido durante una sesión. Movimiento
reducido sí necesita reserva, aunque no cambie el patrón: una sesión activa
o pausada lo rechaza antes de SQLite. La petición de reducción de Android
se respeta siempre, independientemente de la preferencia y del bloqueo.

P12/P13 consultan al motor al entrar, también por ruta directa. Durante la
consulta o si falla se permite solo el tema; Sonido no presenta controles
operativos. Las respuestas de Ajustes actualizan configuración y ciclo,
sin renovar la vigencia ocular ni presentar mediciones de edad desconocida.
Los avisos de consulta fallida usan los componentes existentes B5.2.

Cambiar realmente el patrón invalida el ID de prueba, su reproducción y
«Lo escuché» en Kotlin. Dart exige coincidencia con el patrón durable y
ausencia de cambio pendiente. Volver rápidamente 1→2→1 tampoco rescata la
confirmación del primer 1. Restaurar un patrón tras un fallo no restaura una
confirmación invalidada: hay que repetir la prueba. La vista previa P13 es
solo aceptación técnica de reproducción; nunca acredita audición humana.
La alerta nativa conserva el patrón confirmado de la sesión.

## Comprobaciones ejecutadas

No se repitieron la suite completa, las matrices de contraste ni los módulos
intactos. Los resultados separados siguientes se solapan; no se suman como
un conteo nuevo de la suite completa.

| Comprobación | Resultado y alcance |
|---|---|
| Análisis app y plugin `flutter analyze --no-pub` | Ambos sin problemas; `build/review-5e/analyze-final.txt` y `analyze-plugin.txt` |
| Preferencias reales | 26/26; `test/history/real_preferences_test.dart`, salida `preferences-final.txt` |
| Migración poblada, con aserciones de contenidos | 1/1 adicional dirigida; `migration-final.txt` |
| Preferencias compartidas, fallos, DEMO y transporte afectados | 98/98; `dirigidas.txt` |
| Kotlin sonido y reserva | 9/9: `ExperimentalMonitoringTest.sound_*` y `settings_*`, incluidos dos casos nuevos; `jvm-settings.txt` y XML de Gradle |
| Muestras nuevas y acciones semánticas | 6/6, 12 PNG en `test/goldens/fase5e_review/`; `renders-final.txt` |
| Registro de especificaciones | 500 comprobaciones, OK; `spec.txt` |
| Pigeon | Regeneración `tools/generate_pigeon.py --check` coherente con el contrato y sin diff; `pigeon-check-final.txt` |
| APK release normal | Compilado; identidad, firma, permisos y hash indicados abajo |

Persistencia: SQLite real en disco y conexiones nuevas; guardados sucesivos
y cambios encolados simultáneos de tema, movimiento y patrón dejan la fila
`singleton=1`. Fallos retiran únicamente la preferencia rechazada y conservan
las aceptadas. La reapertura por `bootstrap` carga la base real; la DEMO
mantiene su archivo y preferencias separados. El test de reapertura usa un
doble explícito del motor, porque ahora guardar sonido/movimiento también
requiere aceptación nativa; no se sustituye SQLite por un doble.

Migración: base versión 1 construida con las tres tablas sin modificaciones
de 5D, poblada mediante hechos sintéticos por el importador: **tres sesiones
(finalizada, interrumpida, pausada), cinco marcas y doce recibos con sus
hashes**. Se cierra, abre con v2 y guarda preferencias; se comparan todas
las columnas ordenadas de las tres tablas antes/después. Reimportar los
doce hechos no cambia nada; integridad y claves foráneas correctas. No se
presenta esa fixture como una sesión real de cámara.

Motor: rechazo antes de persistir, error de canal anterior a la reserva,
fallo de SQLite con restauración, ráfagas y vuelta al patrón original,
respuesta perdida después de aplicar y reinicio durante commit/restauración.
Inicio bloqueado durante una escritura retenida; estado Flutter antiguo con
sesión nativa vigente; sesión activa y pausada en Kotlin; patrón nuevo tras
reabrir, respuesta antigua de prueba y alerta con el patrón correspondiente.

Interfaz: inspección visual de las 12 muestras nuevas, claro y oscuro,
360 al 100 % y 320 al 200 %; P12/P13 guardados y bloqueo por sesión en pausa
desconocida al entrar por ruta directa. Sin desbordes de Flutter; las zonas
inferiores de P12 son desplazables, no se fuerza todo el contenido en una
pantalla. Se activan tema, movimiento, Sonido, prueba y Guardar por el árbol
semántico; movimiento bloqueado carece de acción tap. Android pide reducción
y esta se mantiene con «Según Android». Esto no sustituye TalkBack físico.
Los seis goldens 5C preexistentes y los 28 de Claude para 5E **no se tocaron**.

**Aclaración del conteo histórico:** `823 pasan / 7 fallan` fue la ejecución
de Claude antes de adaptar el supuesto de la prueba de la normal sin Ajustes.
La prueba adaptada `demo_flow_test` «modo normal: motor no comprobado,
preparación bloqueada y sin rutas del recorrido» **pasa** en las dirigidas
98/98. Verifica que P12/P13 existen sin datos DEMO y mantiene bloqueado el
recorrido DEMO en la normal. No se infiere ni se anuncia otro resultado
global; los seis goldens conocidos siguen pendientes sin actualizarse.

## Artefactos

Original solicitado, verificado y conservado sin sobrescribir:
`D:/dev/vigia-entrega/vigia-normal-fase5e-release.apk`, 95 319 541 bytes,
SHA-256 `ab582248785dbac59fe174ef11f9d1b1e2fdf93ab7326d94a9a98ccbadc133c0`.
También se preservó en `build/review-5e/vigia-normal-fase5e-claude-release.apk`.

APK reparado, compilado del commit de código
`6e89972626b3a24b714cf39871062d73317aa326`:
`D:/dev/vigia-entrega/vigia-normal-fase5e-codex-release.apk`, **95 335 925
bytes**, SHA-256
`e96f1900c4933198e9b5d63c05b9d45ec9e50003b4f1b2abfa154c54e3a1ee93`.
La copia entregada coincide con `build/review-5e/` y su entrada se añadió a
`D:/dev/vigia-entrega/SHA256SUMS.txt`, conservando las anteriores. Log final:
`build-apk-final.txt`; se comprobó que `lib/`, plugin, Android y dependencias
no difieren del commit al compilar. El primer build intermedio no es el
artefacto entregado. No se instaló este APK ni se abrió un emulador en esta
revisión: comprobación estática, compilación y regresiones automatizadas.

Ambos APK verifican firma v2 y son la variante normal `com.juanrueda.vigia`, «Vigía», versión
0.1.0/1, minSdk 26 y targetSdk 36. La firma es de depuración, no una clave
de publicación: certificado SHA-256
`dd6dbeb4d913a16de01e08990d232b5b8d1bd988f0d4613a86d42f124f27dead`.
Permisos: `android.permission.CAMERA` y el permiso interno
`com.juanrueda.vigia.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`; sin red,
GPS ni micrófono. Detalle de `aapt` y `apksigner` en `build/review-5e/`.

## Límites y siguiente acción

Recorrido real con cámara en **D1 pendiente**: calibración aceptada, sesión
con aviso del patrón guardado, pausa/reanudación, finalización, coincidencia
de las vistas y persistencia de esa sesión tras reiniciar. No se reabrió
webcam ni AVD, no se tomaron imágenes y no se atribuyen rechazos a iluminación.
Siguen pendientes «No evaluable», audibilidad humana de los tres patrones
en alarma y TalkBack físico. Umbrales y reglas oculares intactos.

Se entrega revisión del trabajo de Claude y validación propia de las
reparaciones. El siguiente bloque requiere autorización expresa; no se
ejecuta la secuencia VIG aplazada. La revisión independiente de estas
reparaciones y la prueba física no se dan por realizadas.

Cierre Git: `main`, commit de código `6e89972` y el commit documental que
contiene este archivo; once commits locales sobre la referencia local de
`origin/main`. Sin amend, push ni PR. Fuentes de `docs/source/` intactas.
