package com.juanrueda.monitoring_engine

import com.juanrueda.monitoring_engine.face.FaceAnalysisCore
import com.juanrueda.monitoring_engine.face.FaceEngine
import com.juanrueda.monitoring_engine.face.FaceEngineListener
import com.juanrueda.monitoring_engine.face.FacePresenceStatus
import com.juanrueda.monitoring_engine.face.ModelLoad
import java.nio.ByteBuffer
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

internal class FaceResultTimingTest {
    @Test
    fun timingsSeparateCallbackFromDispatchAndDoNotMakeStaleResultsCurrent() {
        var nowNs = 1_000_000_000L
        val queue = ArrayDeque<Runnable>()
        val timings = mutableListOf<List<Long>>()
        val listeners = mutableListOf<FaceEngineListener>()
        val core = FaceAnalysisCore<String>(
            token = 1,
            loadModel = { ModelLoad.Ready(ByteBuffer.allocateDirect(1)) },
            createEngine = { _, listener ->
                listeners += listener
                object : FaceEngine<String> {
                    override fun detectAsync(frame: String, rotationDegrees: Int, timestampMs: Long) {}
                    override fun close() {}
                }
            },
            post = { queue.addLast(it) },
            clockNs = { nowNs },
            publish = {},
            onResultTiming = { a, b, c -> timings += listOf(a, b, c) },
        )
        core.start()
        assertTrue(core.submit("sin imagen real", 0, nowNs, 640, 480))
        nowNs = 1_100_000_000L
        listeners.last().onResult(1_000, 1)
        nowNs = 5_000_000_000L
        queue.removeFirst().run()
        assertEquals(listOf(listOf(1_000_000_000L, 1_100_000_000L, 5_000_000_000L)), timings)
        assertEquals(FacePresenceStatus.WAITING_RESULTS, core.status)
        assertEquals(1, core.discardedTooOld)

        // La instancia anterior no añade datos al diagnóstico de una nueva.
        core.start()
        listeners.first().onResult(1_000, 1)
        queue.removeFirst().run()
        assertEquals(1, timings.size)
        core.stop()
        listeners.last().onResult(1_000, 1)
        queue.removeFirst().run()
        assertEquals(1, timings.size)
    }
}
