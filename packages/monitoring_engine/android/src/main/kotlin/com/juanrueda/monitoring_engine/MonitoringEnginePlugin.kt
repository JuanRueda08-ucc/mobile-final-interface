package com.juanrueda.monitoring_engine

import android.util.Log
import com.juanrueda.monitoring_engine.camera.FrontCameraHost
import com.juanrueda.monitoring_engine.camera.FrontCameraPreview
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
        ) { token, reason, code ->
            scope.launch {
                try {
                    events.onPreviewClosed(PreviewClosedEvent(token, reason, code))
                } catch (e: Exception) {
                    // Flutter ya no escucha: el cierre nativo sigue siendo válido.
                    Log.w("VigiaFrontCamera", "Aviso de cierre no entregado", e)
                }
            }
        }
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
