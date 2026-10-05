# Vigía — Instrucciones de trabajo para Claude Design
Versión 1.0 · 1 de octubre de 2026  
Autor del proyecto: Juan José Rueda Viveros  
Uso: instrucciones para copiar en Claude Design. No ejecutan un envío ni crean por sí mismas un diseño.

## 1. Preparar el contexto

Adjuntar en el mismo proyecto/conversación:

1. Vigia_01_PRD_Producto_y_Alcance_v1.1.md.
2. Vigia_02_UX_Flujos_y_Navegacion_v1.0.md.
3. Vigia_03_Brief_Diseno_Claude_Design_v1.0.md.
4. Este documento.

Si un archivo no puede leerse, pegar su contenido íntegro; no sustituirlo por una descripción general. No adjuntar referencias de marca ajenas como si fueran el sistema de Vigía. Las referencias visuales futuras se etiquetan como inspiración y no cambian funciones.

El primer mensaje será únicamente el prompt B1 de sección 2. B2–B5 son instrucciones posteriores, no deben ejecutarse junto con B1. Conservar el contexto y registrar versión de cada entrega.

El PRD define comportamiento y alcance; el Área 02 define interacción; el brief define el encargo. Si se encuentra una contradicción, citar las dos reglas y sus IDs, proponer una solución y continuar solo la parte que no depende de esa decisión. No abrir una consulta por cada detalle de composición.

## 2. Prompt inicial — B1: wireframes del recorrido principal

Copiar íntegro el siguiente texto:

```text
Actúa como diseñador de producto móvil para Vigía. Lee los cuatro documentos adjuntos antes de diseñar. Estamos estructurando la app antes de programarla. Tu tarea actual es B1: wireframes y prototipo del recorrido principal. No ejecutes todavía B2, la exploración visual ni el design system definitivo.

Vigía será una app Android, con Flutter/Dart para interfaz y motor Kotlin de cámara e IA local. El usuario prepara el teléfono con el vehículo detenido, recibe avisos y revisa datos después. iOS es una evolución futura. Diseña para uso personal sin cuenta obligatoria; no añadas funciones fuera del PRD.

Entrega B1 con estas seis pantallas:
- P02 Permiso de cámara, como apoyo del recorrido.
- P03 Inicio.
- P04 Preparación.
- P05 Calibración.
- P06 Monitoreo y pausa en la misma pantalla.
- P07 Resumen.
Incluye D01 Salir de preparación, D02 Finalizar y D05 Volver al inicio desde monitoreo. No crees todavía las otras doce pantallas ni los otros cinco diálogos como si estuvieran terminados.

Diseña en escala de grises, con tipografía provisional del sistema. Usa un viewport principal de contenido de 360×800 unidades lógicas y revisa anchos 320 y 412. Anota zonas del sistema por separado. Acciones táctiles de al menos 48×48 y controles de P06 de al menos 56 de alto. Comprueba texto al 100 % y 200 %; permite scroll accesible si hace falta, sin recortar acciones esenciales.

Implementa todas las variantes de la sección 6 del brief. No basta mostrar cinco pantallas en estado exitoso. Los estados pueden abrirse como vistas o mediante controles de revisión externos al teléfono representado; esos controles no pertenecen a la UI de producción.

Conecta Inicio → Preparación → Calibración → Preparación → Monitoreo → Resumen. Iniciar no navega a Activa antes de confirmación simulada del motor. Pausar/Reanudar/Finalizar tienen solicitud, confirmación y rechazo separados. Tras 5 s sin resolución muestra Confirmación pendiente; consultar estado no crea otra sesión ni otra orden.

En Preparación verifica por separado permiso, cámara, modelo, ojos evaluables, referencia aplicable y sonido confirmado. Cada condición falsa tiene causa visible e impide iniciar. Rostro detectado no significa ojos medibles. Lo escuché solo se habilita después de reproducción técnica exitosa; No lo escuché mantiene el bloqueo. Cada nueva sesión necesita prueba audible.

Separa sesión, calidad y señal. Activa con medición no disponible muestra No evaluable. Pausada muestra Evaluación suspendida. Cierre ocular prolongado muestra Detente en un lugar seguro, sin exigir bostezo, respuesta ni botón Entendido. No uses Seguro, Puedes conducir ni porcentajes de fatiga.

No inventes Q, Kcal, W, C, Tclose, Eend, Rrepeat, Tstale o Krecover. Calibración no muestra porcentaje o duración hasta contar con una regla real para calcularlos. Un resultado simulado puede activar una variante de interfaz, pero no demuestra detección válida.

Usa DS00, DS01, DS02 y DS07 del Área 02. DS01 conserva 600 s evaluables, 120 no evaluables, 180 pausados, 60 desconocidos acotados, 83,3 % de cobertura, 960 s representados y dos episodios. Repeticiones del sonido no elevan episodios. DS02 conserva final desconocido; en B1 representa la recuperación en P03, sin crear P09 ni cambiar su destino. DS07 conserva incertidumbre de pausa hasta respuesta.

P04–P06 no tienen barra principal. Volver desde P06 abre D05 y conserva sesión/ID. P03 conserva el acceso al mismo monitoreo. Mientras exista sesión vigente, incluida pausa, aplica los bloqueos del Área 02. Historial y Ajustes siguen como destinos futuros del tablero, sin simular una implementación completa de B2.

Un cierre confirmado permite P07 aunque la consolidación siga pendiente. P07 distingue completo, pendiente, incompleto y extremo temporal desconocido. No presentar guardado exitoso por pulsación. Volver al inicio después de cerrar no reabre P06 de esa sesión.

Marca el prototipo como DEMO — datos simulados, visible en las vistas de monitoreo/registros y en la documentación. No solicites cámara real, no grabes rostros ni conectes servicios de IA. Las respuestas de motor del prototipo son simuladas y separadas de las acciones del usuario.

Entrega:
1. Tablero de las seis pantallas y los tres diálogos, con estados accesibles.
2. Prototipo navegable del recorrido central y sus cancelaciones/fallos.
3. Tabla de acciones: pantalla/estado, control, condición, disparador, resultado, destino y error/cancelación.
4. Matriz de cobertura: ID de vista, variante, RFxx.CAx/UXxx.CAx, evidencia de diseño y pendiente nativo.
5. Revisión a 320/360/412 de ancho y texto 100/200 %, con problemas y correcciones por pantalla.
6. Lista de destinos pendientes de B2 y decisiones que requieren cierre fuera de diseño.

Nombra cada vista con pantalla y estado, por ejemplo P04__ojos_no_evaluables__v1 y P06__confirmacion_pausa_pendiente__v1. Mantén los IDs del Área 02. Describe las propuestas nuevas con motivo y efecto; no reescribas las reglas fuente para acomodar el diseño.

Construye B1 ahora y entrega el resultado concreto. Si la herramienta no permite un artefacto interactivo, dilo y entrega wireframes con tabla completa de transiciones; no lo llames prototipo navegable. No marques criterios RF/RNF como probados con IA, persistencia o hardware. Termina después de B1, sin avanzar automáticamente a B2–B5.
```

## 3. Cómo revisar B1

Comprobar los doce criterios BD.CA01–BD.CA12 del brief según su bloque aplicable. BD.CA10 corresponde a B4 y BD.CA11 a B5; no exigirlos como implementación terminada en B1. Todas las variantes de sección 6 sí deben estar representadas en B1.

Ejecutar estos recorridos en el prototipo o verificarlos contra una tabla si no existe interacción:

| Revisión | Acción | Resultado esperado |
|---|---|---|
| REV01 | Negar permiso | Preparación no inicia; explicación y recuperación visibles |
| REV02 | Rostro visible y ojos inválidos | Rostro detectado + No puedo evaluar los ojos; inicio bloqueado |
| REV03 | Probar sonido y elegir No lo escuché | Sigue bloqueado; puede repetir prueba |
| REV04 | Cancelar calibración después de invalidar referencia | Vuelve P04 sin sesión ni referencia reaplicada |
| REV05 | Solicitar inicio y retrasar confirmación | Iniciando/Confirmación pendiente; no Activa por pulsación |
| REV06 | Perder calidad durante cierre ocular | No evaluable; no suma cierres separados ni mantiene normalidad |
| REV07 | Reanudar con rechazo | Pausada, misma sesión, causa visible |
| REV08 | Volver P06→P03→P06 | D05; mismo ID; no nuevo inicio |
| REV09 | Cerrar con consolidación pendiente | P07 pendiente; no éxito definitivo de guardado |
| REV10 | Abrir DS02 | Final desconocido; no captura automática ni duración hasta reapertura |
| REV11 | Revisar DS01 | 83,3 %, 960 s y dos episodios; pausas/desconocidos visibles |
| REV12 | Aumentar texto al 200 % y estrechar a 320 | Etiquetas/acciones esenciales accesibles sin solapamiento |

Cambiar estado desde un selector externo es una representación de diseño, no evidencia de ejecución nativa. Una navegación simulada no aprueba RF09/RNF04/RNF07.

### Prompt para corregir una entrega

```text
Revisa la versión [versión] de B1. Corrige estos incumplimientos:
[ID REV/BD/UX, vista, condición, resultado observado y resultado esperado].
Limita los cambios a esas vistas y componentes afectados. Conserva el resto de reglas del PRD/Área 02. Entrega versión nueva, tabla de cambios, rutas afectadas y evidencia por criterio. No amplíes el alcance ni cambies una dependencia de IA para ocultar un fallo de diseño.
```

## 4. Prompt posterior — B2: completar wireframes

Enviar cuando se haya revisado B1 y corregido sus incumplimientos:

```text
Continúa con B2 de Vigía usando la versión revisada [versión B1], el PRD, el Área 02 y el brief. Mantén los seis IDs existentes y añade P01, P08, P09, P10, P11, P12, P13, P14, P15, P16, P17 y P18. Añade D03, D04, D06, D07 y D08.

Conecta incorporación, historial/detalle/valoración, tendencias, preferencias, ayuda, exportación, borrado y retención conforme FL01 y FL08–FL15. Conserva carga/vacío/error/operación pendiente/resultados distintos. Diseña bloqueos durante sesión vigente, incluidos accesos directos, sin inventar permisos de conducción.

Usa DS00–DS08. CSV tiene dos archivos y éxito parcial; borrado fallido permanece pendiente; reducir retención presenta fecha y recuento antes de confirmar. Valoración solo en Finalizada; alias opcional hasta 40 caracteres. Tendencias separa políticas y denominadores; sin tiempo evaluable muestra No disponible. No hay cuentas, flotas, GPS, pagos o nube en V1.

Entrega inventario completo P01–P18 y D01–D08, flujos conectados FL01–FL15, tabla de acciones, pruebas de tamaño/texto y matriz de los 66 criterios UX con evidencia de diseño, no nativa. Ejecuta los escenarios de interfaz previstos por UT01–UT08 como revisión interna; no inventes participantes ni declare esas pruebas con usuarios ejecutadas. Sigue en escala de grises y termina en B2.
```

## 5. Prompt posterior — B3: dirección visual

```text
Con B1/B2 revisados, desarrolla B3: dos direcciones visuales de Vigía sobre P03, P04 y P06. Mantén exactamente la misma navegación, contenido, estados y controles; cambia únicamente decisiones visuales. Incluye en P06 normal, advertencia, cierre ocular y no evaluable, en claro y oscuro para ambas propuestas.

Presenta por cada dirección: fuentes propuestas, paleta con valores exactos, jerarquía, espaciado, iconos y ejemplos. Usa los objetivos del brief: contraste de texto mínimo 4,5:1, controles mínimo 48×48, legibilidad 100/200 %. Registra combinaciones primer plano/fondo y contraste obtenido. Si no puedes medir, marca Pendiente; no lo declares aprobado.

Evita radar facial decorativo, porcentajes de fatiga, semáforo Seguro, mapas/velocímetro y chat de IA. Registra fuentes/licencias conocidas y pendientes de los activos. Compara ambas propuestas por evidencia concreta y recomienda una con sus motivos. No mezcles partes silenciosamente ni apliques aún a todas las pantallas. Entrega B3 y registra la selección del responsable del proyecto antes de B4.
```

## 6. Prompt posterior — B4: design system

```text
Construye B4 para Vigía con la dirección seleccionada [dirección y versión]. Usa las necesidades de las 18 pantallas y ocho diálogos revisados. Entrega un sistema documentado para implementar en Flutter, independiente del código web del prototipo.

Documenta tokens de color por tema y rol semántico, tipografía, espaciado, radios, bordes, elevación si se usa, iconos y movimiento. Cada token tiene nombre estable, valor exacto, unidad, uso, tema y ejemplo. Declara equivalencias entre unidades del prototipo y unidades lógicas/escala de texto Flutter; no equipares px físicos con dp sin explicación.

Documenta componentes de botones, campos/validación, listas, selectores, tarjetas de sesión, indicadores de medición, avisos, preview de preparación, estados pendientes/vacíos/error, métricas, episodios y diálogos. Cada componente define anatomía, tamaños/padding, textos, iconos, estados aplicables, semántica accesible, acción y uso permitido. Componentes repetidos comparten reglas.

Incluye tablas de contraste por tema, áreas táctiles, texto 100/200 %, orden de foco/lectura, nombre de controles con icono, foco inicial y restauración de diálogos. No anuncies el cronómetro cada segundo ni repitas cada frame. Duración/repetición de avisos del motor sigue pendiente en Eend/Rrepeat; no inventes esos valores como animación de UI.

Si propones patrones sonoros, documenta categoría, recurso, duración, licencia y regla de uso. Usa las restricciones de RF04/RF29; no anules No molestar ni desactives alerta ocular. Diferencia el sonido de ejemplo del prototipo de la reproducción validada Android.

Entrega catalogo visual, tabla de tokens, especificación de componentes, ejemplos claro/oscuro y lista de decisiones/pendientes. Si exportas JSON usa nombres y valores exactos, sin placeholders presentados como definitivos. Si no puedes exportar archivos, proporciona tablas estructuradas para reconstrucción. No declares TalkBack o reproducción Android verificados en un prototipo web. Termina en B4.
```

## 7. Prompt posterior — B5: aplicar sistema y entregar a desarrollo

```text
Desarrolla B5 aplicando el design system [versión] a las 18 pantallas, ocho diálogos y variantes revisadas de Vigía. Mantén IDs y comportamiento. Entrega un prototipo conectado y un paquete de especificación para Codex y Claude Code, cuyo destino es Flutter/Dart con motor Kotlin.

Incluye inventario completo, mapa de navegación, matriz de acciones/estados, vínculo a los 66 criterios UX, tokens, componentes, textos, medidas, semántica, activos con fuente/licencia y lista de pendientes. Incluye vacío/error/carga/incertidumbre, datos incompletos y bloqueos durante sesión; no entregues solo pantallas exitosas. Identifica los datos simulados.

Comprueba 320/360/412 de ancho y texto 100/200 % en claro/oscuro. Registra resultados por vista. Toda excepción conserva mensaje, acción y recuperación. Una acción habilitada tiene destino/resultado/error; una pendiente tiene ID y motivo y no se declara disponible.

Ofrece archivos editables, exportaciones o tablas estructuradas según lo que permita realmente la herramienta. El código HTML/React del prototipo puede incluirse como referencia de interacción, pero no como app Flutter terminada. No cambies stack ni empieces cámara, motor IA, base de datos o integración real para cerrar el diseño.

Entrega versión final del diseño, lista de cambios, cobertura con evidencia, dependencias pendientes y guía para trasladar componentes a Flutter. Distingue revisión de diseño, pruebas con usuarios realmente ejecutadas y pruebas nativas todavía no ejecutadas. No declare el producto validado para conducir o comercializar por completar las pantallas.
```

## 8. Formato obligatorio de evidencias y entrega

### Vista

Nombre propuesto: Pxx__estado__vN. Los nombres son metadatos del tablero, no texto del producto. Conservar el ID de sesión cuando corresponda.

### Matriz de acción

| Vista/estado | Control | Precondición | Disparador | Resultado visible | Destino | Error/cancelación | Criterio |
|---|---|---|---|---|---|---|---|
| P04__sonido_sin_confirmar | Lo escuché | Reproducción técnica exitosa | Pulsación | Sonido confirmado; inicio depende de otras cinco condiciones | P04 | Si falta éxito técnico, deshabilitado | UX04.CA1, RF04.CA2 |
| P06__pausada | Reanudar | Estado conocido, sin otra orden | Pulsación | Reanudando; pausa sigue abierta hasta respuesta | P06 | Rechazo conserva Pausada y causa | UX10.CA2, RF17.CA2 |

### Matriz de cobertura

| Criterio | Vista/escenario | Evidencia | Estado de diseño | Dependencia nativa |
|---|---|---|---|---|
| UX03.CA2 | P04__ojos_no_evaluables | Enlace/captura y acción bloqueada | Representado / pendiente / incumple | Q e inferencia real aún no probados |
| UX18.CA2 | P15__csv_parcial + D08 | Archivo 1 confirmado, 2 cancelado | Representado / pendiente / incumple | Escritura real RF26 no probada |

No usar Aprobado en app para evidencia de diseño. Un criterio que mezcla interfaz y operación real conserva su pendiente nativo aunque la representación sea correcta.

### Paquete final esperado

- Inventario con ID, pantalla, variantes y versión.
- Tablero/prototipo o limitación explícita si no se puede generar.
- Tabla de acciones y cobertura.
- Tabla de tokens y componentes.
- Textos definitivos de interfaz y textos todavía propuestos.
- Activos reutilizables con procedencia/licencia.
- Medidas, comportamiento adaptativo y semántica para Flutter.
- Lista de cambios, decisiones propuestas y dependencias abiertas.

No entregar solo imágenes sin especificación. Si un formato no está disponible, documentar la limitación y proporcionar contenido reconstruible. No afirmar una exportación automática a Flutter ni una ejecución real por el aspecto del prototipo.
