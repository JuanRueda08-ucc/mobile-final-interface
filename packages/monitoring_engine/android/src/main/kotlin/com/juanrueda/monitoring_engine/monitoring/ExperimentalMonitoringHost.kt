package com.juanrueda.monitoring_engine.monitoring

import android.content.Context
import android.media.AudioManager
import android.media.ToneGenerator
import android.os.SystemClock
import android.util.Log
import com.juanrueda.monitoring_engine.CalibrationStep as PigeonStep
import com.juanrueda.monitoring_engine.EngineMeasurement
import com.juanrueda.monitoring_engine.EngineSessionLifecycle
import com.juanrueda.monitoring_engine.EngineSignal
import com.juanrueda.monitoring_engine.ExperimentalMonitoringHostApi
import com.juanrueda.monitoring_engine.MonitoringCommandResult
import com.juanrueda.monitoring_engine.MonitoringSnapshot
import java.util.UUID
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.TimeUnit

/**
 * Tono local con `ToneGenerator` en el flujo de alarma (fase 5C). No usa
 * micrófono, red ni archivos. Devuelve solo el resultado técnico: no afirma
 * que alguien lo oyera. Un volumen de alarma en cero se informa como fallo.
 */
internal class ToneAlertSink(private val context: Context) : AlertSink {
    private val lock = Any()
    private var generator: ToneGenerator? = null

    override fun play(kind: ToneKind): String? = synchronized(lock) {
        val audio = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        if (audio.getStreamVolume(AudioManager.STREAM_ALARM) == 0) return "alarmVolumeZero"
        releaseLocked()
        val (tone, millis) = when (kind) {
            ToneKind.TEST -> ToneGenerator.TONE_PROP_BEEP to 600
            ToneKind.PROLONGED_CLOSURE -> ToneGenerator.TONE_CDMA_HIGH_L to 1200
        }
        return try {
            val g = ToneGenerator(AudioManager.STREAM_ALARM, 100)
            generator = g
            if (g.startTone(tone, millis)) null else "toneNotStarted"
        } catch (e: RuntimeException) {
            "toneUnavailable"
        }
    }

    override fun stop() = synchronized(lock) { releaseLocked() }

    private fun releaseLocked() {
        val g = generator ?: return
        generator = null
        try {
            g.stopTone()
            g.release()
        } catch (e: RuntimeException) {
            // Ya liberado.
        }
    }
}

/**
 * Implementación de [ExperimentalMonitoringHostApi] y vigilante periódico
 * del coordinador (hilo `VigiaMonitoring`, cada 50 ms).
 */
internal class ExperimentalMonitoringHost(
    context: Context,
    publish: (MonitoringSnapshot) -> Unit,
    onRelease: (Long) -> Unit,
) : ExperimentalMonitoringHostApi {
    private val alerts = ToneAlertSink(context)
    val coordinator = MonitoringCoordinator(
        clockNs = SystemClock::elapsedRealtimeNanos,
        newId = { UUID.randomUUID().toString() },
        alerts = alerts,
        publish = {
            logTransition(it)
            publish(it.toPigeon())
        },
        onRelease = onRelease,
    )
    private val ticker: ScheduledExecutorService = Executors.newSingleThreadScheduledExecutor { r ->
        Thread(r, "VigiaMonitoring")
    }

    init {
        ticker.scheduleWithFixedDelay(
            {
                try {
                    coordinator.tick()
                } catch (t: Throwable) {
                    Log.w("VigiaMonitoring", "Vigilante: ${t.javaClass.simpleName}")
                }
            },
            MonitoringCoordinator.TICK_MS,
            MonitoringCoordinator.TICK_MS,
            TimeUnit.MILLISECONDS,
        )
    }

    @Volatile
    private var lastLogged: String? = null

    /**
     * Registro técnico de transiciones: solo códigos y contadores, nunca
     * imágenes, puntos faciales ni EAR por observación.
     */
    private fun logTransition(s: MonitoringState) {
        val key = "calibración=${s.calibrationPhase}/${s.calibrationProbe} rechazo=${s.calibrationRejection} " +
            "detalle=${s.calibrationDetail} sesión=${s.lifecycle} reanudando=${s.resumePending} " +
            "medición=${s.measurement} señal=${s.signal} causa=${s.measurementCause} " +
            "activaciones=${s.closureActivations} tonos=${s.tonesPlayed}/${s.tonesFailed} cámara=${s.attachedToken}"
        if (key == lastLogged) return
        lastLogged = key
        Log.i("VigiaMonitoring", key)
    }

    fun close() {
        coordinator.shutdown()
        ticker.shutdownNow()
    }

    override fun getMonitoringSnapshot() = coordinator.snapshot().toPigeon()
    override fun beginCalibration() = coordinator.beginCalibration().toPigeon()
    override fun cancelCalibration() = coordinator.cancelCalibration().toPigeon()
    override fun testSound() = coordinator.testSound().toPigeon()
    override fun confirmSoundHeard(soundTestId: String) = coordinator.confirmSoundHeard(soundTestId).toPigeon()
    override fun startSession(calibrationId: String, soundTestId: String) =
        coordinator.startSession(calibrationId, soundTestId).toPigeon()
    override fun pauseSession(sessionId: String) = coordinator.pauseSession(sessionId).toPigeon()
    override fun resumeSession(sessionId: String) = coordinator.resumeSession(sessionId).toPigeon()
    override fun stopSession(sessionId: String) = coordinator.stopSession(sessionId).toPigeon()
}

internal fun CommandOutcome.toPigeon() = MonitoringCommandResult(
    accepted = accepted,
    errorCode = errorCode,
    snapshot = state.toPigeon(),
)

internal fun MonitoringState.toPigeon() = MonitoringSnapshot(
    engineInstanceId = engineInstanceId,
    sequence = sequence,
    profileId = ExperimentalProfile.PROFILE_ID,
    qualificationStatus = ExperimentalProfile.QUALIFICATION_STATUS,
    attachedToken = attachedToken,
    eyesValid = eyesValid,
    eyeIssue = eyeIssue,
    earRight = earRight,
    earLeft = earLeft,
    ratioRight = ratioRight,
    ratioLeft = ratioLeft,
    observationAgeMs = observationAgeMs,
    calibrationStep = when (calibrationPhase) {
        CalibrationPhase.IDLE -> PigeonStep.IDLE
        CalibrationPhase.OPEN_REFERENCE -> PigeonStep.OPEN_REFERENCE
        CalibrationPhase.CLOSE_LEAD_IN -> PigeonStep.CLOSE_LEAD_IN
        CalibrationPhase.CLOSED_PROBE -> PigeonStep.CLOSED_PROBE
        CalibrationPhase.REOPEN -> PigeonStep.REOPEN
        CalibrationPhase.ACCEPTED -> PigeonStep.ACCEPTED
        CalibrationPhase.REJECTED -> PigeonStep.REJECTED
        CalibrationPhase.CANCELED -> PigeonStep.CANCELED
    },
    calibrationAttempt = calibrationAttempt,
    calibrationProbe = calibrationProbe.toLong(),
    stepElapsedMs = stepElapsedMs,
    stepDurationMs = stepDurationMs,
    stepValidSamples = stepValidSamples?.toLong(),
    calibrationId = calibrationId,
    calibrationRejection = calibrationRejection,
    calibrationDetail = calibrationDetail,
    openEarRight = openEarRight,
    openEarLeft = openEarLeft,
    calibrationSamples = calibrationSamples?.toLong(),
    calibrationCoverage = calibrationCoverage,
    soundTestId = soundTestId,
    soundTestPlayed = soundTestPlayed,
    soundHeard = soundHeard,
    soundFailure = soundFailure,
    lifecycle = when (lifecycle) {
        SessionLifecycle.NONE -> EngineSessionLifecycle.NONE
        SessionLifecycle.ACTIVE -> EngineSessionLifecycle.ACTIVE
        SessionLifecycle.PAUSED -> EngineSessionLifecycle.PAUSED
        SessionLifecycle.FINALIZED -> EngineSessionLifecycle.FINALIZED
    },
    resumePending = resumePending,
    sessionId = sessionId,
    measurement = when (measurement) {
        Measurement.INITIALIZING -> EngineMeasurement.INITIALIZING
        Measurement.USABLE -> EngineMeasurement.USABLE
        Measurement.LIMITED -> EngineMeasurement.LIMITED
        Measurement.UNAVAILABLE -> EngineMeasurement.UNAVAILABLE
    },
    signal = when (signal) {
        Signal.NOT_EVALUABLE -> EngineSignal.NOT_EVALUABLE
        Signal.NO_PERSISTENT_SIGNALS -> EngineSignal.NO_PERSISTENT_SIGNALS
        Signal.PROLONGED_EYE_CLOSURE -> EngineSignal.PROLONGED_EYE_CLOSURE
    },
    measurementCause = measurementCause,
    activeMs = activeMs,
    pausedMs = pausedMs,
    evaluableMs = evaluableMs,
    closureActivations = closureActivations.toLong(),
    tonesPlayed = tonesPlayed.toLong(),
    tonesFailed = tonesFailed.toLong(),
    closedRunMs = closedRunMs,
)
