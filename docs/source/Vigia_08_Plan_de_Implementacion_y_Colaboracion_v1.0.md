# Vigía · Área 08: plan de implementación y colaboración

**Versión:** 1.0 · **Fecha:** 5 de octubre de 2026 (UTC) · **Proyecto:** Vigía, Android primero; iOS futuro · **Autor del proyecto:** Juan José Rueda Viveros.

**Estado de esta entrega:** especificación de ejecución. No se creó la app, un repositorio Git ni una cuenta externa. Las tareas, pruebas de producto y puertas de aceptación siguen pendientes. La validación al final comprueba este documento y sus referencias, no el funcionamiento de una aplicación.

## 1. Resultado y alcance

Esta área convierte las especificaciones anteriores en una secuencia ejecutable: estructura del repositorio, 72 tareas por dependencias, once hitos, reglas de colaboración entre Codex y Claude Code y evidencia necesaria para cerrar cada entrega. Conserva los 310 IDs fuente del Área 07 y sus 40 casos QA. No reduce V1 para facilitar la demo académica.

El primer resultado técnico será una integración pequeña sobre teléfono físico: cámara frontal → modelo facial local → evento tipado → UI → registro durable. Después se integran Q, calibración, política temporal, sesión y almacenamiento recuperable; luego la interfaz completa. La excelencia visual tiene tareas y gates propios, además de accesibilidad, privacidad, desempeño y evaluación de señales.

No forman parte de la ejecución actual: codificar, crear repositorios/cuentas, publicar, enviar mensajes, reclutar participantes o realizar grabaciones. Tampoco se incorporan backend, login, GPS, micrófono, LLM, flotas ni cámara externa. La app culinaria y Wear OS se estructuran por separado después.

## 2. Fuentes, precedencia y cambios

| Fuente vigente | Autoridad y uso en implementación |
|---|---|
| Vigia_01_PRD_Producto_y_Alcance_v1.1.md | Alcance y 126 criterios RF/RNF: 96 RF y 30 RNF |
| Vigia_02_UX_Flujos_y_Navegacion_v1.0.md | 66 criterios UX, IDs P01–P18/D01–D08, acciones, estados y guardas |
| Área 03, brief B4.2/B5.2 + HTML completo por recibir | Referencia visual; no modifica estados ni criterios funcionales |
| Vigia_04_Arquitectura_Tecnica_y_Contratos_v1.0.md | Componentes, autoridad, estados, comandos/eventos y AT01–AT22 |
| Vigia_05_IA_y_Protocolo_de_Evaluacion_v1.0.md | Q/Kcal/política experimental, AI01–AI28, EV01–EV13, SC01–SC14 |
| Vigia_06_Modelo_de_Datos_y_Privacidad_v1.0.md | DDL/contratos de datos, borrado/exportación, DT01–DT24 y DS00–DS08 |
| Vigia_07_Plan_de_Pruebas_Calidad_y_Distribucion_v1.0.md | QA01–QA40, etapas E0–E4, G01–G10, RL01–RL12 y 310 IDs trazados |
| Esta Área 08 | Orden de construcción, propiedad de cambios, backlog y cierre de tareas |

No existe una regla de “gana el documento más reciente” para todo. PRD/UX definen el comportamiento; arquitectura/IA/datos definen cómo mantener sus garantías; QA define cómo demostrarlo; el diseño define presentación. Una contradicción se registra con ambas citas y se resuelve mediante ADR y versión del documento afectado antes de implementar el comportamiento en disputa. Una plantilla, conversación o herramienta no puede suavizar un criterio vigente.

VIG-001 copia las fuentes a `docs/source/` conservando nombres/versiones y crea `docs/spec-index.json` con ruta, versión, hash SHA-256 y estado de recepción. Los documentos de trabajo de `docs/` referencian dichas fuentes y no reemplazan silenciosamente el original. Un cambio incluye IDs afectados, motivo, revisión, código/tests pendientes y evidencia invalidada. Las rutas `docs/evidence/` contienen informes saneados; datasets, rostros y archivos personales permanecen fuera de Git.

El PRD conserva pendientes históricos sobre Kcal: el Área 05 concreta una política experimental, pero su calificación física requiere EV. La frase “120 vistas comprobadas” del summary B5.2 no es evidencia independiente. El HTML completo y su inventario todavía faltan. La navegación escalada al 135 % en ese summary no satisface el requisito Android al 200 %.

## 3. Stack y decisiones de implementación

| Elemento | Decisión conservada | Comprobación antes de considerarlo operativo |
|---|---|---|
| UI | Flutter/Dart, Riverpod, go_router, tokens propios | Compilación, navegación por autoridad nativa, QA33/QA34 físicos |
| Historia | Drift/SQLite en Flutter | DDL/migraciones, constraints, proyecciones y DT |
| Motor Android | Kotlin, CameraX, MediaPipe, coroutines, Room | Pipeline físico, actor único, AT/AI y fallos recuperables |
| Puente | Pigeon para órdenes/DTO; stream compacto versionado y snapshot | Generados de versión idéntica y reconciliación, sin frames |
| Alertas | Audio nativo + foreground service camera | AudioFocus, estados técnicos, restricciones reales y cierre |
| IA | Modelo facial neural local + política temporal especificada | EyeVisibilityGate, Kcal/AI y EV independientes de fixtures |
| Archivo externo | SAF con adapter nativo tipado independiente de sesión | Copia/cierre/cancelación/partial/unknown; sin permiso general |
| Dependencias | Versiones compatibles fijadas en H00 | Lockfile, wrapper y build limpio, sin Android `+` dinámico |
| iOS | Mismo dominio/contratos; futuro adapter Swift | Sin iOS disponible, ni cámara fake ni soporte anunciado en V1 |

Se conserva una app raíz y un plugin local. No hace falta un monorepo con otras dos apps ni un paquete por pantalla. La app usa dependencia `path` hacia `packages/monitoring_engine`; Pub Workspaces queda opcional para cuando exista necesidad real de resolución compartida. Si se adopta, registrar requisitos de Dart y lockfile en ADR; no introducirlo por moda [S4].

Flutter, Dart, Pigeon, Kotlin, AGP, JDK, Gradle, SDK y librerías no reciben versiones inventadas aquí. VIG-002/003 fijan una matriz compilada. Reglas Play/target y cuenta se vuelven a consultar en VIG-069; las verificaciones del Área 07 no sustituyen la comprobación al envío.

## 4. Estructura prevista del repositorio

Las rutas siguientes describen el repositorio futuro, no carpetas creadas por esta entrega. Los directorios `domain/data/presentation` solo se añaden cuando existe una responsabilidad concreta; no se fabrica una clase por cada getter.

| Ruta | Contenido y propietario de responsabilidad |
|---|---|
| README.md | Propósito, etapas reales, arranque reproducible y comandos verificados |
| AGENTS.md / CLAUDE.md | Reglas comunes e importación explícita; sin secretos ni configuración global |
| pubspec.yaml / pubspec.lock | Dependencias de app y enlace al plugin; resolución bloqueada |
| android/ | Host Flutter, flavors, manifest/backup, empaquetado y firma referenciada |
| docs/source/ / docs/spec-index.json | Especificaciones originales, versiones/hashes y faltantes |
| docs/product.md / ux.md / screens.md | Alcance, flujos y registro pantalla/estado/criterio |
| docs/architecture.md / ai.md / data.md | Interfaces vigentes y garantías técnicas |
| docs/design-system.md / motion.md / licenses.md | Tokens, componentes, comportamiento motion, procedencia/atribuciones |
| docs/testing.md / toolchain.md / roadmap.md | Campañas, dispositivos, herramientas, tareas y dependencias |
| docs/decisions/ / issues/ | ADR numerados y fallos con reproducción/impacto |
| docs/tasks/ / handoffs/ | Ficha VIG y entrega reproducible entre herramientas |
| docs/evidence/ / release/ / operations/ | Informes saneados, hashes, decisiones de etapa y procedimientos |
| lib/app/bootstrap/ / router/ / providers/ | Resolución inicial, composición y guardas, sin otra autoridad de sesión |
| lib/core/design_system/ | Tokens/temas, componentes, accesibilidad y movimiento |
| lib/core/monitoring/ | Adapter tipado, conexión, codec y proyección de snapshot |
| lib/core/database/ | Drift, migraciones, importación durable y proyecciones |
| lib/core/export/ | Snapshot/staging/serialización y ProductOperationCoordinator, adapter SAF |
| lib/features/onboarding/ | Incorporación versionada y permisos |
| lib/features/preparation/ / calibration/ | Montaje, seis puertas, referencia y sonido previo |
| lib/features/monitoring/ | P06 y acciones de sesión; UI consume hechos del motor |
| lib/features/history/ | Resumen P07, historial P08, sesión P09, episodio P10, tendencias P11 y feedback |
| lib/features/settings/ | Tema/sonido/datos/alias/exportación y Ayuda |
| assets/fonts/ / icons/ / sounds/ / help/ | Recursos locales con licencia; sin carga web en runtime |
| packages/monitoring_engine/lib/ | API Dart del plugin; generados internos sin widgets de producto |
| packages/monitoring_engine/pigeons/ | monitoring_api.dart, document_export_api.dart y configuración de generación |
| packages/monitoring_engine/android/src/main/kotlin/<namespace>/ | plugin/, coordinator/, camera/, inference/, policy/, journal/, alerts/, export/ |
| packages/monitoring_engine/android/src/test/ / androidTest/ | Unitarias Kotlin e instrumentación Android |
| test/ / integration_test/ / testdata/ | Tests Dart/widget/golden, recorridos e inputs sintéticos identificados |
| ml/models/ / manifests/ / protocol/ / evaluation/ / reports/ | Assets permitidos y hashes, protocolo, evaluación; sin dataset personal |
| tools/ | Generación, validadores, bench y comandos reproducibles de build |
| .github/workflows/ | Solo si se adopta GitHub: CI derivada de comandos locales existentes |

`<namespace>` se sustituye por la identidad elegida en H00; no se deja como paquete compilable. PackageId de distribución y marca no se adivinan a partir de “Vigía”. Paths Android definitivos quedan reflejados en README al crear el plugin [S6].

### 4.1 Dirección de dependencias y autoridad

Widgets → casos de uso/providers → repositorios/adapters → plugin/Drift. El plugin no importa widgets ni la base Drift. `SessionCoordinator` nativo es la única autoridad de sesión/cámara/política/alertas. Drift es historia consolidada; Room es journal durable; `ProductOperationCoordinator` serializa operaciones de producto incompatibles, sin convertirse en otro motor.

Los estados de ciclo, medición, señal, conexión, comando y registro se conservan separados. Un error de journal no equivale automáticamente a una sesión finalizada; una UI desconectada no equivale a proceso muerto. Ninguna pantalla deduce “Activa” por haber pulsado Iniciar.

Un repositorio/caso de uso puede compartirse entre resumen, detalle, tendencia y exportación; todos usan las mismas proyecciones. No habrá una fórmula de cobertura diferente en cada pantalla. No se crea un segundo servicio para detectar señales desde Dart.

### 4.2 Propiedad exacta de pantallas y diálogos

Los nombres siguientes proceden del inventario UX vigente; una referencia visual no los renumera. Tarea principal integra pantalla/diálogo y delega la operación al motor o repositorio correspondiente.

| ID | Nombre UX | Tarea principal de integración |
|---|---|---|
| P01 | Bienvenida y procesamiento | VIG-035 |
| P02 | Permiso de cámara | VIG-035 |
| P03 | Inicio | VIG-035 |
| P04 | Preparación | VIG-036 |
| P05 | Calibración | VIG-036 |
| P06 | Monitoreo y pausa | VIG-037 |
| P07 | Resumen | VIG-039 |
| P08 | Historial | VIG-040 |
| P09 | Detalle de sesión | VIG-041 |
| P10 | Detalle de episodio | VIG-041 |
| P11 | Tendencias | VIG-042 |
| P12 | Ajustes | VIG-043 |
| P13 | Sonido | VIG-043 |
| P14 | Datos | VIG-043 |
| P15 | Exportación | VIG-046 |
| P16 | Temas de ayuda | VIG-044 |
| P17 | Artículo de ayuda | VIG-044 |
| P18 | Perfil local opcional | VIG-043 |
| D01 | Salir de preparación iniciada | VIG-036 |
| D02 | Finalizar sesión | VIG-037 |
| D03 | Eliminar una sesión | VIG-041 |
| D04 | Reducir retención | VIG-043 |
| D05 | Volver desde monitoreo | VIG-037 |
| D06 | Recuperar sesión interrumpida | VIG-035 |
| D07 | Borrar todos los datos | VIG-043 |
| D08 | Exportación CSV parcial | VIG-046 |

## 5. Unidad de trabajo, entrada y salida

### 5.1 Estados de tarea y estados de prueba

| Estado de tarea | Condición observable |
|---|---|
| planned | Definida; sin implementación/evidencia nueva |
| ready | Dependencias técnicas listas, DoR completa, responsable y revisión asignados |
| inProgress | Un escritor trabaja en paths declarados; commit base identificado |
| blocked | Falta decisión/entorno/material; causa, siguiente acción y dueño registrados |
| inReview | Diff y evidencia listos; responsable deja de modificar mientras se revisa |
| changesRequested | Revisión identifica fallo concreto; vuelve a un escritor |
| done | Entregable, criterios locales y revisión completos; evidencia enlazada |

Pruebas conservan `notRun/passed/failed/blocked/notApplicable` del Área 07 y gates su estado separado. Una tarea puede terminar como preparación de protocolo con ensayos aún `notRun`; no puede declararse `done` si su criterio local exigía ejecutar esos ensayos y no se ejecutaron. `notApplicable` no permite excluir RF/UX vigente de V1. Un gate no cambia automáticamente al cerrar una tarea.

**Definition of Ready (DoR):** fuente/versiones e IDs identificados; dependencias disponibles; input/resultado y paths claros; decisión de contrato resuelta si aplica; entorno/fixtures autorizados disponibles; escritor y revisor asignados; criterios locales y evidencia acordados. Si falta el HTML, equipos o participantes, se pueden preparar tareas independientes, pero no aprobar el resultado que depende del faltante.

**Definition of Done (DoD común):** entregable revisado sobre diff real; criterios locales comprobados; comandos ejecutados y resultados publicados; regresión proporcional al cambio Área 07; sin incumplimiento S0/S1; documentación/ADRs/lockfiles/generados coherentes; evidencia saneada y hash/commit vinculados; ningún pendiente escondido como éxito. El autor puede efectuar revisión técnica con otra herramienta; cuando no hay revisor independiente, se registra explícitamente autorrevisión y el gate que requiere aprobación externa sigue abierto.

### 5.2 Prioridad y alcance

Prioridad se calcula por dependencia y gate, no por títulos como “Alta”. Dentro de cada hito se toma primero el ID listo que desbloquea la siguiente prueba; si hay un S0/S1, se atiende su reproducción/corrección antes de nuevo alcance. UI y motion tienen hitos propios y no se descartan para “terminar rápido”. Un bloqueo de EyeVisibilityGate no se resuelve quitando Q.

WIP por defecto: **una tarea de implementación, un escritor, una rama**. Codex y Claude Code no editan simultáneamente el mismo árbol. Cambios de contrato, schema, lockfile, manifest y configuración de generación tienen un único responsable por tarea. No se crean subagentes ni se asigna trabajo paralelo en esta planificación.

## 6. Contratos de integración que condicionan el backlog

### 6.1 Cámara/modelo/evento/UI/journal del H01

La preparación no es una sesión. El pipeline físico puede probar presencia de rostro/inferencia y `preparationChanged` manteniendo Q/cal/sonido pendientes. Su control durable genera un `technicalFailure` identificado, por ejemplo modelo alterado en labReal o permiso retirado, y lo relee de Room. No se inventa un evento nuevo para fingir inferencia; campos extra necesarios pasan por VIG-007/ADR.

El H01 no acepta Kcal, no activa alertas por datos inventados y no aprueba RF09 solo por ver un contador. RF09 requiere preparación/calibración válidas y diez minutos físicos como Área 07. H01 demuestra el cableado temprano y permite resolver toolchain/rotación/asset antes de implementar todas las pantallas.

### 6.2 Persistencia y recuperación

Orden durable: Room → lectura validada JCS/hash/versión → transacción Drift → ACK de recordId/hash exactos. UI stream y animaciones no crean historia. Dos bases no son una transacción atómica: borrado tiene etapas/tombstones y reset de dataset idempotente; exportación congela selección y distingue copia externa de commit interno.

VIG-007 incluye `commitDatasetReset(operationId, newDatasetId)` del Área 06, además de todas las órdenes Área 04. Nanos se transportan según contrato seguro; no se convierten a números JSON inseguros. Generados Dart/Kotlin se producen con la misma versión de Pigeon, permanecen dentro del mismo plugin y se regeneran juntos [S5].

### 6.3 ADR08-01 propuesto: adapter de documentos SAF

Área 04 requiere SAF; su API de monitoreo no enumera el selector/escritura de documentos. Se propone cerrar ese punto con **`DocumentExportHostApi` independiente dentro del plugin local**, en `pigeons/document_export_api.dart` y Android `export/`. Es un ADR de implementación por revisar en VIG-007, no una API ya construida. No amplía la autoridad del motor.

Contrato previsto:

| Operación/DTO | Datos y efecto |
|---|---|
| getExportStagingDirectory() | Devuelve raíz privada de staging; no URI externo ni permiso general |
| exportDocument(request) | `operationId`, `exportId`, `stagedFileName`, `suggestedFileName`, `mimeType`; un selector/copia a la vez bajo la exclusión de ProductOperationCoordinator |
| DocumentExportResult | Mismos IDs + `status` canceled/written/failed/unknown, código tipado si aplica; ningún URI persistente |

El adapter valida ruta canónica dentro de `filesDir/exports-staging/<exportId>/`, archivo permitido y existencia. Nunca acepta una ruta arbitraria para leer archivos del usuario. Cada `operationId` refiere un intento, no toda la exportación; un reintento deliberado recibe otro ID, conserva exportId/snapshot y solo toma el archivo pendiente. No reabrir selector por repetir una misma llamada pendiente. `written` requiere copia y cierre exitosos; si el proceso muere después de cierre externo, el estado durable puede quedar `unknown` al recuperar: no repetir ni sobrescribir automáticamente. El estado de negocio por archivo queda en Drift conforme Área 06.

El selector se lanza desde Activity visible; cancelación devuelve canceled sin éxito ficticio. URI/grant temporal se usa en memoria y se libera, sin `takePersistableUriPermission`, base de URI ni logs de destino. El adapter no inicia preparación ni cámara. JSON y los dos CSV pueden tener resultados distintos; SAF no vuelve atómica su escritura conjunta. Archivos locales pueden guardarse offline; proveedores externos remotos están fuera de esa garantía.

Cualquier diferencia necesaria en el DTO se aprueba dentro de VIG-007, con actualización de arquitectura/QA26 y generación conjunta; no se implementa un canal improvisado dentro de un widget.

## 7. Hitos y puertas de salida

Los hitos ordenan entregas; las dependencias de tarea indican lo que se necesita realmente para trabajar. Una tarea independiente de diseño o protocolo puede prepararse antes si se registra el cambio de orden y no aumenta WIP. No se asignan semanas ni fechas inventadas: duraciones dependen de dispositivos, HTML y participantes aún desconocidos.

| Hito | Tareas | Entrega observable | Salida y límites |
|---|---|---|---|
| H00 · Preparación de ejecución | 001–006 | Fuentes, toolchain, app/plugin vacío, variantes, instrucciones y harness | DoR del pipeline; G01 actualizado, no gates físicos aprobados |
| H01 · Primera integración física | 007–014 | CameraX/modelo real→evento tipado→UI y fallo durable→Room | Demostración en D1; G02 solo parcial; no RF09 terminado |
| H02 · Motor y política | 015–022 | Q/cal/C/H/W/episodios/sonido/seis puertas con fixtures | AI y AT locales pertinentes; G03 requiere campaña completa en H07; G08 pendiente |
| H03 · Datos y recuperación | 023–031 | Journal/importación/ACK, ciclo completo, borrado/retención/migraciones | DT y escenarios locales; G04 exige evidencia de fallos Android H07 |
| H04 · Interfaz principal | 032–039 | Design system Flutter, onboarding/preparación/monitoreo/router/resumen | Estados reales conectados; G05 pendiente Android/QA33/QA34 |
| H05 · Producto funcional | 040–047 | Historia/detalle/feedback/tendencias/ajustes/ayuda/exportación/demo | Ninguna acción fake o pendiente; aún no V1 aceptada |
| H06 · Calidad de interfaz | 048–051 | Texto/TalkBack/baseline/motion/usuarios | G05 y G07 solo si evidencia completa; alto acabado visual medido |
| H07 · Calidad integrada | 052–058 | Host/Android/fallos/privacy/dispositivos/soak/paquete | G02–G04/G06 según ejecución; no sustituye G08 |
| H08 · Evaluación de señales | 059–063 | Piloto/holdout/EV/calificación versionada | G08 si todos los mínimos cumplen; señal validada no equivale a contexto comercial |
| H09 · Candidatos y entrega | 064–066 | CI reproducible, E2 académico y candidato E3 | E2 puede tener pendientes explícitos; E3 requiere G02–G09 y 192 CA |
| H10 · Preparación comercial | 067–072 | Contexto E4, privacidad/cuenta/firma/soporte/paquete/procedimientos | G10/RL para E4; publicación requiere instrucción posterior |

El orden crítico inicial es H00 → H01 → H02/H03 → interfaz integrada. H06/H07/H08 alimentan la aceptación de E3; ninguna suple a otra. H08 puede necesitar varias iteraciones y holdouts nuevos; el backlog no garantiza que la primera política sea suficientemente precisa.

## 8. Backlog ejecutable

Cada ficha contiene dependencia directa, paths de responsabilidad, resultado y cierre observable. Todos los IDs parten de **planned**, **responsable/revisor unassigned** y **evidencia notRun**. Antes de ejecutarlos se completa la ficha §10. Las referencias QA son suites/criterios de verificación pertinentes; una ficha no promete ejecutar íntegramente una suite antes de existir sus demás dependencias. El hito de campaña reúne la evidencia completa.

Las pruebas locales indicadas en “Cierre” sí son obligatorias para terminar esa tarea. Si el cierre exige personas, dispositivo o respuesta de tienda que no existe, permanece blocked/notRun; no se sustituye por una salida redactada por IA.

### H00

#### VIG-001 · Consolidar la especificación vigente

**Depende de:** Ninguna. **Paths:** `docs/, docs/decisions/`.

**Entrega:** Copias de las fuentes y registro de versiones, hashes, 310 IDs, 40 QA y 12 RL; relación de contradicciones abiertas.

**Cierre:** Comparar cada ID con Área 07; cero omitidos/duplicados. Registrar que Kcal experimental del Área 05 concreta el pendiente del PRD sin convertirlo en calificación física. No tratar el summary B5.2 como HTML inspeccionado.

**Verificación relacionada:** QA40. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-002 · Fijar toolchain y equipos de referencia

**Depende de:** VIG-001. **Paths:** `docs/toolchain.md, docs/testing.md`.

**Entrega:** Matriz Flutter/Dart/Pigeon/Kotlin/JDK/Gradle/AGP/SDK/CameraX/MediaPipe/Room/Drift y registro D1–D4/P16K/EM con equipos realmente disponibles.

**Cierre:** Conservar salida de herramientas; comprobar compatibilidad por compilación en VIG-003, no solo por tabla. minSdk 26 es candidato hasta esa comprobación. Marcar cada equipo ausente como pendiente; revalidar target al distribuir.

**Verificación relacionada:** QA35, QA36, QA40. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-003 · Crear la app y un único plugin local Android

**Depende de:** VIG-002. **Paths:** `pubspec.yaml, pubspec.lock, android/, packages/monitoring_engine/`.

**Entrega:** App Flutter vacía ejecutable y plugin Kotlin local enlazado por path, wrapper Gradle y dependencias resueltas.

**Cierre:** Instalación en D1 y compilación limpia desde el lockfile; la segunda compilación no modifica resolución. Sin backend, segundo dueño de cámara, WebView de producto ni plataforma iOS declarada operativa.

**Verificación relacionada:** QA32, QA40. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-004 · Separar real, demo y harness de laboratorio

**Depende de:** VIG-003. **Paths:** `android/, lib/app/bootstrap/, testdata/, docs/testing.md`.

**Entrega:** Configuraciones con applicationId, almacenamiento y entrada de datos separados; etiqueta permanente de simulación en demo.

**Cierre:** Instalar real y demo simultáneamente y comprobar aislamiento. candidateReal excluye fixtures y controles de inyección; labReal declara sus hooks. Auditar manifest fusionado: núcleo real sin INTERNET ni permisos de micrófono/GPS/almacenamiento general.

**Verificación relacionada:** QA09, QA32, QA37, QA40. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-005 · Instalar reglas comunes de colaboración

**Depende de:** VIG-001, VIG-003. **Paths:** `AGENTS.md, CLAUDE.md, README.md, docs/roadmap.md`.

**Entrega:** Instrucciones de proyecto, plantilla de tarea/PR/handoff y dueño único por cambio; CLAUDE.md importa las reglas comunes.

**Cierre:** Comprobar que las dos herramientas encuentran las instrucciones en la raíz y señalan las mismas fuentes. Ninguna regla declara aprobados ensayos, obliga a publicar o altera configuración global del usuario.

**Verificación relacionada:** QA40. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-006 · Preparar harness y registro de evidencia

**Depende de:** VIG-003, VIG-004, VIG-005. **Paths:** `test/, integration_test/, packages/monitoring_engine/android/, tools/, docs/testing.md`.

**Entrega:** Reloj controlable, fixtures identificados, simulador de fallos, esquema run-manifest y comandos de validación realmente disponibles.

**Cierre:** Un caso de cada nivel produce passed/failed/notRun con artefacto y expected/actual; fixture no se presenta como cámara física. Hooks de reloj/fallo no se empaquetan en candidateReal.

**Verificación relacionada:** QA31, QA32, QA40. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

### H01

#### VIG-007 · Declarar contratos y cerrar interfaces pendientes

**Depende de:** VIG-001, VIG-003, VIG-006. **Paths:** `packages/monitoring_engine/pigeons/, docs/decisions/ADR08-01-export.md`.

**Entrega:** DTO/enums/API de Área 04, commitDatasetReset de Área 06 y API SAF independiente especificada en §6.3.

**Cierre:** Revisión campo por campo de nulabilidad, UUID, versiones, estados, errores, relojes y límites de lote. Sin Map anónimo en widgets. Exportar no introduce una segunda autoridad de sesión ni comparte ACK con archivos externos.

**Verificación relacionada:** QA08, QA10, QA20, QA26, QA27, QA31, QA32. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-008 · Generar y validar ambos lados de Pigeon

**Depende de:** VIG-007, VIG-002. **Paths:** `packages/monitoring_engine/lib/src/generated/, packages/monitoring_engine/android/`.

**Entrega:** Dart/Kotlin generados por la misma versión exacta y prueba de roundtrip de enums/DTO.

**Cierre:** Regeneración desde checkout limpio deja diff vacío; valor/esquema no soportado rechaza con error tipado. Generados internos del mismo plugin, sin edición manual ni publicación separada de un lado.

**Verificación relacionada:** QA20, QA32, QA40. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-009 · Construir coordinator, snapshots y comandos base

**Depende de:** VIG-008, VIG-006. **Paths:** `packages/monitoring_engine/android/src/main/kotlin/<namespace>/coordinator/, lib/core/monitoring/`.

**Entrega:** Actor nativo, capabilities, preparación, commandId, stateRevision/eventSequence/engineInstanceId y stream compacto.

**Cierre:** Idempotencia de payload y rechazo de mismatch; revisión vieja no retrocede estado. Heartbeat 1000 ms, canal sin señales 3000 ms y consulta de comando a 5 s conservan incertidumbre. No se implementa una sesión Activa ficticia para la demo del pipeline.

**Verificación relacionada:** QA08, QA10, QA20, QA32. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-010 · Conectar CameraX y preview nativo

**Depende de:** VIG-009, VIG-004. **Paths:** `packages/monitoring_engine/android/src/main/kotlin/<namespace>/camera/, lib/core/monitoring/`.

**Entrega:** Cámara frontal, rotación/transformación, backpressure y preview con único propietario nativo.

**Cierre:** Abrir/cerrar preparación repetidamente libera recursos; permiso negado y cámara ocupada producen causas distintas. Ningún frame cruza Pigeon ni Flutter obtiene una segunda captura. Registrar captura/recepción monotónicas.

**Verificación relacionada:** QA02, QA03, QA09, QA18, QA35. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-011 · Empaquetar y ejecutar el modelo facial local

**Depende de:** VIG-010. **Paths:** `packages/monitoring_engine/android/src/main/kotlin/<namespace>/inference/, ml/models/, docs/licenses.md`.

**Entrega:** Asset MediaPipe con versión, SHA-256, procedencia y licencia; resultados de cámara física sin nube.

**Cierre:** Hash alterado/asset ausente bloquean modelo con códigos estables. Conservar traza sin imágenes ni malla completa persistida. Landmarks por sí solos no habilitan Q ni afirman detectar somnolencia; EyeVisibilityGate sigue en VIG-016.

**Verificación relacionada:** QA03, QA09, QA32, QA37, QA40. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-012 · Crear el journal nativo mínimo

**Depende de:** VIG-009, VIG-006. **Paths:** `packages/monitoring_engine/android/src/main/kotlin/<namespace>/journal/`.

**Entrega:** Room/outbox con identidad de dataset, secuencia, payload/hash y registro durable de fallo técnico de preparación.

**Cierre:** Reabrir proceso y releer el mismo recordId/hash; no se escribe una sesión si no hubo inicio aceptado. La captura y alertas futuras no quedan bloqueadas por el consumidor Dart. El DDL completo sigue en VIG-024/028.

**Verificación relacionada:** QA19, QA31, QA37. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-013 · Mostrar el pipeline mediante adapter tipado

**Depende de:** VIG-008, VIG-009, VIG-010, VIG-011, VIG-012. **Paths:** `lib/core/monitoring/, lib/features/preparation/`.

**Entrega:** UI provisional de preparación que consume preparación/snapshot, preview y causas bloqueantes; readPendingRecords/ACK solo como diagnóstico de laboratorio.

**Cierre:** Sin botón de inicio operativo antes de calibración/sonido/Q. Mostrar un resultado real de presencia facial y el fallo técnico durable; stream UI no se usa como fuente de historial. Mantener tipos y distinguir pérdida del canal de fallo del modelo.

**Verificación relacionada:** QA03, QA05, QA20, QA31. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-014 · Demostrar la primera integración física

**Depende de:** VIG-013. **Paths:** `docs/evidence/H01/, docs/roadmap.md`.

**Entrega:** APK labReal, manifiesto de ejecución y traza cámara→modelo→preparationChanged→UI; fallo controlado technicalFailure→Room→lectura tipada.

**Cierre:** Instalar en D1 sin datos/Wi-Fi y reproducir ambos recorridos. No iniciar sesión sin seis puertas, ni guardar imágenes, ni contar la prueba como RF09 de diez minutos completada. Bloqueos de compatibilidad pasan a incidencia con reproducción.

**Verificación relacionada:** QA03, QA05, QA09, QA31, QA40. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

### H02

#### VIG-015 · Implementar EAR y normalización geométrica

**Depende de:** VIG-011, VIG-006. **Paths:** `packages/monitoring_engine/android/src/main/kotlin/<namespace>/inference/, packages/monitoring_engine/android/src/main/kotlin/<namespace>/policy/`.

**Entrega:** EAR por ojo con índices de Área 05, coordenadas orientadas en píxeles y ratios sobre referencia.

**Cierre:** Fixtures de rotación/escala/NaN y pares de ojos comprueban fórmulas; división imposible produce no evaluable. No persistir ni exportar malla completa; no usar altura del párpado como prueba de visibilidad.

**Verificación relacionada:** QA03, QA06, QA12, QA14, QA37. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-016 · Resolver Q y EyeVisibilityGate

**Depende de:** VIG-015, VIG-014. **Paths:** `packages/monitoring_engine/android/src/main/kotlin/<namespace>/inference/, ml/, docs/ai.md`.

**Entrega:** Filtro de calidad, razones tipadas y decisión reproducible de visibilidad ocular con versión y controles SC08/SC13.

**Cierre:** Verificar todos los umbrales Q del Área 05 y landmarks plausibles con ojo ocluido. Cierre válido no se rechaza por ser cierre. Si no se consigue separar visibilidad/oclusión, registrar bloqueo G08; no omitir esta puerta para completar producto.

**Verificación relacionada:** QA03, QA06, QA12, QA14, QA39. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-017 · Implementar Kcal e invalidación de referencia

**Depende de:** VIG-016, VIG-012. **Paths:** `packages/monitoring_engine/android/src/main/kotlin/<namespace>/policy/, packages/monitoring_engine/android/src/main/kotlin/<namespace>/journal/, lib/core/monitoring/`.

**Entrega:** Calibración guiada 8 s, mínimo 60/cobertura 0,80, estabilidad, dos probes cerrados/reapertura y snapshot versionado.

**Cierre:** AI11–AI13 y AT05: aceptar solo secuencia íntegra; tres códigos de rechazo, cancelación y Cambié la posición conservan bloqueo. Guardar referencia aceptada única; versiones incompatibles impiden inicio sin alterar historia.

**Verificación relacionada:** QA06, QA07, QA29, QA37. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-018 · Implementar continuidad C y cierre H

**Depende de:** VIG-017, VIG-006. **Paths:** `packages/monitoring_engine/android/src/main/kotlin/<namespace>/policy/, packages/monitoring_engine/android/src/test/kotlin/<namespace>/`.

**Entrega:** Ratios cierre ≤0,55/apertura ≥0,75, Gmax 150 ms, Tclose 1500 ms, Tstale 750 ms y Krecover 1000 ms con seis muestras.

**Cierre:** AI03–AI10/AI12/AI27: probar cada frontera inclusiva/exclusiva; gap 151 corta, captura vieja 751 descarta, silencio cambia estado por watchdog ≤100 ms. No interpolar inválidas ni sumar cierres previos a recuperación.

**Verificación relacionada:** QA12, QA14, QA15. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-019 · Implementar advertencia W

**Depende de:** VIG-018. **Paths:** `packages/monitoring_engine/android/src/main/kotlin/<namespace>/policy/, packages/monitoring_engine/android/src/test/kotlin/<namespace>/`.

**Entrega:** Ventana continua 30 s, cobertura completa, ratio cerrado ≥0,20, tres runs ≥200 ms, persistencia 500 ms y salida ≤0,10.

**Cierre:** AI15–AI17: seis bloques positivos activan a 30500 ms en fixture de 100 ms; controles 499/500 ms y runs insuficientes. Gap invalida ventana; H puede dispararse antes de que W esté lista.

**Verificación relacionada:** QA11, QA12, QA14, QA15. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-020 · Implementar episodios, escalada y timers

**Depende de:** VIG-018, VIG-019, VIG-012. **Paths:** `packages/monitoring_engine/android/src/main/kotlin/<namespace>/policy/, packages/monitoring_engine/android/src/main/kotlin/<namespace>/journal/`.

**Entrega:** Un episodio para W→H, final normal por apertura válida 2000 ms y extremos null al cortar continuidad.

**Cierre:** AI18–AI21: escalada H inmediata; repeticiones W 15000/H 5000 ms desde intento, incluido fallo. Reabrir señal crea segmento nuevo; no dar duración cero a final desconocido.

**Verificación relacionada:** QA13, QA15, QA23, QA31. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-021 · Implementar audio y servicio foreground camera

**Depende de:** VIG-020, VIG-010. **Paths:** `packages/monitoring_engine/android/src/main/kotlin/<namespace>/alerts/, packages/monitoring_engine/android/src/main/kotlin/<namespace>/coordinator/, android/`.

**Entrega:** Alertas locales independientes de Drift/red, audioFocus/ruta, notificación y ciclo de servicio asociado a sesión explícita.

**Cierre:** Éxito técnico y fallo conservan episodio/estado distintos; audio nunca confirma audibilidad humana. Verificar restricciones de Android por equipos y cierre ≤2 s; no añadir full-screen intent por suposición.

**Verificación relacionada:** QA04, QA11, QA12, QA13, QA18, QA35, QA36, QA40. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-022 · Integrar seis puertas y prueba sonora por sesión

**Depende de:** VIG-017, VIG-021, VIG-009. **Paths:** `packages/monitoring_engine/android/src/main/kotlin/<namespace>/coordinator/, lib/core/monitoring/`.

**Entrega:** Preparación consumible con cámara, permiso, modelo, Q, cal compatible y sonido técnico+Lo escuché; inicio nativo revalida.

**Cierre:** QA05 seis negativas aisladas, carrera antes de tap y control positivo; diez inicios generan un ID. Nueva sesión exige prueba/confirmación nuevas. Rechazo no crea Activa; cambios de montaje/patrón invalidan la puerta correspondiente.

**Verificación relacionada:** QA04, QA05, QA07, QA08, QA17, QA29. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

### H03

#### VIG-023 · Traducir el esquema histórico a Drift

**Depende de:** VIG-006, VIG-012. **Paths:** `lib/core/database/, test/database/`.

**Entrega:** Quince tablas, índices/triggers/constraints de Área 06, versiones explícitas y proyecciones compartidas.

**Cierre:** DT01/DT03/DT05/DT10: FK válidas, huérfano rechazado, snapshots inmutables y cálculos DS01–DS04 exactos. Generación no sustituye revisar SQL; no fallback destructivo.

**Verificación relacionada:** QA07, QA21, QA24, QA25, QA31, QA37. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-024 · Consolidar Room→Drift con JCS y ACK

**Depende de:** VIG-023, VIG-012, VIG-008. **Paths:** `lib/core/database/, packages/monitoring_engine/android/src/main/kotlin/<namespace>/journal/`.

**Entrega:** DDL nativo completo de Área 06, serialización RFC8785, hashes y importación transaccional/dedupe con ACK exacto.

**Cierre:** DT07–DT09/DT20/DT23: 10 sesiones/100 episodios importados tres veces no cambian conteos. Commit antes ACK soporta reinicio; revisión posterior no desaparece con ACK previo. Batch ≤100/1 MiB, registro ≤64 KiB; versión/hash inválidos no se ACKean.

**Verificación relacionada:** QA08, QA19, QA31, QA37. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-025 · Reconciliar snapshots y eventos al reconectar

**Depende de:** VIG-024, VIG-009. **Paths:** `lib/core/monitoring/, lib/app/bootstrap/`.

**Entrega:** Suscribir con buffer, capabilities/snapshot, descarte por instance/revision y reconciliación durable antes de habilitar mutaciones.

**Cierre:** Cortar canal con motor vivo no termina sesión; eventos viejos no retroceden UI. Silencio 3000 ms declara conexión no disponible y consulta; orden pendiente 5 s se resuelve por snapshot, sin crear nuevo comando.

**Verificación relacionada:** QA08, QA10, QA19, QA20, QA31. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-026 · Completar inicio, pausa, reanudación y cierre

**Depende de:** VIG-022, VIG-024, VIG-025, VIG-020, VIG-021. **Paths:** `packages/monitoring_engine/android/src/main/kotlin/<namespace>/coordinator/, packages/monitoring_engine/android/src/main/kotlin/<namespace>/camera/, lib/core/monitoring/`.

**Entrega:** Ciclo de sesión completo, pausas persistidas, callbacks por generación y compatibilidad de calibración.

**Cierre:** AT01–AT08/AT19: pausa libera use cases y suspende policy; reanudar visible verifica Q/permiso, conserva ID y abre nuevas ventanas. Retorno de Ajustes no auto-reanuda. Incompatibilidad de cal no reemplaza referencia a escondidas; cierre idempotente ≤2 s.

**Verificación relacionada:** QA08, QA10, QA16, QA17, QA18, QA20, QA29, QA36. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-027 · Tolerar fallo de almacenamiento y pérdidas

**Depende de:** VIG-024, VIG-026. **Paths:** `packages/monitoring_engine/android/src/main/kotlin/<namespace>/journal/, lib/core/database/, lib/core/monitoring/`.

**Entrega:** Buffer limitado, pérdida durable resumida y registro pending/incomplete separado de ciclo/medición.

**Cierre:** Agotar 256 registros o 1 MiB y conservar recordLossSummary con pérdidas reales; no reconstruir huecos desde UI. Fallo de Room/Drift no impide alerta en memoria; resumen/export no llaman completo al registro incompleto.

**Verificación relacionada:** QA18, QA21, QA31. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-028 · Recuperar después de muerte de proceso

**Depende de:** VIG-026, VIG-027. **Paths:** `packages/monitoring_engine/android/src/main/kotlin/<namespace>/journal/, lib/app/bootstrap/, lib/core/database/`.

**Entrega:** Recuperación desde commits, interrupted con extremo desconocido y protección contra sesión automática.

**Cierre:** AT11/AT20/DS02 con active y paused: no extrapolar tiempo hasta reapertura, no reactivar cámara. Diferenciar desconexión, kill, force-stop y reboot en evidencia; mismo dataset sin borrado implícito.

**Verificación relacionada:** QA19, QA21, QA31, QA36. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-029 · Implementar borrado y reset de dataset

**Depende de:** VIG-024, VIG-025, VIG-028. **Paths:** `lib/core/database/, packages/monitoring_engine/android/src/main/kotlin/<namespace>/journal/, lib/core/export/`.

**Entrega:** Operación durable por etapas/tombstones, borrado en ambas bases/staging y commitDatasetReset idempotente.

**Cierre:** DT02/DT12/DT13/DT17: caída en cada etapa recupera mismo operationId/UUID; lote antiguo no resucita datos. Vigente/paused/incierto bloquean; borrar todo elimina alias/cal y conserva solo preferencias/barreras permitidas. No prometer borrado forense ni de copias externas.

**Verificación relacionada:** QA27, QA31, QA37. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-030 · Implementar retención y fechas locales

**Depende de:** VIG-029, VIG-023. **Paths:** `lib/core/database/, lib/features/settings/`.

**Entrega:** 90 inicial; 30/90/180/sin límite; corte por fecha local y alcance congelado antes de confirmar.

**Cierre:** DT11/DS08: límite igual permanece, anterior se elimina; cambio de zona/selección exige confirmar nuevo alcance. No borrar vigente ni cleanup durante incertidumbre; apertura/cierre disparan limpieza permitida.

**Verificación relacionada:** QA25, QA28, QA31. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-031 · Proteger migraciones y datos corruptos

**Depende de:** VIG-024, VIG-029, VIG-030. **Paths:** `lib/core/database/, packages/monitoring_engine/android/src/main/kotlin/<namespace>/journal/, testdata/migrations/`.

**Entrega:** Migraciones versionadas, fixtures DB V1 y manejo explícito de fallo/corrupción sin destruir evidencia.

**Cierre:** DT21/DT22/DT23 y futuros deltas reales preservan IDs/FK/tombstones; no inventar V0 distribuida. JSON duplicado/NaN/versión extraña rechazan. Corrupción no se disfraza de historial vacío; ensayo de migración sin delta distribuido queda future/planned con protección inicial comprobada.

**Verificación relacionada:** QA22, QA27, QA31, QA37. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

### H04

#### VIG-032 · Congelar inventario visual B5.2

**Depende de:** VIG-001. **Paths:** `docs/design-system.md, docs/screens.md, docs/motion.md`.

**Entrega:** HTML completo recibido/hash, tokens, P01–P18/D01–D08, variantes, recursos y motion inventariados.

**Cierre:** Inspeccionar el archivo completo cuando esté disponible; no aceptar 120 vistas/1440 checks solo por summary. Documentar cada estado con RF/UX/acción/error. Confirmar licencias Inter/iconos y navegación 200 %; referencias Co inspiran, no autorizan copiar activos.

**Verificación relacionada:** QA33, QA34, QA40. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-033 · Crear tokens, temas y tipografía local

**Depende de:** VIG-003, VIG-032. **Paths:** `lib/core/design_system/, assets/fonts/, docs/licenses.md`.

**Entrega:** Color/espaciado/radio/tipo/elevación/movimiento por tokens; claro, grafito-violeta y Sistema persistibles.

**Cierre:** Oscuro conserva #24232B/#302E39/#3B3845/#F7F5FA/#CEC9D5 del brief vigente con contraste por pareja real. Inter y licencia locales; cero Google Fonts remoto. Escala 200 % sin fijar navegación en 135 %; no afirmar contraste aprobado por hex aislado.

**Verificación relacionada:** QA29, QA33, QA34, QA37. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-034 · Crear componentes y movimiento reutilizable

**Depende de:** VIG-033, VIG-006. **Paths:** `lib/core/design_system/, test/design_system/`.

**Entrega:** Botones, tarjetas, estados, diálogos, tabs, feedback, skeleton/error/vacío y transiciones con tokens y semántica.

**Cierre:** Componentes responden a loading/disabled/error sin toasts falsos; taps ≥48×48, foco seguro y acciones identificadas. Motion reducido elimina aura animada; P06 mantiene prioridad/legibilidad sin decoración intensa. Duraciones/curvas se congelan en inventario, no se inventan del video no disponible.

**Verificación relacionada:** QA10, QA20, QA33, QA34. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-035 · Implementar incorporación y permisos

**Depende de:** VIG-034, VIG-025, VIG-026, VIG-028. **Paths:** `lib/features/onboarding/, lib/app/`.

**Entrega:** P01/P02/P03 con explicación versionada, permiso real y retorno de ajustes.

**Cierre:** RF01/RF02/UX01/UX02: cero cámara antes de la acción, no repetir explicación ya vista, rechazo/permanente diferenciados. Reapertura con sesión vigente conserva ID; confirmar permiso no equivale a iniciar.

**Verificación relacionada:** QA01, QA02, QA19, QA20. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-036 · Implementar preparación/calibración visual

**Depende de:** VIG-034, VIG-022, VIG-026, VIG-035. **Paths:** `lib/features/preparation/, lib/features/calibration/`.

**Entrega:** P03/P04/P05 según inventario con seis puertas, montaje, probes de cal y prueba sonora.

**Cierre:** Mostrar rostro separado de ojos; causas específicas, cancelación y tres rechazos. Cambié la posición bloquea inicio. Progreso procede de fase/muestras del motor y política versionada; ninguna duración/porcentaje clínico fabricados.

**Verificación relacionada:** QA03, QA04, QA05, QA06, QA07, QA08. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-037 · Implementar monitoreo y control de sesión

**Depende de:** VIG-034, VIG-026, VIG-027, VIG-028, VIG-036. **Paths:** `lib/features/monitoring/`.

**Entrega:** P06 con ejes ciclo/medición/señal/conexión/registro, alertas, pausa/reanudar/finalizar y estados pendientes.

**Cierre:** QA10–QA20 y UX07–UX13: UI ≤1000 ms desde recepción; Q inválida muestra no evaluable, nunca Seguro/fatiga %. Audio/eventos reales, no animación generadora de alertas. Confirmación pendiente consulta misma orden; acción táctil no cambia a Activa antes del motor. Control offline con fixture rotulado verifica episodio/sonido, separado de inferencia física QA09.

**Verificación relacionada:** QA08, QA09, QA10, QA11, QA12, QA13, QA14, QA15, QA16, QA17, QA18, QA19, QA20, QA33. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-038 · Aplicar guardas de navegación y operaciones

**Depende de:** VIG-035, VIG-036, VIG-037, VIG-025. **Paths:** `lib/app/router/, lib/app/providers/, lib/core/export/`.

**Entrega:** Router por estado autoritativo y ProductOperationCoordinator para selector/export/borrado/inicio incompatibles.

**Cierre:** Las nueve rutas P09–P11/P13–P18 bloquean active/paused/transiciones/uncierto; P03↔P06 no sustituye sesión. P08 restringida/P12 permitida según UX; enlaces profundos pasan la misma guarda. Selector abierto no admite otra sesión ni mutación incompatible.

**Verificación relacionada:** QA20, QA26, QA27, QA28, QA29, QA30. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-039 · Implementar resumen de sesión

**Depende de:** VIG-037, VIG-038, VIG-023, VIG-027. **Paths:** `lib/features/history/`.

**Entrega:** P07 proyecta tiempos/cobertura/conteos y calidad del registro desde datos consolidados.

**Cierre:** DS01–DS04/QA21: 960 s y 83,3 % cuando corresponde; pausas/unknown fuera del denominador. Cero evaluable→No disponible; null no se convierte en cero. Pending/incomplete explícitos y misma proyección para UI/export.

**Verificación relacionada:** QA21, QA23, QA25, QA31. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

### H05

#### VIG-040 · Implementar historial y paginación

**Depende de:** VIG-039, VIG-031. **Paths:** `lib/features/history/`.

**Entrega:** P08 con vacío/error/lectura/filtrado y paginación de 50 por start/id.

**Cierre:** 101 sesiones y empate de fechas: sin pérdida/duplicado, detalle del ID elegido; reinicio conserva orden/estado. Error de lectura muestra Reintentar, no vacío. Guarda impide entrar con vigente.

**Verificación relacionada:** QA22, QA20. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-041 · Implementar detalle y valoración

**Depende de:** VIG-040, VIG-020. **Paths:** `lib/features/history/`.

**Entrega:** P09 detalle de sesión con ID/inicio/final/tiempos/cobertura/línea temporal/versiones y acciones exportar/eliminar; P10 episodio con useful/notPerceived/unsure, categoría/motivo/offsets y duración nullable.

**Cierre:** QA23/QA24: navegar P08→P09→P10 conserva los IDs elegidos; técnico no es episodio de somnolencia ni hay fotos inventadas. Solo finalized y sin otra vigente permite editar feedback; nunca modifica evidencia/policy/cal. Eliminar usa VIG-029; Exportar define callback tipado cuyo cableado real se cierra en VIG-046/047, sin éxito ficticio. Feedback no es ground truth.

**Verificación relacionada:** QA22, QA23, QA24, QA26, QA27, QA20, QA39. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-042 · Implementar tendencias de 7/30 días

**Depende de:** VIG-040, VIG-023, VIG-030. **Paths:** `lib/features/history/`.

**Entrega:** P11 con rango exacto, grupos por policyVersion, tasas por hora y coberturas por sumas.

**Cierre:** DS03/DS04 y fronteras locales: 4,0/6,0 por hora y 75/50 % en grupos definidos; cero denominador No disponible. No promediar porcentajes, emitir diagnóstico/ranking ni mezclar versiones sin etiqueta.

**Verificación relacionada:** QA25, QA20. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-043 · Implementar ajustes de tema, sonido y datos

**Depende de:** VIG-033, VIG-038, VIG-029, VIG-030, VIG-022. **Paths:** `lib/features/settings/`.

**Entrega:** P12/P13/P14/P18 según UX: tema, sonido, datos y perfil local con alias opcional; retención y confirmaciones de borrado.

**Cierre:** Tema claro/oscuro/sistema sobrevive reinicio; alias NFC trim ≤40 escalares Unicode y fuera de export. Cambio de patrón exige prueba nueva; sin control de desactivar H conservando operación plena. Borrado usa etapas reales, no solo vacía widgets.

**Verificación relacionada:** QA04, QA27, QA28, QA29, QA20, QA37. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-044 · Implementar seis temas de ayuda

**Depende de:** VIG-035, VIG-038, VIG-043. **Paths:** `lib/features/settings/, assets/help/`.

**Entrega:** P16 lista de temas y P17 artículo: encuadre/soporte, iluminación/ojos, cal, sonido, interrupciones y datos/export con causa/acción/reintento.

**Cierre:** QA30 offline: enlaces al destino correcto y cero captura al leer. Con vigente solo aviso breve permitido; ningún artículo extenso salta guardas. Explicar límites y copia externa sin prometer prevención de accidentes.

**Verificación relacionada:** QA01, QA20, QA30, QA37. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-045 · Serializar snapshot JSON/CSV y staging

**Depende de:** VIG-023, VIG-024, VIG-029, VIG-038, VIG-039. **Paths:** `lib/core/export/, test/export/`.

**Entrega:** Snapshot inmutable, exportSchemaVersion, JSON y CSV de 34/31 columnas, UTF-8 sin BOM/coma/CRLF, staging TTL24h.

**Cierre:** DT14–DT17/DT24: parser compara IDs/FK/nulls/hash; cero episodios permite header, cero sesiones bloquea selector. Archivos UUID+UTC sin alias; expiración/borrado invalidan staging. No convertir copia externa en atomicidad de DB.

**Verificación relacionada:** QA21, QA26, QA27, QA37. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-046 · Implementar SAF y exportación parcial

**Depende de:** VIG-045, VIG-007, VIG-008, VIG-038. **Paths:** `packages/monitoring_engine/android/src/main/kotlin/<namespace>/export/, lib/core/export/, lib/features/settings/`.

**Entrega:** API tipada aislada para selector/copia/cierre, P15/D08 y estado por archivo del mismo exportId.

**Cierre:** Cancel/fail/written/unknown distinguibles; caída después de cerrar archivo externo antes de commit puede dejar copia desconocida. DS05 reintenta solo pendiente del snapshot congelado; no solicita permiso general ni guarda URI persistente. Selección/copia no arranca cámara.

**Verificación relacionada:** QA26, QA27, QA20, QA37. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-047 · Completar demo y recorridos integrados

**Depende de:** VIG-040, VIG-041, VIG-042, VIG-043, VIG-044, VIG-046, VIG-004. **Paths:** `lib/app/bootstrap/, testdata/, integration_test/`.

**Entrega:** Recorridos M01–M10 sobre demo y recorrido real de funciones no simuladas, todas las pantallas conectadas.

**Cierre:** Demo rotulada en monitoreo/historial/export con DB independiente; no permite hacer pasar fixture por inferencia física. En real no quedan botones pendientes, selectors de test ni acciones que solo muestran éxito sin persistir.

**Verificación relacionada:** QA01, QA02, QA03, QA04, QA05, QA06, QA07, QA08, QA09, QA10, QA11, QA12, QA13, QA14, QA15, QA16, QA17, QA18, QA19, QA20, QA21, QA22, QA23, QA24, QA25, QA26, QA27, QA28, QA29, QA30, QA31, QA32. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

### H06

#### VIG-048 · Verificar TalkBack, texto y foco en Android

**Depende de:** VIG-047, VIG-034. **Paths:** `lib/, docs/evidence/QA33/`.

**Entrega:** Campaña claro/oscuro, texto 100/200 %, tamaños disponibles y TalkBack con orden/acciones/cambios pertinentes.

**Cierre:** QA33: contraste ≥4,5:1 y taps ≥48×48; ningún control/texto esencial recortado al 200 %. No capar etiquetas a 135 %. Diálogos foco seguro, texto de error accesible y sin anuncios por frame/segundo. Corregir y repetir casos afectados.

**Verificación relacionada:** QA33, QA34. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-049 · Validar acabado y recursos offline

**Depende de:** VIG-047, VIG-048, VIG-032. **Paths:** `test/goldens/, assets/, docs/licenses.md, docs/evidence/QA34/`.

**Entrega:** Baseline Flutter aprobado por estado, inventario completo y licencias/atribuciones de fonts/iconos/sonidos/modelo.

**Cierre:** QA34: baseline nuevo comparado con B5.2 real, sin asumir equivalencia HTML/Flutter. No hay peticiones de fuentes ni assets externos; red físicamente deshabilitada funciona. Golden no reemplaza Android ni aprueba animaciones por sí solo.

**Verificación relacionada:** QA09, QA29, QA33, QA34, QA37, QA40. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-050 · Medir aura y transiciones con motor activo

**Depende de:** VIG-049, VIG-037. **Paths:** `lib/core/design_system/, docs/evidence/QA35/`.

**Entrega:** Motion reducido y normal perfilados junto a cámara/inferencia; simplificación basada en medidas si supera presupuesto.

**Cierre:** QA35 en D1 y equipos de gate: p95 build/raster por separado ≤16,7 ms a 60 Hz/60 s. Movimiento reducido no ejecuta aura; P06 mantiene estabilidad. Ajustar decoración antes de degradar Q/captura o esconder pérdida de medición.

**Verificación relacionada:** QA33, QA34, QA35. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-051 · Ejecutar comprensión con cinco usuarios

**Depende de:** VIG-048, VIG-049, VIG-050. **Paths:** `docs/evidence/QA38/, docs/issues/`.

**Entrega:** Protocolo UT01–UT08, consentimiento/IDs, resultados sin ayuda y correcciones de confusión observadas.

**Cierre:** QA38: ≥4/5 UT01/04/05/06/07; 5/5 UT02/03/08. Confusión sobre aptitud, señales o copias se corrige y reevalúa con ronda de cinco. No inventar participantes; faltan personas→notRun. Reclutamiento/envío solo por instrucción explícita.

**Verificación relacionada:** QA38, QA33, QA34. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

### H07

#### VIG-052 · Ejecutar suites de host y regresión

**Depende de:** VIG-047, VIG-006, VIG-031. **Paths:** `test/, packages/monitoring_engine/android/src/test/kotlin/<namespace>/, docs/evidence/`.

**Entrega:** Ejecución reproducible de unitarias/widget/SQL/serialización y AI deterministas con metadatos de commit/config.

**Cierre:** AI01–AI28 tres repeticiones coherentes; DT pertinentes con expected/actual y regresión por cambio Área 07. Ensayos físicos no se aprueban desde host. Los 37 checks Área 06 y 23 Área 07 previos siguen como evidencia documental, no tests de esta app.

**Verificación relacionada:** QA01, QA02, QA03, QA04, QA05, QA06, QA07, QA08, QA09, QA10, QA11, QA12, QA13, QA14, QA15, QA16, QA17, QA18, QA19, QA20, QA21, QA22, QA23, QA24, QA25, QA26, QA27, QA28, QA29, QA30, QA31, QA32, QA37, QA40. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-053 · Ejecutar Android y matriz de fallos

**Depende de:** VIG-052, VIG-028, VIG-046, VIG-038. **Paths:** `integration_test/, packages/monitoring_engine/android/src/main/kotlin/<namespace>/androidTest/, docs/evidence/`.

**Entrega:** AT01–AT22 y QA funcionales físicos/harness, fallos de ACK/borrado/export/audio/canal/proceso con puntos de caída.

**Cierre:** Cada caso apunta a APK/hash/equipo; distinguir inyección de medición física. Reproducir active/paused/pendiente/incierto, no solo happy path. Gap sin evidencia e integrityFailure no se ACKean ni presentan complete.

**Verificación relacionada:** QA01, QA02, QA03, QA04, QA05, QA06, QA07, QA08, QA09, QA10, QA11, QA12, QA13, QA14, QA15, QA16, QA17, QA18, QA19, QA20, QA21, QA22, QA23, QA24, QA25, QA26, QA27, QA28, QA29, QA30, QA31, QA32, QA36, QA37, QA40. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-054 · Auditar privacidad y backup real

**Depende de:** VIG-053, VIG-049. **Paths:** `android/, packages/monitoring_engine/android/src/main/kotlin/<namespace>/journal/, docs/evidence/QA37/`.

**Entrega:** Manifest fusionado, inspección DB/WAL/staging/logs, recursos y ensayos de exclusión cloud/D2D por dominio aplicable.

**Cierre:** QA37/DT18/DT22: sin fotos/video/malla/alias exportado ni secretos en logs; nueve dominios de exclusión declarados en Área 06 y reinstalación/restauración verificadas cuando plataforma lo permite. allowBackup=false aislado no cierra gate. Sin SDK analítico o cifrado adicional afirmado sin implementación.

**Verificación relacionada:** QA09, QA26, QA27, QA31, QA32, QA37, QA40. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-055 · Medir latencias en equipos de referencia

**Depende de:** VIG-053, VIG-050, VIG-054, VIG-002. **Paths:** `tools/bench/, docs/evidence/QA35/`.

**Entrega:** Tres corridas por equipo/modo declarado, ≥1000 resultados/run y 30 intentos de audio por categoría/salida.

**Cierre:** p95 captura→resultado <200 ms, decisión→sonido máximo ≤500 ms y UI p95 build/raster ≤16,7 ms separados. nearest-rank ceil(0,95n), relojes correlacionados. Si equipo/escenario falla, incidencia o soporte explícitamente limitado sin ocultar denominador.

**Verificación relacionada:** QA10, QA11, QA12, QA35, QA36. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-056 · Medir continuidad y escenarios Android

**Depende de:** VIG-055, VIG-026, VIG-028. **Paths:** `docs/evidence/QA36/`.

**Entrega:** Cinco escenarios ×5 min ×3 repeticiones por combinación declarada: P06 visible, otra pantalla permitida de Vigía, otra app, bloqueo y llamada entrante.

**Cierre:** Usar nombres/condiciones exactos QA36, registrar captura y Q por separado, pausas/interrupciones y notificación. No tratar frames presentes como ojos evaluables ni prometer continuidad en equipos no ensayados.

**Verificación relacionada:** QA09, QA14, QA15, QA16, QA17, QA18, QA19, QA36. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-057 · Ejecutar estabilidad de 60 minutos

**Depende de:** VIG-055, VIG-056. **Paths:** `docs/evidence/QA35/`.

**Entrega:** Tres sesiones de 60 min por equipo declarado, memoria PSS KiB por minuto, timestamps, incidentes y estado térmico disponible.

**Cierre:** QA35: media muestras [50,60)/[10,20) ≤1,20; diez muestras en cada tramo, PID continuo. Dato faltante/PID nuevo bloquea resultado, no se rellena. Verificar cierre de recursos diez ciclos ≤2 s y ausencia de congelamientos.

**Verificación relacionada:** QA18, QA31, QA35, QA36. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-058 · Verificar paquete, 16 KB e instalación

**Depende de:** VIG-054, VIG-057, VIG-004. **Paths:** `android/, docs/evidence/QA40/`.

**Entrega:** Inspección ELF/ZIP/ABI, ejecución en P16K, APK real offline y actualización por ruta/firma concreta.

**Cierre:** QA40/RL04/RL11: verificar bibliotecas Flutter/MediaPipe/SQLite empaquetadas; no inferir 16 KB por versión Gradle. Artefacto probado es el hash entregado, sin fixtures real ni dependencias dinámicas. Si firma definitiva falta, resultado de desarrollo no aprueba RL02 comercial.

**Verificación relacionada:** QA09, QA32, QA37, QA40. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

### H08

#### VIG-059 · Preparar protocolo IA y material independiente

**Depende de:** VIG-016, VIG-017, VIG-052, VIG-001. **Paths:** `ml/protocol/, docs/ai.md`.

**Entrega:** Escenarios SC01–SC14, guía de anotación visual, IDs/consentimiento, exposición por condición y separación dev/val/test por persona.

**Cierre:** QA39: referencia humana no toma EAR/salida motor como verdad; dos anotadores ciegos y adjudicación. Datos personales no van al repo. Preparar materiales no equivale a reclutar, grabar ni probar conduciendo; mantener entorno detenido previsto.

**Verificación relacionada:** QA39, QA03, QA06, QA12, QA14. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-060 · Realizar piloto de viabilidad con seis personas

**Depende de:** VIG-059, VIG-014, VIG-053. **Paths:** `ml/reports/, docs/issues/`.

**Entrega:** Resultados exploratorios de cámara, visibilidad, cal y molestias del flujo; seis participantes diferenciados del holdout.

**Cierre:** Registrar aptos/rechazos/oclusiones y fallos sin prometer precisión con n=6. Si cambia Q/modelo/cal, versionar y repetir suites afectadas. No reutilizar estos participantes como test final; ausencia de participantes mantiene notRun.

**Verificación relacionada:** QA03, QA06, QA14, QA39. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-061 · Construir dataset anotado y holdout

**Depende de:** VIG-060, VIG-059. **Paths:** `ml/manifests/, ml/protocol/`.

**Entrega:** Manifiestos sin caras: 30 personas 15dev/5val/10test; dataset externo protegido y anotaciones adjudicadas con hash/versiones.

**Cierre:** Cumplir todos los mínimos Área 05: 60 H/60 W, ≥6 por categoría/persona de test, 20 h negativo y ≥1 h/persona, ≥10 eventos/categoría y 2 h negativas por condición. Acuerdo ≥90 %, mediana límites ≤100 ms. Datos insuficientes no califican ni se maquillan con fixtures.

**Verificación relacionada:** QA39. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-062 · Evaluar EV01–EV13 sin ajustar sobre test

**Depende de:** VIG-061, VIG-057, VIG-058. **Paths:** `ml/evaluation/, ml/reports/`.

**Entrega:** Matching reproducible [-100,+1000] ms, recall/precision, FP/h, cobertura/visibilidad, latencia y CI por persona/condición.

**Cierre:** Aplicar tie-break y FN de no evaluable del Área 05; bootstrap 2000 con seed, Wilson/Poisson pertinentes. Publicar tardíos/FN y denominadores; comparar todos los umbrales EV sin redefinirlos. Si falla, nueva versión y holdout independiente, no cambiar test para aprobar.

**Verificación relacionada:** QA39, QA35, QA03, QA06, QA11, QA12, QA14, QA15. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-063 · Congelar política y calificación de señales

**Depende de:** VIG-062, VIG-052, VIG-053. **Paths:** `docs/ai.md, ml/manifests/, docs/decisions/`.

**Entrega:** Modelo/policy/Q/Kcal/asset/calCompatibility versionados e informe de condiciones calificadas y pendientes.

**Cierre:** G08 solo cierra con EV01–EV13 íntegros; H recall ≥0,95/precision ≥0,90, W ≥0,85/≥0,85 y resto de cobertura/FP/latencia/oclusiones Área 05. Cambio tras freeze invalida evidencia afectada; sin calificación no llamar E3 ni seguridad demostrada.

**Verificación relacionada:** QA39, QA07, QA29, QA40. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

### H09

#### VIG-064 · Preparar CI y manifiesto reproducible de candidato

**Depende de:** VIG-052, VIG-053, VIG-058, VIG-005. **Paths:** `.github/workflows/ si se elige GitHub, tools/, docs/release/`.

**Entrega:** Pipeline portable de análisis/host/generación/build, run-manifest y checklist RL con links a evidencia física externa.

**Cierre:** CI limpia no genera diff; lockfiles/versiones/hash identificados. Jobs de host no aprueban equipos/UT/EV; notRun visible. Ejecución local es suficiente hasta elegir hosting; no crear repo remoto, subir binarios ni añadir secretos automáticamente.

**Verificación relacionada:** QA40, QA32, QA37. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-065 · Preparar entrega académica E2

**Depende de:** VIG-047, VIG-048, VIG-049, VIG-052, VIG-053, VIG-064. **Paths:** `docs/release/academic/`.

**Entrega:** APK demo/labReal/candidateReal según gates realmente cerrados, informe para materia y guion con capturas/video y licencias.

**Cierre:** Instalar el mismo hash e identificar simulación/cámara real. Reportar G/QA/EV/UT pendientes; E2 puede presentarse con límites, nunca como E3 aprobada. HTML B5.2 es referencia de diseño, no APK; rúbrica profesor se incorpora cuando exista.

**Verificación relacionada:** QA33, QA34, QA40. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-066 · Cerrar candidato V1 funcional E3

**Depende de:** VIG-051, VIG-054, VIG-055, VIG-056, VIG-057, VIG-058, VIG-063, VIG-064, VIG-065. **Paths:** `docs/release/candidate/`.

**Entrega:** Registro firmado por responsable de stage decision con G02–G09 y 192 CA vigentes respaldados por evidencia.

**Cierre:** Cero S0/S1, cero CA vigente failed/notRun/blocked; cumplimiento íntegro por equipo/condición declarada. Rastrear 310 IDs y 40 QA sin convertir escenario en criterio nuevo. E3 no autoriza publicar ni cierra contexto E4.

**Verificación relacionada:** QA40, QA38, QA39. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

### H10

#### VIG-067 · Definir y evaluar contexto comercial adicional

**Depende de:** VIG-066. **Paths:** `docs/commercial/protocol.md, docs/release/`.

**Entrega:** Protocolo específico del uso real, riesgos/condiciones de montaje, límites y revisión independiente pertinente; informe tras ejecución.

**Cierre:** RL09 sigue blocked hasta protocolo aprobado y evidencia real; piloto detenido de señales no basta para contexto comercial. Preparar protocolo no autoriza reclutar ni ensayar conduciendo. Sin criterios comerciales aprobados previamente, no declarar E4.

**Verificación relacionada:** QA39, QA40. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-068 · Preparar privacidad pública, listing y licencias

**Depende de:** VIG-066, VIG-054, VIG-049. **Paths:** `docs/commercial/privacy.md, docs/commercial/listing.md, docs/licenses.md`.

**Entrega:** Textos revisables con responsable/contacto por definir, permisos/datos reales y capturas del candidato.

**Cierre:** RL03/RL06/RL07: coherencia con comportamiento auditado; no claims de prevención/diagnóstico. Declaraciones dependen SDKs reales, no de asumir local=ningún dato. Licencias completas; ningún texto público publicado por esta tarea.

**Verificación relacionada:** QA37, QA40, QA34. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-069 · Resolver identidad, firma, cuenta y track

**Depende de:** VIG-066, VIG-058, VIG-064. **Paths:** `docs/release/distribution.md, android/`.

**Entrega:** PackageId/versionCode definitivos, custodia fuera del repo, certificado público y requisitos actuales de cuenta/track registrados.

**Cierre:** RL01/RL02/RL04/RL08: instalar/actualizar con firma elegida; reconsultar fuentes oficiales al distribuir. Registrar tipo/fecha de cuenta y aplicabilidad de testers; sin datos reales queda pending. No abrir cuenta, invitar personas ni entregar claves al repo.

**Verificación relacionada:** QA40, QA32. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-070 · Definir soporte e incidencias de versión distribuida

**Depende de:** VIG-066, VIG-068. **Paths:** `docs/operations/support.md, docs/operations/incidents.md`.

**Entrega:** Canal/contacto, reporte voluntario local, responsable/disponibilidad y manejo S0/S1 con corrección hacia adelante.

**Cierre:** RL10: no SLA inventado, backend/crash reporter añadido ni caras/alias/export adjuntos por defecto. Ejercicio de mesa reproduce suspensión de candidato, identificación de versión afectada, release notes y migración segura; no downgrade de DB como rollback.

**Verificación relacionada:** QA37, QA40. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-071 · Preparar candidato comercial revisable E4

**Depende de:** VIG-067, VIG-068, VIG-069, VIG-070, VIG-066. **Paths:** `docs/release/commercial/`.

**Entrega:** AAB/APK firmados, fichas/declaraciones listas, evidencia del artefacto y checklist RL01–RL12 para decisión del responsable.

**Cierre:** G10/RL09 requieren evaluación comercial cerrada y todos los anteriores aplicables aprobados. Resultado es paquete preparado; publicación/reclutamiento/envíos requieren instrucción posterior explícita. No marcar revisión Play aprobada sin respuesta de la tienda.

**Verificación relacionada:** QA40, QA37, QA39. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.

#### VIG-072 · Definir actualización y regresión posterior

**Depende de:** VIG-070, VIG-071. **Paths:** `docs/operations/updates.md, docs/release/`.

**Entrega:** Procedimiento de cambios, matriz de regresión por componente, custodia de versiones y decisiones ante incidentes.

**Cierre:** Ensayo de mesa con hotfix visual y cambio Q/modelo: identificar suites/evidencia reutilizable y las que se invalidan. No simular usuarios activos, métricas de adopción ni publicación ocurrida; primera ejecución operativa queda future hasta distribución real.

**Verificación relacionada:** QA40, QA35, QA37, QA39. **Estado:** planned; evidencia notRun; responsable/revisor unassigned.


## 9. Colaboración entre Codex y Claude Code

### 9.1 Asignación y revisión

Se propone Codex para contratos/motor/datos/harness y Claude Code para Flutter/design system/interacciones; ambas herramientas pueden asumir cualquiera de esas tareas. Es una distribución por continuidad y responsabilidad, no una afirmación de superioridad. En la ficha se nombra un escritor concreto; la otra herramienta revisa en modo lectura o recibe la siguiente tarea después del handoff.

Un cambio Pigeon/Kotlin/Dart/schema con varios archivos es una sola tarea de integración. El revisor no crea un contrato alternativo ni modifica archivos mientras el escritor sigue trabajando. Cuando pide cambios, deja paths, requisito, reproducción y resultado esperado; después el escritor recupera la tarea. No se confía en “todo comprobado” de un summary sin comandos/artefactos.

Codex aplica instrucciones de proyecto mediante AGENTS.md con alcance de directorio; instrucciones más cercanas pueden especializar la raíz. No se crean overrides que oculten reglas comunes [S1]. Claude Code admite instrucciones e imports en CLAUDE.md; se recomienda importar `@AGENTS.md` para mantener una fuente común. Las versiones actuales también pueden usar AGENTS directamente en determinadas condiciones; la importación explícita evita depender de esa detección [S2].

### 9.2 Git y propiedad de archivos

Al empezar una tarea: leer instrucciones/fuentes, inspeccionar estado Git, registrar commit base y cambios preexistentes del usuario, elegir una rama de tarea y declarar paths. Nunca borrar o reformatear trabajo ajeno para obtener un árbol limpio. Si los cambios preexistentes coinciden con la tarea, documentar cómo se integrarán; no reset/force-push/stash destructivo por conveniencia.

Convención propuesta: `task/VIG-018-cierre-h`; commit `VIG-018: implementar continuidad de cierre H`. Un commit revisable puede integrar varios archivos inseparables. PR/diff describe trigger, comportamiento resultante, fuentes/criterios, evidencia y límites. No hay número arbitrario de líneas como criterio de calidad; separar cambios que requieren revisiones distintas.

Por defecto las herramientas trabajan secuencialmente en un solo checkout. Si después el usuario autoriza trabajo paralelo, usar worktrees separados, rama distinta y propietario por paquete/contrato. Git worktree permite directorios de trabajo distintos ligados al repo [S3]; no resuelve conflictos de diseño ni autoriza dos editores del mismo contrato. Integrar un cambio, validar en la rama de integración y luego el siguiente. Nunca compartir un mismo directorio entre dos procesos escritores.

Un cambio de lockfile/Gradle/SDK/modelo/policy requiere revisar la matriz de regresión Área 07. No actualizar dependencias incidentalmente en una tarea de colores. No conservar staging exports reales, dataset, claves de firma, contraseñas ni logs personales en Git.

### 9.3 Handoff entre herramientas

Un handoff incluye: tarea y estado, commit/rama base y final, diff/paths, fuentes/versiones/IDs, decisiones, comandos con resultado, artefactos/hashes, fallos y siguiente acción. El receptor vuelve a leer archivos y estado Git: no hereda memoria de otra conversación ni asume que los archivos del summary existen.

Si una respuesta de herramienta dice que no ejecutó capturas/tests, la evidencia es notRun. Si hay una captura web, cubre lo observado en web; no aprueba permisos, cámara, audio, TalkBack o rendimiento Android. El handoff identifica ese límite de forma expresa.

## 10. Plantillas para instalar al crear el repositorio

Son texto reutilizable; esta entrega no escribió AGENTS.md/CLAUDE.md activos en el workspace. Se adaptan en VIG-005 y los comandos se sustituyen solo por los realmente verificados en H00.

### 10.1 AGENTS.md de raíz

```markdown
# Vigía — instrucciones comunes

Lee README.md y docs/spec-index.json. Para la tarea actual consulta las fuentes
en docs/source/ y los IDs de docs/tasks/VIG-xxx.md; no dependas de memoria de chat.

Reglas de producto:
- Android primero, Flutter UI y plugin Kotlin local. iOS es futuro.
- SessionCoordinator nativo es única autoridad de sesión/cámara/policy/alertas.
- Mantén separados ciclo, medición, señal, conexión, comando y registro.
- Cámara/modelo locales. Sin frames por puente, fotos/video/malla guardados,
  porcentaje de fatiga, diagnóstico, GPS, micrófono ni backend añadido.
- Seis puertas para iniciar; repetir permiso/Q/cal/sonido según contrato.
- UI no inventa confirmación. Snapshot resuelve órdenes pendientes.
- Room→validación→commit Drift→ACK exacto. Export externo no es transacción DB.
- Borrado por etapas evita resurrección; nunca fallback destructivo de DB.
- Conserva IDs RF/RNF/UX/P/D/AT/AI/EV/DT/QA y límites de las fuentes.
- B5.2 es referencia visual. No reemplaza las pruebas físicas Android.

Trabajo:
- Una tarea, un escritor. Declara paths, rama y commit base antes de editar.
- Respeta cambios previos del usuario; no reset/force-push/borrado destructivo.
- Revisa contratos en fuente Pigeon y genera Dart/Kotlin con versión idéntica.
  No edites generados a mano ni actualices dependencias fuera del alcance.
- Usa README.md para comandos disponibles. Ejecuta validación proporcional
  al cambio y matriz de regresión docs/testing.md; informa lo no ejecutado.
- Tarea done no implica QA/gate passed. Solo aprueba evidencia ejecutada.
- No guardes datasets personales, exports reales ni secretos en Git/logs.
- Handoff: diff/commit, fuentes/IDs, comandos, expected/actual, hashes y límites.
- Publicación, reclutamiento y envíos requieren instrucción explícita de usuario.

Autor del proyecto: Juan José Rueda Viveros.
```

### 10.2 CLAUDE.md de raíz

```markdown
@AGENTS.md

Aplica las reglas comunes importadas. Lee la ficha docs/tasks/VIG-xxx.md
antes de editar. Si recibes un handoff, verifica archivos/commit/evidencia.
Declara si eres escritor o revisor; como revisor no modifiques el árbol.
```

No duplicar el contenido de AGENTS en CLAUDE; las divergencias entre copias producen reglas distintas. Instrucciones por subdirectorio se añaden solo para requisitos específicos y referencian la raíz. Se comprueba el comportamiento de carga en las versiones instaladas; no se modifica configuración global para este proyecto.

### 10.3 Ficha de tarea

```markdown
# VIG-xxx — título concreto
Estado: ready | Escritor: ... | Revisor: ...
Rama: ... | Commit base: ... | Paths autorizados para esta tarea: ...
Fuentes: nombre/versión/hash + secciones e IDs afectados
Dependencias: VIG-... con evidencia/diff disponible

Trigger/input: ...
Resultado observable esperado: ...
Entregables y límites: ...
Criterios locales de cierre: ...
Ensayos QA/AT/AI/DT/EV/UT pertinentes: ...
Entorno/fixture/APK/modelo/policy/seed: ...
Comandos verificados que se ejecutarán: ...
Riesgo/decisión contractual pendiente: ...

Al cerrar: expected/actual, estado por ensayo, comandos/salida, paths/hash,
commit final, incidencias, revisión y evidencia que queda notRun.
```

### 10.4 Instrucción al escritor

```text
Implementa VIG-xxx de docs/tasks/VIG-xxx.md. Lee AGENTS.md/CLAUDE.md,
README y fuentes citadas. Inspecciona el estado Git y respeta cambios previos.
Declara escritor, commit base y paths; no avances a otra tarea al terminar.
Cumple los criterios locales y ejecuta validación proporcional disponible.
Si hay contradicción contractual o falta una entrada imprescindible,
registra el bloqueo y continúa solo entregables independientes del faltante.
Entrega diff/commit, expected/actual, evidencia y handoff; no apruebes pruebas
no ejecutadas ni gates que dependen de dispositivos/usuarios inexistentes.
```

### 10.5 Instrucción al revisor

```text
Revisa VIG-xxx en modo lectura sobre commit/diff indicado. Consulta fuentes
y criterios, no solo el summary. Comprueba autoridad, tipos, errores,
recuperación, accesibilidad y evidencia pertinente al cambio.
Devuelve hallazgos con path, requisito, reproducción y esperado; clasifica
según severidad Área 07. Identifica omisiones/notRun. No edites archivos
ni declares aprobación de gates por el hecho de que compile o pase host.
```

### 10.6 PR y handoff

```markdown
# VIG-xxx — comportamiento resultante
Problema/trigger: ...
Cambio: ...
Fuentes e IDs: ...
Validación ejecutada: comando, entorno, expected/actual, resultado/evidencia
Pendiente/no ejecutado: ...
Riesgos/compatibilidad/migración: ...

Handoff:
- Escritor/revisor, tarea/estado, rama y commit base/final
- Paths/diff y documentación/ADR actualizados
- APK/modelo/policy/config/hash y run-manifest
- Incidencias y siguiente acción exacta
```

## 11. Evidencia, campañas y decisión de etapa

El registro de ejecución conserva `runId`, fecha/zona, operador, commit, toolchain, applicationId/variante, APK/hash, dispositivo/Android, modelo/hash, policy/config/Kcal, fixture/input/hash/seed, expected/actual, resultado, incidencias y paths de evidencia. Se identifican origen físico/sintético/web y relojes utilizados. No se usan capturas de una build para aprobar otra sin análisis de cambios.

La entrada del registro es una ejecución, no una frase del agente. Cada fuente apunta a QA y a tareas responsables; QA apunta a runs y fallos. Se pueden reutilizar evidencias solo con revisión del alcance de cambios y condiciones Área 07. AI determinista y DT de host no reemplazan EV ni Android. Ausencia de muestras/PID continuo bloquea el cálculo de memoria en lugar de completar valores por estimación.

Etapas: E0 documentación; E1 viabilidad; E2 entrega académica con pendientes explícitos; E3 V1 con los 192 CA RF/RNF/UX y G02–G09 aprobados; E4 comercial con contexto adicional y G10/RL. El nombre de una rama o build “release” no cambia la etapa. Una demo impecable con fixtures sigue siendo demo.

La campaña Android conserva presupuestos del Área 07: p95 captura→resultado <200 ms, audio ≤500 ms desde decisión, p95 build/raster ≤16,7 ms a 60 Hz, stop ≤2 s y UI ≤1000 ms desde recepción. No mezclar latencias ni convertir percentil en media. QA35/QA36 fijan muestras, duración y repeticiones; este backlog no las reduce.

Incidencia incluye severidad, requisito, versión, reproducción, esperado/actual y evidencia. S0/S1 impiden candidato; un criterio vigente fallido impide G09 aunque la severidad sea menor. No usar “aceptado con excepción” para llamar E3 a una V1 incompleta; cambiar alcance requiere PRD/UX versionados y decisión explícita.

## 12. Bloqueos y decisiones todavía abiertos

| Falta real | Acción prevista | Qué puede continuar / qué no se cierra |
|---|---|---|
| HTML completo B5.2, recursos y motion | VIG-032 inspecciona archivo/inventario | H00–H03 pueden avanzar; G05/QA34 no se aprueban |
| Equipos concretos y toolchain compilada | VIG-002/003/055–058 | Documentación/harness; no soporte físico declarado |
| Modelo asset/licencia/hash | VIG-011 | Contratos/estructura; no inferencia física completada |
| EyeVisibilityGate viable | VIG-016/060/062 | Geometría y fixtures; no ojos ocluidos como Q usable ni G08 |
| Participantes UT y evaluación IA | VIG-051/060/061 | Protocolos listos; pruebas notRun, no resultados inventados |
| Calificación independiente de señales | VIG-062/063 | E2 con límites; no E3/G08 si falla o falta exposición |
| Identidad/firma/cuenta/soporte/responsable | VIG-068–070 | Paquete de desarrollo; no RL/G10 comercial completos |
| Evaluación de contexto comercial | VIG-067 | E3 posible con sus gates; E4/RL09 siguen bloqueados |

El inventario B5.2 no exige volver a Claude Design hoy. Se mantendrá como referencia hasta implementar y verificar en Flutter; un defecto observado genera corrección concreta. No se solicita otro rediseño preventivo.

## 13. Fuentes técnicas oficiales

Consultadas para las reglas de colaboración/organización; no prueban que Vigía funcione.

- **S1. OpenAI, instrucciones de proyecto:** [AGENTS.md](https://developers.openai.com/codex/guides/agents-md). Documentación oficial de alcance/carga de instrucciones.
- **S2. Anthropic, contexto persistente:** [Memory / CLAUDE.md](https://code.claude.com/docs/en/memory). Importaciones y carga de instrucciones del proyecto.
- **S3. Git:** [git-worktree](https://git-scm.com/docs/git-worktree). Árboles de trabajo separados para ejecución futura autorizada.
- **S4. Dart:** [Pub workspaces](https://dart.dev/tools/pub/workspaces). Alternativa opcional de resolución compartida.
- **S5. Flutter/Pigeon:** [Pigeon](https://pub.dev/packages/pigeon). Generación y límites de compatibilidad de los lados generados.
- **S6. Flutter:** [Developing packages and plugins](https://docs.flutter.dev/packages-and-plugins/developing-packages). Estructura del plugin y plataformas declaradas.

No se fijaron versiones de estas herramientas desde un fragmento de documentación. Al crear el repo se comprueban las instaladas y se registra la matriz. Políticas Android/Play se revalidan para distribución como exige Área 07.

## 14. Verificación de esta entrega

Se ejecutaron **26 comprobaciones estructurales**, todas correctas, sobre este documento y el anexo actual Área 07: IDs/conteos, dependencias/DAG, fichas completas, referencias QA, trazabilidad de 310 fuentes, 12 RL y plantillas. No se ejecutaron builds, tests de app, cámara, audio, TalkBack, participantes, evaluación IA ni publicación.

- 72 tareas con IDs consecutivos y únicos: correcto.
- Dependencias existentes, únicas y sin autorreferencia: correcto.
- Grafo de dependencias sin ciclos: correcto.
- Todo prerrequisito precede al consumidor en numeración: correcto.
- Resultado, cierre y paths no vacíos en cada tarea: correcto.
- Estado de tarea/evidencia sin ejecución ficticia: correcto.
- 40 QA existentes en Área 07: correcto.
- Referencias QA de tareas válidas y cobertura completa: correcto.
- 310 fuentes únicas extraídas del anexo vigente: correcto.
- Conteos RF/RNF/UX/AT/AI/EV/DT/SC/DS/UT conservados: correcto.
- 192 CA de producto preservados: correcto.
- Toda fuente tiene QA válido y estado inicial permitido: correcto.
- 40 QA tienen responsabilidad directa de backlog: correcto.
- Responsables de QA existen y citan ese QA: correcto.
- 26 pantallas/diálogos con nombre UX y responsable exactos: correcto.
- Cada fuente tiene una tarea principal existente: correcto.
- Tarea principal vinculada a un QA de su fuente: correcto.
- 310 filas de trazabilidad generadas: correcto.
- Todas las fuentes mapean a tareas existentes: correcto.
- 12 RL tienen filas independientes: correcto.
- 72 fichas visibles sin duplicados: correcto.
- 11 hitos visibles con cobertura total: correcto.
- Sin bloques de código incompletos: correcto.
- Plantillas comunes explícitas sin archivos activos: correcto.
- ADR SAF mantiene separación de autoridad y estado desconocido: correcto.
- Sin marcadores editoriales pendientes salvo resumen de validación: correcto.

## 15. Anexo: fuente → QA → tareas

La tabla conserva cada ID del anexo vigente Área 07 exactamente una vez. El texto íntegro del criterio está en su fuente y Área 07; aquí no se abrevia su significado para implementarlo. La tarea principal responde por integrar ese criterio/ensayo en la ficha correspondiente; la columna adicional localiza implementación de apoyo y campañas para todos sus QA. Es **responsabilidad planificada, no aceptación individual**. Al ejecutar se registra qué subcasos satisface cada diff/run y el cierre independiente del criterio; una campaña no sustituye al responsable técnico.

SC/DS/UT conservan `planned`; criterios y ensayos `notRun`. RL01–RL12 no son parte de los 310 IDs base: se trazan por separado en §16.

| ID fuente | QA asignados (Área 07) | Tarea principal | Apoyo y campañas | Estado fuente inicial |
|---|---|---|---|---|
| RF01.CA1 | QA01 | VIG-035 | VIG-044, VIG-047, VIG-052, VIG-053 | notRun |
| RF01.CA2 | QA01 | VIG-035 | VIG-044, VIG-047, VIG-052, VIG-053 | notRun |
| RF01.CA3 | QA01 | VIG-035 | VIG-044, VIG-047, VIG-052, VIG-053 | notRun |
| RF02.CA1 | QA02 | VIG-035 | VIG-010, VIG-047, VIG-053 | notRun |
| RF02.CA2 | QA02 | VIG-035 | VIG-010, VIG-047, VIG-053 | notRun |
| RF02.CA3 | QA02 | VIG-035 | VIG-010, VIG-047, VIG-053 | notRun |
| RF03.CA1 | QA03 | VIG-016 | VIG-011, VIG-015, VIG-036, VIG-047, VIG-053, VIG-062 | notRun |
| RF03.CA2 | QA03 | VIG-016 | VIG-011, VIG-015, VIG-036, VIG-047, VIG-053, VIG-062 | notRun |
| RF03.CA3 | QA03 | VIG-016 | VIG-011, VIG-015, VIG-036, VIG-047, VIG-053, VIG-062 | notRun |
| RF04.CA1 | QA04 | VIG-022 | VIG-021, VIG-036, VIG-043, VIG-047, VIG-053 | notRun |
| RF04.CA2 | QA04 | VIG-022 | VIG-021, VIG-036, VIG-043, VIG-047, VIG-053 | notRun |
| RF04.CA3 | QA04 | VIG-022 | VIG-021, VIG-036, VIG-043, VIG-047, VIG-053 | notRun |
| RF05.CA1 | QA05 | VIG-022 | VIG-036, VIG-047, VIG-053 | notRun |
| RF05.CA2 | QA05 | VIG-022 | VIG-036, VIG-047, VIG-053 | notRun |
| RF05.CA3 | QA05 | VIG-022 | VIG-036, VIG-047, VIG-053 | notRun |
| RF06.CA1 | QA06 | VIG-017 | VIG-036, VIG-047, VIG-053, VIG-062 | notRun |
| RF06.CA2 | QA06 | VIG-017 | VIG-036, VIG-047, VIG-053, VIG-062 | notRun |
| RF06.CA3 | QA06 | VIG-017 | VIG-036, VIG-047, VIG-053, VIG-062 | notRun |
| RF07.CA1 | QA07 | VIG-017 | VIG-023, VIG-036, VIG-047, VIG-053, VIG-063 | notRun |
| RF07.CA2 | QA07 | VIG-017 | VIG-023, VIG-036, VIG-047, VIG-053, VIG-063 | notRun |
| RF07.CA3 | QA07 | VIG-017 | VIG-023, VIG-036, VIG-047, VIG-053, VIG-063 | notRun |
| RF08.CA1 | QA08 | VIG-026 | VIG-009, VIG-022, VIG-024, VIG-037, VIG-047, VIG-052, VIG-053 | notRun |
| RF08.CA2 | QA08 | VIG-026 | VIG-009, VIG-022, VIG-024, VIG-037, VIG-047, VIG-052, VIG-053 | notRun |
| RF08.CA3 | QA08 | VIG-026 | VIG-009, VIG-022, VIG-024, VIG-037, VIG-047, VIG-052, VIG-053 | notRun |
| RF09.CA1 | QA09 | VIG-011 | VIG-004, VIG-014, VIG-047, VIG-053, VIG-054, VIG-058 | notRun |
| RF09.CA2 | QA09 | VIG-011 | VIG-004, VIG-014, VIG-047, VIG-053, VIG-054, VIG-058 | notRun |
| RF09.CA3 | QA09 | VIG-011 | VIG-004, VIG-014, VIG-047, VIG-053, VIG-054, VIG-058 | notRun |
| RF10.CA1 | QA10 | VIG-037 | VIG-009, VIG-025, VIG-026, VIG-047, VIG-053 | notRun |
| RF10.CA2 | QA10 | VIG-037 | VIG-009, VIG-025, VIG-026, VIG-047, VIG-053 | notRun |
| RF10.CA3 | QA10 | VIG-037 | VIG-009, VIG-025, VIG-026, VIG-047, VIG-053 | notRun |
| RF11.CA1 | QA11 | VIG-019 | VIG-021, VIG-037, VIG-047, VIG-052, VIG-053, VIG-055, VIG-062 | notRun |
| RF11.CA2 | QA11 | VIG-019 | VIG-021, VIG-037, VIG-047, VIG-052, VIG-053, VIG-055, VIG-062 | notRun |
| RF11.CA3 | QA11 | VIG-019 | VIG-021, VIG-037, VIG-047, VIG-052, VIG-053, VIG-055, VIG-062 | notRun |
| RF12.CA1 | QA12 | VIG-018 | VIG-021, VIG-037, VIG-047, VIG-052, VIG-053, VIG-055, VIG-062 | notRun |
| RF12.CA2 | QA12 | VIG-018 | VIG-021, VIG-037, VIG-047, VIG-052, VIG-053, VIG-055, VIG-062 | notRun |
| RF12.CA3 | QA12 | VIG-018 | VIG-021, VIG-037, VIG-047, VIG-052, VIG-053, VIG-055, VIG-062 | notRun |
| RF13.CA1 | QA13 | VIG-020 | VIG-021, VIG-037, VIG-047, VIG-052, VIG-053 | notRun |
| RF13.CA2 | QA13 | VIG-020 | VIG-021, VIG-037, VIG-047, VIG-052, VIG-053 | notRun |
| RF13.CA3 | QA13 | VIG-020 | VIG-021, VIG-037, VIG-047, VIG-052, VIG-053 | notRun |
| RF14.CA1 | QA14 | VIG-018 | VIG-016, VIG-019, VIG-037, VIG-047, VIG-052, VIG-053, VIG-062 | notRun |
| RF14.CA2 | QA14 | VIG-018 | VIG-016, VIG-019, VIG-037, VIG-047, VIG-052, VIG-053, VIG-062 | notRun |
| RF14.CA3 | QA14 | VIG-018 | VIG-016, VIG-019, VIG-037, VIG-047, VIG-052, VIG-053, VIG-062 | notRun |
| RF15.CA1 | QA15 | VIG-018 | VIG-020, VIG-037, VIG-047, VIG-052, VIG-053, VIG-062 | notRun |
| RF15.CA2 | QA15 | VIG-018 | VIG-020, VIG-037, VIG-047, VIG-052, VIG-053, VIG-062 | notRun |
| RF15.CA3 | QA15 | VIG-018 | VIG-020, VIG-037, VIG-047, VIG-052, VIG-053, VIG-062 | notRun |
| RF16.CA1 | QA16 | VIG-026 | VIG-037, VIG-047, VIG-053, VIG-056 | notRun |
| RF16.CA2 | QA16 | VIG-026 | VIG-037, VIG-047, VIG-053, VIG-056 | notRun |
| RF16.CA3 | QA16 | VIG-026 | VIG-037, VIG-047, VIG-053, VIG-056 | notRun |
| RF17.CA1 | QA17 | VIG-026 | VIG-022, VIG-037, VIG-047, VIG-053, VIG-056 | notRun |
| RF17.CA2 | QA17 | VIG-026 | VIG-022, VIG-037, VIG-047, VIG-053, VIG-056 | notRun |
| RF17.CA3 | QA17 | VIG-026 | VIG-022, VIG-037, VIG-047, VIG-053, VIG-056 | notRun |
| RF18.CA1 | QA18 | VIG-026 | VIG-010, VIG-021, VIG-027, VIG-037, VIG-047, VIG-053, VIG-057 | notRun |
| RF18.CA2 | QA18 | VIG-026 | VIG-010, VIG-021, VIG-027, VIG-037, VIG-047, VIG-053, VIG-057 | notRun |
| RF18.CA3 | QA18 | VIG-026 | VIG-010, VIG-021, VIG-027, VIG-037, VIG-047, VIG-053, VIG-057 | notRun |
| RF19.CA1 | QA19 | VIG-028 | VIG-025, VIG-035, VIG-037, VIG-047, VIG-053, VIG-056 | notRun |
| RF19.CA2 | QA19 | VIG-028 | VIG-025, VIG-035, VIG-037, VIG-047, VIG-053, VIG-056 | notRun |
| RF19.CA3 | QA19 | VIG-028 | VIG-025, VIG-035, VIG-037, VIG-047, VIG-053, VIG-056 | notRun |
| RF20.CA1 | QA20 | VIG-038 | VIG-025, VIG-047, VIG-053 | notRun |
| RF20.CA2 | QA20 | VIG-038 | VIG-025, VIG-047, VIG-053 | notRun |
| RF20.CA3 | QA20 | VIG-038 | VIG-025, VIG-047, VIG-053 | notRun |
| RF21.CA1 | QA21 | VIG-039 | VIG-023, VIG-027, VIG-028, VIG-045, VIG-047, VIG-052, VIG-053 | notRun |
| RF21.CA2 | QA21 | VIG-039 | VIG-023, VIG-027, VIG-028, VIG-045, VIG-047, VIG-052, VIG-053 | notRun |
| RF21.CA3 | QA21 | VIG-039 | VIG-023, VIG-027, VIG-028, VIG-045, VIG-047, VIG-052, VIG-053 | notRun |
| RF22.CA1 | QA22 | VIG-040 | VIG-031, VIG-047, VIG-052, VIG-053 | notRun |
| RF22.CA2 | QA22 | VIG-040 | VIG-031, VIG-047, VIG-052, VIG-053 | notRun |
| RF22.CA3 | QA22 | VIG-040 | VIG-031, VIG-047, VIG-052, VIG-053 | notRun |
| RF23.CA1 | QA23 | VIG-041 | VIG-020, VIG-039, VIG-047, VIG-052, VIG-053 | notRun |
| RF23.CA2 | QA23 | VIG-041 | VIG-020, VIG-039, VIG-047, VIG-052, VIG-053 | notRun |
| RF23.CA3 | QA23 | VIG-041 | VIG-020, VIG-039, VIG-047, VIG-052, VIG-053 | notRun |
| RF24.CA1 | QA24 | VIG-041 | VIG-023, VIG-047, VIG-052, VIG-053 | notRun |
| RF24.CA2 | QA24 | VIG-041 | VIG-023, VIG-047, VIG-052, VIG-053 | notRun |
| RF24.CA3 | QA24 | VIG-041 | VIG-023, VIG-047, VIG-052, VIG-053 | notRun |
| RF25.CA1 | QA25 | VIG-042 | VIG-023, VIG-030, VIG-047, VIG-052, VIG-053 | notRun |
| RF25.CA2 | QA25 | VIG-042 | VIG-023, VIG-030, VIG-047, VIG-052, VIG-053 | notRun |
| RF25.CA3 | QA25 | VIG-042 | VIG-023, VIG-030, VIG-047, VIG-052, VIG-053 | notRun |
| RF26.CA1 | QA26 | VIG-046 | VIG-007, VIG-038, VIG-045, VIG-047, VIG-052, VIG-053, VIG-054 | notRun |
| RF26.CA2 | QA26 | VIG-046 | VIG-007, VIG-038, VIG-045, VIG-047, VIG-052, VIG-053, VIG-054 | notRun |
| RF26.CA3 | QA26 | VIG-046 | VIG-007, VIG-038, VIG-045, VIG-047, VIG-052, VIG-053, VIG-054 | notRun |
| RF27.CA1 | QA27 | VIG-029 | VIG-038, VIG-043, VIG-045, VIG-047, VIG-052, VIG-053, VIG-054 | notRun |
| RF27.CA2 | QA27 | VIG-029 | VIG-038, VIG-043, VIG-045, VIG-047, VIG-052, VIG-053, VIG-054 | notRun |
| RF27.CA3 | QA27 | VIG-029 | VIG-038, VIG-043, VIG-045, VIG-047, VIG-052, VIG-053, VIG-054 | notRun |
| RF28.CA1 | QA28 | VIG-030 | VIG-038, VIG-043, VIG-047, VIG-052, VIG-053 | notRun |
| RF28.CA2 | QA28 | VIG-030 | VIG-038, VIG-043, VIG-047, VIG-052, VIG-053 | notRun |
| RF28.CA3 | QA28 | VIG-030 | VIG-038, VIG-043, VIG-047, VIG-052, VIG-053 | notRun |
| RF29.CA1 | QA29 | VIG-043 | VIG-017, VIG-022, VIG-033, VIG-047, VIG-052, VIG-053, VIG-063 | notRun |
| RF29.CA2 | QA29 | VIG-043 | VIG-017, VIG-022, VIG-033, VIG-047, VIG-052, VIG-053, VIG-063 | notRun |
| RF29.CA3 | QA29 | VIG-043 | VIG-017, VIG-022, VIG-033, VIG-047, VIG-052, VIG-053, VIG-063 | notRun |
| RF30.CA1 | QA30 | VIG-044 | VIG-038, VIG-047, VIG-053 | notRun |
| RF30.CA2 | QA30 | VIG-044 | VIG-038, VIG-047, VIG-053 | notRun |
| RF30.CA3 | QA30 | VIG-044 | VIG-038, VIG-047, VIG-053 | notRun |
| RF31.CA1 | QA31 | VIG-024 | VIG-012, VIG-025, VIG-027, VIG-028, VIG-029, VIG-031, VIG-047, VIG-052, VIG-053 | notRun |
| RF31.CA2 | QA31 | VIG-024 | VIG-012, VIG-025, VIG-027, VIG-028, VIG-029, VIG-031, VIG-047, VIG-052, VIG-053 | notRun |
| RF31.CA3 | QA31 | VIG-024 | VIG-012, VIG-025, VIG-027, VIG-028, VIG-029, VIG-031, VIG-047, VIG-052, VIG-053 | notRun |
| RF32.CA1 | QA32 | VIG-047 | VIG-004, VIG-008, VIG-053, VIG-058 | notRun |
| RF32.CA2 | QA32 | VIG-047 | VIG-004, VIG-008, VIG-053, VIG-058 | notRun |
| RF32.CA3 | QA32 | VIG-047 | VIG-004, VIG-008, VIG-053, VIG-058 | notRun |
| RNF01.CA1 | QA09, QA26, QA27, QA30, QA37 | VIG-047 | VIG-004, VIG-007, VIG-011, VIG-014, VIG-024, VIG-029, VIG-038, VIG-043, VIG-044, VIG-045, VIG-046, VIG-052, VIG-053, VIG-054, VIG-058 | notRun |
| RNF01.CA2 | QA09, QA26, QA27, QA30, QA37 | VIG-037 | VIG-004, VIG-007, VIG-011, VIG-014, VIG-024, VIG-029, VIG-038, VIG-043, VIG-044, VIG-045, VIG-046, VIG-047, VIG-052, VIG-053, VIG-054, VIG-058 | notRun |
| RNF01.CA3 | QA09, QA26, QA27, QA30, QA37 | VIG-047 | VIG-004, VIG-007, VIG-011, VIG-014, VIG-024, VIG-029, VIG-038, VIG-043, VIG-044, VIG-045, VIG-046, VIG-052, VIG-053, VIG-054, VIG-058 | notRun |
| RNF02.CA1 | QA35 | VIG-050 | VIG-002, VIG-055, VIG-057 | notRun |
| RNF02.CA2 | QA35 | VIG-050 | VIG-002, VIG-055, VIG-057 | notRun |
| RNF02.CA3 | QA35 | VIG-050 | VIG-002, VIG-055, VIG-057 | notRun |
| RNF03.CA1 | QA33, QA34 | VIG-048 | VIG-032, VIG-033, VIG-034, VIG-049, VIG-050 | notRun |
| RNF03.CA2 | QA33, QA34 | VIG-048 | VIG-032, VIG-033, VIG-034, VIG-049, VIG-050 | notRun |
| RNF03.CA3 | QA33, QA34 | VIG-048 | VIG-032, VIG-033, VIG-034, VIG-049, VIG-050 | notRun |
| RNF04.CA1 | QA36 | VIG-056 | VIG-002, VIG-026, VIG-028 | notRun |
| RNF04.CA2 | QA36 | VIG-056 | VIG-002, VIG-026, VIG-028 | notRun |
| RNF04.CA3 | QA36 | VIG-056 | VIG-002, VIG-026, VIG-028 | notRun |
| RNF05.CA1 | QA08, QA27, QA31 | VIG-024 | VIG-009, VIG-012, VIG-022, VIG-025, VIG-026, VIG-027, VIG-028, VIG-029, VIG-031, VIG-037, VIG-038, VIG-043, VIG-045, VIG-047, VIG-052, VIG-053, VIG-054 | notRun |
| RNF05.CA2 | QA08, QA27, QA31 | VIG-024 | VIG-009, VIG-012, VIG-022, VIG-025, VIG-026, VIG-027, VIG-028, VIG-029, VIG-031, VIG-037, VIG-038, VIG-043, VIG-045, VIG-047, VIG-052, VIG-053, VIG-054 | notRun |
| RNF05.CA3 | QA08, QA27, QA31 | VIG-029 | VIG-009, VIG-012, VIG-022, VIG-024, VIG-025, VIG-026, VIG-027, VIG-028, VIG-031, VIG-037, VIG-038, VIG-043, VIG-045, VIG-047, VIG-052, VIG-053, VIG-054 | notRun |
| RNF06.CA1 | QA18 | VIG-026 | VIG-010, VIG-021, VIG-027, VIG-037, VIG-047, VIG-053, VIG-057 | notRun |
| RNF06.CA2 | QA18 | VIG-026 | VIG-010, VIG-021, VIG-027, VIG-037, VIG-047, VIG-053, VIG-057 | notRun |
| RNF06.CA3 | QA18 | VIG-026 | VIG-010, VIG-021, VIG-027, VIG-037, VIG-047, VIG-053, VIG-057 | notRun |
| RNF07.CA1 | QA35 | VIG-055 | VIG-002, VIG-050, VIG-057 | notRun |
| RNF07.CA2 | QA35 | VIG-055 | VIG-002, VIG-050, VIG-057 | notRun |
| RNF07.CA3 | QA35 | VIG-055 | VIG-002, VIG-050, VIG-057 | notRun |
| RNF08.CA1 | QA35, QA39, QA40 | VIG-064 | VIG-001, VIG-002, VIG-005, VIG-016, VIG-050, VIG-055, VIG-057, VIG-058, VIG-059, VIG-060, VIG-061, VIG-062, VIG-063, VIG-065, VIG-066, VIG-067, VIG-068, VIG-069, VIG-070, VIG-071, VIG-072 | notRun |
| RNF08.CA2 | QA35, QA39, QA40 | VIG-064 | VIG-001, VIG-002, VIG-005, VIG-016, VIG-050, VIG-055, VIG-057, VIG-058, VIG-059, VIG-060, VIG-061, VIG-062, VIG-063, VIG-065, VIG-066, VIG-067, VIG-068, VIG-069, VIG-070, VIG-071, VIG-072 | notRun |
| RNF08.CA3 | QA35, QA39, QA40 | VIG-064 | VIG-001, VIG-002, VIG-005, VIG-016, VIG-050, VIG-055, VIG-057, VIG-058, VIG-059, VIG-060, VIG-061, VIG-062, VIG-063, VIG-065, VIG-066, VIG-067, VIG-068, VIG-069, VIG-070, VIG-071, VIG-072 | notRun |
| RNF09.CA1 | QA35 | VIG-057 | VIG-002, VIG-050, VIG-055 | notRun |
| RNF09.CA2 | QA35 | VIG-057 | VIG-002, VIG-050, VIG-055 | notRun |
| RNF09.CA3 | QA35 | VIG-057 | VIG-002, VIG-050, VIG-055 | notRun |
| RNF10.CA1 | QA29, QA32, QA40 | VIG-047 | VIG-001, VIG-004, VIG-005, VIG-008, VIG-017, VIG-022, VIG-033, VIG-043, VIG-052, VIG-053, VIG-058, VIG-063, VIG-064, VIG-065, VIG-066, VIG-067, VIG-068, VIG-069, VIG-070, VIG-071, VIG-072 | notRun |
| RNF10.CA2 | QA29, QA32, QA40 | VIG-047 | VIG-001, VIG-004, VIG-005, VIG-008, VIG-017, VIG-022, VIG-033, VIG-043, VIG-052, VIG-053, VIG-058, VIG-063, VIG-064, VIG-065, VIG-066, VIG-067, VIG-068, VIG-069, VIG-070, VIG-071, VIG-072 | notRun |
| RNF10.CA3 | QA29, QA32, QA40 | VIG-047 | VIG-001, VIG-004, VIG-005, VIG-008, VIG-017, VIG-022, VIG-033, VIG-043, VIG-052, VIG-053, VIG-058, VIG-063, VIG-064, VIG-065, VIG-066, VIG-067, VIG-068, VIG-069, VIG-070, VIG-071, VIG-072 | notRun |
| UX01.CA1 | QA01, QA19, QA20 | VIG-035 | VIG-025, VIG-028, VIG-037, VIG-038, VIG-044, VIG-047, VIG-052, VIG-053, VIG-056 | notRun |
| UX01.CA2 | QA01, QA19, QA20 | VIG-025 | VIG-028, VIG-035, VIG-037, VIG-038, VIG-044, VIG-047, VIG-052, VIG-053, VIG-056 | notRun |
| UX01.CA3 | QA01, QA19, QA20 | VIG-025 | VIG-028, VIG-035, VIG-037, VIG-038, VIG-044, VIG-047, VIG-052, VIG-053, VIG-056 | notRun |
| UX02.CA1 | QA02 | VIG-035 | VIG-010, VIG-047, VIG-053 | notRun |
| UX02.CA2 | QA02 | VIG-035 | VIG-010, VIG-047, VIG-053 | notRun |
| UX02.CA3 | QA02 | VIG-035 | VIG-010, VIG-047, VIG-053 | notRun |
| UX03.CA1 | QA03, QA05 | VIG-036 | VIG-011, VIG-015, VIG-016, VIG-022, VIG-047, VIG-053, VIG-062 | notRun |
| UX03.CA2 | QA03, QA05 | VIG-036 | VIG-011, VIG-015, VIG-016, VIG-022, VIG-047, VIG-053, VIG-062 | notRun |
| UX03.CA3 | QA03, QA05 | VIG-036 | VIG-011, VIG-015, VIG-016, VIG-022, VIG-047, VIG-053, VIG-062 | notRun |
| UX04.CA1 | QA04 | VIG-036 | VIG-021, VIG-022, VIG-043, VIG-047, VIG-053 | notRun |
| UX04.CA2 | QA04 | VIG-036 | VIG-021, VIG-022, VIG-043, VIG-047, VIG-053 | notRun |
| UX04.CA3 | QA04 | VIG-036 | VIG-021, VIG-022, VIG-043, VIG-047, VIG-053 | notRun |
| UX05.CA1 | QA06, QA07 | VIG-036 | VIG-017, VIG-023, VIG-047, VIG-053, VIG-062, VIG-063 | notRun |
| UX05.CA2 | QA06, QA07 | VIG-036 | VIG-017, VIG-023, VIG-047, VIG-053, VIG-062, VIG-063 | notRun |
| UX05.CA3 | QA06, QA07 | VIG-036 | VIG-017, VIG-023, VIG-047, VIG-053, VIG-062, VIG-063 | notRun |
| UX06.CA1 | QA08, QA20 | VIG-037 | VIG-009, VIG-022, VIG-024, VIG-025, VIG-026, VIG-038, VIG-047, VIG-052, VIG-053 | notRun |
| UX06.CA2 | QA08, QA20 | VIG-037 | VIG-009, VIG-022, VIG-024, VIG-025, VIG-026, VIG-038, VIG-047, VIG-052, VIG-053 | notRun |
| UX06.CA3 | QA08, QA20 | VIG-037 | VIG-009, VIG-022, VIG-024, VIG-025, VIG-026, VIG-038, VIG-047, VIG-052, VIG-053 | notRun |
| UX07.CA1 | QA10 | VIG-037 | VIG-009, VIG-025, VIG-026, VIG-047, VIG-053 | notRun |
| UX07.CA2 | QA10 | VIG-037 | VIG-009, VIG-025, VIG-026, VIG-047, VIG-053 | notRun |
| UX07.CA3 | QA10 | VIG-037 | VIG-009, VIG-025, VIG-026, VIG-047, VIG-053 | notRun |
| UX08.CA1 | QA11, QA12, QA13 | VIG-037 | VIG-018, VIG-019, VIG-020, VIG-021, VIG-047, VIG-052, VIG-053, VIG-055, VIG-062 | notRun |
| UX08.CA2 | QA11, QA12, QA13 | VIG-037 | VIG-018, VIG-019, VIG-020, VIG-021, VIG-047, VIG-052, VIG-053, VIG-055, VIG-062 | notRun |
| UX08.CA3 | QA11, QA12, QA13 | VIG-037 | VIG-018, VIG-019, VIG-020, VIG-021, VIG-047, VIG-052, VIG-053, VIG-055, VIG-062 | notRun |
| UX09.CA1 | QA14, QA15 | VIG-037 | VIG-016, VIG-018, VIG-019, VIG-020, VIG-047, VIG-052, VIG-053, VIG-062 | notRun |
| UX09.CA2 | QA14, QA15 | VIG-037 | VIG-016, VIG-018, VIG-019, VIG-020, VIG-047, VIG-052, VIG-053, VIG-062 | notRun |
| UX09.CA3 | QA14, QA15 | VIG-037 | VIG-016, VIG-018, VIG-019, VIG-020, VIG-047, VIG-052, VIG-053, VIG-062 | notRun |
| UX10.CA1 | QA16, QA17 | VIG-037 | VIG-022, VIG-026, VIG-047, VIG-053, VIG-056 | notRun |
| UX10.CA2 | QA16, QA17 | VIG-037 | VIG-022, VIG-026, VIG-047, VIG-053, VIG-056 | notRun |
| UX10.CA3 | QA16, QA17 | VIG-037 | VIG-022, VIG-026, VIG-047, VIG-053, VIG-056 | notRun |
| UX11.CA1 | QA20 | VIG-038 | VIG-025, VIG-047, VIG-053 | notRun |
| UX11.CA2 | QA20 | VIG-038 | VIG-025, VIG-047, VIG-053 | notRun |
| UX11.CA3 | QA20 | VIG-038 | VIG-025, VIG-047, VIG-053 | notRun |
| UX12.CA1 | QA18, QA21, QA31 | VIG-037 | VIG-010, VIG-012, VIG-021, VIG-023, VIG-024, VIG-025, VIG-026, VIG-027, VIG-028, VIG-029, VIG-031, VIG-039, VIG-045, VIG-047, VIG-052, VIG-053, VIG-057 | notRun |
| UX12.CA2 | QA18, QA21, QA31 | VIG-039 | VIG-010, VIG-012, VIG-021, VIG-023, VIG-024, VIG-025, VIG-026, VIG-027, VIG-028, VIG-029, VIG-031, VIG-037, VIG-045, VIG-047, VIG-052, VIG-053, VIG-057 | notRun |
| UX12.CA3 | QA18, QA21, QA31 | VIG-039 | VIG-010, VIG-012, VIG-021, VIG-023, VIG-024, VIG-025, VIG-026, VIG-027, VIG-028, VIG-029, VIG-031, VIG-037, VIG-045, VIG-047, VIG-052, VIG-053, VIG-057 | notRun |
| UX13.CA1 | QA19 | VIG-028 | VIG-025, VIG-035, VIG-037, VIG-047, VIG-053, VIG-056 | notRun |
| UX13.CA2 | QA19 | VIG-028 | VIG-025, VIG-035, VIG-037, VIG-047, VIG-053, VIG-056 | notRun |
| UX13.CA3 | QA19 | VIG-028 | VIG-025, VIG-035, VIG-037, VIG-047, VIG-053, VIG-056 | notRun |
| UX14.CA1 | QA21 | VIG-039 | VIG-023, VIG-027, VIG-028, VIG-045, VIG-047, VIG-052, VIG-053 | notRun |
| UX14.CA2 | QA21 | VIG-039 | VIG-023, VIG-027, VIG-028, VIG-045, VIG-047, VIG-052, VIG-053 | notRun |
| UX14.CA3 | QA21 | VIG-039 | VIG-023, VIG-027, VIG-028, VIG-045, VIG-047, VIG-052, VIG-053 | notRun |
| UX15.CA1 | QA22, QA23 | VIG-040 | VIG-020, VIG-031, VIG-039, VIG-041, VIG-047, VIG-052, VIG-053 | notRun |
| UX15.CA2 | QA22, QA23 | VIG-040 | VIG-020, VIG-031, VIG-039, VIG-041, VIG-047, VIG-052, VIG-053 | notRun |
| UX15.CA3 | QA22, QA23 | VIG-041 | VIG-020, VIG-031, VIG-039, VIG-040, VIG-047, VIG-052, VIG-053 | notRun |
| UX16.CA1 | QA24 | VIG-041 | VIG-023, VIG-047, VIG-052, VIG-053 | notRun |
| UX16.CA2 | QA24 | VIG-041 | VIG-023, VIG-047, VIG-052, VIG-053 | notRun |
| UX16.CA3 | QA24 | VIG-041 | VIG-023, VIG-047, VIG-052, VIG-053 | notRun |
| UX17.CA1 | QA25 | VIG-042 | VIG-023, VIG-030, VIG-047, VIG-052, VIG-053 | notRun |
| UX17.CA2 | QA25 | VIG-042 | VIG-023, VIG-030, VIG-047, VIG-052, VIG-053 | notRun |
| UX17.CA3 | QA25 | VIG-042 | VIG-023, VIG-030, VIG-047, VIG-052, VIG-053 | notRun |
| UX18.CA1 | QA26 | VIG-046 | VIG-007, VIG-038, VIG-045, VIG-047, VIG-052, VIG-053, VIG-054 | notRun |
| UX18.CA2 | QA26 | VIG-046 | VIG-007, VIG-038, VIG-045, VIG-047, VIG-052, VIG-053, VIG-054 | notRun |
| UX18.CA3 | QA26 | VIG-046 | VIG-007, VIG-038, VIG-045, VIG-047, VIG-052, VIG-053, VIG-054 | notRun |
| UX19.CA1 | QA27 | VIG-029 | VIG-038, VIG-043, VIG-045, VIG-047, VIG-052, VIG-053, VIG-054 | notRun |
| UX19.CA2 | QA27 | VIG-029 | VIG-038, VIG-043, VIG-045, VIG-047, VIG-052, VIG-053, VIG-054 | notRun |
| UX19.CA3 | QA27 | VIG-029 | VIG-038, VIG-043, VIG-045, VIG-047, VIG-052, VIG-053, VIG-054 | notRun |
| UX20.CA1 | QA28 | VIG-030 | VIG-038, VIG-043, VIG-047, VIG-052, VIG-053 | notRun |
| UX20.CA2 | QA28 | VIG-030 | VIG-038, VIG-043, VIG-047, VIG-052, VIG-053 | notRun |
| UX20.CA3 | QA28 | VIG-030 | VIG-038, VIG-043, VIG-047, VIG-052, VIG-053 | notRun |
| UX21.CA1 | QA01, QA29, QA30 | VIG-043 | VIG-017, VIG-022, VIG-033, VIG-035, VIG-038, VIG-044, VIG-047, VIG-052, VIG-053, VIG-063 | notRun |
| UX21.CA2 | QA01, QA29, QA30 | VIG-044 | VIG-017, VIG-022, VIG-033, VIG-035, VIG-038, VIG-043, VIG-047, VIG-052, VIG-053, VIG-063 | notRun |
| UX21.CA3 | QA01, QA29, QA30 | VIG-043 | VIG-017, VIG-022, VIG-033, VIG-035, VIG-038, VIG-044, VIG-047, VIG-052, VIG-053, VIG-063 | notRun |
| UX22.CA1 | QA32, QA33 | VIG-048 | VIG-004, VIG-008, VIG-032, VIG-033, VIG-034, VIG-047, VIG-050, VIG-053, VIG-058 | notRun |
| UX22.CA2 | QA32, QA33 | VIG-048 | VIG-004, VIG-008, VIG-032, VIG-033, VIG-034, VIG-047, VIG-050, VIG-053, VIG-058 | notRun |
| UX22.CA3 | QA32, QA33 | VIG-047 | VIG-004, VIG-008, VIG-032, VIG-033, VIG-034, VIG-048, VIG-050, VIG-053, VIG-058 | notRun |
| DS00 | QA22 | VIG-040 | VIG-031, VIG-047, VIG-052, VIG-053 | planned |
| DS01 | QA21 | VIG-039 | VIG-023, VIG-027, VIG-028, VIG-045, VIG-047, VIG-052, VIG-053 | planned |
| DS02 | QA19, QA21 | VIG-028 | VIG-023, VIG-025, VIG-027, VIG-035, VIG-037, VIG-039, VIG-045, VIG-047, VIG-052, VIG-053, VIG-056 | planned |
| DS03 | QA25 | VIG-042 | VIG-023, VIG-030, VIG-047, VIG-052, VIG-053 | planned |
| DS04 | QA21, QA25 | VIG-039 | VIG-023, VIG-027, VIG-028, VIG-030, VIG-042, VIG-045, VIG-047, VIG-052, VIG-053 | planned |
| DS05 | QA26 | VIG-046 | VIG-007, VIG-038, VIG-045, VIG-047, VIG-052, VIG-053, VIG-054 | planned |
| DS06 | QA27 | VIG-029 | VIG-038, VIG-043, VIG-045, VIG-047, VIG-052, VIG-053, VIG-054 | planned |
| DS07 | QA16 | VIG-037 | VIG-026, VIG-047, VIG-053, VIG-056 | planned |
| DS08 | QA28 | VIG-030 | VIG-038, VIG-043, VIG-047, VIG-052, VIG-053 | planned |
| UT01 | QA38 | VIG-051 | VIG-066 | planned |
| UT02 | QA38 | VIG-051 | VIG-066 | planned |
| UT03 | QA38 | VIG-051 | VIG-066 | planned |
| UT04 | QA38 | VIG-051 | VIG-066 | planned |
| UT05 | QA38 | VIG-051 | VIG-066 | planned |
| UT06 | QA38 | VIG-051 | VIG-066 | planned |
| UT07 | QA38 | VIG-051 | VIG-066 | planned |
| UT08 | QA38 | VIG-051 | VIG-066 | planned |
| AT01 | QA05, QA08 | VIG-022 | VIG-009, VIG-024, VIG-026, VIG-036, VIG-037, VIG-047, VIG-052, VIG-053 | notRun |
| AT02 | QA08, QA20 | VIG-009 | VIG-022, VIG-024, VIG-025, VIG-026, VIG-037, VIG-038, VIG-047, VIG-052, VIG-053 | notRun |
| AT03 | QA16 | VIG-026 | VIG-037, VIG-047, VIG-053, VIG-056 | notRun |
| AT04 | QA02, QA17 | VIG-026 | VIG-010, VIG-022, VIG-035, VIG-037, VIG-047, VIG-053, VIG-056 | notRun |
| AT05 | QA06, QA07 | VIG-017 | VIG-023, VIG-036, VIG-047, VIG-053, VIG-062, VIG-063 | notRun |
| AT06 | QA20 | VIG-025 | VIG-038, VIG-047, VIG-053 | notRun |
| AT07 | QA10, QA12, QA14, QA15 | VIG-018 | VIG-009, VIG-016, VIG-019, VIG-020, VIG-021, VIG-025, VIG-026, VIG-037, VIG-047, VIG-052, VIG-053, VIG-055, VIG-062 | notRun |
| AT08 | QA16, QA18 | VIG-026 | VIG-010, VIG-021, VIG-027, VIG-037, VIG-047, VIG-053, VIG-056, VIG-057 | notRun |
| AT09 | QA31 | VIG-024 | VIG-012, VIG-025, VIG-027, VIG-028, VIG-029, VIG-031, VIG-047, VIG-052, VIG-053 | notRun |
| AT10 | QA31 | VIG-024 | VIG-012, VIG-025, VIG-027, VIG-028, VIG-029, VIG-031, VIG-047, VIG-052, VIG-053 | notRun |
| AT11 | QA19 | VIG-028 | VIG-025, VIG-035, VIG-037, VIG-047, VIG-053, VIG-056 | notRun |
| AT12 | QA27 | VIG-029 | VIG-038, VIG-043, VIG-045, VIG-047, VIG-052, VIG-053, VIG-054 | notRun |
| AT13 | QA28 | VIG-030 | VIG-038, VIG-043, VIG-047, VIG-052, VIG-053 | notRun |
| AT14 | QA21, QA25 | VIG-039 | VIG-023, VIG-027, VIG-028, VIG-030, VIG-042, VIG-045, VIG-047, VIG-052, VIG-053 | notRun |
| AT15 | QA26 | VIG-046 | VIG-007, VIG-038, VIG-045, VIG-047, VIG-052, VIG-053, VIG-054 | notRun |
| AT16 | QA20 | VIG-038 | VIG-025, VIG-047, VIG-053 | notRun |
| AT17 | QA04, QA11, QA12 | VIG-021 | VIG-018, VIG-019, VIG-022, VIG-036, VIG-037, VIG-043, VIG-047, VIG-052, VIG-053, VIG-055, VIG-062 | notRun |
| AT18 | QA09, QA32 | VIG-004 | VIG-008, VIG-011, VIG-014, VIG-047, VIG-053, VIG-054, VIG-058 | notRun |
| AT19 | QA18 | VIG-026 | VIG-010, VIG-021, VIG-027, VIG-037, VIG-047, VIG-053, VIG-057 | notRun |
| AT20 | QA19, QA21 | VIG-028 | VIG-023, VIG-025, VIG-027, VIG-035, VIG-037, VIG-039, VIG-045, VIG-047, VIG-052, VIG-053, VIG-056 | notRun |
| AT21 | QA37 | VIG-054 | VIG-004, VIG-024, VIG-029, VIG-045 | notRun |
| AT22 | QA32 | VIG-008 | VIG-004, VIG-047, VIG-053, VIG-058 | notRun |
| SC01 | QA39, QA35 | VIG-059 | VIG-002, VIG-016, VIG-050, VIG-055, VIG-057, VIG-060, VIG-061, VIG-062, VIG-063 | planned |
| SC02 | QA39, QA35 | VIG-059 | VIG-002, VIG-016, VIG-050, VIG-055, VIG-057, VIG-060, VIG-061, VIG-062, VIG-063 | planned |
| SC03 | QA39, QA35 | VIG-059 | VIG-002, VIG-016, VIG-050, VIG-055, VIG-057, VIG-060, VIG-061, VIG-062, VIG-063 | planned |
| SC04 | QA39, QA35 | VIG-059 | VIG-002, VIG-016, VIG-050, VIG-055, VIG-057, VIG-060, VIG-061, VIG-062, VIG-063 | planned |
| SC05 | QA39, QA03, QA12, QA14 | VIG-059 | VIG-011, VIG-015, VIG-016, VIG-018, VIG-019, VIG-021, VIG-036, VIG-037, VIG-047, VIG-052, VIG-053, VIG-055, VIG-060, VIG-061, VIG-062, VIG-063 | planned |
| SC06 | QA39, QA03, QA12, QA14 | VIG-059 | VIG-011, VIG-015, VIG-016, VIG-018, VIG-019, VIG-021, VIG-036, VIG-037, VIG-047, VIG-052, VIG-053, VIG-055, VIG-060, VIG-061, VIG-062, VIG-063 | planned |
| SC07 | QA39, QA03, QA12, QA14 | VIG-059 | VIG-011, VIG-015, VIG-016, VIG-018, VIG-019, VIG-021, VIG-036, VIG-037, VIG-047, VIG-052, VIG-053, VIG-055, VIG-060, VIG-061, VIG-062, VIG-063 | planned |
| SC08 | QA39, QA03, QA12, QA14 | VIG-059 | VIG-011, VIG-015, VIG-016, VIG-018, VIG-019, VIG-021, VIG-036, VIG-037, VIG-047, VIG-052, VIG-053, VIG-055, VIG-060, VIG-061, VIG-062, VIG-063 | planned |
| SC09 | QA39, QA03, QA12, QA14 | VIG-059 | VIG-011, VIG-015, VIG-016, VIG-018, VIG-019, VIG-021, VIG-036, VIG-037, VIG-047, VIG-052, VIG-053, VIG-055, VIG-060, VIG-061, VIG-062, VIG-063 | planned |
| SC10 | QA39, QA03, QA12, QA14 | VIG-059 | VIG-011, VIG-015, VIG-016, VIG-018, VIG-019, VIG-021, VIG-036, VIG-037, VIG-047, VIG-052, VIG-053, VIG-055, VIG-060, VIG-061, VIG-062, VIG-063 | planned |
| SC11 | QA39, QA14, QA15 | VIG-059 | VIG-016, VIG-018, VIG-019, VIG-020, VIG-037, VIG-047, VIG-052, VIG-053, VIG-060, VIG-061, VIG-062, VIG-063 | planned |
| SC12 | QA39, QA16, QA17, QA19 | VIG-059 | VIG-016, VIG-022, VIG-025, VIG-026, VIG-028, VIG-035, VIG-037, VIG-047, VIG-053, VIG-056, VIG-060, VIG-061, VIG-062, VIG-063 | planned |
| SC13 | QA39, QA12 | VIG-059 | VIG-016, VIG-018, VIG-021, VIG-037, VIG-047, VIG-052, VIG-053, VIG-055, VIG-060, VIG-061, VIG-062, VIG-063 | planned |
| SC14 | QA39, QA07 | VIG-059 | VIG-016, VIG-017, VIG-023, VIG-036, VIG-047, VIG-053, VIG-060, VIG-061, VIG-062, VIG-063 | planned |
| EV01 | QA39, QA40 | VIG-064 | VIG-001, VIG-005, VIG-016, VIG-058, VIG-059, VIG-060, VIG-061, VIG-062, VIG-063, VIG-065, VIG-066, VIG-067, VIG-068, VIG-069, VIG-070, VIG-071, VIG-072 | notRun |
| EV02 | QA11, QA12, QA13, QA14, QA15, QA16, QA39 | VIG-052 | VIG-016, VIG-018, VIG-019, VIG-020, VIG-021, VIG-026, VIG-037, VIG-047, VIG-053, VIG-055, VIG-056, VIG-059, VIG-060, VIG-061, VIG-062, VIG-063 | notRun |
| EV03 | QA06, QA39 | VIG-017 | VIG-016, VIG-036, VIG-047, VIG-053, VIG-059, VIG-060, VIG-061, VIG-062, VIG-063 | notRun |
| EV04 | QA39 | VIG-062 | VIG-016, VIG-059, VIG-060, VIG-061, VIG-063 | notRun |
| EV05 | QA39 | VIG-062 | VIG-016, VIG-059, VIG-060, VIG-061, VIG-063 | notRun |
| EV06 | QA39 | VIG-062 | VIG-016, VIG-059, VIG-060, VIG-061, VIG-063 | notRun |
| EV07 | QA39 | VIG-062 | VIG-016, VIG-059, VIG-060, VIG-061, VIG-063 | notRun |
| EV08 | QA39 | VIG-062 | VIG-016, VIG-059, VIG-060, VIG-061, VIG-063 | notRun |
| EV09 | QA14, QA39 | VIG-062 | VIG-016, VIG-018, VIG-019, VIG-037, VIG-047, VIG-052, VIG-053, VIG-059, VIG-060, VIG-061, VIG-063 | notRun |
| EV10 | QA39 | VIG-062 | VIG-016, VIG-059, VIG-060, VIG-061, VIG-063 | notRun |
| EV11 | QA35, QA39 | VIG-055 | VIG-002, VIG-016, VIG-050, VIG-057, VIG-059, VIG-060, VIG-061, VIG-062, VIG-063 | notRun |
| EV12 | QA13, QA39 | VIG-020 | VIG-016, VIG-021, VIG-037, VIG-047, VIG-052, VIG-053, VIG-059, VIG-060, VIG-061, VIG-062, VIG-063 | notRun |
| EV13 | QA39 | VIG-061 | VIG-016, VIG-059, VIG-060, VIG-062, VIG-063 | notRun |
| AI01 | QA12 | VIG-015 | VIG-018, VIG-021, VIG-037, VIG-047, VIG-052, VIG-053, VIG-055, VIG-062 | notRun |
| AI02 | QA12 | VIG-015 | VIG-018, VIG-021, VIG-037, VIG-047, VIG-052, VIG-053, VIG-055, VIG-062 | notRun |
| AI03 | QA12 | VIG-018 | VIG-021, VIG-037, VIG-047, VIG-052, VIG-053, VIG-055, VIG-062 | notRun |
| AI04 | QA12 | VIG-018 | VIG-021, VIG-037, VIG-047, VIG-052, VIG-053, VIG-055, VIG-062 | notRun |
| AI05 | QA12 | VIG-018 | VIG-021, VIG-037, VIG-047, VIG-052, VIG-053, VIG-055, VIG-062 | notRun |
| AI06 | QA12, QA14, QA15 | VIG-018 | VIG-016, VIG-019, VIG-020, VIG-021, VIG-037, VIG-047, VIG-052, VIG-053, VIG-055, VIG-062 | notRun |
| AI07 | QA12 | VIG-018 | VIG-021, VIG-037, VIG-047, VIG-052, VIG-053, VIG-055, VIG-062 | notRun |
| AI08 | QA14 | VIG-018 | VIG-016, VIG-019, VIG-037, VIG-047, VIG-052, VIG-053, VIG-062 | notRun |
| AI09 | QA14 | VIG-018 | VIG-016, VIG-019, VIG-037, VIG-047, VIG-052, VIG-053, VIG-062 | notRun |
| AI10 | QA15 | VIG-018 | VIG-020, VIG-037, VIG-047, VIG-052, VIG-053, VIG-062 | notRun |
| AI11 | QA06 | VIG-017 | VIG-036, VIG-047, VIG-053, VIG-062 | notRun |
| AI12 | QA12, QA39 | VIG-016 | VIG-018, VIG-021, VIG-037, VIG-047, VIG-052, VIG-053, VIG-055, VIG-059, VIG-060, VIG-061, VIG-062, VIG-063 | notRun |
| AI13 | QA06 | VIG-017 | VIG-036, VIG-047, VIG-053, VIG-062 | notRun |
| AI14 | QA03, QA14 | VIG-016 | VIG-011, VIG-015, VIG-018, VIG-019, VIG-036, VIG-037, VIG-047, VIG-052, VIG-053, VIG-062 | notRun |
| AI15 | QA11 | VIG-019 | VIG-021, VIG-037, VIG-047, VIG-052, VIG-053, VIG-055, VIG-062 | notRun |
| AI16 | QA11 | VIG-019 | VIG-021, VIG-037, VIG-047, VIG-052, VIG-053, VIG-055, VIG-062 | notRun |
| AI17 | QA11 | VIG-019 | VIG-021, VIG-037, VIG-047, VIG-052, VIG-053, VIG-055, VIG-062 | notRun |
| AI18 | QA13 | VIG-020 | VIG-021, VIG-037, VIG-047, VIG-052, VIG-053 | notRun |
| AI19 | QA13 | VIG-020 | VIG-021, VIG-037, VIG-047, VIG-052, VIG-053 | notRun |
| AI20 | QA13 | VIG-020 | VIG-021, VIG-037, VIG-047, VIG-052, VIG-053 | notRun |
| AI21 | QA13, QA15 | VIG-020 | VIG-018, VIG-021, VIG-037, VIG-047, VIG-052, VIG-053, VIG-062 | notRun |
| AI22 | QA16 | VIG-026 | VIG-037, VIG-047, VIG-053, VIG-056 | notRun |
| AI23 | QA16, QA17, QA18 | VIG-026 | VIG-010, VIG-021, VIG-022, VIG-027, VIG-037, VIG-047, VIG-053, VIG-056, VIG-057 | notRun |
| AI24 | QA11, QA12 | VIG-018 | VIG-019, VIG-021, VIG-037, VIG-047, VIG-052, VIG-053, VIG-055, VIG-062 | notRun |
| AI25 | QA24 | VIG-041 | VIG-023, VIG-047, VIG-052, VIG-053 | notRun |
| AI26 | QA03, QA39 | VIG-016 | VIG-011, VIG-015, VIG-036, VIG-047, VIG-053, VIG-059, VIG-060, VIG-061, VIG-062, VIG-063 | notRun |
| AI27 | QA11, QA12 | VIG-018 | VIG-019, VIG-021, VIG-037, VIG-047, VIG-052, VIG-053, VIG-055, VIG-062 | notRun |
| AI28 | QA13, QA31 | VIG-024 | VIG-012, VIG-020, VIG-021, VIG-025, VIG-027, VIG-028, VIG-029, VIG-031, VIG-037, VIG-047, VIG-052, VIG-053 | notRun |
| DT01 | QA31 | VIG-023 | VIG-012, VIG-024, VIG-025, VIG-027, VIG-028, VIG-029, VIG-031, VIG-047, VIG-052, VIG-053 | notRun |
| DT02 | QA27 | VIG-029 | VIG-038, VIG-043, VIG-045, VIG-047, VIG-052, VIG-053, VIG-054 | notRun |
| DT03 | QA07, QA29 | VIG-023 | VIG-017, VIG-022, VIG-033, VIG-036, VIG-043, VIG-047, VIG-052, VIG-053, VIG-063 | notRun |
| DT04 | QA21, QA31 | VIG-023 | VIG-012, VIG-024, VIG-025, VIG-027, VIG-028, VIG-029, VIG-031, VIG-039, VIG-045, VIG-047, VIG-052, VIG-053 | notRun |
| DT05 | QA24 | VIG-041 | VIG-023, VIG-047, VIG-052, VIG-053 | notRun |
| DT06 | QA08 | VIG-026 | VIG-009, VIG-022, VIG-024, VIG-037, VIG-047, VIG-052, VIG-053 | notRun |
| DT07 | QA31 | VIG-024 | VIG-012, VIG-025, VIG-027, VIG-028, VIG-029, VIG-031, VIG-047, VIG-052, VIG-053 | notRun |
| DT08 | QA31 | VIG-024 | VIG-012, VIG-025, VIG-027, VIG-028, VIG-029, VIG-031, VIG-047, VIG-052, VIG-053 | notRun |
| DT09 | QA19, QA31 | VIG-024 | VIG-012, VIG-025, VIG-027, VIG-028, VIG-029, VIG-031, VIG-035, VIG-037, VIG-047, VIG-052, VIG-053, VIG-056 | notRun |
| DT10 | QA21, QA25 | VIG-023 | VIG-027, VIG-028, VIG-030, VIG-039, VIG-042, VIG-045, VIG-047, VIG-052, VIG-053 | notRun |
| DT11 | QA28 | VIG-030 | VIG-038, VIG-043, VIG-047, VIG-052, VIG-053 | notRun |
| DT12 | QA27 | VIG-029 | VIG-038, VIG-043, VIG-045, VIG-047, VIG-052, VIG-053, VIG-054 | notRun |
| DT13 | QA27 | VIG-029 | VIG-038, VIG-043, VIG-045, VIG-047, VIG-052, VIG-053, VIG-054 | notRun |
| DT14 | QA26 | VIG-045 | VIG-007, VIG-038, VIG-046, VIG-047, VIG-052, VIG-053, VIG-054 | notRun |
| DT15 | QA26 | VIG-045 | VIG-007, VIG-038, VIG-046, VIG-047, VIG-052, VIG-053, VIG-054 | notRun |
| DT16 | QA26 | VIG-046 | VIG-007, VIG-038, VIG-045, VIG-047, VIG-052, VIG-053, VIG-054 | notRun |
| DT17 | QA26, QA27 | VIG-045 | VIG-007, VIG-029, VIG-038, VIG-043, VIG-046, VIG-047, VIG-052, VIG-053, VIG-054 | notRun |
| DT18 | QA37 | VIG-054 | VIG-004, VIG-024, VIG-029, VIG-045 | notRun |
| DT19 | QA32 | VIG-004 | VIG-008, VIG-047, VIG-053, VIG-058 | notRun |
| DT20 | QA31 | VIG-027 | VIG-012, VIG-024, VIG-025, VIG-028, VIG-029, VIG-031, VIG-047, VIG-052, VIG-053 | notRun |
| DT21 | QA06, QA37 | VIG-017 | VIG-004, VIG-024, VIG-029, VIG-036, VIG-045, VIG-047, VIG-053, VIG-054, VIG-062 | notRun |
| DT22 | QA27, QA37 | VIG-054 | VIG-004, VIG-024, VIG-029, VIG-038, VIG-043, VIG-045, VIG-047, VIG-052, VIG-053 | notRun |
| DT23 | QA31, QA37 | VIG-031 | VIG-004, VIG-012, VIG-024, VIG-025, VIG-027, VIG-028, VIG-029, VIG-045, VIG-047, VIG-052, VIG-053, VIG-054 | notRun |
| DT24 | QA26, QA37 | VIG-045 | VIG-004, VIG-007, VIG-024, VIG-029, VIG-038, VIG-046, VIG-047, VIG-052, VIG-053, VIG-054 | notRun |

## 16. Checklist RL → tareas de distribución

| ID | Tareas | Estado inicial |
|---|---|---|
| RL01 | VIG-002, VIG-003, VIG-064, VIG-069 | pending |
| RL02 | VIG-058, VIG-069, VIG-071 | pending |
| RL03 | VIG-011, VIG-032, VIG-049, VIG-068 | pending |
| RL04 | VIG-004, VIG-021, VIG-054, VIG-058, VIG-069 | pending |
| RL05 | VIG-051–VIG-058, VIG-063, VIG-066 | pending |
| RL06 | VIG-054, VIG-068, VIG-071 | pending |
| RL07 | VIG-065, VIG-068, VIG-071 | pending |
| RL08 | VIG-069, VIG-071 | pending |
| RL09 | VIG-067, VIG-071 | blocked |
| RL10 | VIG-070, VIG-072 | pending |
| RL11 | VIG-058, VIG-065, VIG-069, VIG-071 | pending |
| RL12 | VIG-065, VIG-066, VIG-071 | pending; publicación no autorizada en esta entrega |

## 17. Siguiente ejecución concreta

El Área 08 queda preparada documentalmente. El siguiente paso de implementación es **H00: VIG-001 → VIG-002 → VIG-003**, completando variantes/instrucciones/harness antes del pipeline H01. Cuando se indique empezar a desarrollar se crearán el repo y estos archivos con las versiones verificadas; no se inicia por copiar 18 pantallas desconectadas.

Para preparar esa ejecución todavía falta confirmar el entorno de desarrollo y teléfono disponible, recibir el HTML B5.2 completo cuando toque inventariarlo y fijar packageId/toolchain compatibles. Esas entradas no impiden cerrar esta planificación y tampoco exigen volver hoy a Claude Design. El roadmap comercial permanece preparado como trabajo futuro, condicionado a evidencia y autorización de publicación.
