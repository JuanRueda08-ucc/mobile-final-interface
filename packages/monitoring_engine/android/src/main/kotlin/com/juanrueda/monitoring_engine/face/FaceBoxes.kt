package com.juanrueda.monitoring_engine.face

import com.juanrueda.monitoring_engine.monitoring.EyeGeometry

/**
 * Recuadros de la cara y de cada ojo para dibujarlos sobre la vista previa
 * (rediseño de P06, 2026-11-15, autorizado por el usuario).
 *
 * Solo salen 12 números: `[cara, ojo derecho, ojo izquierdo]`, cada uno
 * `izquierda, arriba, derecha, abajo`, normalizados a 0..1 en el cuadro
 * **entregado** a MediaPipe (sin girar ni espejar, igual que sus puntos).
 * Los puntos faciales no salen de aquí, no se guardan ni se registran; los
 * recuadros tampoco se guardan: viven solo en el resultado vigente.
 */
internal object FaceBoxes {
    const val SIZE = 12

    /** Recuadros de un resultado con exactamente un rostro; nulo si no. */
    fun of(faceCount: Int, points: FloatArray?): List<Double>? {
        if (faceCount != 1 || points == null || points.size < 2) return null
        val face = bounds(points, null) ?: return null
        val right = eye(points, EyeGeometry.RIGHT) ?: return null
        val left = eye(points, EyeGeometry.LEFT) ?: return null
        return face + right + left
    }

    private fun bounds(points: FloatArray, idx: IntArray?): List<Double>? {
        var l = Double.POSITIVE_INFINITY
        var t = Double.POSITIVE_INFINITY
        var r = Double.NEGATIVE_INFINITY
        var b = Double.NEGATIVE_INFINITY
        val n = idx?.size ?: (points.size / 2)
        for (k in 0 until n) {
            val i = idx?.get(k) ?: k
            if (2 * i + 1 >= points.size) return null
            val x = points[2 * i].toDouble()
            val y = points[2 * i + 1].toDouble()
            if (!x.isFinite() || !y.isFinite()) return null
            l = minOf(l, x)
            t = minOf(t, y)
            r = maxOf(r, x)
            b = maxOf(b, y)
        }
        if (r <= l || b <= t) return null
        return listOf(clamp(l), clamp(t), clamp(r), clamp(b))
    }

    /** Recuadro del ojo: contorno ampliado y con un alto mínimo. */
    private fun eye(points: FloatArray, idx: IntArray): List<Double>? {
        val (l, t, r, b) = bounds(points, idx) ?: return null
        val cx = (l + r) / 2
        val cy = (t + b) / 2
        // Los puntos no se escalan por el tamaño en píxeles: el recuadro es
        // orientativo, no una medición.
        val half = maxOf(r - l, b - t) * 0.75
        return listOf(clamp(cx - half), clamp(cy - half), clamp(cx + half), clamp(cy + half))
    }

    private fun clamp(v: Double) = v.coerceIn(0.0, 1.0)
}
