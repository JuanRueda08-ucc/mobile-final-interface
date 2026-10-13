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
 * Revisión de Codex de la fase 5B (P1): la edad de un resultado se comprueba
 * con el reloj del momento en que se aplica en el hilo de análisis, no con la
 * hora a la que MediaPipe lo entregó. Dobles: detector falso, reloj manual y
 * cola de avisos retenida, para simular la espera del aviso en la cola.
 *
 * Solo usa la API anterior a la corrección, para poder ejecutar estas
 * pruebas también contra el código de 3be9bf1.
 */
internal class FaceAnalysisDelayTest {
    private class Harness {
        var nowMs = 1_000L
        val queue = ArrayDeque<Runnable>()
        val published = mutableListOf<FacePresence>()
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
            publish = { published += it },
        )

        init {
            core.start()
        }

        fun frameAt(ms: Long): Long {
            core.submit("cuadro", 0, ms * 1_000_000, 640, 480)
            return ms
        }

        /** MediaPipe entrega el resultado ahora; el aviso queda en cola. */
        fun deliver(ts: Long, faces: Int) = listener.onResult(ts, faces)

        fun runQueued() {
            while (queue.isNotEmpty()) queue.removeFirst().run()
        }

        val everDetected get() = published.any { it.status.isDetection }
    }

    /** Reproducción de Codex: cuadro 1000 → recepción 1100 → aplicación 5000. */
    @Test
    fun codexRepro_delayedDispatchIsNotPublishedAsCurrent() {
        for (faces in listOf(0, 1, 2)) {
            val h = Harness()
            val ts = h.frameAt(1_000)
            h.nowMs = 1_100
            h.deliver(ts, faces)
            h.nowMs = 5_000
            h.runQueued()
            assertFalse(h.everDetected, "Se publicó un resultado de 4000 ms ($faces rostros)")
            assertEquals(FacePresenceStatus.WAITING_RESULTS, h.core.status)
            h.core.tick()
            assertFalse(h.everDetected)
        }
    }

    @Test
    fun delayedDispatch_ageCountsUntilApplication_boundary() {
        // Edad al aplicar = 750: vigente.
        val ok = Harness()
        val ts = ok.frameAt(1_000)
        ok.nowMs = 1_100
        ok.deliver(ts, 1)
        ok.nowMs = 1_750
        ok.runQueued()
        assertEquals(FacePresenceStatus.ONE_FACE, ok.core.status)
        assertEquals(750, ok.published.last().resultAgeMs)

        // Edad al aplicar = 751: se descarta, aunque al recibirlo tenía 100.
        val late = Harness()
        val ts2 = late.frameAt(1_000)
        late.nowMs = 1_100
        late.deliver(ts2, 1)
        late.nowMs = 1_751
        late.runQueued()
        assertFalse(late.everDetected)
    }

    @Test
    fun freshResultAfterADelayedOne_isAccepted() {
        val h = Harness()
        val old = h.frameAt(1_000)
        h.nowMs = 1_100
        h.deliver(old, 1)
        h.nowMs = 5_000
        h.runQueued()
        val fresh = h.frameAt(5_000)
        h.nowMs = 5_040
        h.deliver(fresh, 2)
        h.runQueued()
        assertEquals(FacePresenceStatus.MULTIPLE_FACES, h.core.status)
        assertEquals(40, h.published.last().resultAgeMs)
    }

    @Test
    fun silenceIsMeasuredFromApplication() {
        val h = Harness()
        val ts = h.frameAt(1_000)
        h.nowMs = 1_050
        h.deliver(ts, 1)
        h.nowMs = 1_300
        h.runQueued()
        assertEquals(FacePresenceStatus.ONE_FACE, h.core.status)
        h.nowMs = 1_300 + 749
        h.core.tick()
        assertEquals(FacePresenceStatus.ONE_FACE, h.core.status)
        h.nowMs = 1_300 + 750
        h.core.tick()
        assertEquals(FacePresenceStatus.WAITING_RESULTS, h.core.status)
    }

    /** Una entrega «futura» respecto del reloj no se convierte en edad cero ni negativa. */
    @Test
    fun futureEntryTime_isDiscardedNotAgeZero() {
        val h = Harness()
        val ts = h.frameAt(1_500) // entrega 500 ms en el futuro del reloj (1000)
        h.deliver(ts, 1)
        h.runQueued()
        assertFalse(h.everDetected)
        assertTrue(h.core.status == FacePresenceStatus.WAITING_RESULTS)
    }
}
