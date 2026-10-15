package com.juanrueda.monitoring_engine

import android.database.sqlite.SQLiteException
import android.os.Process
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.juanrueda.monitoring_engine.journal.ExperimentalJournalHost
import com.juanrueda.monitoring_engine.journal.JournalConflict
import com.juanrueda.monitoring_engine.journal.JournalLifecycle
import com.juanrueda.monitoring_engine.journal.RecordType
import com.juanrueda.monitoring_engine.journal.SessionJournal
import com.juanrueda.monitoring_engine.journal.SessionStart
import com.juanrueda.monitoring_engine.journal.SessionTotals
import com.juanrueda.monitoring_engine.journal.SqliteJournalStore
import java.util.UUID
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Fase 5D · journal experimental sobre **SQLite real de Android**
 * (`SqliteJournalStore`), sin cámara ni sesión con rostro: los hechos se
 * escriben con [SessionJournal] y valores fijados por la prueba.
 *
 * - [sqlite_commitReopenAckAndConstraints]: conexiones nuevas, ACK exacto,
 *   inmutabilidad, una sola sesión abierta y cierre único.
 * - Reinicio real del proceso: [processRestart_step1_leaveOpenSession] y,
 *   en **otra invocación** de `am instrument` (otro proceso),
 *   [processRestart_step2_recoverInNewProcess]. Ver la guía de la fase 5D.
 */
@RunWith(AndroidJUnit4::class)
class JournalSqliteInstrumentedTest {
    private val context = InstrumentationRegistry.getInstrumentation().targetContext

    private fun journal(store: SqliteJournalStore) = SessionJournal(
        store, System::currentTimeMillis, { -300 }, { UUID.randomUUID().toString() },
    )

    private fun start(id: String, engine: String) = SessionStart(
        id, engine, "lab-eye-rules-0.1", "experimental", "mp-eye6-v1", "model", "0".repeat(64),
        "cal-$id", 0.30, 0.29, 120, 0.95,
    )

    private fun totals(at: Long) = SessionTotals(at, at, at / 2, 0, 0, 0, 0, 0)

    @Test
    fun sqlite_commitReopenAckAndConstraints() {
        val name = "journal_test_${UUID.randomUUID()}.sqlite"
        try {
            var store = SqliteJournalStore(context, name)
            val j = journal(store)
            assertTrue(j.started(start("s1", "e1")))
            j.checkpoint(totals(1000), JournalLifecycle.ACTIVE)
            // Segunda sesión abierta: la restricción única la rechaza.
            assertFalse(journal(store).started(start("s2", "e1")))
            assertTrue(j.finalized(totals(2000)))
            store.close()

            // Conexión nueva sobre el mismo archivo.
            store = SqliteJournalStore(context, name)
            val host = ExperimentalJournalHost(store)
            val batch = host.readPendingRecords(100)
            assertEquals(
                listOf(RecordType.SESSION_STARTED, RecordType.PROGRESS_CHECKPOINT, RecordType.SESSION_FINALIZED),
                batch.records.map { it.recordType },
            )
            assertEquals(listOf(1L, 2L, 3L), batch.records.map { it.journalSequence })
            assertEquals(JournalLifecycle.FINALIZED, store.session("s1")!!.lifecycle)
            assertEquals(2000L, store.session("s1")!!.endOffsetMs)
            // Vector escrito y releído por SQLite Android para la prueba Dart.
            for (r in batch.records) {
                android.util.Log.i("VigiaJournalVector", com.juanrueda.monitoring_engine.journal.JournalCodec.encode(mapOf(
                    "journalSequence" to r.journalSequence, "recordId" to r.recordId,
                    "sessionId" to r.sessionId, "recordType" to r.recordType,
                    "occurredEpochMs" to r.occurredEpochMs, "occurredOffsetMinutes" to r.occurredOffsetMinutes,
                    "sessionOffsetMs" to r.sessionOffsetMs, "payloadSchemaVersion" to r.payloadSchemaVersion,
                    "payloadJson" to r.payloadJson, "payloadHash" to r.payloadHash,
                )))
            }
            // ACK con hash ajeno: nada; exacto: los dos primeros.
            assertEquals(0L, host.acknowledgeRecords(listOf(batch.records[0].recordId), listOf("f".repeat(64))))
            assertEquals(
                2L,
                host.acknowledgeRecords(batch.records.take(2).map { it.recordId }, batch.records.take(2).map { it.payloadHash }),
            )
            store.close()

            store = SqliteJournalStore(context, name)
            assertEquals(listOf(3L), store.readPending(100).map { it.journalSequence })
            // Hechos inmutables e imborrables.
            val db = context.openOrCreateDatabase(name, 0, null)
            try {
                db.execSQL("UPDATE n_outbox SET payload_json='{}' WHERE journal_sequence=1")
                fail("el trigger debía impedir la modificación")
            } catch (e: SQLiteException) {
                assertTrue(e.message!!.contains("immutableJournalRecord"))
            }
            try {
                db.execSQL("DELETE FROM n_outbox")
                fail("el trigger debía impedir el borrado")
            } catch (e: SQLiteException) {
                assertTrue(e.message!!.contains("journalRecordDelete"))
            }
            db.close()
            // Cierre único: el segundo cierre no cambia la sesión.
            val again = journal(store)
            try {
                store.commit(emptyList(), com.juanrueda.monitoring_engine.journal.SessionChange(
                    "s1", JournalLifecycle.FINALIZED, 9000,
                    expected = setOf(JournalLifecycle.ACTIVE, JournalLifecycle.PAUSED), endOffsetMs = 9000,
                ))
                fail("debía rechazarse")
            } catch (e: JournalConflict) {
                assertEquals(2000L, store.session("s1")!!.endOffsetMs)
            }
            assertNull(again.latestDurableOffset)
            store.close()
        } finally {
            context.deleteDatabase(name)
        }
    }

    @Test
    fun processRestart_step1_leaveOpenSession() {
        context.deleteDatabase(RESTART_DB)
        val store = SqliteJournalStore(context, RESTART_DB)
        val j = journal(store)
        assertTrue(j.started(start("restart-pid-${Process.myPid()}", "engine-pid-${Process.myPid()}")))
        j.checkpoint(totals(1000), JournalLifecycle.ACTIVE)
        j.checkpoint(totals(2000), JournalLifecycle.ACTIVE)
        // Sin cerrar la base ni la sesión: el proceso termina al acabar.
    }

    @Test
    fun sqlite_failuresRollbackStartAndClose_andRecoveryDoesNotInventLostFacts() {
        val name = "journal_failure_${UUID.randomUUID()}.sqlite"
        try {
            var store = SqliteJournalStore(context, name)
            store.highWatermark() // crea el esquema
            val db = context.openOrCreateDatabase(name, 0, null)
            fun block() = db.execSQL("CREATE TRIGGER disk_failure BEFORE INSERT ON n_outbox BEGIN SELECT RAISE(ABORT,'injectedDiskFailure'); END")
            fun unblock() = db.execSQL("DROP TRIGGER disk_failure")
            val j = journal(store)
            block()
            assertFalse(j.started(start("s1", "e1")))
            assertNull(store.session("s1"))
            assertEquals(0L, store.highWatermark())
            unblock()
            assertTrue(j.started(start("s1", "e1")))
            j.checkpoint(totals(1000), JournalLifecycle.ACTIVE)
            block()
            j.closureDetected(1, 1500)
            j.playback(1, 1, 1500, null)
            j.checkpoint(totals(2000), JournalLifecycle.ACTIVE)
            assertFalse(j.finalized(totals(3000)))
            assertEquals(com.juanrueda.monitoring_engine.journal.RecordStatus.INCOMPLETE, j.status)
            assertEquals(JournalLifecycle.ACTIVE, store.session("s1")!!.lifecycle)
            assertNull(store.session("s1")!!.endOffsetMs)
            // Tampoco pudo guardarse la pérdida: desaparece la memoria del escritor.
            store.close()
            unblock()
            db.close()
            store = SqliteJournalStore(context, name)
            assertEquals(1, journal(store).recover("e2"))
            assertEquals(0, journal(store).recover("e2"))
            assertEquals(1000L, store.session("s1")!!.latestDurableOffsetMs)
            assertNull(store.session("s1")!!.endOffsetMs)
            assertEquals(JournalLifecycle.INTERRUPTED, store.session("s1")!!.lifecycle)
            assertEquals(listOf("sessionStarted", "progressCheckpoint", "interruptionRecovered"), store.readPending(100).map { it.recordType })
            assertEquals(listOf(1L, 2L, 3L), store.readPending(100).map { it.journalSequence })
            store.close()
        } finally { context.deleteDatabase(name) }
    }

    @Test
    fun sqlite_monitoringLossSurvivesSuccessfulClose() {
        val name = "journal_loss_${UUID.randomUUID()}.sqlite"
        try {
            val store = SqliteJournalStore(context, name)
            val j = journal(store)
            assertTrue(j.started(start("s1", "e1")))
            val db = context.openOrCreateDatabase(name, 0, null)
            db.execSQL("CREATE TRIGGER disk_failure BEFORE INSERT ON n_outbox BEGIN SELECT RAISE(ABORT,'injectedDiskFailure'); END")
            j.closureDetected(1, 1000)
            j.playback(1, 1, 1000, null)
            db.execSQL("DROP TRIGGER disk_failure")
            db.close()
            assertTrue(j.finalized(totals(2000)))
            assertTrue(store.readPending(100).last().payloadJson.contains("\"recordsLost\":2"))
            assertEquals(listOf("sessionStarted", "sessionFinalized"), store.readPending(100).map { it.recordType })
            store.close()
        } finally { context.deleteDatabase(name) }
    }

    @Test
    fun sqlite_checkpointCost_noCamera_noD1() {
        val name = "journal_cost_${UUID.randomUUID()}.sqlite"
        try {
            val store = SqliteJournalStore(context, name)
            val j = journal(store)
            assertTrue(j.started(start("cost", "e1")))
            val durations = (1L..200L).map { n ->
                val before = System.nanoTime()
                j.checkpoint(totals(n * 1000), JournalLifecycle.ACTIVE)
                (System.nanoTime() - before) / 1_000_000.0
            }.sorted()
            android.util.Log.i("VigiaJournalCost", "SQLite FULL synthetic n=200 p50=${durations[99]} p95=${durations[189]} max=${durations.last()} ms; emulator, not D1")
            assertEquals(201L, store.highWatermark())
            store.close()
        } finally { context.deleteDatabase(name) }
    }

    @Test
    fun sqlite_asyncCheckpointCost_andDurableBarrier_noCamera_noD1() {
        val name = "journal_async_cost_${UUID.randomUUID()}.sqlite"
        val writer = java.util.concurrent.Executors.newSingleThreadExecutor()
        try {
            val store = SqliteJournalStore(context, name)
            val j = SessionJournal(store, System::currentTimeMillis, { -300 }, { UUID.randomUUID().toString() }, writer)
            assertTrue(j.started(start("cost", "e1")))
            val durations = (1L..200L).map { n ->
                val before = System.nanoTime()
                j.checkpoint(totals(n * 1000), JournalLifecycle.ACTIVE)
                (System.nanoTime() - before) / 1_000_000.0
            }.sorted()
            val beforeClose = System.nanoTime()
            assertTrue(j.finalized(totals(201_000)))
            val drainMs = (System.nanoTime() - beforeClose) / 1_000_000.0
            android.util.Log.i("VigiaJournalCost", "ASYNC synthetic n=200 enqueue p50=${durations[99]} p95=${durations[189]} max=${durations.last()} ms; drainAndClose=$drainMs ms; emulator, not D1")
            assertEquals(202L, store.highWatermark())
            assertEquals(JournalLifecycle.FINALIZED, store.session("cost")!!.lifecycle)
            store.close()
        } finally { writer.shutdownNow(); context.deleteDatabase(name) }
    }

    @Test
    fun processRestart_step2_recoverInNewProcess() {
        val store = SqliteJournalStore(context, RESTART_DB)
        val open = store.openSessions()
        assertEquals("hace falta ejecutar antes step1 en otro proceso", 1, open.size)
        val s = open.single()
        assertFalse("otro proceso", s.sessionId == "restart-pid-${Process.myPid()}")
        assertEquals(2000L, s.latestDurableOffsetMs)
        val engine = "engine-pid-${Process.myPid()}"
        assertEquals(1, journal(store).recover(engine))
        assertEquals(0, journal(store).recover(engine), "una sola vez")
        val row = store.session(s.sessionId)!!
        assertEquals(JournalLifecycle.INTERRUPTED, row.lifecycle)
        assertNull(row.endOffsetMs)
        assertEquals(2000L, row.latestDurableOffsetMs)
        val types = store.readPending(100).map { it.recordType }
        assertEquals(1, types.count { it == RecordType.INTERRUPTION_RECOVERED })
        assertFalse(RecordType.SESSION_FINALIZED in types)
        store.close()
        context.deleteDatabase(RESTART_DB)
    }

    @Test
    fun processRestart_lossStep1_unpersistedFailure() {
        context.deleteDatabase(LOSS_RESTART_DB)
        val store = SqliteJournalStore(context, LOSS_RESTART_DB)
        val j = journal(store)
        assertTrue(j.started(start("loss-pid-${Process.myPid()}", "engine-pid-${Process.myPid()}")))
        j.checkpoint(totals(1000), JournalLifecycle.ACTIVE)
        val db = context.openOrCreateDatabase(LOSS_RESTART_DB, 0, null)
        db.execSQL("CREATE TRIGGER disk_failure BEFORE INSERT ON n_outbox BEGIN SELECT RAISE(ABORT,'injectedDiskFailure'); END")
        j.closureDetected(1, 2000)
        j.checkpoint(totals(3000), JournalLifecycle.ACTIVE)
        assertEquals(com.juanrueda.monitoring_engine.journal.RecordStatus.INCOMPLETE, j.status)
        assertEquals(2L, store.highWatermark())
        // No se guarda marca de pérdida ni se cierra: el proceso acaba aquí.
    }

    @Test
    fun processRestart_lossStep2_recoverWithoutMemory() {
        val store = SqliteJournalStore(context, LOSS_RESTART_DB)
        val s = store.openSessions().single()
        assertFalse("otro PID", s.sessionId == "loss-pid-${Process.myPid()}")
        val db = context.openOrCreateDatabase(LOSS_RESTART_DB, 0, null)
        db.execSQL("DROP TRIGGER disk_failure")
        db.close()
        val j = journal(store)
        assertEquals(1, j.recover("new-pid-${Process.myPid()}"))
        assertEquals(0, j.recover("new-pid-${Process.myPid()}"))
        val recovered = store.session(s.sessionId)!!
        assertEquals(JournalLifecycle.INTERRUPTED, recovered.lifecycle)
        assertEquals(1000L, recovered.latestDurableOffsetMs)
        assertNull(recovered.endOffsetMs)
        assertEquals(listOf("sessionStarted", "progressCheckpoint", "interruptionRecovered"), store.readPending(100).map { it.recordType })
        store.close()
        context.deleteDatabase(LOSS_RESTART_DB)
    }

    /**
     * Semilla **sintética** para la comprobación de extremo a extremo en la
     * app (guía 5D): una sesión cerrada y otra abierta con el formato real
     * del journal. No es una sesión con cámara; los valores los fija la prueba.
     */
    @Test
    fun seed_forAppEndToEnd() {
        context.deleteDatabase(SEED_DB)
        val store = SqliteJournalStore(context, SEED_DB)
        val a = journal(store)
        assertTrue(a.started(start("e2e-finalizada-${UUID.randomUUID()}", "engine-seed-1")))
        a.checkpoint(totals(1000), JournalLifecycle.ACTIVE)
        a.closureDetected(1, 20_000)
        a.playback(1, 1, 20_000, null)
        a.pauseStarted(1, SessionTotals(30_000, 30_000, 24_000, 0, 1, 1, 0, 1))
        a.pauseEnded(1, SessionTotals(40_000, 30_000, 24_000, 10_000, 1, 1, 0, 1))
        assertTrue(a.finalized(SessionTotals(70_000, 60_000, 45_000, 10_000, 1, 1, 0, 1)))
        val b = journal(store)
        assertTrue(b.started(start("e2e-abierta-${UUID.randomUUID()}", "engine-seed-1")))
        b.checkpoint(SessionTotals(5_000, 5_000, 4_000, 0, 0, 0, 0, 0), JournalLifecycle.ACTIVE)
        store.close()
    }

    private fun assertEquals(message: String, expected: Int, actual: Int) =
        org.junit.Assert.assertEquals(message, expected.toLong(), actual.toLong())

    private fun assertEquals(expected: Int, actual: Int, message: String) =
        org.junit.Assert.assertEquals(message, expected.toLong(), actual.toLong())

    companion object {
        const val RESTART_DB = "journal_restart_test.sqlite"
        const val LOSS_RESTART_DB = "journal_loss_restart_test.sqlite"
        const val SEED_DB = "journal_e2e_seed.sqlite"
    }
}
