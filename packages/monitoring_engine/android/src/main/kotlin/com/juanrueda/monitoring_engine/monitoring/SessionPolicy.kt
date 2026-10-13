package com.juanrueda.monitoring_engine.monitoring

/** Eje de medición (Área 04 §4.1). */
internal enum class Measurement { INITIALIZING, USABLE, LIMITED, UNAVAILABLE }

/** Eje de señal (Área 04 §4.1). La advertencia W no se implementa en 5C. */
internal enum class Signal { NOT_EVALUABLE, NO_PERSISTENT_SIGNALS, PROLONGED_EYE_CLOSURE }

/**
 * Política temporal de un segmento de medición (fase 5C), con el reloj
 * monotónico del proceso. Sin dependencias de Android.
 *
 * - **Krecover** (Área 05 §10): tras iniciar, reanudar o perder datos, hacen
 *   falta ≥1000 ms entre la primera y la última observación válida, ≥6
 *   muestras, todas válidas y con gaps ≤ Gmax. Antes: no evaluable.
 * - **C** (§5.2): rR ≤ thetaClosed y rL ≤ thetaClosed (igualdad cumple), con
 *   ratios respecto a la referencia de cada ojo. No se suaviza.
 * - **Tclose** (§9.1, §11): duración del tramo = marca actual − primera marca
 *   cerrada del tramo; spans con gap ≤ Gmax. H = usable ∧ C ∧ duración ≥
 *   Tclose. Al pasar H a verdadera se pide un aviso; mientras sigue, se
 *   repite cada Rrepeat (5000 ms) desde el último intento. Ningún temporizador
 *   prolonga el tramo sin una observación nueva.
 * - **Pérdida** (§9.2): Q inválida, gap > Gmax entre observaciones,
 *   silencio de recepción > Gmax (limited) o ≥ Tstale (unavailable), o la
 *   cámara cerrada cortan el tramo y exigen Krecover. **La pérdida de datos
 *   nunca equivale a ojos cerrados.**
 */
internal class SessionPolicy(
    private val reference: CalibrationReference,
    private val p: ExperimentalProfile = ExperimentalProfile,
) {
    var measurement = Measurement.INITIALIZING
        private set
    var signal = Signal.NOT_EVALUABLE
        private set

    /** Causa técnica de la última pérdida (código de [QReason] u otro). */
    var cause: String? = null
        private set

    /** Krecover: primera y última observación válida del tramo de recuperación. */
    private var recoverFirst: Long? = null
    private var recoverLast: Long? = null
    private var recoverCount = 0

    private var lastValidT: Long? = null
    private var lastReceivedNs: Long? = null
    private var lastObservationNs: Long? = null
    private var runStart: Long? = null
    private var runLast: Long? = null
    private var h = false
    private var lastDispatchNs: Long? = null

    /** Entradas de H (activaciones del cierre prolongado). */
    var activations = 0
        private set

    /** Duración del tramo cerrado en curso (ms), o nulo. */
    val closedRunMs: Long?
        get() {
            val s = runStart ?: return null
            val l = runLast ?: return null
            return (l - s) / 1_000_000
        }

    val usable: Boolean get() = measurement == Measurement.USABLE

    /**
     * Procesa una observación. Devuelve `true` si hay que pedir un aviso de
     * cierre prolongado ahora ([nowNs] es la decisión).
     */
    fun onObservation(input: EyeObservation, nowNs: Long): Boolean {
        // El callback puede adelantarse al tick: no borra un silencio vencido.
        tick(nowNs)
        val o = input.checkedAt(nowNs)
        lastReceivedNs = o.receivedNs
        lastObservationNs = o.tNs
        if (!o.valid) {
            val r = o.reasons.firstOrNull() ?: QReason.INVALID_GEOMETRY
            lose(
                if (r == QReason.NO_FACE || r == QReason.AMBIGUOUS_FACE || r == QReason.STALE_RESULT) {
                    Measurement.UNAVAILABLE
                } else {
                    Measurement.LIMITED
                },
                r.code,
            )
            return false
        }
        val prev = lastValidT
        lastValidT = o.tNs
        val gap = if (prev == null) null else o.tNs - prev
        if (gap != null && (gap <= 0 || gap > ns(p.G_MAX_MS))) {
            // Gap: la observación no se une a lo anterior; empieza otra recuperación.
            lose(Measurement.LIMITED, if (gap <= 0) QReason.INVALID_TIMESTAMP.code else "gap")
            lastValidT = o.tNs
        }
        if (!usable) {
            if (recoverFirst == null) recoverFirst = o.tNs
            recoverLast = o.tNs
            recoverCount++
            val first = recoverFirst!!
            if (recoverCount >= p.RECOVER_MIN_SAMPLES && o.tNs - first >= ns(p.RECOVER_MIN_DURATION_MS)) {
                measurement = Measurement.USABLE
                signal = Signal.NO_PERSISTENT_SIGNALS
                cause = null
                // C empieza en esta muestra con duración cero (§10).
            } else {
                return false
            }
        }
        return evaluate(o, nowNs)
    }

    private fun evaluate(o: EyeObservation, nowNs: Long): Boolean {
        val rR = o.earRight!! / reference.openEarRight
        val rL = o.earLeft!! / reference.openEarLeft
        val closed = rR <= p.THETA_CLOSED && rL <= p.THETA_CLOSED
        if (!closed) {
            runStart = null
            runLast = null
            h = false
            signal = Signal.NO_PERSISTENT_SIGNALS
            return false
        }
        if (runStart == null) runStart = o.tNs
        runLast = o.tNs
        val dur = o.tNs - runStart!!
        if (dur < ns(p.T_CLOSE_MS)) return false
        signal = Signal.PROLONGED_EYE_CLOSURE
        if (!h) {
            h = true
            activations++
            lastDispatchNs = nowNs
            return true
        }
        val last = lastDispatchNs
        if (last == null || nowNs - last >= ns(p.REPEAT_PROLONGED_MS)) {
            lastDispatchNs = nowNs
            return true
        }
        return false
    }

    /** Vigilancia de recepción en [nowNs] (Área 05 §9.2). */
    fun tick(nowNs: Long) {
        val last = lastReceivedNs ?: return
        val silence = nowNs - last
        if (silence >= ns(p.T_STALE_MS) || lastObservationNs?.let { nowNs - it > ns(p.T_STALE_MS) } == true) {
            if (measurement != Measurement.UNAVAILABLE) lose(Measurement.UNAVAILABLE, "noResults")
        } else if (silence > ns(p.G_MAX_MS)) {
            if (measurement == Measurement.USABLE || recoverFirst != null) lose(Measurement.LIMITED, "resultsDelayed")
        }
    }

    /** La cámara se cerró o no hay análisis: no hay observaciones. */
    fun cameraLost() {
        lose(Measurement.UNAVAILABLE, "cameraClosed")
        lastReceivedNs = null
        lastObservationNs = null
    }

    private fun lose(m: Measurement, why: String) {
        measurement = m
        signal = Signal.NOT_EVALUABLE
        cause = why
        recoverFirst = null
        recoverLast = null
        recoverCount = 0
        runStart = null
        runLast = null
        h = false
        lastValidT = null
    }

    private fun ns(ms: Long) = ms * 1_000_000
}
