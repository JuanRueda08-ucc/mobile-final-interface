package com.juanrueda.monitoring_engine.face

import com.juanrueda.monitoring_engine.monitoring.EyeGeometry
import com.juanrueda.monitoring_engine.monitoring.EyeObservation
import com.juanrueda.monitoring_engine.monitoring.QReason
import java.nio.ByteBuffer

/** Estado del análisis de presencia facial (espejo de `FaceAnalysisStatus` de Pigeon). */
internal enum class FacePresenceStatus {
    LOADING_MODEL,
    WAITING_RESULTS,
    NO_FACE,
    ONE_FACE,
    MULTIPLE_FACES,
    STOPPED,
    MODEL_ERROR,
    ANALYSIS_ERROR,
    ;

    /** Hay un detector listo que acepta cuadros. */
    val acceptsFrames: Boolean get() = this == WAITING_RESULTS || isDetection

    /** Resultado vigente (sujeto a caducidad). */
    val isDetection: Boolean get() = this == NO_FACE || this == ONE_FACE || this == MULTIPLE_FACES
}

/** Resultado compacto que sale del motor: sin imágenes ni puntos faciales. */
internal data class FacePresence(
    val token: Long,
    /** Orden de publicación dentro de la apertura: estrictamente creciente. */
    val sequence: Long,
    val generation: Long,
    val status: FacePresenceStatus,
    val faceCount: Int?,
    /**
     * Identidad de la inferencia que se informa (única en la apertura); nula
     * sin resultado vigente. Un latido repite el mismo valor: no es un
     * resultado nuevo.
     */
    val resultId: Long?,
    /**
     * Edad del resultado **al crear este mensaje**: reloj monotónico de ese
     * instante menos la entrega de su cuadro al analizador. No se congela.
     */
    val resultAgeMs: Long?,
    val maxFaces: Int,
    val staleAfterMs: Long,
    val framesSubmitted: Long,
    val resultsAccepted: Long,
    val framesDropped: Long,
    val resultsDiscarded: Long,
    val expired: Boolean,
    val frameWidth: Int?,
    val frameHeight: Int?,
    val frameRotationDegrees: Int?,
    val errorCode: String?,
)

/**
 * Tiempos de vigencia (fase 5B).
 *
 * - [STALE_AFTER_MS]: Tstale = 750 ms, valor **candidato y experimental** del
 *   perfil `lab-eye-rules-0.1` (Área 05 §7, `qualificationStatus=experimental`).
 *   No es un valor aceptado de producción.
 * - [TICK_MS]: periodo del vigilante; acota a ≤100 ms la reacción tras vencer
 *   Tstale (límite propuesto en Área 05 §9.2).
 * - [HEARTBEAT_MS]: latido hacia Flutter cada 1000 ms (propuesta de transporte
 *   de Área 04 §9); no sustituye a Tstale.
 */
internal object FaceTiming {
    const val STALE_AFTER_MS = 750L
    const val TICK_MS = 100L
    const val HEARTBEAT_MS = 1000L
    const val PENDING_FRAMES_MAX = 8
}

/** Detector de rostros sobre cuadros de tipo [F] (en Android, `Bitmap`). */
internal interface FaceEngine<F> {
    /**
     * Envía [frame] al detector y vuelve sin esperar el resultado. El llamador
     * conserva la propiedad de [frame] y puede liberarlo al volver: la
     * implementación copia los datos antes de volver.
     */
    fun detectAsync(frame: F, rotationDegrees: Int, timestampMs: Long)

    /** Libera el detector. Tras volver no se entregan más resultados útiles. */
    fun close()
}

/** Avisos del detector; pueden llegar en cualquier hilo. */
internal interface FaceEngineListener {
    /**
     * [points]: con exactamente un rostro, sus puntos normalizados (x0, y0,
     * x1, y1, …) respecto al cuadro entregado; si no, nulo. Fase 5C: solo
     * se usan para medir los ojos en Kotlin y no se conservan.
     */
    fun onResult(timestampMs: Long, faceCount: Int, points: FloatArray? = null)
    fun onError(code: String)
}

/**
 * Lógica del análisis de presencia facial de **una** apertura de cámara.
 * Sin dependencias de Android para probarla en la JVM con dobles.
 *
 * **Hilo.** Todos los métodos públicos se llaman en el hilo de análisis de la
 * apertura. Los avisos del detector llegan en el hilo de MediaPipe y se pasan
 * al hilo de análisis con [post]; la hora del hilo de MediaPipe solo sirve
 * para comprobar el orden de las marcas.
 *
 * **Identidad.** Cada carga del modelo es una generación. Un aviso de otra
 * generación, o posterior a [stop], se descarta sin tocar el estado.
 *
 * **Vigencia.** «Sin rostro», «un rostro» y «varios rostros» solo se informan
 * con un resultado explícito del detector. La falta de resultados no es
 * ausencia de rostro: sin resultados durante Tstale ([staleAfterNs]) el estado
 * vuelve a «esperando resultados» con `expired`.
 *
 * La edad de un resultado es siempre `ahora − entrega de su cuadro al
 * analizador`, con el reloj monotónico del instante en que se usa:
 * - al **aplicarlo** en el hilo de análisis (incluye la espera del aviso en
 *   la cola): si supera Tstale, se descarta;
 * - al **crear cada mensaje** (cambio, latido o consulta) y al **leer el
 *   estado**: si el resultado vigente ya tiene edad > Tstale, o silencio
 *   ≥ Tstale desde su aplicación, se retira antes, sin esperar al vigilante.
 *   Así ningún mensaje anuncia como vigente un resultado caducado, y
 *   `resultAgeMs` es la edad en ese instante, no la de la aceptación.
 *
 * Una marca imposible (entrega posterior a la recepción o a ahora) se
 * descarta como inválida, no como edad cero. Igualdad de edad con Tstale
 * sigue vigente; igualdad de silencio caduca (Área 05 §9.2).
 *
 * **Un cuadro cada vez.** No se envía otro cuadro mientras el anterior no
 * tenga resultado: así ninguno espera en la cola de MediaPipe y la edad del
 * resultado es la de su inferencia. Si el resultado no llega en Tstale, se
 * deja de esperarlo (MediaPipe pudo descartar el cuadro) y se envía otro.
 */
internal class FaceAnalysisCore<F>(
    private val token: Long,
    private val loadModel: () -> ModelLoad,
    private val createEngine: (ByteBuffer, FaceEngineListener) -> FaceEngine<F>,
    private val post: (Runnable) -> Unit,
    private val clockNs: () -> Long,
    private val publish: (FacePresence) -> Unit,
    private val staleAfterNs: Long = FaceTiming.STALE_AFTER_MS * 1_000_000,
    private val heartbeatNs: Long = FaceTiming.HEARTBEAT_MS * 1_000_000,
    private val maxFaces: Int = FaceModelSpec.MAX_FACES,
    /**
     * Fase 5C: cada resultado aplicado (o descartado por antiguo o por marca
     * imposible) se entrega como observación ocular compacta al coordinador.
     */
    private val observe: (EyeObservation) -> Unit = {},
) {
    private var current = FacePresenceStatus.LOADING_MODEL

    /** Estado vigente; antes de leerlo se retira un resultado caducado. */
    val status: FacePresenceStatus
        get() {
            refreshVigencia(clockNs())
            return current
        }
    var generation = 0L
        private set

    private var stopped = false
    private var engine: FaceEngine<F>? = null
    private var errorCode: String? = null

    /** Cuadros enviados y aún sin resultado: marca de tiempo → entrega (ns). */
    private val pending = LinkedHashMap<Long, Long>()
    private var lastSubmittedTs = Long.MIN_VALUE

    /** Cuadro enviado y aún sin resultado, y su entrega (ns). */
    private var inFlightTs: Long? = null
    private var inFlightEntryNs = 0L

    /** Diagnóstico: resultados descartados por superar Tstale y edad máxima aceptada. */
    var discardedTooOld = 0L
        private set
    var maxAcceptedAgeMs = 0L
        private set
    private var lastResultTs = Long.MIN_VALUE

    private var faceCount: Int? = null
    private var lastAcceptedEntryNs = 0L
    private var lastAcceptedAppliedNs = 0L
    private var resultId: Long? = null
    private var sequence = 0L

    /** Diagnóstico: resultados descartados por marcas de tiempo imposibles. */
    var discardedInvalidTime = 0L
        private set
    private var expired = false
    private var lastPublishNs = Long.MIN_VALUE

    private var framesSubmitted = 0L
    private var resultsAccepted = 0L
    private var framesDropped = 0L
    private var resultsDiscarded = 0L
    private var frameWidth: Int? = null
    private var frameHeight: Int? = null
    private var frameRotation: Int? = null

    /** Carga el modelo (generación nueva) y crea el detector. */
    fun start() {
        if (stopped) return
        generation++
        closeEngine()
        clearResult()
        pending.clear()
        inFlightTs = null
        lastResultTs = Long.MIN_VALUE
        errorCode = null
        setStatus(FacePresenceStatus.LOADING_MODEL)

        val load = try {
            loadModel()
        } catch (e: Throwable) {
            ModelLoad.Failed(FaceErrorCodes.MODEL_READ_FAILED)
        }
        when (load) {
            is ModelLoad.Failed -> return fail(FacePresenceStatus.MODEL_ERROR, load.code)
            is ModelLoad.Ready -> {
                val gen = generation
                val listener = object : FaceEngineListener {
                    override fun onResult(timestampMs: Long, faceCount: Int, points: FloatArray?) {
                        val receivedNs = clockNs()
                        post { onEngineResult(gen, timestampMs, faceCount, receivedNs, points) }
                    }

                    override fun onError(code: String) {
                        post { onEngineError(gen, code) }
                    }
                }
                engine = try {
                    createEngine(load.buffer, listener)
                } catch (e: Throwable) {
                    // Incluye UnsatisfiedLinkError (biblioteca nativa ausente).
                    return fail(FacePresenceStatus.MODEL_ERROR, FaceErrorCodes.MODEL_INCOMPATIBLE)
                }
                setStatus(FacePresenceStatus.WAITING_RESULTS)
            }
        }
    }

    /**
     * Reintenta tras un error de modelo o de inferencia. `false` (sin efecto)
     * en cualquier otro estado: no duplica un detector en marcha.
     */
    fun restart(): Boolean {
        if (stopped) return false
        if (status != FacePresenceStatus.MODEL_ERROR && status != FacePresenceStatus.ANALYSIS_ERROR) return false
        start()
        return true
    }

    /** Hay un detector listo: merece la pena convertir el siguiente cuadro. */
    val acceptsFrames: Boolean get() = !stopped && engine != null && current.acceptsFrames

    /** Cuadro descartado antes de convertirlo (sin detector listo o conversión fallida). */
    fun dropFrame() {
        framesDropped++
    }

    /**
     * Ofrece un cuadro entregado al analizador en [entryNs]. `true` si se
     * envió al detector. En cualquier caso el llamador libera [frame] al
     * volver.
     */
    fun submit(frame: F, rotationDegrees: Int, entryNs: Long, width: Int, height: Int): Boolean {
        val e = engine
        if (stopped || e == null || !current.acceptsFrames) {
            framesDropped++
            return false
        }
        if (inFlightTs != null && entryNs - inFlightEntryNs < staleAfterNs) {
            framesDropped++
            return false
        }
        val ts = entryNs / 1_000_000
        // MediaPipe exige marcas crecientes por instancia: no se reordenan.
        if (ts <= lastSubmittedTs) {
            framesDropped++
            return false
        }
        lastSubmittedTs = ts
        frameWidth = width
        frameHeight = height
        frameRotation = rotationDegrees
        pending[ts] = entryNs
        while (pending.size > FaceTiming.PENDING_FRAMES_MAX) pending.remove(pending.keys.first())
        inFlightTs = ts
        inFlightEntryNs = entryNs
        return try {
            e.detectAsync(frame, rotationDegrees, ts)
            framesSubmitted++
            true
        } catch (t: Throwable) {
            pending.remove(ts)
            inFlightTs = null
            fail(FacePresenceStatus.ANALYSIS_ERROR, FaceErrorCodes.INFERENCE_FAILED)
            false
        }
    }

    /** Vigilante periódico: caducidad y latido. */
    fun tick() {
        if (stopped) return
        val now = clockNs()
        if (refreshVigencia(now)) return
        if (isHeartbeatDue(now)) publishNow()
    }

    /**
     * Resultado compacto creado ahora, para responder a una consulta de
     * Flutter. Comparte la numeración de los mensajes (`sequence`) y no se
     * envía por el aviso. Antes de crearlo se retira un resultado caducado.
     */
    fun snapshotNow(): FacePresence {
        val now = clockNs()
        expireInPlace(now)
        return build(now)
    }

    /** El resultado vigente ya no lo es: edad > Tstale o silencio ≥ Tstale. */
    private fun isStale(now: Long): Boolean =
        current.isDetection &&
            (now - lastAcceptedEntryNs > staleAfterNs || now - lastAcceptedAppliedNs >= staleAfterNs)

    /** Retira un resultado caducado sin publicar. `true` si lo retiró. */
    private fun expireInPlace(now: Long): Boolean {
        if (stopped || !isStale(now)) return false
        clearResult()
        expired = true
        current = FacePresenceStatus.WAITING_RESULTS
        return true
    }

    /** Retira un resultado caducado y lo avisa. `true` si lo retiró. */
    private fun refreshVigencia(now: Long): Boolean {
        if (!expireInPlace(now)) return false
        publishNow()
        return true
    }

    /** Termina el análisis y libera el detector. Definitivo. */
    fun stop() {
        if (stopped) return
        stopped = true
        generation++
        closeEngine()
        pending.clear()
        inFlightTs = null
        clearResult()
        setStatus(FacePresenceStatus.STOPPED)
    }

    private fun onEngineResult(gen: Long, ts: Long, count: Int, receivedNs: Long, points: FloatArray? = null) {
        if (stopped || gen != generation || !current.acceptsFrames) return
        if (inFlightTs?.let { ts >= it } == true) inFlightTs = null
        val entryNs = pending[ts]
        // Los cuadros anteriores sin resultado ya no lo tendrán (el limitador
        // de MediaPipe los descartó).
        pending.keys.removeAll { it <= ts }
        if (entryNs == null || ts <= lastResultTs) {
            resultsDiscarded++
            return
        }
        lastResultTs = ts
        // Reloj actual: el aviso pudo esperar en la cola del hilo de análisis.
        val now = clockNs()
        if (entryNs > receivedNs || receivedNs > now) {
            resultsDiscarded++
            discardedInvalidTime++
            observe(EyeObservation.invalid(token, now, now, QReason.INVALID_TIMESTAMP))
            return
        }
        val age = now - entryNs
        if (age > staleAfterNs) {
            resultsDiscarded++
            discardedTooOld++
            observe(EyeObservation.invalid(token, entryNs, now, QReason.STALE_RESULT))
            return
        }
        maxAcceptedAgeMs = maxOf(maxAcceptedAgeMs, age / 1_000_000)
        expireInPlace(now)
        val previous = current to faceCount
        faceCount = count
        lastAcceptedEntryNs = entryNs
        lastAcceptedAppliedNs = now
        expired = false
        resultsAccepted++
        resultId = resultsAccepted
        val next = when {
            count <= 0 -> FacePresenceStatus.NO_FACE
            count == 1 -> FacePresenceStatus.ONE_FACE
            else -> FacePresenceStatus.MULTIPLE_FACES
        }
        current = next
        observe(EyeObservation.of(token, entryNs, now, count, measureEyes(count, points)))
        // Publica también cuando no cambia el estado: es un resultado nuevo
        // (otra identidad), no un latido.
        if (previous != (next to faceCount) || isHeartbeatDue(now)) publishNow()
    }

    /** Medición ocular en Kotlin (fase 5C); los puntos no se conservan. */
    private fun measureEyes(count: Int, points: FloatArray?): com.juanrueda.monitoring_engine.monitoring.EyeMeasurement? {
        if (count != 1 || points == null) return null
        val w = frameWidth ?: return null
        val h = frameHeight ?: return null
        // Escala según el tamaño entregado (sin intercambiar por el giro):
        // comprobado con MediaPipe real en `EyeMeasurementInstrumentedTest`
        // (misma EAR con la imagen derecha y girada 90°).
        return EyeGeometry.measure(points, w, h)
    }

    private fun onEngineError(gen: Long, code: String) {
        if (stopped || gen != generation) return
        fail(FacePresenceStatus.ANALYSIS_ERROR, code)
    }

    private fun fail(next: FacePresenceStatus, code: String) {
        closeEngine()
        pending.clear()
        inFlightTs = null
        clearResult()
        errorCode = code
        val now = clockNs()
        observe(EyeObservation.invalid(token, now, now, QReason.INFERENCE_ERROR))
        setStatus(next)
    }

    private fun isHeartbeatDue(now: Long) = lastPublishNs == Long.MIN_VALUE || now - lastPublishNs >= heartbeatNs

    private fun clearResult() {
        faceCount = null
        resultId = null
        expired = false
    }

    private fun closeEngine() {
        val e = engine ?: return
        engine = null
        try {
            e.close()
        } catch (t: Throwable) {
            // El detector ya no se usa; su fallo al cerrar no cambia el estado.
        }
    }

    private fun setStatus(next: FacePresenceStatus) {
        current = next
        publishNow()
    }

    /** Publica el estado creado ahora; antes retira un resultado caducado. */
    private fun publishNow() {
        val now = clockNs()
        expireInPlace(now)
        lastPublishNs = now
        publish(build(now))
    }

    private fun build(now: Long): FacePresence =
            FacePresence(
                token = token,
                sequence = ++sequence,
                generation = generation,
                status = current,
                faceCount = faceCount,
                resultId = resultId,
                resultAgeMs = if (current.isDetection) (now - lastAcceptedEntryNs) / 1_000_000 else null,
                maxFaces = maxFaces,
                staleAfterMs = staleAfterNs / 1_000_000,
                framesSubmitted = framesSubmitted,
                resultsAccepted = resultsAccepted,
                framesDropped = framesDropped,
                resultsDiscarded = resultsDiscarded,
                expired = expired,
                frameWidth = frameWidth,
                frameHeight = frameHeight,
                frameRotationDegrees = frameRotation,
                errorCode = errorCode,
            )
}
