# Vigía · Área 05: IA y protocolo de evaluación

Versión 1.0 · 3 de octubre de 2026  
Autor del proyecto: Juan José Rueda Viveros  
Plataforma inicial: Android, cámara frontal del teléfono, procesamiento local.  
Estado: especificación de algoritmos y ensayos. No hay modelo de somnolencia entrenado, resultados de evaluación ni umbrales aceptados para distribución.

## 1. Qué define esta área

Esta entrega define entradas/salidas, características faciales, calidad Q, calibración Kcal, criterio ocular C, advertencia W, cierre prolongado Tclose, episodios Eend, repetición Rrepeat, vigencia Tstale, recuperación Krecover y evaluación. Se redacta sobre el PRD v1.1, UX v1.0 y arquitectura Área 04 v1.0, consultados en su estado actual.

Se distinguen tres estados de una decisión: **especificada** (algoritmo y unidades definidos), **candidata** (valor para experimentar) y **aceptada** (valor congelado con evidencia de los ensayos correspondientes). Ningún valor de laboratorio se vuelve aceptado por aparecer en este documento. RF06, RF11, RF12, RF14 y RF15 continúan sin aceptación hasta completar sus pruebas con configuración aceptada.

La implementación podrá ejecutar cámara e inferencia reales en laboratorio con una configuración candidata claramente identificada. Eso no es simulación, pero tampoco acredita fiabilidad para conducir. El manifiesto y la variante de distribución impedirán publicar una política cuyo qualificationStatus siga en experimental. No se añade una pantalla ni se vuelve a Claude Design en esta área.

## 2. Qué es la IA de Vigía y qué observa

| Parte | Función | Naturaleza |
|---|---|---|
| Face Landmarker | Localiza geometría facial en imágenes | Modelo neuronal preentrenado local |
| QualityEvaluator | Determina si la observación admite el cálculo | Reglas de calidad versionadas; modelo adicional solo si se demuestra necesario |
| FeatureExtractor | Calcula apertura ocular y referencias | Geometría y normalización |
| TemporalAggregator | Procesa secuencias con tiempo y cortes | Algoritmo temporal |
| DetectionPolicy | Decide advertencia o cierre ocular prolongado | Reglas explícitas versionadas |

La API de MediaPipe devuelve landmarks y, opcionalmente, blendshapes y matrices faciales. No devuelve un diagnóstico de fatiga ni una probabilidad de que alguien pueda conducir [S1]. Los umbrales de detección/presencia/tracking de la API no son una puntuación de calidad ocular por muestra.

La señal principal V1 es cierre ocular bilateral observado. La advertencia candidata usa acumulación temporal de cierres; no depende de un bostezo. Apertura de boca, inclinación y parpadeo pueden investigarse, pero no generan por sí solos una etiqueta de somnolencia. No se incorporan LLM, chatbot, micrófono ni identificación facial.

Objetivos separados de evaluación:

- Verificar que la geometría distingue observaciones oculares en condiciones declaradas.
- Verificar que reglas, cortes, tiempos y episodios se implementan correctamente.
- Medir detección de **señales visibles anotadas**, falsas alertas y abstención.
- Evaluar somnolencia fisiológica solo en una fase distinta con referencia y protocolo adecuados. Actuar un cierre de ojos no aporta esa evidencia.

## 3. Configuración del modelo y manifiestos

Propuesta de laboratorio: Face Landmarker en LIVE_STREAM, delegate CPU como baseline, maxNumFaces=2 para reconocer ambigüedad cuando la tarea devuelve dos rostros; blendshapes desactivados y matrices faciales activadas para explorar calidad por postura. La documentación indica que el suavizado de la tarea se aplica con numFaces=1 [S1]; no asumirlo con dos rostros.

Dos rostros devueltos invalidan la selección V1: no elegir automáticamente quién conduce. Cero rostros significa ausencia. Un rostro devuelto no demuestra que sea el conductor ni garantiza que no exista otro rostro fuera de detección. El montaje y campo de visión forman parte de las condiciones de uso.

Versión y SHA-256 del archivo .task, biblioteca, delegate y configuración quedan fijados al crear el repositorio. El modelo se incluye como asset y no exige descarga al abrir. No usar latest.release del ejemplo documental en un build reproducible.

Manifiesto model-manifest: modelId, sourceUrl, downloadedAt, sha256, versionTag, licenseEvidencePath, taskLibraryVersion, landmarkSchemaVersion, delegate, runningMode, maxNumFaces y flags de salida. La licencia del código y la del archivo de modelo se verifican por separado; no afirmar que sean iguales.

Manifiesto policy-manifest: policyVersion, featureSchemaVersion, qualityConfigVersion, calibrationConfigVersion, parámetros completos, qualificationStatus, dataset/protocol/report IDs y compatibilidad con modelo. Cada sesión conserva esa configuración inmutable o su contenido direccionado por hash.

## 4. Datos de entrada, unidades y descarte

FrameEnvelope interno: frameId, captureGeneration, engineInstanceId, sessionId nullable, timestampCaptureNs, timestampSubmitNs, timestampResultNs, clockMappingVersion, widthPx, heightPx, rotationDegrees y imagen transitoria. GeometryResult relaciona esos IDs con caras, puntos y matriz. No se transmite imagen/landmarks completos a Flutter ni se persisten en V1.

La imagen para geometría se rota a orientación vertical/coherente con la cámara. Para medir distancias, convertir coordenadas normalizadas a píxeles: xPx=xNorm×widthPx, yPx=yNorm×heightPx. No calcular EAR directamente con x/y normalizados cuando ancho y alto son distintos. El espejo del preview no modifica la entrada de cálculo.

Descartar resultados con generación/instancia/sesión incorrecta, timestamp no creciente, esquema desconocido, valores no finitos o captura anterior al inicio confirmado. El resultado descartado no incrementa tiempo evaluable ni actualiza un episodio. Identificar causa técnica y liberar recursos.

El tiempo de cierre utiliza timestamps de captura convertidos al mismo reloj monotónico. El instante de decisión y los intervalos del estado de medición se registran con reloj del coordinador. Se conservan ambos: latencia de inferencia no se confunde con duración de cierre. Si no se ha demostrado la conversión de reloj, el modo no puede aceptar métricas de captura ni continuidad.

## 5. Apertura ocular y criterio C

### 5.1 Fórmula geométrica

Para seis puntos 2D de un ojo:

EAR = (dist(p2,p6) + dist(p3,p5)) / (2×dist(p1,p4)).

dist es distancia euclídea en píxeles; EAR no tiene unidad. La fórmula se toma de la literatura de apertura ocular [S2]. Su adaptación a MediaPipe se evalúa en Vigía; no hereda los resultados de otro detector.

Mapeo candidato landmarkSchemaVersion=mp-eye6-v1, siguiendo los contornos publicados por el proyecto MediaPipe [S3]:

| Ojo anatómico | p1 | p2 | p3 | p4 | p5 | p6 |
|---|---:|---:|---:|---:|---:|---:|
| Derecho | 33 | 160 | 158 | 133 | 153 | 144 |
| Izquierdo | 362 | 385 | 387 | 263 | 373 | 380 |

Verificar índices/orden mediante fixtures de geometría, overlay de investigación y esquema del modelo fijado. Un cambio de asset o topología exige repetir el ensayo; no intercambiar ojos basándose en el espejo de pantalla.

Ejemplo matemático: distancias verticales 6 y 6 px, horizontal 20 px → EAR=0,30. Verticales 1 y 1 px con horizontal 20 → 0,05. Son coordenadas sintéticas para comprobar fórmula; no validan que esa geometría mida un ojo real.

### 5.2 Normalización

La referencia guarda openEAR_R y openEAR_L independientes. rR=EAR_R/openEAR_R; rL=EAR_L/openEAR_L. No promediar primero los ojos: un ojo abierto no debe ocultar que el otro es inválido. Referencia ausente/incompatible o divisor no válido produce notEvaluable.

C(t)=Q(t) válida AND rR≤thetaClosed AND rL≤thetaClosed. Igualdad cumple. Un valor por encima en cualquiera de los ojos rompe el tramo. No se usa un valor suavizado para prolongar un cierre; el baseline temporal utiliza ratios de cada observación válida.

Open(t)=Q(t) válida AND rR≥thetaOpen AND rL≥thetaOpen. La banda entre thetaClosed y thetaOpen no se declara cerrada ni completamente abierta. thetaOpen se usa para comprobar reapertura/calibración/cierre del episodio; no introduce histéresis oculta en C.

Un guiño unilateral con el otro ojo abierto no activa RF12. Si cualquiera de los ojos no es medible, no basta el otro: Q inválida y No evaluable. La cobertura y el rendimiento de esta decisión se miden por condición.

El ratio EAR normalizado no equivale a porcentaje de párpado sobre pupila. No llamar “80 % cerrado” a un ratio 0,20 sin una validación específica.

## 6. Q: calidad de observación candidata

Q es una conjunción de condiciones comprobables, no una media que permita compensar un ojo invisible con buena iluminación. Registrar todos los motivos falsos. La evaluación se divide en Qgeom/imagen antes de calibración y Qref cuando existe referencia.

| Condición | Cálculo | Rechazo |
|---|---|---|
| Identidad de muestra | IDs/generación/esquema/timestamp coinciden | oldGeneration, invalidTimestamp, schemaMismatch |
| Resultado vigente | Edad captura→recepción≤Tstale y sin error | staleResult, inferenceError |
| Una cara retornada | faceCount==1 | noFace, ambiguousFace |
| Puntos utilizables | Índices presentes, coordenadas finitas, puntos/ROI dentro de imagen | invalidGeometry, eyeOutsideFrame |
| Resolución ocular | dist(p1,p4)≥minEyeWidthPx en cada ojo | insufficientEyeResolution |
| Asimetría geométrica | max(anchoR,anchoL)/min(anchoR,anchoL)≤maxWidthRatio | excessivePerspective |
| Luz | Estadísticos de ambos ROI superan los límites definidos | underexposedEyes, overexposedEyes |
| Nitidez | Varianza de Laplaciano de cada ROI≥minSharpness | blurredEyes |
| Postura aplicable | Cambio relativo de matriz≤maxPoseDeltaDeg cuando hay referencia | poseOutsideCalibration |
| Compatibilidad | Modelo, esquema y mountRevision admitidos | calibrationIncompatible |

No se añade una altura ocular mínima positiva: unos párpados cerrados pueden tener separación casi nula y seguir siendo una observación válida. Q no exige rR/rL de ojos abiertos. Esto se prueba expresamente para evitar que el filtro elimine las señales que queremos medir.

ROI de cada ojo: centro=(p1+p4)/2; rectángulo orientado con el segmento horizontal del ojo, ancho=1,6×dist(p1,p4), alto=0,8×dist(p1,p4). Muestrear en gris a 96×48 por interpolación bilineal, sin guardar recorte. ROI que sale de imagen se rechaza, no se rellena en negro. Intensidad candidata Y=0,2126R+0,7152G+0,0722B en escala 0–255 para el baseline RGB; conversiones YUV→RGB se fijan/versionan. Esta intensidad no es una medición fotométrica ni lux.

Luz: medianaY y fracción de píxeles extremos, considerando Y≤5 o Y≥250. Nitidez: varianza poblacional del Laplaciano de kernel [[0,1,0],[1,-4,1],[0,1,0]] sobre interior del ROI normalizado. Reportar valores, tamaño, interpolación y versión; el umbral no se traslada entre resoluciones/procesados sin ensayo.

Postura candidata: extraer rotación aproximada de la matriz facial fijando layout de la API; ortonormalizar columnas por Gram–Schmidt, verificar normas, orientación y determinante positivo. Rdelta=Rrefᵀ×Rcurrent; ángulo=acos(clamp((trace(Rdelta)−1)/2,−1,1)) en grados. No etiquetar ese ángulo como yaw/pitch fisiológicos. Matriz inválida impide esta comprobación. Su correspondencia con cambios de pose reales se verifica antes de aceptar la regla.

Durante adquisición inicial, Qgeom/imagen permite tomar una matriz provisional y comprobar estabilidad/asimetría; la postura relativa a la referencia definitiva se aplica después. La prueba de cámara no convierte esa referencia provisional en una calibración aceptada.

**Límite de esta Q:** luz, nitidez y geometría plausibles no prueban visibilidad ocular. Un modelo puede devolver puntos sobre gafas oscuras, reflejos o una oclusión. Estos casos son pruebas obligatorias: si el baseline los acepta como medibles, falla la calificación y se debe incorporar/mejorar un EyeVisibilityGate local con evaluación propia. No se cierra RF03/RF14 mediante una mera cara detectada ni declarando “gafas no soportadas” mientras la UI sigue mostrando medición utilizable sobre ellas.

## 7. Parámetros iniciales de laboratorio

Todos los valores siguientes son **candidatos propuestos para verificar y comparar**, no recomendaciones de duración fisiológica ni valores clínicamente validados. profileId=lab-eye-rules-0.1; qualificationStatus=experimental. Codex/Claude Code solo los usarán en una configuración de laboratorio identificada y fixtures; no los copiarán como una política aceptada de producción.

| Grupo / parámetro | Candidato | Unidad / condición exacta |
|---|---:|---|
| Confianza API: detección/presencia/tracking | 0,5 / 0,5 / 0,5 | Configuración de tarea, no score ocular |
| Q: minEyeWidthPx | 24 | Píxeles de imagen orientada, ambos ojos |
| Q: maxWidthRatio | 1,8 | Cociente adimensional |
| Q: minMedianY / maxMedianY | 40 / 220 | Inclusivos, luminancia 0–255 |
| Q: maxExtremeFraction | 0,25 | Inclusivo, por ROI |
| Q: minSharpness | 30 | Varianza de Laplaciano según sección 6 |
| Qref: maxPoseDeltaDeg | 25 | Grados relativos, inclusivo |
| Kcal: openDurationMs / minOpenSamples | 8000 / 60 | Secuencia guiada; todas las observaciones Q se cuentan |
| Kcal: minCoverage / maxRelativeMAD | 0,80 / 0,15 | Ambos ojos; cobertura y dispersión definidas en sección 8 |
| Kcal: openEARMin / openEARMax | 0,10 / 0,60 | Inclusivos, ambos ojos |
| Kcal: closedProbeCount / closedProbeDurationMs | 2 / 1000 | Cierres voluntarios estando detenido |
| Kcal: reopenDurationMs | 2000 | Entre comprobaciones y después de última |
| Kcal: minProbeSamples / minProbeCoverage | 6 / 0,80 | Por cierre, con Qgeom/imagen válida |
| Kcal: maxClosedProbeRatio | 0,50 | Mediana EAR cierre / referencia abierta, ambos ojos |
| C: thetaClosed | 0,55 | Ratios rR y rL≤umbral |
| Reapertura: thetaOpen | 0,75 | Ratios rR y rL≥umbral |
| Tclose | 1500 | ms continuos de C, observaciones válidas |
| Gmax | 150 | ms máximos entre capturas adyacentes y entre resultados recibidos |
| Tstale | 750 | ms máximos de edad de captura y de silencio de resultados |
| Krecover: minDurationMs / minSamples | 1000 / 6 | Secuencia válida continua después del corte |
| Krecover: minCoverage | 1,00 | Sin gaps>Gmax ni muestras inválidas en esa secuencia |
| W: windowMs / minWindowCoverage | 30000 / 1,00 | Ventana completamente reconstruida, sin cortes |
| W: thetaEntry / thetaExit | 0,20 / 0,10 | Proporción temporal; entry≥, exit≤ |
| W: minClosedRuns / minRunDurationMs | 3 / 200 | Tramos completos con reapertura comprobada |
| W: entryPersistenceMs | 500 | Condición de entrada válida continua |
| Eend: openPersistenceMs | 2000 | C y W falsas y Open verdadera continuamente |
| Rrepeat: warningMs / prolongedClosureMs | 15000 / 5000 | Desde último intento de dispatch de esa categoría |

Gmax<Tstale y thetaClosed<thetaOpen son invariantes. La salida de Q/condiciones no finitas no se resuelve con clamp salvo el argumento de acos por error de redondeo. Cada parámetro tiene unidad, límite inclusivo y fixture de frontera.

Configuración de captura para comparar: solicitar 640×480 y 1280×720 antes de rotación, cada una con 15 y 30 fps cuando CameraX/equipo admitan esas combinaciones; registrar la resolución y frecuencia realmente entregadas. No forzar soporte no reportado ni equiparar fps solicitados con procesados. El perfil elegido depende de RNF02/RNF07/RNF09, Q y detección.

## 8. Kcal: calibración y rechazos

Flujo propuesto para P05, con vehículo detenido y usuario despierto: referencia con ojos abiertos y comprobaciones voluntarias breves de cierre/reapertura. No se pide generar somnolencia. Ajustar el contenido de instrucciones mediante handoff posterior si cambia el flujo visual existente; esta área define el proceso del motor.

1. Adquirir 8000 ms de referencia abierta guiada. No contar este tiempo como sesión.
2. Admitir muestras Qgeom/imagen válidas; interrupciones no se rellenan. Exigir ≥60 muestras y cobertura≥0,80.
3. Calcular openEAR de cada ojo como percentil 80 de EAR válida; interpolación lineal con h=(n−1)×0,8 sobre valores ordenados. Registrar mediana y MAD de todas las muestras admitidas. relativeMAD=1,4826×mediana(|EAR−mediana(EAR)|)/mediana(EAR). Mediana≤0 o cálculo no finito rechaza por referencia inestable; no aplicar un divisor artificial.
4. Exigir openEAR dentro de [0,10;0,60] y relativeMAD≤0,15. La pose de referencia es una rotación válida representativa elegida como medoid: muestra que minimiza suma de ángulos a las otras; empate por timestamp menor. Exigir maxPoseDeltaDeg para la secuencia admitida.
5. Ejecutar dos comprobaciones guiadas de cierre de 1000 ms, cada una con ≥6 muestras válidas y cobertura≥0,80; medianaRatio≤0,50 en ambos ojos. Verificar reapertura por 2000 ms con ambos ratios≥0,75 y Q válida después de cada cierre.
6. Aceptar una única referencia inmutable si todas las condiciones cumplen; almacenar valores, conteos, coberturas, dispersión, separación observada, versiones y mountRevision. No guardar frames.

Cobertura de adquisición: suma de spans entre capturas adyacentes con ambos extremos Q válidos y gap≤Gmax dividida por duración guiada; extremos sin observación no se completan. Los parpadeos espontáneos permanecen en la muestra, no se eliminan usando la clasificación futura para fabricar estabilidad.

| Resultado | Condición concreta | Código público |
|---|---|---|
| Falta de evidencia | Conteo/cobertura/duración admitida insuficientes | insufficientObservations |
| Ojos no utilizables | Geometría/imagen/visibilidad fallan sin evidencia suficiente de ambos estados | invalidEyeQuality |
| Referencia inconsistente | MAD/rango/postura fallan o no hay separación/reapertura de las comprobaciones | unstableReference |

Si hay varias causas, guardar todas y elegir código principal en orden: invalidEyeQuality cuando existe fallo ocular explícito; insufficientObservations cuando faltan datos sin ese fallo; unstableReference con datos suficientes pero incompatibles. Cancelar invalida calibrationAttemptId; callbacks tardíos no aceptan ni guardan referencia.

Una calibración antigua no se adapta durante un cierre. Cambiar montaje, esquema/modelo incompatible o nueva referencia invalida aplicabilidad según RF07. No se promete detectar automáticamente cambios de persona; el producto es de uso personal y exige preparar de nuevo al cambiar de usuario.

## 9. Continuidad, spans y vigencia

### 9.1 Continuidad de señales

Para dos observaciones de captura consecutivas ti−1 y ti, un span [ti−1,ti) puede aportar tiempo de cierre solo si ambas tienen Q válida, C verdadera, misma generación/segmento y 0<ti−ti−1≤Gmax. La duración del tramo es timestamp de captura actual menos primer timestamp cerrado del tramo. No suma un valor fijo 1/fps ni cuenta frames como segundos.

Primer punto cerrado aporta duración cero. Una muestra C falsa, inválida o gap>Gmax reinicia el tramo. Al llegar una muestra válida después del gap, no se une al tramo anterior. Ningún timer dispara RF12 prolongando la última observación sin otro resultado válido.

Spans mixtos abierto/cerrado aportan cero tiempo cerrado al baseline conservador; con Q válida siguen siendo observables. Esto puede subestimar transiciones: se mide el error frente a anotaciones. No es evidencia de que los ojos estuvieron abiertos todo el span. Esta convención solo calcula closedTime, no transforma calidad inválida en ojos abiertos.

### 9.2 Intervalos de sesión y cobertura del producto

El tiempo evaluable del historial mide el tiempo de estado del coordinador en que admite decisiones según Q/Krecover; sus transiciones usan receipt/decision monotónico. La proporción de cierre de W usa spans de captura. Son denominadores diferentes y ambos quedan identificados en evidencia.

Watchdog del coordinador:

- Al recibir Q inválida, pasar inmediatamente a limited/unavailable según causa y notEvaluable; cerrar el intervalo evaluable, cortar ventanas y tramo.
- Si silencio de recepción>Gmax, pasar a limited/notEvaluable y cortar continuidad aunque todavía no llegue Tstale. El límite se mide desde recepción del último resultado, no desde el momento de dibujar Flutter.
- Si silencio≥Tstale o edad del resultado>Tstale, unavailable/notEvaluable y causa sin resultados/resultados atrasados. Igualdad de edad Tstale todavía es vigente; igualdad de silencio activa el watchdog. Estas dos comparaciones se prueban por separado.
- En un proceso vivo se conocen esos intervalos no evaluables; se registran como tales, no como paused. Un proceso muerto deja extremo desconocido según Área 04.

La espera acotada hasta Gmax es una convención de vigencia del estado, no una observación nueva ni tiempo adicional de C. Documentar precisión del scheduler: límite de reacción propuesto ≤100 ms desde vencimiento de watchdog en equipo compatible; la UI cumple RF14.CA3 después de la decisión.

Si la recepción es continua pero captureAge crece, no se acepta una cola atrasada como monitoreo actual. Heartbeat de Flutter cada 1000 ms y timeout UI de 3000 ms pertenecen al Área 04 y no sustituyen Gmax/Tstale.

## 10. Krecover y preparación para decidir

Después de pérdida, pausa, inicio de nueva generación o error, crear un measurementSegmentId nuevo y descartar todo buffer temporal anterior.

Krecover candidato exige ≥1000 ms entre primera y última captura válida, ≥6 muestras, cada gap≤150 ms, Q válida en todas y sin watchdog de recepción vencido. Una inválida/gap reinicia la adquisición. Antes de cumplirlo: initializing o limited y notEvaluable; no advertencia ni RF12.

Al cumplirlo: usable. C comienza desde la muestra de habilitación con duración cero; no incorpora el cierre acumulado durante recuperación. W reconstruye su ventana desde ese límite. Esta decisión añade espera al primer cierre después de pérdida; se mide como latencia extremo a extremo y no se oculta al reportar solo decisión→sonido.

Reanudar sigue paused hasta comprobar cámara/modelo/referencia y Krecover; luego conserva sessionId y cierra una sola pausa. La adquisición previa a confirmación no suma tiempo de sesión evaluable. En preparación se puede comprobar calidad, pero startSession descarta tramos oculares de preparación.

## 11. Tclose y regla de cierre prolongado

H(t)=usable AND C(t) AND closedRunDurationMs≥Tclose.

Al pasar H falsa→verdadera, emitir prolongedEyeClosure con motivo Cierre ocular prolongado, evidencia temporal, ID de episodio y versión. No exigir apertura de boca, parpadeos previos ni una ventana W completa. El sonido se solicita desde Kotlin y su inicio se mide frente a decisión; meta ≤500 ms de RF12.

Ejemplo de fixture con Q usable ya establecida y muestras cada 100 ms: C verdadera desde captura t=0 hasta t=1400 → no H; nueva captura válida cerrada t=1500 → H. Insertar Q inválida en t=800 impide usar los 800 ms previos; el tramo posterior parte de cero después de Krecover. Un resultado sin bostezo da el mismo resultado.

Si C pasa a falsa, H pasa a falsa; no sostener la etiqueta de cierre actual mediante una animación, timer o requisito de reconocimiento por el conductor. El episodio puede seguir pendiente de cierre Eend. No hay botón para reconocer alertas durante monitoreo.

## 12. W: advertencia por acumulación ocular

Nombre de métrica interna: closedTimeRatio; nombre explicativo: proporción temporal de cierre según regla ocular. No se denomina PERCLOS validado. La referencia FHWA describe medición de párpado sobre pupila y cierres lentos con criterios propios [S4]; un EAR normalizado no es equivalente.

Window(t)=[t−30000,t] dentro del segmento actual, después de usable. Requiere 30000 ms completos, todos los spans sin cortes y coverage=1,00. La proporción se calcula como suma de duración de spans C/C dividida por duración observable de ventana; recortar spans exactamente en sus límites. No usar conteo de frames.

Un closedRun completo es un tramo C con duración≥200 ms que termina con Open comprobada, sin pérdida de observación; una banda intermedia o pérdida que impide comprobar reapertura no fabrica un parpadeo. Al pasar C a falsa en la banda, conservar el último tramo como pendiente de reapertura, sin extender su duración; Open lo completa. Una nueva C antes de Open descarta ese candidato pendiente y empieza otro tramo. Pérdida/gap/pausa descartan pendientes. Para minClosedRuns, contar tramos completos con inicio y reapertura dentro de la ventana; no contar uno que se prolonga por el borde.

Entrada W: windowReady AND ratio≥0,20 AND completedClosedRuns≥3 durante ≥500 ms, con Q/recepción vigentes. Al cumplirse, W=true y emitir warning con motivo Cierres oculares acumulados. Mientras W activa, mantenerla hasta ratio≤0,10; no crear nuevas entradas en cada frame. Pérdida/pausa invalidan W inmediatamente y cortan el episodio por observación, no prueban que el patrón haya desaparecido.

La cuenta de tramos se exige al entrar; la salida usa ratio y corte. Esto es histéresis explícita. Un único cierre largo puede activar H, pero no W por sí solo. Una conversación o un bostezo con ojos abiertos no cumple W ni H; una expresión que realmente cause cierres debe anotarse como señal visible y analizarse como posible falsa alarma de interpretación, no ocultarse.

Antes de tener ventana W completa se pueden evaluar H y C; W tiene warningWindowReady=false. El estado Sin señales persistentes se refiere a las reglas disponibles, con esa limitación documentada; no afirma que se haya descartado una acumulación en 30 s todavía no observados. La UI no añade gráficos ni porcentajes de fatiga.

Fixture positivo candidato: Q válida y muestras cada 100 ms durante ≥30500 ms; seis bloques cerrados con puntos extremos en [5000,6000], [8000,9000], [11000,12000], [14000,15000], [17000,18000], [20000,21000], reapertura entre bloques. Los spans C/C suman 6000 ms dentro de 30000; ratio=0,20 y ningún tramo llega a 1500. Entrada W tras 500 ms de condición completa → t=30500. El generador debe declarar timestamps/ratios exactos para que no dependa de la intención textual del caso.

## 13. Episodios, Eend y Rrepeat

El episodio es una unidad observacional del motor, no un diagnóstico ni cada reproducción de sonido. Apertura cuando H o W entran y no hay episodio abierto. Mantener ID cuando persiste señal, cuando una advertencia escala a H o cuando hay una reapertura breve menor que Eend.

Signal actual: H tiene precedencia; si H falsa y W verdadera, warning; si ambas falsas y Q usable, noPersistentSignals. El historial conserva categoría inicial, transiciones y categoría máxima; no cambia retroactivamente una advertencia inicial por una nueva categoría sin registro.

Eend normal: H=false, W=false y Open=true continuamente por 2000 ms, con Q válida y gaps≤Gmax. Una banda intermedia reinicia contador Eend. Al cumplirlo, guardar fin confirmado de episodio al timestamp de decisión del cierre, además de última señal observada. Una nueva activación posterior crea otro ID.

Pérdida de Q, pausa, fin de sesión o muerte del proceso cortan el seguimiento. Registrar endReason=observationLost/paused/sessionStopped/processInterrupted y observedThroughOffsetMs; mantener signalEndOffsetMs=null cuando no se comprobó Eend. No afirmar que el ojo se abrió en el corte ni mostrar duración fisiológica cero. El episodio siguiente pertenece a nuevo segmento y tiene ID nuevo; no fusionar automáticamente dos episodios a través de un hueco.

Rrepeat: mientras la categoría sigue realmente activa y existe Q usable, warning repite como mínimo cada 15000 ms y H cada 5000 ms desde último intento de dispatch de esa categoría. Fallo de sonido también consume el intento para evitar una petición por frame; se informa fallo y no éxito. No repetir estando paused/notEvaluable.

Cada entrada nueva de H desde otra señal solicita aviso inmediato, aunque el periodo de warning no venciera. La escalada registra transición en el mismo episodio. Una señal H continua repite solo por Rrepeat; no por cada resultado. Si H vuelve tras una reapertura breve dentro del mismo episodio, registrar nueva activación y aviso inmediato; evaluar este patrón frente a molestia/duplicación percibida.

Cada intento tiene playbackId, ordinal, categoría, motivo, decisión/request/start/end monotónicos y estado técnico. No sumar reproducciones al conteo de episodios. No inferir audibilidad en cabina ni adaptación de umbrales a partir de feedback.

## 14. Bostezo, postura y otras señales

| Observación | Uso V1 | Condición para incorporarla después |
|---|---|---|
| Apertura bucal | Variable de investigación opcional; no dispara alerta | Fórmula, etiquetas de hablar/bostezar/cantar/comer, falsos positivos y evaluación |
| Giro/inclinación | Calidad y aplicabilidad de referencia | Separar mirar espejos de señal de somnolencia con protocolo propio |
| Frecuencia de parpadeo | No se declara medida válida hasta verificar resolución temporal | Anotación, sensibilidad a duración/gaps y error de conteo |
| Blendshapes | Desactivados en baseline | Comparación con apertura geométrica y coste de inferencia |
| Clasificador temporal aprendido | Evolución | Datos/licencias/etiquetas, split por persona y comparación con baseline |

No se añaden condiciones a RF12 que obliguen a esperar estas señales. Una app completa puede tener una política inicial acotada y evaluada; no necesita múltiples señales no verificadas para aparentar más IA.

## 15. Plan de selección de parámetros

Orden experimental, usando solo desarrollo/validación:

1. Verificar relojes, índices, geometría y comportamiento de generación con fixtures.
2. Comparar modos de captura/delegate; conservar configuraciones que cumplen recursos y resolución temporal.
3. Evaluar Q contra visibilidad humana, incluyendo ojos cerrados válidos y oclusiones; añadir EyeVisibilityGate si falla.
4. Ajustar Kcal, thetaClosed/thetaOpen y postura por persona/condición, sin tocar test.
5. Comparar Tclose/Gmax/Tstale/Krecover y efecto sobre pérdidas/latencia.
6. Comparar W/Eend/Rrepeat y revisar tasa de episodios, alertas repetidas y comprensión.
7. Congelar configuración final de candidata, manifestos y protocolo antes de abrir test.

Espacio inicial de búsqueda propuesto, no combinación cartesiana exhaustiva:

| Parámetro | Valores a comparar |
|---|---|
| minEyeWidthPx | 20, 24, 32 |
| minSharpness | 15, 30, 60 bajo el mismo preprocesado |
| maxPoseDeltaDeg | 15, 25, 35 |
| thetaClosed | 0,40; 0,55; 0,65 |
| thetaOpen | 0,70; 0,75; 0,85, siempre >thetaClosed |
| TcloseMs | 1000, 1500, 2000 |
| GmaxMs | 100, 150, 250 |
| TstaleMs | 500, 750, 1000, siempre >Gmax |
| KrecoverMs | 500, 1000, 1500 |
| W windowMs | 15000, 30000, 60000 |
| W thetaEntry | 0,15; 0,20; 0,25 |

Los parámetros no listados se mantienen en el candidato inicial hasta un fallo documentado. Cambiar la fórmula, tamaño ROI o gate produce qualityConfigVersion nueva. Evitar ajustar para una sola cara/dispositivo y publicar el valor como general.

Selección lexicográfica: descartar configuraciones que fallan privacidad/invariantes/Q; después exigir metas de sensibilidad/falsas alertas/latencia/cobertura de validación; entre candidatas que pasan, elegir menor tasa falsa alta, luego mayor cobertura y menor consumo. Si ninguna pasa, no seleccionar por “la menos mala” como aceptada: conservar experimental y revisar modelo/calidad/datos.

Cambiar Tclose, ventana W o política afecta qué patrón detecta la app. Mantener un benchmark de referencia fijo para comparar versiones; no redefinir las etiquetas después de ver errores.

## 16. Datos y protocolo de anotación

V1 no guarda imágenes. Investigación requiere captura separada y explícita con consentimiento, finalidad, acceso restringido, retención y retirada definidos antes de recogerla. Este documento especifica el protocolo, no confirma autorizaciones ni participantes reclutados.

Sesión de investigación: participantCode pseudónimo, recordingId, dispositivo/cámara, resolución/fps reales, orientación, condiciones de luz y gafas reportadas, montaje, timestamps, consentimiento/protocolVersion y split. Identidad/contacto se conserva fuera del dataset de trabajo y de Git. No guardar nombres en filenames.

No inducir sueño ni privación de sueño para esta fase. Cierres voluntarios y tareas negativas se realizan sentado o con vehículo detenido, sin conducción. El uso en movimiento requiere otra fase supervisada; sus resultados no se presumen aquí.

### 16.1 Etiquetas independientes del detector

Dos anotadores revisan video sin EAR, ratios, decisiones ni overlays del modelo. Un tercero resuelve discrepancias. La instrucción dada al participante no es ground truth: se etiqueta lo visible.

| Etiqueta | Criterio observable |
|---|---|
| eyeRVisible / eyeLVisible | Contorno y estado ocular distinguibles por imagen |
| open / partial / closed / unknown por ojo | Closed: cubrimiento visual estimado ≥80 % de pupila; uncertain→unknown, no deducir de EAR |
| faceCount / faceVisible | Rostros visibles en imagen, sin identificar personas |
| occlusion / glare / underexposure / motionBlur | Motivo de no interpretación visual |
| actionContext | Hablar, mirar lateralmente, parpadear, cierre voluntario, otro; separado de estado ocular |
| boundary | Primer/último frame de condición, con incertidumbre en ms |

La anotación de 80 % es una definición de referencia visible del estudio, inspirada en medición ocular [S4]; no se supone que humanos la estimen perfectamente. Imágenes en que no puede apreciarse pupila/párpado se marcan unknown. No usar ausencia de landmarks para definir automáticamente esa etiqueta.

Anotar a fps original los límites oculares; cada límite incluye resolución temporal. Para clips negativos largos, revisión completa y marcas de todos los candidatos oculares, no solo ventanas donde el sistema alertó. Segunda revisión independiente de todos los positivos y de al menos 20 % de tiempo negativo seleccionada antes de correr el detector. Revisar desacuerdos y documentar el resto con su nivel de revisión.

Exigir acuerdo≥90 % en estados open/partial/closed sobre frames muestreados y mediana de diferencia de límites≤100 ms, como meta de anotación propuesta. Si falla, revisar instrucciones/imagen y repetir; no llamar exactas las etiquetas. Guardar originales de cada anotador y consenso.

### 16.2 Referencia de eventos del benchmark

Benchmark ref-eye-events-v1 se fija antes de test:

- Evento alto: cierre bilateral visible continuo≥1500 ms, sin tramo unknown. Tiempo eligibleAt=inicioVisible+1500 ms. No se etiqueta como microsueño ni sueño fisiológico.
- Advertencia de referencia: ventana de 30000 ms completamente anotable con ≥20 % de tiempo bilateral closed y ≥3 tramos de al menos 200 ms con reapertura, persistente 500 ms. Se deriva de etiquetas humanas, no de salidas MediaPipe.
- Un evento de referencia mantiene ID hasta ambos criterios falsos y apertura bilateral por 2000 ms. Escalada pertenece al mismo evento con transiciones por categoría.
- Hueco unknown corta la referencia y conserva extremo incierto. No unir mediante interpolación escenas ocultan ojos.

Este benchmark verifica percepción de señales y política definidas. Que coincida con las condiciones candidatas no demuestra que esos límites representen fatiga; la referencia física es independiente del EAR, pero la definición temporal es una elección del proyecto. Comparaciones de otras duraciones conservan el benchmark y reportan la diferencia de objetivo.

## 17. Población, particiones y tamaños propuestos

### Fase A: viabilidad

Seis adultos voluntarios, al menos dos dispositivos disponibles, condiciones controladas; 10 cierres y 10 controles por participante/dispositivo utilizado. Sirve para detectar fallos de Q, índice, resolución y calibración. No aporta aceptación comercial ni se mezclará como test final si se usó para ajustar.

### Fase B: piloto de señales visibles

Propuesta de 30 participantes adultos: 15 desarrollo, 5 validación, 10 test. Asignación por persona antes del análisis; todas sus sesiones/dispositivos/frames permanecen en el mismo split. No repartir fotogramas contiguos entre entrenamiento y prueba.

Selección buscará diversidad de morfología ocular, presentación facial/tonos de piel y uso de gafas transparentes, sin afirmar representatividad estadística. Registrar distribución real y faltantes. No inferir atributos sensibles automáticamente de las imágenes.

Test congelado exige:

- Al menos 60 episodios de cierre de referencia y 60 advertencias de referencia; al menos 6 de cada categoría por participante. Transiciones dentro de un mismo episodio no se convierten en 2 episodios independientes.
- Al menos 20 h de tiempo negativo **evaluable** anotado en total, distribuido con ≥1 h por persona. Registrar también tiempo de grabación total, no evaluable y unknown. Si no se reúne el tiempo, el resultado queda insuficiente.
- Condiciones candidatas soportadas con al menos 10 eventos por categoría y ≥2 h negativas por condición. Los eventos pueden agruparse por condiciones declaradas, pero no se inventa independencia entre repeticiones de una misma persona.
- Todos los escenarios de invalidación tienen clips específicos; no se compensan con muchos frames fáciles.

Estas cantidades son objetivos de un piloto, no un cálculo de potencia para validación fisiológica. Su viabilidad y calendario se concretan antes del reclutamiento. Un piloto menor puede producir resultados exploratorios, pero no se rebaja el mínimo silenciosamente para marcar aceptación.

Guardar participant-split.json con hashes y protocolo; las sesiones de calibración de personas de test pueden crear su referencia individual sin modificar umbrales globales. No reutilizar etiquetas/errores de test para afinar: una revisión necesita nueva versión y nuevo conjunto de test independiente.

## 18. Matriz de escenarios

| ID | Escenario | Resultado que debe comprobarse |
|---|---|---|
| SC01 | Frontal, luz uniforme, sin gafas | Calibración y detección de referencia |
| SC02 | Gafas transparentes sin reflejo ocultante | Igual objetivo; resultados separados |
| SC03 | Luz ambiental reducida pero ojos humanos anotables | Q y cobertura medidas; soporte solo si pasa |
| SC04 | Vibración/movimientos pequeños controlados | Sin unión de gaps ni falsas decisiones por tracking |
| SC05 | Parpadeos cortos y guiños | No RF12; W solo si cumple patrón real definido |
| SC06 | Hablar, cantar o apertura bucal aislada | Boca no dispara; evaluar cierres oculares visibles si ocurren |
| SC07 | Mirada lateral / hacia espejo simulado | No somnolencia por pose; fuera de referencia→No evaluable |
| SC08 | Gafas oscuras, mano oclusora, reflejo que oculta ojo | No medición ocular utilizable; prueba del EyeVisibilityGate |
| SC09 | Rostro ausente, cámara cubierta, oscuridad | No disponible/no evaluable, sin normalidad ficticia |
| SC10 | Dos caras visibles dentro del encuadre | Ambigüedad; no selección automática |
| SC11 | Pérdida y retorno, frames atrasados/desordenados | Corte, watchdog, Krecover y ausencia de alerta antigua |
| SC12 | Pausa, permiso retirado, cierre de proceso | Contratos Área 04; sin entrenamiento ni captura automática |
| SC13 | Cierre real visible con buena imagen | Q no lo rechaza por párpados juntos |
| SC14 | Cambio de montaje declarado/modelo | Referencia no aplicable, inicio bloqueado |

SC01–SC04 son candidatas, no ya soportadas. Luz se registra con iluminación física si hay instrumento, exposición y stats ROI; no llamar lux a un promedio de píxeles. Vibración usa protocolo reproducible de montaje/amplitud si existe instrumento; no afirmar equivalencia a un vehículo por mover la mano.

SC08–SC10 no se aceptan con “el detector no funciona ahí” si muestran usable/noPersistentSignals. Se exige degradación visible correcta. Un dispositivo/condición no aprobados se identifican como no calificados, sin garantizar detección automática de todos los equipos incompatibles.

## 19. Emparejamiento y métricas

### 19.1 Emparejamiento determinista

Por recordingId y categoría: ordenar transiciones de referencia por eligibleAt. Para cada una, buscar activaciones del motor aún no asignadas en [eligibleAt−100 ms, eligibleAt+1000 ms]. Igualdad de extremos admite match. Elegir menor diferencia absoluta; empate por timestamp menor y luego ID lexicográfico. Una activación solo empareja una referencia.

La tolerancia de 100 ms contempla anotación; una alerta más temprana se contabiliza como temprana/no emparejada, no se presenta como anticipación fisiológica. Una más tardía que 1000 ms es tardía y cuenta FN para aceptación a tiempo; se conserva su detección tardía descriptiva. Reproducciones de un mismo episodio no son nuevas activaciones. Una escalada H es activación de categoría dentro de ese episodio, con su métrica separada.

Motor sin calidad usable en un evento físicamente anotable: FN en sensibilidad extremo a extremo, no excluirlo para mejorar resultado. Se informa sensibilidad condicional a calidad aparte. Segmento humano unknown no tiene etiqueta de señal fiable; excluirlo del denominador de detección, informar su duración y evaluar abstención.

En cruces entre warning y H, comparar cada categoría y también episodios únicos: evitar sumar dos TP de categoría como dos episodios físicos. Para precisión, toda activación no emparejada en tiempo anotable es FP, incluidas activaciones duplicadas o tardías dentro de un episodio positivo. Para tasa sobre exposición negativa, contar solo esos FP ocurridos en intervalos negativos y reportar además extras/duplicados en positivos. Activación en segmento unknown es no verificable y se reporta por separado.

### 19.2 Métricas obligatorias

| Métrica | Fórmula / reporte |
|---|---|
| Sensibilidad a tiempo | TP/(TP+FN), por categoría y extremo a extremo |
| Precisión | TP/(TP+FP) en segmentos anotables; indicar tempranas/tardías y segmentos no verificables |
| F1 | 2×precision×recall/(precision+recall); null si no definido |
| Falsas alertas/h evaluable negativa | FP ocurridos en referencia negativa / horas evaluables dentro de esa referencia negativa |
| Falsas alertas/h grabada negativa | FP ocurridos en referencia negativa / horas negativas conocidas, aunque Q rechace parte |
| Cobertura de producto | evaluableMs/(evaluableMs+nonEvaluableMs); fuera pausas/unknown |
| Cobertura frente a humanos | Tiempo usable del motor / tiempo visualmente anotable, alineado por relojes |
| Abstención correcta | Tiempo no evaluable sobre tiempo humano no interpretable |
| Rechazo de ojos cerrados válidos | Muestras cerradas anotables rechazadas por Q / muestras cerradas anotables |
| Error de duración | Error firmado/absoluto de tramos con ambos extremos confirmados |
| Latencia captura→resultado | p50/p95/p99; al menos 1000 resultados por modo/equipo |
| Latencia evento elegible→decisión | p50/p95/p99, incluyendo recuperación; FN/tardíos por separado |
| Latencia decisión→sonido | p50/p95/máximo y fallos; límite RF11/RF12 ≤500 ms |
| Episodios y repeticiones | IDs únicos, transiciones, intentos sonoros y errores separados |

Denominador cero: null/No disponible. No declarar 100 % de precisión cuando no hubo alertas. No usar exactitud por frame como métrica principal en un conjunto dominado por ojos abiertos.

Reportar métricas agregadas y por persona, dispositivo, condición, calidad y versión. Un resultado global no compensa una condición fallida que se pretende soportar. Mostrar distribución de tiempo rejected/unknown y no solo el subconjunto evaluable.

Intervalos: proporciones con intervalo Wilson 95 % como descriptivo binomial [S5]; registrar que episodios de una persona están correlacionados. Añadir bootstrap por participante, 2000 remuestreos, semilla registrada, percentiles 2,5/97,5 para métricas agregadas de tasas/cobertura/latencia; remuestrear todas las sesiones del participante juntas [S6]. No bootstrap de frames como si fueran personas independientes.

Con cero falsas alertas, bootstrap puede degenerar en [0,0]; no informar incertidumbre cero. Reportar exposición y límite superior unilateral de referencia −ln(0,05)/horas bajo una hipótesis Poisson explícita, sin asumir que esa hipótesis está probada. Resultados de muy pocos participantes/condiciones se identifican como exploratorios.

## 20. Criterios de aceptación propuestos del piloto

Estos límites son decisiones de ingeniería para evaluar señales visibles en el estudio, no límites publicados de seguridad vial. Se congelan antes de test. Ninguno se declara alcanzado en esta entrega.

| ID | Condición de aceptación | Evidencia |
|---|---|---|
| EV01 | Configuración/manifestos/hash del APK, modelo, datos, split, anotación y protocolo completos | Reporte reproducible; tres ejecuciones fixture coherentes |
| EV02 | Todos los fixtures de sección 21 pasan; cero alerta en pausa/no evaluable/generación vieja | Reporte unitario y de integración |
| EV03 | Calibraciones con datos aptos ≥90 % aceptadas; controles de rechazo nunca guardan accepted | Denominadores por condición y los tres códigos |
| EV04 | En condiciones calificadas: sensibilidad a tiempo H≥0,95 y precisión H≥0,90 | ≥60 referencias H y desglose por persona/condición |
| EV05 | Advertencia: sensibilidad≥0,85 y precisión≥0,85 | ≥60 referencias W y etiquetas físicas independientes |
| EV06 | FP H≤0,20/h y FP W≤1,00/h evaluable negativa | ≥20 h evaluables negativas; tasas por persona/condición |
| EV07 | Cobertura frente a humanos≥0,90 agregada y≥0,85 por condición declarada | Tiempo anotable, rechazado y evaluable publicados |
| EV08 | Rechazo de muestras cerradas válidas por Q≤5 % por condición | Referencia manual y causas de Q |
| EV09 | Oclusión/ausencia/fallo técnico: ninguna nueva activación H/W una vez invalidado; estado notEvaluable y causa | SC08–SC11, relojes, deadline de watchdog y UI |
| EV10 | p95 elegible→decisión≤1000 ms para eventos emparejados; todos los tardíos cuentan FN | No ocultar espera Krecover ni eventos perdidos |
| EV11 | Captura→resultado p95<200 ms; decisión→sonido≤500 ms; 60 min, memoria/UI según RNF02/RNF07/RNF09 | Equipos y modos concretos, profile/release |
| EV12 | Un ID por episodio, repetición exacta por política, ninguna dependencia de bostezo para H | Fixtures y videos de referencia |
| EV13 | Mínimos de participantes, eventos, exposición y calidad de anotación cumplidos | Inventario dataset; faltantes no rellenados |

EV09 no basta por sí sola para aceptar Q: también comparar momentos físicamente ocultos contra la invalidación real. Si el gate nunca invalida una oclusión plausible, falla SC08 aunque no se haya producido una alerta casualmente. La tasa de usable en frames humanos unknown por oclusión debe ser ≤5 % en cada escenario de oclusión probado; publicar el tiempo y casos restantes. En cada oclusión sostenida de prueba (>1000 ms), exigir invalidación del motor≤1000 ms desde el inicio visible anotado; después se verifica la reacción UI según RF14.CA3. Ninguna nueva activación de señal puede producirse durante el tramo ya invalidado.

Un modo pasa solo para condiciones/equipos con evidencia suficiente. Fallo → condición no calificada o revisión de política/gate; no mantener la etiqueta comercial con una nota pequeña. Estos criterios permiten aceptación de **piloto de señales**, no de uso universal ni eficacia para reducir accidentes.

Validación comercial/fisiológica sigue separada: protocolo supervisado, referencia independiente del estado de somnolencia, población representativa, tamaño calculado, límites por condición y evaluación de impacto/uso real. No se sustituye por cuestionario de feedback, cierres voluntarios o literatura sobre otro sensor.

## 21. Fixtures de frontera y fallos

Formato previsto en testdata/ai: fixtureId, fixtureVersion, profileId/hash, initialState, calibrationSnapshot, observations[] con timestampCapture/receipt, Q/rawGeometry o ratios sintéticos, acciones, expectedTransitions[], expectedEpisodes[], expectedDispatches[], expectedSpans[]. Modo ratios prueba política; modo geometría prueba fórmula/Q; ambos identificados. Ninguno se conecta a un build real.

| ID | Entrada / acción | Resultado exacto candidato |
|---|---|---|
| AI01 | Geometría vertical 6+6, horizontal20 px | EAR=0,30; división por0 o NaN→invalidGeometry |
| AI02 | Imagen640×480 y su escala uniforme2× | EAR idéntico dentro de tolerancia1e−9 en doubles sintéticos |
| AI03 | rR=rL=0,55 vs uno0,550001, Q válida | Primero C=true; segundo C=false |
| AI04 | C válido cada100 ms, t0..1400 vs t1500 | Sin H antes; activación única en1500 |
| AI05 | C válido sin boca/solo boca abierta | H idéntica sin bostezo; boca con ojos abiertos sin H/W |
| AI06 | Una muestra Q inválida entre cierres | C/ventanas cortadas; no suma tramos; Krecover obligatorio |
| AI07 | Gap capturas150 vs151 ms | Primero admite continuidad; segundo corta |
| AI08 | Silencio recepción150/151/750 ms | Sin vencimientoG a150; limited a151; unavailable a750, scheduler≤100 ms |
| AI09 | Resultado edad750 vs751 ms | 750 vigente; 751 rechazado; no alerta por cola vieja |
| AI10 | Krecover1000 ms con6+ válidas vs999 ms | Usable solo al cumplir ambos; nueva C desde ese límite |
| AI11 | Kcal60 muestras y cobertura0,80 vs59/0,799 | Primera pasa cantidad/cobertura si resto cumple; otras rechazan |
| AI12 | Cierre ocular visible con altura casi0 y ancho apto | Q no falla por exigir ojos abiertos; demostrar en geometría y video |
| AI13 | Comprobación cerrada sin separación/reapertura | unstableReference; no calibrationAccepted |
| AI14 | Dos caras, ROI fuera, blur/luz fuera de límites | Motivos tipados; notEvaluable; no referencia ni alerta aceptadas |
| AI15 | Seis bloques sección12 / ratio0,199999 / solo2 runs | W positiva a30500; controles no entran |
| AI16 | W activa ratio0,10 vs0,100001 | Primera sale; segunda mantiene si no hubo corte |
| AI17 | W pending499/500 ms | No entra a499; entra al primer resultado válido que completa500 |
| AI18 | W activa y H entra durante periodo de sonido W | Mismo episodeId, categoría máxima H, dispatch inmediato H |
| AI19 | H continua y sin audio iniciado | Intentos aentrada y +5000 ms como mínimo, no por frame; fallos no éxito |
| AI20 | H/W falsas y Open1999/2000 ms | Episodio no cierra a1999; cierre normal a2000 con observación válida |
| AI21 | Pérdida durante episodio / retorno | signalEnd null, corte observacional y nuevo segmento; no fusionar hueco |
| AI22 | Pausar durante C y presentar fixture que activa H | Cero nueva decisión/episodio/aviso durante pausa |
| AI23 | Callback de generación vieja tras stop/resume | Descarta; no toca calidad/señal/episodio actual |
| AI24 | Misma política con muestreo irregular≤Gmax | Duraciones por timestamps; no por nºframes |
| AI25 | Feed feedback“Útil”/“No percibí” | No cambia manifestos/umbrales ni señal histórica |
| AI26 | Muestra no interpretable con landmarks plausibles | Falla EyeVisibilityGate si usable; caso obligatorio de SC08 |
| AI27 | Primeros29999 ms de ventana W | W no lista; H continúa evaluable sin esperar W |
| AI28 | Reproducciones repetidas/3 imports del mismo journal | Episodios únicos; conteos no aumentan |

Fixtures frontera generan timestamps explícitos; los de 1 ms no dependen de que la cámara física capture a 1000 fps. Las tolerancias numéricas no se aplican a duraciones integer ni sustituyen operadores inclusivos. Comparaciones de proporción temporal usan duraciones enteras y umbrales decimales representados como fracciones racionales para evitar redondear un límite; EAR usa double sin redondeo de presentación antes de decidir. Para eventos con la misma hora, el fixture fija orden de entrada al actor; no depende del orden accidental de hilos. Los relojes falsos permiten probar deadline; el teléfono físico prueba scheduler/latencia real.

## 22. Informe, ficha del modelo y trazabilidad

Entregables de ejecución posterior:

| Archivo previsto | Contenido mínimo |
|---|---|
| ml/model-card.md | Propósito, modelo facial, procedencia/licencia, población/condiciones y límites |
| ml/policy-card.md | Fórmulas, parámetros, versiones, significado de episodios y qualificationStatus |
| ml/data-card.md | Procedencia, consentimiento/licencias, splits, etiquetas, exclusiones y retención |
| ml/protocol.md | Procedimiento físico, benchmark, escenarios, instrumentación y matching |
| ml/reports/report-ID.md | Resultados obtenidos/esperados, conteos, intervalos, errores y soportes concretos |
| testdata/ai/ | Fixtures de política/geometría con salida esperada y hashes |
| docs/decisions/ADR05-*.md | Cambios de señal/calidad/política y sus efectos |

No usar datos públicos hasta verificar licencia, finalidad, disponibilidad y correspondencia con cámara RGB de teléfono. Una cámara infrarroja dedicada, un dataset actuado o una licencia solo académica no habilitan automáticamente uso comercial. No se selecciona un dataset externo concreto en esta entrega.

| Requisito vigente | Especificación IA | Evidencia prevista |
|---|---|---|
| RF03, RF05 | Q, preparación y referencia | AI12/14/26, SC01–SC10 |
| RF06, RF07 | Kcal y compatibilidad/montaje | AI11/13; tres rechazos; manifestos |
| RF09 | Modelo local e inferencia física | APK offline, hash y timestamps |
| RF10 | Q y señal separadas | AI06/08/14; state snapshots |
| RF11 | W | AI15–AI18, EV05/06 |
| RF12 | C/Tclose sin bostezo | AI03–AI07, EV04/10 |
| RF13 | Eend/Rrepeat/episodio | AI18–AI21/28, EV12 |
| RF14 | Q/Gmax/Tstale | AI06–AI09/26, EV09 |
| RF15 | Krecover | AI06/10/21 |
| RF16, RF17 | Pausa y reconstrucción | AI22/23, contratos Área04 |
| RF21, RF23, RF25 | Duraciones/denominadores/versiones | Spans y episodios; fixtures DS01–DS04 del Área02 |
| RF24, RF29 | Feedback separado/política fija | AI25; manifiesto inmutable |
| RF32, RNF10 | Fixtures aislados de build real | Auditoría de wiring/assets |
| RNF01/02/04/07/08/09 | Offline, recursos, continuidad, reproducibilidad | EV01/11 y ensayos físicos del Área04 |

## 23. Qué queda cerrado y qué exige evidencia

Definidos en esta versión: señales iniciales, fórmulas y unidades, límites de Q candidata, proceso de calibración, reglas temporales y cortes, benchmark visible, emparejamiento, métricas, tamaños/particiones del piloto, metas de aceptación, fixtures y registro de resultados.

Pendientes de aceptación: selección de asset/licencia/versiones, teléfono y modo de captura, eficacia del EyeVisibilityGate, ajuste/congelación de parámetros, anotación y reclutamiento real, ejecución de fixtures/instrumentación, resultados del piloto y validación comercial/fisiológica. La especificación permite implementar y experimentar; no sustituye esos resultados.

Para empezar el ensayo técnico, registrar modelo/Android del teléfono disponible y si la materia exige entrenamiento de un modelo propio. Mientras no se confirme esto, conservar el baseline preentrenado más reglas sin afirmar que se entrenó IA propia. No es necesario retomar Claude Design para avanzar en esta definición.

Siguiente área de estructuración propuesta: **Área 06, modelo de datos y privacidad**. Convertirá las entidades de Área04 y la evidencia de Área05 en esquema, migraciones, columnas de exportación, operaciones de borrado/retención y reglas de backups. Después se consolida el plan de pruebas y backlog de implementación.

## 24. Fuentes primarias y alcance de uso

Consultadas el 03/10/2026. Los números candidatos y metas del piloto son propuestas de Vigía, no valores atribuidos a estas fuentes.

- **S1. Google.** [Face landmark detection guide for Android](https://developers.google.com/edge/mediapipe/solutions/vision/face_landmarker/android). API, salidas, configuración, timestamps y live stream. No validación de somnolencia.
- **S2. Soukupová, T., y Čech, J. (2016).** [Real-Time Eye Blink Detection using Facial Landmarks](https://vision.fe.uni-lj.si/cvww2016/proceedings/papers/05.pdf). 21st Computer Vision Winter Workshop. Fórmula EAR y detección temporal de parpadeo; nuestro mapeo/política tienen evaluación propia.
- **S3. Google AI Edge, repositorio oficial.** [face_mesh_connections.py](https://github.com/google-ai-edge/mediapipe/blob/master/mediapipe/python/solutions/face_mesh_connections.py). Contornos/índices para verificar el candidato ocular; fijar commit/esquema al implementar.
- **S4. Federal Highway Administration (1998).** [PERCLOS: A Valid Psychophysiological Measure of Alertness As Assessed by Psychomotor Vigilance](https://rosap.ntl.bts.gov/view/dot/113/dot_113_DS1.pdf). Referencia de medición ocular y evaluación experimental; no demuestra equivalencia de EAR ni fiabilidad de Vigía.
- **S5. NIST/SEMATECH.** [Confidence intervals](https://www.itl.nist.gov/div898/handbook/prc/section2/prc241.htm). Intervalos de proporciones; supuestos y dependencia de episodios se declaran.
- **S6. SciPy, documentación oficial.** [scipy.stats.bootstrap](https://docs.scipy.org/doc/scipy/reference/generated/scipy.stats.bootstrap.html). Herramienta de remuestreo; unidad participante elegida por protocolo Vigía. La documentación no valida nuestro tamaño de muestra.

No hay pruebas de detector ejecutadas ni participantes evaluados en esta entrega.
