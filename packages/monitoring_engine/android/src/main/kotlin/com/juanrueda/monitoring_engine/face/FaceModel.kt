package com.juanrueda.monitoring_engine.face

import java.io.FileNotFoundException
import java.io.InputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.security.MessageDigest

/**
 * Manifiesto del modelo facial empaquetado (fase 5B; campos de Área 05 §3).
 *
 * El archivo es el `face_landmarker.task` oficial de MediaPipe (float16,
 * ruta versionada `/1/` del bucket `mediapipe-models`). Procedencia, licencia
 * y verificación: `docs/fase5b-mediapipe.md` y `docs/licenses.md`.
 */
internal object FaceModelSpec {
    const val MODEL_ID = "mediapipe/face_landmarker/float16/1"
    const val ASSET_PATH = "vigia_models/face_landmarker_float16_v1.task"
    const val SOURCE_URL =
        "https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/1/face_landmarker.task"
    const val SIZE_BYTES = 3_758_596L
    const val SHA256 = "64184e229b263107bc2b804c6625db1341ff2bb731874b0bcc2fe6544e0bc9ff"
    const val TASK_LIBRARY = "com.google.mediapipe:tasks-vision:1.0.0"
    const val RUNNING_MODE = "LIVE_STREAM"
    const val DELEGATE = "CPU"

    /** Dos rostros como mínimo: con uno no se puede afirmar que no haya varios (Área 05 §3). */
    const val MAX_FACES = 2

    /** Confianzas de la tarea (Área 05 §7, candidatas): no son una medida ocular. */
    const val MIN_DETECTION_CONFIDENCE = 0.5f
    const val MIN_PRESENCE_CONFIDENCE = 0.5f
    const val MIN_TRACKING_CONFIDENCE = 0.5f
}

/** Resultado de leer y verificar el modelo. */
internal sealed interface ModelLoad {
    /** Bytes verificados, en un búfer directo listo para MediaPipe. */
    class Ready(val buffer: ByteBuffer) : ModelLoad

    /** Fallo explícito y recuperable; [code] es un código técnico estable. */
    data class Failed(val code: String) : ModelLoad
}

/** Códigos de error del modelo y del análisis (diagnóstico, no textos de interfaz). */
internal object FaceErrorCodes {
    /** El asset no está en el APK. */
    const val MODEL_MISSING = "modelMissing"

    /** El asset existe pero su tamaño o SHA-256 no coinciden: alterado o truncado. */
    const val MODEL_CORRUPT = "modelCorrupt"

    /** Bytes verificados que MediaPipe no puede cargar (o biblioteca nativa ausente). */
    const val MODEL_INCOMPATIBLE = "modelIncompatible"

    /** No se pudo leer el asset por otra causa de E/S. */
    const val MODEL_READ_FAILED = "modelReadFailed"

    /** MediaPipe informó un error de inferencia. */
    const val INFERENCE_FAILED = "inferenceFailed"

    /** CameraX no admitió el análisis junto a la vista previa. */
    const val ANALYSIS_UNSUPPORTED = "analysisUnsupported"
}

/**
 * Lee el modelo y comprueba tamaño y SHA-256 **sobre los mismos bytes** que
 * se entregarán a MediaPipe (`setModelAssetBuffer`): no hay ventana entre la
 * verificación y la carga. Sin dependencias de Android, para probarlo en la JVM.
 */
internal object FaceModelLoader {
    fun load(
        open: () -> InputStream,
        expectedSize: Long = FaceModelSpec.SIZE_BYTES,
        expectedSha256: String = FaceModelSpec.SHA256,
    ): ModelLoad {
        val bytes = try {
            open().use { readAtMost(it, expectedSize + 1) }
        } catch (e: FileNotFoundException) {
            return ModelLoad.Failed(FaceErrorCodes.MODEL_MISSING)
        } catch (e: Exception) {
            return ModelLoad.Failed(FaceErrorCodes.MODEL_READ_FAILED)
        }
        if (bytes.size.toLong() != expectedSize) return ModelLoad.Failed(FaceErrorCodes.MODEL_CORRUPT)
        if (sha256Hex(bytes) != expectedSha256) return ModelLoad.Failed(FaceErrorCodes.MODEL_CORRUPT)
        val buffer = ByteBuffer.allocateDirect(bytes.size).order(ByteOrder.nativeOrder())
        buffer.put(bytes)
        buffer.rewind()
        return ModelLoad.Ready(buffer)
    }

    /** Lee como mucho [limit] bytes: un archivo mayor de lo esperado se detecta sin leerlo entero. */
    private fun readAtMost(input: InputStream, limit: Long): ByteArray {
        val out = java.io.ByteArrayOutputStream()
        val chunk = ByteArray(64 * 1024)
        var total = 0L
        while (total < limit) {
            val n = input.read(chunk, 0, minOf(chunk.size.toLong(), limit - total).toInt())
            if (n < 0) break
            out.write(chunk, 0, n)
            total += n
        }
        return out.toByteArray()
    }

    fun sha256Hex(bytes: ByteArray): String =
        MessageDigest.getInstance("SHA-256").digest(bytes).joinToString("") { "%02x".format(it) }
}
