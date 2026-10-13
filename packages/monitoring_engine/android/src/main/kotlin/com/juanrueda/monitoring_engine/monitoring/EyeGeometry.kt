package com.juanrueda.monitoring_engine.monitoring

import kotlin.math.hypot
import kotlin.math.max
import kotlin.math.min

/** Motivos de Q inválida (Área 05 §6). Códigos técnicos, no textos de interfaz. */
internal enum class QReason(val code: String, val eyeFailure: Boolean = false) {
    NO_FACE("noFace"),
    AMBIGUOUS_FACE("ambiguousFace"),
    INVALID_GEOMETRY("invalidGeometry", eyeFailure = true),
    EYE_OUTSIDE_FRAME("eyeOutsideFrame", eyeFailure = true),
    INSUFFICIENT_EYE_RESOLUTION("insufficientEyeResolution", eyeFailure = true),
    EXCESSIVE_PERSPECTIVE("excessivePerspective", eyeFailure = true),
    STALE_RESULT("staleResult"),
    INVALID_TIMESTAMP("invalidTimestamp"),
    INFERENCE_ERROR("inferenceError"),
}

/**
 * Medición ocular de **una** observación con un rostro: EAR de cada ojo y
 * los motivos de Q geométrica. Solo datos compactos: los puntos faciales no
 * salen de [EyeGeometry.measure].
 */
internal data class EyeMeasurement(
    val earRight: Double?,
    val earLeft: Double?,
    val widthRightPx: Double?,
    val widthLeftPx: Double?,
    val reasons: Set<QReason>,
) {
    val valid: Boolean get() = reasons.isEmpty() && earRight != null && earLeft != null
}

/**
 * Apertura ocular y Q geométrica (Área 05 §4–6, esquema `mp-eye6-v1`).
 *
 * - EAR = (dist(p2,p6) + dist(p3,p5)) / (2·dist(p1,p4)), con distancias en
 *   **píxeles**: x·ancho, y·alto del cuadro entregado a MediaPipe (sus
 *   coordenadas normalizadas usan ese tamaño también con giro; comprobado
 *   con MediaPipe real, ver `EyeMeasurementInstrumentedTest`). No se usa el espejo
 *   de la vista previa: «derecho» es el ojo anatómico según el mapeo.
 * - Q geométrica: índices presentes, coordenadas finitas, los seis puntos y
 *   el ROI orientado de cada ojo (1,6×ancho por 0,8×ancho) dentro de la
 *   imagen, ancho ≥ minEyeWidthPx en cada ojo y asimetría ≤ maxWidthRatio.
 * - **No implementado:** luz, nitidez y postura de la Q del Área 05 §6.
 *   Una observación que pasa esta Q no prueba que los ojos sean visibles
 *   (gafas oscuras, reflejos): limitación declarada del prototipo.
 * - No se exige una altura ocular mínima: un ojo cerrado sigue siendo una
 *   observación válida.
 */
internal object EyeGeometry {
    /** Ojo derecho anatómico: p1..p6. */
    val RIGHT = intArrayOf(33, 160, 158, 133, 153, 144)

    /** Ojo izquierdo anatómico: p1..p6. */
    val LEFT = intArrayOf(362, 385, 387, 263, 373, 380)

    private val maxIndex = max(RIGHT.max(), LEFT.max())

    /**
     * Mide [points] (x0, y0, x1, y1, … normalizados al cuadro de
     * [widthPx]×[heightPx]). [points] no se conserva.
     */
    fun measure(
        points: FloatArray,
        widthPx: Int,
        heightPx: Int,
        minEyeWidthPx: Double = ExperimentalProfile.MIN_EYE_WIDTH_PX,
        maxWidthRatio: Double = ExperimentalProfile.MAX_WIDTH_RATIO,
    ): EyeMeasurement {
        val reasons = mutableSetOf<QReason>()
        if (widthPx <= 0 || heightPx <= 0 || points.size < 2 * (maxIndex + 1)) {
            return EyeMeasurement(null, null, null, null, setOf(QReason.INVALID_GEOMETRY))
        }
        for (i in RIGHT + LEFT) {
            if (!points[2 * i].isFinite() || !points[2 * i + 1].isFinite()) {
                return EyeMeasurement(null, null, null, null, setOf(QReason.INVALID_GEOMETRY))
            }
        }
        val right = eye(points, RIGHT, widthPx, heightPx)
        val left = eye(points, LEFT, widthPx, heightPx)
        if (!right.inside || !left.inside) reasons += QReason.EYE_OUTSIDE_FRAME
        if (right.width < minEyeWidthPx || left.width < minEyeWidthPx) {
            reasons += QReason.INSUFFICIENT_EYE_RESOLUTION
        }
        val wMin = min(right.width, left.width)
        if (wMin <= 0.0 || max(right.width, left.width) / wMin > maxWidthRatio) {
            reasons += QReason.EXCESSIVE_PERSPECTIVE
        }
        val earR = right.ear.takeIf { it.isFinite() }
        val earL = left.ear.takeIf { it.isFinite() }
        if (earR == null || earL == null) reasons += QReason.INVALID_GEOMETRY
        return EyeMeasurement(earR, earL, right.width, left.width, reasons)
    }

    private class Eye(val ear: Double, val width: Double, val inside: Boolean)

    private fun eye(points: FloatArray, idx: IntArray, w: Int, h: Int): Eye {
        val xs = DoubleArray(6) { points[2 * idx[it]].toDouble() * w }
        val ys = DoubleArray(6) { points[2 * idx[it] + 1].toDouble() * h }
        fun d(a: Int, b: Int) = hypot(xs[a] - xs[b], ys[a] - ys[b])
        val width = d(0, 3)
        val ear = (d(1, 5) + d(2, 4)) / (2.0 * width)
        var inside = (0 until 6).all { xs[it] in 0.0..w.toDouble() && ys[it] in 0.0..h.toDouble() }
        if (inside && width > 0.0) {
            // ROI orientado con el segmento p1→p4 (Área 05 §6): sus esquinas
            // deben quedar dentro de la imagen; no se rellena.
            val cx = (xs[0] + xs[3]) / 2
            val cy = (ys[0] + ys[3]) / 2
            val ux = (xs[3] - xs[0]) / width
            val uy = (ys[3] - ys[0]) / width
            val hw = 0.8 * width
            val hh = 0.4 * width
            for (sx in intArrayOf(-1, 1)) for (sy in intArrayOf(-1, 1)) {
                val px = cx + sx * hw * ux - sy * hh * uy
                val py = cy + sx * hw * uy + sy * hh * ux
                if (px < 0.0 || px > w || py < 0.0 || py > h) inside = false
            }
        }
        return Eye(ear, width, inside)
    }
}
