# Vigía · Contradicciones y pendientes abiertos de la especificación

**Tarea:** VIG-001 · Consolidar la especificación vigente
**Rama:** `task/VIG-001-specification` · **Fecha de registro:** 2026-10-05
**Fuentes:** `docs/source/` registradas con hash en [`docs/spec-index.json`](../spec-index.json).

Este registro **no modifica ninguna fuente** ni resuelve en silencio un requisito. Cada entrada cita los textos en conflicto, la regla de precedencia aplicable y la tarea que debe cerrarla. Las líneas se refieren a las versiones con hash registradas en `spec-index.json`.

Regla de precedencia (Área 08 §2, línea 28): «PRD/UX definen el comportamiento; arquitectura/IA/datos definen cómo mantener sus garantías; QA define cómo demostrarlo; el diseño define presentación». Una contradicción se registra con ambas citas y se resuelve mediante un ADR y una nueva versión del documento afectado **antes** de implementar el comportamiento en disputa.

| ID | Hallazgo | Estado | Tarea que lo resuelve |
|---|---|---|---|
| OI-01 | El nombre real del PRD no coincide con el nombre citado | Registrado; sin renombrar | VIG-001 (registro); responsable del proyecto (nombre definitivo) |
| OI-02 | HTML B5.2 recibido, aunque las Áreas 04/07/08 lo daban por faltante | Abierto | VIG-032 |
| OI-03 | El HTML usa Inter, pero su tabla de activos y PD-05 citan Public Sans | Abierto | VIG-032, VIG-033 |
| OI-04 | En el HTML, la etiqueta de la barra inferior deja de escalar al 135 %; PRD/UX exigen 200 % | Abierto | VIG-033, VIG-034, VIG-048 |
| OI-05 | El PRD marca los parámetros de IA como pendientes; el Área 05 propone valores experimentales | Registrado; sigue experimental | VIG-016, VIG-017, VIG-063 |
| OI-06 | Ruta de evidencia: `qa/runs/` (Área 07) frente a `docs/evidence/` (Área 08) | Abierto | VIG-006 |
| OI-07 | Adapter SAF de exportación ausente en el Área 04; ADR08-01 solo propuesto | Abierto | VIG-007 |
| OI-08 | RF27.CA2 dice «Borrar todo **añade** referencias y alias»; UX/A04/A06 dicen que las retira | Abierto; requiere decisión | Responsable del proyecto + ADR antes de VIG-029/VIG-043 |

---

## OI-01 · Nombre real del PRD distinto del nombre citado

- **Fuentes:**
  - Archivo recibido: `docs/source/Vigia_01_PRD_Producto_y_Alcance_v1.1 (1).md` (versión declarada 1.1, línea 2).
  - Citado como `Vigia_01_PRD_Producto_y_Alcance_v1.1.md` en: Brief Área 03 §1 (línea 8), Instrucciones Área 03 §1 (línea 10), Área 04 §1 (línea 16) y Área 08 §2 (línea 19).
- **Efecto:** cualquier referencia automática por nombre citado no encuentra el archivo. El contenido es la versión 1.1 declarada, de modo que no afecta al comportamiento.
- **Precedencia:** Área 08 §2 (línea 30): VIG-001 copia las fuentes «conservando nombres/versiones» y «no reemplaza silenciosamente el original».
- **Acción en VIG-001:** `spec-index.json` registra `fileName` (nombre real) y `citedAs` (nombre citado) para `A01-PRD`. No se renombra el archivo.
- **Pendiente:** el responsable del proyecto decide si en una entrega futura sustituye el archivo por uno con el nombre citado. Si lo hace, el cambio de nombre se registra con un nuevo hash, aunque el contenido no cambie.

## OI-02 · HTML B5.2 recibido; las fuentes lo daban por faltante

- **Fuentes que lo dan por faltante o no revisado:** Área 04 §1 (líneas 19 y 23), Área 07 §1 (línea 15) y §16 (línea 451), Área 08 §2 (líneas 21 y 32), §12 (línea 1118) y §17 (línea 1513).
- **Hecho comprobado:** `docs/source/Vigia B5.2 Completo (standalone).html` está presente (606 811 bytes; SHA-256 en `spec-index.json`). Es una página empaquetada cuyo contenido declara «Vigía · B5.2 completo · Monocromo y aura (B4.2) · P01–P18 y D01–D08» y «v1 · 2 oct 2026». En el código se observan 120 identificadores de vista con sufijo `__v1`, Inter incrustada (7 archivos woff2) y React 18.3.1 empaquetado.
- **Lo que la recepción NO acredita:**
  - pruebas Android, TalkBack, escala real de texto al 200 %, contraste medido en pantalla, audio, cámara ni rendimiento;
  - la implementación de la interfaz Flutter;
  - las afirmaciones internas del HTML («0 problemas en 1440 combinaciones», contraste calculado desde hex, etc.), que son evidencia de diseño declarada por la herramienta y no resultados independientes (Área 07 §1, línea 15; Área 08 §2, línea 32).
- **Efecto:** VIG-032 puede iniciar el inventario sobre un archivo con hash fijo. QA33, QA34 y G05 siguen pendientes.
- **Precedencia:** Área 08 §2: el diseño es referencia visual y no modifica estados ni criterios funcionales. ADR04-08: interfaz Flutter nativa; diseño HTML como referencia.
- **Tarea:** VIG-032 (inventario de vistas, tokens, recursos y motion, contrastado con RF/UX). Hasta entonces, la mención «HTML completo por recibir» del Área 08 queda superada solo en cuanto a la **recepción**.

## OI-03 · Fuente tipográfica: Inter usada frente a Public Sans declarada en el HTML

- **Fuentes, todas dentro del HTML B5.2 (contenido del bundle):**
  - Las reglas `@font-face` declaran `font-family: 'Inter'` y el tema aplica `'Inter',system-ui,sans-serif`.
  - La pestaña «Activos con fuente y licencia» lista «Public Sans · Google Fonts · SIL OFL 1.1 declarada; archivo de licencia sin verificar · Pendiente PD-05».
  - La tabla de pendientes contiene «PD-05 · Archivo de licencia y alojamiento de Public Sans».
  - Otra tabla del mismo HTML registra «Licencia y archivo de Inter; autoría de los iconos · Pendiente de verificación documental».
- **Fuentes del proyecto:** Área 08 VIG-033 (línea 553): «Inter y licencia locales; cero Google Fonts remoto». Área 07 RL03 (línea 430): «Modelo/Inter/iconos/sonidos/SDKs con procedencia/licencia».
- **Efecto:** el inventario de licencias del propio HTML no corresponde a la fuente que usa. Ninguna licencia tipográfica está verificada.
- **Precedencia:** Área 08 §2: el diseño define presentación; la fuente usada en B5.2 y citada por VIG-033/RL03 es Inter. La mención a Public Sans se trata como residuo de una versión anterior del inventario, **pendiente de confirmar** en VIG-032.
- **Tareas:** VIG-032 (confirmar la fuente y corregir el inventario en `docs/design-system.md`/`docs/licenses.md`), VIG-033 (alojar Inter y su licencia en `assets/fonts/`), VIG-049 (QA34 sin peticiones externas) y RL03.

## OI-04 · Barra de navegación limitada al 135 % frente al requisito de 200 %

- **Fuente de diseño:** HTML B5.2, pestaña de revisión: «Etiquetas de la barra inferior no cabían en 320 / 200 %» → «La etiqueta de la barra escala hasta 135 %; el resto del texto escala completo. Decisión de diseño propuesta, por validar en Android».
- **Fuentes de comportamiento:**
  - PRD RNF03.CA1 (línea 468): «Con escala de texto 100 % y 200 %, ninguna etiqueta o acción esencial queda cortada, superpuesta o inaccesible…».
  - UX22.CA1 (línea 676): «Texto al 100/200 % en ambos temas conserva acciones esenciales…».
- **Ya señalado en:** Área 04 §1 (línea 23), Área 07 §16 («Nav al 200 %… sin límite 135 %»), Área 08 §2 (línea 32), VIG-033 (línea 553) y VIG-048 (línea 707: «No capar etiquetas a 135 %»).
- **Efecto:** la propuesta de diseño no puede implementarse tal cual. La navegación Flutter debe resolver el 200 % sin recorte, por ejemplo con otra disposición, a definir en implementación.
- **Precedencia:** PRD y UX prevalecen sobre el diseño (Área 08 §2). Un fallo de texto esencial recortado al 200 % es S2 (Área 07 §3).
- **Tareas:** VIG-033 (tokens y escala), VIG-034 (componente de navegación) y VIG-048 (QA33 en Android).

## OI-05 · Parámetros de IA: pendientes en el PRD, experimentales en el Área 05 (Kcal)

- **Fuentes:**
  - PRD §6.1 (líneas 80–95): Q, Kcal, W, C, Tclose, Eend, Rrepeat, Tstale y Krecover son pendientes; «Codex y Claude Code no deben rellenarlos por su cuenta».
  - PRD RF06.CA3 (línea 145): «Kcal está pendiente: RF06 no se cierra hasta fijarlo».
  - Área 05 §7 (líneas 121–157): valores candidatos con `profileId=lab-eye-rules-0.1` y `qualificationStatus=experimental`, por ejemplo Kcal `openDurationMs/minOpenSamples` 8000/60, `minCoverage/maxRelativeMAD` 0,80/0,15 y dos cierres de prueba de 1000 ms con reapertura de 2000 ms. El mismo apartado (línea 123) indica que son «candidatos propuestos para verificar y comparar», que «solo los usarán en una configuración de laboratorio identificada y fixtures» y que no se copiarán «como una política aceptada de producción».
  - Área 08 §2 (línea 32) y VIG-001 (línea 225): «Registrar que Kcal experimental del Área 05 concreta el pendiente del PRD sin convertirlo en calificación física».
- **Registro:** **Kcal, como el resto de parámetros del Área 05 §7, es una configuración experimental de laboratorio (`lab-eye-rules-0.1`).** No es política de producción, no cierra RF06 ni los demás RF dependientes y no permite afirmar detección validada. RF06.CA1–CA3 siguen `notRun` en `traceability.json`.
- **Efecto:** VIG-017 puede implementar Kcal en `labReal` con fixtures identificados. La calificación física requiere EV01–EV13 y G08.
- **Precedencia:** el PRD define que el requisito no se cierra sin el parámetro. El Área 05 concreta un candidato experimental. Ninguna tarea puede presentar estos valores como aceptados.
- **Tareas:** VIG-016 (Q y EyeVisibilityGate), VIG-017 (Kcal), VIG-062 (EV) y VIG-063 (congelación y calificación; G08).

## OI-06 · Ruta de evidencia de ejecuciones

- **Fuentes:** Área 07 §6 (línea 96): «Ruta propuesta futura: qa/runs/<runId>/». Área 08 §4 (línea 69): `docs/evidence/ / release/ / operations/`, y fichas con paths `docs/evidence/H01/`, `docs/evidence/QA33/`, etc.
- **Efecto:** sin decisión, cada herramienta puede guardar run-manifest y resultados en sitios distintos, lo que rompe la trazabilidad QA→runs (Área 08 §11).
- **Precedencia:** el Área 08 fija la estructura del repositorio y la propiedad de cambios. El Área 07 llama a su ruta «propuesta futura». No hay contradicción de comportamiento, solo de organización.
- **Tarea:** VIG-006 (esquema run-manifest y comandos de validación) debe fijar una única ruta mediante ADR y actualizar `docs/testing.md`. VIG-001 no la elige.

## OI-07 · Adapter de exportación SAF sin contrato en el Área 04

- **Fuentes:**
  - Área 04 §2 (tabla de stack, líneas 29–43) y §17 (líneas 417–445): no incluyen una API de selector/escritura de documentos ni rutas `lib/core/export/` o `export/` del plugin.
  - Área 08 §4 (líneas 74 y 83) las añade, y §6.3 (líneas 173–189) propone **ADR08-01**: `DocumentExportHostApi` independiente en `pigeons/document_export_api.dart`, «un ADR de implementación por revisar en VIG-007, no una API ya construida».
- **Efecto:** RF26/QA26 dependen de un contrato aún no aprobado.
- **Precedencia:** el Área 04 manda sobre contratos y autoridad. El Área 08 propone cerrar el hueco sin ampliar la autoridad del motor. Hasta que se apruebe en VIG-007, ADR08-01 es solo una propuesta.
- **Tareas:** VIG-007 (aprobar o ajustar ADR08-01, actualizar arquitectura y QA26) y VIG-046 (implementación).

## OI-08 · RF27.CA2: «Borrar todo añade referencias y alias»

- **Texto literal del PRD (RF27.CA2, línea 312), conservado sin cambios en `traceability.json`:**
  > Tras reinicio y reintento de consolidación, el ID eliminado no reaparece. Borrar todo añade referencias y alias y vuelve a estado de primera preparación; las preferencias de tema pueden conservarse.
- **Textos en conflicto:**
  - UX D07 (línea 138): «Incluye historial, eventos, referencias y alias; copias externas permanecen».
  - UX FL13 (línea 477): «Borrar todo retira referencias y alias».
  - Área 04 §13 (línea 359): «…borrar referencias y…».
  - Área 06 §12 (línea 564): «Borrar todo: borrar todas las sesiones y referencias, alias, …».
  - Área 08 VIG-029 (línea 511): «borrar todo elimina alias/cal».
- **Efecto:** leído literalmente, RF27.CA2 pide añadir referencias y alias al borrar todo, lo contrario de D07/FL13/A04/A06. La interpretación «retirar» es la coherente con el resto, pero **no se corrige en silencio**.
- **Precedencia:** PRD y UX definen ambos el comportamiento, sin regla automática de «gana el más reciente» (Área 08 §2). Hace falta un ADR con ambas citas y una nueva versión del documento afectado (previsiblemente PRD v1.2) antes de implementar Borrar todo.
- **Tarea:** decisión del responsable del proyecto, registrada como ADR antes de VIG-029 (borrado y reset de dataset) y VIG-043 (D07). Mientras tanto, RF27.CA2 sigue `notRun` con su texto literal.

---

## Fuentes citadas que no se recibieron

Registradas en `spec-index.json → missingSources`, sin hash, tamaño, versión ni contenido inventados:

| ID lógico | Fuente | Citada por | Efecto |
|---|---|---|---|
| BASE-v0.2 | `Vigia_Base_Proyecto_v0.2.md` | PRD línea 5; Área 04 §1 línea 18 | Bajo: Área 04 §1 indica que el PRD y la UX vigentes la sustituyen. Se pierde trazabilidad histórica. |
| B5.2-SUMMARY | Resumen de Claude del B5.2 completo | Área 04 §1; Área 07 §1; Área 08 §2 | Ninguno sobre el comportamiento: las fuentes ya lo declaran no independiente. |
| B4.2-B5.2-BRIEF | «Brief B4.2/B5.2» como documento separado | Área 08 §2 y VIG-033 | Los tokens oscuros que cita VIG-033 aparecen dentro del HTML B5.2. Se confirmará en VIG-032 si es el mismo entregable. |

## Fuera del alcance de VIG-001

- No se instalaron SDKs ni se creó la app Flutter.
- No se ejecutó ningún ensayo QA/AT/AI/EV/DT/UT. Todos conservan `notRun` o `planned`.
- No se aprobó ningún gate (G01–G10) ni ninguna RL. RL09 sigue `blocked`.
- Este registro no constituye una revisión aprobada por Codex.
