package com.juanrueda.monitoring_engine.camera

import androidx.camera.core.CameraState
import com.juanrueda.monitoring_engine.CameraPermissionStatus
import com.juanrueda.monitoring_engine.PreviewCloseReason
import com.juanrueda.monitoring_engine.PreviewOpenStatus

/**
 * Reglas puras de la fase 5A, separadas de Android para probarlas en la JVM.
 * Las constantes de [CameraState] son enteros que el compilador incorpora.
 */
internal object CameraRules {
    /**
     * Estado tras responder una solicitud de permiso. Si Android denegó y ya
     * no explicaría la solicitud, solo queda abrir los ajustes del teléfono.
     *
     * Limitación conocida: si el usuario descarta el diálogo la primera vez,
     * Android tampoco ofrece explicación y el caso se informa como
     * [CameraPermissionStatus.REQUIRES_SETTINGS].
     */
    fun permissionAfterRequest(granted: Boolean, showRationale: Boolean): CameraPermissionStatus =
        when {
            granted -> CameraPermissionStatus.GRANTED
            showRationale -> CameraPermissionStatus.DENIED
            else -> CameraPermissionStatus.REQUIRES_SETTINGS
        }

    /** Resultado de apertura para un error de CameraX antes de abrir. */
    fun openFailure(errorCode: Int): PreviewOpenStatus =
        when (errorCode) {
            CameraState.ERROR_CAMERA_IN_USE,
            CameraState.ERROR_MAX_CAMERAS_IN_USE -> PreviewOpenStatus.CAMERA_IN_USE
            CameraState.ERROR_CAMERA_DISABLED -> PreviewOpenStatus.CAMERA_DISABLED
            else -> PreviewOpenStatus.FAILED
        }

    /** Motivo de cierre para un error de CameraX con la vista ya abierta. */
    fun closeReason(errorCode: Int): PreviewCloseReason =
        when (errorCode) {
            CameraState.ERROR_CAMERA_IN_USE,
            CameraState.ERROR_MAX_CAMERAS_IN_USE -> PreviewCloseReason.CAMERA_IN_USE
            else -> PreviewCloseReason.CAMERA_ERROR
        }

    /** Código técnico legible de un error de CameraX (diagnóstico). */
    fun errorName(errorCode: Int): String =
        when (errorCode) {
            CameraState.ERROR_CAMERA_IN_USE -> "cameraInUse"
            CameraState.ERROR_MAX_CAMERAS_IN_USE -> "maxCamerasInUse"
            CameraState.ERROR_CAMERA_DISABLED -> "cameraDisabled"
            CameraState.ERROR_CAMERA_FATAL_ERROR -> "cameraFatalError"
            CameraState.ERROR_DO_NOT_DISTURB_MODE_ENABLED -> "doNotDisturbEnabled"
            CameraState.ERROR_OTHER_RECOVERABLE_ERROR -> "otherRecoverableError"
            CameraState.ERROR_STREAM_CONFIG -> "streamConfig"
            else -> "cameraError$errorCode"
        }

    /** Giro que Flutter debe aplicar: ninguno si la textura ya lo resuelve. */
    fun displayRotation(sensorToDisplayDegrees: Int, textureHandlesRotation: Boolean): Int =
        if (textureHandlesRotation) 0 else ((sensorToDisplayDegrees % 360) + 360) % 360

    /** Tamaño de la imagen derecha a partir del búfer y del giro aplicado. */
    fun uprightSize(bufferWidth: Int, bufferHeight: Int, rotationDegrees: Int): Pair<Int, Int> =
        if (rotationDegrees == 90 || rotationDegrees == 270) bufferHeight to bufferWidth
        else bufferWidth to bufferHeight
}

/**
 * Petición vigente de vista previa. Flutter elige el token; una apertura nueva
 * sustituye a la anterior y un cierre con un token antiguo no cierra la
 * vigente (la pantalla anterior se desmonta después de montar la nueva).
 */
internal class PreviewGate {
    var current: Long? = null
        private set

    /** Hace vigente [token] y devuelve el anterior, si había. */
    fun begin(token: Long): Long? {
        val previous = current
        current = token
        return previous
    }

    fun isCurrent(token: Long): Boolean = current == token

    /** Termina [token] si es el vigente. `false` si era antiguo o ya cerrado. */
    fun end(token: Long): Boolean {
        if (current != token) return false
        current = null
        return true
    }
}
