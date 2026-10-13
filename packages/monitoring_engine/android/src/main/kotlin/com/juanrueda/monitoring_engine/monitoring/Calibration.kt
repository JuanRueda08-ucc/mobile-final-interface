package com.juanrueda.monitoring_engine.monitoring

import kotlin.math.abs
import kotlin.math.floor

/**
 * Observación del análisis facial que recibe el coordinador (fase 5C).
 *
 * [tNs] es la **entrega del cuadro al analizador** en el reloj monotónico
 * del proceso (`elapsedRealtimeNanos`), no la marca de captura del sensor:
 * la conversión captura→monotónico no se ha demostrado (Área 04 §5, Área 05
 * §4). Se usa como marca de la observación para spans y continuidad.
 * [receivedNs] es la recepción en el coordinador.
 */
internal data class EyeObservation(
    val token: Long,
    val tNs: Long,
    val receivedNs: Long,
    val faceCount: Int,
    val measurement: EyeMeasurement?,
    val reasons: Set<QReason>,
) {
    val valid: Boolean get() = reasons.isEmpty() && measurement?.valid == true
    val earRight: Double? get() = measurement?.earRight
    val earLeft: Double? get() = measurement?.earLeft

    /** Revalida al usar la observación, incluida cualquier espera por el cerrojo. */
    fun checkedAt(nowNs: Long): EyeObservation = when {
        tNs < 0 || receivedNs < tNs || nowNs < receivedNs ->
            invalid(token, tNs, nowNs, QReason.INVALID_TIMESTAMP)
        nowNs - tNs > ExperimentalProfile.T_STALE_MS * 1_000_000 ||
            nowNs - receivedNs >= ExperimentalProfile.T_STALE_MS * 1_000_000 ->
            invalid(token, tNs, nowNs, QReason.STALE_RESULT)
        else -> this
    }

    companion object {
        /** Construye la observación y sus motivos de Q a partir del resultado. */
        fun of(token: Long, tNs: Long, receivedNs: Long, faceCount: Int, m: EyeMeasurement?): EyeObservation {
            val reasons = when {
                faceCount <= 0 -> setOf(QReason.NO_FACE)
                faceCount > 1 -> setOf(QReason.AMBIGUOUS_FACE)
                m == null -> setOf(QReason.INVALID_GEOMETRY)
                else -> m.reasons
            }
            return EyeObservation(token, tNs, receivedNs, faceCount, if (faceCount == 1) m else null, reasons)
        }

        /** Resultado descartado (caducado o con marca imposible): rompe la continuidad. */
        fun invalid(token: Long, tNs: Long, receivedNs: Long, reason: QReason) =
            EyeObservation(token, tNs, receivedNs, 0, null, setOf(reason))
    }
}

/** Referencia aceptada (Área 04 §7.4, campos compactos). */
internal data class CalibrationReference(
    val calibrationId: String,
    val openEarRight: Double,
    val openEarLeft: Double,
    val openSamples: Int,
    val openCoverage: Double,
    val relativeMadRight: Double,
    val relativeMadLeft: Double,
    val probeRatios: List<Pair<Double, Double>>,
)

internal enum class CalibrationStep { OPEN_REFERENCE, CLOSE_LEAD_IN, CLOSED_PROBE, REOPEN }

internal enum class CalibrationRejection(val code: String) {
    INSUFFICIENT_OBSERVATIONS("insufficientObservations"),
    INVALID_EYE_QUALITY("invalidEyeQuality"),
    UNSTABLE_REFERENCE("unstableReference"),
}

internal sealed interface CalibrationOutcome {
    data class Accepted(val reference: CalibrationReference) : CalibrationOutcome

    /** [detail]: causa técnica concreta (diagnóstico, no texto de interfaz). */
    data class Rejected(val reason: CalibrationRejection, val detail: String) : CalibrationOutcome
}

/**
 * Kcal de un intento (Área 05 §8), guiado por el tiempo monotónico.
 *
 * 1. Referencia abierta durante 8000 ms: ≥60 muestras válidas, cobertura
 *    ≥0,80; openEAR de cada ojo = percentil 80 (interpolación lineal);
 *    openEAR en [0,10; 0,60] y relativeMAD ≤ 0,15 en cada ojo.
 * 2. Dos comprobaciones de cierre: aviso «Cierra los ojos» ([PROBE_LEAD_IN_MS],
 *    prototipo), 1000 ms de medición con ≥6 muestras válidas, cobertura
 *    ≥0,80 y mediana de ratio ≤0,50 en ambos ojos; luego reapertura
 *    comprobada: 2000 ms continuos con ambos ratios ≥0,75 y Q válida, dentro
 *    de [REOPEN_TIMEOUT_MS] (prototipo).
 *
 * Cobertura: suma de spans entre observaciones consecutivas con ambos
 * extremos válidos y 0 < gap ≤ Gmax, dividida por la duración del paso. Los
 * parpadeos espontáneos permanecen en la muestra. **Postura no comprobada**
 * (pendiente). Sin observación no se completa nada.
 */
internal class CalibrationRun(
    private val startNs: Long,
    private val newId: () -> String,
    private val p: ExperimentalProfile = ExperimentalProfile,
) {
    var step = CalibrationStep.OPEN_REFERENCE
        private set

    /** Comprobación de cierre en curso (1..2); 0 durante la referencia. */
    var probe = 0
        private set
    var stepStartNs = startNs
        private set

    private val samples = mutableListOf<EyeObservation>()
    private var openR = 0.0
    private var openL = 0.0
    private var openCount = 0
    private var openCoverage = 0.0
    private var madR = 0.0
    private var madL = 0.0
    private val probeRatios = mutableListOf<Pair<Double, Double>>()

    /** Reapertura: inicio del tramo Open continuo y última observación. */
    private var openRunStart: Long? = null
    private var lastReopenT: Long? = null
    private var reopenSawValid = false

    var outcome: CalibrationOutcome? = null
        private set

    val stepDurationMs: Long
        get() = when (step) {
            CalibrationStep.OPEN_REFERENCE -> p.OPEN_DURATION_MS
            CalibrationStep.CLOSE_LEAD_IN -> p.PROBE_LEAD_IN_MS
            CalibrationStep.CLOSED_PROBE -> p.CLOSED_PROBE_DURATION_MS
            CalibrationStep.REOPEN -> p.REOPEN_DURATION_MS
        }

    /** Muestras válidas del paso en curso (diagnóstico). */
    val validSamples: Int get() = samples.count { it.valid }

    fun onObservation(o: EyeObservation) {
        if (outcome != null || o.tNs < stepStartNs) return
        when (step) {
            CalibrationStep.OPEN_REFERENCE, CalibrationStep.CLOSED_PROBE -> {
                if (o.tNs < stepStartNs + ms(stepDurationMs)) samples += o
            }
            CalibrationStep.CLOSE_LEAD_IN -> Unit
            CalibrationStep.REOPEN -> reopen(o)
        }
    }

    /** Avanza los pasos vencidos en [nowNs]. Devuelve el resultado si terminó. */
    fun tick(nowNs: Long): CalibrationOutcome? {
        if (outcome != null) return outcome
        val end = stepStartNs + ms(stepDurationMs)
        when (step) {
            CalibrationStep.OPEN_REFERENCE -> if (nowNs >= end) finishOpen(end)
            CalibrationStep.CLOSE_LEAD_IN -> if (nowNs >= end) next(CalibrationStep.CLOSED_PROBE, end)
            CalibrationStep.CLOSED_PROBE -> if (nowNs >= end) finishProbe(end)
            CalibrationStep.REOPEN -> if (nowNs >= stepStartNs + ms(p.REOPEN_TIMEOUT_MS)) {
                reject(
                    if (reopenSawValid) CalibrationRejection.UNSTABLE_REFERENCE
                    else CalibrationRejection.INSUFFICIENT_OBSERVATIONS,
                    "reopenNotConfirmed(probe=$probe)",
                )
            }
        }
        return outcome
    }

    private fun finishOpen(end: Long) {
        val valid = samples.filter { it.valid }
        openCount = valid.size
        openCoverage = coverage(samples, p.OPEN_DURATION_MS)
        if (valid.size < p.MIN_OPEN_SAMPLES || openCoverage < p.MIN_COVERAGE) {
            return rejectInsufficient("open(samples=${valid.size}, coverage=${fmt(openCoverage)})")
        }
        val r = valid.map { it.earRight!! }
        val l = valid.map { it.earLeft!! }
        val mr = relativeMad(r)
        val ml = relativeMad(l)
        if (mr == null || ml == null) return reject(CalibrationRejection.UNSTABLE_REFERENCE, "medianNotPositive")
        openR = percentile80(r)
        openL = percentile80(l)
        madR = mr
        madL = ml
        val inRange = { v: Double -> v >= p.OPEN_EAR_MIN && v <= p.OPEN_EAR_MAX }
        if (!inRange(openR) || !inRange(openL)) {
            return reject(CalibrationRejection.UNSTABLE_REFERENCE, "openEarOutOfRange(${fmt(openR)}, ${fmt(openL)})")
        }
        if (mr > p.MAX_RELATIVE_MAD || ml > p.MAX_RELATIVE_MAD) {
            return reject(CalibrationRejection.UNSTABLE_REFERENCE, "relativeMad(${fmt(mr)}, ${fmt(ml)})")
        }
        probe = 1
        next(CalibrationStep.CLOSE_LEAD_IN, end)
    }

    private fun finishProbe(end: Long) {
        val valid = samples.filter { it.valid }
        val cov = coverage(samples, p.CLOSED_PROBE_DURATION_MS)
        if (valid.size < p.MIN_PROBE_SAMPLES || cov < p.MIN_PROBE_COVERAGE) {
            return rejectInsufficient("probe$probe(samples=${valid.size}, coverage=${fmt(cov)})")
        }
        val rr = median(valid.map { it.earRight!! / openR })
        val rl = median(valid.map { it.earLeft!! / openL })
        if (rr > p.MAX_CLOSED_PROBE_RATIO || rl > p.MAX_CLOSED_PROBE_RATIO) {
            return reject(CalibrationRejection.UNSTABLE_REFERENCE, "probe${probe}NotClosed(${fmt(rr)}, ${fmt(rl)})")
        }
        probeRatios += rr to rl
        next(CalibrationStep.REOPEN, end)
    }

    private fun reopen(o: EyeObservation) {
        if (o.valid) reopenSawValid = true
        val open = o.valid && o.earRight!! / openR >= p.THETA_OPEN && o.earLeft!! / openL >= p.THETA_OPEN
        val last = lastReopenT
        lastReopenT = o.tNs
        if (!open) {
            openRunStart = null
            return
        }
        val start = openRunStart
        if (start == null || last == null || o.tNs - last <= 0 || o.tNs - last > ms(p.G_MAX_MS)) {
            openRunStart = o.tNs
            return
        }
        if (o.tNs - start >= ms(p.REOPEN_DURATION_MS)) {
            if (probe < p.CLOSED_PROBE_COUNT) {
                probe++
                next(CalibrationStep.CLOSE_LEAD_IN, o.tNs)
            } else {
                outcome = CalibrationOutcome.Accepted(
                    CalibrationReference(
                        calibrationId = newId(),
                        openEarRight = openR,
                        openEarLeft = openL,
                        openSamples = openCount,
                        openCoverage = openCoverage,
                        relativeMadRight = madR,
                        relativeMadLeft = madL,
                        probeRatios = probeRatios.toList(),
                    ),
                )
            }
        }
    }

    private fun next(s: CalibrationStep, at: Long) {
        step = s
        stepStartNs = at
        samples.clear()
        openRunStart = null
        lastReopenT = null
        reopenSawValid = false
    }

    /** Orden del Área 05 §8: fallo ocular explícito → invalidEyeQuality. */
    private fun rejectInsufficient(detail: String) {
        val eyeFailure = samples.any { o -> o.reasons.any { it.eyeFailure } }
        reject(
            if (eyeFailure) CalibrationRejection.INVALID_EYE_QUALITY
            else CalibrationRejection.INSUFFICIENT_OBSERVATIONS,
            detail,
        )
    }

    private fun reject(r: CalibrationRejection, detail: String) {
        outcome = CalibrationOutcome.Rejected(r, detail)
    }

    private fun ms(v: Long) = v * 1_000_000

    private fun coverage(obs: List<EyeObservation>, durationMs: Long): Double {
        var spanNs = 0L
        for (i in 1 until obs.size) {
            val a = obs[i - 1]
            val b = obs[i]
            val gap = b.tNs - a.tNs
            if (a.valid && b.valid && gap > 0 && gap <= ms(p.G_MAX_MS)) spanNs += gap
        }
        return spanNs.toDouble() / ms(durationMs)
    }

    companion object {
        /** Percentil 80 con h = (n−1)·0,8 e interpolación lineal (Área 05 §8). */
        fun percentile80(values: List<Double>): Double {
            val s = values.sorted()
            val h = (s.size - 1) * 0.8
            val lo = floor(h).toInt()
            val hi = minOf(lo + 1, s.size - 1)
            return s[lo] + (h - lo) * (s[hi] - s[lo])
        }

        fun median(values: List<Double>): Double {
            val s = values.sorted()
            val n = s.size
            return if (n % 2 == 1) s[n / 2] else (s[n / 2 - 1] + s[n / 2]) / 2
        }

        /** 1,4826·MAD/mediana; nulo si la mediana no es positiva o no es finito. */
        fun relativeMad(values: List<Double>): Double? {
            val m = median(values)
            if (!(m > 0.0)) return null
            val mad = median(values.map { abs(it - m) })
            val r = 1.4826 * mad / m
            return r.takeIf { it.isFinite() }
        }

        private fun fmt(v: Double) = "%.3f".format(java.util.Locale.ROOT, v)
    }
}
