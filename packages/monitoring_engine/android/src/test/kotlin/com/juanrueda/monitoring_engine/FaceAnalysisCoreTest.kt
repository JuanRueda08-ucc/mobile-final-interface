package com.juanrueda.monitoring_engine

import com.juanrueda.monitoring_engine.face.FaceAnalysisCore
import com.juanrueda.monitoring_engine.face.FaceEngine
import com.juanrueda.monitoring_engine.face.FaceEngineListener
import com.juanrueda.monitoring_engine.face.FaceErrorCodes
import com.juanrueda.monitoring_engine.face.FaceModelLoader
import com.juanrueda.monitoring_engine.face.FaceModelSpec
import com.juanrueda.monitoring_engine.face.FacePresence
import com.juanrueda.monitoring_engine.face.FacePresenceStatus
import com.juanrueda.monitoring_engine.face.ModelLoad
import java.io.ByteArrayInputStream
import java.io.File
import java.io.FileNotFoundException
import java.io.IOException
import java.io.InputStream
import java.nio.ByteBuffer
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNull
import kotlin.test.assertTrue

/*
 * Fase 5B: verificación del modelo y lógica del análisis de presencia facial
 * con **dobles** (detector falso, reloj manual y cola de avisos manual). No
 * ejecutan MediaPipe ni usan la cámara: la inferencia real la prueba
 * `FaceLandmarkerInstrumentedTest` en Android. Desde android/:
 *   ./gradlew :monitoring_engine:testDebugUnitTest
 */
internal class FaceAnalysisCoreTest {
    // ---------------------------------------------------------------- modelo

    private val sample = "modelo de prueba".toByteArray()
    private val sampleSha = FaceModelLoader.sha256Hex(sample)

    private fun load(open: () -> InputStream, size: Long = sample.size.toLong(), sha: String = sampleSha) =
        FaceModelLoader.load(open, size, sha)

    @Test
    fun model_verifiedBytesGoToADirectBuffer() {
        val r = assertIs<ModelLoad.Ready>(load({ ByteArrayInputStream(sample) }))
        assertTrue(r.buffer.isDirect)
        val copy = ByteArray(r.buffer.remaining()).also { r.buffer.duplicate().get(it) }
        assertTrue(copy.contentEquals(sample))
    }

    @Test
    fun model_missingAsset() {
        assertEquals(
            ModelLoad.Failed(FaceErrorCodes.MODEL_MISSING),
            load({ throw FileNotFoundException("vigia_models/x.task") }),
        )
    }

    @Test
    fun model_alteredSameSizeIsCorrupt() {
        val altered = sample.copyOf().also { it[0] = (it[0] + 1).toByte() }
        assertEquals(ModelLoad.Failed(FaceErrorCodes.MODEL_CORRUPT), load({ ByteArrayInputStream(altered) }))
    }

    @Test
    fun model_truncatedOrLongerIsCorrupt() {
        assertEquals(
            ModelLoad.Failed(FaceErrorCodes.MODEL_CORRUPT),
            load({ ByteArrayInputStream(sample.copyOf(sample.size - 1)) }),
        )
        assertEquals(
            ModelLoad.Failed(FaceErrorCodes.MODEL_CORRUPT),
            load({ ByteArrayInputStream(sample + byteArrayOf(0)) }),
        )
    }

    @Test
    fun model_readErrorIsExplicit() {
        val failing = object : InputStream() {
            override fun read(): Int = throw IOException("disco")
            override fun read(b: ByteArray, off: Int, len: Int): Int = throw IOException("disco")
        }
        assertEquals(ModelLoad.Failed(FaceErrorCodes.MODEL_READ_FAILED), load({ failing }))
    }

    /** El asset versionado es exactamente el del manifiesto (tamaño y SHA-256). */
    @Test
    fun model_packagedAssetMatchesManifest() {
        val asset = File("src/main/assets/${FaceModelSpec.ASSET_PATH}")
        assertTrue(asset.isFile, "Falta ${asset.absolutePath}")
        assertIs<ModelLoad.Ready>(FaceModelLoader.load({ asset.inputStream() }))
    }

    // ---------------------------------------------------------------- núcleo

    private class FakeEngine(val listener: FaceEngineListener) : FaceEngine<String> {
        val submitted = mutableListOf<Long>()
        var closed = 0
        var throwOnDetect: Throwable? = null
        var throwOnClose: Throwable? = null

        override fun detectAsync(frame: String, rotationDegrees: Int, timestampMs: Long) {
            throwOnDetect?.let { throw it }
            submitted += timestampMs
        }

        override fun close() {
            closed++
            throwOnClose?.let { throw it }
        }
    }

    private class Harness(
        var model: () -> ModelLoad = { ModelLoad.Ready(ByteBuffer.allocateDirect(1)) },
        var engineError: Throwable? = null,
    ) {
        var nowMs = 1_000L
        val queue = ArrayDeque<Runnable>()
        val published = mutableListOf<FacePresence>()
        val engines = mutableListOf<FakeEngine>()
        val observations = mutableListOf<com.juanrueda.monitoring_engine.monitoring.EyeObservation>()
        val core = FaceAnalysisCore(
            token = 7,
            loadModel = { model() },
            createEngine = { _, listener ->
                engineError?.let { throw it }
                FakeEngine(listener).also { engines += it }
            },
            post = { queue.addLast(it) },
            clockNs = { nowMs * 1_000_000 },
            publish = { published += it },
            observe = { observations += it },
        )
        val engine get() = engines.last()
        val last get() = published.last()

        fun drain() {
            while (queue.isNotEmpty()) queue.removeFirst().run()
        }

        /** Cuadro entregado ahora; devuelve su marca de tiempo (ms). */
        fun frame(): Long {
            core.submit("cuadro", 270, nowMs * 1_000_000, 640, 480)
            return nowMs
        }

        /** El detector responde ahora para [ts] con [faces] rostros. */
        fun result(ts: Long, faces: Int, engine: FakeEngine = this.engine) {
            engine.listener.onResult(ts, faces)
            drain()
        }
    }

    @Test
    fun engineFailureImmediatelyInvalidatesOcularObservationAndOldErrorsAreIgnored() {
        val h = Harness()
        h.core.start()
        val old = h.engine
        old.listener.onError("failed")
        h.drain()
        assertEquals(1, h.observations.size)
        assertEquals("inferenceError", h.observations.single().reasons.first().code)
        assertFalse(h.observations.single().valid)
        assertTrue(h.core.restart())
        old.listener.onError("old failure")
        h.drain()
        assertEquals(1, h.observations.size)
        assertEquals(FacePresenceStatus.WAITING_RESULTS, h.core.status)
    }

    @Test
    fun start_loadsModelThenWaits() {
        val h = Harness()
        h.core.start()
        assertEquals(
            listOf(FacePresenceStatus.LOADING_MODEL, FacePresenceStatus.WAITING_RESULTS),
            h.published.map { it.status },
        )
        assertEquals(1, h.engines.size)
        assertEquals(2, h.last.maxFaces)
        assertEquals(750, h.last.staleAfterMs)
        assertNull(h.last.faceCount)
    }

    @Test
    fun modelFailure_isExplicitAndFramesAreDropped() {
        val h = Harness(model = { ModelLoad.Failed(FaceErrorCodes.MODEL_CORRUPT) })
        h.core.start()
        assertEquals(FacePresenceStatus.MODEL_ERROR, h.last.status)
        assertEquals(FaceErrorCodes.MODEL_CORRUPT, h.last.errorCode)
        assertTrue(h.engines.isEmpty())
        assertFalse(h.core.acceptsFrames)
        assertFalse(h.core.submit("cuadro", 0, 5_000_000_000, 1, 1))
    }

    @Test
    fun engineCreationFailure_isIncompatibleModel() {
        val h = Harness(engineError = UnsatisfiedLinkError("libmediapipe_tasks_jni"))
        h.core.start()
        assertEquals(FacePresenceStatus.MODEL_ERROR, h.last.status)
        assertEquals(FaceErrorCodes.MODEL_INCOMPATIBLE, h.last.errorCode)
    }

    @Test
    fun results_mapToNoneOneOrSeveralFaces() {
        val h = Harness()
        h.core.start()
        for ((faces, status) in listOf(
            0 to FacePresenceStatus.NO_FACE,
            1 to FacePresenceStatus.ONE_FACE,
            2 to FacePresenceStatus.MULTIPLE_FACES,
        )) {
            h.nowMs += 33
            val ts = h.frame()
            h.nowMs += 20
            h.result(ts, faces)
            assertEquals(status, h.last.status)
            assertEquals(faces, h.last.faceCount)
            assertEquals(20, h.last.resultAgeMs)
        }
        assertEquals(3, h.last.resultsAccepted)
    }

    @Test
    fun noResults_isNeverNoFace() {
        val h = Harness()
        h.core.start()
        repeat(30) {
            h.nowMs += 33
            h.frame()
            h.core.tick()
        }
        assertEquals(FacePresenceStatus.WAITING_RESULTS, h.last.status)
        assertTrue(h.published.none { it.status == FacePresenceStatus.NO_FACE })
    }

    @Test
    fun staleness_silenceEqualToTstaleExpires() {
        val h = Harness()
        h.core.start()
        val ts = h.frame()
        h.result(ts, 1)
        val receivedAt = h.nowMs
        h.nowMs = receivedAt + 749
        h.core.tick()
        assertEquals(FacePresenceStatus.ONE_FACE, h.last.status)
        h.nowMs = receivedAt + 750
        h.core.tick()
        assertEquals(FacePresenceStatus.WAITING_RESULTS, h.last.status)
        assertTrue(h.last.expired)
        assertNull(h.last.faceCount)
        // Un resultado nuevo vuelve a ser vigente.
        val ts2 = h.frame()
        h.result(ts2, 0)
        assertEquals(FacePresenceStatus.NO_FACE, h.last.status)
        assertFalse(h.last.expired)
    }

    @Test
    fun staleness_ageEqualToTstaleIsValidAboveIsDiscarded() {
        val h = Harness()
        h.core.start()
        val ts = h.frame()
        h.nowMs += 750
        h.result(ts, 1)
        assertEquals(FacePresenceStatus.ONE_FACE, h.last.status)

        val ts2 = h.frame()
        h.nowMs += 751
        h.result(ts2, 2)
        assertEquals(FacePresenceStatus.ONE_FACE, h.last.status)
        assertEquals(1, h.last.resultsAccepted)
        h.core.tick()
        assertEquals(1, h.last.resultsDiscarded)
    }

    @Test
    fun oldGenerationCallbacks_areDiscarded() {
        val h = Harness()
        h.core.start()
        val first = h.engine
        val ts = h.frame()
        first.listener.onError(FaceErrorCodes.INFERENCE_FAILED)
        h.drain()
        assertEquals(FacePresenceStatus.ANALYSIS_ERROR, h.last.status)
        assertEquals(1, first.closed)

        assertTrue(h.core.restart())
        assertEquals(2, h.engines.size)
        assertEquals(FacePresenceStatus.WAITING_RESULTS, h.last.status)
        // El detector anterior responde tarde: no cuenta.
        h.result(ts, 1, engine = first)
        first.listener.onError(FaceErrorCodes.INFERENCE_FAILED)
        h.drain()
        assertEquals(FacePresenceStatus.WAITING_RESULTS, h.last.status)
        assertEquals(0, h.last.resultsAccepted)
    }

    @Test
    fun stop_releasesEngineAndIgnoresLateCallbacks() {
        val h = Harness()
        h.core.start()
        val ts = h.frame()
        h.engine.listener.onResult(ts, 1) // en cola, sin entregar
        h.core.stop()
        assertEquals(1, h.engine.closed)
        assertEquals(FacePresenceStatus.STOPPED, h.last.status)
        val count = h.published.size
        h.drain()
        h.core.tick()
        h.core.stop()
        assertEquals(count, h.published.size)
        assertFalse(h.core.restart())
        assertFalse(h.core.submit("cuadro", 0, (h.nowMs + 50) * 1_000_000, 1, 1))
        assertEquals(1, h.engines.size)
    }

    @Test
    fun stop_toleratesEngineCloseFailure() {
        val h = Harness()
        h.core.start()
        h.engine.throwOnClose = IllegalStateException("grafo")
        h.core.stop()
        assertEquals(FacePresenceStatus.STOPPED, h.last.status)
    }

    @Test
    fun detectAsyncFailure_isRecoverable() {
        val h = Harness()
        h.core.start()
        h.engine.throwOnDetect = IllegalStateException("marca")
        h.frame()
        assertEquals(FacePresenceStatus.ANALYSIS_ERROR, h.last.status)
        assertEquals(FaceErrorCodes.INFERENCE_FAILED, h.last.errorCode)
        assertTrue(h.core.restart())
        h.nowMs += 33
        val ts = h.frame()
        h.result(ts, 1)
        assertEquals(FacePresenceStatus.ONE_FACE, h.last.status)
    }

    @Test
    fun restart_onlyAfterAnError() {
        val h = Harness()
        h.core.start()
        assertFalse(h.core.restart())
        assertEquals(1, h.engines.size)
    }

    @Test
    fun timestamps_mustIncrease() {
        val h = Harness()
        h.core.start()
        h.frame()
        h.frame() // misma marca de tiempo
        h.nowMs -= 5
        h.frame() // marca anterior
        assertEquals(1, h.engine.submitted.size)
        h.nowMs += 2_000 // latido: publica los contadores
        h.core.tick()
        assertEquals(2, h.last.framesDropped)
    }

    @Test
    fun unknownOrRepeatedResults_areDiscarded() {
        val h = Harness()
        h.core.start()
        h.result(123, 1) // nunca enviado
        val ts = h.frame()
        h.result(ts, 1)
        h.result(ts, 2) // repetido
        assertEquals(FacePresenceStatus.ONE_FACE, h.last.status)
        h.core.tick()
        h.nowMs += 1_000
        h.core.tick()
        assertEquals(2, h.last.resultsDiscarded)
    }

    @Test
    fun pendingFrames_areBounded() {
        val h = Harness()
        h.core.start()
        val first = h.frame()
        repeat(20) {
            // Sin resultados: cada cuadro se envía al vencer la espera del anterior.
            h.nowMs += 750
            h.frame()
        }
        assertEquals(21, h.engine.submitted.size)
        // El primero ya salió de la ventana de cuadros pendientes.
        h.result(first, 1)
        assertEquals(FacePresenceStatus.WAITING_RESULTS, h.last.status)
    }

    @Test
    fun oneFrameInFlight_noQueueInsideMediaPipe() {
        val h = Harness()
        h.core.start()
        val ts = h.frame()
        h.nowMs += 33
        h.frame() // el anterior sigue en proceso: no se envía
        h.nowMs += 33
        h.frame()
        assertEquals(listOf(ts), h.engine.submitted)
        h.result(ts, 1)
        h.nowMs += 33
        val next = h.frame()
        assertEquals(listOf(ts, next), h.engine.submitted)
    }

    @Test
    fun oneFrameInFlight_givesUpAfterTstale() {
        val h = Harness()
        h.core.start()
        h.frame()
        h.nowMs += 749
        h.frame()
        assertEquals(1, h.engine.submitted.size)
        h.nowMs += 1
        h.frame()
        assertEquals(2, h.engine.submitted.size)
    }

    @Test
    fun heartbeat_republishesWithoutChanges() {
        val h = Harness()
        h.core.start()
        val count = h.published.size
        h.nowMs += 999
        h.core.tick()
        assertEquals(count, h.published.size)
        h.nowMs += 1
        h.core.tick()
        assertEquals(count + 1, h.published.size)
        assertEquals(FacePresenceStatus.WAITING_RESULTS, h.last.status)
    }

    @Test
    fun sameResultTwice_isPublishedOnceUntilHeartbeat() {
        val h = Harness()
        h.core.start()
        val ts1 = h.frame()
        h.result(ts1, 1)
        val count = h.published.size
        h.nowMs += 33
        val ts2 = h.frame()
        h.result(ts2, 1)
        assertEquals(count, h.published.size)
    }

    /** Contrato del resultado compacto: orden de mensajes e identidad de la inferencia. */
    @Test
    fun snapshots_carryIncreasingSequenceAndResultIdentity() {
        val h = Harness()
        h.core.start()
        val ts1 = h.frame()
        h.result(ts1, 1)
        val first = h.last
        h.nowMs += 1_000 // sin resultados nuevos: caduca antes del latido
        h.core.tick()
        assertEquals(FacePresenceStatus.WAITING_RESULTS, h.last.status)
        assertNull(h.last.resultId)

        val ts2 = h.frame()
        h.result(ts2, 1)
        val second = h.last
        assertTrue(second.resultId!! > first.resultId!!)
        // Latido de la misma inferencia: mismo resultId, sequence mayor.
        h.nowMs += 700
        val ts3 = h.frame()
        h.nowMs += 10
        h.result(ts3, 1)
        h.nowMs += 300
        h.core.tick()
        val beat = h.last
        assertTrue(beat.resultId!! > second.resultId!!) // hubo otra inferencia
        h.nowMs += 20
        h.core.stop()
        assertNull(h.last.resultId)
        val seqs = h.published.map { it.sequence }
        assertEquals(seqs.sorted().distinct(), seqs)
    }

    /** El latido lleva la identidad de la última inferencia aceptada, aunque no se publicara. */
    @Test
    fun heartbeat_carriesLatestAcceptedResultId() {
        val h = Harness()
        h.core.start()
        val ts1 = h.frame()
        h.result(ts1, 1)
        val published = h.last.resultId!!
        h.nowMs += 400
        val ts2 = h.frame()
        h.result(ts2, 1) // mismo estado: no se publica todavía
        assertEquals(published, h.last.resultId)
        h.nowMs += 600 // 1000 ms desde la última publicación, 600 de silencio
        h.core.tick()
        assertEquals(FacePresenceStatus.ONE_FACE, h.last.status)
        assertTrue(h.last.resultId!! > published)
    }

    /** Consulta de Flutter: estado creado ahora, con la edad de este instante. */
    @Test
    fun snapshotNow_reportsCurrentAgeAndRetiresStaleResults() {
        val h = Harness()
        h.core.start()
        val ts = h.frame()
        h.nowMs += 100
        h.result(ts, 1)
        val published = h.published.size
        h.nowMs += 200 // edad 300
        val fresh = h.core.snapshotNow()
        assertEquals(FacePresenceStatus.ONE_FACE, fresh.status)
        assertEquals(300, fresh.resultAgeMs)
        assertTrue(fresh.sequence > h.last.sequence)
        assertEquals(published, h.published.size) // la consulta no se avisa
        h.nowMs += 451 // edad 751
        val stale = h.core.snapshotNow()
        assertEquals(FacePresenceStatus.WAITING_RESULTS, stale.status)
        assertTrue(stale.expired)
        assertNull(stale.resultId)
        assertNull(stale.resultAgeMs)
        assertTrue(stale.sequence > fresh.sequence)
    }

    @Test
    fun snapshotNow_boundary750IsCurrent() {
        val h = Harness()
        h.core.start()
        val ts = h.frame()
        h.result(ts, 0)
        h.nowMs += 749 // silencio 749 (< 750) y edad 749
        assertEquals(FacePresenceStatus.NO_FACE, h.core.snapshotNow().status)
        h.nowMs += 1 // silencio 750: caduca
        assertEquals(FacePresenceStatus.WAITING_RESULTS, h.core.snapshotNow().status)
    }
}
