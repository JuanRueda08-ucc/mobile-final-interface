package com.juanrueda.monitoring_engine.journal

import java.security.MessageDigest

/**
 * Serialización canónica del journal experimental (fase 5D; Área 06 §8).
 *
 * Subconjunto **propio** y documentado, no una implementación completa de
 * JCS/RFC 8785: solo admite objetos, listas, cadenas, enteros, booleanos y
 * nulos. Los decimales no se admiten (no hay que reproducir el formato de
 * números de ECMAScript): las mediciones se guardan como enteros escalados
 * (`…E6` = millonésimas). Reglas, idénticas en Dart
 * (`lib/data/experimental_history/journal_codec.dart`):
 *
 * - claves ordenadas por unidades UTF-16, sin espacios;
 * - en cadenas se escapan `"`, `\` y los caracteres de control U+0000–U+001F
 *   como `\u00xx` (hexadecimal en minúsculas); el resto va literal en UTF-8;
 * - el hash es SHA-256, en hexadecimal en minúsculas, de esos bytes UTF-8.
 */
internal object JournalCodec {
    fun encode(value: Any?): String = StringBuilder().also { write(it, value) }.toString()

    fun sha256Hex(text: String): String =
        MessageDigest.getInstance("SHA-256").digest(text.toByteArray(Charsets.UTF_8))
            .joinToString("") { "%02x".format(it) }

    private fun write(out: StringBuilder, v: Any?) {
        when (v) {
            null -> out.append("null")
            is Boolean -> out.append(if (v) "true" else "false")
            is Int -> out.append(v.toLong())
            is Long -> {
                // Área 06 §8: enteros representables sin pérdida en JSON.
                require(v in -MAX_SAFE..MAX_SAFE) { "Entero fuera de rango: $v" }
                out.append(v)
            }
            is String -> writeString(out, v)
            is Map<*, *> -> {
                val keys = v.keys.map { it as String }.sorted()
                require(keys.toSet().size == keys.size) { "Clave duplicada" }
                out.append('{')
                keys.forEachIndexed { i, k ->
                    if (i > 0) out.append(',')
                    writeString(out, k)
                    out.append(':')
                    write(out, v[k])
                }
                out.append('}')
            }
            is List<*> -> {
                out.append('[')
                v.forEachIndexed { i, e ->
                    if (i > 0) out.append(',')
                    write(out, e)
                }
                out.append(']')
            }
            else -> throw IllegalArgumentException("Tipo no admitido en el journal: ${v.javaClass.simpleName}")
        }
    }

    private fun writeString(out: StringBuilder, s: String) {
        out.append('"')
        for (c in s) {
            when {
                c == '"' -> out.append("\\\"")
                c == '\\' -> out.append("\\\\")
                c.code < 0x20 -> out.append("\\u00").append("%02x".format(c.code))
                else -> out.append(c)
            }
        }
        out.append('"')
    }

    private const val MAX_SAFE = 9_007_199_254_740_991L
}

/** Hecho del journal tal como se guarda y se entrega a Flutter. */
internal data class JournalRecord(
    val journalSequence: Long,
    val recordId: String,
    val sessionId: String?,
    val recordType: String,
    val occurredEpochMs: Long,
    val occurredOffsetMinutes: Int,
    val sessionOffsetMs: Long?,
    val payloadSchemaVersion: Int,
    val payloadJson: String,
    val payloadHash: String,
) {
    companion object {
        const val SCHEMA_VERSION = 1
        const val PAYLOAD_SCHEMA_VERSION = 1

        /** Conjunto de datos de este journal: siempre real experimental. */
        const val DATASET_MODE = "realExperimental"

        /**
         * Construye el registro y su hash. El hash cubre el sobre completo
         * (incluida la secuencia) salvo el propio hash, como fija el Área 06 §8;
         * el estado de ACK es transporte y no entra.
         */
        fun build(
            journalSequence: Long,
            recordId: String,
            sessionId: String?,
            recordType: String,
            occurredEpochMs: Long,
            occurredOffsetMinutes: Int,
            sessionOffsetMs: Long?,
            payload: Map<String, Any?>,
        ): JournalRecord {
            val payloadJson = JournalCodec.encode(payload)
            val envelope = mapOf(
                "schemaVersion" to SCHEMA_VERSION,
                "datasetMode" to DATASET_MODE,
                "journalSequence" to journalSequence,
                "recordId" to recordId,
                "sessionId" to sessionId,
                "recordType" to recordType,
                "occurredEpochMs" to occurredEpochMs,
                "occurredOffsetMinutes" to occurredOffsetMinutes,
                "sessionOffsetMs" to sessionOffsetMs,
                "payloadSchemaVersion" to PAYLOAD_SCHEMA_VERSION,
                "payload" to payload,
            )
            return JournalRecord(
                journalSequence, recordId, sessionId, recordType, occurredEpochMs,
                occurredOffsetMinutes, sessionOffsetMs, PAYLOAD_SCHEMA_VERSION, payloadJson,
                JournalCodec.sha256Hex(JournalCodec.encode(envelope)),
            )
        }
    }
}

/** Tipos de hecho del journal experimental (subconjunto del Área 06 §8). */
internal object RecordType {
    const val SESSION_STARTED = "sessionStarted"
    const val PROGRESS_CHECKPOINT = "progressCheckpoint"
    const val PAUSE_STARTED = "pauseStarted"
    const val PAUSE_ENDED = "pauseEnded"
    const val CLOSURE_DETECTED = "closureDetected"
    const val PLAYBACK_RESULT = "playbackResult"
    const val SESSION_FINALIZED = "sessionFinalized"
    const val INTERRUPTION_RECOVERED = "interruptionRecovered"
}
