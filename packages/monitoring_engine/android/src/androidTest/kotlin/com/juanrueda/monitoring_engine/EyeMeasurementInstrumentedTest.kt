package com.juanrueda.monitoring_engine

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import android.os.SystemClock
import android.util.Log
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.juanrueda.monitoring_engine.face.FaceAnalysisCore
import com.juanrueda.monitoring_engine.face.FaceModelLoader
import com.juanrueda.monitoring_engine.face.FaceModelSpec
import com.juanrueda.monitoring_engine.face.MediaPipeFaceEngine
import com.juanrueda.monitoring_engine.monitoring.EyeObservation
import com.juanrueda.monitoring_engine.monitoring.QReason
import java.util.concurrent.Executors
import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.TimeUnit
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Fase 5C · medición ocular con **imágenes reales** y MediaPipe real, por el
 * mismo núcleo que la app ([FaceAnalysisCore] → `EyeGeometry`). Solo hay
 * fotos con los ojos **abiertos** (retrato de la NASA, dominio público): no
 * acredita la medición de ojos cerrados con imágenes reales.
 */
@RunWith(AndroidJUnit4::class)
class EyeMeasurementInstrumentedTest {
    private val instrumentation = InstrumentationRegistry.getInstrumentation()
    private val context = instrumentation.targetContext

    private fun fixture(name: String): Bitmap =
        instrumentation.context.assets.open("face_fixtures/$name").use { BitmapFactory.decodeStream(it) }
            .copy(Bitmap.Config.ARGB_8888, false)

    private fun observe(bitmap: Bitmap, rotation: Int = 0): List<EyeObservation> {
        val executor = Executors.newSingleThreadExecutor()
        val out = LinkedBlockingQueue<EyeObservation>()
        val core = FaceAnalysisCore<Bitmap>(
            token = 1,
            loadModel = { FaceModelLoader.load({ context.assets.open(FaceModelSpec.ASSET_PATH) }) },
            createEngine = { model, listener -> MediaPipeFaceEngine.create(context, model, listener) },
            post = { executor.execute(it) },
            clockNs = SystemClock::elapsedRealtimeNanos,
            publish = {},
            // En el emulador la inferencia es lenta: la vigencia no se evalúa aquí.
            staleAfterNs = 60_000_000_000,
            observe = { out.add(it) },
        )
        executor.submit { core.start() }.get()
        val end = SystemClock.elapsedRealtime() + 3_000
        while (SystemClock.elapsedRealtime() < end) {
            executor.submit {
                core.submit(bitmap, rotation, SystemClock.elapsedRealtimeNanos(), bitmap.width, bitmap.height)
            }.get()
            Thread.sleep(30)
        }
        Thread.sleep(500)
        executor.submit { core.stop() }.get()
        executor.shutdown()
        executor.awaitTermination(5, TimeUnit.SECONDS)
        return out.toList()
    }

    /** Retrato ampliado ×2 (bilineal): los ojos de la miniatura miden ~18 px. */
    private fun portraitX2(): Bitmap {
        val p = fixture("one_face_nasa_s85-41895_500px.jpg")
        return Bitmap.createScaledBitmap(p, p.width * 2, p.height * 2, true)
    }

    @Test
    fun smallEyes_realPortrait_rejectedByResolution() {
        val o = observe(fixture("one_face_nasa_s85-41895_500px.jpg")).last()
        Log.i(TAG, "miniatura: motivos=${o.reasons} EAR der=${o.earRight} izq=${o.earLeft} " +
            "anchos=${o.measurement?.widthRightPx}/${o.measurement?.widthLeftPx}")
        assertEquals(setOf(QReason.INSUFFICIENT_EYE_RESOLUTION), o.reasons)
    }

    @Test
    fun openEyes_realPortrait_measurableEar() {
        val obs = observe(portraitX2())
        assertTrue("sin observaciones", obs.isNotEmpty())
        val o = obs.last()
        Log.i(TAG, "retrato: rostros=${o.faceCount} motivos=${o.reasons} EAR der=${o.earRight} izq=${o.earLeft} " +
            "anchos=${o.measurement?.widthRightPx}/${o.measurement?.widthLeftPx}")
        assertEquals(1, o.faceCount)
        assertTrue("Q: ${o.reasons}", o.valid)
        // Ojos abiertos: EAR dentro del rango de referencia candidato (Kcal).
        assertTrue(o.earRight!! in 0.10..0.60 && o.earLeft!! in 0.10..0.60)
    }

    @Test
    fun rotatedInput_sameEarAsUpright() {
        val upright = portraitX2()
        val m = Matrix().apply { postRotate(-90f) }
        val sideways = Bitmap.createBitmap(upright, 0, 0, upright.width, upright.height, m, true)
        val a = observe(upright).last()
        val b = observe(sideways, rotation = 90).last()
        Log.i(TAG, "derecho EAR=${a.earRight}/${a.earLeft}; girado 90 EAR=${b.earRight}/${b.earLeft}")
        assertTrue(a.valid)
        assertTrue(b.valid)
        assertEquals(a.earRight!!, b.earRight!!, 0.03)
        assertEquals(a.earLeft!!, b.earLeft!!, 0.03)
    }

    @Test
    fun twoFacesAndNoFace_areNotMeasured() {
        val two = observe(fixture("two_faces_nasa_s65-56188.jpg")).last()
        assertEquals(setOf(QReason.AMBIGUOUS_FACE), two.reasons)
        val none = observe(fixture("no_face_nasa_apollo17_500px.jpg")).last()
        assertEquals(setOf(QReason.NO_FACE), none.reasons)
    }

    private companion object {
        const val TAG = "VigiaEyeMeasurement"
    }
}
