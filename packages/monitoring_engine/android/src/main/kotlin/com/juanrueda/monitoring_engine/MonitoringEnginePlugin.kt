package com.juanrueda.monitoring_engine

import android.util.Log
import com.juanrueda.monitoring_engine.camera.FrontCameraHost
import com.juanrueda.monitoring_engine.camera.FrontCameraPreview
import com.juanrueda.monitoring_engine.face.FacePresence
import com.juanrueda.monitoring_engine.face.FacePresenceStatus
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

/**
 * Plugin del motor de Vigía.
 *
 * - `monitoring_engine` (MethodChannel de la plantilla, VIG-003):
 *   `getPlatformVersion`.
 * - Fase 5A: [FrontCameraHostApi] (Pigeon) con el permiso CAMERA y la vista
 *   previa frontal; [FrontCameraFlutterApi] avisa de los cierres nativos.
 * - Fase 5B: [FrontCameraFlutterApi.onFaceAnalysis] entrega el resultado
 *   compacto de presencia facial (sin imágenes ni puntos faciales).
 */
class MonitoringEnginePlugin :
    FlutterPlugin,
    ActivityAware,
    MethodCallHandler {
    private lateinit var channel: MethodChannel
    private var camera: FrontCameraHost? = null
    private var scope: CoroutineScope? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "monitoring_engine")
        channel.setMethodCallHandler(this)

        val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
        this.scope = scope
        val events = FrontCameraFlutterApi(flutterPluginBinding.binaryMessenger)
        val preview = FrontCameraPreview(
            flutterPluginBinding.applicationContext,
            flutterPluginBinding.textureRegistry,
            onClosed = { token, reason, code ->
                scope.launch {
                    try {
                        events.onPreviewClosed(PreviewClosedEvent(token, reason, code))
                    } catch (e: Exception) {
                        // Flutter ya no escucha: el cierre nativo sigue siendo válido.
                        Log.w("VigiaFrontCamera", "Aviso de cierre no entregado", e)
                    }
                }
            },
            onFacePresence = { presence ->
                scope.launch {
                    try {
                        events.onFaceAnalysis(presence.toPigeon())
                    } catch (e: Exception) {
                        // Flutter ya no escucha; Dart vigila por su cuenta la
                        // falta de noticias.
                        Log.w("VigiaFaceAnalysis", "Resultado de análisis no entregado")
                    }
                }
            },
        )
        val host = FrontCameraHost(flutterPluginBinding.applicationContext, preview)
        camera = host
        FrontCameraHostApi.setUp(flutterPluginBinding.binaryMessenger, host)
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        if (call.method == "getPlatformVersion") {
            result.success("Android ${android.os.Build.VERSION.RELEASE}")
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        FrontCameraHostApi.setUp(binding.binaryMessenger, null)
        camera?.detachActivity()
        camera = null
        scope?.cancel()
        scope = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        camera?.attachActivity(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        camera?.detachActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        camera?.attachActivity(binding)
    }

    override fun onDetachedFromActivity() {
        camera?.detachActivity()
    }
}

private fun FacePresence.toPigeon() = FaceAnalysisSnapshot(
    token = token,
    generation = generation,
    status = when (status) {
        FacePresenceStatus.LOADING_MODEL -> FaceAnalysisStatus.LOADING_MODEL
        FacePresenceStatus.WAITING_RESULTS -> FaceAnalysisStatus.WAITING_RESULTS
        FacePresenceStatus.NO_FACE -> FaceAnalysisStatus.NO_FACE
        FacePresenceStatus.ONE_FACE -> FaceAnalysisStatus.ONE_FACE
        FacePresenceStatus.MULTIPLE_FACES -> FaceAnalysisStatus.MULTIPLE_FACES
        FacePresenceStatus.STOPPED -> FaceAnalysisStatus.STOPPED
        FacePresenceStatus.MODEL_ERROR -> FaceAnalysisStatus.MODEL_ERROR
        FacePresenceStatus.ANALYSIS_ERROR -> FaceAnalysisStatus.ANALYSIS_ERROR
    },
    faceCount = faceCount?.toLong(),
    resultAgeMs = resultAgeMs,
    maxFaces = maxFaces.toLong(),
    staleAfterMs = staleAfterMs,
    framesSubmitted = framesSubmitted,
    resultsAccepted = resultsAccepted,
    framesDropped = framesDropped,
    resultsDiscarded = resultsDiscarded,
    expired = expired,
    frameWidth = frameWidth?.toLong(),
    frameHeight = frameHeight?.toLong(),
    frameRotationDegrees = frameRotationDegrees?.toLong(),
    errorCode = errorCode,
)
