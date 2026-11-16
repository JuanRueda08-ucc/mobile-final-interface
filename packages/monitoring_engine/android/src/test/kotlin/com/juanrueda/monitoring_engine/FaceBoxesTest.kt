package com.juanrueda.monitoring_engine

import com.juanrueda.monitoring_engine.face.FaceBoxes
import com.juanrueda.monitoring_engine.monitoring.EyeGeometry
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

/*
 * Rediseño de P06 (2026-11-15): de los puntos faciales solo salen 12 números
 * (recuadros de la cara y de cada ojo), normalizados y dentro de 0..1.
 */
internal class FaceBoxesTest {
    /** 478 puntos de una cara sintética: contorno en 0,3..0,7 y ojos. */
    private fun face(): FloatArray {
        val p = FloatArray(2 * 478) { 0.5f }
        // Extremos de la cara.
        p[0] = 0.3f; p[1] = 0.25f
        p[2] = 0.7f; p[3] = 0.75f
        fun eye(idx: IntArray, cx: Float) {
            val xs = floatArrayOf(cx - 0.04f, cx - 0.015f, cx + 0.015f, cx + 0.04f, cx + 0.015f, cx - 0.015f)
            val ys = floatArrayOf(0.43f, 0.415f, 0.415f, 0.43f, 0.445f, 0.445f)
            for (k in 0 until 6) {
                p[2 * idx[k]] = xs[k]
                p[2 * idx[k] + 1] = ys[k]
            }
        }
        eye(EyeGeometry.RIGHT, 0.4f)
        eye(EyeGeometry.LEFT, 0.6f)
        return p
    }

    @Test
    fun oneFace_twelveValuesInsideFrame() {
        val b = assertNotNull(FaceBoxes.of(1, face()))
        assertEquals(FaceBoxes.SIZE, b.size)
        assertTrue(b.all { it in 0.0..1.0 })
        // Cara: extremos de todos los puntos.
        assertEquals(0.3, b[0], 1e-6)
        assertEquals(0.25, b[1], 1e-6)
        assertEquals(0.7, b[2], 1e-6)
        assertEquals(0.75, b[3], 1e-6)
        // Ojo derecho centrado en 0,4 y dentro de la cara.
        assertEquals(0.4, (b[4] + b[6]) / 2, 1e-6)
        assertTrue(b[4] > b[0] && b[6] < b[2])
        // Ojo izquierdo centrado en 0,6.
        assertEquals(0.6, (b[8] + b[10]) / 2, 1e-6)
    }

    @Test
    fun noFaceSeveralFacesOrBadPoints_noBoxes() {
        assertNull(FaceBoxes.of(0, null))
        assertNull(FaceBoxes.of(2, face()))
        assertNull(FaceBoxes.of(1, null))
        assertNull(FaceBoxes.of(1, FloatArray(10)))
        val nan = face().also { it[2 * EyeGeometry.RIGHT[0]] = Float.NaN }
        assertNull(FaceBoxes.of(1, nan))
    }

    @Test
    fun boxesNearTheEdge_areClamped() {
        val p = face().also { it[0] = -0.2f; it[3] = 1.3f }
        val b = assertNotNull(FaceBoxes.of(1, p))
        assertEquals(0.0, b[0], 0.0)
        assertEquals(1.0, b[3], 0.0)
    }
}
