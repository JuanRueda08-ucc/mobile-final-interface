package com.juanrueda.monitoring_engine

import com.juanrueda.monitoring_engine.journal.ExperimentalJournalHost
import com.juanrueda.monitoring_engine.journal.JournalCodec
import com.juanrueda.monitoring_engine.journal.JournalLifecycle
import com.juanrueda.monitoring_engine.journal.JournalRecord
import com.juanrueda.monitoring_engine.journal.RecordStatus
import com.juanrueda.monitoring_engine.journal.RecordType
import com.juanrueda.monitoring_engine.journal.SessionJournal
import com.juanrueda.monitoring_engine.monitoring.AlertSink
import com.juanrueda.monitoring_engine.monitoring.CalibrationPhase
import com.juanrueda.monitoring_engine.monitoring.EyeMeasurement
import com.juanrueda.monitoring_engine.monitoring.EyeObservation
import com.juanrueda.monitoring_engine.monitoring.MonitoringCoordinator
import com.juanrueda.monitoring_engine.monitoring.MonitoringState
import com.juanrueda.monitoring_engine.monitoring.SessionLifecycle
import com.juanrueda.monitoring_engine.monitoring.ToneKind
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

/*
 * Fase 5D · journal nativo de la sesión experimental, con secuencias
 * controladas (observaciones sintéticas, reloj manual, tono falso) y el doble
 * [MemoryJournalStore]. La durabilidad en SQLite y el reinicio real del
 * proceso se prueban en Android (`JournalSqliteInstrumentedTest`).
 */
internal class ExperimentalJournalTest {
    private fun ms(v: Long) = v * 1_000_000
    private val open = 0.30
    private val closed = 0.10
    private fun eyes(e: Double) = EyeMeasurement(e, e, 40.0, 40.0, emptySet())

    private class Tone : AlertSink {
        var fail: String? = null
        override fun play(kind: ToneKind): String? = if (kind == ToneKind.PROLONGED_CLOSURE) fail else null
        override fun stop() = Unit
    }

    /** Un coordinador (una «instancia del motor») sobre un journal compartido. */
    private inner class Rig(val store: MemoryJournalStore = MemoryJournalStore(), startMs: Long = 0,
                          writer: java.util.concurrent.ExecutorService? = null) {
        var nowMs = startMs
        var wallMs = 1_760_000_000_000L + startMs
        val tone = Tone()
        val published = mutableListOf<MonitoringState>()
        var factoryCalls = 0
        var factoryFails = false
        var releases = 0
        var onReleased: (() -> Unit)? = null
        private var n = 0
        val c = MonitoringCoordinator(
            clockNs = { nowMs * 1_000_000 },
            newId = { "id-${System.identityHashCode(this)}-${++n}" },
            alerts = tone,
            publish = { published += it },
            onRelease = { releases++; onReleased?.invoke() },
            journalFactory = {
                factoryCalls++
                check(!factoryFails) { "fallo de apertura" }
                SessionJournal(store, { wallMs }, { -300 }, { java.util.UUID.randomUUID().toString() }, writer)
            },
        )
        val last get() = published.last()

        fun at(t: Long, o: EyeObservation? = null) {
            wallMs += t - nowMs
            nowMs = t
            o?.let(c::observe)
            c.tick()
        }

        fun feed(fromMs: Long, toMs: Long, ear: Double, token: Long = 1) {
            var t = fromMs
            while (t <= toMs) {
                at(t, EyeObservation.of(token, ms(t), ms(t), 1, eyes(ear)))
                t += 100
            }
        }

        fun calibrated(token: Long = 1) {
            c.attach(token)
            assertTrue(c.beginCalibration().accepted)
            var t = nowMs
            while (last.calibrationPhase != CalibrationPhase.ACCEPTED) {
                val e = if (last.calibrationPhase == CalibrationPhase.CLOSED_PROBE) closed else open
                at(t, EyeObservation.of(token, ms(t), ms(t), 1, eyes(e)))
                assertTrue(last.calibrationPhase != CalibrationPhase.REJECTED, "${last.calibrationDetail}")
                t += 50
            }
        }

        fun started(): String {
            calibrated()
            val sound = c.testSound().state.soundTestId!!
            assertTrue(c.confirmSoundHeard(sound).accepted)
            feed(nowMs + 50, nowMs + 50, open)
            val r = c.startSession(last.calibrationId!!, sound)
            assertTrue(r.accepted, r.errorCode)
            return r.state.sessionId!!
        }
    }

    private fun payload(r: JournalRecord) = r.payloadJson

    private fun JournalRecord.long(key: String): Long =
        Regex("\"$key\":(-?\\d+)").find(payloadJson)!!.groupValues[1].toLong()

    // ----------------------------------------------------------- formato

    @Test
    fun codec_conformanceVector_matchesIndependentSha256() {
        // Mismo vector que `test/experimental_history/journal_codec_test.dart`;
        // el hash se calculó aparte con Python (hashlib) sobre la cadena esperada.
        val r = JournalRecord.build(
            7, "rec-ñ", "s-1", RecordType.CLOSURE_DETECTED, 1_760_000_000_000, -300, 2600,
            mapOf(
                "note" to "a\"b\\c\n", "list" to listOf(1, "x"), "flag" to true, "none" to null,
                "decisionOffsetMs" to 2600L, "activationOrdinal" to 1,
            ),
        )
        assertEquals(
            "{\"activationOrdinal\":1,\"decisionOffsetMs\":2600,\"flag\":true,\"list\":[1,\"x\"]," +
                "\"none\":null,\"note\":\"a\\\"b\\\\c\\u000a\"}",
            r.payloadJson,
        )
        assertEquals("4c3ee8ae1be6de24332dd239b5d8c6d015e76c0da3c3ba319a9f18821f86b6aa", r.payloadHash)
    }

    @Test
    fun codec_rejectsDecimalsAndUnsafeIntegers() {
        assertTrue(runCatching { JournalCodec.encode(mapOf("x" to 0.5)) }.isFailure)
        assertTrue(runCatching { JournalCodec.encode(mapOf("x" to Long.MAX_VALUE)) }.isFailure)
    }

    // ------------------------------------------------------------- sesión

    @Test
    fun session_isJournaledInOrder_withSingleDurableClose() {
        val rig = Rig()
        val id = rig.started()
        val t0 = rig.nowMs
        rig.feed(t0 + 100, t0 + 1100, open)
        rig.feed(t0 + 1200, t0 + 2700, closed) // cierre prolongado → tono
        rig.feed(t0 + 2800, t0 + 3800, open)
        assertTrue(rig.c.pauseSession(id).accepted)
        rig.at(rig.nowMs + 2000)
        rig.c.detach(1)
        rig.c.attach(2)
        assertTrue(rig.c.resumeSession(id).accepted)
        rig.feed(rig.nowMs + 100, rig.nowMs + 1200, open, token = 2)
        assertEquals(SessionLifecycle.ACTIVE, rig.last.lifecycle)
        val end = rig.c.stopSession(id).state
        val s = rig.store

        val types = s.records.map { it.recordType }.filter { it != RecordType.PROGRESS_CHECKPOINT }
        assertEquals(
            listOf(
                RecordType.SESSION_STARTED, RecordType.CLOSURE_DETECTED, RecordType.PLAYBACK_RESULT,
                RecordType.PAUSE_STARTED, RecordType.PAUSE_ENDED, RecordType.SESSION_FINALIZED,
            ),
            types,
        )
        assertTrue(s.ofType(RecordType.PROGRESS_CHECKPOINT).size >= 3, "puntos de control cada ≥1 s")
        // Secuencia global creciente sin huecos; todos de esta sesión.
        assertEquals((1L..s.records.size).toList(), s.records.map { it.journalSequence })
        assertTrue(s.records.all { it.sessionId == id })
        // El cierre conserva los totales que mostró el motor.
        val fin = s.ofType(RecordType.SESSION_FINALIZED).single()
        assertEquals(end.activeMs, fin.long("activeMs"))
        assertEquals(end.evaluableMs, fin.long("evaluableMs"))
        assertEquals(end.pausedMs, fin.long("pausedMs"))
        assertEquals(1, fin.long("closureActivations"))
        assertEquals(1, fin.long("tonesPlayed"))
        assertEquals(1, fin.long("pauseCount"))
        assertEquals(0, fin.long("recordsLost"))
        assertEquals(end.activeMs - end.evaluableMs, fin.long("nonEvaluableMs"))
        assertEquals(JournalLifecycle.FINALIZED, s.session(id)!!.lifecycle)
        assertEquals(fin.long("endOffsetMs"), s.session(id)!!.endOffsetMs)
        assertEquals(RecordStatus.DURABLE, end.recordStatus)
        // Cierre único: otra orden de finalizar no escribe nada.
        val before = s.records.size
        assertFalse(rig.c.stopSession(id).accepted)
        assertEquals(before, s.records.size)
        // Sin imágenes ni puntos: solo estas claves (contadores, límites,
        // versiones y la referencia compacta de la calibración).
        val keys = s.records.flatMap { r -> Regex("\"([A-Za-z0-9]+)\":").findAll(r.payloadJson).map { it.groupValues[1] }.toList() }.toSet()
        val allowed = setOf(
            "sessionId", "engineInstanceId", "startedEpochMs", "startOffsetMinutes", "profileId",
            "qualificationStatus", "landmarkSchema", "modelId", "modelSha256", "calibration", "calibrationId",
            "openEarRightE6", "openEarLeftE6", "openSamples", "openCoverageE6", "activeMs", "evaluableMs",
            "nonEvaluableMs", "pausedMs", "closureActivations", "tonesPlayed", "tonesFailed", "pauseCount",
            "knownThroughOffsetMs", "recordsLost", "pauseOrdinal", "activationOrdinal", "decisionOffsetMs",
            "playbackOrdinal", "requestedOffsetMs", "status", "errorCode", "endOffsetMs", "endedEpochMs",
            "endOffsetMinutes",
        )
        assertEquals(emptySet(), keys - allowed)
    }

    @Test
    fun closure_toneIsDispatchedEvenIfJournalWriteFails_andRecordBecomesIncomplete() {
        val rig = Rig()
        val id = rig.started()
        val t0 = rig.nowMs
        rig.feed(t0 + 100, t0 + 1100, open)
        rig.store.failWrites = true
        rig.feed(t0 + 1200, t0 + 2700, closed)
        assertEquals(1, rig.last.tonesPlayed, "el aviso no espera al journal")
        assertEquals(RecordStatus.INCOMPLETE, rig.last.recordStatus)
        rig.store.failWrites = false
        rig.feed(t0 + 2800, t0 + 4000, open)
        rig.c.stopSession(id)
        val fin = rig.store.ofType(RecordType.SESSION_FINALIZED).single()
        assertTrue(fin.long("recordsLost") >= 2, "se declara la pérdida")
        assertTrue(rig.store.ofType(RecordType.CLOSURE_DETECTED).isEmpty(), "no se fabrica el hecho perdido")
        assertEquals(1, fin.long("closureActivations"), "el total del motor sí es conocido")
    }

    @Test
    fun start_isRejectedWhenSessionStartIsNotDurable() {
        val rig = Rig()
        rig.calibrated()
        val sound = rig.c.testSound().state.soundTestId!!
        rig.c.confirmSoundHeard(sound)
        rig.feed(rig.nowMs + 50, rig.nowMs + 50, open)
        rig.store.failWrites = true
        val r = rig.c.startSession(rig.last.calibrationId!!, sound)
        assertFalse(r.accepted)
        assertEquals("journalWriteFailed", r.errorCode)
        assertEquals(SessionLifecycle.NONE, r.state.lifecycle)
        assertTrue(rig.store.records.isEmpty())
    }

    @Test
    fun secondSession_hasNewIdentity_andOnlyOneOpenAtATime() {
        val rig = Rig()
        val first = rig.started()
        rig.feed(rig.nowMs + 100, rig.nowMs + 1500, open)
        rig.c.stopSession(first)
        val second = rig.started()
        assertNotEquals(first, second)
        rig.feed(rig.nowMs + 100, rig.nowMs + 1500, open)
        assertEquals(listOf(second), rig.store.openSessions().map { it.sessionId })
        rig.c.stopSession(second)
        assertEquals(2, rig.store.ofType(RecordType.SESSION_STARTED).size)
        assertEquals(
            listOf(first, second),
            rig.store.ofType(RecordType.SESSION_FINALIZED).map { it.sessionId },
        )
        assertEquals(rig.store.records.map { it.recordId }.toSet().size, rig.store.records.size)
    }

    // -------------------------------------------------------- recuperación

    @Test
    fun blockedWriter_doesNotBlockObservationToneOrResourceRelease() {
        val writer = java.util.concurrent.Executors.newSingleThreadExecutor()
        val commands = java.util.concurrent.Executors.newSingleThreadExecutor()
        val gate = java.util.concurrent.CountDownLatch(1)
        val entered = java.util.concurrent.CountDownLatch(1)
        try {
            val rig = Rig(writer = writer)
            val id = rig.started()
            rig.store.beforeCommit = { entered.countDown(); check(gate.await(10, java.util.concurrent.TimeUnit.SECONDS)) }
            rig.at(rig.nowMs + 1000)
            assertTrue(entered.await(2, java.util.concurrent.TimeUnit.SECONDS))
            commands.submit {
                val t0 = rig.nowMs
                rig.feed(t0 + 100, t0 + 1100, open)
                rig.feed(t0 + 1200, t0 + 2700, closed)
                rig.c.ensureJournal() // tampoco espera E/S con una sesión viva
            }.get(2, java.util.concurrent.TimeUnit.SECONDS)
            assertEquals(1, rig.last.tonesPlayed)
            assertEquals(RecordStatus.PENDING, rig.last.recordStatus)
            val released = java.util.concurrent.CountDownLatch(1)
            rig.onReleased = { released.countDown() }
            val stop = commands.submit { rig.c.stopSession(id) }
            assertTrue(released.await(2, java.util.concurrent.TimeUnit.SECONDS), "cámara liberada antes de esperar al cierre")
            assertFalse(stop.isDone)
            gate.countDown()
            stop.get(5, java.util.concurrent.TimeUnit.SECONDS)
            assertEquals(1, rig.store.ofType(RecordType.SESSION_FINALIZED).size)
            assertEquals(RecordStatus.DURABLE, rig.last.recordStatus)
        } finally { gate.countDown(); commands.shutdownNow(); writer.shutdownNow() }
    }

    @Test
    fun boundedQueue_declaresLossAndFinalizationDrainsInOrder() {
        val writer = java.util.concurrent.Executors.newSingleThreadExecutor()
        val gate = java.util.concurrent.CountDownLatch(1)
        val entered = java.util.concurrent.CountDownLatch(1)
        try {
            val store = MemoryJournalStore()
            val j = SessionJournal(store, { 1_760_000_000_000L }, { -300 }, { java.util.UUID.randomUUID().toString() }, writer)
            val start = com.juanrueda.monitoring_engine.journal.SessionStart("s", "e", "lab-eye-rules-0.1", "experimental", "eye", "model", "0".repeat(64), "cal", .3, .3, 120, .95)
            assertTrue(j.started(start))
            store.beforeCommit = { entered.countDown(); check(gate.await(10, java.util.concurrent.TimeUnit.SECONDS)) }
            j.closureDetected(1, 1000)
            assertTrue(entered.await(2, java.util.concurrent.TimeUnit.SECONDS))
            for (n in 2..300) j.closureDetected(n, n * 1000L)
            assertEquals(RecordStatus.INCOMPLETE, j.status)
            gate.countDown()
            assertTrue(j.finalized(com.juanrueda.monitoring_engine.journal.SessionTotals(300_000, 300_000, 0, 0, 300, 0, 0, 0)))
            assertEquals(256, store.ofType(RecordType.CLOSURE_DETECTED).size)
            assertEquals(44, store.ofType(RecordType.SESSION_FINALIZED).single().long("recordsLost"))
            assertEquals((1L..258L).toList(), store.records.map { it.journalSequence })
        } finally { gate.countDown(); writer.shutdownNow() }
    }

    @Test
    fun closeCivilTime_isTheStopRequest_notTheTimeAfterDrainingWrites() {
        val writer = java.util.concurrent.ThreadPoolExecutor(1, 1, 0,
            java.util.concurrent.TimeUnit.MILLISECONDS, java.util.concurrent.LinkedBlockingQueue())
        val control = java.util.concurrent.Executors.newSingleThreadExecutor()
        val gate = java.util.concurrent.CountDownLatch(1)
        val entered = java.util.concurrent.CountDownLatch(1)
        val wall = java.util.concurrent.atomic.AtomicLong(1000)
        try {
            val store = MemoryJournalStore()
            val j = SessionJournal(store, wall::get, { -300 }, { java.util.UUID.randomUUID().toString() }, writer)
            assertTrue(j.started(com.juanrueda.monitoring_engine.journal.SessionStart(
                "s", "e", "lab-eye-rules-0.1", "experimental", "eye", "model", "0".repeat(64), "cal", .3, .3, 120, .95)))
            store.beforeCommit = { entered.countDown(); check(gate.await(10, java.util.concurrent.TimeUnit.SECONDS)) }
            wall.set(2000)
            j.checkpoint(com.juanrueda.monitoring_engine.journal.SessionTotals(1000, 1000, 0, 0, 0, 0, 0, 0), JournalLifecycle.ACTIVE)
            assertTrue(entered.await(2, java.util.concurrent.TimeUnit.SECONDS))
            val close = control.submit<Boolean> { j.finalized(com.juanrueda.monitoring_engine.journal.SessionTotals(1000, 1000, 0, 0, 0, 0, 0, 0)) }
            val deadline = System.nanoTime() + 2_000_000_000L
            while (writer.queue.isEmpty() && System.nanoTime() < deadline) Thread.yield()
            assertFalse(writer.queue.isEmpty(), "el cierre ya espera detrás del checkpoint")
            wall.set(9000)
            gate.countDown()
            assertTrue(close.get(5, java.util.concurrent.TimeUnit.SECONDS))
            assertEquals(2000, store.ofType(RecordType.SESSION_FINALIZED).single().long("endedEpochMs"))
        } finally { gate.countDown(); writer.shutdownNow(); control.shutdownNow() }
    }

    @Test
    fun failedJournalOpen_doesNotDisableDurabilityOnRetry() {
        val rig = Rig()
        rig.factoryFails = true
        runCatching { rig.c.ensureJournal() }
        rig.factoryFails = false
        rig.started()
        assertEquals(1, rig.store.ofType(RecordType.SESSION_STARTED).size)
        assertEquals(RecordStatus.DURABLE, rig.last.recordStatus)
    }

    @Test
    fun failedJournalFactory_rejectsStartWithTypedFailureAndCanRetry() {
        val rig = Rig()
        rig.calibrated()
        val sound = rig.c.testSound().state.soundTestId!!
        rig.c.confirmSoundHeard(sound)
        rig.feed(rig.nowMs + 50, rig.nowMs + 50, open)
        rig.factoryFails = true
        val result = rig.c.startSession(rig.last.calibrationId!!, sound)
        assertFalse(result.accepted)
        assertEquals("journalWriteFailed", result.errorCode)
        assertEquals(SessionLifecycle.NONE, result.state.lifecycle)
        rig.factoryFails = false
        val retry = rig.c.startSession(rig.last.calibrationId!!, sound)
        assertTrue(retry.accepted)
        assertEquals(1, rig.store.ofType(RecordType.SESSION_STARTED).size)
    }

    @Test
    fun failedFinalization_releasesResources_andCanRecoverInSameEngine() {
        val rig = Rig()
        val first = rig.started()
        rig.feed(rig.nowMs + 100, rig.nowMs + 1500, open)
        rig.store.failWrites = true
        rig.c.stopSession(first)
        assertEquals(1, rig.releases)
        assertEquals(SessionLifecycle.FINALIZED, rig.last.lifecycle)
        assertEquals(RecordStatus.INCOMPLETE, rig.last.recordStatus)
        rig.store.failWrites = false
        rig.c.ensureJournal()
        assertEquals(JournalLifecycle.INTERRUPTED, rig.store.session(first)!!.lifecycle)
        assertNull(rig.store.session(first)!!.endOffsetMs)
        assertNotEquals(first, rig.started())
        assertEquals(1, rig.store.ofType(RecordType.INTERRUPTION_RECOVERED).size)
    }

    @Test
    fun recovery_marksOpenSessionInterruptedOnce_withoutResumingOrInventingEnd() {
        val store = MemoryJournalStore()
        val a = Rig(store)
        val id = a.started()
        a.feed(a.nowMs + 100, a.nowMs + 2500, open)
        val durable = store.session(id)!!.latestDurableOffsetMs
        // Muerte del proceso: el coordinador A desaparece sin cerrar nada.
        val b = Rig(store, startMs = 500_000)
        assertEquals(0, b.factoryCalls, "el journal se abre bajo demanda")
        assertEquals(1, b.c.ensureJournal())
        val rec = store.ofType(RecordType.INTERRUPTION_RECOVERED).single()
        assertEquals(id, rec.sessionId)
        assertNull(rec.sessionOffsetMs, "la recuperación no es tiempo de sesión")
        assertEquals(durable, rec.long("lastDurableOffsetMs"))
        val row = store.session(id)!!
        assertEquals(JournalLifecycle.INTERRUPTED, row.lifecycle)
        assertNull(row.endOffsetMs, "sin final atribuido")
        assertEquals(durable, row.latestDurableOffsetMs)
        assertTrue(store.ofType(RecordType.SESSION_FINALIZED).isEmpty())
        // No se reanuda: la nueva instancia no tiene sesión y no sigue escribiendo.
        assertEquals(SessionLifecycle.NONE, b.c.snapshot().lifecycle)
        assertNull(b.c.snapshot().sessionId)
        // Una tercera apertura no la vuelve a recuperar.
        assertEquals(0, Rig(store, startMs = 900_000).c.ensureJournal())
        assertEquals(1, store.ofType(RecordType.INTERRUPTION_RECOVERED).size)
        // Y se puede iniciar otra sesión después.
        val c = Rig(store, startMs = 1_000_000)
        assertNotEquals(id, c.started())
    }

    @Test
    fun recovery_runsBeforeStartEvenWithoutAnExplicitRead() {
        val store = MemoryJournalStore()
        val a = Rig(store)
        val first = a.started()
        val b = Rig(store, startMs = 100_000)
        b.started()
        assertEquals(JournalLifecycle.INTERRUPTED, store.session(first)!!.lifecycle)
        val types = store.records.map { it.recordType }
        assertTrue(types.indexOf(RecordType.INTERRUPTION_RECOVERED) < types.lastIndexOf(RecordType.SESSION_STARTED))
    }

    @Test
    fun pausedSessionLostWithProcess_isInterruptedNotFinalized() {
        val store = MemoryJournalStore()
        val a = Rig(store)
        val id = a.started()
        a.feed(a.nowMs + 100, a.nowMs + 1500, open)
        a.c.pauseSession(id)
        a.at(a.nowMs + 3000)
        val b = Rig(store, startMs = 100_000)
        b.c.ensureJournal()
        val rec = store.ofType(RecordType.INTERRUPTION_RECOVERED).single()
        assertTrue("\"previousLifecycle\":\"paused\"" in payload(rec))
        assertEquals(JournalLifecycle.INTERRUPTED, store.session(id)!!.lifecycle)
    }

    @Test
    fun engineDetach_keepsSessionOpenForRecovery_withLastCheckpoint() {
        val store = MemoryJournalStore()
        val a = Rig(store)
        val id = a.started()
        a.feed(a.nowMs + 100, a.nowMs + 1650, open)
        a.c.shutdown()
        val row = store.session(id)!!
        assertEquals(JournalLifecycle.ACTIVE, row.lifecycle, "desconectar no es un cierre confirmado")
        assertTrue(row.latestDurableOffsetMs >= 1600)
        // Tras desconectar, el coordinador antiguo ya no escribe.
        val n = store.records.size
        a.at(a.nowMs + 5000)
        assertEquals(n, store.records.size)
        Rig(store, startMs = 100_000).c.ensureJournal()
        assertEquals(JournalLifecycle.INTERRUPTED, store.session(id)!!.lifecycle)
    }

    @Test
    fun withoutSession_journalIsNeverOpened() {
        // La DEMO comparte el plugin: cámara, calibración y sonido no abren el journal.
        val rig = Rig()
        rig.calibrated()
        rig.c.testSound()
        rig.feed(rig.nowMs + 50, rig.nowMs + 3000, open)
        rig.c.snapshot()
        assertEquals(0, rig.factoryCalls)
        assertEquals(RecordStatus.NONE, rig.last.recordStatus)
        assertNull(rig.last.latestDurableOffsetMs)
    }

    // ------------------------------------------------------------- lectura

    @Test
    fun host_readsPendingInOrder_andAcksOnlyExactRevisions() {
        val store = MemoryJournalStore()
        val rig = Rig(store)
        val id = rig.started()
        rig.feed(rig.nowMs + 100, rig.nowMs + 3000, open)
        rig.c.stopSession(id)
        var recovered = 0
        val host = ExperimentalJournalHost(store, ensureRecovered = { recovered++ })
        val all = store.records.size
        val first = host.readPendingRecords(2)
        assertEquals(1, recovered)
        assertEquals(listOf(1L, 2L), first.records.map { it.journalSequence })
        assertTrue(first.hasMore)
        assertEquals(all.toLong(), first.highWatermark)
        // Hash distinto: no se confirma.
        assertEquals(0, host.acknowledgeRecords(listOf(first.records[0].recordId), listOf("0".repeat(64))))
        assertEquals(2, host.acknowledgeRecords(first.records.map { it.recordId }, first.records.map { it.payloadHash }))
        // Repetir el ACK no cambia nada (idempotente).
        assertEquals(0, host.acknowledgeRecords(first.records.map { it.recordId }, first.records.map { it.payloadHash }))
        val rest = host.readPendingRecords(500)
        assertEquals(all - 2, rest.records.size, "el límite se acota a 100 y el resto sigue pendiente")
        assertEquals(3L, rest.records.first().journalSequence)
        assertFalse(rest.hasMore)
    }
}
