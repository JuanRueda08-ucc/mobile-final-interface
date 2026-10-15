package com.juanrueda.monitoring_engine.journal

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper

/**
 * Journal durable de la variante normal: `vigia_journal_real_v1.sqlite`, en
 * el almacenamiento privado de la app (excluido de copias por las reglas de
 * `android/app/src/main/res/xml`). La DEMO no lo abre nunca: su recorrido no
 * usa el motor.
 *
 * Subconjunto de `JOURNAL_SCHEMA_V1` (Área 06 §7) con SQLite de Android en
 * lugar de Room (sin dependencias nuevas): `n_sessions` y `n_outbox`, con la
 * sesión vigente única, hechos inmutables y `synchronous=FULL`. No incluye
 * contextos de dataset, órdenes, lotes, borrado ni barreras: el prototipo no
 * tiene borrado, exportación ni reinicio de datos.
 */
internal class SqliteJournalStore(context: Context, name: String = DATABASE_NAME) : JournalStore {
    private val helper = object : SQLiteOpenHelper(context.applicationContext, name, null, VERSION) {
        override fun onConfigure(db: SQLiteDatabase) {
            db.setForeignKeyConstraintsEnabled(true)
        }

        override fun onOpen(db: SQLiteDatabase) {
            // Área 06 §16: commit durable del journal.
            db.rawQuery("PRAGMA synchronous=FULL", null).close()
        }

        override fun onCreate(db: SQLiteDatabase) = SCHEMA.forEach(db::execSQL)

        override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
            // Sin ruta destructiva: no hay otra versión distribuida.
            throw IllegalStateException("Migración del journal $oldVersion→$newVersion no definida")
        }
    }

    private val db: SQLiteDatabase get() = helper.writableDatabase

    override fun commit(records: List<PendingRecord>, change: SessionChange?): List<JournalRecord> {
        val d = db
        d.beginTransaction()
        try {
            if (change != null) applyChange(d, change)
            var next = highWatermark(d)
            val written = records.map { p ->
                val r = JournalRecord.build(
                    ++next, p.recordId, p.sessionId, p.recordType, p.occurredEpochMs,
                    p.occurredOffsetMinutes, p.sessionOffsetMs, p.payload,
                )
                d.insertOrThrow("n_outbox", null, ContentValues().apply {
                    put("journal_sequence", r.journalSequence)
                    put("record_id", r.recordId)
                    put("session_id", r.sessionId)
                    put("record_type", r.recordType)
                    put("occurred_epoch_ms", r.occurredEpochMs)
                    put("occurred_offset_minutes", r.occurredOffsetMinutes)
                    put("session_offset_ms", r.sessionOffsetMs)
                    put("payload_schema_version", r.payloadSchemaVersion)
                    put("payload_json", r.payloadJson)
                    put("payload_hash", r.payloadHash)
                    put("ack_state", "pending")
                })
                r
            }
            if (change != null) {
                d.execSQL(
                    "UPDATE n_sessions SET last_record_sequence=? WHERE session_id=?",
                    arrayOf<Any>(next, change.sessionId),
                )
            }
            d.setTransactionSuccessful()
            return written
        } finally {
            d.endTransaction()
        }
    }

    private fun applyChange(d: SQLiteDatabase, c: SessionChange) {
        val create = c.create
        if (create != null) {
            d.insertOrThrow("n_sessions", null, ContentValues().apply {
                put("session_id", create.sessionId)
                put("engine_instance_id", create.engineInstanceId)
                put("lifecycle", create.lifecycle.code)
                put("started_epoch_ms", create.startedEpochMs)
                put("start_offset_minutes", create.startOffsetMinutes)
                put("latest_durable_offset_ms", create.latestDurableOffsetMs)
                put("last_record_sequence", 0)
            })
            return
        }
        val expected = c.expected ?: JournalLifecycle.entries.toSet()
        val placeholders = expected.joinToString(",") { "?" }
        val args = mutableListOf<Any?>(
            c.lifecycle.code, c.latestDurableOffsetMs, c.endOffsetMs, c.sessionId,
        ) + expected.map { it.code }
        val stmt = d.compileStatement(
            "UPDATE n_sessions SET lifecycle=?, " +
                "latest_durable_offset_ms=MAX(latest_durable_offset_ms, ?), " +
                "end_offset_ms=COALESCE(?, end_offset_ms) " +
                "WHERE session_id=? AND lifecycle IN ($placeholders)",
        )
        args.forEachIndexed { i, a ->
            when (a) {
                null -> stmt.bindNull(i + 1)
                is Long -> stmt.bindLong(i + 1, a)
                else -> stmt.bindString(i + 1, a.toString())
            }
        }
        if (stmt.executeUpdateDelete() != 1) {
            throw JournalConflict("Sesión ${c.sessionId} fuera del ciclo esperado")
        }
    }

    override fun openSessions(): List<JournalSession> =
        sessions("lifecycle IN ('active','paused')", emptyArray())

    override fun session(sessionId: String): JournalSession? =
        sessions("session_id=?", arrayOf(sessionId)).firstOrNull()

    private fun sessions(where: String, args: Array<String>): List<JournalSession> =
        db.rawQuery(
            "SELECT session_id, engine_instance_id, lifecycle, started_epoch_ms, start_offset_minutes, " +
                "latest_durable_offset_ms, end_offset_ms FROM n_sessions WHERE $where ORDER BY started_epoch_ms",
            args,
        ).use { c ->
            buildList {
                while (c.moveToNext()) {
                    add(
                        JournalSession(
                            sessionId = c.getString(0),
                            engineInstanceId = c.getString(1),
                            lifecycle = JournalLifecycle.of(c.getString(2)),
                            startedEpochMs = c.getLong(3),
                            startOffsetMinutes = c.getInt(4),
                            latestDurableOffsetMs = c.getLong(5),
                            endOffsetMs = if (c.isNull(6)) null else c.getLong(6),
                        ),
                    )
                }
            }
        }

    override fun readPending(limit: Int): List<JournalRecord> =
        db.rawQuery(
            "SELECT journal_sequence, record_id, session_id, record_type, occurred_epoch_ms, " +
                "occurred_offset_minutes, session_offset_ms, payload_schema_version, payload_json, payload_hash " +
                "FROM n_outbox WHERE ack_state='pending' ORDER BY journal_sequence LIMIT ?",
            arrayOf(limit.toString()),
        ).use { c ->
            buildList {
                while (c.moveToNext()) {
                    add(
                        JournalRecord(
                            journalSequence = c.getLong(0),
                            recordId = c.getString(1),
                            sessionId = if (c.isNull(2)) null else c.getString(2),
                            recordType = c.getString(3),
                            occurredEpochMs = c.getLong(4),
                            occurredOffsetMinutes = c.getInt(5),
                            sessionOffsetMs = if (c.isNull(6)) null else c.getLong(6),
                            payloadSchemaVersion = c.getInt(7),
                            payloadJson = c.getString(8),
                            payloadHash = c.getString(9),
                        ),
                    )
                }
            }
        }

    override fun highWatermark(): Long = highWatermark(db)

    private fun highWatermark(d: SQLiteDatabase): Long =
        d.rawQuery("SELECT COALESCE(MAX(journal_sequence), 0) FROM n_outbox", null).use { c ->
            c.moveToFirst()
            c.getLong(0)
        }

    override fun acknowledge(records: List<Pair<String, String>>): Int {
        val d = db
        d.beginTransaction()
        try {
            var n = 0
            for ((id, hash) in records) {
                n += d.update(
                    "n_outbox",
                    ContentValues().apply { put("ack_state", "acked") },
                    "record_id=? AND payload_hash=? AND ack_state='pending'",
                    arrayOf(id, hash),
                )
            }
            d.setTransactionSuccessful()
            return n
        } finally {
            d.endTransaction()
        }
    }

    override fun close() = helper.close()

    companion object {
        const val DATABASE_NAME = "vigia_journal_real_v1.sqlite"
        const val VERSION = 1

        val SCHEMA = listOf(
            """
            CREATE TABLE n_sessions (
             session_id TEXT PRIMARY KEY NOT NULL,
             engine_instance_id TEXT NOT NULL,
             lifecycle TEXT NOT NULL CHECK(lifecycle IN ('active','paused','finalized','interrupted')),
             started_epoch_ms INTEGER NOT NULL,
             start_offset_minutes INTEGER NOT NULL CHECK(start_offset_minutes BETWEEN -840 AND 840),
             latest_durable_offset_ms INTEGER NOT NULL CHECK(latest_durable_offset_ms>=0),
             end_offset_ms INTEGER CHECK(end_offset_ms IS NULL OR end_offset_ms>=latest_durable_offset_ms),
             last_record_sequence INTEGER NOT NULL CHECK(last_record_sequence>=0),
             CHECK(lifecycle='finalized' OR end_offset_ms IS NULL),
             CHECK(lifecycle!='finalized' OR end_offset_ms IS NOT NULL)
            )
            """.trimIndent(),
            "CREATE UNIQUE INDEX n_one_current_session ON n_sessions((1)) WHERE lifecycle IN ('active','paused')",
            """
            CREATE TABLE n_outbox (
             journal_sequence INTEGER PRIMARY KEY NOT NULL CHECK(journal_sequence>=1),
             record_id TEXT NOT NULL UNIQUE,
             session_id TEXT,
             record_type TEXT NOT NULL,
             occurred_epoch_ms INTEGER NOT NULL,
             occurred_offset_minutes INTEGER NOT NULL CHECK(occurred_offset_minutes BETWEEN -840 AND 840),
             session_offset_ms INTEGER CHECK(session_offset_ms IS NULL OR session_offset_ms>=0),
             payload_schema_version INTEGER NOT NULL CHECK(payload_schema_version=1),
             payload_json TEXT NOT NULL,
             payload_hash TEXT NOT NULL CHECK(length(payload_hash)=64 AND payload_hash NOT GLOB '*[^0-9a-f]*'),
             ack_state TEXT NOT NULL CHECK(ack_state IN ('pending','acked'))
            )
            """.trimIndent(),
            "CREATE INDEX n_pending_records ON n_outbox(ack_state, journal_sequence)",
            """
            CREATE TRIGGER n_outbox_content_immutable BEFORE UPDATE ON n_outbox
            WHEN NEW.journal_sequence IS NOT OLD.journal_sequence OR NEW.record_id IS NOT OLD.record_id
             OR NEW.session_id IS NOT OLD.session_id OR NEW.record_type IS NOT OLD.record_type
             OR NEW.occurred_epoch_ms IS NOT OLD.occurred_epoch_ms
             OR NEW.occurred_offset_minutes IS NOT OLD.occurred_offset_minutes
             OR NEW.session_offset_ms IS NOT OLD.session_offset_ms
             OR NEW.payload_schema_version IS NOT OLD.payload_schema_version
             OR NEW.payload_json IS NOT OLD.payload_json OR NEW.payload_hash IS NOT OLD.payload_hash
            BEGIN SELECT RAISE(ABORT,'immutableJournalRecord'); END
            """.trimIndent(),
            "CREATE TRIGGER n_outbox_no_delete BEFORE DELETE ON n_outbox BEGIN SELECT RAISE(ABORT,'journalRecordDelete'); END",
        )
    }
}
