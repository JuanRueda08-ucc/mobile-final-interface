package com.juanrueda.monitoring_engine.journal

/** Ciclo materializado de una sesión en el journal (Área 06 §7, subconjunto). */
internal enum class JournalLifecycle(val code: String) {
    ACTIVE("active"),
    PAUSED("paused"),
    FINALIZED("finalized"),
    INTERRUPTED("interrupted");

    val open: Boolean get() = this == ACTIVE || this == PAUSED

    companion object {
        fun of(code: String) = entries.first { it.code == code }
    }
}

/** Materialización mínima de la sesión (`n_sessions`). */
internal data class JournalSession(
    val sessionId: String,
    val engineInstanceId: String,
    val lifecycle: JournalLifecycle,
    val startedEpochMs: Long,
    val startOffsetMinutes: Int,
    val latestDurableOffsetMs: Long,
    val endOffsetMs: Long?,
)

/** Hecho por escribir: la secuencia y el hash los asigna el almacén. */
internal data class PendingRecord(
    val recordId: String,
    val sessionId: String?,
    val recordType: String,
    val occurredEpochMs: Long,
    val occurredOffsetMinutes: Int,
    val sessionOffsetMs: Long?,
    val payload: Map<String, Any?>,
)

/**
 * Cambio de la materialización que acompaña a los hechos en la **misma**
 * transacción. [expected] es el ciclo que debe tener la sesión: si no
 * coincide, la transacción entera se deshace (cierre único, recuperación
 * única). [create] crea la fila (inicio).
 */
internal data class SessionChange(
    val sessionId: String,
    val lifecycle: JournalLifecycle,
    val latestDurableOffsetMs: Long,
    val expected: Set<JournalLifecycle>? = null,
    val create: JournalSession? = null,
    val endOffsetMs: Long? = null,
)

/** La transición no se aplicó porque la sesión no estaba en el ciclo esperado. */
internal class JournalConflict(message: String) : IllegalStateException(message)

/**
 * Almacén durable del journal experimental. En Android es SQLite
 * ([SqliteJournalStore], `vigia_journal_real_v1.sqlite`); las pruebas JVM
 * usan un doble en memoria con las mismas reglas.
 *
 * - [commit] es atómico: hechos y materialización, o nada.
 * - Los hechos son inmutables; solo cambia su estado de ACK.
 * - La secuencia es global, creciente y no se reutiliza (los hechos no se
 *   borran en este prototipo).
 */
internal interface JournalStore {
    fun commit(records: List<PendingRecord>, change: SessionChange?): List<JournalRecord>

    fun openSessions(): List<JournalSession>

    fun session(sessionId: String): JournalSession?

    /** Hechos sin ACK en orden de secuencia, como mucho [limit]. */
    fun readPending(limit: Int): List<JournalRecord>

    /** Último número de secuencia asignado (0 sin hechos). */
    fun highWatermark(): Long

    /** ACK de las revisiones exactas (ID y hash). Devuelve cuántas se marcaron. */
    fun acknowledge(records: List<Pair<String, String>>): Int

    fun close()
}
