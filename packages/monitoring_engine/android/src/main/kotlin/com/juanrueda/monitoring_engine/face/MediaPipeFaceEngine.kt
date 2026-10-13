package com.juanrueda.monitoring_engine.face

import android.content.Context
import android.graphics.Bitmap
import com.google.mediapipe.framework.image.BitmapImageBuilder
import com.google.mediapipe.tasks.core.BaseOptions
import com.google.mediapipe.tasks.core.Delegate
import com.google.mediapipe.tasks.vision.core.ImageProcessingOptions
import com.google.mediapipe.tasks.vision.core.RunningMode
import com.google.mediapipe.tasks.vision.facelandmarker.FaceLandmarker
import java.nio.ByteBuffer

/**
 * [FaceEngine] sobre MediaPipe Tasks Vision 1.0.0 (Face Landmarker,
 * LIVE_STREAM, CPU, hasta [FaceModelSpec.MAX_FACES] rostros).
 *
 * - Sin blendshapes ni matrices: esta fase solo cuenta rostros.
 * - Los puntos faciales del resultado se leen aquí para contar rostros y no
 *   salen de este método: no se envían a Flutter, no se guardan ni se
 *   registran.
 * - **Propiedad de la imagen.** Con un `MPImage` sobre `Bitmap`,
 *   `detectAsync` copia los píxeles en un `ImageFrame` nativo antes de volver
 *   (`AndroidPacketCreator.createImage` → `CreateImageFrameFromBitmap`, que
 *   hace `memcpy`; MediaPipe v1.0.0). Por eso el llamador puede liberar el
 *   `Bitmap` al volver. La imagen que MediaPipe entrega al listener es otra
 *   copia, propiedad del listener, y se cierra en él.
 * - **Giro.** `ImageProcessingOptions.rotationDegrees` es horario, igual que
 *   `ImageInfo.rotationDegrees` de CameraX: se pasa sin cambio. La imagen de
 *   análisis no se espeja; el espejo es solo de la vista previa.
 * - Con LIVE_STREAM, MediaPipe añade un limitador de flujo (`maxInFlight=1`,
 *   `maxInQueue=1`) que descarta cuadros si está ocupado: la cola no crece.
 */
internal class MediaPipeFaceEngine private constructor(
    private val landmarker: FaceLandmarker,
) : FaceEngine<Bitmap> {

    override fun detectAsync(frame: Bitmap, rotationDegrees: Int, timestampMs: Long) {
        val image = BitmapImageBuilder(frame).build()
        val options = ImageProcessingOptions.builder().setRotationDegrees(rotationDegrees).build()
        landmarker.detectAsync(image, options, timestampMs)
    }

    override fun close() {
        landmarker.close()
    }

    companion object {
        fun create(context: Context, model: ByteBuffer, listener: FaceEngineListener): MediaPipeFaceEngine {
            val options = FaceLandmarker.FaceLandmarkerOptions.builder()
                .setBaseOptions(
                    BaseOptions.builder()
                        .setModelAssetBuffer(model)
                        .setDelegate(Delegate.CPU)
                        .build(),
                )
                .setRunningMode(RunningMode.LIVE_STREAM)
                .setNumFaces(FaceModelSpec.MAX_FACES)
                .setMinFaceDetectionConfidence(FaceModelSpec.MIN_DETECTION_CONFIDENCE)
                .setMinFacePresenceConfidence(FaceModelSpec.MIN_PRESENCE_CONFIDENCE)
                .setMinTrackingConfidence(FaceModelSpec.MIN_TRACKING_CONFIDENCE)
                .setOutputFaceBlendshapes(false)
                .setOutputFacialTransformationMatrixes(false)
                .setResultListener { result, input ->
                    val faces = result.faceLandmarks().size
                    input.close()
                    listener.onResult(result.timestampMs(), faces)
                }
                .setErrorListener { _ ->
                    // Solo el código: el mensaje de MediaPipe no se reenvía ni se registra.
                    listener.onError(FaceErrorCodes.INFERENCE_FAILED)
                }
                .build()
            return MediaPipeFaceEngine(FaceLandmarker.createFromOptions(context, options))
        }
    }
}
