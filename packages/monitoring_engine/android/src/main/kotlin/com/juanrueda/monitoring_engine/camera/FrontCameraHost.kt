package com.juanrueda.monitoring_engine.camera

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.provider.Settings
import android.util.Log
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import com.juanrueda.monitoring_engine.CameraPermissionStatus
import com.juanrueda.monitoring_engine.FrontCameraHostApi
import com.juanrueda.monitoring_engine.PreviewCloseReason
import com.juanrueda.monitoring_engine.PreviewOpenResult
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.PluginRegistry
import kotlin.coroutines.resume
import kotlinx.coroutines.CancellableContinuation
import kotlinx.coroutines.suspendCancellableCoroutine

/**
 * Implementación de [FrontCameraHostApi]: permiso CAMERA y vista previa
 * frontal. La cámara solo se abre con la Activity visible y se libera cuando
 * deja de verse o se desconecta.
 */
internal class FrontCameraHost(
    private val context: Context,
    private val preview: FrontCameraPreview,
) : FrontCameraHostApi, PluginRegistry.RequestPermissionsResultListener {
    private var binding: ActivityPluginBinding? = null
    private var activityLifecycle: Lifecycle? = null
    private val permissionWaiters = mutableListOf<CancellableContinuation<CameraPermissionStatus>>()

    /** Explicación que Android ofrecía al lanzar la solicitud en curso. */
    private var rationaleBeforeRequest = false

    private val visibilityObserver = object : DefaultLifecycleObserver {
        override fun onStop(owner: LifecycleOwner) {
            preview.closeFromNative(PreviewCloseReason.BACKGROUND)
        }
    }

    private val activity: Activity? get() = binding?.activity

    fun attachActivity(binding: ActivityPluginBinding) {
        detachActivity()
        this.binding = binding
        binding.addRequestPermissionsResultListener(this)
        activityLifecycle = (binding.activity as? LifecycleOwner)?.lifecycle
        activityLifecycle?.addObserver(visibilityObserver)
    }

    fun detachActivity() {
        val b = binding ?: return
        preview.closeFromNative(PreviewCloseReason.DETACHED)
        activityLifecycle?.removeObserver(visibilityObserver)
        activityLifecycle = null
        b.removeRequestPermissionsResultListener(this)
        binding = null
        // Sin Activity no llegará respuesta: se informa el estado actual.
        resolvePermission(checkCameraPermission())
    }

    override fun checkCameraPermission(): CameraPermissionStatus =
        if (context.checkSelfPermission(Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) {
            CameraPermissionStatus.GRANTED
        } else {
            CameraPermissionStatus.DENIED
        }

    override suspend fun requestCameraPermission(): CameraPermissionStatus {
        val current = checkCameraPermission()
        val activity = activity
        if (current == CameraPermissionStatus.GRANTED || activity == null) return current
        return suspendCancellableCoroutine { cont ->
            permissionWaiters += cont
            cont.invokeOnCancellation { permissionWaiters.remove(cont) }
            // Pulsaciones repetidas comparten la misma solicitud de Android.
            if (permissionWaiters.size == 1) {
                rationaleBeforeRequest = activity.shouldShowRequestPermissionRationale(Manifest.permission.CAMERA)
                activity.requestPermissions(arrayOf(Manifest.permission.CAMERA), REQUEST_CODE)
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != REQUEST_CODE) return false
        val index = permissions.indexOf(Manifest.permission.CAMERA)
        val status = if (index < 0) {
            // Solicitud interrumpida (resultado vacío): se consulta de nuevo.
            checkCameraPermission()
        } else {
            CameraRules.permissionAfterRequest(
                granted = grantResults.getOrNull(index) == PackageManager.PERMISSION_GRANTED,
                showRationaleBefore = rationaleBeforeRequest,
                showRationaleAfter = activity?.shouldShowRequestPermissionRationale(Manifest.permission.CAMERA) == true,
            )
        }
        resolvePermission(status)
        return true
    }

    private fun resolvePermission(status: CameraPermissionStatus) {
        val waiters = permissionWaiters.toList()
        permissionWaiters.clear()
        waiters.forEach { if (it.isActive) it.resume(status) }
    }

    override fun openAppSettings(): Boolean {
        val intent = Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.fromParts("package", context.packageName, null),
        )
        return try {
            val a = activity
            if (a != null) a.startActivity(intent)
            else context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            true
        } catch (e: Exception) {
            Log.w("VigiaFrontCamera", "No se pudieron abrir los ajustes", e)
            false
        }
    }

    override suspend fun openFrontPreview(token: Long): PreviewOpenResult =
        preview.open(token, activityLifecycle)

    override fun closeFrontPreview(token: Long) {
        preview.close(token)
    }

    override fun restartFaceAnalysis(token: Long): Boolean = preview.restartAnalysis(token)

    private companion object {
        // Código propio de la solicitud CAMERA de este plugin.
        const val REQUEST_CODE = 0x5641
    }
}
