package com.juanrueda.monitoring_engine

import com.juanrueda.monitoring_engine.face.FaceAnalysisCore
import com.juanrueda.monitoring_engine.face.FaceEngine
import com.juanrueda.monitoring_engine.face.FaceEngineListener
import com.juanrueda.monitoring_engine.face.FacePresence
import com.juanrueda.monitoring_engine.face.FacePresenceStatus
import com.juanrueda.monitoring_engine.face.ModelLoad
import java.nio.ByteBuffer
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/*
 * Revisión de Codex de la fase 5B (P1, segunda ronda): la edad de un
 * resultado se recalcula con el reloj actual en **cada** publicación (latido
 * incluido) y al leer el estado, no solo al aceptar la inferencia. Dobles:
 * detector falso, reloj manual y cola de avisos.
 *
 * Solo usa la API anterior a esta corrección, para poder ejecutarla también
 * contra el código de c5c0503.
 */
internal class FacePublishAgeTest {
    private class Harness {
        var nowMs = 1_000L
        val queue = ArrayDeque<Runnable>()
        val messages = mutableListOf<Pair<Long, FacePresence>>()
        lateinit var listener: FaceEngineListener
        val core = FaceAnalysisCore<String>(
            token = 1,
            loadModel = { ModelLoad.Ready(ByteBuffer.allocateDirect(1)) },
            createEngine = { _, l ->
                listener = l
                object : FaceEngine<String> {
                    override fun detectAsync(frame: String, rotationDegrees: Int, timestampMs: Long) {}
                    override fun close() {}
                }
            },
            post = { queue.addLast(it) },
            clockNs = { nowMs * 1_000_000 },
            publish = { messages += nowMs to it },
        )

        init {
            core.start()
        }

        /** Cuadro entregado en [frameMs]; su resultado se aplica en [appliedMs]. */
        fun result(frameMs: Long, appliedMs: Long, faces: Int) {
            nowMs = frameMs
            core.submit("cuadro", 0, frameMs * 1_000_000, 640, 480)
            nowMs = appliedMs
            listener.onResult(frameMs, faces)
            while (queue.isNotEmpty()) queue.removeFirst().run()
        }

        /** Escenario de Codex: 1000→1000 publicado; 1300→1950 sin publicar. */
        fun codexScenario(faces: Int) {
            result(1_000, 1_000, faces)
            result(1_300, 1_950, faces)
        }

        fun detectionsAfter(ms: Long) = messages.filter { it.first >= ms && it.second.status.isDetection }
    }

    /** Reproducción de Codex: el latido a 2051 tiene un resultado de 751 ms. */
    @Test
    fun codexRepro_heartbeatDoesNotPublishAStaleResult() {
        for (faces in listOf(0, 1, 2)) {
            val h = Harness()
            h.codexScenario(faces)
            h.nowMs = 2_051
            h.core.tick()
            assertTrue(h.detectionsAfter(2_051).isEmpty(), "Latido con edad 751 ($faces rostros)")
            val last = h.messages.last().second
            assertEquals(FacePresenceStatus.WAITING_RESULTS, last.status)
            assertTrue(last.expired)
        }
    }

    /**
     * Límite en un latido: resultados 1000→1000 (publicado) y 1250→1700 (mismo
     * estado, sin publicar). El latido a 2000 es la primera publicación del
     * segundo: edad 750, vigente, e informa 750 (no los 450 de la
     * aceptación). A 2001 (edad 751) ya no se publica como vigente.
     */
    @Test
    fun heartbeat_reportsCurrentAge_boundary750_751() {
        for (faces in listOf(0, 1, 2)) {
            val ok = Harness()
            ok.result(1_000, 1_000, faces)
            ok.result(1_250, 1_700, faces)
            ok.nowMs = 2_000
            ok.core.tick()
            val (at, last) = ok.messages.last()
            assertEquals(2_000, at)
            assertTrue(last.status.isDetection)
            assertEquals(750, last.resultAgeMs)

            val late = Harness()
            late.result(1_000, 1_000, faces)
            late.result(1_250, 1_700, faces)
            late.nowMs = 2_001
            late.core.tick()
            assertTrue(late.detectionsAfter(2_001).isEmpty())
            assertEquals(FacePresenceStatus.WAITING_RESULTS, late.messages.last().second.status)
        }
    }

    /** Entre ticks, leer el estado ya retira un resultado caducado. */
    @Test
    fun statusRead_betweenTicks_appliesExpiry() {
        val h = Harness()
        h.codexScenario(1)
        h.nowMs = 2_050
        assertEquals(FacePresenceStatus.ONE_FACE, h.core.status)
        h.nowMs = 2_051
        assertEquals(FacePresenceStatus.WAITING_RESULTS, h.core.status)
        assertFalse(h.messages.last().second.status.isDetection)
    }

    /** Control positivo: resultados nuevos y frescos mantienen el estado. */
    @Test
    fun freshResults_keepDetectionWithCurrentAge() {
        val h = Harness()
        var frame = 1_000L
        repeat(10) {
            h.result(frame, frame + 100, 2)
            frame += 200
        }
        h.nowMs = frame - 200 + 300
        h.core.tick()
        assertEquals(FacePresenceStatus.MULTIPLE_FACES, h.core.status)
        val last = h.messages.last().second
        assertTrue(last.status.isDetection)
        assertTrue(last.resultAgeMs!! <= 750)
    }
}
