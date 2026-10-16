package com.juanrueda.monitoring_engine.monitoring

import android.media.ToneGenerator

/**
 * Patrones de sonido incluidos (P13, RF29.CA3; fase 5E). Son los mismos
 * tonos de `ToneGenerator` que `MainActivity` usa para la prueba y el cierre
 * en la app DEMO; aquí solo hacen falta esos dos (la advertencia W no existe
 * en el motor experimental).
 *
 * Un identificador desconocido no se sustituye por otro: el coordinador lo
 * rechaza (`unknownSoundPattern`). [PATRON_1] conserva los tonos que el
 * motor usaba antes de 5E.
 */
internal enum class SoundPattern(val id: String, val testTone: Int, val closureTone: Int) {
    PATRON_1("patron_1", ToneGenerator.TONE_PROP_BEEP, ToneGenerator.TONE_CDMA_HIGH_L),
    PATRON_2("patron_2", ToneGenerator.TONE_CDMA_ALERT_CALL_GUARD, ToneGenerator.TONE_CDMA_EMERGENCY_RINGBACK),
    PATRON_3("patron_3", ToneGenerator.TONE_PROP_ACK, ToneGenerator.TONE_CDMA_ABBR_ALERT),
    ;

    fun tone(kind: ToneKind) = when (kind) {
        ToneKind.TEST -> testTone
        ToneKind.PROLONGED_CLOSURE -> closureTone
    }

    companion object {
        val DEFAULT = PATRON_1

        fun byId(id: String): SoundPattern? = entries.firstOrNull { it.id == id }
    }
}
