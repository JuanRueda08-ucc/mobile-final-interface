package com.juanrueda.monitoring_engine.journal

import java.util.concurrent.Callable
import java.util.concurrent.ExecutionException
import java.util.concurrent.ExecutorService
import java.util.concurrent.atomic.AtomicInteger

/** Totales de la sesión conocidos por el coordinador en un instante (ms). */
internal data class SessionTotals(
    val offsetMs: Long,
    val activeMs: Long,
    val evaluableMs: Long,
    val pausedMs: Long,
    val closureActivations: Int,
    val tonesPlayed: Int,
    val tonesFailed: Int,
    val pauseCount: Int,
) {
    fun toPayload(): Map<String, Any?> = mapOf(
        "activeMs" to activeMs,
        "evaluableMs" to evaluableMs,
        "nonEvaluableMs" to activeMs - evaluableMs,
        "pausedMs" to pausedMs,
        "closureActivations" to closureActivations,
        "tonesPlayed" to tonesPlayed,
        "tonesFailed" to tonesFailed,
        "pauseCount" to pauseCount,
    )
}

/** Datos inmutables de la sesión al confirmar su inicio (SessionMetadataV1, subconjunto). */
internal data class SessionStart(
    val sessionId: String,
    val engineInstanceId: String,
    val profileId: String,
    val qualificationStatus: String,
    val landmarkSchema: String,
    val modelId: String,
    val modelSha256: String,
    val calibrationId: String,
    val openEarRight: Double,
    val openEarLeft: Double,
    val calibrationSamples: Int,
    val calibrationCoverage: Double,
)

/** Estado del registro de la sesión (Área 04 §7.3 `recordStatus`). */
internal enum class RecordStatus(val code: String) {
    /** Sin sesión que registrar. */
    NONE("none"),

    /** Todos los hechos de la sesión se confirmaron en el journal. */
    DURABLE("durable"),

    /** Hechos en la cola local, todavía no confirmados por SQLite. */
    PENDING("pending"),

    /** Algún hecho no se pudo escribir: el registro está incompleto. */
    INCOMPLETE("incomplete"),
}

/**
 * Escritor del journal de la sesión experimental (fase 5D). Lo usa el
 * coordinador. En Android, las escrituras del recorrido van a un escritor
 * FIFO separado del cerrojo del motor. Inicio/cierre esperan su commit;
 * los demás hechos tienen una cola acotada de 256 operaciones compactas.
 *
 * - El inicio solo se confirma si `sessionStarted` es durable: sin journal no
 *   hay sesión ([started] devuelve `false`).
 * - Los demás hechos no bloquean el aviso: se escriben **después** del tono.
 *   Si una escritura falla, la sesión sigue, se cuenta la pérdida y el
 *   registro queda incompleto. La cola no reintenta ni es durable; perder
 *   el proceso sin cierre siempre se recupera como incompleto.
 * - Cierre único: `sessionFinalized` exige la sesión abierta en la misma
 *   transacción.
 * - [recover] marca como interrumpidas, una sola vez, las sesiones abiertas
 *   por instancias anteriores del motor; no las reanuda ni les da final.
 *
 * Sin imágenes, puntos faciales ni series por observación: solo límites,
 * contadores y la referencia compacta de la calibración.
 */
internal class SessionJournal(
    private val store: JournalStore,
    private val wallClockMs: () -> Long,
    private val zoneOffsetMinutes: (Long) -> Int,
    private val newId: () -> String,
    private val executor: ExecutorService? = null,
) {
    @Volatile private var sessionId: String? = null
    private val lost = AtomicInteger()
    private val queued = AtomicInteger()
    @Volatile private var latestDurableOffsetMs = 0L

    @Volatile private var savedStatus = RecordStatus.NONE
    val status: RecordStatus
        get() = if (savedStatus == RecordStatus.DURABLE && queued.get() > 0) RecordStatus.PENDING else savedStatus

    /** Barrera FIFO: inicio/cierre solo responden después del commit real. */
    private fun <T> serialized(work: () -> T): T {
        val writer = executor ?: return work()
        return try {
            writer.submit(Callable { work() }).get()
        } catch (e: ExecutionException) {
            throw (e.cause as? RuntimeException ?: IllegalStateException(e.cause))
        } catch (e: InterruptedException) {
            Thread.currentThread().interrupt()
            throw IllegalStateException("Journal interrumpido", e)
        }
    }

    /** Último límite confirmado de la sesión actual o recién cerrada. */
    val latestDurableOffset: Long? get() = if (status == RecordStatus.NONE) null else latestDurableOffsetMs

    /**
     * Recupera sesiones abiertas de instancias anteriores. Devuelve cuántas,
     * o -1 si no se pudo leer el journal (la siguiente instancia lo reintenta;
     * mientras tanto el inicio de otra sesión choca con la sesión abierta).
     */
    fun recover(engineInstanceId: String): Int = serialized { recoverNow(engineInstanceId) }

    private fun recoverNow(engineInstanceId: String): Int {
        var n = 0
        val open = try {
            store.openSessions()
        } catch (e: RuntimeException) {
            return -1
        }
        for (s in open) {
            // Solo la sesión todavía poseída por este escritor sigue viva.
            // Un cierre fallido abandona su ID y puede recuperarse sin matar
            // el proceso ni bloquear todos los inicios posteriores.
            if (s.engineInstanceId == engineInstanceId && s.sessionId == sessionId) continue
            val now = wallClockMs()
            try {
                store.commit(
                    listOf(
                        PendingRecord(
                            recordId = newId(),
                            sessionId = s.sessionId,
                            recordType = RecordType.INTERRUPTION_RECOVERED,
                            occurredEpochMs = now,
                            occurredOffsetMinutes = zoneOffsetMinutes(now),
                            // El instante de recuperación no es tiempo de sesión.
                            sessionOffsetMs = null,
                            payload = mapOf(
                                "recoveredEpochMs" to now,
                                "recoveredByEngineInstanceId" to engineInstanceId,
                                "previousEngineInstanceId" to s.engineInstanceId,
                                "previousLifecycle" to s.lifecycle.code,
                                "lastDurableOffsetMs" to s.latestDurableOffsetMs,
                            ),
                        ),
                    ),
                    SessionChange(
                        sessionId = s.sessionId,
                        lifecycle = JournalLifecycle.INTERRUPTED,
                        latestDurableOffsetMs = s.latestDurableOffsetMs,
                        expected = setOf(JournalLifecycle.ACTIVE, JournalLifecycle.PAUSED),
                    ),
                )
                n++
            } catch (e: JournalConflict) {
                // Otra recuperación ya la cerró: no se registra dos veces.
            } catch (e: RuntimeException) {
                // Sigue abierta: la próxima instancia vuelve a intentarlo.
            }
        }
        return n
    }

    /** Inicio confirmado y durable. `false` si no se pudo escribir. */
    fun started(start: SessionStart): Boolean = serialized { startedNow(start) }

    private fun startedNow(start: SessionStart): Boolean {
        val now = wallClockMs()
        val zone = zoneOffsetMinutes(now)
        return try {
            store.commit(
                listOf(
                    PendingRecord(
                        recordId = newId(),
                        sessionId = start.sessionId,
                        recordType = RecordType.SESSION_STARTED,
                        occurredEpochMs = now,
                        occurredOffsetMinutes = zone,
                        sessionOffsetMs = 0,
                        payload = mapOf(
                            "sessionId" to start.sessionId,
                            "engineInstanceId" to start.engineInstanceId,
                            "startedEpochMs" to now,
                            "startOffsetMinutes" to zone,
                            "profileId" to start.profileId,
                            "qualificationStatus" to start.qualificationStatus,
                            "landmarkSchema" to start.landmarkSchema,
                            "modelId" to start.modelId,
                            "modelSha256" to start.modelSha256,
                            "calibration" to mapOf(
                                "calibrationId" to start.calibrationId,
                                "openEarRightE6" to e6(start.openEarRight),
                                "openEarLeftE6" to e6(start.openEarLeft),
                                "openSamples" to start.calibrationSamples,
                                "openCoverageE6" to e6(start.calibrationCoverage),
                            ),
                        ),
                    ),
                ),
                SessionChange(
                    sessionId = start.sessionId,
                    lifecycle = JournalLifecycle.ACTIVE,
                    latestDurableOffsetMs = 0,
                    create = JournalSession(
                        start.sessionId, start.engineInstanceId, JournalLifecycle.ACTIVE, now, zone, 0, null,
                    ),
                ),
            )
            sessionId = start.sessionId
            lost.set(0)
            latestDurableOffsetMs = 0
            savedStatus = RecordStatus.DURABLE
            true
        } catch (e: RuntimeException) {
            false
        }
    }

    fun checkpoint(totals: SessionTotals, lifecycle: JournalLifecycle) =
        write(RecordType.PROGRESS_CHECKPOINT, totals.offsetMs, lifecycle) {
            totals.toPayload() + mapOf("knownThroughOffsetMs" to totals.offsetMs, "recordsLost" to lost.get())
        }

    fun pauseStarted(ordinal: Int, totals: SessionTotals) =
        write(RecordType.PAUSE_STARTED, totals.offsetMs, JournalLifecycle.PAUSED) {
            totals.toPayload() + mapOf("pauseOrdinal" to ordinal)
        }

    /** La pausa se cierra cuando la reanudación queda confirmada (Krecover). */
    fun pauseEnded(ordinal: Int, totals: SessionTotals) =
        write(RecordType.PAUSE_ENDED, totals.offsetMs, JournalLifecycle.ACTIVE) {
            totals.toPayload() + mapOf("pauseOrdinal" to ordinal)
        }

    fun closureDetected(ordinal: Int, decisionOffsetMs: Long) =
        write(RecordType.CLOSURE_DETECTED, decisionOffsetMs, JournalLifecycle.ACTIVE) {
            mapOf("activationOrdinal" to ordinal, "decisionOffsetMs" to decisionOffsetMs)
        }

    /** Resultado técnico de un intento de tono; no acredita que se oyera. */
    fun playback(activationOrdinal: Int, playbackOrdinal: Int, offsetMs: Long, errorCode: String?) =
        write(RecordType.PLAYBACK_RESULT, offsetMs, JournalLifecycle.ACTIVE) {
            mapOf(
                "activationOrdinal" to activationOrdinal,
                "playbackOrdinal" to playbackOrdinal,
                "requestedOffsetMs" to offsetMs,
                "status" to if (errorCode == null) "started" else "failed",
                "errorCode" to errorCode,
            )
        }

    /** Cierre único y durable. `false` si no se escribió. */
    fun finalized(totals: SessionTotals): Boolean {
        // Fecha del hecho, no del momento posterior a vaciar la cola.
        val occurred = wallClockMs()
        return serialized { finalizedNow(totals, occurred) }
    }

    private fun finalizedNow(totals: SessionTotals, now: Long): Boolean {
        val id = sessionId ?: return false
        return try {
            store.commit(
                listOf(
                    PendingRecord(
                        recordId = newId(),
                        sessionId = id,
                        recordType = RecordType.SESSION_FINALIZED,
                        occurredEpochMs = now,
                        occurredOffsetMinutes = zoneOffsetMinutes(now),
                        sessionOffsetMs = totals.offsetMs,
                        payload = totals.toPayload() + mapOf(
                            "endOffsetMs" to totals.offsetMs,
                            "endedEpochMs" to now,
                            "endOffsetMinutes" to zoneOffsetMinutes(now),
                            "recordsLost" to lost.get(),
                        ),
                    ),
                ),
                SessionChange(
                    sessionId = id,
                    lifecycle = JournalLifecycle.FINALIZED,
                    latestDurableOffsetMs = totals.offsetMs,
                    expected = setOf(JournalLifecycle.ACTIVE, JournalLifecycle.PAUSED),
                    endOffsetMs = totals.offsetMs,
                ),
            )
            latestDurableOffsetMs = totals.offsetMs
            sessionId = null
            true
        } catch (e: RuntimeException) {
            lost.incrementAndGet()
            savedStatus = RecordStatus.INCOMPLETE
            sessionId = null
            false
        }
    }

    /** El motor se desconecta sin cierre: la sesión queda abierta para [recover]. */
    fun abandon() = serialized { sessionId = null }

    private fun write(
        type: String,
        offsetMs: Long,
        lifecycle: JournalLifecycle,
        payload: () -> Map<String, Any?>,
    ) {
        val occurred = wallClockMs()
        val writer = executor
        if (writer == null) return writeNow(type, offsetMs, lifecycle, payload, occurred)
        if (sessionId == null) return
        // Solo hechos compactos de límites/contadores (<1 KiB cada uno).
        // Nunca se bloquea análisis/audio por una cola llena. No es durable.
        if (queued.incrementAndGet() > 256) {
            queued.decrementAndGet()
            lost.incrementAndGet()
            savedStatus = RecordStatus.INCOMPLETE
            return
        }
        try {
            writer.execute {
                try { writeNow(type, offsetMs, lifecycle, payload, occurred) }
                finally { queued.decrementAndGet() }
            }
        } catch (_: RuntimeException) {
            queued.decrementAndGet()
            lost.incrementAndGet()
            savedStatus = RecordStatus.INCOMPLETE
        }
    }

    private fun writeNow(
        type: String,
        offsetMs: Long,
        lifecycle: JournalLifecycle,
        payload: () -> Map<String, Any?>,
        now: Long,
    ) {
        val id = sessionId ?: return
        try {
            store.commit(
                listOf(
                    PendingRecord(newId(), id, type, now, zoneOffsetMinutes(now), offsetMs, payload()),
                ),
                SessionChange(
                    sessionId = id,
                    lifecycle = lifecycle,
                    latestDurableOffsetMs = offsetMs,
                    expected = setOf(JournalLifecycle.ACTIVE, JournalLifecycle.PAUSED),
                ),
            )
            if (offsetMs > latestDurableOffsetMs) latestDurableOffsetMs = offsetMs
        } catch (e: RuntimeException) {
            lost.incrementAndGet()
            savedStatus = RecordStatus.INCOMPLETE
        }
    }

    private fun e6(v: Double): Long = Math.round(v * 1_000_000)
}
