package com.juanrueda.monitoring_engine.face

import android.content.Context
import android.graphics.Bitmap
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import android.util.Size
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.core.resolutionselector.AspectRatioStrategy
import androidx.camera.core.resolutionselector.ResolutionSelector
import androidx.camera.core.resolutionselector.ResolutionStrategy
import com.juanrueda.monitoring_engine.monitoring.EyeObservation
import java.nio.ByteBuffer
import java.util.concurrent.RejectedExecutionException
import java.util.concurrent.ScheduledThreadPoolExecutor
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger

/**
 * Análisis de presencia facial de una apertura de la vista previa (fase 5B).
 *
 * - Aporta el caso de uso [useCase] (`ImageAnalysis`), que el propietario de
 *   la cámara vincula **junto a Preview en la misma cámara**: no abre otra.
 * - Un hilo propio (`VigiaFaceAnalysis-<token>`) carga el modelo, convierte
 *   los cuadros, llama a MediaPipe y vigila la caducidad. Nada de eso ocurre
 *   en el hilo principal.
 * - `STRATEGY_KEEP_ONLY_LATEST`: CameraX conserva como mucho un cuadro en
 *   espera; junto con el limitador de MediaPipe, ninguna cola crece.
 * - **Propiedad.** El `ImageProxy` se copia a un `Bitmap` y se cierra en el
 *   acto (también si se descarta). El `Bitmap` se libera al volver
 *   `detectAsync`, que ya copió los píxeles (ver [MediaPipeFaceEngine]).
 * - [close] retira el analizador, detiene el núcleo (cierra el detector) y
 *   apaga el hilo. Los avisos posteriores se descartan.
 * - Los registros (`Log`) solo contienen el token, el estado y contadores:
 *   ninguna imagen, punto facial ni dato de rostro.
 */
internal class FaceAnalysisSession(
    context: Context,
    private val token: Long,
    onPresence: (FacePresence) -> Unit,
    /** Fase 5C: observaciones oculares compactas, en el hilo de análisis. */
    onObservation: (EyeObservation) -> Unit = {},
    loadModel: () -> ModelLoad = {
        FaceModelLoader.load({ context.assets.open(FaceModelSpec.ASSET_PATH) })
    },
    createEngine: (ByteBuffer, FaceEngineListener) -> FaceEngine<Bitmap> = { model, listener ->
        try {
            MediaPipeFaceEngine.create(context, model, listener)
        } catch (t: Throwable) {
            // Diagnóstico técnico: tipo y mensaje de MediaPipe (sin datos de imagen).
            Log.w(TAG, "Detector no creado: ${generateSequence(t) { it.cause }.joinToString(" <- ") { "${it.javaClass.name}: ${it.message}" }}")
            throw t
        }
    },
) {
    private val executor = ScheduledThreadPoolExecutor(1) { r ->
        Thread(r, "VigiaFaceAnalysis-$token")
    }
    private val main = Handler(Looper.getMainLooper())

    @Volatile
    private var closed = false
    private var started = false

    /** Último resultado publicado (hilo de análisis), para el registro de cierre. */
    private var lastPresence: FacePresence? = null

    private val core = FaceAnalysisCore(
        token = token,
        loadModel = loadModel,
        createEngine = createEngine,
        post = ::onAnalysisThread,
        clockNs = SystemClock::elapsedRealtimeNanos,
        publish = { presence ->
            lastPresence = presence
            main.post { onPresence(presence) }
        },
        observe = onObservation,
    )

    val useCase: ImageAnalysis = ImageAnalysis.Builder()
        .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
        .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_RGBA_8888)
        .setResolutionSelector(
            ResolutionSelector.Builder()
                .setAspectRatioStrategy(AspectRatioStrategy.RATIO_4_3_FALLBACK_AUTO_STRATEGY)
                .setResolutionStrategy(
                    ResolutionStrategy(
                        ANALYSIS_SIZE,
                        ResolutionStrategy.FALLBACK_RULE_CLOSEST_HIGHER_THEN_LOWER,
                    ),
                )
                .build(),
        )
        .build()

    /** Empieza a analizar. Se llama una vez, con el caso de uso ya vinculado. */
    fun start() {
        if (closed || started) return
        started = true
        val live = LIVE.incrementAndGet()
        Log.i(TAG, "Análisis $token: inicio (análisis vivos: $live)")
        useCase.setAnalyzer(executor, ::analyze)
        onAnalysisThread { core.start() }
        executor.scheduleWithFixedDelay(
            { core.tick() },
            FaceTiming.TICK_MS,
            FaceTiming.TICK_MS,
            TimeUnit.MILLISECONDS,
        )
    }

    /** Reintento tras un error de modelo o inferencia (sin efecto en otro estado). */
    fun restart() {
        onAnalysisThread { core.restart() }
    }

    /**
     * Crea en el hilo de análisis el estado de este instante y lo entrega a
     * [answer] (en ese hilo). Nulo si la sesión ya se cerró.
     */
    fun query(answer: (FacePresence?) -> Unit) {
        if (closed || !started) return answer(null)
        try {
            executor.execute { answer(if (closed) null else core.snapshotNow()) }
        } catch (e: RejectedExecutionException) {
            answer(null)
        }
    }

    /** Libera analizador, detector e hilo. Idempotente. */
    fun close() {
        if (closed) return
        closed = true
        useCase.clearAnalyzer()
        if (!started) {
            executor.shutdownNow()
            return
        }
        onAnalysisThread {
            core.stop()
            val live = LIVE.decrementAndGet()
            val p = lastPresence
            Log.i(
                TAG,
                "Análisis $token: fin (análisis vivos: $live; cuadros enviados ${p?.framesSubmitted}, " +
                    "resultados aceptados ${p?.resultsAccepted}, cuadros descartados ${p?.framesDropped}, " +
                    "resultados descartados ${p?.resultsDiscarded} (por antiguos ${core.discardedTooOld}), " +
                    "edad máxima aceptada ${core.maxAcceptedAgeMs} ms; cuadro ${p?.frameWidth}x${p?.frameHeight} " +
                    "giro ${p?.frameRotationDegrees})",
            )
        }
        // Las tareas ya encoladas (entre ellas la detención) terminan; el
        // vigilante periódico se cancela.
        executor.shutdown()
    }

    private fun analyze(proxy: ImageProxy) {
        val entryNs = SystemClock.elapsedRealtimeNanos()
        val frame: Bitmap
        val rotation: Int
        val width: Int
        val height: Int
        try {
            if (closed || !core.acceptsFrames) {
                core.dropFrame()
                return
            }
            rotation = proxy.imageInfo.rotationDegrees
            width = proxy.width
            height = proxy.height
            frame = try {
                proxy.toBitmap()
            } catch (e: Exception) {
                core.dropFrame()
                return
            }
        } finally {
            proxy.close()
        }
        try {
            core.submit(frame, rotation, entryNs, width, height)
        } finally {
            frame.recycle()
        }
    }

    private fun onAnalysisThread(task: Runnable) {
        try {
            executor.execute(task)
        } catch (e: RejectedExecutionException) {
            // Sesión cerrada: el aviso tardío se descarta.
        }
    }

    companion object {
        private const val TAG = "VigiaFaceAnalysis"

        /** Tamaño pedido antes de girar (Área 05 §7 compara 640×480 y 1280×720). */
        private val ANALYSIS_SIZE = Size(640, 480)

        /** Análisis vivos en el proceso (diagnóstico: no debe pasar de 1). */
        private val LIVE = AtomicInteger(0)
        val liveCount: Int get() = LIVE.get()
    }
}
