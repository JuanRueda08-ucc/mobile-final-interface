package com.juanrueda.monitoring_engine

import androidx.camera.core.CameraState
import com.juanrueda.monitoring_engine.camera.CameraRules
import com.juanrueda.monitoring_engine.camera.PreviewGate
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

/*
 * Fase 5A: reglas puras de permiso, errores de CameraX y vigencia de las
 * peticiones de vista previa. Son pruebas con JVM, sin cámara ni Android real.
 * Se ejecutan desde android/:
 *   ./gradlew :monitoring_engine:testDebugUnitTest
 */
internal class CameraRulesTest {
    @Test
    fun permissionAfterRequest_distinguishesDeniedFromSettings() {
        assertEquals(
            CameraPermissionStatus.GRANTED,
            CameraRules.permissionAfterRequest(granted = true, showRationale = false),
        )
        assertEquals(
            CameraPermissionStatus.DENIED,
            CameraRules.permissionAfterRequest(granted = false, showRationale = true),
        )
        assertEquals(
            CameraPermissionStatus.REQUIRES_SETTINGS,
            CameraRules.permissionAfterRequest(granted = false, showRationale = false),
        )
    }

    @Test
    fun openFailure_onlyAttributesInUseWhenCameraXSaysSo() {
        assertEquals(PreviewOpenStatus.CAMERA_IN_USE, CameraRules.openFailure(CameraState.ERROR_CAMERA_IN_USE))
        assertEquals(PreviewOpenStatus.CAMERA_IN_USE, CameraRules.openFailure(CameraState.ERROR_MAX_CAMERAS_IN_USE))
        assertEquals(PreviewOpenStatus.CAMERA_DISABLED, CameraRules.openFailure(CameraState.ERROR_CAMERA_DISABLED))
        assertEquals(PreviewOpenStatus.FAILED, CameraRules.openFailure(CameraState.ERROR_CAMERA_FATAL_ERROR))
        assertEquals(PreviewOpenStatus.FAILED, CameraRules.openFailure(CameraState.ERROR_STREAM_CONFIG))
    }

    @Test
    fun closeReason_mapsInUseAndOtherErrors() {
        assertEquals(PreviewCloseReason.CAMERA_IN_USE, CameraRules.closeReason(CameraState.ERROR_CAMERA_IN_USE))
        assertEquals(PreviewCloseReason.CAMERA_ERROR, CameraRules.closeReason(CameraState.ERROR_CAMERA_FATAL_ERROR))
        assertEquals("cameraInUse", CameraRules.errorName(CameraState.ERROR_CAMERA_IN_USE))
    }

    @Test
    fun displayRotation_isZeroWhenTextureRotatesAndNormalizedOtherwise() {
        assertEquals(0, CameraRules.displayRotation(270, textureHandlesRotation = true))
        assertEquals(270, CameraRules.displayRotation(270, textureHandlesRotation = false))
        assertEquals(90, CameraRules.displayRotation(-270, textureHandlesRotation = false))
        assertEquals(0, CameraRules.displayRotation(360, textureHandlesRotation = false))
    }

    @Test
    fun uprightSize_swapsOnQuarterTurns() {
        assertEquals(480 to 640, CameraRules.uprightSize(640, 480, 90))
        assertEquals(480 to 640, CameraRules.uprightSize(640, 480, 270))
        assertEquals(640 to 480, CameraRules.uprightSize(640, 480, 180))
    }

    @Test
    fun gate_newOpenSupersedesAndOldCloseIsIgnored() {
        val gate = PreviewGate()
        assertNull(gate.begin(1))
        // Pantalla nueva abre antes de que la anterior se desmonte.
        assertEquals(1L, gate.begin(2))
        assertFalse(gate.isCurrent(1))
        // El cierre tardío de la pantalla anterior no cierra la vigente.
        assertFalse(gate.end(1))
        assertTrue(gate.isCurrent(2))
        assertTrue(gate.end(2))
        // Cerrar dos veces no hace nada la segunda.
        assertFalse(gate.end(2))
        assertNull(gate.current)
    }
}
