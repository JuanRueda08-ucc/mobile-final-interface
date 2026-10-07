package com.juanrueda.vigia

import android.media.AudioManager
import android.media.ToneGenerator
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Fase 2 (demostración): reproduce un tono local con ToneGenerator para la
 * prueba de sonido de Preparación y las alertas simuladas de Monitoreo.
 *
 * Devuelve solo el resultado técnico (played/cause). No afirma que alguien lo
 * oyera, no usa micrófono, red ni archivos. El AlertDispatcher del motor real
 * (Área 04 §10) queda fuera de esta fase.
 *
 * Fase 3: el canal `vigia/app` informa el applicationId real del proceso para
 * que Dart compruebe, antes de abrir el historial, que el recorrido DEMO corre
 * en com.juanrueda.vigia.demo y no en la app normal.
 */
class MainActivity : FlutterActivity() {
    private val handler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "vigia/app")
            .setMethodCallHandler { call, result ->
                if (call.method == "applicationId") result.success(packageName)
                else result.notImplemented()
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "vigia/demo_sound")
            .setMethodCallHandler { call, result ->
                if (call.method != "play") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                result.success(
                    play(
                        call.argument<String>("kind") ?: "test",
                        call.argument<String>("pattern") ?: "patron_1",
                    ),
                )
            }
    }

    /**
     * Patrones incluidos (P13): tonos de ToneGenerator para prueba,
     * advertencia y cierre ocular prolongado. Un patrón desconocido no se
     * sustituye por otro: se informa como fallo.
     */
    private val patterns = mapOf(
        "patron_1" to Triple(
            ToneGenerator.TONE_PROP_BEEP,
            ToneGenerator.TONE_PROP_BEEP2,
            ToneGenerator.TONE_CDMA_HIGH_L,
        ),
        "patron_2" to Triple(
            ToneGenerator.TONE_CDMA_ALERT_CALL_GUARD,
            ToneGenerator.TONE_CDMA_ALERT_INCALL_LITE,
            ToneGenerator.TONE_CDMA_EMERGENCY_RINGBACK,
        ),
        "patron_3" to Triple(
            ToneGenerator.TONE_PROP_ACK,
            ToneGenerator.TONE_SUP_INTERCEPT,
            ToneGenerator.TONE_CDMA_ABBR_ALERT,
        ),
    )

    private fun play(kind: String, pattern: String): Map<String, Any?> {
        val audio = getSystemService(AUDIO_SERVICE) as AudioManager
        if (audio.getStreamVolume(AudioManager.STREAM_MUSIC) == 0) {
            return mapOf("played" to false, "cause" to "El volumen multimedia está en cero.")
        }
        val tones = patterns[pattern]
            ?: return mapOf("played" to false, "cause" to "Patrón de sonido desconocido.")
        val (tone, millis) = when (kind) {
            "closure" -> tones.third to 1200
            "warning" -> tones.second to 700
            else -> tones.first to 600
        }
        return try {
            val generator = ToneGenerator(AudioManager.STREAM_MUSIC, 100)
            val started = generator.startTone(tone, millis)
            if (started) {
                handler.postDelayed({ generator.release() }, millis + 200L)
                mapOf("played" to true)
            } else {
                generator.release()
                mapOf("played" to false, "cause" to "Android no inició la reproducción.")
            }
        } catch (e: RuntimeException) {
            mapOf("played" to false, "cause" to "No se pudo reproducir el sonido.")
        }
    }
}
