package com.juanrueda.monitoring_engine.monitoring

/** Aviso sonoro local (en Android, `ToneGenerator`). */
internal interface AlertSink {
    /** Reproduce el tono de [kind]. Nulo si se inició; si no, el código del fallo. */
    fun play(kind: ToneKind): String?

    /** Detiene cualquier tono y libera el audio. */
    fun stop()
}

internal enum class ToneKind { TEST, PROLONGED_CLOSURE }

internal enum class SessionLifecycle { NONE, ACTIVE, PAUSED, FINALIZED }

/** Paso público de la calibración (incluye estados terminales). */
internal enum class CalibrationPhase {
    IDLE, OPEN_REFERENCE, CLOSE_LEAD_IN, CLOSED_PROBE, REOPEN, ACCEPTED, REJECTED, CANCELED,
}

/** Estado compacto que sale del coordinador: sin imágenes ni puntos faciales. */
internal data class MonitoringState(
    val engineInstanceId: String,
    val sequence: Long,
    val attachedToken: Long?,
    // Observación ocular más reciente.
    val eyesValid: Boolean,
    val eyeIssue: String?,
    val earRight: Double?,
    val earLeft: Double?,
    val ratioRight: Double?,
    val ratioLeft: Double?,
    val observationAgeMs: Long?,
    // Calibración.
    val calibrationPhase: CalibrationPhase,
    val calibrationAttempt: Long,
    val calibrationProbe: Int,
    val stepElapsedMs: Long?,
    val stepDurationMs: Long?,
    val stepValidSamples: Int?,
    val calibrationId: String?,
    val calibrationRejection: String?,
    val calibrationDetail: String?,
    val openEarRight: Double?,
    val openEarLeft: Double?,
    val calibrationSamples: Int?,
    val calibrationCoverage: Double?,
    // Prueba de sonido.
    val soundTestId: String?,
    val soundTestPlayed: Boolean,
    val soundHeard: Boolean,
    val soundFailure: String?,
    // Sesión.
    val lifecycle: SessionLifecycle,
    val resumePending: Boolean,
    val sessionId: String?,
    val measurement: Measurement,
    val signal: Signal,
    val measurementCause: String?,
    val activeMs: Long,
    val pausedMs: Long,
    val evaluableMs: Long,
    val closureActivations: Int,
    val tonesPlayed: Int,
    val tonesFailed: Int,
    val closedRunMs: Long?,
)

/** Resultado de una orden: aceptada o rechazada con un código técnico. */
internal data class CommandOutcome(val accepted: Boolean, val errorCode: String?, val state: MonitoringState)

/**
 * Coordinador del recorrido experimental (fase 5C, Área 04 §4 y §6).
 *
 * - **Una sola sesión** vigente (activa o en pausa). Las órdenes
 *   incompatibles se rechazan con un código; no crean transiciones.
 * - Las observaciones del análisis facial (hilo de análisis), las órdenes
 *   (hilo principal) y el vigilante comparten un único cerrojo: es el actor
 *   serial del coordinador.
 * - Solo se aceptan observaciones de la apertura de cámara vinculada
 *   ([attach]); al cerrarla ([detach]) no hay medición.
 * - **Iniciar** comprueba de nuevo, aquí: sin sesión vigente, referencia
 *   aceptada (la indicada), prueba de sonido correcta y confirmada (la
 *   indicada, sin consumir), cámara vinculada y última observación válida y
 *   vigente. Los datos de preparación no se reutilizan: la sesión empieza
 *   con Krecover.
 * - **Pausar** corta la medición y detiene el tono; la cámara la libera el
 *   propietario ([onRelease]). **Reanudar** deja la pausa abierta
 *   (`resumePending`) hasta cumplir Krecover con la cámara reabierta.
 * - **Finalizar** detiene la evaluación y el tono y libera la cámara; la
 *   sesión queda terminal con su resumen en memoria (sin persistencia).
 * - El aviso de cierre prolongado se decide y se reproduce aquí, sin pasar
 *   por Flutter.
 */
internal class MonitoringCoordinator(
    private val clockNs: () -> Long,
    private val newId: () -> String,
    private val alerts: AlertSink,
    private val publish: (MonitoringState) -> Unit,
    /** Libera la cámara de la apertura vinculada (pausa y fin). */
    private val onRelease: (token: Long) -> Unit = {},
) {
    private val lock = Any()
    private val engineInstanceId = newId()
    private var sequence = 0L

    private var token: Long? = null
    private var last: EyeObservation? = null

    private var calibrationAttempt = 0L
    private var calibration: CalibrationRun? = null
    private var calibrationPhase = CalibrationPhase.IDLE
    private var calibrationRejection: CalibrationRejection? = null
    private var calibrationDetail: String? = null
    private var reference: CalibrationReference? = null

    private var soundTestId: String? = null
    private var soundPlayed = false
    private var soundHeard = false
    private var soundFailure: String? = null

    private var lifecycle = SessionLifecycle.NONE
    private var sessionId: String? = null
    private var policy: SessionPolicy? = null
    private var resumePending = false
    private var startNs = 0L
    private var endNs: Long? = null
    private var pauseStartNs: Long? = null
    private var pausedNs = 0L
    private var usableSinceNs: Long? = null
    private var evaluableNs = 0L
    private var tonesPlayed = 0
    private var tonesFailed = 0

    private var lastPublishNs = Long.MIN_VALUE
    private var lastEyePublishNs = Long.MIN_VALUE

    // ------------------------------------------------------------ cámara

    /** La apertura [t] de la cámara está abierta y su análisis en marcha. */
    fun attach(t: Long) = synchronized(lock) {
        token = t
        last = null
        publishNow()
    }

    /** La apertura [t] se cerró: no hay observaciones. */
    fun detach(t: Long) = synchronized(lock) {
        if (token != t) return@synchronized
        token = null
        last = null
        val now = clockNs()
        calibration?.let { cancelCalibrationLocked(CalibrationPhase.REJECTED, CalibrationRejection.INSUFFICIENT_OBSERVATIONS, "cameraClosed") }
        policy?.let {
            it.cameraLost()
            settleEvaluable(now)
        }
        publishNow()
    }

    // ------------------------------------------------------ observaciones

    fun observe(o: EyeObservation) = synchronized(lock) {
        if (o.token != token) return@synchronized
        val now = clockNs()
        last = o
        var changed = false
        calibration?.let { run ->
            val before = run.step to run.probe
            run.onObservation(o)
            changed = advanceCalibration(now) || before != (run.step to run.probe)
        }
        val pol = policy
        if (pol != null && (lifecycle == SessionLifecycle.ACTIVE || resumePending)) {
            val before = Triple(pol.measurement, pol.signal, pol.activations)
            val dispatch = pol.onObservation(o, now)
            if (resumePending && pol.usable) confirmResume(now)
            settleEvaluable(now)
            if (dispatch) dispatchTone(ToneKind.PROLONGED_CLOSURE)
            changed = changed || dispatch || before != Triple(pol.measurement, pol.signal, pol.activations)
        }
        if (changed) publishNow() else publishEyeThrottled(now)
    }

    /** Vigilante periódico: calibración, recepción y latido. */
    fun tick() = synchronized(lock) {
        val now = clockNs()
        var changed = advanceCalibration(now)
        val pol = policy
        if (pol != null && (lifecycle == SessionLifecycle.ACTIVE || resumePending)) {
            val before = pol.measurement to pol.signal
            pol.tick(now)
            settleEvaluable(now)
            changed = changed || before != (pol.measurement to pol.signal)
        }
        when {
            changed || now - lastPublishNs >= HEARTBEAT_NS -> publishNow()
            // Progreso de la calibración, como mucho cada 200 ms.
            calibration != null -> publishEyeThrottled(now)
        }
    }

    // ------------------------------------------------------------ órdenes

    fun snapshot(): MonitoringState = synchronized(lock) { build(clockNs()) }

    fun beginCalibration(): CommandOutcome = synchronized(lock) {
        when {
            sessionVigente() -> reject("sessionActive")
            token == null -> reject("cameraNotReady")
            calibration != null -> reject("calibrationInProgress")
            else -> {
                calibrationAttempt++
                reference = null
                calibrationRejection = null
                calibrationDetail = null
                calibration = CalibrationRun(clockNs(), newId)
                calibrationPhase = CalibrationPhase.OPEN_REFERENCE
                accept()
            }
        }
    }

    fun cancelCalibration(): CommandOutcome = synchronized(lock) {
        if (calibration == null) return@synchronized reject("noCalibration")
        cancelCalibrationLocked(CalibrationPhase.CANCELED, null, null)
        accept()
    }

    fun testSound(): CommandOutcome = synchronized(lock) {
        if (sessionVigente()) return@synchronized reject("sessionActive")
        val failure = alerts.play(ToneKind.TEST)
        soundTestId = newId()
        soundPlayed = failure == null
        soundHeard = false
        soundFailure = failure
        if (failure == null) accept() else reject(failure)
    }

    fun confirmSoundHeard(id: String): CommandOutcome = synchronized(lock) {
        if (id != soundTestId || !soundPlayed) return@synchronized reject("soundTestNotPlayed")
        soundHeard = true
        accept()
    }

    fun startSession(calibrationId: String, soundId: String): CommandOutcome = synchronized(lock) {
        val ref = reference
        val o = last
        val now = clockNs()
        when {
            sessionVigente() -> reject("sessionActive")
            calibration != null -> reject("calibrationInProgress")
            ref == null || ref.calibrationId != calibrationId -> reject("calibrationNotApplicable")
            soundId != soundTestId || !soundPlayed || !soundHeard -> reject("soundNotConfirmed")
            token == null -> reject("cameraNotReady")
            o == null || !o.valid || now - o.receivedNs >= STALE_NS -> reject("eyesNotEvaluable")
            else -> {
                lifecycle = SessionLifecycle.ACTIVE
                sessionId = newId()
                policy = SessionPolicy(ref)
                resumePending = false
                startNs = now
                endNs = null
                pauseStartNs = null
                pausedNs = 0
                usableSinceNs = null
                evaluableNs = 0
                tonesPlayed = 0
                tonesFailed = 0
                // La confirmación sonora se consume con este inicio.
                soundHeard = false
                soundPlayed = false
                soundTestId = null
                accept()
            }
        }
    }

    fun pauseSession(id: String): CommandOutcome = synchronized(lock) {
        if (id != sessionId) return@synchronized reject("unknownSession")
        if (lifecycle != SessionLifecycle.ACTIVE) return@synchronized reject("sessionNotActive")
        val now = clockNs()
        lifecycle = SessionLifecycle.PAUSED
        pauseStartNs = now
        policy?.cameraLost()
        settleEvaluable(now)
        alerts.stop()
        token?.let(onRelease)
        accept()
    }

    fun resumeSession(id: String): CommandOutcome = synchronized(lock) {
        if (id != sessionId) return@synchronized reject("unknownSession")
        if (lifecycle != SessionLifecycle.PAUSED) return@synchronized reject("sessionNotPaused")
        if (resumePending) return@synchronized accept()
        resumePending = true
        // Segmento nuevo: nada anterior a la pausa se reutiliza.
        policy = SessionPolicy(reference!!).also { if (last == null) it.cameraLost() }
        accept()
    }

    fun stopSession(id: String): CommandOutcome = synchronized(lock) {
        if (id != sessionId) return@synchronized reject("unknownSession")
        if (!sessionVigente()) return@synchronized reject("sessionNotActive")
        val now = clockNs()
        settleEvaluable(now, ending = true)
        pauseStartNs?.let { pausedNs += now - it }
        pauseStartNs = null
        lifecycle = SessionLifecycle.FINALIZED
        resumePending = false
        endNs = now
        alerts.stop()
        token?.let(onRelease)
        accept()
    }

    /** El plugin se desconecta: termina sin sesión viva ni tono. */
    fun shutdown() = synchronized(lock) {
        calibration = null
        if (sessionVigente()) {
            val now = clockNs()
            settleEvaluable(now, ending = true)
            pauseStartNs?.let { pausedNs += now - it }
            pauseStartNs = null
            lifecycle = SessionLifecycle.FINALIZED
            resumePending = false
            endNs = now
        }
        alerts.stop()
    }

    // ----------------------------------------------------------- internos

    private fun sessionVigente() = lifecycle == SessionLifecycle.ACTIVE || lifecycle == SessionLifecycle.PAUSED

    private fun confirmResume(now: Long) {
        resumePending = false
        lifecycle = SessionLifecycle.ACTIVE
        pauseStartNs?.let { pausedNs += now - it }
        pauseStartNs = null
    }

    /** Cuenta el tiempo evaluable (usable con sesión activa) hasta [now]. */
    private fun settleEvaluable(now: Long, ending: Boolean = false) {
        val usable = !ending && lifecycle == SessionLifecycle.ACTIVE && policy?.usable == true
        val since = usableSinceNs
        if (since != null) {
            evaluableNs += now - since
            usableSinceNs = if (usable) now else null
        } else if (usable) {
            usableSinceNs = now
        }
    }

    private fun advanceCalibration(now: Long): Boolean {
        val run = calibration ?: return false
        val before = run.step to run.probe
        when (val out = run.tick(now)) {
            null -> Unit
            is CalibrationOutcome.Accepted -> {
                calibration = null
                reference = out.reference
                calibrationPhase = CalibrationPhase.ACCEPTED
                return true
            }
            is CalibrationOutcome.Rejected -> {
                cancelCalibrationLocked(CalibrationPhase.REJECTED, out.reason, out.detail)
                return true
            }
        }
        calibrationPhase = phaseOf(run.step)
        val changed = before != (run.step to run.probe)
        // Con los ojos cerrados no se lee la pantalla: un pitido de guía pide
        // abrirlos. Es una indicación, no un aviso; su resultado no se cuenta.
        if (changed && run.step == CalibrationStep.REOPEN) alerts.play(ToneKind.TEST)
        return changed
    }

    private fun cancelCalibrationLocked(phase: CalibrationPhase, why: CalibrationRejection?, detail: String?) {
        calibration = null
        reference = null
        calibrationPhase = phase
        calibrationRejection = why
        calibrationDetail = detail
    }

    private fun dispatchTone(kind: ToneKind) {
        // Un fallo también consume el intento (Área 05 §13).
        if (alerts.play(kind) == null) tonesPlayed++ else tonesFailed++
    }

    private fun accept() = CommandOutcome(true, null, publishNow())

    private fun reject(code: String) = CommandOutcome(false, code, publishNow())

    private fun publishEyeThrottled(now: Long) {
        if (now - lastEyePublishNs >= EYE_PUBLISH_NS) publishNow()
    }

    private fun publishNow(): MonitoringState {
        val now = clockNs()
        lastPublishNs = now
        lastEyePublishNs = now
        val s = build(now)
        publish(s)
        return s
    }

    private fun build(now: Long): MonitoringState {
        val o = last
        val ref = reference
        val run = calibration
        val pol = policy
        val vigente = o != null && now - o.receivedNs < STALE_NS
        val evaluable = evaluableNs + (usableSinceNs?.let { now - it } ?: 0)
        val end = endNs ?: now
        val paused = pausedNs + (pauseStartNs?.let { now - it } ?: 0)
        val sessionShown = lifecycle != SessionLifecycle.NONE
        return MonitoringState(
            engineInstanceId = engineInstanceId,
            sequence = ++sequence,
            attachedToken = token,
            eyesValid = vigente && o!!.valid,
            eyeIssue = when {
                o == null -> if (token == null) "cameraClosed" else "noResults"
                !vigente -> QReason.STALE_RESULT.code
                else -> o.reasons.firstOrNull()?.code
            },
            earRight = if (vigente) o!!.earRight else null,
            earLeft = if (vigente) o!!.earLeft else null,
            ratioRight = if (vigente && ref != null) o!!.earRight?.div(ref.openEarRight) else null,
            ratioLeft = if (vigente && ref != null) o!!.earLeft?.div(ref.openEarLeft) else null,
            observationAgeMs = o?.let { (now - it.tNs) / 1_000_000 },
            calibrationPhase = calibrationPhase,
            calibrationAttempt = calibrationAttempt,
            calibrationProbe = run?.probe ?: 0,
            stepElapsedMs = run?.let { (now - it.stepStartNs) / 1_000_000 },
            stepDurationMs = run?.stepDurationMs,
            stepValidSamples = run?.validSamples,
            calibrationId = ref?.calibrationId,
            calibrationRejection = calibrationRejection?.code,
            calibrationDetail = calibrationDetail,
            openEarRight = ref?.openEarRight,
            openEarLeft = ref?.openEarLeft,
            calibrationSamples = ref?.openSamples,
            calibrationCoverage = ref?.openCoverage,
            soundTestId = soundTestId,
            soundTestPlayed = soundPlayed,
            soundHeard = soundHeard,
            soundFailure = soundFailure,
            lifecycle = lifecycle,
            resumePending = resumePending,
            sessionId = sessionId,
            measurement = pol?.measurement ?: Measurement.UNAVAILABLE,
            signal = if (lifecycle == SessionLifecycle.ACTIVE) pol?.signal ?: Signal.NOT_EVALUABLE else Signal.NOT_EVALUABLE,
            measurementCause = pol?.cause,
            activeMs = if (sessionShown) (end - startNs - paused) / 1_000_000 else 0,
            pausedMs = if (sessionShown) paused / 1_000_000 else 0,
            evaluableMs = if (sessionShown) evaluable / 1_000_000 else 0,
            closureActivations = pol?.activations ?: 0,
            tonesPlayed = tonesPlayed,
            tonesFailed = tonesFailed,
            closedRunMs = if (lifecycle == SessionLifecycle.ACTIVE) pol?.closedRunMs else null,
        )
    }

    companion object {
        const val HEARTBEAT_NS = 1_000_000_000L
        const val EYE_PUBLISH_NS = 200_000_000L
        const val STALE_NS = ExperimentalProfile.T_STALE_MS * 1_000_000
        const val TICK_MS = 50L

        private fun phaseOf(s: CalibrationStep) = when (s) {
            CalibrationStep.OPEN_REFERENCE -> CalibrationPhase.OPEN_REFERENCE
            CalibrationStep.CLOSE_LEAD_IN -> CalibrationPhase.CLOSE_LEAD_IN
            CalibrationStep.CLOSED_PROBE -> CalibrationPhase.CLOSED_PROBE
            CalibrationStep.REOPEN -> CalibrationPhase.REOPEN
        }
    }
}
