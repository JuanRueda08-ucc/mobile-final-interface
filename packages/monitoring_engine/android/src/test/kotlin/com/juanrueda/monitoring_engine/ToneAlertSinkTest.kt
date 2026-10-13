package com.juanrueda.monitoring_engine

import com.juanrueda.monitoring_engine.monitoring.ToneAlertSink
import com.juanrueda.monitoring_engine.monitoring.ToneHandle
import com.juanrueda.monitoring_engine.monitoring.ToneKind
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

internal class ToneAlertSinkTest {
    private class FakeTone : ToneHandle {
        var started = true
        var failStart = false
        var failStop = false
        var released = 0
        override fun startTone(tone: Int, millis: Int): Boolean {
            if (failStart) throw RuntimeException("start failed")
            return started
        }
        override fun stopTone() { if (failStop) throw RuntimeException("stop failed") }
        override fun release() { released++ }
    }
    private class Rig {
        var volume = 5
        val tone = FakeTone()
        val sink = ToneAlertSink({ volume }) { _, _ -> tone }
    }
    @Test fun failedStartReleasesGenerator() {
        val r = Rig()
        r.tone.started = false
        assertEquals("toneNotStarted", r.sink.play(ToneKind.TEST))
        assertEquals(1, r.tone.released)
    }
    @Test fun stopFailureStillReleasesGeneratorAndDoesNotDoubleRelease() {
        val r = Rig()
        assertNull(r.sink.play(ToneKind.TEST))
        r.tone.failStop = true
        r.sink.stop()
        r.sink.stop()
        assertEquals(1, r.tone.released)
    }
    @Test fun startExceptionReleasesCreatedGenerator() {
        val r = Rig()
        r.tone.failStart = true
        assertEquals("toneUnavailable", r.sink.play(ToneKind.TEST))
        assertEquals(1, r.tone.released)
    }
    @Test fun zeroVolumeReleasesPreviousTone() {
        val r = Rig()
        assertNull(r.sink.play(ToneKind.TEST))
        r.volume = 0
        assertEquals("alarmVolumeZero", r.sink.play(ToneKind.TEST))
        assertEquals(1, r.tone.released)
    }
}
