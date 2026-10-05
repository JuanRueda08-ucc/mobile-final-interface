# Vigía — PRD: producto y alcance de la primera versión
Área 01 · Versión 1.1 de la especificación · 1 de octubre de 2026  
Autor del proyecto: Juan José Rueda Viveros  
Estado: definición propuesta para revisión; no acredita implementación ni fiabilidad de detección.  
Documento de referencia: Vigia_Base_Proyecto_v0.2.md. “Vigía” sigue siendo un nombre provisional.

## 1. Propósito de esta área

Definir qué producto vamos a construir, para quién, qué funciones incluye la primera versión y cómo comprobar que se completaron. Este documento alimenta el área siguiente: experiencia de usuario, flujos y navegación.

El desarrollo se estructurará por áreas y se avanzará paso a paso. Esta entrega desarrolla solo producto y alcance. No cierra el diseño visual, los umbrales de IA, contratos de programación, esquema de base de datos, distribución ni modelo comercial.

Convenciones:
- V1: función incluida en la primera versión completa.
- Evolución: función posterior; no se presenta como operativa en V1.
- Decisión pendiente: detalle que necesita evidencia o elección; no autoriza al agente a inventarlo.

## 2. Definición del producto

Aplicación Android que utiliza la cámara frontal de un teléfono montado de forma estable para observar señales faciales relacionadas con somnolencia, emitir avisos locales y registrar sesiones y eventos. El conductor prepara el sistema antes de iniciar y consulta los resultados después.

Propuesta de valor: permitir monitoreo personal y revisión de eventos con el teléfono disponible, sin exigir una cámara dedicada ni una cuenta remota. La calidad de observación y sus interrupciones deben ser visibles.

El producto observa señales; no certifica aptitud para conducir. El éxito inicial se define por funcionamiento completo y resultados de evaluación en condiciones declaradas, no por promesas de detección universal o de reducción de accidentes.

## 3. Usuario y escenarios

Usuario principal: conductor individual, particular o profesional, con Android y soporte para el teléfono. Puede trabajar en transporte de pasajeros, carga o distribución; la V1 no requiere vinculación empresarial.

Usuario secundario previsto: responsable de una flota que recibe eventos compartidos con autorización. No tendrá una cuenta ni panel empresarial en V1.

Escenarios V1:
- Preparar una sesión con el vehículo detenido.
- Monitorear con cámara e IA reales dentro de condiciones compatibles.
- Recibir una alerta breve con información comprensible.
- Conocer cuándo el sistema no puede medir.
- Registrar una pausa manual y reanudar cuando corresponda.
- Finalizar y revisar eventos, cobertura e interrupciones.
- Comparar sesiones y exportar o eliminar datos.

Escenarios no soportados por defecto: captura sin montaje estable, oscuridad u oclusiones que impidan medir, ejecución bajo cualquier restricción del teléfono y detección en cualquier modelo Android. Las condiciones efectivas se definirán por pruebas.

## 4. Objetivo y resultado esperado

Objetivo general: entregar y evaluar una aplicación Android completa con IA local para observar señales faciales relacionadas con somnolencia, alertar y permitir revisión personal.

Resultados de la primera entrega:
1. APK instalable con recorrido completo.
2. Captura e inferencia reales incluidas en el dispositivo.
3. Preparación y calibración con resultados explícitos.
4. Alertas locales con motivo y registro de episodios.
5. Historial persistente y recuperación de interrupciones.
6. Resumen y tendencias basados en observaciones reales.
7. Configuración, ayuda, exportación y eliminación.
8. Evidencia reproducible de pruebas y limitaciones.

## 5. Alcance por módulo

| ID | Módulo | Función V1 |
|---|---|---|
| M01 | Incorporación | Explicar propósito, procesamiento y condiciones; gestionar permisos |
| M02 | Preparación | Guiar montaje; comprobar rostro/ojos utilizables y sonido |
| M03 | Calibración | Crear una referencia válida o explicar por qué falla |
| M04 | Monitoreo | Mantener sesión, observaciones y estado de medición |
| M05 | Avisos | Diferenciar señales persistentes, prioridad alta y fallo de medición |
| M06 | Pausas | Registrar pausa y reanudación manual |
| M07 | Resumen | Duración conocida, tiempo evaluable, pausas, eventos e interrupciones |
| M08 | Historial y detalle | Consultar sesiones y motivos; comentar alertas retrospectivamente |
| M09 | Tendencias | Comparar registros por periodo considerando cobertura y versiones |
| M10 | Configuración y datos | Tema, opciones de aviso, retención, exportación, eliminación y ayuda |

Se propone un perfil local opcional con alias. La aplicación es de uso personal en V1; no identifica automáticamente quién está frente a la cámara ni separa varios conductores de forma automática.

## 6. Requisitos funcionales y criterios de aceptación específicos

Se conservan RF01–RF32. Cada requisito indica obligación y pruebas con condición, acción y resultado observable. Las metas temporales de UI/operación son propuestas de ingeniería, no tiempos de detección fisiológica ya validados.

Regla de cierre: un requisito dependiente de un parámetro sin definir NO está listo para aceptarse. La forma del ensayo queda fijada; sus valores y fixtures se completarán en el área de IA. Codex y Claude Code no deben rellenarlos por su cuenta.

### 6.1 Parámetros pendientes de cierre en el área de IA

| Referencia | Definición que debe quedar cerrada | Requisitos afectados |
|---|---|---|
| Q | Función de validez de observación: entradas, fórmula, unidades y umbrales | RF03, RF05, RF10, RF14, RF17 |
| Kcal | Duración y cantidad mínima de observaciones, cobertura y límite de dispersión para aceptar referencia | RF06 |
| W | Fórmula/condiciones de advertencia, ventana y umbrales; casos negativos | RF11 |
| C | Criterio exacto de ojo cerrado: métrica, normalización y umbral | RF12 |
| Tclose | Duración continua mínima de C con Q válida, en ms | RF12, RF15 |
| Eend | Condición y duración para cerrar un episodio | RF13 |
| Rrepeat | Intervalo y condiciones para repetir un aviso, por categoría | RF13 |
| Tstale | Edad máxima de un resultado para usarlo, en ms | RF14 |
| Krecover | Observaciones y cobertura necesarias para reconstruir ventana tras pérdida | RF15 |
| Matriz compatible | Equipos, Android y escenarios que pasan los ensayos | RF09, RF18, RF20, RNF04, RNF07, RNF09 |

Cada parámetro exige valor/algoritmo, versión y ensayo anotado de aceptación y rechazo. No basta “se definirá después” para cerrar el requisito. El cierre continuo usa timestamp monotónico y una observación inválida rompe el tramo. La ausencia de resultados se trata con Tstale; no prolonga indefinidamente la última clasificación.

### 6.2 Requisitos funcionales

#### RF01 — Presentar propósito y tratamiento de datos antes de solicitar cámara

**Obligación:** La aplicación debe mostrar la explicación de uso antes de invocar el permiso de cámara.

- **RF01.CA1:** Dada una instalación nueva, al abrirla se muestran finalidad, procesamiento local, datos guardados y condiciones de preparación; todavía no se abre la cámara ni se solicita su permiso.
- **RF01.CA2:** Al pulsar Continuar se guarda la versión de la explicación vista y se pasa a la explicación del permiso.
- **RF01.CA3:** Al reabrir con esa versión ya vista, no se repite la incorporación; Ayuda permite consultar el mismo contenido.

#### RF02 — Solicitar permiso de cámara y recuperar su rechazo

**Obligación:** La aplicación debe solicitar cámara desde la preparación y bloquear captura cuando no esté autorizado su uso.

- **RF02.CA1:** Con permiso no concedido, pulsar Permitir cámara invoca la solicitud de Android; aceptar habilita la comprobación de cámara.
- **RF02.CA2:** Si el usuario rechaza, no comienza captura ni se crea una sesión; se muestra Cámara sin permiso.
- **RF02.CA3:** Si Android ya no permite repetir la solicitud, se ofrece Abrir ajustes; al volver se vuelve a consultar el permiso, sin asumir aceptación.

#### RF03 — Mostrar encuadre y estado de medición antes de iniciar

**Obligación:** La preparación debe mostrar preview y resultados separados de presencia facial y medición ocular.

- **RF03.CA1:** Con cámara autorizada y una entrada de prueba con rostro presente y calidad ocular inválida, se muestra Rostro detectado y No puedo evaluar los ojos; Iniciar monitoreo está deshabilitado.
- **RF03.CA2:** Con entrada sin rostro, se muestra Rostro no detectado y el botón de inicio sigue deshabilitado.
- **RF03.CA3:** Con rostro y calidad válidos, se habilita el siguiente paso de preparación, pero no se inicia una sesión automáticamente.

#### RF04 — Probar sonido y exigir confirmación de audibilidad

**Obligación:** Antes de cada sesión, el usuario debe reproducir un aviso y confirmar que lo escuchó.

- **RF04.CA1:** En preparación, pulsar Probar sonido solicita reproducción y registra su resultado técnico.
- **RF04.CA2:** Solo después de resultado técnico exitoso se habilita Lo escuché; sin esa confirmación no se permite iniciar.
- **RF04.CA3:** Si la reproducción devuelve error, se muestra No se pudo reproducir el sonido y Reintentar; no se marca la prueba aprobada. La app no afirma medir audibilidad en la cabina.

#### RF05 — Bloquear inicio y mostrar la causa cuando falla preparación

**Obligación:** El inicio debe requerir permiso, cámara, modelo, medición válida, calibración aplicable y prueba audible confirmada.

- **RF05.CA1:** Para cada precondición falsa, una prueba independiente mantiene deshabilitado Iniciar monitoreo y no crea registro de sesión.
- **RF05.CA2:** La interfaz identifica cada causa: Cámara sin permiso, Cámara no disponible, Modelo no disponible, Ojos no evaluables, Calibración pendiente o Prueba de sonido pendiente.
- **RF05.CA3:** Si una precondición deja de cumplirse después de habilitar el botón, pulsarlo vuelve a comprobar todas; no crea una sesión si la comprobación falla.

#### RF06 — Guardar calibración únicamente cuando cumple sus condiciones

**Obligación:** La calibración debe aceptar o rechazar la referencia usando una configuración de calidad versionada.

- **RF06.CA1:** Con secuencia que cumple Kcal, se guarda una única referencia con ID, fecha, versión de modelo, versión de calibración y resumen de observaciones; se muestra Calibración completada.
- **RF06.CA2:** Con secuencia que incumple Kcal, no se guarda una referencia aceptada y se muestra el código de causa: observaciones insuficientes, calidad ocular inválida o referencia inestable.
- **RF06.CA3:** Cancelar detiene la captura de referencia y vuelve a preparación sin crear sesión. Kcal está pendiente: RF06 no se cierra hasta fijarlo.

#### RF07 — Verificar referencia y montaje antes de cada sesión

**Obligación:** Cada inicio debe asociar una referencia compatible; un cambio de montaje declarado por el usuario exige repetir calibración.

- **RF07.CA1:** La preparación muestra Verifica el soporte y permite declarar Cambié la posición; seleccionarlo marca la referencia como no aplicable y exige RF06.
- **RF07.CA2:** Si las versiones de modelo/esquema difieren de las admitidas por la referencia, no se inicia y se muestra Repite la calibración.
- **RF07.CA3:** La sesión almacena el ID y una instantánea o versión inmutable de la referencia; recalibrar después no modifica los datos de sesiones anteriores. No se promete detección automática de movimientos del soporte.

#### RF08 — Crear una sola sesión tras confirmar inicio

**Obligación:** La acción de inicio debe crear una sesión única y mostrarla activa solo después de confirmación del motor.

- **RF08.CA1:** Con todas las precondiciones cumplidas, diez pulsaciones de inicio en un segundo generan un solo ID de sesión y un solo registro inicial.
- **RF08.CA2:** Mientras el motor no confirma, se muestra Iniciando y se bloquea otro inicio; la UI no muestra Activa.
- **RF08.CA3:** Si el motor rechaza, se vuelve a preparación con el error y no queda una sesión activa ficticia; todo registro inicial creado se marca fallido.

#### RF09 — Analizar cámara física con modelo incluido y sin internet

**Obligación:** El motor debe utilizar un modelo local identificado y devolver resultados sobre imágenes capturadas.

- **RF09.CA1:** En un equipo compatible, con internet deshabilitado, una sesión de diez minutos produce resultados de inferencia sobre cámara física.
- **RF09.CA2:** El informe de prueba registra hash/versión del modelo y timestamps de entrada y resultado; no basta un contador de UI o resultados precargados.
- **RF09.CA3:** El registro de tráfico verifica que no se envían imágenes, landmarks ni observaciones a servidores durante esa prueba.

#### RF10 — Mostrar ciclo de sesión, medición y resultado como estados distintos

**Obligación:** La UI debe representar el estado real del motor sin deducir ausencia de señales de una imagen inválida.

- **RF10.CA1:** La UI distingue Preparando, Iniciando, Activa, Pausada, Finalizando, Finalizada e Interrumpida; un cambio de estado se muestra como máximo un segundo después de recibirlo.
- **RF10.CA2:** La medición se muestra como Inicializando, Utilizable, Limitada o No disponible; el resultado permite Sin señales persistentes, Advertencia, Alerta por cierre prolongado o No evaluable.
- **RF10.CA3:** Si la calidad es inválida, el resultado es No evaluable; no se muestra Sin señales persistentes, Seguro ni porcentajes de fatiga.

#### RF11 — Emitir advertencia cuando una ventana cumple la regla temporal

**Obligación:** El motor debe emitir advertencia al pasar de regla W falsa a verdadera con calidad válida.

- **RF11.CA1:** Con una secuencia anotada que satisface W, se emite una advertencia con ID, motivo y versión de política; un control que no satisface W no la emite.
- **RF11.CA2:** Se prueban los límites de cada condición de W: un paso temporal antes del umbral no activa; alcanzar el umbral sí activa si las otras condiciones se cumplen.
- **RF11.CA3:** La reproducción comienza como máximo 500 ms después de la decisión del motor; W está pendiente y RF11 no se cierra hasta definir su fórmula, ventana y umbrales.

#### RF12 — Emitir alerta por cierre ocular prolongado

**Obligación:** El motor debe emitir alerta cuando observa cierre ocular continuo válido durante al menos Tclose, sin exigir un bostezo.

- **RF12.CA1:** Con calidad válida y criterio ocular C cumplido continuamente por Tclose, se genera alerta visual y sonora y se registra el motivo Cierre ocular prolongado.
- **RF12.CA2:** En una secuencia sin bostezo pero con ese cierre se genera la misma alerta; una secuencia de cierre menor que Tclose no activa RF12.
- **RF12.CA3:** Una observación ocular inválida rompe continuidad: el tramo posterior no se suma al anterior. La reproducción comienza como máximo 500 ms después de la decisión. C y Tclose están pendientes; RF12 no se cierra sin esos valores.

#### RF13 — Agrupar un episodio y controlar repetición del aviso

**Obligación:** El motor debe mantener un ID por episodio y registrar por separado sus reproducciones.

- **RF13.CA1:** Una secuencia continua que mantiene la misma regla activa crea un episodio, aunque haya múltiples resultados de inferencia; nunca crea un evento por fotograma.
- **RF13.CA2:** Una reproducción repetida conserva ID de episodio y añade número/tiempo de aviso; solo se repite cuando se cumple Rrepeat.
- **RF13.CA3:** Tras cumplir Eend y volver a activar la regla, se crea otro ID. Una alerta RF12 no se suprime por el periodo de repetición de una advertencia RF11. Eend y Rrepeat deben cerrarse en la política.

#### RF14 — Suspender evaluación y registrar pérdida de observación

**Obligación:** El motor debe pasar a no evaluable ante resultado inválido o ausencia de resultados vigentes.

- **RF14.CA1:** Un resultado inválido produce estado No evaluable y abre un intervalo con causa y timestamp; nunca se convierte en observación de ojos abiertos.
- **RF14.CA2:** Si no llegan resultados durante Tstale, se invalida la observación y se registra Sin resultados de cámara/inferencia.
- **RF14.CA3:** El cambio visible tarda como máximo un segundo desde la decisión del motor. Tstale está pendiente; no se puede cerrar la prueba de ausencia de resultados hasta fijarlo.

#### RF15 — Recuperar evaluación sin reutilizar continuidad inválida

**Obligación:** Después de una pérdida, el motor debe recuperar calidad y reconstruir la ventana antes de emitir resultados evaluables.

- **RF15.CA1:** Tras una entrada inválida, una secuencia que todavía no satisface Krecover mantiene No evaluable y no emite decisiones basadas en la ventana anterior.
- **RF15.CA2:** Al satisfacer Krecover, se cierra el intervalo de pérdida y se pasa a medición Utilizable; los resultados utilizan solo observaciones posteriores al corte.
- **RF15.CA3:** Una prueba con dos cierres separados por pérdida no suma ambos para alcanzar Tclose. Krecover requiere definición antes de cerrar RF15.

#### RF16 — Pausar análisis y registrar el intervalo solicitado

**Obligación:** Una pausa confirmada por el motor debe detener evaluación de somnolencia y abrir un intervalo pausado.

- **RF16.CA1:** Pulsar Pausar pide transición; solo después de confirmación aparece Pausada y empieza el intervalo con timestamp del motor.
- **RF16.CA2:** Mientras está pausada, una secuencia que normalmente activaría RF12 no produce un nuevo episodio de detección.
- **RF16.CA3:** Diez solicitudes de pausa durante la transición crean un solo intervalo; su duración no se incluye en tiempo evaluable ni no evaluable.

#### RF17 — Reanudar la misma sesión tras comprobar condiciones

**Obligación:** La reanudación debe conservar ID y cerrar la pausa solo cuando el motor confirma recepción de observaciones utilizables.

- **RF17.CA1:** Con cámara, modelo y calidad aptos, pulsar Reanudar confirma la transición, cierra pausa y conserva el ID de sesión.
- **RF17.CA2:** Con cualquier condición falsa se permanece Pausada, se identifica la causa y no se acumula tiempo evaluable.
- **RF17.CA3:** Las ventanas de cierre anteriores a la pausa se descartan; una repetición de la solicitud no crea otra sesión ni cierra dos veces la pausa. Los criterios de calidad dependen de Q.

#### RF18 — Finalizar sesión y liberar sus recursos

**Obligación:** Al finalizar, el motor debe cerrar el análisis, guardar el cierre y liberar cámara y avisos.

- **RF18.CA1:** Pulsar Finalizar deshabilita nuevas órdenes de inicio para esa sesión y pasa a Finalizando hasta confirmación.
- **RF18.CA2:** En un equipo compatible, como máximo dos segundos después de confirmar Finalizada no llegan frames a esa sesión, la cámara está liberada, sus sonidos se detienen y su servicio de monitoreo deja de ejecutarse.
- **RF18.CA3:** Solicitar cierre repetidamente conserva un único cierre; si guardar falla, el resumen indica Registro incompleto y no afirma que quedó guardado.

#### RF19 — Identificar sesión interrumpida después de terminar el proceso

**Obligación:** Al reabrir, se debe reconciliar el registro durable y distinguir una sesión sin cierre confirmado.

- **RF19.CA1:** Forzar terminación con sesión activa y reabrir la marca Interrumpida; recupera los eventos cuyo commit había sido confirmado.
- **RF19.CA2:** No crea observaciones ni eventos entre el último resultado durable y la recuperación; el final incierto se presenta como desconocido.
- **RF19.CA3:** No inicia cámara ni reanuda sesión automáticamente; ofrece revisar el registro o preparar una nueva sesión.

#### RF20 — Mantener sesión al cambiar de pantalla y detectar desconexión del motor

**Obligación:** La navegación Flutter debe conservar la sesión nativa; una UI sin estado vigente no debe seguir mostrando monitoreo activo.

- **RF20.CA1:** Durante una prueba de dos minutos con cinco cambios entre pantallas de la app, se conserva ID y continúan resultados; no se inicia otra captura.
- **RF20.CA2:** Con pérdida de conexión UI–motor, se muestra Estado del monitoreo no disponible; la UI no confirma continuidad hasta obtener un snapshot vigente.
- **RF20.CA3:** Al reconectar, consulta estado y registros; no ejecuta inicio por defecto. El comportamiento al bloquear o cambiar a otra app se registra por escenario en RNF04, sin asumir compatibilidad universal.

#### RF21 — Calcular resumen desde registros persistidos y señalar faltantes

**Obligación:** El resumen debe derivarse de intervalos y episodios consolidados.

- **RF21.CA1:** Para un fixture con 600 s evaluables, 120 s no evaluables, 180 s pausados y 60 s desconocidos, muestra 83,3 % de cobertura, los cuatro tiempos y total representado de 960 s.
- **RF21.CA2:** Cantidad de eventos coincide con IDs de episodio únicos; repeticiones de sonido no aumentan el conteo de episodios.
- **RF21.CA3:** Con consolidación pendiente muestra Resumen pendiente de completar; con escritura fallida muestra Registro incompleto. Un extremo temporal desconocido se rotula así, sin inventar fecha final.

#### RF22 — Consultar historial por fecha y conservarlo tras reinicio

**Obligación:** El historial debe listar sesiones guardadas, de más reciente a más antigua, con estado y cobertura.

- **RF22.CA1:** Guardar dos sesiones, cerrar y reabrir conserva sus IDs; se muestran en orden descendente de inicio con fecha, estado y cobertura.
- **RF22.CA2:** Sin sesiones muestra Aún no tienes sesiones y Preparar primera sesión; con error de lectura muestra No se pudo cargar el historial y Reintentar.
- **RF22.CA3:** Una sesión interrumpida no aparece como finalizada y no se oculta; la lectura de detalles utiliza el mismo ID seleccionado.

#### RF23 — Mostrar motivo, duración y contexto de cada episodio

**Obligación:** El detalle debe permitir localizar el episodio y consultar su evidencia resumida.

- **RF23.CA1:** Seleccionar evento muestra categoría, motivo, fecha, desplazamiento desde inicio, calidad de medición y versiones de modelo/política.
- **RF23.CA2:** Si duración/final no están confirmados, muestra Duración no disponible o Episodio sin cierre confirmado; no los reemplaza por cero.
- **RF23.CA3:** El detalle no muestra capturas faciales si el producto no las guardó; un aviso técnico de cámara no se rotula como somnolencia.

#### RF24 — Guardar valoración retrospectiva sin alterar el evento

**Obligación:** La valoración debe guardarse como dato separado y solo permitirse fuera de una sesión activa.

- **RF24.CA1:** Para una sesión cerrada se puede elegir Útil, No percibí somnolencia o No estoy seguro; se conserva código y fecha de valoración tras reiniciar.
- **RF24.CA2:** Cambiar valoración sustituye la anterior en ese campo, pero mantiene ID, motivo, timestamps y versión del evento detectado.
- **RF24.CA3:** En sesión activa no se habilita la edición; una valoración no modifica umbrales ni activa entrenamiento.

#### RF25 — Mostrar estadísticas descriptivas de siete y treinta días

**Obligación:** La vista debe calcular totales y tasas sin mezclar denominadores ni versiones de política.

- **RF25.CA1:** En periodos de siete y treinta fechas locales incluyendo hoy, se filtran sesiones por fecha de inicio y se muestra intervalo exacto; las sumas se calculan por grupo de versión de política.
- **RF25.CA2:** Con 2 episodios y 1800 s evaluables, muestra 4,0 episodios/hora evaluable; la cobertura agregada usa sumas de tiempos, no promedio de porcentajes.
- **RF25.CA3:** Sin tiempo evaluable, tasa y cobertura muestran No disponible. Presenta totales por categoría y pausas; no genera diagnóstico, ranking ni conclusión automática de mejoría.

#### RF26 — Exportar sesiones y eventos a JSON y CSV y comprobar escritura

**Obligación:** La exportación debe crear archivos legibles con los datos seleccionados y metadatos de versión.

- **RF26.CA1:** Seleccionar JSON incluye schemaVersion, exportedAt, sesiones, episodios, intervalos, pausas y valoraciones; seleccionar CSV produce un archivo de sesiones y otro de episodios con IDs de relación.
- **RF26.CA2:** Los archivos incluyen fechas ISO 8601 con zona/offset, duraciones en ms y versiones; al reimportarlos en la prueba coinciden IDs y conteos con la selección. Texto con coma, comillas o salto de línea no rompe columnas CSV.
- **RF26.CA3:** Cancelar el selector no muestra éxito ni marca exportación completada. Error de escritura muestra No se pudo exportar; solo se confirma después de cierre exitoso del archivo.

#### RF27 — Eliminar sesiones y sus datos asociados en ambos almacenes

**Obligación:** El borrado debe abarcar historial y journal nativo e impedir que la consolidación restaure los datos borrados.

- **RF27.CA1:** Para sesión cerrada, cancelar confirmación no borra; confirmar elimina sesión, episodios, intervalos, pausas y valoraciones de ambos almacenes.
- **RF27.CA2:** Tras reinicio y reintento de consolidación, el ID eliminado no reaparece. Borrar todo añade referencias y alias y vuelve a estado de primera preparación; las preferencias de tema pueden conservarse.
- **RF27.CA3:** Con sesión activa, se solicita finalizarla antes del borrado. Si cualquiera de los almacenes falla, no muestra éxito; mantiene solicitud pendiente y evita restaurar los registros ya borrados. Archivos exportados se informan como copias externas no eliminadas.

#### RF28 — Aplicar retención configurable sin borrar sesiones activas

**Obligación:** La retención debe depurar sesiones cerradas que vencen según su fecha de inicio.

- **RF28.CA1:** Valor inicial de producto: 90 días; admite 30, 90, 180 días o Hasta que los borre. Se guarda la opción y se informa que reducirla eliminará sesiones anteriores al corte.
- **RF28.CA2:** Para N días, corte = inicio de hoy menos N−1 fechas locales; una sesión anterior al corte se elimina y una exactamente en el corte se conserva. Se aplican las cascadas de RF27.
- **RF28.CA3:** Se ejecuta al abrir la app y después de cerrar/consolidar sesión; una sesión activa no se elimina. Un fallo de depuración no se presenta como limpieza completa. Son opciones propuestas de producto, no resultados de validación.

#### RF29 — Guardar preferencias y evitar cambios silenciosos durante sesión

**Obligación:** Las preferencias de usuario deben persistir y los parámetros del motor mantenerse identificados por sesión.

- **RF29.CA1:** Elegir Claro, Oscuro o Sistema y reabrir conserva la elección; los avisos usan texto e icono además del color.
- **RF29.CA2:** Una sesión activa conserva la versión de política de su inicio; la UI no ofrece sliders para cambiar Tclose o parámetros de detección durante la sesión.
- **RF29.CA3:** Las opciones de sonido seleccionan un patrón incluido y permiten probarlo; no hay opción de desactivar la alerta ocular manteniendo la sesión declarada plenamente operativa. Cambios de patrón requieren repetir RF04 antes de la siguiente sesión.

#### RF30 — Ofrecer instrucciones para montaje y fallos identificados

**Obligación:** Ayuda debe contener procedimientos accesibles sin iniciar captura.

- **RF30.CA1:** Se pueden abrir seis temas: soporte/encuadre, iluminación/ojos, calibración, sonido, interrupciones y datos/exportación.
- **RF30.CA2:** Cada tema muestra causa, acción concreta y condición para volver a intentar; Cámara sin permiso enlaza a Ajustes y Calibración pendiente enlaza a preparación.
- **RF30.CA3:** Abrir Ayuda no activa cámara, no crea una sesión y no requiere internet. Durante sesión activa la app muestra solo el aviso técnico breve, no un tutorial que exija lectura.

#### RF31 — Consolidar registros sin duplicar ni declarar completitud falsa

**Obligación:** La importación del journal debe ser idempotente y confirmar registros únicamente después de commit.

- **RF31.CA1:** Importar el mismo lote tres veces conserva un registro por ID de sesión/episodio/intervalo.
- **RF31.CA2:** Forzar cierre después del commit y antes de confirmación al journal, reabrir e importar otra vez mantiene los mismos conteos.
- **RF31.CA3:** Con lote pendiente o error de escritura, RF21 muestra estado pendiente/incompleto; si falta metadato necesario no se informa resumen definitivo. La prueba de eliminación verifica que RF27 no se revierte.

#### RF32 — Separar datos simulados y compilación de producción

**Obligación:** La variante demo debe identificar simulación y no compartir persistencia con producción.

- **RF32.CA1:** La variante demo muestra DEMO — datos simulados en monitoreo, historial y exportación; usa un almacén distinto.
- **RF32.CA2:** La compilación de producción no expone selector de fixtures ni conecta proveedores de resultados simulados; prueba de build verifica esa configuración.
- **RF32.CA3:** Una demostración con cámara real puede usar la variante real; no se rotula inferencia real si la entrada o resultados están precargados.

## 7. Reglas del producto

### Inicio y preparación

La preparación se realiza con el vehículo detenido. Verificar modelo disponible, permiso de cámara, observación utilizable, referencia y prueba de sonido. La confirmación audible es del usuario; no se afirma que la app mida audibilidad real en la cabina.

Un problema corregible ofrece explicación y reintento. Un equipo o condición incompatible no permite presentar el monitoreo como operativo. Se requiere una comprobación breve al inicio de cada sesión; una referencia previa no elimina esa comprobación.

### Monitoreo e interacción

Durante monitoreo: estado breve, duración y controles grandes. No solicitar texto, contestar cuestionarios, exportar archivos ni interpretar gráficos. La consulta de detalle y comentarios queda fuera de la sesión activa. Los controles se usan al estar detenido.

No usar “Seguro”, “Puedes conducir” o porcentajes de fatiga no validados. Texto propuesto con medición utilizable: “Monitoreo activo”; la ausencia de señales puede mostrarse como dato secundario.

### Alertas

Tres categorías:
- Advertencia: señales persistentes que cumplen la política.
- Prioridad alta: patrón definido de mayor prioridad, con medición válida.
- Medición no disponible: no se puede evaluar; no es una detección de somnolencia.

Texto de acción propuesto: “Detente en un lugar seguro”. El diseño final del mensaje pertenece al área de experiencia. La app no pretende determinar cuál es ese lugar.

La alerta no depende de internet ni de que Flutter renderice una pantalla. El usuario prueba el sonido antes de comenzar. No se eluden silencio o No molestar. Si el sistema no permite el canal sonoro necesario, la preparación indica el problema y solicita resolverlo antes del inicio.

### Pausas y cierres

Una pausa es manual; V1 no conoce movimiento o velocidad. No se infiere que el vehículo esté detenido por ausencia de rostro. Reanudar requiere comprobación de calidad.

Después de finalizar, la app no puede conservar la cámara activa por error. Una sesión interrumpida no se reanuda automáticamente al abrir la app.

### Comentarios

Son percepción del usuario posterior al evento, no etiquetas clínicas ni prueba de que el algoritmo estaba bien o mal. Se conservan separados del resultado original. No activan entrenamiento ni ajuste automático de umbrales.

## 8. Estados y manejo de excepciones

| Situación | Comportamiento esperado |
|---|---|
| Sin permiso | Preparación bloqueada, explicación y recuperación |
| Cámara ocupada | No evaluable; conserva datos y ofrece recuperación cuando se detenga |
| Modelo ausente/incompatible | No inicia inferencia; error específico |
| Referencia de baja calidad | No válida; reintento con guía |
| Rostro visible pero ojos no medibles | No evaluable para señales oculares |
| Luz insuficiente/oclusiones | Medición no disponible; no estimar con datos inventados |
| Pérdida de cámara durante sesión | Aviso técnico, intervalo y recuperación controlada |
| Fallo de audio | Aviso técnico; no confirmar reproducción exitosa |
| Restricción térmica o de energía | Medición limitada o detenida según política; capacidad real visible |
| Falta de espacio o fallo de escritura | Indica registros incompletos; no afirma persistencia exitosa |
| Desconexión de interfaz | Motor conserva registros durables; reconciliación al volver |
| Proceso terminado | Sesión interrumpida; ninguna continuidad de análisis supuesta |
| Historial vacío | Explicación y acción para preparar primera sesión |
| Exportación cancelada/fallida | No comunica éxito |
| Eliminación durante sesión | Solicita finalizar antes de borrar datos de la sesión activa |

Cambios de conectividad no son causa para detener el análisis local. El modo offline debe ser un comportamiento normal.

## 9. Definiciones de tiempo y métricas personales

La sesión empieza cuando el motor confirma inicio, no durante preparación. Se representan intervalos mutuamente excluyentes:
- Evaluable: observaciones suficientes para aplicar la política.
- No evaluable: motor activo pero observación insuficiente.
- Pausado: suspensión solicitada por el usuario.
- Desconocido: no existe evidencia suficiente del estado.

Cobertura = tiempo evaluable / tiempo de monitoreo con estado conocido, excluyendo pausas. Si el denominador es cero, mostrar “No disponible”. Mostrar también duración de pausas y existencia de tiempo desconocido, para que la cobertura no oculte interrupciones.

No sumar duración de eventos al tiempo de sesión: eventos ocurren dentro de los intervalos. Duración utiliza reloj monotónico; las fechas civiles sirven para presentación y agrupación.

Ante cierre inesperado no se presume que hubo conducción hasta que se reabrió la app. Se conserva el último estado durable, se marca final desconocido/interrumpido y no se rellena ese hueco como tiempo evaluable.

Tendencias propuestas:
- Cantidad de sesiones.
- Tiempo evaluable total.
- Cobertura de observación.
- Episodios por categoría.
- Episodios por hora evaluable, cuando existe denominador.
- Pausas registradas.

Comparar solo registros compatibles en política y condiciones documentadas; separar versiones cuando afecten interpretación. No convertir estas tendencias en diagnóstico, ranking de seguridad o recomendación automática de turnos.

Con pocos datos mostrar registros disponibles sin afirmar una tendencia. La regla mínima para conclusiones, si se incorporan, se define después; V1 puede presentar comparaciones descriptivas.

## 10. Datos y privacidad desde producto

Datos V1: alias opcional, referencias de calibración, sesiones, eventos, intervalos de calidad, pausas, preferencias y comentarios. Cada evento conserva versión de modelo/política y evidencia resumida.

No almacenar fotos, videos ni landmarks completos por defecto. No identificar al conductor mediante reconocimiento facial. No solicitar GPS, micrófono ni contactos para el alcance definido.

Exportación explícita por el usuario; no envío automático a familiares, empresa o supervisor. El informe permite al usuario conocer qué datos saldrán de la app. Una vez exportado, el archivo es una copia fuera del historial: borrarlo de la app no elimina automáticamente copias compartidas.

Borrado y retención incluyen el registro nativo y el historial consolidado. El tratamiento de copias de seguridad se define antes de distribución. No afirmar que SQLite, Room o Drift ofrecen cifrado por defecto.

Investigación con imágenes, si se necesita, requiere un modo y procedimiento separados; no se habilita de forma silenciosa en el producto personal.

## 11. Requisitos de calidad y aceptación específicos

Se conservan RNF01–RNF10. Los números de rendimiento son metas de ingeniería propuestas para esta especificación, no resultados obtenidos. La aceptación por equipo queda pendiente hasta fijar la matriz y ejecutar los ensayos. Los límites de fiabilidad del detector no se inventan aquí.

### RNF01 — Completar monitoreo y revisión sin conexión

- **RNF01.CA1:** En un dispositivo de referencia, desactivar datos móviles y Wi-Fi antes de abrir la app y completar preparación, calibración, diez minutos de sesión y cierre; ninguna acción solicita conectividad.
- **RNF01.CA2:** Con fixture que activa RF12 durante esa sesión, se emite alerta y aparece su episodio en el resumen.
- **RNF01.CA3:** Historial, Ayuda, borrado y escritura de exportación a almacenamiento local funcionan offline; compartir a una app externa no forma parte de esa garantía.

### RNF02 — Mantener tiempo de renderizado y aislar inferencia de UI

- **RNF02.CA1:** En compilación profile/release, con pantalla de 60 Hz, el percentil 95 del tiempo de build y del tiempo de rasterizado, medidos por separado durante 60 s de monitoreo, no supera 16,7 ms cada uno.
- **RNF02.CA2:** El perfil de hilos confirma que el cálculo de inferencia y características no se ejecuta en el hilo de UI Flutter ni en el hilo principal Android.
- **RNF02.CA3:** Se repite en cada equipo declarado compatible con su versión de modelo y modo de captura. Si falla, ese modo/equipo no satisface RNF02; no se cierra mediante una inspección visual.

### RNF03 — Verificar lectura, contraste, tamaño de controles y semántica

- **RNF03.CA1:** Con escala de texto 100 % y 200 %, ninguna etiqueta o acción esencial queda cortada, superpuesta o inaccesible; se comprueban preparación, calibración, monitoreo, resumen, historial y ajustes en modo claro y oscuro.
- **RNF03.CA2:** Objetivos de diseño propuestos: contraste de texto ≥4,5:1 y área táctil de acciones ≥48×48 unidades lógicas; se registran mediciones por componente, sin afirmar certificación externa.
- **RNF03.CA3:** TalkBack anuncia nombre, función y estado de las acciones; un cambio de calidad se anuncia sin obligar a interpretar color. El reporte enumera cada pantalla/componente probado y su resultado.

### RNF04 — Declarar continuidad por equipo y escenario probado

- **RNF04.CA1:** Para cada combinación marca/modelo/Android/build, ejecutar cinco minutos en cada escenario: app visible, otra pantalla de la app, otra app, pantalla bloqueada y llamada recibida. Separar los escenarios para atribuir resultados.
- **RNF04.CA2:** Registrar timestamps de resultados y periodos que superen Tstale, estados, avisos e ID. Con hueco o captura suspendida no se declara monitoreo continuo para ese escenario.
- **RNF04.CA3:** Forzar cierre y retirar permiso producen el comportamiento de RF19 y RF14; publicar una tabla de soportado/no soportado para cada escenario. La matriz queda pendiente hasta ejecutar pruebas.

### RNF05 — Conservar unicidad y estados ante reintentos

- **RNF05.CA1:** Con un fixture de 10 sesiones y 100 episodios, importar tres veces conserva exactamente 10 IDs de sesión y 100 IDs de episodio.
- **RNF05.CA2:** Simular fallo después de commit y antes de confirmación, reiniciar y reintentar conserva los mismos conteos y relaciones.
- **RNF05.CA3:** Borrar una sesión e importar un lote antiguo no la restaura; fallo parcial mantiene el estado de error exigido por RF27.

### RNF06 — Comprobar liberación de cámara y servicio tras cierre

- **RNF06.CA1:** Después de confirmación de cierre, dentro de dos segundos el contador de frames de esa sesión deja de aumentar y se cancela toda reproducción vinculada a ella.
- **RNF06.CA2:** El servicio de monitoreo de esa sesión ya no figura en ejecución y el preview no mantiene acceso a la cámara.
- **RNF06.CA3:** Diez ciclos de inicio/cierre permiten abrir de nuevo la cámara sin reiniciar la app; nunca quedan dos propietarios del dispositivo de captura.

### RNF07 — Medir latencia, carga y recursos por modo de captura

- **RNF07.CA1:** Por cada equipo/mode declarado, medir al menos 1000 resultados; latencia captura→resultado facial p95 <200 ms. Se documenta cómo se obtiene el timestamp de captura; no sustituirlo por el momento de dibujar la UI.
- **RNF07.CA2:** Registrar frecuencia solicitada/real, frames capturados, enviados, procesados y descartados, RAM, estado térmico y batería inicial/final con duración. Toda temperatura incluye sensor y unidad; si no está disponible se registra No disponible.
- **RNF07.CA3:** Medir por separado decisión→inicio de sonido; debe ser ≤500 ms según RF11/RF12. No usar esa medida para afirmar que se detecta somnolencia en 500 ms.

### RNF08 — Reproducir ensayos con versiones y fixtures identificados

- **RNF08.CA1:** Cada reporte incluye hash del APK, equipo/Android, versión/hash del modelo, política, calibración, configuración, protocolo y fecha.
- **RNF08.CA2:** Cada caso con fixture identifica su versión y conserva eventos/timestamps esperados y obtenidos.
- **RNF08.CA3:** Ejecutar tres veces el mismo fixture en la misma configuración produce la misma clasificación e IDs distintos entre ejecuciones; diferencias de tiempo de ejecución se reportan frente a los límites de rendimiento.

### RNF09 — Completar sesenta minutos y evaluar estabilidad de memoria

- **RNF09.CA1:** En cada equipo declarado compatible, ejecutar 60 min continuos en el modo de captura elegido sin crash ni ANR; registrar toda interrupción y toda restricción térmica.
- **RNF09.CA2:** Como objetivo provisional, la media de memoria del proceso en los últimos diez minutos no supera en más del 20 % la media de los minutos 10–20; registrar muestras cada minuto. Un fallo exige revisión, no una promesa de estabilidad.
- **RNF09.CA3:** Al finalizar, ejecutar RF18 y RF21. La prueba de 60 min solo acepta esa duración/condición; no valida una jornada completa.

### RNF10 — Identificar simulación y mostrar solo funciones disponibles

- **RNF10.CA1:** La auditoría de build comprueba que producción conecta el modelo real y no fixtures; demo mantiene la separación RF32.
- **RNF10.CA2:** Recorrer cada acción habilitada de V1 obtiene el resultado especificado o su error; no hay botones que devuelvan éxito sin ejecutar la operación.
- **RNF10.CA3:** La interfaz de V1 no presenta iOS, flotas, GPS, cámara externa o entrenamiento propio como disponibles. El reporte verifica el inventario de módulos M01–M10.

### Fiabilidad del detector: cierre pendiente

La evaluación del área de IA deberá fijar: población y condiciones, unidad de evento, tolerancia temporal para emparejar alerta/anotación, tamaño de muestra, sensibilidad mínima por categoría, máximo de falsas alertas por hora evaluable y latencia máxima hasta alerta. Sin esos valores el detector no se declara aceptado para uso real.

La prueba de reglas con fixtures verifica implementación, no validez fisiológica. Las pruebas de UX no sustituyen esas métricas.

## 12. Evaluación del producto

Antes de implementación, pruebas de comprensión del prototipo con personas representativas:
- Entender diferencia entre monitoreo activo y falta de medición.
- Completar preparación sin ayuda del desarrollador.
- Interpretar una alerta sin asumir permiso para seguir conduciendo.
- Encontrar evento, exportación y borrado después de una sesión.

Propuesta inicial: cinco participantes para revisión formativa de UX; no es una validación estadística de detección. No se afirma que esa muestra represente a todos los conductores.

Después de implementación: pruebas controladas de señales anotadas y escenarios negativos, seguidas de validación representativa supervisada. No inducir somnolencia mientras se conduce.

Indicadores del producto: porcentaje de tareas completadas, errores de preparación, fallos recuperados y comprensión de estados. La recolección inicial puede hacerse en sesiones de prueba; no se necesita telemetría remota ni cuenta.

## 13. Fuera de V1 y ruta futura

| Evolución | Dependencia previa |
|---|---|
| iOS | Adaptador nativo y evaluación específica de plataforma |
| Cuentas y respaldo remoto | Necesidad definida, identidad, privacidad y recuperación |
| Gestión empresarial | Roles, permisos, vinculación y reglas de acceso |
| GPS/rutas | Función justificable, consumo y tratamiento de ubicación |
| Cámara externa | Compatibilidad, experiencia de instalación y nuevo alcance de hardware |
| Clasificador temporal propio | Datos autorizados, baseline y mejora medida |
| Detección específica de distracción | Definición y validación diferentes de somnolencia |
| Publicación comercial | Desempeño declarado, operación y revisión de distribución |
| Pagos o suscripción | Modelo de ingresos y funciones con demanda comprobada |

No se generan pantallas falsas para funciones futuras. No fijar precios en este PRD. La detección local y sus avisos no requieren una conexión remota para funcionar.

## 14. Definición de V1 terminada

Todos los requisitos V1 y sus criterios RFxx.CAx/RNFxx.CAx deben tener evidencia de aprobado; todo parámetro del catálogo 6.1 debe estar cerrado. Cambiar alcance requiere una revisión explícita con motivo y nueva versión. Un criterio bloqueado por parámetro o equipo pendiente no se registra como aprobado.

Entrega verificable:
- APK instalable en equipos declarados.
- Modelo local con procedencia y licencia revisadas.
- Sesión offline con eventos observables.
- Resumen e historial coherentes.
- Exportación y eliminación comprobadas.
- Informe de funcionamiento, rendimiento y detección en condiciones de prueba.
- Diseño revisado y documentación para reproducir resultados.

Esto define una primera versión funcional completa. La comercialización requiere su propia puerta de validación y no queda aprobada por completar el APK.

## 15. Decisiones asentadas y pendientes

Asentadas para esta estructura:
- Android primero; iOS posterior.
- Flutter + Dart con motor Android en Kotlin.
- IA e inferencia locales.
- Usuario individual y perfil local opcional.
- Sin cuenta obligatoria para funciones centrales.
- Preparación/calibración antes del uso; pausas manuales.
- Historial, tendencias descriptivas, exportación JSON/CSV y borrado.
- Trabajo por áreas, con documentos compartidos para Codex y Claude Code.

Propuestas de este PRD sujetas a revisión: retención inicial de 90 días con opciones de RF28, periodos de tendencias de 7/30 días, comentarios retrospectivos y metas temporales/recursos de RNF02, RNF06, RNF07 y RNF09. Son decisiones de producto/ingeniería propuestas, no mediciones ya obtenidas.

Pendientes que sí afectan implementación: teléfono de referencia, fecha/dedicación, exigencia académica de modelo propio, reglas de calibración, política de alertas, criterios de calidad y condiciones de continuidad soportadas.

Se puede definir el flujo UX ahora. Los requisitos que dependen de Q, Kcal, W, C, Tclose, Eend, Rrepeat, Tstale o Krecover no están listos para aceptación hasta completar el catálogo 6.1. Documentar que faltan valores no equivale a cerrar el requisito.

## 16. Siguiente área y orden de trabajo

Área 01: producto y alcance — revisada para precisión en v1.1; los parámetros de IA y la matriz de equipos siguen pendientes. No se declara implementación aceptada.  
Área 02: experiencia de usuario — siguiente trabajo.  
Áreas posteriores: pantallas/wireframes, design system, motor IA, arquitectura/contratos, datos/privacidad, calidad, operación comercial y backlog de desarrollo.

Área 02 entregará:
1. Mapa de navegación.
2. Flujos de primera instalación, sesión habitual, pausa, finalización y recuperación.
3. Acciones disponibles en cada estado.
4. Mensajes y decisiones ante excepciones.
5. Trazabilidad de cada flujo con RF01–RF32.

Los wireframes y el diseño visual se harán después de esos flujos. No se crea código de aplicación en esta área.

## 17. Registro de revisión v1.1

Se reemplazaron 32 títulos/definiciones y 96 criterios funcionales, y se detallaron 10 requisitos de calidad con 30 criterios. RF12 se llama ahora Emitir alerta por cierre ocular prolongado; Prioridad alta queda como categoría de aviso, no como nombre del requisito.

Formato obligatorio para próximas áreas: ID estable, obligación concreta, condición de prueba, acción/disparador y resultado observable. Usar unidades/límites cuando sean necesarios; identificar dependencias sin valor. Evitar aceptación basada únicamente en “fluido”, “correcto”, “consistente”, “según política” o “cuando sea necesario”. Una referencia a otro criterio debe señalar su ID.

Los agentes no pueden convertir un parámetro pendiente en un valor arbitrario ni afirmar aceptación sin ejecutar la evidencia requerida. La precisión se aplica a todos los requisitos futuros, no solo a RF12.

