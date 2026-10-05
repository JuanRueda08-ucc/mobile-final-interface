# Vigía — Brief de diseño para Claude Design
Área 03 y Área 04 · Versión 1.0 · 1 de octubre de 2026  
Autor del proyecto: Juan José Rueda Viveros  
Estado: encargo de diseño; no es un diseño aprobado ni una app implementada.

## 1. Documentos que acompañan el encargo

1. Vigia_01_PRD_Producto_y_Alcance_v1.1.md.
2. Vigia_02_UX_Flujos_y_Navegacion_v1.0.md.
3. Este brief.
4. Vigia_03_Instrucciones_Claude_Design_v1.0.md.

El PRD define alcance, datos y aceptación funcional. El Área 02 define navegación, pantallas y comportamiento visible. Este brief fija el encargo visual. Las instrucciones fijan orden y entregables. Una mejora estética no cambia una regla funcional. Si se detecta una contradicción, se registra con los IDs y textos afectados antes de proponer una resolución; no se altera la fuente silenciosamente.

## 2. Producto y usuario

Vigía es una aplicación Android para observar señales faciales relacionadas con somnolencia mediante la cámara frontal de un teléfono montado de forma estable. La IA se ejecutará localmente. El conductor prepara el teléfono antes de usarlo y consulta resultados después.

Usuario principal: conductor particular o profesional que utiliza su propio teléfono Android. La primera versión es personal, sin cuenta obligatoria. No identifica automáticamente a quién está frente a cámara. Un alias local es opcional.

El nombre Vigía es provisional. El diseño corresponde a un producto funcional completo desarrollado en una materia de Diseño de Interfaces. La calidad visual debe acompañar preparación, monitoreo, errores y gestión de datos reales.

Base de implementación prevista: Flutter/Dart para interfaz y Kotlin para el motor Android. iOS es evolución posterior. El resultado visual se entregará con especificaciones independientes del framework para traducirlo a Flutter; un prototipo web no acredita una app Android ni exportación automática a Dart.

## 3. Objetivos observables de diseño

| ID | Objetivo | Comprobación |
|---|---|---|
| BD01 | Hacer identificables los bloqueos de preparación | Cada una de las seis causas RF05.CA2 aparece con texto y acción disponible; inicio sigue deshabilitado |
| BD02 | Distinguir sesión, medición y señal | Activa/No disponible muestra No evaluable; Pausada muestra Evaluación suspendida |
| BD03 | Priorizar aviso durante monitoreo | Cierre ocular prolongado y acción breve aparecen sin abrir diálogo ni responder |
| BD04 | Representar operaciones pendientes | Inicio/pausa/reanudación/cierre no muestran éxito antes de confirmación |
| BD05 | Explicar registros incompletos | Resumen distingue pendientes, errores y final desconocido; no inventa duración |
| BD06 | Dar continuidad visual a todas las funciones | Componentes repetidos comparten tokens, estados y reglas de uso |
| BD07 | Permitir implementación verificable | Cada pantalla referencia IDs UX; cada componente y token tiene nombre, valor y uso |

## 4. Dirección visual

Diseñar una interfaz contemporánea con jerarquía tipográfica visible, espaciado consistente, superficies simples y controles identificables. Usar iconos de una misma familia. Evitar añadir tarjetas cuando no agrupan información o una acción relacionada.

Antes y después de la sesión puede mostrarse información detallada. En Monitoreo la jerarquía será: aviso/medición actual, información breve de sesión y controles. Preview facial es necesario en Preparación; no debe dominar Monitoreo. Una visualización facial decorativa no debe parecer medición real.

No incluir velocímetro, mapa, ruta, asistente conversacional, porcentaje de fatiga, ranking de seguridad, cuenta atrás hasta un microsueño ni ilustraciones que sugieran capacidades inexistentes. No usar el color verde con rótulo Seguro. Las categorías advertencia, cierre ocular y medición no disponible deben tener texto e icono además de color.

Modo claro y oscuro deben ser diseñados. No asumir que oscuro es siempre mejor ni que un color funciona sobre cualquier fondo. No aprobar colores hasta medir las combinaciones reales de texto/superficie.

En wireframes usar escala de grises y tipografía provisional del sistema. Después explorar dos direcciones visuales sobre las mismas pantallas P03, P04 y P06, manteniendo contenido y reglas. Compararlas por legibilidad, identificación de controles, jerarquía de estados y contraste medido. No generar dos productos con navegación diferente.

No se fija aún logotipo, paleta, familia tipográfica comercial ni sonidos. Una propuesta debe registrar esos valores y, para fuentes/iconos/activos, procedencia y licencia; no afirmar licencia sin comprobarla.

## 5. Condiciones de composición y accesibilidad

Valores propuestos para diseñar y revisar; no son resultados de ensayos ejecutados:

- Lienzo principal: viewport de contenido de 360×800 unidades lógicas en orientación vertical. Revisar también anchos de 320 y 412; documentar altura disponible y zonas del sistema por separado.
- Esas unidades son de referencia de diseño, no píxeles físicos del teléfono ni promesa de que 1 px web equivalga a 1 dp en todo contexto.
- Acciones: área interactiva mínima de 48×48 unidades lógicas. En P06 proponer altura mínima de 56 para Pausar/Reanudar y Finalizar, sin solapamientos.
- Contraste de texto: mínimo propuesto 4,5:1 en las combinaciones de cada tema. Registrar primer plano, fondo y razón obtenida, incluidos avisos y controles deshabilitados con texto.
- Texto: revisar 100 % y 200 %. Ninguna acción esencial queda cortada, superpuesta o fuera del alcance del desplazamiento vertical.
- P06 prioriza aviso y controles en la composición principal. Si texto 200 % no permite conservarlos todos visibles, diseñar desplazamiento accesible; no recortar etiquetas para conservar un aspecto fijo.
- Botones con icono tienen nombre accesible. Documentar orden de lectura, foco inicial de diálogos y retorno de foco a su disparador al cancelar.
- No usar animación continua, parpadeo ni movimiento como único indicador. Estado pendiente también tiene texto.

El prototipo puede documentar semántica y medidas. TalkBack, escala real Android, latencias y captura se comprobarán después en la app.

## 6. Alcance completo y primera entrega

Alcance total: P01–P18, D01–D08, FL01–FL15, UX01–UX22 y sus 66 criterios. Mantener los IDs.

La primera entrega B1 se limita a cinco pantallas centrales y una pantalla de apoyo: P03 Inicio, P04 Preparación, P05 Calibración, P06 Monitoreo, P07 Resumen y P02 Permiso de cámara. Incluye D01, D02 y D05. No añade todavía el detalle completo de recuperación D06/P09, ni Historial/Ajustes como pantallas terminadas.

| Pantalla | Variantes que B1 debe cubrir |
|---|---|
| P02 | Explicación previa; permiso rechazado; rechazo que exige abrir ajustes |
| P03 | Sin historial; último resumen; sesión vigente; registro interrumpido; estado del motor desconocido |
| P04 | Lista para iniciar; seis bloqueos independientes RF05.CA2; reproducción pendiente; reproducción exitosa aún sin confirmación; No lo escuché |
| P05 | Instrucción inicial; adquisición; aceptación; tres rechazos RF06.CA2 |
| P06 | Iniciando; activa con calidad válida; advertencia; cierre ocular; no evaluable; recuperación; pausando; pausada; reanudando; reanudación rechazada; finalizando; confirmación pendiente; desconexión; fallo de sonido |
| P07 | Completo; consolidación pendiente; registro incompleto; extremo final desconocido |

Cada variante debe poder abrirse y comprobarse. Puede ser una vista separada o un escenario seleccionable desde herramientas externas de revisión; no esconderla en una nota ni introducir selectores técnicos en la UI de producción.

Los enlaces fuera de B1 se anotan en el tablero como Pendiente de B2 y se registran en cobertura. No se declaran funciones terminadas ni se crean pantallas genéricas para simularlas. Para el prototipo B1, el recorrido central debe completarse sin depender de esos destinos.

## 7. Reglas que se conservan

1. Navegación principal: Inicio, Historial, Ajustes. Tendencias pertenece a Historial.
2. P04–P06 no muestran barra principal. P06 y pausa usan el mismo ID.
3. Preparación exige seis condiciones; rostro visible no significa ojos medibles.
4. Lo escuché requiere éxito técnico previo; No lo escuché mantiene inicio bloqueado.
5. No se inventa duración/progreso de Kcal ni valor de umbrales de IA.
6. Cierre ocular no exige bostezo, respuesta ni botón Entendido.
7. Una orden pendiente no equivale a estado confirmado. Los 5 s del Área 02 son una decisión UX de espera, no latencia fisiológica.
8. Pausa y reanudación conservan ID; reanudación fallida conserva pausa abierta.
9. Finalizar libera recursos independientemente de consolidar el resumen.
10. Sesión interrumpida no reinicia captura ni recibe un final ficticio.
11. Mientras hay sesión vigente, incluida pausa, bloquear detalle, tendencias, valoración, exportación, borrado, retención, alias y tutorial. Aplicar también a rutas directas.
12. Fallo de audio permanece visible y no se cuenta como nuevo episodio ni automáticamente como fallo ocular.
13. Resumen conserva tiempos evaluable/no evaluable/pausado/desconocido y distingue episodios de repeticiones.
14. Exportación CSV produce dos archivos con resultados separados. Eliminación incompleta no comunica éxito.
15. Todos los datos del prototipo están identificados como DEMO — datos simulados. No afirmar cámara, IA o almacenamiento reales.

## 8. Datos de referencia para diseño

Usar DS00–DS08 del Área 02. Para B1: DS00, DS01, DS02 y DS07 son los casos principales. Datos que deben mantenerse:

- DS01: 600 s evaluables, 120 s no evaluables, 180 s pausados, 60 s desconocidos acotados; cobertura 83,3 %; total representado 960 s; dos episodios. Repetir sonido no añade episodio.
- DS02: final sin confirmar; mostrar desconocido. No calcular hasta la hora de reapertura.
- DS07: pausa sin respuesta durante 5 s; snapshot posterior Activa. No confirmar Pausada por pulsación.
- Cero denominador: No disponible, nunca 0 % presentado como medición obtenida.

Rótulo DEMO visible en pantallas de registros/monitoreo y exportación simulada. En tablero y documentación aclarar que el comportamiento del motor fue representado, no ejecutado.

## 9. Entregables por bloque

| Bloque | Contenido | Evidencia de entrega |
|---|---|---|
| B1 · Wireframes centrales | Seis pantallas, tres diálogos y variantes de sección 6 | Tablero identificado, recorrido navegable, tabla de acciones/estados y cobertura |
| B2 · Wireframes restantes | P01, P08–P18 y D03, D04, D06, D07, D08 | Inventario total P01–P18/D01–D08 y recorridos de datos/ayuda sin destinos indefinidos |
| B3 · Dirección visual | Dos propuestas para P03/P04/P06 | Comparación con mismos estados, valores y contraste; una selección registrada |
| B4 · Design system | Tokens, componentes y estados claros/oscuros | Catálogo con valores exactos, medidas, semántica, variantes y ejemplos |
| B5 · Diseño completo y entrega Flutter | Aplicar sistema a todo el inventario | Prototipo, recursos, especificaciones y cobertura UX; pendientes separados |

En B4 documentar al menos: colores semánticos por tema, tipografía y escala, espaciado, radios, bordes, elevaciones si se usan, iconografía y movimiento. Componentes: botones, campo/validación, fila de lista, selector, tarjeta de sesión, indicador de medición, aviso, preview de preparación, estado pendiente, vacío, error, métrica, episodio y diálogo.

Cada componente declara estados que corresponden a su función; no inventar estado hover obligatorio para controles táctiles. Cada token declara nombre, valor, unidad, uso y tema. Las medidas destinadas a Flutter se entregan en unidades lógicas y escalas tipográficas explicadas. Anotar cualquier equivalencia web usada en el prototipo.

## 10. Aceptación del encargo

| Criterio | Comprobación necesaria |
|---|---|
| BD.CA01 | B1 contiene exactamente sus seis IDs de pantalla y tres diálogos, con acceso a todas las variantes de sección 6 |
| BD.CA02 | Con cualquiera de los seis bloqueos P04, Iniciar no navega a Activa |
| BD.CA03 | No lo escuché conserva bloqueo y permite repetir sonido |
| BD.CA04 | Pausa sin respuesta conserva incertidumbre; rechazo de reanudación conserva pausa/ID |
| BD.CA05 | Calidad inválida muestra No evaluable; no aparece Seguro ni porcentaje de fatiga |
| BD.CA06 | Cierre confirmado con lote pendiente abre resumen pendiente sin reiniciar cámara representada |
| BD.CA07 | DS01/DS02 se representan con valores y extremos desconocidos de sección 8 |
| BD.CA08 | Cada acción de B1 tiene destino/resultado/cancelación/error o bloqueo identificados; destinos B2 se registran como pendientes |
| BD.CA09 | Se entregan variantes a 320/360/412 de ancho y prueba visual 100/200 % con resultado por pantalla |
| BD.CA10 | B4 incluye valores y razones de contraste por tema; no acepta solo etiquetas como moderno o accesible |
| BD.CA11 | B5 conserva trazabilidad de los 66 criterios UX con evidencia o pendiente explícito; no marca pruebas nativas como ejecutadas |
| BD.CA12 | Archivos de entrega y tablero incluyen versión, IDs, fuentes y lista de cambios; la simulación permanece identificada |

El responsable del proyecto revisará cada bloque antes de pedir el siguiente. La revisión es de un resultado concreto; no se exige aprobación de cada decisión de espaciado. Una modificación de comportamiento requiere propuesta con motivo e IDs afectados. No modificar el PRD para justificar un diseño que omitió una condición.
