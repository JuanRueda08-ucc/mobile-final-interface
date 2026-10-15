package com.juanrueda.monitoring_engine

import com.juanrueda.monitoring_engine.journal.JournalConflict
import com.juanrueda.monitoring_engine.journal.JournalRecord
import com.juanrueda.monitoring_engine.journal.JournalSession
import com.juanrueda.monitoring_engine.journal.JournalStore
import com.juanrueda.monitoring_engine.journal.PendingRecord
import com.juanrueda.monitoring_engine.journal.SessionChange

/**
 * Doble en memoria de [JournalStore] con las reglas de `SqliteJournalStore`:
 * commit atómico, una sola sesión abierta, ciclo esperado, secuencia max+1 e
 * IDs únicos. [failWrites] simula un fallo de escritura (disco lleno, base
 * bloqueada). La durabilidad real se prueba con SQLite en Android
 * (`JournalSqliteInstrumentedTest`).
 */
internal class MemoryJournalStore : JournalStore {
    val records = mutableListOf<JournalRecord>()
    val acked = mutableSetOf<String>()
    val sessions = linkedMapOf<String, JournalSession>()
    var failWrites = false
    var commits = 0

    override fun commit(records: List<PendingRecord>, change: SessionChange?): List<JournalRecord> {
        if (failWrites) throw IllegalStateException("escritura simulada fallida")
        val newSessions = LinkedHashMap(sessions)
        if (change != null) {
            val create = change.create
            if (create != null) {
                check(create.sessionId !in newSessions) { "UNIQUE session_id" }
                check(newSessions.values.none { it.lifecycle.open }) { "UNIQUE n_one_current_session" }
                newSessions[create.sessionId] = create
            } else {
                val cur = newSessions[change.sessionId]
                if (cur == null || (change.expected != null && cur.lifecycle !in change.expected!!)) {
                    throw JournalConflict("fuera de ciclo")
                }
                newSessions[change.sessionId] = cur.copy(
                    lifecycle = change.lifecycle,
                    latestDurableOffsetMs = maxOf(cur.latestDurableOffsetMs, change.latestDurableOffsetMs),
                    endOffsetMs = change.endOffsetMs ?: cur.endOffsetMs,
                )
            }
        }
        var next = highWatermark()
        val ids = this.records.map { it.recordId }.toMutableSet()
        val built = records.map {
            check(ids.add(it.recordId)) { "UNIQUE record_id" }
            JournalRecord.build(
                ++next, it.recordId, it.sessionId, it.recordType, it.occurredEpochMs,
                it.occurredOffsetMinutes, it.sessionOffsetMs, it.payload,
            )
        }
        this.records += built
        sessions.clear()
        sessions.putAll(newSessions)
        commits++
        return built
    }

    override fun openSessions() = sessions.values.filter { it.lifecycle.open }

    override fun session(sessionId: String) = sessions[sessionId]

    override fun readPending(limit: Int) = records.filter { it.recordId !in acked }.take(limit)

    override fun highWatermark() = records.maxOfOrNull { it.journalSequence } ?: 0L

    override fun acknowledge(records: List<Pair<String, String>>): Int = records.count { (id, hash) ->
        this.records.any { it.recordId == id && it.payloadHash == hash } && acked.add(id)
    }

    override fun close() = Unit

    fun ofType(type: String) = records.filter { it.recordType == type }
}
