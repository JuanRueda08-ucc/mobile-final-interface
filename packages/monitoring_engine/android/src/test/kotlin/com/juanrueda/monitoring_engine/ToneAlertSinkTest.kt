package com.juanrueda.monitoring_engine

import android.media.ToneGenerator
import com.juanrueda.monitoring_engine.monitoring.SoundPattern
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
        val tones = mutableListOf<Int>()
        override fun startTone(tone: Int, millis: Int): Boolean {
            tones += tone
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
        assertEquals("toneNotStarted", r.sink.play(ToneKind.TEST, SoundPattern.DEFAULT))
        assertEquals(1, r.tone.released)
    }
    @Test fun stopFailureStillReleasesGeneratorAndDoesNotDoubleRelease() {
        val r = Rig()
        assertNull(r.sink.play(ToneKind.TEST, SoundPattern.DEFAULT))
        r.tone.failStop = true
        r.sink.stop()
        r.sink.stop()
        assertEquals(1, r.tone.released)
    }
    @Test fun startExceptionReleasesCreatedGenerator() {
        val r = Rig()
        r.tone.failStart = true
        assertEquals("toneUnavailable", r.sink.play(ToneKind.TEST, SoundPattern.DEFAULT))
        assertEquals(1, r.tone.released)
    }
    @Test fun zeroVolumeReleasesPreviousTone() {
        val r = Rig()
        assertNull(r.sink.play(ToneKind.TEST, SoundPattern.DEFAULT))
        r.volume = 0
        assertEquals("alarmVolumeZero", r.sink.play(ToneKind.TEST, SoundPattern.DEFAULT))
        assertEquals(1, r.tone.released)
    }
    @Test fun eachPatternPlaysItsOwnTones() {
        // Mismos tonos que MainActivity usa en la DEMO para prueba y cierre.
        val expected = mapOf(
            SoundPattern.PATRON_1 to (ToneGenerator.TONE_PROP_BEEP to ToneGenerator.TONE_CDMA_HIGH_L),
            SoundPattern.PATRON_2 to (ToneGenerator.TONE_CDMA_ALERT_CALL_GUARD to ToneGenerator.TONE_CDMA_EMERGENCY_RINGBACK),
            SoundPattern.PATRON_3 to (ToneGenerator.TONE_PROP_ACK to ToneGenerator.TONE_CDMA_ABBR_ALERT),
        )
        for ((pattern, tones) in expected) {
            val r = Rig()
            assertNull(r.sink.play(ToneKind.TEST, pattern))
            assertNull(r.sink.play(ToneKind.PROLONGED_CLOSURE, pattern))
            assertEquals(listOf(tones.first, tones.second), r.tone.tones, pattern.id)
        }
        assertEquals(listOf("patron_1", "patron_2", "patron_3"), SoundPattern.entries.map { it.id })
    }
}
