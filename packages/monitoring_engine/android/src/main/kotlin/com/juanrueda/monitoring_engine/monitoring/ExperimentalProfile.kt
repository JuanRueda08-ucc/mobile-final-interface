package com.juanrueda.monitoring_engine.monitoring

/**
 * Configuración de laboratorio del recorrido experimental (fase 5C).
 *
 * Valores **candidatos** del perfil `lab-eye-rules-0.1` del Área 05 §7, con
 * `qualificationStatus=experimental`. No son una política aceptada de
 * producción ni valores fisiológicos validados: sirven para ejercer el
 * recorrido real en pruebas. Cambiarlos exige repetir las pruebas.
 *
 * Los parámetros marcados **«prototipo»** no están en el Área 05: los añade
 * esta implementación para guiar la calibración y quedan pendientes de
 * definición (ver `docs/fase5c-monitoreo-experimental.md`).
 */
internal object ExperimentalProfile {
    const val PROFILE_ID = "lab-eye-rules-0.1"
    const val QUALIFICATION_STATUS = "experimental"
    const val LANDMARK_SCHEMA = "mp-eye6-v1"

    // Q (Área 05 §6–7). Luz, nitidez y postura **no se implementan** aún.
    const val MIN_EYE_WIDTH_PX = 24.0
    const val MAX_WIDTH_RATIO = 1.8

    // Kcal (Área 05 §8).
    const val OPEN_DURATION_MS = 8_000L
    const val MIN_OPEN_SAMPLES = 60
    const val MIN_COVERAGE = 0.80
    const val MAX_RELATIVE_MAD = 0.15
    const val OPEN_EAR_MIN = 0.10
    const val OPEN_EAR_MAX = 0.60
    const val CLOSED_PROBE_COUNT = 2
    const val CLOSED_PROBE_DURATION_MS = 1_000L
    const val REOPEN_DURATION_MS = 2_000L
    const val MIN_PROBE_SAMPLES = 6
    const val MIN_PROBE_COVERAGE = 0.80
    const val MAX_CLOSED_PROBE_RATIO = 0.50

    /** Prototipo: tiempo para reaccionar a «Cierra los ojos» antes de medir. */
    const val PROBE_LEAD_IN_MS = 1_500L

    /** Prototipo: espera máxima de la reapertura comprobada de 2000 ms. */
    const val REOPEN_TIMEOUT_MS = 6_000L

    // C, reapertura, Tclose, continuidad y vigencia (Área 05 §5, §9, §11).
    const val THETA_CLOSED = 0.55
    const val THETA_OPEN = 0.75
    const val T_CLOSE_MS = 1_500L
    const val G_MAX_MS = 150L
    const val T_STALE_MS = 750L

    // Krecover (Área 05 §10).
    const val RECOVER_MIN_DURATION_MS = 1_000L
    const val RECOVER_MIN_SAMPLES = 6

    // Rrepeat del cierre prolongado (Área 05 §13).
    const val REPEAT_PROLONGED_MS = 5_000L

    init {
        // Invariantes del Área 05 §7.
        check(G_MAX_MS < T_STALE_MS)
        check(THETA_CLOSED < THETA_OPEN)
    }
}
