package com.juanrueda.monitoring_engine.journal

import com.juanrueda.monitoring_engine.ExperimentalJournalHostApi
import com.juanrueda.monitoring_engine.JournalBatch
import com.juanrueda.monitoring_engine.JournalRecordMessage
import java.util.UUID

/**
 * Lectura y ACK del journal para la importación de Flutter (fase 5D, Área 04
 * §12). Entrega los hechos sin ACK en orden de secuencia y marca como
 * confirmadas solo las revisiones exactas (ID y hash) que Flutter ya guardó.
 * El lote no se registra: su identificador no garantiza nada por sí mismo.
 */
internal class ExperimentalJournalHost(
    private val store: JournalStore,
    /** Abre el journal y recupera las interrumpidas antes de la primera lectura. */
    private val ensureRecovered: () -> Unit = {},
) : ExperimentalJournalHostApi {
    override fun readPendingRecords(limit: Long): JournalBatch {
        ensureRecovered()
        val n = limit.coerceIn(1, MAX_BATCH.toLong()).toInt()
        // Uno más para saber si quedan otros.
        val read = store.readPending(n + 1)
        val records = read.take(n)
        return JournalBatch(
            batchId = UUID.randomUUID().toString(),
            records = records.map { it.toMessage() },
            highWatermark = store.highWatermark(),
            hasMore = read.size > n,
        )
    }

    override fun acknowledgeRecords(recordIds: List<String>, payloadHashes: List<String>): Long {
        require(recordIds.size == payloadHashes.size) { "ACK con listas de distinto tamaño" }
        return store.acknowledge(recordIds.zip(payloadHashes)).toLong()
    }

    companion object {
        /** Área 04 §7: límite inicial de 100 registros por lote. */
        const val MAX_BATCH = 100
    }
}

internal fun JournalRecord.toMessage() = JournalRecordMessage(
    journalSequence = journalSequence,
    recordId = recordId,
    sessionId = sessionId,
    recordType = recordType,
    occurredEpochMs = occurredEpochMs,
    occurredOffsetMinutes = occurredOffsetMinutes.toLong(),
    sessionOffsetMs = sessionOffsetMs,
    payloadSchemaVersion = payloadSchemaVersion.toLong(),
    payloadJson = payloadJson,
    payloadHash = payloadHash,
)
