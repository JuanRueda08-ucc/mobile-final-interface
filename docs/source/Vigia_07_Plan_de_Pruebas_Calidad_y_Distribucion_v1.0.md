# Vigía · Área 07: plan de pruebas, calidad y distribución

Versión 1.0 · 3 de octubre de 2026, America/Bogota  
Autor del proyecto: Juan José Rueda Viveros  
Estado: especificación para implementación posterior. Esta entrega define ensayos y evidencia; no acredita una app ejecutada, equipos compatibles ni aceptación de la IA.

## 1. Alcance y fuentes del proyecto

Esta área reúne las condiciones para aceptar la interfaz, las funciones, los contratos nativos, la IA, los datos y los paquetes de distribución de Vigía. No crea todavía el repositorio ni modifica Claude Design.

Se consultaron los documentos vigentes completos: PRD v1.1, UX v1.0, arquitectura v1.0 del Área 04, IA v1.0 del Área 05 y datos/privacidad v1.0 del Área 06. Sus criterios mantienen sus IDs y resultados exigidos. El anexo identifica cada criterio; asignar una prueba no significa aprobarlo.

El PRD contiene 96 criterios RF y 30 RNF; UX contiene 66 criterios. También se conservan AT01–AT22, AI01–AI28, EV01–EV13 y DT01–DT24. Los escenarios SC01–SC14, datos DS00–DS08 y tareas UT01–UT08 tienen funciones diferentes: contexto de evaluación, fixtures y tareas de comprensión, respectivamente.

La referencia B5.2 proviene del resumen enviado por el usuario. Sus afirmaciones sobre 120 vistas, 1440 comprobaciones, fuentes y capturas no son resultados independientes de este documento. Antes de usarla como baseline de implementación se registrará el HTML completo y su hash, los tokens, recursos y estados. No se vuelve a diseñar en Claude durante esta etapa.

## 2. Qué significa avanzar y qué significa aceptar

| Etapa | Resultado permitido | Condición de cierre |
|---|---|---|
| E0 · Especificación | Documentación preparada para implementar | Trazabilidad sin criterios omitidos, decisiones y bloqueos identificados |
| E1 · Viabilidad técnica | Ensayo de cámara, modelo y puente nativo | Entrada física, resultados locales identificados, control de recursos y errores; configuración experimental visible |
| E2 · Integración académica | APK de laboratorio con recorrido completo | Funciones e interfaz comprobadas, informe de pendientes; no se denomina V1 terminada si faltan RF/RNF o evaluación IA |
| E3 · V1 funcional evaluada | Primera versión aceptada en condiciones declaradas | Todos los RF/RNF/UX aplicables y sus dependencias aprobados; parámetros calificados, dispositivos y condiciones documentados |
| E4 · Distribución comercial | Candidato de publicación | E3, validación adicional del contexto de uso propuesto, licencias, privacidad, soporte y requisitos de tienda cerrados |

El piloto de cierres visibles del Área 05 no valida sueño fisiológico ni reducción de accidentes. E4 requiere decidir y ejecutar la evaluación del uso real previsto antes de promocionar monitoreo durante conducción. Esa fase aún no tiene protocolo aprobado; su ausencia bloquea la afirmación comercial, pero permite desarrollar E1/E2. No se induce somnolencia en personas que conducen.

Regla de aceptación: un criterio pendiente, bloqueado o sin evidencia nunca se convierte en aprobado por una demostración visual, una captura ni un resumen de otro agente. El funcionamiento de cámara real con parámetros experimentales se identifica como laboratorio.

## 3. Estados de prueba, incidencias y revisión

| Estado | Uso exacto |
|---|---|
| notRun | Caso especificado sin ejecución |
| blocked | No se puede ejecutar o aceptar; registrar dependencia concreta |
| running | Ejecución iniciada, todavía sin veredicto |
| passed | Resultado y evidencia satisfacen todas las condiciones del caso |
| failed | Al menos una condición no se cumple; registrar esperado/obtenido |
| obsolete | Evidencia anterior a un cambio que afecta el resultado; repetir |
| notApplicable | Solo tras decisión de alcance versionada y motivada; no elimina un RF/RNF vigente |

Cada repetición tiene executionId propio. Una repetición posterior no borra la ejecución fallida. Un caso de integración con varias condiciones solo pasa cuando todas pasan. En el anexo, los criterios RF/RNF/UX siguen notRun; fixtures y escenarios figuran planned. La verificación documental de esta entrega se registra aparte.

Severidad de incidencia:

- S0: observación inválida presentada como válida; cámara automática tras reapertura; alerta con callback antiguo; datos borrados que reaparecen; acceso no autorizado o mezcla demo/real. Bloquea aceptar la compilación para uso real.
- S1: crash/ANR, duplicación de sesiones, pérdida silenciosa de datos, aviso confirmado sin reproducción, flujo esencial inaccesible o fallo de un límite temporal obligatorio. Bloquea E3/E4.
- S2: error recuperable con explicación que impide un requisito vigente, incluido texto esencial recortado al 200 %. Bloquea el criterio y por ello E3 mientras no se resuelva.
- S3: discrepancia visual respecto a baseline sin pérdida de función ni incumplimiento medido. Se registra y revisa antes del acabado visual final.

Severidad no sustituye prioridad de trabajo ni redefine RF12 como una prioridad de backlog. Una alerta por cierre prolongado mantiene su nombre funcional. Los S0/S1 se revisan antes de ampliar funcionalidades; no se cierran por ocultar el control que revela el problema.

Cuando una sola persona desarrolla y revisa, queda identificado como autorrevisión. Codex/Claude Code pueden producir pruebas e informes; no sustituyen al participante, anotador, equipo físico ni responsable de entrega. No se inventan revisores externos.

## 4. Entornos y variantes de compilación

| Entorno / variante propuesta | Entrada y uso | Evidencia que puede producir |
|---|---|---|
| Host Dart/Kotlin | DTO, fórmulas, política y reloj controlado | Exactitud determinista, serialización y estados; no cámara física |
| Widget Flutter | UI, semantics y recursos controlados | Layout, navegación, estados y golden; no permisos de Android ni audio físico |
| Emulador Android | Puente, almacenamiento, permisos y versiones de OS | Integración de plataforma; no latencia/cobertura facial del teléfono |
| demo | Datos y persistencia separados, etiqueta de simulación | Recorridos y evaluación visual; no fiabilidad de IA |
| labReal | Cámara/modelo físicos, política experimental identificada | Viabilidad, Q, latencias y ensayos controlados; no aceptación de conducción |
| Instrumentation de laboratorio | APK de pruebas separado, fallos/relojes controlados | Contratos y fallos de los mismos componentes; declarar cualquier inyección |
| candidateReal profile | Misma configuración y fuentes que candidato | Perfil de UI/hilos en teléfono físico |
| candidateReal release | Modelo y recursos reales, sin selectores/inyección | Recorrido y mediciones finales, paquete instalable candidato |

Los nombres de variantes son propuestos para el Área 08. Congelar toolchain compatible al crear el repo; registrar Flutter/Dart, Kotlin, Gradle, AGP, SDK/NDK y dependencias exactas. No fijar versiones de paquetes por memoria ni actualizar a latest durante una campaña.

Flutter integration_test cubre interacción dentro de la app, pero no la UI nativa de permisos/selector [S1]. Usar pruebas instrumentadas/UI Automator para controles del sistema [S2] y comprobación manual para TalkBack, audio y comportamiento físico. Elegir versión estable compatible al implementar, sin copiar una dependencia alpha solo por aparecer en un ejemplo oficial.

La ejecución de scripts host del Área 06 conserva su alcance: comprobación de SQL de referencia. No equivale a haber traducido las tablas a Room/Drift ni probado un teléfono.

## 5. Registro y selección de dispositivos

No se conocen todavía los teléfonos disponibles. Se fijan perfiles de selección y condiciones; sus filas comienzan sin fabricante/modelo asignado. Un perfil vacío no cuenta como equipo probado.

| Perfil | Equipo requerido antes de ejecutar | Ensayos |
|---|---|---|
| D1 | Teléfono Android físico de referencia, cámara frontal y audio funcionales | Todos los recorridos, tiempos, Q/calibración, persistencia y duración |
| D2 | Teléfono físico de otro fabricante y capacidad distinta de D1 | Mismos ensayos del modo que se pretenda declarar compatible |
| D3 | Teléfono físico de la versión Android más antigua que se quiera admitir | Recursos, permisos y mismo paquete; si no existe, no declarar esa versión probada |
| D4 | Teléfono físico Android 14 o posterior, preferiblemente del target de distribución | Servicio camera, permisos durante uso y escenarios de continuidad |
| P16K | Entorno Android de 16 KB con librerías del paquete real | Instalación/carga de Flutter, MediaPipe y SQLite, recorrido y cierre; puede ser emulador para compatibilidad |
| EM | Emuladores de minSdk candidato y fronteras API 31/33/34/target | UI/permisos/schemas y cambios del sistema; complementar, no reemplazar D1–D4 |

Un teléfono puede cubrir varios perfiles si cumple sus condiciones; se necesitan al menos dos modelos físicos de fabricantes diferentes para la primera campaña de compatibilidad propuesta. No se garantiza que esos dos representen todos los Android. Cada modelo declarado compatible pasa todos sus ensayos pertinentes.

minSdk 26 sigue candidato del Área 04. Si no se consigue D3 o una dependencia lo impide, registrar bloqueo y resolver alcance explícitamente. No bajar ni subir minSdk de forma silenciosa. ABI(s) se deciden según dependencias y equipos, y se registran por artefacto. La compatibilidad 16 KB incluye librerías nativas y paquete construido desde AAB, no solo el APK local [S8].

Cada fila de dispositivo registra: deviceId de ensayo, fabricante/modelo, Android/API, buildFingerprint, parche de seguridad, ABI, tamaño de página, RAM reportada, viewport lógico/densidad, tasa de refresco real, cámara/resolución/fps reales, volumen/canal/salida de audio, DND, ahorro de batería, estado térmico disponible, montaje y fuente de alimentación. No registrar IMEI, número telefónico ni cuenta personal.

## 6. Evidencia reproducible

Ruta propuesta futura: qa/runs/<runId>/. Mantener dataset/identidades de participantes y videos de investigación fuera del Git de app. Guardar en el repo fixtures sintéticos, protocolos, manifests y resúmenes no personales. No crear ahora esas carpetas como si el repo existiera.

| Archivo futuro | Campos / contenido obligatorio |
|---|---|
| run-manifest.json | runId, fecha ISO con offset, zona, gitCommit, variante/modo, APK/AAB hash, modelo/hash, política/hash, calibración/config/hash, versiones de DB/canal/export, toolchain, protocolo, deviceId y operatorId |
| results.json | executionId, caseId, criterionIds, precondiciones, fixture/versión/seed, expected, actual, status, timestamps, artifacts y defectIds |
| timings.csv | Captura/recepción/decisión/reproducción en reloj monotónico, origen y unidades; frame/episode/playback IDs de laboratorio |
| frames.csv | build y raster por frame Flutter; configuración y ventana exacta de medida |
| memory.csv | PSS del proceso Android en KiB cada minuto; campos de método/PID y muestras ausentes |
| continuity.csv | Resultado capturado/recibido, gaps, cambios de calidad/ciclo y cortes por escenario |
| screenshots/ y recordings/ | Estado/pantalla, tema, escala, viewport, movimiento; sin caras o alias personales en material compartido |
| inventory.json | Cada recurso/librería/modelo, origen, versión/hash, licencia y atribución requerida |
| compatibility.json | Resultado por equipo/build/modelo/política/modo/condición/escenario y enlace a runId |
| release-manifest.json | Versión, versionCode, packageId, firma pública/hash, paquete/hash, alcance probado, issues abiertos y evidencia que autoriza la etapa |

Un hash ausente impide marcar una ejecución aceptada; no usar hashes sintéticos del Área 06 como identidad del modelo real. No guardar contraseñas, claves de firma, URI privadas de exportación ni payload facial en logs compartidos. Los logs extendidos pertenecen al harness y se desactivan en release.

Los IDs de nueva sesión/episodio varían entre repeticiones. Al comparar fixtures, usar una correspondencia de IDs generados que preserve relaciones y orden; no esperar que dos ejecuciones reutilicen UUID reales. Mantener constantes entrada, reloj controlado, seed y política.

## 7. Reglas comunes de ejecución

Los casos QA01–QA32 heredan íntegramente CA1–CA3 del RF con el mismo número, además de los ensayos listados. QA33–QA40 integran calidad y evaluación. No sustituyen ni debilitan los criterios de las áreas anteriores.

Para cada caso registrar versión, precondiciones, acción, resultado y evidencia. Ejecutar cada fixture determinista tres veces en la misma configuración, sin diferencias de decisiones salvo IDs mapeados. Repetir los recorridos esenciales tres veces por equipo candidato. Un fallo cuenta; no promediarlo con dos éxitos.

Al probar calidad inválida o motor desconectado, comprobar a la vez UI, decisiones, cámara/audio y registros. Una pantalla correcta no demuestra que el motor haya detenido la evaluación. Para errores de persistencia, distinguir estado confirmado en memoria de lo que sobrevivió al reinicio.

Los ensayos de pausa/stop incluyen callbacks de generaciones antiguas. Los fallos controlados se inyectan en harness identificado, nunca mediante un selector oculto distribuido en producción. Captura de video/reproducción se declara; no se rotula cámara física una entrada de archivo.

Cada subcaso de fallo tiene ejecución independiente y restauración de precondiciones. Incluir un control válido después del fallo para detectar recursos retenidos o estado contaminado.

## 8. Catálogo de ensayos funcionales

### QA01 · Incorporación antes de cámara

Instalación limpia, explicación no vista: abrir, continuar, cerrar y reabrir. Comprobar orden explicación→permiso, versión guardada y acceso al mismo texto desde Ayuda. Antes de acción autorizada: cero solicitud/captura y cero sesión. Evidencia: secuencia de UI y contadores nativos. RF01.CA1–CA3; UX01/UX21.

### QA02 · Permiso rechazado, permanente y retirado

Tres instalaciones/estados separados: conceder, rechazar y Android sin posibilidad de repetir solicitud. Probar Abrir ajustes y volver sin cambio y con permiso concedido. La consulta real decide; regreso no inicia sesión. Retirar permiso durante sesión/reanudación verifica error, pausa/medición y mismo ID según contexto. Evidencia: UI Automator/manual, snapshot y registros. RF02; UX02/UX10; AT04.

### QA03 · Rostro y ojos como resultados distintos

Entradas controladas sin rostro, un rostro con ojos no evaluables y uno utilizable. Mostrar mensajes específicos; ninguna causa inválida habilita inicio. Preview procede del propietario nativo único. Captura física complementa fixture; incluir dos caras y ojos ocluidos. Evidencia: estados/eventos con input ID; sin transformar Q inválida en ojos abiertos. RF03; UX03; AI14/AI26.

### QA04 · Prueba sonora y confirmación humana

Antes de cada nueva sesión, intentar confirmar sin reproducción, reproducir con éxito, rechazar haberlo escuchado y reintentar. Inyectar fallo técnico separado. Solo éxito técnico habilita Lo escuché; éxito más confirmación habilita esa puerta de inicio. Cambiar patrón invalida prueba siguiente. No inferir audibilidad por callback. Evidencia: playback, estado del control y observación del participante detenido. RF04; UX04; AT17.

### QA05 · Seis puertas y carrera antes de inicio

Seis subcasos con permiso, cámara, modelo, Q, calibración aplicable o prueba sonora falsos, uno por vez; los demás verdaderos. En todos, botón bloqueado y causa correcta. Luego cambiar una puerta entre habilitación y tap; Kotlin vuelve a validar, sin inicio ficticio. Control con seis verdaderas inicia solo tras confirmación. RF05; UX03/UX06; AT01.

### QA06 · Calibración aceptada, tres rechazos y cancelación

Aplicar Kcal de Área 05 con versión: cantidad/cobertura suficientes y referencias estables; controles de insuficiencia, calidad ocular inválida y referencia inestable; cancelar en cada fase guiada. Solo aceptación persiste CalibrationSnapshot completo y hash. No persistir una referencia parcial como accepted. Comprobar frontera AI11 y probes/reapertura AI13. Evidencia: DTO, Room/Drift y registros; calibración no suma sesión. RF06; UX05; AT05; DT21.

### QA07 · Cambio de montaje y snapshots históricos

Aceptar referencia, marcar Cambié la posición y comprobar bloqueo/Repite calibración. Probar modelo/esquema incompatible separado. Crear sesión válida, recalibrar después y releer versión/hash/snapshot anterior: idénticos. No exigir detección automática de movimiento no prevista. Evidencia: snapshots/DB y UI de preparación. RF07; UX05; AT05; DT03.

### QA08 · Inicio idempotente y estado pendiente

Diez taps en un segundo y diez comandos diferentes sobre preparación consumida: una sesión confirmada. Repetir commandId con payload idéntico devuelve mismo efecto/resultado; distinto payload rechaza. Retrasar respuesta 5 s: confirmar snapshot, sin convertir demora en rechazo o cancelación. Inyectar rechazo: no Activa ficticia. Evidencia: comando, estado/revision e IDs nativos/historial. RF08; UX06; AT01/AT02.

### QA09 · Cámara e IA locales sin red

Datos móviles y Wi-Fi desactivados antes de abrir: preparar, calibrar, diez minutos de cámara física y cerrar. Conservar modelo/hash, timestamps y resultados de imágenes reales. Ensayo separado de fixture determinista activa H para lógica offline; no sustituye los diez minutos físicos. Auditoría con red disponible verifica ausencia de transmisiones de imágenes/observaciones y ausencia de cargas de recursos externos. RF09; RNF01; AT18; QA37 complementa.

### QA10 · Ciclo, medición y señal independientes

Recorrer todos los ciclos y cuatro estados de medición; inyectar usable/noPersistentSignals, warning, H, limited/unavailable. Cambio visible ≤1000 ms desde recepción del evento UI; no desde captura. Q inválida exige notEvaluable, nunca Seguro ni porcentaje de fatiga. Evidencia: snapshot/recepción y frame visible con reloj correlacionado. RF10; UX07; AT07.

### QA11 · Advertencia temporal W

AI15–AI17: secuencia positiva de seis bloques, ratio/control de runs, salida de W y persistencia 499/500 ms. Verificar motivo/política, episodio y sonido ≤500 ms desde decisión en ensayo de dispatch físico/harness declarado. W no lista antes de completar ventana; no sustituir comparación temporal por número de frames. RF11; UX08; QA35/QA39 completan evaluación física y latencias.

### QA12 · Cierre prolongado H

AI03–AI07: ratios 0,55/0,550001, cierre válido 1400/1500 ms, sin bostezo, muestra inválida y gap 150/151 ms. Solo continuidad válida activa H y motivo específico; alerta/episodio no esperan W lista. Audio ≤500 ms desde decisión. SC13 comprueba que Q no rechaza párpados cerrados válidos. RF12; UX08; AI12/AI27; QA39 mide señales físicas.

### QA13 · Episodio, escalada y repeticiones

AI18–AI21: mantener H/W crea un ID; H que entra durante advertencia escala mismo episodio y despacho inmediato. Repetición usa intervalos desde intento, incluido fallo; no un sonido por frame. Eend 1999/2000 ms solo con apertura válida. Corte deja signalEnd null; nueva evidencia tras recuperación crea otro segmento/episodio. Evidencia: episodios/transiciones/playbacks y secuencias esperadas. RF13; EV12.

### QA14 · Pérdida, watchdog y resultados atrasados

AI06/AI08/AI09: Q inválida corta; silencio a 150 ms no vence G, a 151 limited y a 750 unavailable según política, con deadline scheduler ≤100 ms. Edad de captura 750 vigente y 751 descartada. Registrar recepciones/capturas, gaps y motivos; UI cambia ≤1 s desde decisión. No mantener Sin señales persistentes en una observación inválida. RF14; UX09; SC08–SC11.

### QA15 · Recuperación sin unir cierres

AI10: 999/1000 ms y cantidad mínima de muestras de Krecover, después de pérdida. Permanece no evaluable hasta cumplir; nueva continuidad C comienza en el límite de recuperación. Dos cierres separados por inválida no se suman. Ventana W se reconstruye del nuevo segmento. Evidencia: spans, estados y ausencia de alerta vieja. RF15; UX09; AT07.

### QA16 · Pausa confirmada y análisis detenido

Diez solicitudes durante transición: una pausa. Retrasar respuesta 5 s y devolver snapshot Activa, DS07: pendiente, sin intervalo ficticio. Tras confirmar paused, inyectar una secuencia H y callbacks antiguos: cero nueva decisión, episodio o aviso. Pausa no entra en evaluable/noEvaluable. RF16; UX10; AT03/AT08; AI22.

### QA17 · Reanudación del mismo ID

Reanudar con condiciones válidas; tres controles separados de cámara, modelo y Q inválidos. Rechazo conserva paused e intervalo abierto. Sin permiso ofrece Ajustes; volver no reanuda. Calidad y confirmación nativas cierran pausa, mismo sessionId y ventanas nuevas. Repetición de comando no cierra dos veces. Evidencia: snapshots y DB; callbacks antiguos descartados. RF17; UX10; AT04.

### QA18 · Finalizar y liberar recursos

Finalizar varias veces crea un cierre; Finalizando hasta confirmación. A los 2 s tras confirmación: contador de frames detenido, sonido cancelado, preview/cámara liberados y servicio de esa sesión ausente. Diez ciclos de inicio/cierre conservan propietario único. Inyectar fallo durable: Registro incompleto y cierre en memoria diferenciado de DB. RF18; RNF06; UX12; AT19.

### QA19 · Muerte de proceso y extremo desconocido

Terminar proceso con active y con paused por separado; reabrir. Solo sobreviven commits; interrupted, extremo desconocido y cero tiempo inventado hasta recuperación. No cámara ni sesión automática. No equiparar muerte de proceso con desconexión del canal ni swipe de recientes con force-stop; registrar mecanismo. Evidencia: DB antes/después, snapshot y recursos. RF19; UX13; AT11/AT20; DS02.

### QA20 · Navegación y pérdida del canal

P03↔P06 conserva motor e ID. Con active, paused y estado incierto, intentar las nueve rutas P09–P11/P13–P18: bloqueadas. P08/P12 cumplen las restricciones UX, sin abrir acciones incompatibles. Cortar canal con motor vivo: UI desconectada, inicio bloqueado; reconectar importa evidencia. Entregar eventos de instance/revision viejos: no retroceso. RF20; UX01/UX11; AT06/AT16.

### QA21 · Resumen con evidencia incompleta

DS01–DS04, lotes pending y pérdida de escritura. Comparar UI, consulta y exports: mismos cuatro tiempos, cobertura y conteos; paused/unknown no cambian denominador. DS01: 960 s, 83,3 %, dos episodios; DS02 no extrapola fin; denominador cero→No disponible. Incompleto/pending no se rotulan completos. Evidencia: filas, sumas exactas y presentación. RF21; UX12/UX14; AT14; DT10.

### QA22 · Historial, reinicio, vacío y fallo

Dos sesiones con fechas distintas más interrupted: reabrir conserva IDs/orden y estados. DS00 lectura exitosa muestra vacío; fallo de lectura muestra error/Reintentar. Selección abre el ID correcto. Fixture de 101 sesiones y empate de fechas valida páginas de 50, cursor start/id y ningún duplicado. Evidencia: consulta y navegación. RF22; UX15; Área 06.

### QA23 · Detalle de episodio y datos desconocidos

Elegir episodio con cierre normal y otro cortado: categoría/motivo/fecha/offset/calidad/versiones correctos. Duración sin fin es no disponible; no cero. Aviso técnico no se presenta como somnolencia. No buscar ni mostrar capturas que no se guardaron. Evidencia: DTO, UI y campos nullable. RF23; UX15; DT14.

### QA24 · Valoración separada

Sesión finalized: guardar useful, sustituir por notPerceived/unsure y reabrir; conserva episodio/política/evidencia. Padre active, paused o interrupted y otra sesión vigente bloquean edición según UX/dominio. Sin campo libre añadido. Evidencia: feedback, inmutabilidad y DB tras reinicio. RF24; UX16; AI25; DT05.

### QA25 · Siete y treinta fechas locales

Congelar hoy/zona y construir sesiones antes, dentro y exactamente en límites. Filtrar por inicio, mostrar rango exacto y separar policyVersion. DS03: 4,0/h y 6,0/h; coberturas 75/50 por grupo. Agregación suma tiempos, no promedia porcentajes. DS04 cero→No disponible; sin diagnósticos/rankings. Evidencia: consultas y cálculos en misma proyección. RF25; UX17; AT14.

### QA26 · JSON, dos CSV y escritura parcial

Congelar selección, exportar JSON y ambos CSV; parser de prueba compara IDs/FK/conteos/nulls y encabezados 34/31 columnas. Cero episodios→header; cero sesiones bloquea antes del selector. Separar cancelar, fallo de cierre y caída tras cierre externo antes de commit→unknown. DS05 partial/D08 reintenta solo archivo pendiente, mismo snapshot/exportId; TTL 24 h invalida. Evidencia: bytes/hash y estados; RF26; UX18; DT14–DT17/DT24.

### QA27 · Borrado por etapas sin resurrección

Cancelar confirmación no cambia DB; confirmar elimina alcance en Room/Drift/staging. Inyectar caída/fallo en intentSaved/nativeDeleted/localDeleted/contextReset/complete según scope; reintentar mismo operationId/UUID. Lote antiguo no repone datos. Borrar todo elimina alias/calibración, conserva solo preferencias permitidas/barreras mínimas. Active/paused/incierto bloquean; no éxito parcial. Copias externas permanecen. RF27; UX19; AT12; DT02/DT12/DT13/DT17.

### QA28 · Retención, igualdad y zona

Opciones 30/90/180/NULL, inicial 90. DS08: 01/10/2026 Bogotá, N30→02/09 00:00−05:00; anterior elimina, igual conserva. Cambiar zona y congelar corte/IDs; conjunto que cambia exige nueva confirmación. Active/paused excluidas y cleanup diferido; fallo no afirma completitud. Abrir y cierre/consolidación disparan limpieza cuando permitido. RF28; UX20; AT13; DT11.

### QA29 · Preferencias y política inmutable

Claro/Oscuro/Sistema sobreviven reinicio y reaccionan al sistema cuando corresponda. El patrón procede de catálogo empaquetado y vuelve a exigir prueba audible. Sesión conserva modelo/política; no sliders ocultos de Tclose ni modo operativo con alerta H desactivada. Comprobar cada control habilitado/error, no un toast ficticio. RF29; UX21; DT03; QA34.

### QA30 · Seis temas de Ayuda

Abrir soporte/encuadre, iluminación/ojos, calibración, sonido, interrupciones y datos/exportación sin red. Cada uno muestra causa/acción/reintento; enlaces reales a Ajustes/preparación cuando corresponda. No crea sesión/cámara. Durante vigente, solo mensaje técnico breve conforme a guardas. Evidencia: recorrido y contador de recursos. RF30; UX21.

### QA31 · Importación, ACK y fallos de almacenamiento

Fixture 10 sesiones/100 episodios, importar tres veces: mismos conteos y relaciones. Caer después de commit antes ACK; versión posterior conserva recordId distinto y no desaparece con ACK anterior. Hash distinto, versión desconocida y gap sin prueba no se ACKean. Agotar buffer 256 registros/1 MiB: recordLossSummary, incompleto, sin reconstrucción. Migración real conserva datos/barreras; no fallback destructivo. RF31; AT09/AT10; DT07–DT09/DT20/DT23.

### QA32 · Demo aislada y capacidades reales

Demo rotula simulación en monitoreo/historial/exportación, con base distinta. Auditar candidateReal: sin selector/provider de fixtures ni datos de test personales. Contrato/esquema/plataforma no soportados produce error y no habilita mutaciones. iOS/flotas/GPS/cámara externa no aparecen operativos. Evidencia: recursos/binario/configuración y recorrido M01–M10. RF32; RNF10; UX22; AT18/AT22; DT19.

## 9. Ensayos de calidad y evaluación

### QA33 · Accesibilidad y movimiento reducido

Para P01–P18 y D01–D08, registrar todos los estados del inventario vigente, ambos temas y escalas 100/200 %. Viewports de referencia 320/360/412 unidades lógicas; no son píxeles físicos. Con 120 estados, matriz base=120×3×2×2=1440, condicionada a confirmar ese inventario. Cada estado nuevo amplía la matriz; no declarar 1440 ejecutados aquí.

Aceptación: ninguna etiqueta/acción esencial cortada o inaccesible; área táctil ≥48×48; contraste de texto ≥4,5:1 incluso sobre degradado. Medir par real más desfavorable y registrar foreground/background. Guideline API y scanner ayudan [S4], pero su éxito no reemplaza el umbral de Vigía ni TalkBack.

TalkBack físico: nombre, función, estado y orden de foco; diálogos mantienen foco y vuelven al disparador; no se anuncia cronómetro cada segundo ni cada frame. Una transición de calidad anuncia causa comprensible una vez, sin depender del color. Registrar gestos y resultado, incluida cámara/preview nativos. Pantalla bloqueada pertenece a QA36, no a prueba de semantics Flutter.

Movimiento reducido activado desde el sistema: detener aura/loops y efectos espaciales no esenciales; estados/alertas se actualizan igualmente, sin esperar animación. Ensayar cambio del ajuste con app abierta, cerrar/reabrir y transición mientras llega una alerta. La navegación al 135 % no satisface el ensayo de 200 %; resolver layout en implementación. RNF03; UX22.

### QA34 · Acabado visual, recursos y animaciones

Baseline congelado: HTML completo B5.2, tokens y componentes exportados, licencia/procedencia de fuente/iconos, mapa de estados y motion. Graphite vigente del resumen: fondo #24232B; superficie #302E39; agrupación/nav #3B3845; textos #F7F5FA/#CEC9D5. Usar estos como referencia declarada, no como medición del archivo no inspeccionado.

Para cada token de tipografía registrar familia local, archivo/hash, peso, tamaño, altura de línea y fallback. El APK usa fuentes empaquetadas: instalación/primer inicio y todos los textos con Wi-Fi/datos apagados; ningún peso depende de Google Fonts. Si falta el archivo o licencia, el recurso sigue bloqueado; no llamar Inter a otra fuente sin decisión documentada.

Componentes: comparar botones, cápsulas, tarjetas, diálogos, navegación, vacíos/errores, aura y charts con mismo estado/ancho/tema. Cero uso de valores visuales divergentes sin token/decisión. Golden controla geometría/tokens y enmascara solo preview, timestamps e IDs variables, conservando layout/semantics. No usar un porcentaje global de píxeles para ignorar texto recortado.

Inventario motion: componentId, trigger, propiedades, duración/easing/loop, respuesta a reducción y estados interrumpidos. Antes de aceptar animación, ambos extremos y progreso real observable; tap/doble tap, navegación atrás y alerta durante transición no duplican acciones. Monitoreo mantiene fondo estable y presenta señal inmediatamente; no espera fin de entrada/loop. Duraciones/easing se extraen del baseline aprobado: si faltan, quedan blocked y se documentan en handoff, sin inventar otro diseño aquí. Perfil de aura normal/reducida bajo QA35. Registro de licencias bajo QA40.

### QA35 · UI, hilos, latencias y estabilidad de 60 minutos

Por equipo/modo candidato, tres ejecuciones independientes en teléfono físico. Registrar potencia/carga, batería, brillo, refresco real, montaje, resolución/fps entregados, temperatura/sensor o No disponible. No aceptar debug/emulador como rendimiento final [S3]. Profile mide UI/hilos; release verifica comportamiento final del mismo commit/configuración. Conservar ambos hashes, sin llamar idénticos a binarios diferentes.

UI RNF02: 60 s de monitoreo a 60 Hz, build y raster por separado, p95≤16,7 ms cada uno. Registrar ventanas adicionales de navegación/animación para revisión visual. Inferencia/características fuera de hilo UI Flutter y principal Android; trace debe identificar threads y trabajo, no solo aspecto fluido.

Inferencia RNF07: ≥1000 resultados por ejecución/mode; captura→resultado facial p95<200 ms. Relacionar timestamp de captura con reloj monotónico Android mediante método documentado; si no se puede, latencia queda blocked. No usar timestamp de preview. Registrar capturados/enviados/procesados/descartados y resultados rechazados, sin podar outliers después de medir.

Sonido: ≥30 intentos de entrada/repetición por categoría por salida declarada, con harness de componentes identificado o señales físicas registradas; medir decisión→inicio técnico de reproducción, todos ≤500 ms. Reportar callbacks faltantes como fallo/unknown, no excluirlos. Prueba de componente no acepta por sí sola RF09 o evaluación de señales físicas. Comprobar audio externo si se pretende declarar soportado; V1 inicial puede declarar solo altavoz probado. DND/silencio y audio focus no se eluden; informar limitación.

Duración RNF09: tres sesiones de 60 min por equipo/modo declarado, cero crash/ANR y registro de restricciones/interrupciones. PSS Android en KiB cada minuto; comparar media de diez muestras en [10,20) min con diez en [50,60) min: final≤1,20×base. Faltar muestras impide aceptar ese cálculo. Registrar también picos; no usar solo heap Dart. Ante PID nuevo la ejecución está interrumpida, sin combinar procesos. Finalizar y validar recursos/resumen. Sesenta minutos no acreditan una jornada.

Método de percentil: ordenar n muestras y usar nearest-rank, posición ceil(0,95×n), base 1; no promediar p95 de runs. Cada run cumple por separado. Si hay menos de 1000 resultados o no se pudo medir un reloj, no convertirlo en passed por media favorable.

### QA36 · Continuidad por equipo y escenario

Cinco escenarios RNF04 separados, cada uno cinco minutos y tres repeticiones: P06 visible, otra pantalla permitida de la app, otra app, bloqueo y llamada entrante. Iniciar explícitamente desde Activity visible, luego cambiar contexto. Para llamada registrar inicio/contestación/final y ruta de audio, sin guardar número. No solicitar permisos telefónicos para observar la prueba.

Registrar capturas/recepciones, gaps>Gmax, gaps≥Tstale, ciclo/medición, avisos/ID y restricciones. Etiqueta continua solo si hay evidencia de captura/resultados durante todo el escenario sin corte de medición; una Q inválida también invalida afirmar evaluación continua. Captura y evaluación se reportan por separado. Si un escenario suspende cámara, clasificarlo no soportado con degradación correcta, sin prometer continuidad general.

Añadir permiso retirado, muerte de proceso, force-stop, reinicio del teléfono, cámara ocupada y cambio de orientación/insets. No relanzar cámara de forma automática tras arranque o reapertura. Android impone reglas de servicio y permiso durante uso [S5]; declarar camera/permiso correspondiente y probar target efectivo, sin arrancar desde background/BOOT para esquivar la restricción.

compatibility.json liga cada resultado a equipo/Android/build/modelo/política/modo/condición. Cambiar cualquiera invalida o requiere revisión de esa fila; no transferir el resultado de D1 a D2.

### QA37 · Privacidad, backups y almacenamiento físico

Con registros sintéticos, auditar manifest fusionado, SDKs, assets y tráfico al abrir/preparar/monitorear/revisar/exportar. No fotos/video/landmarks persistidos, GPS/micrófono/contactos ni transmisiones automáticas. Inspeccionar archivos propios/DB/staging/logs antes y después; no basta que la UI no muestre una foto.

JCS: vectors de RFC8785 en Dart/Kotlin y hash idéntico de misma entrada; números/unicode/claves duplicadas/versiones inválidas y límites JSON del Área 06. No sustituir por sort_keys. Backups cloud/restauración y D2D ejecutados por equipo/plataforma declarados no recuperan historial/calibración/staging; XML es evidencia de configuración, no del resultado. Mantener garantía limitada a pruebas, sin prometer inmunidad forense.

Pruebas de WAL/checkpoint y falta de espacio con harness: datos coherentes, error visible, ACK solo después de commit. Borrado lógico revisado en ambos almacenes/cachés; no afirmar destrucción de flash. Migraciones solo cuando exista cambio real y ruta distribuida; n/a inicial no acepta automáticamente toda futura migración. AT21; DT18/DT21–DT24; Área 06.

### QA38 · Comprensión con cinco participantes

Cinco adultos con experiencia de conducción y uso Android, detenidos/escritorio, sin relación necesaria con quienes anotan IA. Ejecutar UT01–UT08 con consignas del Área 02. No señalar botones; ayuda→Con ayuda, fallo→No completada. Registrar pasos, errores, tiempo observado y frase de interpretación, sin mezclarlo con latencia de motor.

Aceptar objetivos formativos: ≥4/5 sin ayuda en UT01/UT04/UT05/UT06/UT07; 5/5 interpretación correcta en UT02/UT03/UT08. Cualquier confusión sobre aptitud, no medición o copias externas obliga corrección y repetición de tarea afectada con cinco participantes en nueva ronda; registrar reutilización de personas y posible aprendizaje. No ocultar primeras respuestas.

La prueba se puede ejecutar en prototipo con etiqueta de simulación y después repetir en Flutter/Android. TalkBack sigue su ensayo propio; incluir una persona usuaria de lector cuando se pueda y reportar si no se consiguió. Esa ausencia impide afirmar validación con usuarios TalkBack, aunque un operador haya probado la herramienta. UT no acredita sensibilidad del detector.

### QA39 · Evaluación IA y anotación independiente

Ejecutar EV01–EV13 y SC01–SC14 según Área 05, sin redefinir ground truth desde EAR o decisiones del motor. Dos anotadores sin overlays/ratios y un tercero para discrepancias; acuerdo de estados ≥90 % y mediana de diferencia de límites≤100 ms. Fallo del acuerdo exige revisar protocolo y repetir anotación, no declarar preciso el benchmark.

Piloto: 30 adultos, split por persona 15 desarrollo/5 validación/10 test; mínimo 60 referencias H y 60 W en test, ≥6 por categoría/persona; ≥20 h negativas evaluables y ≥1 h/persona. Por condición declarada: ≥10 eventos/categoría y ≥2 h negativas. Conservar exposición total/no evaluable/unknown y composición real, sin afirmar representatividad universal.

Aceptación candidata de señales: H sensibilidad a tiempo≥0,95 y precisión≥0,90; W sensibilidad/precisión≥0,85; FP H≤0,20/h y W≤1,00/h negativa evaluable; cobertura frente a humanos≥0,90 agregada y≥0,85 por condición; rechazo por Q de ojos cerrados válidos≤5 % por condición; p95 elegible→decisión≤1000 ms. Referencias tardías cuentan FN conforme al Área 05. No calcular latencia solo en aciertos sin reportar misses.

Publicar denominadores/desgloses por persona, condición y equipo, eventos emparejados/FP/FN, cobertura y limitaciones. Los mínimos agregados y gates por condición que existen en Área 05 se respetan; no imponer después del test un nuevo umbral por persona ni esconder una condición fallida detrás de un promedio. El conjunto de test no ajusta parámetros; cambio de política requiere otra versión y test independiente.

Emparejamiento por recordingId/categoría: referencias ordenadas por eligibleAt, activación todavía no asignada en [eligibleAt−100 ms, eligibleAt+1000 ms], límites inclusivos. Elegir menor diferencia absoluta; empate por timestamp menor y luego ID lexicográfico. Reproducciones no son activaciones nuevas. Toda activación no emparejada en tiempo anotable cuenta FP para precisión; FP/h negativa usa únicamente intervalos negativos. Unknown se reporta como no verificable, sin etiqueta inventada. FN incluye eventos anotables que el motor rechazó por Q. p95 de latencia elegible se calcula sobre matches y se publican FN/tardíos junto a él, sin ocultarlos.

Incertidumbre según Área 05: Wilson 95 % descriptivo para proporciones y bootstrap por participante, 2000 remuestreos con seed registrada, percentiles 2,5/97,5 para métricas agregadas. No tratar frames como personas independientes. Con cero FP, mostrar exposición y referencia superior unilateral −ln(0,05)/horas bajo hipótesis Poisson explícita; no reportar incertidumbre cero por bootstrap degenerado.

EyeVisibilityGate pendiente es dependencia real: SC08/AI26 no pasa porque landmarks parezcan plausibles. Cierres voluntarios detenidos validan señales definidas, no fatiga clínica ni una cámara en cualquier cabina. La publicación comercial exige la fase adicional de E4; no cambiar qualificationStatus a accepted por pasar fixtures.

EV03 exige aceptación de ≥90 % de calibraciones con datos aptos, con denominadores por condición y ningún control rechazado guardado como accepted. En cada escenario de oclusión, tasa de usable en frames humanos unknown≤5 %; oclusión sostenida >1000 ms exige invalidación≤1000 ms desde inicio visible anotado. Luego se verifica deadline UI de RF14. No aprobar el gate por ausencia casual de H/W si siguió presentando la imagen ocluida como utilizable.

### QA40 · Artefactos, trazabilidad y distribución

Auditar paquete candidato real: modelo/recursos incluidos, sin fixtures/selectores o logs personales, licencia de cada recurso y firma verificable. Instalar desde cero offline y actualizar desde cada versión distribuida sin pérdida de datos/barreras; first release registra instalación limpia, las rutas futuras siguen pendientes hasta existir.

Validar 16 KB y librerías/ABIs, permisos/camera foreground service y target vigente de tienda, assets/listing sin funciones futuras ni promesas de aptitud. Cada criterio RF/RNF/UX tiene resultado y evidencia del candidato; AT/AI/EV/DT relevantes ejecutados. Ninguna captura HTML acepta un permiso/audio/latencia real.

Completar manifests/reporte/release notes y matriz de compatibilidad, revisión por Juan José y decisión de etapa. Preparar el paquete no publica ni envía invitaciones. Las decisiones de cuenta, packageId definitivo y firma se cierran al preparar distribución; no inventar credenciales/identidad comercial ahora. La sección 15 define puertas concretas.

## 10. Matriz de fallos y puntos de caída

| Punto de fallo | Ensayo | Estado/datos que deben quedar |
|---|---|---|
| Antes de confirmar inicio | QA05/QA08 | Preparación/error; ninguna sesión Activa ficticia |
| Comando pendiente 5 s | QA08/QA16/QA17 | Consultar snapshot, mantener incertidumbre; cero transición fabricada |
| Callback tras pause/stop | QA16–QA18 | Generación vieja descartada; cero alerta o mutación actual |
| Journal no escribe | QA18/QA31 | Incompleto, buffer limitado y resumen de pérdida; avisos no esperan Drift |
| Commit Drift antes ACK | QA31 | Releer/deduplicar, mismos IDs; no pérdida por ACK prematuro |
| Gap o hash inválido | QA31/QA37 | Error/pendiente, sin ACK de hecho no validado |
| Muerte de proceso | QA19 | Solo evidencia durable, interrupted, final desconocido |
| Etapas de borrado/reset | QA27 | Barreras y operación pendiente; retry mismo ID, sin resurrección |
| Archivo externo cerrado antes commit | QA26 | unknown; no éxito inventado ni sobreescritura automática |
| Un CSV escrito y otro cancelado | QA26 | partial/D08, mismo snapshot al reintentar pendiente |
| Caducidad/borrado de staging | QA26/QA27 | expired/invalidated, no reconstrucción de datos eliminados |
| Primera base migrada y segunda falla | QA31/QA37 | Conservar versiones/operación; no drop/recreate ni restore silencioso |

Inyectar la caída inmediatamente antes y después del efecto durable listado, con executionId distinto. Guardar snapshot/DB previa y posterior; reinicio real del proceso cuando el caso lo exige. Una excepción capturada sin reinicio no sustituye el ensayo de caída.

## 11. Campaña y controles de regresión

Orden de implementación/verificación propuesto: host/contratos → bridge/cámara real → política/calibración → persistencia/recuperación → flujo completo → diseño/accesibilidad → rendimiento/compatibilidad → usuarios/evaluación IA → paquete candidato. Detener expansión cuando fallan invariantes del motor o datos; resolver antes de recopilar evidencia sobre una base incorrecta.

| Cambio | Repetir antes de aceptar |
|---|---|
| Token/typography/layout/motion | QA33/QA34, flujos afectados; QA35 si altera costo de render o monitoreo |
| Navegación/comando/estado | QA05/QA08/QA10/QA16–QA20 y AT afectados |
| Modelo/Q/calibración/política | AI completo, QA03/QA06/QA07/QA11–QA17/QA35/QA39, compatibilidad afectada |
| Journal/historial/export/borrado | QA19/QA21–QA28/QA31/QA37 y DT afectados; datos migrados |
| Dependencia/SDK/target/servicio/audio | Puente, QA09/QA18/QA32/QA35–QA37/QA40 en dispositivos afectados |
| Empaquetado/firma/recurso | QA09/QA32/QA34/QA40 y instalación/actualización de candidato |

Antes de release, suite determinista completa sin omisiones y smoke E2E en cada equipo/condición declarada. Las campañas físicas caras se repiten cuando el cambio puede invalidarlas; justificar reuso de evidencia por commit/componente. No repetir indefinidamente pruebas ya suficientes sin cambio o incertidumbre nueva.

CI futura: formato/análisis, unitarias Dart/Kotlin, DTO/JCS, widgets/semantics/goldens controlados, Room/Drift instrumentado en emulador y revisión de recursos/fixtures del release. El pipeline no produce un passed de TalkBack, audio físico o IA anotada. Credenciales de firma se cargan fuera del repo y nunca en logs.

No se fija una cobertura de líneas decorativa. El objetivo medible es 100 % de criterios aplicables con casos y evidencia; ramas de decisión temporal, rechazo de entrada, idempotencia y recuperación tienen controles positivo/negativo/frontera. Cobertura de líneas, si se obtiene, complementa esa matriz.

## 12. Puertas de aceptación

| Gate | Condición comprobable | Bloquea |
|---|---|---|
| G01 · Integridad de especificación | Cada ID fuente aparece una vez en registro, ≥1 QA asignado, sin referencia inexistente; estados reales | E0 |
| G02 · Cámara y contratos | Inicio/pausa/cierre/recuperación/guardas, AT deterministas; cámara física y dueño único | E1/E2/E3 |
| G03 · Política implementada | AI01–AI28 tres repeticiones coherentes, metadatos/fixtures identificados | E2/E3 |
| G04 · Datos y fallos | DT pertinentes, etapas de borrado/ACK/export, cierres desconocidos y snapshots coherentes | E2/E3 |
| G05 · Interfaz final | QA33/QA34, cero incumplimiento esencial al 200 %, recursos locales/licenciados y estados completos | E3/E4 |
| G06 · Dispositivos y desempeño | QA35/QA36 en cada combinación declarada; límites y continuidades explícitos | E3/E4 |
| G07 · Comprensión | UT01–UT08 cumplen metas formativas, confusiones señaladas corregidas/reprobadas | E3/E4 |
| G08 · Señales IA | EV01–EV13, mínimos/dataset y Q/visibilidad calificados; SC sin normalidad ficticia | E3/E4 |
| G09 · V1 completa | Los 192 CA RF/RNF/UX vigentes aprobados, dependencias cerradas; sin S0/S1 ni criterio vigente fallido | E3 |
| G10 · Publicación | E3, contexto de uso E4 validado, licencias/privacidad/soporte/store y paquete/firma aprobados | E4 |

E2 puede entregarse con informe de gates pendientes; no se llama E3 ni V1 terminada. Los criterios de migración sin ruta distribuida se documentan como ensayo futuro, no como excusa para omitir protección de datos en primera versión. Un cambio de alcance requiere nueva versión del PRD/UX; no convertir RF de V1 en notApplicable dentro de un reporte.

## 13. Entrega académica y demostración

Paquete de entrega: APK(s) identificados demo/labReal o candidateReal según etapa, hashes y versiones, instrucciones de instalación/uso detenido, informe de pruebas con estados, capturas/video de recorrido, recursos/licencias y README de reproducción. No entregar un archivo HTML como si fuera APK.

Guion verificable: incorporación/permisos → preparación con bloqueo y calibración → prueba de sonido → inicio confirmado → advertencia/H o simulación rotulada → pausa/reanudación → pérdida de medición → cierre/resumen → historial/detalle/valoración → exportación parcial → borrado. Mostrar tema claro/oscuro, texto 200 % y reducción de movimiento. Los eventos que usan fixture se identifican verbal y visualmente; separar la demostración de inferencia física.

El informe a la materia describe decisiones de composición, tipografía, tokens, interacción, estados, accesibilidad, animación y pruebas de comprensión con sus resultados. No inventar nota/rúbrica del profesor; incorporar la rúbrica cuando se entregue. La excelencia visual se revisa con baseline/componentes y personas, sin prometer que un checklist equivale a una interfaz perfecta.

## 14. Distribución Android y políticas verificadas

Consulta oficial realizada el 3/10/2026. Estas reglas pueden cambiar y se revalidan al preparar el envío; no sustituyen verificar la cuenta y Play Console reales.

Para nuevas apps/actualizaciones móviles, la página oficial consultada exige target Android 16/API 36 o superior desde 31/08/2026 [S6]. Propuesta de distribución: targetSdk≥36 y compileSdk compatible con toolchain/dependencias; minSdk sigue independiente y candidato. No basar este proyecto nuevo en una extensión de plazo de una app existente ni en reglas de Wear OS.

Una cuenta personal creada después del 13/11/2023 está sujeta al ensayo cerrado con al menos 12 testers inscritos continuamente durante 14 días antes de solicitar acceso a producción [S7]. No se conoce tipo/fecha de cuenta de Juan José; aplicabilidad queda pendiente. Este requisito de tienda no sustituye los cinco usuarios UX ni los participantes de IA. No reclutar ni invitar testers sin instrucción explícita.

El plan incluye APK firmado para instalación académica y AAB firmado para candidato Play, con Play App Signing cuando corresponda [S9]. Registrar certificados públicos/hashes; las claves y passwords quedan fuera del repo. No asegurar actualización cruzada entre APK académico y Play si difieren firmas/packageId; probar ruta concreta o separarlos claramente.

Google Play solicita declaración de tipos de foreground service y demostración de su función [S10]. Para Vigía, documentar inicio explícito y ciclo del servicio camera, interrupción y cierre. No solicitar full-screen intent por suponer que una alerta de conducción lo autoriza. Elegir permisos mínimos y revisar manifest fusionado/behavior.

Data safety y política pública de privacidad se preparan según comportamiento efectivo de app/SDKs [S11]. No marcar automáticamente No recopila por analizar localmente sin auditar SDKs/transmisiones/exportación. La privacidad técnica del Área 06 es entrada; identidad/contacto del responsable, URL y declaraciones finales siguen pendientes hasta distribución. No se han publicado páginas ni formularios.

16 KB: inspeccionar ELF/ZIP y ejecutar paquete en ese entorno siguiendo documentación [S8], con librerías Flutter/MediaPipe/SQLite reales. El gate de Vigía exige prueba antes de candidato Play, independientemente de fechas transitorias de la tienda. No afirmar compatibilidad por conocer versión de Gradle solamente.

## 15. Checklist de candidato y operación posterior

| ID | Evidencia requerida para cerrar | Estado inicial |
|---|---|---|
| RL01 | PackageId/nombre de distribución/versionCode definidos; versión y hash del APK/AAB | pending |
| RL02 | Firma válida y custodia/recuperación de clave documentadas; actualización probada para ruta elegida | pending |
| RL03 | Modelo/Inter/iconos/sonidos/SDKs con procedencia/licencia/atribución; recursos realmente incluidos | pending |
| RL04 | Manifest final, permisos mínimos, target vigente, ABIs/16 KB y tipos FGS comprobados | pending |
| RL05 | Gates G02–G09 cerrados para candidateReal, condición/equipo/escenario publicados | pending |
| RL06 | Política privacidad/contacto/Data safety coherentes con auditoría, eliminación y copias externas | pending |
| RL07 | Listing/capturas/video reales, sin funciones futuras ni aptitud/seguridad prometida | pending |
| RL08 | Requisitos de cuenta/track cumplidos; inscripción testers si aplica, revisión real de tienda | pending |
| RL09 | Evaluación adicional del contexto comercial y protocolo ejecutado; límites aceptados | blocked |
| RL10 | Canal de soporte, flujo de reporte local voluntario y release notes definidos; ningún envío automático añadido | pending |
| RL11 | Paquete firmado instalado offline y smoke en modelos declarados, evidencia del artefacto distribuible | pending |
| RL12 | Decisión de etapa por responsable y registro de issues/excepciones; publicación explícitamente autorizada | pending |

Propuesta de soporte: incidencia voluntaria con versión/equipo/Android/pasos/código técnico; no adjuntar caras, alias o exports por defecto. No se incorpora backend/crash reporter automáticamente. Tiempo de respuesta/correo reales se fijan con disponibilidad del responsable antes de publicar, no se inventa un SLA.

Si un defecto S0/S1 afecta una versión distribuida: registrar alcance, detener nuevos candidatos, preparar corrección y nueva evidencia; decidir retirada/actualización informada según canal. No bajar versionCode ni restaurar backups personales silenciosamente. Downgrade de DB no se usa como rollback genérico: corrección compatible o migración segura hacia adelante. Conservar artefacto/evidencia anteriores para reproducir, no mantener acceso público por inercia.

Versiones de política/modelo y recurso visual tienen historiales distintos. Un hotfix visual puede reutilizar evidencia IA solo si no cambió captura/Q/política/latencia relevante, con revisión documentada. Toda modificación que afecte denominadores/tiempos exige recalcular y verificar integridad.

## 16. Dependencias abiertas y siguiente área

| Dependencia | Decisión/evidencia que falta | Área/casos que bloquea |
|---|---|---|
| HTML completo B5.2 + inventario motion | Hash/recursos/estados/tokens y licencia fuente/iconos | QA33/QA34, G05 |
| Nav al 200 % | Layout en Flutter y prueba Android, sin límite 135 % | QA33, RNF03 |
| Toolchain/equipos | Versiones compatibles y D1–D4 concretos | QA35–QA37, G06 |
| Modelo real y licencia | Asset/hash/procedencia y licencia revisados | QA06/QA09/QA39/QA40 |
| EyeVisibilityGate | Viabilidad y controles de oclusión/cierre válidos | AI12/AI26, SC08/SC13, G08 |
| Calificación IA | Anotación/split/EV y condiciones con exposición suficiente | G08/G09 |
| Room/Drift/JCS/backup reales | Traducción/migraciones/harness/pruebas físicas | G04, QA37 |
| Contexto comercial | Protocolo/uso real que aún no cubre piloto de señales detenidas | E4, RL09 |
| Distribución | Cuenta/packageId/firma/responsable/contacto/track | G10, RL01/RL02/RL06/RL08/RL12 |

No falta otro rediseño para empezar a organizar implementación. Cuando una prueba revele un cambio necesario, se registra el handoff concreto y se modifica lo afectado, conservando IDs/flujos/restricciones de Vigía. La preparación del Área 08 no exige que pruebas de una app inexistente estén aprobadas.

Siguiente paso: **Área 08, plan de implementación y colaboración Codex/Claude Code**. Convertirá estas especificaciones en backlog por dependencias, hitos, estructura del repo, tareas con Definition of Done y reglas de colaboración/revisión. El primer hito técnico resolverá cámara frontal→modelo local→evento→UI→journal, antes de ampliar pantallas. La creación/codificación del repo se hará cuando el usuario indique empezar esa ejecución.

## 17. Fuentes técnicas primarias

Las metas QA, repeticiones, gates y perfiles son decisiones de Vigía. Las fuentes explican capacidades/restricciones de herramientas y distribución; no certifican este producto.

- S1. Flutter, [Integration testing concepts](https://docs.flutter.dev/cookbook/testing/integration/introduction). Alcance de integration_test y límites con UI nativa.
- S2. Android, [Write automated tests with UI Automator](https://developer.android.com/training/testing/other-components/ui-automator). Interacción con UI de plataforma.
- S3. Flutter, [Performance profiling](https://docs.flutter.dev/perf/ui-performance). Dispositivo físico y profile frente a debug/emulador.
- S4. Flutter, [Accessibility testing](https://docs.flutter.dev/ui/accessibility/accessibility-testing). Guideline API/scanner; complementar con operación real.
- S5. Android, [Foreground service types](https://developer.android.com/develop/background-work/services/fgs/service-types) y [Background-start restrictions](https://developer.android.com/develop/background-work/services/fgs/restrictions-bg-start). Cámara, permisos y arranque del servicio.
- S6. Google Play, [Target API requirements](https://support.google.com/googleplay/android-developer/answer/11926878). Requisito móvil vigente consultado, revisar antes del envío.
- S7. Google Play, [Testing requirements for new personal accounts](https://support.google.com/googleplay/android-developer/answer/14151465). Aplicabilidad por cuenta y prueba cerrada.
- S8. Android, [Support 16 KB page sizes](https://developer.android.com/guide/practices/page-sizes). Librerías, empaquetado y ejecución.
- S9. Android, [Sign your app](https://developer.android.com/studio/publish/app-signing). Firma y Play App Signing.
- S10. Google Play, [Foreground service and full-screen intent requirements](https://support.google.com/googleplay/android-developer/answer/13392821). Declaración/demo, sin asumir autorización full-screen.
- S11. Google Play, [Data safety](https://support.google.com/googleplay/android-developer/answer/10787469). Declaraciones incluyendo SDKs y política de privacidad.

## 18. Verificación de esta entrega

Se ejecutaron 23 comprobaciones documentales/de cálculo, todas satisfactorias, sobre esta entrega. Se contrastó el anexo contra el texto de los cinco documentos vigentes leídos completos. Resultado: 310 IDs únicos, ninguno omitido, sin referencia QA inexistente y texto fuente preservado. Las 40 familias QA, 10 gates y 12 condiciones RL tienen IDs únicos; todas las tablas mantienen columnas consistentes.

| Inventario contrastado | Cantidad |
|---|---:|
| RF.CA | 96 |
| RNF.CA | 30 |
| UX.CA | 66 |
| AT | 22 |
| AI | 28 |
| EV | 13 |
| DT | 24 |
| SC | 14 |
| DS | 9 |
| UT | 8 |
| Total de IDs fuente | 310 |

También se comprobaron la multiplicación condicional de layout 1440, posición nearest-rank del p95 con muestras de referencia, desigualdades de latencia, factor de memoria 1,20, corte DS08 Bogotá y consistencia de cantidades del piloto. Esto verifica la aritmética y trazabilidad del plan, no tiempos ni resultados de una app.

Los 192 CA RF/RNF/UX y los 87 AT/AI/EV/DT siguen notRun; los 31 SC/DS/UT figuran planned. No se ejecutaron APK, Flutter, Kotlin, Android, TalkBack, sonido, cámara, backups, usuarios ni evaluación IA durante esta entrega. No se comprobó el HTML completo B5.2. La evidencia de referencia del Área 06 conserva el alcance allí documentado; no se usa para aprobar el producto en este plan.

## 19. Anexo de trazabilidad por ID

Cada fila conserva ID y texto del criterio/fixture fuente. QA indica familia de ensayo, no ejecución completa. Las fechas/builds/resultados de ejecución se añadirán al registro futuro; no rellenarlos con la fecha de este plan.

| ID | Fuente | Criterio, ensayo o escenario de origen | Familias QA | Estado inicial |
|---|---|---|---|---|
| RF01.CA1 | PRD | Dada una instalación nueva, al abrirla se muestran finalidad, procesamiento local, datos guardados y condiciones de preparación; todavía no se abre la cámara ni se solicita su permiso. | QA01 | notRun |
| RF01.CA2 | PRD | Al pulsar Continuar se guarda la versión de la explicación vista y se pasa a la explicación del permiso. | QA01 | notRun |
| RF01.CA3 | PRD | Al reabrir con esa versión ya vista, no se repite la incorporación; Ayuda permite consultar el mismo contenido. | QA01 | notRun |
| RF02.CA1 | PRD | Con permiso no concedido, pulsar Permitir cámara invoca la solicitud de Android; aceptar habilita la comprobación de cámara. | QA02 | notRun |
| RF02.CA2 | PRD | Si el usuario rechaza, no comienza captura ni se crea una sesión; se muestra Cámara sin permiso. | QA02 | notRun |
| RF02.CA3 | PRD | Si Android ya no permite repetir la solicitud, se ofrece Abrir ajustes; al volver se vuelve a consultar el permiso, sin asumir aceptación. | QA02 | notRun |
| RF03.CA1 | PRD | Con cámara autorizada y una entrada de prueba con rostro presente y calidad ocular inválida, se muestra Rostro detectado y No puedo evaluar los ojos; Iniciar monitoreo está deshabilitado. | QA03 | notRun |
| RF03.CA2 | PRD | Con entrada sin rostro, se muestra Rostro no detectado y el botón de inicio sigue deshabilitado. | QA03 | notRun |
| RF03.CA3 | PRD | Con rostro y calidad válidos, se habilita el siguiente paso de preparación, pero no se inicia una sesión automáticamente. | QA03 | notRun |
| RF04.CA1 | PRD | En preparación, pulsar Probar sonido solicita reproducción y registra su resultado técnico. | QA04 | notRun |
| RF04.CA2 | PRD | Solo después de resultado técnico exitoso se habilita Lo escuché; sin esa confirmación no se permite iniciar. | QA04 | notRun |
| RF04.CA3 | PRD | Si la reproducción devuelve error, se muestra No se pudo reproducir el sonido y Reintentar; no se marca la prueba aprobada. La app no afirma medir audibilidad en la cabina. | QA04 | notRun |
| RF05.CA1 | PRD | Para cada precondición falsa, una prueba independiente mantiene deshabilitado Iniciar monitoreo y no crea registro de sesión. | QA05 | notRun |
| RF05.CA2 | PRD | La interfaz identifica cada causa: Cámara sin permiso, Cámara no disponible, Modelo no disponible, Ojos no evaluables, Calibración pendiente o Prueba de sonido pendiente. | QA05 | notRun |
| RF05.CA3 | PRD | Si una precondición deja de cumplirse después de habilitar el botón, pulsarlo vuelve a comprobar todas; no crea una sesión si la comprobación falla. | QA05 | notRun |
| RF06.CA1 | PRD | Con secuencia que cumple Kcal, se guarda una única referencia con ID, fecha, versión de modelo, versión de calibración y resumen de observaciones; se muestra Calibración completada. | QA06 | notRun |
| RF06.CA2 | PRD | Con secuencia que incumple Kcal, no se guarda una referencia aceptada y se muestra el código de causa: observaciones insuficientes, calidad ocular inválida o referencia inestable. | QA06 | notRun |
| RF06.CA3 | PRD | Cancelar detiene la captura de referencia y vuelve a preparación sin crear sesión. Kcal está pendiente: RF06 no se cierra hasta fijarlo. | QA06 | notRun |
| RF07.CA1 | PRD | La preparación muestra Verifica el soporte y permite declarar Cambié la posición; seleccionarlo marca la referencia como no aplicable y exige RF06. | QA07 | notRun |
| RF07.CA2 | PRD | Si las versiones de modelo/esquema difieren de las admitidas por la referencia, no se inicia y se muestra Repite la calibración. | QA07 | notRun |
| RF07.CA3 | PRD | La sesión almacena el ID y una instantánea o versión inmutable de la referencia; recalibrar después no modifica los datos de sesiones anteriores. No se promete detección automática de movimientos del soporte. | QA07 | notRun |
| RF08.CA1 | PRD | Con todas las precondiciones cumplidas, diez pulsaciones de inicio en un segundo generan un solo ID de sesión y un solo registro inicial. | QA08 | notRun |
| RF08.CA2 | PRD | Mientras el motor no confirma, se muestra Iniciando y se bloquea otro inicio; la UI no muestra Activa. | QA08 | notRun |
| RF08.CA3 | PRD | Si el motor rechaza, se vuelve a preparación con el error y no queda una sesión activa ficticia; todo registro inicial creado se marca fallido. | QA08 | notRun |
| RF09.CA1 | PRD | En un equipo compatible, con internet deshabilitado, una sesión de diez minutos produce resultados de inferencia sobre cámara física. | QA09 | notRun |
| RF09.CA2 | PRD | El informe de prueba registra hash/versión del modelo y timestamps de entrada y resultado; no basta un contador de UI o resultados precargados. | QA09 | notRun |
| RF09.CA3 | PRD | El registro de tráfico verifica que no se envían imágenes, landmarks ni observaciones a servidores durante esa prueba. | QA09 | notRun |
| RF10.CA1 | PRD | La UI distingue Preparando, Iniciando, Activa, Pausada, Finalizando, Finalizada e Interrumpida; un cambio de estado se muestra como máximo un segundo después de recibirlo. | QA10 | notRun |
| RF10.CA2 | PRD | La medición se muestra como Inicializando, Utilizable, Limitada o No disponible; el resultado permite Sin señales persistentes, Advertencia, Alerta por cierre prolongado o No evaluable. | QA10 | notRun |
| RF10.CA3 | PRD | Si la calidad es inválida, el resultado es No evaluable; no se muestra Sin señales persistentes, Seguro ni porcentajes de fatiga. | QA10 | notRun |
| RF11.CA1 | PRD | Con una secuencia anotada que satisface W, se emite una advertencia con ID, motivo y versión de política; un control que no satisface W no la emite. | QA11 | notRun |
| RF11.CA2 | PRD | Se prueban los límites de cada condición de W: un paso temporal antes del umbral no activa; alcanzar el umbral sí activa si las otras condiciones se cumplen. | QA11 | notRun |
| RF11.CA3 | PRD | La reproducción comienza como máximo 500 ms después de la decisión del motor; W está pendiente y RF11 no se cierra hasta definir su fórmula, ventana y umbrales. | QA11 | notRun |
| RF12.CA1 | PRD | Con calidad válida y criterio ocular C cumplido continuamente por Tclose, se genera alerta visual y sonora y se registra el motivo Cierre ocular prolongado. | QA12 | notRun |
| RF12.CA2 | PRD | En una secuencia sin bostezo pero con ese cierre se genera la misma alerta; una secuencia de cierre menor que Tclose no activa RF12. | QA12 | notRun |
| RF12.CA3 | PRD | Una observación ocular inválida rompe continuidad: el tramo posterior no se suma al anterior. La reproducción comienza como máximo 500 ms después de la decisión. C y Tclose están pendientes; RF12 no se cierra sin esos valores. | QA12 | notRun |
| RF13.CA1 | PRD | Una secuencia continua que mantiene la misma regla activa crea un episodio, aunque haya múltiples resultados de inferencia; nunca crea un evento por fotograma. | QA13 | notRun |
| RF13.CA2 | PRD | Una reproducción repetida conserva ID de episodio y añade número/tiempo de aviso; solo se repite cuando se cumple Rrepeat. | QA13 | notRun |
| RF13.CA3 | PRD | Tras cumplir Eend y volver a activar la regla, se crea otro ID. Una alerta RF12 no se suprime por el periodo de repetición de una advertencia RF11. Eend y Rrepeat deben cerrarse en la política. | QA13 | notRun |
| RF14.CA1 | PRD | Un resultado inválido produce estado No evaluable y abre un intervalo con causa y timestamp; nunca se convierte en observación de ojos abiertos. | QA14 | notRun |
| RF14.CA2 | PRD | Si no llegan resultados durante Tstale, se invalida la observación y se registra Sin resultados de cámara/inferencia. | QA14 | notRun |
| RF14.CA3 | PRD | El cambio visible tarda como máximo un segundo desde la decisión del motor. Tstale está pendiente; no se puede cerrar la prueba de ausencia de resultados hasta fijarlo. | QA14 | notRun |
| RF15.CA1 | PRD | Tras una entrada inválida, una secuencia que todavía no satisface Krecover mantiene No evaluable y no emite decisiones basadas en la ventana anterior. | QA15 | notRun |
| RF15.CA2 | PRD | Al satisfacer Krecover, se cierra el intervalo de pérdida y se pasa a medición Utilizable; los resultados utilizan solo observaciones posteriores al corte. | QA15 | notRun |
| RF15.CA3 | PRD | Una prueba con dos cierres separados por pérdida no suma ambos para alcanzar Tclose. Krecover requiere definición antes de cerrar RF15. | QA15 | notRun |
| RF16.CA1 | PRD | Pulsar Pausar pide transición; solo después de confirmación aparece Pausada y empieza el intervalo con timestamp del motor. | QA16 | notRun |
| RF16.CA2 | PRD | Mientras está pausada, una secuencia que normalmente activaría RF12 no produce un nuevo episodio de detección. | QA16 | notRun |
| RF16.CA3 | PRD | Diez solicitudes de pausa durante la transición crean un solo intervalo; su duración no se incluye en tiempo evaluable ni no evaluable. | QA16 | notRun |
| RF17.CA1 | PRD | Con cámara, modelo y calidad aptos, pulsar Reanudar confirma la transición, cierra pausa y conserva el ID de sesión. | QA17 | notRun |
| RF17.CA2 | PRD | Con cualquier condición falsa se permanece Pausada, se identifica la causa y no se acumula tiempo evaluable. | QA17 | notRun |
| RF17.CA3 | PRD | Las ventanas de cierre anteriores a la pausa se descartan; una repetición de la solicitud no crea otra sesión ni cierra dos veces la pausa. Los criterios de calidad dependen de Q. | QA17 | notRun |
| RF18.CA1 | PRD | Pulsar Finalizar deshabilita nuevas órdenes de inicio para esa sesión y pasa a Finalizando hasta confirmación. | QA18 | notRun |
| RF18.CA2 | PRD | En un equipo compatible, como máximo dos segundos después de confirmar Finalizada no llegan frames a esa sesión, la cámara está liberada, sus sonidos se detienen y su servicio de monitoreo deja de ejecutarse. | QA18 | notRun |
| RF18.CA3 | PRD | Solicitar cierre repetidamente conserva un único cierre; si guardar falla, el resumen indica Registro incompleto y no afirma que quedó guardado. | QA18 | notRun |
| RF19.CA1 | PRD | Forzar terminación con sesión activa y reabrir la marca Interrumpida; recupera los eventos cuyo commit había sido confirmado. | QA19 | notRun |
| RF19.CA2 | PRD | No crea observaciones ni eventos entre el último resultado durable y la recuperación; el final incierto se presenta como desconocido. | QA19 | notRun |
| RF19.CA3 | PRD | No inicia cámara ni reanuda sesión automáticamente; ofrece revisar el registro o preparar una nueva sesión. | QA19 | notRun |
| RF20.CA1 | PRD | Durante una prueba de dos minutos con cinco cambios entre pantallas de la app, se conserva ID y continúan resultados; no se inicia otra captura. | QA20 | notRun |
| RF20.CA2 | PRD | Con pérdida de conexión UI–motor, se muestra Estado del monitoreo no disponible; la UI no confirma continuidad hasta obtener un snapshot vigente. | QA20 | notRun |
| RF20.CA3 | PRD | Al reconectar, consulta estado y registros; no ejecuta inicio por defecto. El comportamiento al bloquear o cambiar a otra app se registra por escenario en RNF04, sin asumir compatibilidad universal. | QA20 | notRun |
| RF21.CA1 | PRD | Para un fixture con 600 s evaluables, 120 s no evaluables, 180 s pausados y 60 s desconocidos, muestra 83,3 % de cobertura, los cuatro tiempos y total representado de 960 s. | QA21 | notRun |
| RF21.CA2 | PRD | Cantidad de eventos coincide con IDs de episodio únicos; repeticiones de sonido no aumentan el conteo de episodios. | QA21 | notRun |
| RF21.CA3 | PRD | Con consolidación pendiente muestra Resumen pendiente de completar; con escritura fallida muestra Registro incompleto. Un extremo temporal desconocido se rotula así, sin inventar fecha final. | QA21 | notRun |
| RF22.CA1 | PRD | Guardar dos sesiones, cerrar y reabrir conserva sus IDs; se muestran en orden descendente de inicio con fecha, estado y cobertura. | QA22 | notRun |
| RF22.CA2 | PRD | Sin sesiones muestra Aún no tienes sesiones y Preparar primera sesión; con error de lectura muestra No se pudo cargar el historial y Reintentar. | QA22 | notRun |
| RF22.CA3 | PRD | Una sesión interrumpida no aparece como finalizada y no se oculta; la lectura de detalles utiliza el mismo ID seleccionado. | QA22 | notRun |
| RF23.CA1 | PRD | Seleccionar evento muestra categoría, motivo, fecha, desplazamiento desde inicio, calidad de medición y versiones de modelo/política. | QA23 | notRun |
| RF23.CA2 | PRD | Si duración/final no están confirmados, muestra Duración no disponible o Episodio sin cierre confirmado; no los reemplaza por cero. | QA23 | notRun |
| RF23.CA3 | PRD | El detalle no muestra capturas faciales si el producto no las guardó; un aviso técnico de cámara no se rotula como somnolencia. | QA23 | notRun |
| RF24.CA1 | PRD | Para una sesión cerrada se puede elegir Útil, No percibí somnolencia o No estoy seguro; se conserva código y fecha de valoración tras reiniciar. | QA24 | notRun |
| RF24.CA2 | PRD | Cambiar valoración sustituye la anterior en ese campo, pero mantiene ID, motivo, timestamps y versión del evento detectado. | QA24 | notRun |
| RF24.CA3 | PRD | En sesión activa no se habilita la edición; una valoración no modifica umbrales ni activa entrenamiento. | QA24 | notRun |
| RF25.CA1 | PRD | En periodos de siete y treinta fechas locales incluyendo hoy, se filtran sesiones por fecha de inicio y se muestra intervalo exacto; las sumas se calculan por grupo de versión de política. | QA25 | notRun |
| RF25.CA2 | PRD | Con 2 episodios y 1800 s evaluables, muestra 4,0 episodios/hora evaluable; la cobertura agregada usa sumas de tiempos, no promedio de porcentajes. | QA25 | notRun |
| RF25.CA3 | PRD | Sin tiempo evaluable, tasa y cobertura muestran No disponible. Presenta totales por categoría y pausas; no genera diagnóstico, ranking ni conclusión automática de mejoría. | QA25 | notRun |
| RF26.CA1 | PRD | Seleccionar JSON incluye schemaVersion, exportedAt, sesiones, episodios, intervalos, pausas y valoraciones; seleccionar CSV produce un archivo de sesiones y otro de episodios con IDs de relación. | QA26 | notRun |
| RF26.CA2 | PRD | Los archivos incluyen fechas ISO 8601 con zona/offset, duraciones en ms y versiones; al reimportarlos en la prueba coinciden IDs y conteos con la selección. Texto con coma, comillas o salto de línea no rompe columnas CSV. | QA26 | notRun |
| RF26.CA3 | PRD | Cancelar el selector no muestra éxito ni marca exportación completada. Error de escritura muestra No se pudo exportar; solo se confirma después de cierre exitoso del archivo. | QA26 | notRun |
| RF27.CA1 | PRD | Para sesión cerrada, cancelar confirmación no borra; confirmar elimina sesión, episodios, intervalos, pausas y valoraciones de ambos almacenes. | QA27 | notRun |
| RF27.CA2 | PRD | Tras reinicio y reintento de consolidación, el ID eliminado no reaparece. Borrar todo añade referencias y alias y vuelve a estado de primera preparación; las preferencias de tema pueden conservarse. | QA27 | notRun |
| RF27.CA3 | PRD | Con sesión activa, se solicita finalizarla antes del borrado. Si cualquiera de los almacenes falla, no muestra éxito; mantiene solicitud pendiente y evita restaurar los registros ya borrados. Archivos exportados se informan como copias externas no eliminadas. | QA27 | notRun |
| RF28.CA1 | PRD | Valor inicial de producto: 90 días; admite 30, 90, 180 días o Hasta que los borre. Se guarda la opción y se informa que reducirla eliminará sesiones anteriores al corte. | QA28 | notRun |
| RF28.CA2 | PRD | Para N días, corte = inicio de hoy menos N−1 fechas locales; una sesión anterior al corte se elimina y una exactamente en el corte se conserva. Se aplican las cascadas de RF27. | QA28 | notRun |
| RF28.CA3 | PRD | Se ejecuta al abrir la app y después de cerrar/consolidar sesión; una sesión activa no se elimina. Un fallo de depuración no se presenta como limpieza completa. Son opciones propuestas de producto, no resultados de validación. | QA28 | notRun |
| RF29.CA1 | PRD | Elegir Claro, Oscuro o Sistema y reabrir conserva la elección; los avisos usan texto e icono además del color. | QA29 | notRun |
| RF29.CA2 | PRD | Una sesión activa conserva la versión de política de su inicio; la UI no ofrece sliders para cambiar Tclose o parámetros de detección durante la sesión. | QA29 | notRun |
| RF29.CA3 | PRD | Las opciones de sonido seleccionan un patrón incluido y permiten probarlo; no hay opción de desactivar la alerta ocular manteniendo la sesión declarada plenamente operativa. Cambios de patrón requieren repetir RF04 antes de la siguiente sesión. | QA29 | notRun |
| RF30.CA1 | PRD | Se pueden abrir seis temas: soporte/encuadre, iluminación/ojos, calibración, sonido, interrupciones y datos/exportación. | QA30 | notRun |
| RF30.CA2 | PRD | Cada tema muestra causa, acción concreta y condición para volver a intentar; Cámara sin permiso enlaza a Ajustes y Calibración pendiente enlaza a preparación. | QA30 | notRun |
| RF30.CA3 | PRD | Abrir Ayuda no activa cámara, no crea una sesión y no requiere internet. Durante sesión activa la app muestra solo el aviso técnico breve, no un tutorial que exija lectura. | QA30 | notRun |
| RF31.CA1 | PRD | Importar el mismo lote tres veces conserva un registro por ID de sesión/episodio/intervalo. | QA31 | notRun |
| RF31.CA2 | PRD | Forzar cierre después del commit y antes de confirmación al journal, reabrir e importar otra vez mantiene los mismos conteos. | QA31 | notRun |
| RF31.CA3 | PRD | Con lote pendiente o error de escritura, RF21 muestra estado pendiente/incompleto; si falta metadato necesario no se informa resumen definitivo. La prueba de eliminación verifica que RF27 no se revierte. | QA31 | notRun |
| RF32.CA1 | PRD | La variante demo muestra DEMO — datos simulados en monitoreo, historial y exportación; usa un almacén distinto. | QA32 | notRun |
| RF32.CA2 | PRD | La compilación de producción no expone selector de fixtures ni conecta proveedores de resultados simulados; prueba de build verifica esa configuración. | QA32 | notRun |
| RF32.CA3 | PRD | Una demostración con cámara real puede usar la variante real; no se rotula inferencia real si la entrada o resultados están precargados. | QA32 | notRun |
| RNF01.CA1 | PRD | En un dispositivo de referencia, desactivar datos móviles y Wi-Fi antes de abrir la app y completar preparación, calibración, diez minutos de sesión y cierre; ninguna acción solicita conectividad. | QA09, QA26, QA27, QA30, QA37 | notRun |
| RNF01.CA2 | PRD | Con fixture que activa RF12 durante esa sesión, se emite alerta y aparece su episodio en el resumen. | QA09, QA26, QA27, QA30, QA37 | notRun |
| RNF01.CA3 | PRD | Historial, Ayuda, borrado y escritura de exportación a almacenamiento local funcionan offline; compartir a una app externa no forma parte de esa garantía. | QA09, QA26, QA27, QA30, QA37 | notRun |
| RNF02.CA1 | PRD | En compilación profile/release, con pantalla de 60 Hz, el percentil 95 del tiempo de build y del tiempo de rasterizado, medidos por separado durante 60 s de monitoreo, no supera 16,7 ms cada uno. | QA35 | notRun |
| RNF02.CA2 | PRD | El perfil de hilos confirma que el cálculo de inferencia y características no se ejecuta en el hilo de UI Flutter ni en el hilo principal Android. | QA35 | notRun |
| RNF02.CA3 | PRD | Se repite en cada equipo declarado compatible con su versión de modelo y modo de captura. Si falla, ese modo/equipo no satisface RNF02; no se cierra mediante una inspección visual. | QA35 | notRun |
| RNF03.CA1 | PRD | Con escala de texto 100 % y 200 %, ninguna etiqueta o acción esencial queda cortada, superpuesta o inaccesible; se comprueban preparación, calibración, monitoreo, resumen, historial y ajustes en modo claro y oscuro. | QA33, QA34 | notRun |
| RNF03.CA2 | PRD | Objetivos de diseño propuestos: contraste de texto ≥4,5:1 y área táctil de acciones ≥48×48 unidades lógicas; se registran mediciones por componente, sin afirmar certificación externa. | QA33, QA34 | notRun |
| RNF03.CA3 | PRD | TalkBack anuncia nombre, función y estado de las acciones; un cambio de calidad se anuncia sin obligar a interpretar color. El reporte enumera cada pantalla/componente probado y su resultado. | QA33, QA34 | notRun |
| RNF04.CA1 | PRD | Para cada combinación marca/modelo/Android/build, ejecutar cinco minutos en cada escenario: app visible, otra pantalla de la app, otra app, pantalla bloqueada y llamada recibida. Separar los escenarios para atribuir resultados. | QA36 | notRun |
| RNF04.CA2 | PRD | Registrar timestamps de resultados y periodos que superen Tstale, estados, avisos e ID. Con hueco o captura suspendida no se declara monitoreo continuo para ese escenario. | QA36 | notRun |
| RNF04.CA3 | PRD | Forzar cierre y retirar permiso producen el comportamiento de RF19 y RF14; publicar una tabla de soportado/no soportado para cada escenario. La matriz queda pendiente hasta ejecutar pruebas. | QA36 | notRun |
| RNF05.CA1 | PRD | Con un fixture de 10 sesiones y 100 episodios, importar tres veces conserva exactamente 10 IDs de sesión y 100 IDs de episodio. | QA08, QA27, QA31 | notRun |
| RNF05.CA2 | PRD | Simular fallo después de commit y antes de confirmación, reiniciar y reintentar conserva los mismos conteos y relaciones. | QA08, QA27, QA31 | notRun |
| RNF05.CA3 | PRD | Borrar una sesión e importar un lote antiguo no la restaura; fallo parcial mantiene el estado de error exigido por RF27. | QA08, QA27, QA31 | notRun |
| RNF06.CA1 | PRD | Después de confirmación de cierre, dentro de dos segundos el contador de frames de esa sesión deja de aumentar y se cancela toda reproducción vinculada a ella. | QA18 | notRun |
| RNF06.CA2 | PRD | El servicio de monitoreo de esa sesión ya no figura en ejecución y el preview no mantiene acceso a la cámara. | QA18 | notRun |
| RNF06.CA3 | PRD | Diez ciclos de inicio/cierre permiten abrir de nuevo la cámara sin reiniciar la app; nunca quedan dos propietarios del dispositivo de captura. | QA18 | notRun |
| RNF07.CA1 | PRD | Por cada equipo/mode declarado, medir al menos 1000 resultados; latencia captura→resultado facial p95 <200 ms. Se documenta cómo se obtiene el timestamp de captura; no sustituirlo por el momento de dibujar la UI. | QA35 | notRun |
| RNF07.CA2 | PRD | Registrar frecuencia solicitada/real, frames capturados, enviados, procesados y descartados, RAM, estado térmico y batería inicial/final con duración. Toda temperatura incluye sensor y unidad; si no está disponible se registra No disponible. | QA35 | notRun |
| RNF07.CA3 | PRD | Medir por separado decisión→inicio de sonido; debe ser ≤500 ms según RF11/RF12. No usar esa medida para afirmar que se detecta somnolencia en 500 ms. | QA35 | notRun |
| RNF08.CA1 | PRD | Cada reporte incluye hash del APK, equipo/Android, versión/hash del modelo, política, calibración, configuración, protocolo y fecha. | QA35, QA39, QA40 | notRun |
| RNF08.CA2 | PRD | Cada caso con fixture identifica su versión y conserva eventos/timestamps esperados y obtenidos. | QA35, QA39, QA40 | notRun |
| RNF08.CA3 | PRD | Ejecutar tres veces el mismo fixture en la misma configuración produce la misma clasificación e IDs distintos entre ejecuciones; diferencias de tiempo de ejecución se reportan frente a los límites de rendimiento. | QA35, QA39, QA40 | notRun |
| RNF09.CA1 | PRD | En cada equipo declarado compatible, ejecutar 60 min continuos en el modo de captura elegido sin crash ni ANR; registrar toda interrupción y toda restricción térmica. | QA35 | notRun |
| RNF09.CA2 | PRD | Como objetivo provisional, la media de memoria del proceso en los últimos diez minutos no supera en más del 20 % la media de los minutos 10–20; registrar muestras cada minuto. Un fallo exige revisión, no una promesa de estabilidad. | QA35 | notRun |
| RNF09.CA3 | PRD | Al finalizar, ejecutar RF18 y RF21. La prueba de 60 min solo acepta esa duración/condición; no valida una jornada completa. | QA35 | notRun |
| RNF10.CA1 | PRD | La auditoría de build comprueba que producción conecta el modelo real y no fixtures; demo mantiene la separación RF32. | QA29, QA32, QA40 | notRun |
| RNF10.CA2 | PRD | Recorrer cada acción habilitada de V1 obtiene el resultado especificado o su error; no hay botones que devuelvan éxito sin ejecutar la operación. | QA29, QA32, QA40 | notRun |
| RNF10.CA3 | PRD | La interfaz de V1 no presenta iOS, flotas, GPS, cámara externa o entrenamiento propio como disponibles. El reporte verifica el inventario de módulos M01–M10. | QA29, QA32, QA40 | notRun |
| UX01.CA1 | UX | Instalación nueva abre P01 sin permiso ni preview antes de las acciones correspondientes. | QA01, QA19, QA20 | notRun |
| UX01.CA2 | UX | Reapertura con sesión vigente abre P06 del mismo ID sin comando de inicio. | QA01, QA19, QA20 | notRun |
| UX01.CA3 | UX | Estado desconocido muestra incertidumbre y bloquea preparar otra sesión. | QA01, QA19, QA20 | notRun |
| UX02.CA1 | UX | Rechazar mantiene Cámara sin permiso; Ahora no abre Inicio sin captura. | QA02 | notRun |
| UX02.CA2 | UX | Si Android no admite otra solicitud, aparece Abrir ajustes y el retorno denegado conserva bloqueo. | QA02 | notRun |
| UX02.CA3 | UX | Retorno con permiso verificado abre Preparación, no Monitoreo. | QA02 | notRun |
| UX03.CA1 | UX | Cada una de las seis precondiciones falsas produce su causa RF05.CA2 y bloquea inicio. | QA03, QA05 | notRun |
| UX03.CA2 | UX | Rostro presente/ojos inválidos muestra ambos resultados separados. | QA03, QA05 | notRun |
| UX03.CA3 | UX | Pérdida de permiso o calidad antes de pulsar inicio impide presentar sesión confirmada. | QA03, QA05 | notRun |
| UX04.CA1 | UX | Lo escuché permanece deshabilitado hasta reproducción técnica exitosa. | QA04 | notRun |
| UX04.CA2 | UX | No lo escuché conserva bloqueo aunque la reproducción haya sido exitosa. | QA04 | notRun |
| UX04.CA3 | UX | Preparar una nueva sesión exige nueva prueba y confirmación. | QA04 | notRun |
| UX05.CA1 | UX | Sin Kcal cerrado no se muestran duración ni porcentaje inventados. | QA06, QA07 | notRun |
| UX05.CA2 | UX | Cada rechazo muestra causa y Reintentar; no habilita referencia aceptada. | QA06, QA07 | notRun |
| UX05.CA3 | UX | Cancelar vuelve a Preparación sin sesión ni restauración de una referencia invalidada. | QA06, QA07 | notRun |
| UX06.CA1 | UX | Diez pulsaciones de inicio en un segundo producen una transición y un ID, conforme RF08. | QA08, QA20 | notRun |
| UX06.CA2 | UX | A los 5 segundos sin resolución aparece Confirmación pendiente; Consultar estado no crea otra orden. | QA08, QA20 | notRun |
| UX06.CA3 | UX | Una respuesta tardía se reconcilia con el mismo ID sin duplicar sesión o pantalla. | QA08, QA20 | notRun |
| UX07.CA1 | UX | Activa/No disponible muestra No evaluable y nunca Sin señales persistentes. | QA10 | notRun |
| UX07.CA2 | UX | Pausada muestra Evaluación suspendida y no presenta la última señal como actual. | QA10 | notRun |
| UX07.CA3 | UX | Ninguna variante usa Seguro, Puedes conducir o porcentaje de fatiga. | QA10 | notRun |
| UX08.CA1 | UX | RF12 muestra Cierre ocular prolongado y Detente en un lugar seguro sin exigir bostezo o respuesta. | QA11, QA12, QA13 | notRun |
| UX08.CA2 | UX | RF12 tiene precedencia sobre advertencia y no queda suprimida por su periodo de repetición. | QA11, QA12, QA13 | notRun |
| UX08.CA3 | UX | Repeticiones del mismo episodio conservan ID y conteo; la latencia sonora se valida con RF11/RF12. | QA11, QA12, QA13 | notRun |
| UX09.CA1 | UX | Calidad inválida muestra No puedo evaluar y una causa comprobada. | QA14, QA15 | notRun |
| UX09.CA2 | UX | Antes de Krecover permanece Recuperando medición/No evaluable. | QA14, QA15 | notRun |
| UX09.CA3 | UX | Dos cierres separados por pérdida no se suman para activar una alerta. | QA14, QA15 | notRun |
| UX10.CA1 | UX | Pausar muestra Pausando hasta confirmación. | QA16, QA17 | notRun |
| UX10.CA2 | UX | Reanudar rechazado conserva Pausada, causa e ID. | QA16, QA17 | notRun |
| UX10.CA3 | UX | Volver de ajustes del teléfono no reanuda automáticamente. | QA16, QA17 | notRun |
| UX11.CA1 | UX | Cinco cambios Monitoreo/Inicio durante dos minutos conservan ID y resultados RF20. | QA20 | notRun |
| UX11.CA2 | UX | Rutas directas a funciones restringidas muestran Sesión en curso y Volver al monitoreo. | QA20 | notRun |
| UX11.CA3 | UX | Cambiar tema conserva motor y versión de política. | QA20 | notRun |
| UX12.CA1 | UX | Cancelar D02 conserva sesión; confirmar muestra Finalizando hasta respuesta. | QA18, QA21, QA31 | notRun |
| UX12.CA2 | UX | Lote pendiente o escritura fallida muestran resumen pendiente/incompleto. | QA18, QA21, QA31 | notRun |
| UX12.CA3 | UX | Volver desde Resumen no permite reabrir Monitoreo del ID cerrado. | QA18, QA21, QA31 | notRun |
| UX13.CA1 | UX | Reapertura tras terminación forzada muestra Interrumpida sin activar cámara. | QA19 | notRun |
| UX13.CA2 | UX | Final no confirmado permanece desconocido; no se extiende hasta la reapertura. | QA19 | notRun |
| UX13.CA3 | UX | Nueva sesión requiere demostrar ausencia de sesión vigente y obtiene otro ID. | QA19 | notRun |
| UX14.CA1 | UX | El caso de 600 s evaluables, 120 no evaluables, 180 pausados y 60 desconocidos muestra 83,3 % de cobertura y 960 s representados. | QA21 | notRun |
| UX14.CA2 | UX | Dos reproducciones de un episodio siguen contando como un episodio. | QA21 | notRun |
| UX14.CA3 | UX | Sin tiempo evaluable ni no evaluable, cobertura muestra No disponible. | QA21 | notRun |
| UX15.CA1 | UX | Historial vacío y lectura fallida muestran mensajes diferentes. | QA22, QA23 | notRun |
| UX15.CA2 | UX | Orden descendente e ID seleccionado se conservan entre lista y detalle. | QA22, QA23 | notRun |
| UX15.CA3 | UX | Episodio sin final muestra duración no disponible; no presenta una captura inexistente. | QA22, QA23 | notRun |
| UX16.CA1 | UX | Una de las tres opciones se conserva después de guardar y reiniciar. | QA24 | notRun |
| UX16.CA2 | UX | Cambiar valoración no modifica el evento; fallo no muestra Valoración guardada. | QA24 | notRun |
| UX16.CA3 | UX | Con sesión vigente no se permite edición; descartar cambios no escribe ni ajusta política. | QA24 | notRun |
| UX17.CA1 | UX | Con hoy 01/10/2026, 7 días muestra 25/09–01/10 y 30 días 02/09–01/10. | QA25 | notRun |
| UX17.CA2 | UX | Dos episodios en 1800 s evaluables muestran 4,0 episodios/hora evaluable. | QA25 | notRun |
| UX17.CA3 | UX | Sin denominador muestra No disponible; políticas diferentes no se mezclan en una tasa global. | QA25 | notRun |
| UX18.CA1 | UX | Cancelar JSON no muestra éxito; escritura y cierre exitosos muestran nombre del archivo. | QA26 | notRun |
| UX18.CA2 | UX | Un CSV escrito y otro cancelado muestran D08, no exportación completa. | QA26 | notRun |
| UX18.CA3 | UX | Ambos CSV usan el mismo snapshot y reintentar pendientes no duplica el archivo confirmado. | QA26 | notRun |
| UX19.CA1 | UX | Cancelar no borra; confirmar muestra Eliminando hasta completar ambos almacenes. | QA27 | notRun |
| UX19.CA2 | UX | Fallo parcial muestra Eliminación pendiente y bloquea editar/exportar los objetivos. | QA27 | notRun |
| UX19.CA3 | UX | Reinicio o importación de lote antiguo no restaura datos eliminados. | QA27 | notRun |
| UX20.CA1 | UX | Reducir muestra plazo, corte y recuento; cancelar conserva datos y preferencia. | QA28 | notRun |
| UX20.CA2 | UX | Una sesión anterior al corte se elimina; una exactamente en el corte se conserva. | QA28 | notRun |
| UX20.CA3 | UX | Fallo muestra Limpieza pendiente; ampliar plazo no promete recuperar datos. | QA28 | notRun |
| UX21.CA1 | UX | Tema guardado persiste; cambiar patrón requiere otra prueba RF04. | QA01, QA29, QA30 | notRun |
| UX21.CA2 | UX | Los seis temas funcionan offline y abrir un artículo no inicia captura. | QA01, QA29, QA30 | notRun |
| UX21.CA3 | UX | Alias vacío permite preparación; más de 40 caracteres bloquea guardar con mensaje específico. | QA01, QA29, QA30 | notRun |
| UX22.CA1 | UX | Texto al 100/200 % en ambos temas conserva acciones esenciales; controles y contraste cumplen objetivos RNF03. | QA32, QA33 | notRun |
| UX22.CA2 | UX | TalkBack anuncia acción y estado sin leer el cronómetro cada segundo ni repetir por cada frame. | QA32, QA33 | notRun |
| UX22.CA3 | UX | Demo identifica simulación y separa datos; producción no ofrece funciones futuras o fixtures como operativos. | QA32, QA33 | notRun |
| DS00 | UX | Cero sesiones, lectura exitosa · Historial vacío | QA22 | planned |
| DS01 | UX | 600 s evaluables, 120 no evaluables, 180 pausados y 60 desconocidos; dos episodios · 83,3 %; 960 s representados; dos episodios | QA21 | planned |
| DS02 | UX | Inicio y último registro confirmados, sin final · Interrumpida y final desconocido | QA19, QA21 | planned |
| DS03 | UX | Política A: 2 episodios/1800 s evaluables/600 no evaluables; B: 1/600/600 · Tasas 4,0 y 6,0; coberturas 75,0 % y 50,0 %, separadas | QA25 | planned |
| DS04 | UX | 120 s pausados y cero tiempo evaluable/no evaluable · Cobertura y tasa no disponibles | QA21, QA25 | planned |
| DS05 | UX | CSV sesiones escrito; episodios cancelado · Exportación parcial | QA26 | planned |
| DS06 | UX | Historial borrado; journal falla · Eliminación pendiente | QA27 | planned |
| DS07 | UX | Pausa sin respuesta durante 5 s; snapshot posterior Activa · Confirmación pendiente, sin pausa ficticia | QA16 | planned |
| DS08 | UX | Hoy 01/10/2026 en America/Bogota; retención 30 días · Corte 02/09/2026 00:00; anterior elimina, exactamente en corte conserva | QA28 | planned |
| UT01 | UX | Prepara una sesión; primero rechaza cámara y después concédela · Recupera permiso y completa preparación sin tratar alias como obligatorio | QA38 | planned |
| UT02 | UX | El sonido se reprodujo, pero no lo escuchaste · Mantiene bloqueo y repite prueba | QA38 | planned |
| UT03 | UX | Explica Activa/No disponible y Sin señales persistentes · Distingue falta de evaluación de ausencia de señales y no asume aptitud | QA38 | planned |
| UT04 | UX | Pausa y reanuda con respuesta tardía y rechazo · Distingue solicitud, confirmación y pausa aún abierta | QA38 | planned |
| UT05 | UX | Interpreta DS01 · Distingue cobertura, cuatro tiempos, episodios y repeticiones | QA38 | planned |
| UT06 | UX | Exporta CSV y cancela el segundo archivo · Reconoce exportación parcial y encuentra reintento | QA38 | planned |
| UT07 | UX | Cancela una eliminación; después elimina la sesión indicada · Distingue cancelación, alcance y copias externas | QA38 | planned |
| UT08 | UX | Revisa DS02 después de reapertura · Reconoce interrupción y ausencia de reanudación automática | QA38 | planned |
| AT01 | A04 | Diez taps/1 s y diez comandos de inicio distintos sobre preparación consumida: una sesión; no active antes de confirmación · RF05, RF08, UX06 | QA05, QA08 | notRun |
| AT02 | A04 | Repetir commandId/payload conserva resultado; alterar payload rechaza sin segundo efecto; revisión antigua no retrocede UI · RNF05, UX06 | QA08, QA20 | notRun |
| AT03 | A04 | Pausa sin respuesta 5 s, snapshot active: Confirmación pendiente y cero pausas ficticias (DS07) · RF16, UX10 | QA16 | notRun |
| AT04 | A04 | Reanudar sin permiso: paused, misma pausa/ID; volver de Ajustes no reanuda; callback tardío cancelado no cambia estado · RF17, UX10 | QA02, QA17 | notRun |
| AT05 | A04 | Cambiar montaje invalida referencia y bloquea inicio; tres rechazos de calibración nunca persisten accepted · RF06, RF07 | QA06, QA07 | notRun |
| AT06 | A04 | Cortar canal con motor vivo: UI unavailable, inicio bloqueado; reconectar conserva ID y recupera journal · RF20, UX01, UX11 | QA20 | notRun |
| AT07 | A04 | Secuencia con observación inválida entre dos cierres: no suma tramos; snapshot calidad inválida nunca noPersistentSignals · RF10, RF12, RF14, RF15 | QA10, QA12, QA14, QA15 | notRun |
| AT08 | A04 | Registrar capturas/callbacks antes y después de pause/stop: generaciones viejas no deciden ni alertan · RF16, RF18, RNF06 | QA16, QA18 | notRun |
| AT09 | A04 | Fixture 10 sesiones/100 episodios, importar 3 veces y caer tras commit antes ACK: mismos IDs y conteos · RF31, RNF05 | QA31 | notRun |
| AT10 | A04 | Revisar episodio durante lote pendiente; ACK de primera revisión no elimina segunda; hash distinto del mismo recordId genera error · RF31, RNF05 | QA31 | notRun |
| AT11 | A04 | Forzar muerte con sesión actual; reabrir conserva solo commits, interrupted, final desconocido y sin cámara automática · RF19, UX13 | QA19 | notRun |
| AT12 | A04 | Borrar y caer en cada etapa; reimportar lote antiguo: sesión no reaparece; fallo de una base nunca éxito (DS06) · RF27, UX19 | QA27 | notRun |
| AT13 | A04 | DS08: hoy 01/10/2026 Bogotá, N=30, corte 02/09/2026 00:00; anterior elimina, igual conserva y vigente excluida · RF28, UX20 | QA28 | notRun |
| AT14 | A04 | DS01: cobertura 83,3 %, total 960 s y 2 episodios; DS02 final desconocido; DS03 tasas 4,0/6,0 separadas; DS04 no disponible · RF21, RF25, UX14, UX17 | QA21, QA25 | notRun |
| AT15 | A04 | CSV sesiones escrito y episodios cancelado (DS05): D08 y sin exportación completa; JSON relectura conserva IDs · RF26, UX18 | QA26 | notRun |
| AT16 | A04 | Nueve rutas bloqueadas P09–P11/P13–P18 con active, paused y conexión incierta; P03↔P06 conserva motor/ID · UX11, RF20 | QA20 | notRun |
| AT17 | A04 | Fallo de sonido conserva episodio visual y estado sonoro fallido; no heardConfirmed antes de reproducción técnica · RF04, RF11, RF12, UX04 | QA04, QA11, QA12 | notRun |
| AT18 | A04 | APK real offline 10 min con cámara física: modelo/hash y resultados; sin tráfico; demo tiene otra base y ningún fixture real empaquetado · RF09, RF32, RNF01, RNF10 | QA09, QA32 | notRun |
| AT19 | A04 | Cierre repetido y diez ciclos: sin frames/sonido/servicio dentro de 2 s tras confirmación; sin segundo propietario de cámara · RF18, RNF06 | QA18 | notRun |
| AT20 | A04 | Cambio de reloj civil durante fixture no altera offsets/duración; nueva instancia no extrapola tiempos previos · RF19, RF21 | QA19, QA21 | notRun |
| AT21 | A04 | Restauración/transferencia Android de datos de prueba no devuelve sesiones/referencias excluidas; evidencia por versión/equipo · RF27 y decisión de backup | QA37 | notRun |
| AT22 | A04 | Contratos sin plataforma soportada/esquema desconocido: error explícito; UI no habilita cámara ni acciones mutantes · RNF10 | QA32 | notRun |
| SC01 | A05 | Frontal, luz uniforme, sin gafas · Calibración y detección de referencia | QA39, QA35 | planned |
| SC02 | A05 | Gafas transparentes sin reflejo ocultante · Igual objetivo; resultados separados | QA39, QA35 | planned |
| SC03 | A05 | Luz ambiental reducida pero ojos humanos anotables · Q y cobertura medidas; soporte solo si pasa | QA39, QA35 | planned |
| SC04 | A05 | Vibración/movimientos pequeños controlados · Sin unión de gaps ni falsas decisiones por tracking | QA39, QA35 | planned |
| SC05 | A05 | Parpadeos cortos y guiños · No RF12; W solo si cumple patrón real definido | QA39, QA03, QA12, QA14 | planned |
| SC06 | A05 | Hablar, cantar o apertura bucal aislada · Boca no dispara; evaluar cierres oculares visibles si ocurren | QA39, QA03, QA12, QA14 | planned |
| SC07 | A05 | Mirada lateral / hacia espejo simulado · No somnolencia por pose; fuera de referencia→No evaluable | QA39, QA03, QA12, QA14 | planned |
| SC08 | A05 | Gafas oscuras, mano oclusora, reflejo que oculta ojo · No medición ocular utilizable; prueba del EyeVisibilityGate | QA39, QA03, QA12, QA14 | planned |
| SC09 | A05 | Rostro ausente, cámara cubierta, oscuridad · No disponible/no evaluable, sin normalidad ficticia | QA39, QA03, QA12, QA14 | planned |
| SC10 | A05 | Dos caras visibles dentro del encuadre · Ambigüedad; no selección automática | QA39, QA03, QA12, QA14 | planned |
| SC11 | A05 | Pérdida y retorno, frames atrasados/desordenados · Corte, watchdog, Krecover y ausencia de alerta antigua | QA39, QA14, QA15 | planned |
| SC12 | A05 | Pausa, permiso retirado, cierre de proceso · Contratos Área 04; sin entrenamiento ni captura automática | QA39, QA16, QA17, QA19 | planned |
| SC13 | A05 | Cierre real visible con buena imagen · Q no lo rechaza por párpados juntos | QA39, QA12 | planned |
| SC14 | A05 | Cambio de montaje declarado/modelo · Referencia no aplicable, inicio bloqueado | QA39, QA07 | planned |
| EV01 | A05 | Configuración/manifestos/hash del APK, modelo, datos, split, anotación y protocolo completos · Reporte reproducible; tres ejecuciones fixture coherentes | QA39, QA40 | notRun |
| EV02 | A05 | Todos los fixtures de sección 21 pasan; cero alerta en pausa/no evaluable/generación vieja · Reporte unitario y de integración | QA11, QA12, QA13, QA14, QA15, QA16, QA39 | notRun |
| EV03 | A05 | Calibraciones con datos aptos ≥90 % aceptadas; controles de rechazo nunca guardan accepted · Denominadores por condición y los tres códigos | QA06, QA39 | notRun |
| EV04 | A05 | En condiciones calificadas: sensibilidad a tiempo H≥0,95 y precisión H≥0,90 · ≥60 referencias H y desglose por persona/condición | QA39 | notRun |
| EV05 | A05 | Advertencia: sensibilidad≥0,85 y precisión≥0,85 · ≥60 referencias W y etiquetas físicas independientes | QA39 | notRun |
| EV06 | A05 | FP H≤0,20/h y FP W≤1,00/h evaluable negativa · ≥20 h evaluables negativas; tasas por persona/condición | QA39 | notRun |
| EV07 | A05 | Cobertura frente a humanos≥0,90 agregada y≥0,85 por condición declarada · Tiempo anotable, rechazado y evaluable publicados | QA39 | notRun |
| EV08 | A05 | Rechazo de muestras cerradas válidas por Q≤5 % por condición · Referencia manual y causas de Q | QA39 | notRun |
| EV09 | A05 | Oclusión/ausencia/fallo técnico: ninguna nueva activación H/W una vez invalidado; estado notEvaluable y causa · SC08–SC11, relojes, deadline de watchdog y UI | QA14, QA39 | notRun |
| EV10 | A05 | p95 elegible→decisión≤1000 ms para eventos emparejados; todos los tardíos cuentan FN · No ocultar espera Krecover ni eventos perdidos | QA39 | notRun |
| EV11 | A05 | Captura→resultado p95<200 ms; decisión→sonido≤500 ms; 60 min, memoria/UI según RNF02/RNF07/RNF09 · Equipos y modos concretos, profile/release | QA35, QA39 | notRun |
| EV12 | A05 | Un ID por episodio, repetición exacta por política, ninguna dependencia de bostezo para H · Fixtures y videos de referencia | QA13, QA39 | notRun |
| EV13 | A05 | Mínimos de participantes, eventos, exposición y calidad de anotación cumplidos · Inventario dataset; faltantes no rellenados | QA39 | notRun |
| AI01 | A05 | Geometría vertical 6+6, horizontal20 px · EAR=0,30; división por0 o NaN→invalidGeometry | QA12 | notRun |
| AI02 | A05 | Imagen640×480 y su escala uniforme2× · EAR idéntico dentro de tolerancia1e−9 en doubles sintéticos | QA12 | notRun |
| AI03 | A05 | rR=rL=0,55 vs uno0,550001, Q válida · Primero C=true; segundo C=false | QA12 | notRun |
| AI04 | A05 | C válido cada100 ms, t0..1400 vs t1500 · Sin H antes; activación única en1500 | QA12 | notRun |
| AI05 | A05 | C válido sin boca/solo boca abierta · H idéntica sin bostezo; boca con ojos abiertos sin H/W | QA12 | notRun |
| AI06 | A05 | Una muestra Q inválida entre cierres · C/ventanas cortadas; no suma tramos; Krecover obligatorio | QA12, QA14, QA15 | notRun |
| AI07 | A05 | Gap capturas150 vs151 ms · Primero admite continuidad; segundo corta | QA12 | notRun |
| AI08 | A05 | Silencio recepción150/151/750 ms · Sin vencimientoG a150; limited a151; unavailable a750, scheduler≤100 ms | QA14 | notRun |
| AI09 | A05 | Resultado edad750 vs751 ms · 750 vigente; 751 rechazado; no alerta por cola vieja | QA14 | notRun |
| AI10 | A05 | Krecover1000 ms con6+ válidas vs999 ms · Usable solo al cumplir ambos; nueva C desde ese límite | QA15 | notRun |
| AI11 | A05 | Kcal60 muestras y cobertura0,80 vs59/0,799 · Primera pasa cantidad/cobertura si resto cumple; otras rechazan | QA06 | notRun |
| AI12 | A05 | Cierre ocular visible con altura casi0 y ancho apto · Q no falla por exigir ojos abiertos; demostrar en geometría y video | QA12, QA39 | notRun |
| AI13 | A05 | Comprobación cerrada sin separación/reapertura · unstableReference; no calibrationAccepted | QA06 | notRun |
| AI14 | A05 | Dos caras, ROI fuera, blur/luz fuera de límites · Motivos tipados; notEvaluable; no referencia ni alerta aceptadas | QA03, QA14 | notRun |
| AI15 | A05 | Seis bloques sección12 / ratio0,199999 / solo2 runs · W positiva a30500; controles no entran | QA11 | notRun |
| AI16 | A05 | W activa ratio0,10 vs0,100001 · Primera sale; segunda mantiene si no hubo corte | QA11 | notRun |
| AI17 | A05 | W pending499/500 ms · No entra a499; entra al primer resultado válido que completa500 | QA11 | notRun |
| AI18 | A05 | W activa y H entra durante periodo de sonido W · Mismo episodeId, categoría máxima H, dispatch inmediato H | QA13 | notRun |
| AI19 | A05 | H continua y sin audio iniciado · Intentos aentrada y +5000 ms como mínimo, no por frame; fallos no éxito | QA13 | notRun |
| AI20 | A05 | H/W falsas y Open1999/2000 ms · Episodio no cierra a1999; cierre normal a2000 con observación válida | QA13 | notRun |
| AI21 | A05 | Pérdida durante episodio / retorno · signalEnd null, corte observacional y nuevo segmento; no fusionar hueco | QA13, QA15 | notRun |
| AI22 | A05 | Pausar durante C y presentar fixture que activa H · Cero nueva decisión/episodio/aviso durante pausa | QA16 | notRun |
| AI23 | A05 | Callback de generación vieja tras stop/resume · Descarta; no toca calidad/señal/episodio actual | QA16, QA17, QA18 | notRun |
| AI24 | A05 | Misma política con muestreo irregular≤Gmax · Duraciones por timestamps; no por nºframes | QA11, QA12 | notRun |
| AI25 | A05 | Feed feedback“Útil”/“No percibí” · No cambia manifestos/umbrales ni señal histórica | QA24 | notRun |
| AI26 | A05 | Muestra no interpretable con landmarks plausibles · Falla EyeVisibilityGate si usable; caso obligatorio de SC08 | QA03, QA39 | notRun |
| AI27 | A05 | Primeros29999 ms de ventana W · W no lista; H continúa evaluable sin esperar W | QA11, QA12 | notRun |
| AI28 | A05 | Reproducciones repetidas/3 imports del mismo journal · Episodios únicos; conteos no aumentan | QA13, QA31 | notRun |
| DT01 | A06 | DDL V1 crea tablas/índices/triggers; foreign_key_check sin filas; huérfano rechaza · RNF05 | QA31 | notRun |
| DT02 | A06 | Borrar sesión cascada intervalos/episodios/transiciones/avisos/feedback; barrera sobrevive · RF27 | QA27 | notRun |
| DT03 | A06 | Modificar snapshot/versiones de sesión existente rechaza; recalibrar no cambia historia · RF07, RF29 | QA07, QA29 | notRun |
| DT04 | A06 | Intervalos superpuestos rechazan; contiguos aceptan; uno abierto por sesión · RF21 | QA21, QA31 | notRun |
| DT05 | A06 | Feedback solo finalized; reemplazo conserva episodio; otra sesión vigente bloquea vía producto · RF24, UX16 | QA24 | notRun |
| DT06 | A06 | Nativo no admite dos sesiones actuales; intento failed sin inicio no suma historia · RF08 | QA08 | notRun |
| DT07 | A06 | Mismo recordId/hash importa tres veces no duplica; hash distinto bloquea; ACK posterior a commit · RF31, RNF05 | QA31 | notRun |
| DT08 | A06 | ACK de primera revisión no elimina actualización posterior; gap sin disposition mantiene pendiente · RF31 | QA31 | notRun |
| DT09 | A06 | Caer después de commit antes ACK conserva datos; después de muerte final sigue desconocido · RF19, RF31 | QA19, QA31 | notRun |
| DT10 | A06 | DS01–DS04 dan tiempos/coberturas/tasas correctos y null con denominador0 · RF21, RF25 | QA21, QA25 | notRun |
| DT11 | A06 | DS08/cambio zona: corte por fechas, igualdad conserva; vigente excluida · RF28 | QA28 | notRun |
| DT12 | A06 | Borrado cae en cada etapa; lote viejo no restaura; un fallo no muestra éxito · RF27, UX19 | QA27 | notRun |
| DT13 | A06 | Reset de contexto cae entre Room/Drift; mismo newDatasetId al reintentar; alias/ref/staging desaparecen · RF27 | QA27 | notRun |
| DT14 | A06 | JSON parser de prueba conserva IDs/conteos/FK/pausas y reconoce incompleto; sin foto/alias/logs · RF26 | QA26 | notRun |
| DT15 | A06 | CSV relectura mismo nºcolumnas con coma/comillas/CRLF; null≠0; IDs relacionan archivos · RF26 | QA26 | notRun |
| DT16 | A06 | DS05: solo un CSV escrito→partial/D08; cancelación nunca éxito; unknown tras caída no se vuelve written · UX18 | QA26 | notRun |
| DT17 | A06 | Snapshot de exportación congelado; borrar fuente invalida staging; TTL24 h purga · RF26, RF27 | QA26, QA27 | notRun |
| DT18 | A06 | Backups cloud/D2D no devuelven bases/referencias/staging; evidencias por Android/equipo · decisión Área04 | QA37 | notRun |
| DT19 | A06 | Modelo real/demo con bases distintas; fixture jamás entra a historial real · RF32 | QA32 | notRun |
| DT20 | A06 | Buffer excede count/bytes: pérdida identificada; no ACK ficticio ni reconstrucción · RF21, RF31 | QA31 | notRun |
| DT21 | A06 | Calibración inválida nunca persiste accepted; datos no finitos/JSON duplicado/version desconocida rechazan · RF06 | QA06, QA37 | notRun |
| DT22 | A06 | SQLite con WAL, borrado y checkpoint mantiene consistencia; sin promesa de borrado forense · RF27, RNF09 | QA27, QA37 | notRun |
| DT23 | A06 | Ruta de migración real conserva datos/barreras; fallo no hace drop/recreate · RNF05, RNF08 | QA31, QA37 | notRun |
| DT24 | A06 | Códigos/IDs de prefijo fórmula rechazan; JSON no normaliza/alterar Unicode silenciosamente · RF26 | QA26, QA37 | notRun |
