package com.juanrueda.monitoring_engine.camera

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.camera.core.Camera
import androidx.camera.core.CameraSelector
import androidx.camera.core.CameraState
import androidx.camera.core.Preview
import androidx.camera.core.SurfaceRequest
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.lifecycle.awaitInstance
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.LifecycleRegistry
import androidx.lifecycle.Observer
import com.juanrueda.monitoring_engine.PreviewCloseReason
import com.juanrueda.monitoring_engine.PreviewOpenResult
import com.juanrueda.monitoring_engine.PreviewOpenStatus
import com.juanrueda.monitoring_engine.face.FaceAnalysisSession
import com.juanrueda.monitoring_engine.face.FacePresence
import com.juanrueda.monitoring_engine.monitoring.MonitoringCoordinator
import io.flutter.view.TextureRegistry
import java.util.concurrent.Executor
import kotlin.coroutines.resume
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withTimeoutOrNull

/**
 * Único propietario de la cámara frontal en el proceso (fases 5A y 5B).
 *
 * - Vincula Preview y, desde la fase 5B, el `ImageAnalysis` de
 *   [FaceAnalysisSession] **en la misma llamada y la misma cámara**: no se
 *   abre una segunda cámara. Sin fotografía, grabación ni almacenamiento de
 *   imágenes.
 * - Cada apertura tiene su propio análisis facial; al liberarla se cierran
 *   analizador, detector e hilo de análisis.
 * - Cada apertura usa un [LifecycleOwner] propio que vive mientras la
 *   pantalla de Flutter la pide; al cerrarla se destruye y CameraX libera la
 *   cámara. La Activity que deja de verse cierra también la vista previa.
 * - «Abierta» solo se responde cuando CameraX informa [CameraState.Type.OPEN]:
 *   el permiso concedido no basta.
 * - Una apertura o un cierre posteriores invalidan la petición anterior: su
 *   respuesta tardía es [PreviewOpenStatus.SUPERSEDED] y sus recursos se
 *   liberan sin mostrarse.
 *
 * Todo se ejecuta en el hilo principal (Pigeon usa `Dispatchers.Main`).
 */
internal class FrontCameraPreview(
    private val context: Context,
    private val textures: TextureRegistry,
    private val onClosed: (token: Long, reason: PreviewCloseReason, errorCode: String?) -> Unit,
    private val onFacePresence: (FacePresence) -> Unit,
    /** Fase 5C: coordinador del recorrido experimental (observaciones y apertura vinculada). */
    private val monitoring: MonitoringCoordinator? = null,
) {
    private val gate = PreviewGate()
    private var active: Active? = null
    private val main = Handler(Looper.getMainLooper())
    private val mainExecutor = Executor { main.post(it) }

    /** Recursos de una petición. Se liberan una sola vez. */
    private inner class Active(val token: Long) {
        val outcome = CompletableDeferred<Pair<PreviewOpenStatus, String?>>()
        val owner = PreviewLifecycleOwner()
        var provider: ProcessCameraProvider? = null
        var preview: Preview? = null
        var camera: Camera? = null
        var producer: TextureRegistry.SurfaceProducer? = null
        var transformation: SurfaceRequest.TransformationInfo? = null
        var analysis: FaceAnalysisSession? = null
        var surfacesInUse = 0
        var opened = false
        var released = false

        val stateObserver = Observer<CameraState> { state -> onCameraState(this, state) }
    }

    /** `true` si hay una petición vigente (abriendo o abierta). */
    val isActive: Boolean get() = gate.current != null

    suspend fun open(token: Long, activityLifecycle: Lifecycle?): PreviewOpenResult {
        // Una sola cámara: la petición anterior se cierra antes de seguir.
        gate.current?.let { release(it) }
        if (activityLifecycle?.currentState?.isAtLeast(Lifecycle.State.STARTED) != true) {
            return result(token, PreviewOpenStatus.FAILED, "activityNotVisible")
        }
        if (context.checkSelfPermission(Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
            return result(token, PreviewOpenStatus.PERMISSION_MISSING)
        }
        gate.begin(token)
        val a = Active(token)
        active = a

        val provider = try {
            ProcessCameraProvider.awaitInstance(context)
        } catch (e: Exception) {
            Log.w(TAG, "ProcessCameraProvider no disponible", e)
            release(token)
            return result(token, PreviewOpenStatus.FAILED, "providerUnavailable")
        }
        if (a.released) return result(token, PreviewOpenStatus.SUPERSEDED)
        a.provider = provider

        val hasFront = try {
            provider.hasCamera(CameraSelector.DEFAULT_FRONT_CAMERA)
        } catch (e: Exception) {
            Log.w(TAG, "No se pudo consultar la cámara frontal", e)
            false
        }
        if (!hasFront) {
            release(token)
            return result(token, PreviewOpenStatus.NO_FRONT_CAMERA)
        }

        try {
            bind(a, provider)
        } catch (e: Exception) {
            Log.w(TAG, "No se pudo vincular la vista previa", e)
            release(token)
            return result(token, PreviewOpenStatus.FAILED, "bindFailed")
        }

        val outcome = withTimeoutOrNull(OPEN_TIMEOUT_MS) { a.outcome.await() }
        if (a.released) return result(token, PreviewOpenStatus.SUPERSEDED)
        if (outcome == null) {
            release(token)
            return result(token, PreviewOpenStatus.FAILED, "openTimeout")
        }
        val (status, code) = outcome
        if (status != PreviewOpenStatus.OPENED) {
            release(token)
            return result(token, status, code)
        }
        a.opened = true
        monitoring?.attach(token)
        val producer = a.producer!!
        val info = a.transformation
        val rotation = CameraRules.displayRotation(
            info?.rotationDegrees
                ?: a.camera!!.cameraInfo.getSensorRotationDegrees(),
            producer.handlesCropAndRotation(),
        )
        val (w, h) = CameraRules.uprightSize(producer.width, producer.height, rotation)
        return PreviewOpenResult(
            token = token,
            status = PreviewOpenStatus.OPENED,
            textureId = producer.id(),
            width = w.toLong(),
            height = h.toLong(),
            rotationDegrees = rotation.toLong(),
            mirrored = info?.isMirroring ?: true,
        )
    }

    private fun bind(a: Active, provider: ProcessCameraProvider) {
        val producer = textures.createSurfaceProducer()
        a.producer = producer
        val preview = Preview.Builder().build()
        a.preview = preview
        preview.setSurfaceProvider(mainExecutor) { request ->
            if (a.released) {
                request.willNotProvideSurface()
                return@setSurfaceProvider
            }
            producer.setSize(request.resolution.width, request.resolution.height)
            request.setTransformationInfoListener(mainExecutor) { a.transformation = it }
            a.surfacesInUse++
            request.provideSurface(producer.surface, mainExecutor) {
                a.surfacesInUse--
                // CameraX ya no usa la superficie: si la petición terminó,
                // se libera ahora la textura.
                if (a.released && a.surfacesInUse == 0) producer.release()
            }
        }
        val analysis = FaceAnalysisSession(
            context,
            a.token,
            onFacePresence,
            onObservation = { monitoring?.observe(it) },
        )
        a.analysis = analysis
        a.owner.start()
        val camera = provider.bindToLifecycle(
            a.owner,
            CameraSelector.DEFAULT_FRONT_CAMERA,
            preview,
            analysis.useCase,
        )
        a.camera = camera
        camera.cameraInfo.cameraState.observeForever(a.stateObserver)
        // El modelo se carga en el hilo de análisis mientras la cámara abre.
        analysis.start()
    }

    /**
     * Estado del análisis facial de [token] creado ahora en su hilo de
     * análisis; nulo si [token] no es la apertura vigente o ya se cerró.
     */
    suspend fun queryAnalysis(token: Long): FacePresence? {
        val a = active?.takeIf { it.token == token && gate.isCurrent(token) } ?: return null
        val analysis = a.analysis ?: return null
        return suspendCancellableCoroutine { cont ->
            analysis.query { presence -> main.post { if (cont.isActive) cont.resume(presence) } }
        }
    }

    /**
     * Reintenta el análisis facial de [token] tras un error. `false` si
     * [token] no es la apertura vigente.
     */
    fun restartAnalysis(token: Long): Boolean {
        val a = active?.takeIf { it.token == token && gate.isCurrent(token) } ?: return false
        val analysis = a.analysis ?: return false
        analysis.restart()
        return true
    }

    private fun onCameraState(a: Active, state: CameraState) {
        if (a.released) return
        val error = state.error
        if (error != null) {
            val name = CameraRules.errorName(error.code)
            if (!a.opened) {
                a.outcome.complete(CameraRules.openFailure(error.code) to name)
            } else {
                release(a.token)
                onClosed(a.token, CameraRules.closeReason(error.code), name)
            }
            return
        }
        when (state.type) {
            CameraState.Type.OPEN -> a.outcome.complete(PreviewOpenStatus.OPENED to null)
            CameraState.Type.CLOSED -> if (a.opened) {
                release(a.token)
                onClosed(a.token, PreviewCloseReason.CAMERA_ERROR, "closedUnexpectedly")
            }
            else -> Unit
        }
    }

    /** Cierre pedido por Flutter. Un token que ya no es el vigente se ignora. */
    fun close(token: Long) {
        release(token)
    }

    /** Cierre decidido aquí (segundo plano, desconexión); avisa a Flutter. */
    fun closeFromNative(reason: PreviewCloseReason) {
        val token = gate.current ?: return
        val wasOpened = active?.opened == true
        release(token)
        // Una apertura en curso ya responde SUPERSEDED; el aviso es para una
        // vista que Flutter cree abierta.
        if (wasOpened) onClosed(token, reason, null)
    }

    private fun release(token: Long) {
        if (!gate.end(token)) return
        val a = active?.takeIf { it.token == token } ?: return
        active = null
        a.released = true
        monitoring?.detach(token)
        a.outcome.complete(PreviewOpenStatus.SUPERSEDED to null)
        a.camera?.cameraInfo?.cameraState?.removeObserver(a.stateObserver)
        // Primero el análisis: retira el analizador y cierra el detector.
        a.analysis?.close()
        val useCases = listOfNotNull(a.preview, a.analysis?.useCase)
        if (useCases.isNotEmpty()) {
            try {
                a.provider?.unbind(*useCases.toTypedArray())
            } catch (e: Exception) {
                Log.w(TAG, "No se pudo desvincular la vista previa", e)
            }
        }
        a.owner.destroy()
        // Sin superficie entregada a CameraX, la textura se libera ya; si no,
        // al confirmar CameraX que dejó de usarla.
        if (a.surfacesInUse == 0) a.producer?.release()
    }

    private fun result(token: Long, status: PreviewOpenStatus, code: String? = null) =
        PreviewOpenResult(token = token, status = status, errorCode = code)

    private companion object {
        const val TAG = "VigiaFrontCamera"
        const val OPEN_TIMEOUT_MS = 10_000L
    }
}

/** Ciclo de vida propio de una apertura: STARTED→RESUMED al abrir, DESTROYED al cerrar. */
internal class PreviewLifecycleOwner : LifecycleOwner {
    private val registry = LifecycleRegistry(this)
    override val lifecycle: Lifecycle get() = registry

    fun start() {
        registry.currentState = Lifecycle.State.RESUMED
    }

    fun destroy() {
        if (registry.currentState != Lifecycle.State.INITIALIZED) {
            registry.currentState = Lifecycle.State.DESTROYED
        }
    }
}
