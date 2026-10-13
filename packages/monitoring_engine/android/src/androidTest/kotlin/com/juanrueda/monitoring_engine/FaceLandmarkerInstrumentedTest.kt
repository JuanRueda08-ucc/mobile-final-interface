package com.juanrueda.monitoring_engine

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.graphics.Matrix
import android.os.SystemClock
import android.util.Log
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.juanrueda.monitoring_engine.face.FaceAnalysisCore
import com.juanrueda.monitoring_engine.face.FaceEngine
import com.juanrueda.monitoring_engine.face.FaceEngineListener
import com.juanrueda.monitoring_engine.face.FaceErrorCodes
import com.juanrueda.monitoring_engine.face.FaceModelLoader
import com.juanrueda.monitoring_engine.face.FaceModelSpec
import com.juanrueda.monitoring_engine.face.FacePresence
import com.juanrueda.monitoring_engine.face.FacePresenceStatus
import com.juanrueda.monitoring_engine.face.MediaPipeFaceEngine
import com.juanrueda.monitoring_engine.face.ModelLoad
import java.nio.ByteBuffer
import java.util.concurrent.Executors
import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.TimeUnit
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Fase 5B · inferencia **real** en Android: MediaPipe Tasks Vision 1.0.0 con
 * el modelo empaquetado, LIVE_STREAM, a través del mismo núcleo
 * ([FaceAnalysisCore]) y adaptador ([MediaPipeFaceEngine]) que la app.
 *
 * Entrada: imágenes fijas con procedencia y licencia documentadas
 * (`assets/face_fixtures/FUENTES.md`), enviadas como cuadros sucesivos. **No
 * usa la cámara**: la integración CameraX → MediaPipe se comprueba aparte,
 * en el emulador. Desde android/:
 *
 *   ./gradlew :monitoring_engine:connectedDebugAndroidTest
 */
@RunWith(AndroidJUnit4::class)
class FaceLandmarkerInstrumentedTest {
    private val instrumentation = InstrumentationRegistry.getInstrumentation()
    private val context = instrumentation.targetContext
    private val testAssets = instrumentation.context.assets

    private fun fixture(name: String): Bitmap =
        testAssets.open("face_fixtures/$name").use { BitmapFactory.decodeStream(it) }
            .copy(Bitmap.Config.ARGB_8888, false)

    private fun realModel(): ModelLoad =
        FaceModelLoader.load({ context.assets.open(FaceModelSpec.ASSET_PATH) })

    private fun realEngine(model: ByteBuffer, listener: FaceEngineListener): FaceEngine<Bitmap> =
        MediaPipeFaceEngine.create(context, model, listener)

    /** Resultado de analizar una imagen durante [durationMs]. */
    private class Run(val published: List<FacePresence>) {
        val detections get() = published.filter { it.status.isDetection }.map { it.status }.toSet()
        val last get() = published.last()
    }

    /**
     * Envía [bitmap] como cuadro cada 30 ms durante [durationMs] (marcas
     * crecientes, como la cámara) y devuelve todo lo publicado. El núcleo se
     * usa en un único hilo, como en la app.
     */
    private fun analyze(
        bitmap: Bitmap?,
        rotation: Int = 0,
        durationMs: Long = 2_500,
        loadModel: () -> ModelLoad = ::realModel,
        afterStart: (FaceAnalysisCore<Bitmap>) -> Unit = {},
    ): Run {
        val executor = Executors.newSingleThreadExecutor()
        val published = LinkedBlockingQueue<FacePresence>()
        val core = FaceAnalysisCore(
            token = 1,
            loadModel = loadModel,
            createEngine = ::realEngine,
            post = { executor.execute(it) },
            clockNs = SystemClock::elapsedRealtimeNanos,
            publish = { published.add(it) },
        )
        try {
            executor.submit { core.start() }.get(10, TimeUnit.SECONDS)
            executor.submit { afterStart(core) }.get(10, TimeUnit.SECONDS)
            val end = SystemClock.elapsedRealtime() + durationMs
            while (bitmap != null && SystemClock.elapsedRealtime() < end) {
                executor.submit {
                    core.submit(bitmap, rotation, SystemClock.elapsedRealtimeNanos(), bitmap.width, bitmap.height)
                    core.tick()
                }.get(5, TimeUnit.SECONDS)
                Thread.sleep(30)
            }
            Thread.sleep(200)
            executor.submit { core.tick() }.get(5, TimeUnit.SECONDS)
        } finally {
            executor.submit { core.stop() }.get(10, TimeUnit.SECONDS)
            executor.shutdown()
            executor.awaitTermination(10, TimeUnit.SECONDS)
        }
        return Run(published.toList()).also {
            Log.i(TAG, "estados=${it.published.map { p -> p.status }.distinct()} detecciones=${it.detections}")
        }
    }

    @Test
    fun oneFace_nasaPortrait() {
        val run = analyze(fixture("one_face_nasa_s85-41895_500px.jpg"))
        assertEquals(setOf(FacePresenceStatus.ONE_FACE), run.detections)
        assertTrue(run.published.any { it.status == FacePresenceStatus.ONE_FACE && it.faceCount == 1 })
    }

    @Test
    fun twoFaces_nasaGemini6Crew() {
        val run = analyze(fixture("two_faces_nasa_s65-56188.jpg"))
        assertEquals(setOf(FacePresenceStatus.MULTIPLE_FACES), run.detections)
        assertTrue(run.published.any { it.status == FacePresenceStatus.MULTIPLE_FACES && it.faceCount == 2 })
    }

    @Test
    fun noFace_nasaBlueMarble() {
        val run = analyze(fixture("no_face_nasa_apollo17_500px.jpg"))
        assertEquals(setOf(FacePresenceStatus.NO_FACE), run.detections)
    }

    /** Escena sintética uniforme: solo acredita «sin rostro» en esta imagen. */
    @Test
    fun noFace_syntheticUniformImage() {
        val gray = Bitmap.createBitmap(480, 640, Bitmap.Config.ARGB_8888).apply { eraseColor(Color.GRAY) }
        val run = analyze(gray)
        assertEquals(setOf(FacePresenceStatus.NO_FACE), run.detections)
    }

    /**
     * Giro: el retrato se gira 90° antihorario, como llega un cuadro que
     * necesita 90° horarios para quedar derecho (`ImageInfo.rotationDegrees`
     * = 90). Con ese giro en `ImageProcessingOptions`, se detecta el rostro.
     * El giro opuesto (270) se registra solo como observación.
     */
    @Test
    fun rotation_isAppliedClockwiseLikeCameraX() {
        val upright = fixture("one_face_nasa_s85-41895_500px.jpg")
        val sideways = Bitmap.createBitmap(
            upright, 0, 0, upright.width, upright.height,
            Matrix().apply { postRotate(-90f) }, true,
        ).copy(Bitmap.Config.ARGB_8888, false)
        val run = analyze(sideways, rotation = 90)
        assertEquals(setOf(FacePresenceStatus.ONE_FACE), run.detections)
        val wrong = analyze(sideways, rotation = 270)
        Log.i(TAG, "observación: giro opuesto (270) → ${wrong.detections}")
    }

    @Test
    fun missingModel_isExplicitError() {
        val run = analyze(
            bitmap = null,
            loadModel = { FaceModelLoader.load({ context.assets.open("vigia_models/no_existe.task") }) },
        )
        assertEquals(FacePresenceStatus.MODEL_ERROR, run.published[1].status)
        assertEquals(FaceErrorCodes.MODEL_MISSING, run.published[1].errorCode)
    }

    @Test
    fun alteredModel_isRejectedBeforeMediaPipe() {
        val altered = context.assets.open(FaceModelSpec.ASSET_PATH).use { it.readBytes() }
            .also { it[it.size / 2] = (it[it.size / 2] + 1).toByte() }
        val run = analyze(
            bitmap = null,
            loadModel = { FaceModelLoader.load({ altered.inputStream() }) },
        )
        assertEquals(FaceErrorCodes.MODEL_CORRUPT, run.published[1].errorCode)
    }

    /** Bytes que pasan la verificación pero no son un modelo: MediaPipe los rechaza. */
    @Test
    fun incompatibleModel_isRejectedByMediaPipe() {
        val junk = ByteArray(4096) { (it * 31).toByte() }
        val run = analyze(
            bitmap = null,
            loadModel = {
                FaceModelLoader.load({ junk.inputStream() }, junk.size.toLong(), FaceModelLoader.sha256Hex(junk))
            },
        )
        assertEquals(FacePresenceStatus.MODEL_ERROR, run.published[1].status)
        assertEquals(FaceErrorCodes.MODEL_INCOMPATIBLE, run.published[1].errorCode)
    }

    /** Tras un fallo de carga, «Reintentar carga» crea el detector y analiza. */
    @Test
    fun retryAfterModelError_recovers() {
        var attempts = 0
        val run = analyze(
            bitmap = fixture("one_face_nasa_s85-41895_500px.jpg"),
            loadModel = {
                attempts++
                if (attempts == 1) ModelLoad.Failed(FaceErrorCodes.MODEL_MISSING) else realModel()
            },
            afterStart = { assertTrue(it.restart()) },
        )
        assertEquals(2, attempts)
        assertEquals(setOf(FacePresenceStatus.ONE_FACE), run.detections)
    }

    /** Aperturas y cierres repetidos: cada uno crea y libera su detector. */
    @Test
    fun repeatedStartStop_eachRunWorks() {
        val portrait = fixture("one_face_nasa_s85-41895_500px.jpg")
        repeat(5) {
            val run = analyze(portrait, durationMs = 800)
            assertEquals(setOf(FacePresenceStatus.ONE_FACE), run.detections)
            assertEquals(FacePresenceStatus.STOPPED, run.last.status)
        }
    }

    private companion object {
        const val TAG = "VigiaFaceTest"
    }
}
