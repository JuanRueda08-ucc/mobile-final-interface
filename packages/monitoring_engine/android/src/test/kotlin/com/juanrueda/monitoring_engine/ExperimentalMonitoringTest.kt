package com.juanrueda.monitoring_engine

import com.juanrueda.monitoring_engine.monitoring.AlertSink
import com.juanrueda.monitoring_engine.monitoring.CalibrationOutcome
import com.juanrueda.monitoring_engine.monitoring.CalibrationPhase
import com.juanrueda.monitoring_engine.monitoring.CalibrationReference
import com.juanrueda.monitoring_engine.monitoring.CalibrationRejection
import com.juanrueda.monitoring_engine.monitoring.CalibrationRun
import com.juanrueda.monitoring_engine.monitoring.CalibrationStep
import com.juanrueda.monitoring_engine.monitoring.EyeGeometry
import com.juanrueda.monitoring_engine.monitoring.EyeMeasurement
import com.juanrueda.monitoring_engine.monitoring.EyeObservation
import com.juanrueda.monitoring_engine.monitoring.Measurement
import com.juanrueda.monitoring_engine.monitoring.MonitoringCoordinator
import com.juanrueda.monitoring_engine.monitoring.MonitoringState
import com.juanrueda.monitoring_engine.monitoring.QReason
import com.juanrueda.monitoring_engine.monitoring.SessionLifecycle
import com.juanrueda.monitoring_engine.monitoring.SessionPolicy
import com.juanrueda.monitoring_engine.monitoring.Signal
import com.juanrueda.monitoring_engine.monitoring.ToneKind
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertIs
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

/*
 * Fase 5C · lógica del recorrido experimental con **secuencias controladas**
 * (observaciones sintéticas, reloj manual y tono falso). No ejecutan
 * MediaPipe ni la cámara y no acreditan detección con imágenes reales: eso
 * lo prueba `FaceLandmarkerInstrumentedTest` (EAR sobre una foto real) y el
 * recorrido en Android. Desde android/:
 *   ./gradlew :monitoring_engine:testDebugUnitTest
 */
internal class ExperimentalMonitoringTest {
    // ------------------------------------------------------------ ayudas

    private fun ms(v: Long) = v * 1_000_000

    private val open = 0.30
    private val closed = 0.10

    private fun eyes(r: Double, l: Double = r) = EyeMeasurement(r, l, 40.0, 40.0, emptySet())

    private fun obs(tMs: Long, r: Double = open, l: Double = r, token: Long = 1, receivedMs: Long = tMs) =
        EyeObservation.of(token, ms(tMs), ms(receivedMs), 1, eyes(r, l))

    private fun noFace(tMs: Long, token: Long = 1) = EyeObservation.of(token, ms(tMs), ms(tMs), 0, null)

    private fun twoFaces(tMs: Long) = EyeObservation.of(1, ms(tMs), ms(tMs), 2, null)

    private fun lowRes(tMs: Long) = EyeObservation.of(
        1, ms(tMs), ms(tMs), 1,
        EyeMeasurement(open, open, 10.0, 10.0, setOf(QReason.INSUFFICIENT_EYE_RESOLUTION)),
    )

    private val reference = CalibrationReference("cal-1", open, open, 160, 1.0, 0.0, 0.0, emptyList())

    // -------------------------------------------------------- geometría

    /** Puntos de los dos ojos (resto en el centro) en una imagen [w]×[h]. */
    private fun points(
        w: Int,
        h: Int,
        vertical: Double,
        horizontal: Double = 40.0,
        cxR: Double = 200.0,
        cxL: Double = 300.0,
        cy: Double = 240.0,
        leftHorizontal: Double = horizontal,
    ): FloatArray {
        val a = FloatArray(478 * 2) { if (it % 2 == 0) 0.5f else 0.5f }
        fun put(i: Int, x: Double, y: Double) {
            a[2 * i] = (x / w).toFloat()
            a[2 * i + 1] = (y / h).toFloat()
        }
        fun eye(idx: IntArray, cx: Double, hor: Double) {
            put(idx[0], cx - hor / 2, cy)
            put(idx[3], cx + hor / 2, cy)
            put(idx[1], cx - hor / 6, cy - vertical / 2)
            put(idx[5], cx - hor / 6, cy + vertical / 2)
            put(idx[2], cx + hor / 6, cy - vertical / 2)
            put(idx[4], cx + hor / 6, cy + vertical / 2)
        }
        eye(EyeGeometry.RIGHT, cxR, horizontal)
        eye(EyeGeometry.LEFT, cxL, leftHorizontal)
        return a
    }

    @Test
    fun ear_formulaInPixels_examplesOfArea05() {
        // Verticales 6 y 6 px, horizontal 20 px → 0,30; verticales 1 y 1 → 0,05.
        val m = EyeGeometry.measure(points(640, 480, 6.0, 20.0), 640, 480, minEyeWidthPx = 10.0)
        assertEquals(0.30, m.earRight!!, 1e-6)
        assertEquals(0.30, m.earLeft!!, 1e-6)
        val c = EyeGeometry.measure(points(640, 480, 1.0, 20.0), 640, 480, minEyeWidthPx = 10.0)
        assertEquals(0.05, c.earRight!!, 1e-6)
        assertTrue(c.valid, "un ojo casi cerrado sigue siendo una observación válida")
    }

    @Test
    fun ear_usesPixelsNotNormalizedCoordinates() {
        // Con ancho ≠ alto, calcular con x/y normalizados daría otro valor.
        val pts = points(640, 480, 12.0, 40.0)
        val m = EyeGeometry.measure(pts, 640, 480)
        assertEquals(0.30, m.earRight!!, 1e-6)
        val i = EyeGeometry.RIGHT
        val normEar = (kotlin.math.abs(pts[2 * i[1] + 1] - pts[2 * i[5] + 1]) * 2) /
            (2 * kotlin.math.abs(pts[2 * i[3]] - pts[2 * i[0]]))
        assertTrue(kotlin.math.abs(normEar - 0.30) > 0.05)
    }

    @Test
    fun q_rejectsMissingNonFiniteOutsideLowResolutionAndPerspective() {
        assertEquals(
            setOf(QReason.INVALID_GEOMETRY),
            EyeGeometry.measure(FloatArray(100), 640, 480).reasons,
        )
        val nan = points(640, 480, 12.0).also { it[2 * 33] = Float.NaN }
        assertEquals(setOf(QReason.INVALID_GEOMETRY), EyeGeometry.measure(nan, 640, 480).reasons)
        val outside = points(640, 480, 12.0, cxR = 10.0)
        assertTrue(QReason.EYE_OUTSIDE_FRAME in EyeGeometry.measure(outside, 640, 480).reasons)
        val small = points(640, 480, 6.0, horizontal = 23.0)
        assertTrue(QReason.INSUFFICIENT_EYE_RESOLUTION in EyeGeometry.measure(small, 640, 480).reasons)
        val atLimit = points(640, 480, 6.0, horizontal = 24.0)
        assertTrue(EyeGeometry.measure(atLimit, 640, 480).valid, "24 px es inclusivo")
        val skew = points(640, 480, 6.0, horizontal = 30.0, leftHorizontal = 55.0)
        assertTrue(QReason.EXCESSIVE_PERSPECTIVE in EyeGeometry.measure(skew, 640, 480).reasons)
        val ratio18 = points(640, 480, 6.0, horizontal = 30.0, leftHorizontal = 53.0)
        assertFalse(QReason.EXCESSIVE_PERSPECTIVE in EyeGeometry.measure(ratio18, 640, 480).reasons)
    }

    @Test
    fun observation_faceCountDecidesBeforeEyes() {
        assertEquals(setOf(QReason.NO_FACE), noFace(0).reasons)
        assertEquals(setOf(QReason.AMBIGUOUS_FACE), twoFaces(0).reasons)
        assertFalse(twoFaces(0).valid)
        assertTrue(obs(0).valid)
    }

    // ------------------------------------------------------- calibración

    private var ids = 0
    private fun newId() = "id-${++ids}"

    /** Ejecuta la calibración con [ear] por instante y observaciones cada [stepMs]. */
    private fun calibrate(
        stepMs: Long = 50,
        maxMs: Long = 40_000,
        ear: (Long, CalibrationRun) -> EyeObservation?,
    ): CalibrationOutcome {
        val run = CalibrationRun(0, ::newId)
        var t = 0L
        while (t <= maxMs) {
            ear(t, run)?.let(run::onObservation)
            run.tick(ms(t))?.let { return it }
            t += stepMs
        }
        error("sin resultado")
    }

    /** Persona que sigue las indicaciones: ojos abiertos salvo durante la medición del cierre. */
    private fun cooperative(t: Long, run: CalibrationRun): EyeObservation =
        if (run.step == CalibrationStep.CLOSED_PROBE) obs(t, closed) else obs(t, open + (t % 3) * 0.002)

    @Test
    fun calibration_acceptsCooperativeSequence() {
        val out = assertIs<CalibrationOutcome.Accepted>(calibrate(ear = ::cooperative))
        val ref = out.reference
        assertTrue(ref.openEarRight in 0.30..0.305)
        assertTrue(ref.openSamples >= 60)
        assertTrue(ref.openCoverage >= 0.80)
        assertEquals(2, ref.probeRatios.size)
        ref.probeRatios.forEach { (r, l) -> assertTrue(r <= 0.5 && l <= 0.5) }
    }

    @Test
    fun calibration_gapsAboveGmaxGiveNoCoverage() {
        // Observaciones cada 200 ms (> Gmax=150): ningún span cuenta.
        val out = assertIs<CalibrationOutcome.Rejected>(calibrate(stepMs = 200, ear = ::cooperative))
        assertEquals(CalibrationRejection.INSUFFICIENT_OBSERVATIONS, out.reason)
    }

    @Test
    fun calibration_rejectsNoFaceAndMultipleFaces() {
        val none = assertIs<CalibrationOutcome.Rejected>(calibrate { t, _ -> noFace(t) })
        assertEquals(CalibrationRejection.INSUFFICIENT_OBSERVATIONS, none.reason)
        val two = assertIs<CalibrationOutcome.Rejected>(calibrate { t, _ -> twoFaces(t) })
        assertEquals(CalibrationRejection.INSUFFICIENT_OBSERVATIONS, two.reason)
    }

    @Test
    fun calibration_eyeFailureIsInvalidEyeQuality() {
        val out = assertIs<CalibrationOutcome.Rejected>(calibrate { t, _ -> lowRes(t) })
        assertEquals(CalibrationRejection.INVALID_EYE_QUALITY, out.reason)
    }

    @Test
    fun calibration_staleOrMissingResultsAreNotAccepted() {
        // Datos caducados (descartados por el núcleo): solo observaciones inválidas.
        val stale = assertIs<CalibrationOutcome.Rejected>(
            calibrate { t, _ -> EyeObservation.invalid(1, ms(t), ms(t + 800), QReason.STALE_RESULT) },
        )
        assertEquals(CalibrationRejection.INSUFFICIENT_OBSERVATIONS, stale.reason)
        val silent = assertIs<CalibrationOutcome.Rejected>(calibrate { _, _ -> null })
        assertEquals(CalibrationRejection.INSUFFICIENT_OBSERVATIONS, silent.reason)
    }

    @Test
    fun calibration_unstableWhenOutOfRangeDispersedNotClosedOrNotReopened() {
        val high = assertIs<CalibrationOutcome.Rejected>(calibrate { t, _ -> obs(t, 0.65) })
        assertEquals(CalibrationRejection.UNSTABLE_REFERENCE, high.reason)
        val noisy = assertIs<CalibrationOutcome.Rejected>(
            calibrate { t, _ -> obs(t, if ((t / 50) % 2 == 0L) 0.20 else 0.40) },
        )
        assertEquals(CalibrationRejection.UNSTABLE_REFERENCE, noisy.reason)
        val neverClosed = assertIs<CalibrationOutcome.Rejected>(calibrate { t, _ -> obs(t, open) })
        assertEquals(CalibrationRejection.UNSTABLE_REFERENCE, neverClosed.reason)
        assertTrue(neverClosed.detail.startsWith("probe1NotClosed"))
        // Cierra cuando se pide pero no vuelve a abrir.
        var closedOnce = false
        val noReopen = assertIs<CalibrationOutcome.Rejected>(
            calibrate { t, run ->
                if (run.step == CalibrationStep.CLOSED_PROBE) closedOnce = true
                obs(t, if (closedOnce) closed else open)
            },
        )
        assertEquals(CalibrationRejection.UNSTABLE_REFERENCE, noReopen.reason)
        assertTrue(noReopen.detail.startsWith("reopenNotConfirmed"))
    }

    @Test
    fun calibration_formulas() {
        // h = (4−1)·0,8 = 2,4 → 0,3 + 0,4·(0,4 − 0,3)
        assertEquals(0.34, CalibrationRun.percentile80(listOf(0.4, 0.1, 0.3, 0.2)), 1e-9)
        assertEquals(0.0, CalibrationRun.relativeMad(listOf(0.3, 0.3, 0.3))!!, 1e-12)
        assertNull(CalibrationRun.relativeMad(listOf(0.0, 0.0, 0.0)))
    }

    // ------------------------------------------------------------ sesión

    /** Krecover con observaciones abiertas cada 100 ms desde [fromMs] hasta [toMs] inclusive. */
    private fun SessionPolicy.feedOpen(fromMs: Long, toMs: Long, stepMs: Long = 100) {
        var t = fromMs
        while (t <= toMs) {
            onObservation(obs(t), ms(t))
            t += stepMs
        }
    }

    @Test
    fun krecover_needsSixSamplesAndOneSecond() {
        val p = SessionPolicy(reference)
        p.feedOpen(0, 900)
        assertEquals(Measurement.INITIALIZING, p.measurement)
        assertEquals(Signal.NOT_EVALUABLE, p.signal)
        p.onObservation(obs(1000), ms(1000))
        assertEquals(Measurement.USABLE, p.measurement)
        assertEquals(Signal.NO_PERSISTENT_SIGNALS, p.signal)
    }

    @Test
    fun tclose_fixtureOfArea05_1400NoH_1500H() {
        val p = SessionPolicy(reference)
        p.feedOpen(0, 1000)
        var dispatches = 0
        for (t in 1100L..2500L step 100) if (p.onObservation(obs(t, closed), ms(t))) dispatches++
        // Cerrado desde 1100: a 2500 (1400 ms) todavía no.
        assertEquals(Signal.NO_PERSISTENT_SIGNALS, p.signal)
        assertEquals(0, dispatches)
        assertTrue(p.onObservation(obs(2600, closed), ms(2600)), "1500 ms: aviso")
        assertEquals(Signal.PROLONGED_EYE_CLOSURE, p.signal)
        assertEquals(1, p.activations)
        // Sigue cerrado: no repite por cada resultado.
        assertFalse(p.onObservation(obs(2700, closed), ms(2700)))
        // Reabre: H cae.
        p.onObservation(obs(2800, open), ms(2800))
        assertEquals(Signal.NO_PERSISTENT_SIGNALS, p.signal)
    }

    @Test
    fun equalityWithThetaClosedCounts_unilateralDoesNot() {
        val p = SessionPolicy(reference)
        p.feedOpen(0, 1000)
        val atTheta = open * 0.55
        for (t in 1100L..2600L step 100) p.onObservation(obs(t, atTheta), ms(t))
        assertEquals(Signal.PROLONGED_EYE_CLOSURE, p.signal)
        val q = SessionPolicy(reference)
        q.feedOpen(0, 1000)
        for (t in 1100L..4000L step 100) q.onObservation(obs(t, closed, open), ms(t))
        assertEquals(Signal.NO_PERSISTENT_SIGNALS, q.signal, "un guiño no activa RF12")
    }

    @Test
    fun invalidSampleBreaksTheRun_andRequiresKrecover() {
        val p = SessionPolicy(reference)
        p.feedOpen(0, 1000)
        for (t in 1100L..1800L step 100) p.onObservation(obs(t, closed), ms(t))
        p.onObservation(noFace(1900), ms(1900))
        assertEquals(Measurement.UNAVAILABLE, p.measurement)
        assertEquals(Signal.NOT_EVALUABLE, p.signal, "perder el rostro no es ojos cerrados")
        // Vuelve cerrado: primero Krecover (1000 ms), después el tramo empieza en cero.
        var dispatched = false
        for (t in 2000L..3400L step 100) dispatched = p.onObservation(obs(t, closed), ms(t)) || dispatched
        assertEquals(Measurement.USABLE, p.measurement)
        assertFalse(dispatched)
        assertEquals(Signal.NO_PERSISTENT_SIGNALS, p.signal)
        for (t in 3500L..4500L step 100) dispatched = p.onObservation(obs(t, closed), ms(t)) || dispatched
        assertTrue(dispatched, "1500 ms desde la habilitación (3000)")
    }

    @Test
    fun gapAboveGmaxCuts_noTimerExtendsClosure() {
        val p = SessionPolicy(reference)
        p.feedOpen(0, 1000)
        for (t in 1100L..2000L step 100) p.onObservation(obs(t, closed), ms(t))
        // 151 ms sin observación entre dos cerradas: corte.
        p.onObservation(obs(2151, closed), ms(2151))
        assertEquals(Measurement.LIMITED, p.measurement)
        assertEquals(Signal.NOT_EVALUABLE, p.signal)
        // Silencio: el vigilante no convierte la falta de datos en cierre.
        val q = SessionPolicy(reference)
        q.feedOpen(0, 1000)
        q.onObservation(obs(1100, closed), ms(1100))
        q.tick(ms(1250))
        assertEquals(Measurement.USABLE, q.measurement, "silencio = Gmax todavía no corta")
        q.tick(ms(1251))
        assertEquals(Measurement.LIMITED, q.measurement)
        q.tick(ms(1850))
        assertEquals(Measurement.UNAVAILABLE, q.measurement, "silencio ≥ Tstale")
        assertEquals(Signal.NOT_EVALUABLE, q.signal)
        assertEquals(0, q.activations)
    }

    @Test
    fun staleObservationIsNotEvaluable() {
        val p = SessionPolicy(reference)
        p.feedOpen(0, 1000)
        p.onObservation(EyeObservation.invalid(1, ms(1100), ms(1900), QReason.STALE_RESULT), ms(1900))
        assertEquals(Measurement.UNAVAILABLE, p.measurement)
        assertEquals("staleResult", p.cause)
    }

    @Test
    fun rrepeat_every5000msWhileHPersists() {
        val p = SessionPolicy(reference)
        p.feedOpen(0, 1000)
        val dispatchAt = mutableListOf<Long>()
        for (t in 1100L..13_000L step 100) if (p.onObservation(obs(t, closed), ms(t))) dispatchAt += t
        assertEquals(listOf(2600L, 7600L, 12_600L), dispatchAt)
        assertEquals(1, p.activations)
    }

    // ------------------------------------------------------- coordinador

    private class FakeTone : AlertSink {
        val played = mutableListOf<ToneKind>()
        var stops = 0
        var fail: String? = null
        override fun play(kind: ToneKind): String? {
            played += kind
            return fail
        }
        override fun stop() {
            stops++
        }
    }

    private class Rig {
        var nowMs = 0L
        val tone = FakeTone()
        val released = mutableListOf<Long>()
        val published = mutableListOf<MonitoringState>()
        private var n = 0
        val c = MonitoringCoordinator(
            clockNs = { nowMs * 1_000_000 },
            newId = { "id-${++n}" },
            alerts = tone,
            publish = { published += it },
            onRelease = { released += it },
        )
        val last get() = published.last()

        fun at(t: Long, o: EyeObservation? = null) {
            nowMs = t
            o?.let(c::observe)
            c.tick()
        }
    }

    private fun Rig.calibrated(token: Long = 1): Rig {
        c.attach(token)
        assertTrue(c.beginCalibration().accepted)
        var t = nowMs
        while (last.calibrationPhase != CalibrationPhase.ACCEPTED) {
            val o = if (last.calibrationPhase == CalibrationPhase.CLOSED_PROBE) {
                EyeObservation.of(token, ms(t), ms(t), 1, eyes(closed))
            } else {
                EyeObservation.of(token, ms(t), ms(t), 1, eyes(open))
            }
            at(t, o)
            assertTrue(last.calibrationPhase != CalibrationPhase.REJECTED, "${last.calibrationDetail}")
            t += 50
            check(t < 60_000)
        }
        return this
    }

    private fun Rig.soundConfirmed(): String {
        val r = c.testSound()
        assertTrue(r.accepted)
        val id = r.state.soundTestId!!
        assertTrue(c.confirmSoundHeard(id).accepted)
        return id
    }

    private fun Rig.feed(fromMs: Long, toMs: Long, ear: Double, token: Long = 1, stepMs: Long = 100) {
        var t = fromMs
        while (t <= toMs) {
            at(t, EyeObservation.of(token, ms(t), ms(t), 1, eyes(ear)))
            t += stepMs
        }
    }

    private fun Rig.started(): String {
        calibrated()
        val sound = soundConfirmed()
        feed(nowMs + 50, nowMs + 50, open)
        val r = c.startSession(last.calibrationId!!, sound)
        assertTrue(r.accepted, r.errorCode)
        return r.state.sessionId!!
    }

    @Test
    fun coordinator_fullExperimentalFlow_closureTriggersToneAndStopReleases() {
        val rig = Rig()
        val id = rig.started()
        val t0 = rig.nowMs
        rig.feed(t0 + 100, t0 + 1100, open)
        assertEquals(Measurement.USABLE, rig.last.measurement)
        rig.feed(t0 + 1200, t0 + 2700, closed)
        assertEquals(Signal.PROLONGED_EYE_CLOSURE, rig.last.signal)
        // Pitidos de guía de las dos reaperturas, prueba de sonido y un aviso.
        assertEquals(
            listOf(ToneKind.TEST, ToneKind.TEST, ToneKind.TEST, ToneKind.PROLONGED_CLOSURE),
            rig.tone.played,
        )
        assertEquals(1, rig.last.closureActivations)
        assertEquals(1, rig.last.tonesPlayed)
        val stop = rig.c.stopSession(id)
        assertTrue(stop.accepted)
        assertEquals(SessionLifecycle.FINALIZED, stop.state.lifecycle)
        assertEquals(listOf(1L), rig.released, "finalizar libera la cámara")
        assertTrue(rig.tone.stops >= 1, "finalizar detiene el audio")
        // Tras finalizar, más observaciones no producen avisos.
        rig.feed(rig.nowMs + 100, rig.nowMs + 3000, closed)
        assertEquals(1, rig.tone.played.count { it == ToneKind.PROLONGED_CLOSURE })
    }

    @Test
    fun coordinator_singleSession_andStartPreconditionsCheckedInKotlin() {
        val rig = Rig()
        rig.c.attach(1)
        assertEquals("calibrationNotApplicable", rig.c.startSession("x", "y").errorCode)
        rig.calibrated()
        val cal = rig.last.calibrationId!!
        assertEquals("soundNotConfirmed", rig.c.startSession(cal, "y").errorCode)
        val played = rig.c.testSound().state.soundTestId!!
        assertEquals("soundNotConfirmed", rig.c.startSession(cal, played).errorCode, "sin «Lo escuché»")
        rig.c.confirmSoundHeard(played)
        // Última observación sin rostro: no se inicia.
        rig.at(rig.nowMs + 50, noFace(rig.nowMs + 50))
        assertEquals("eyesNotEvaluable", rig.c.startSession(cal, played).errorCode)
        // Observación válida pero antigua (≥ Tstale): tampoco.
        rig.at(rig.nowMs + 50, obs(rig.nowMs + 50))
        rig.at(rig.nowMs + 800)
        assertEquals("eyesNotEvaluable", rig.c.startSession(cal, played).errorCode)
        rig.at(rig.nowMs + 50, obs(rig.nowMs + 50))
        val first = rig.c.startSession(cal, played)
        assertTrue(first.accepted)
        // Una sola sesión: un segundo inicio (también con otra prueba) se rechaza.
        assertEquals("sessionActive", rig.c.startSession(cal, played).errorCode)
        assertEquals("sessionActive", rig.c.beginCalibration().errorCode)
        assertEquals("sessionActive", rig.c.testSound().errorCode)
    }

    @Test
    fun coordinator_pauseCutsAndResumeWaitsForKrecover() {
        val rig = Rig()
        val id = rig.started()
        rig.feed(rig.nowMs + 100, rig.nowMs + 1100, open)
        rig.feed(rig.nowMs + 100, rig.nowMs + 900, closed)
        val p = rig.c.pauseSession(id)
        assertTrue(p.accepted)
        assertEquals(SessionLifecycle.PAUSED, p.state.lifecycle)
        assertEquals(Signal.NOT_EVALUABLE, p.state.signal)
        assertEquals(listOf(1L), rig.released)
        rig.c.detach(1)
        // En pausa no se evalúa ni suena nada aunque lleguen cierres.
        rig.c.attach(2)
        rig.feed(rig.nowMs + 100, rig.nowMs + 4000, closed, token = 2)
        assertEquals(0, rig.last.closureActivations)
        assertEquals(SessionLifecycle.PAUSED, rig.last.lifecycle)
        // Reanudar: la pausa sigue abierta hasta Krecover; el cierre previo no cuenta.
        assertTrue(rig.c.resumeSession(id).accepted)
        assertTrue(rig.last.resumePending)
        rig.feed(rig.nowMs + 100, rig.nowMs + 500, closed, token = 2)
        assertEquals(SessionLifecycle.PAUSED, rig.last.lifecycle)
        rig.feed(rig.nowMs + 100, rig.nowMs + 600, closed, token = 2)
        assertEquals(SessionLifecycle.ACTIVE, rig.last.lifecycle)
        assertFalse(rig.last.resumePending)
        assertEquals(0, rig.last.closureActivations, "el tramo empieza en cero al habilitar")
        assertTrue(rig.last.pausedMs > 0)
    }

    @Test
    fun coordinator_faceLossAndOtherTokenNeverCountAsClosure() {
        val rig = Rig()
        rig.started()
        rig.feed(rig.nowMs + 100, rig.nowMs + 1100, open)
        var t = rig.nowMs
        repeat(40) {
            t += 100
            rig.at(t, noFace(t))
        }
        assertEquals(Signal.NOT_EVALUABLE, rig.last.signal)
        assertEquals(Measurement.UNAVAILABLE, rig.last.measurement)
        // Una apertura no vinculada no aporta observaciones.
        repeat(40) {
            t += 100
            rig.at(t, EyeObservation.of(9, ms(t), ms(t), 1, eyes(closed)))
        }
        assertEquals(0, rig.last.closureActivations)
        assertTrue(rig.tone.played.none { it == ToneKind.PROLONGED_CLOSURE })
    }

    @Test
    fun coordinator_cameraClosedDuringCalibrationRejects_andCancelNeverAccepts() {
        val rig = Rig()
        rig.c.attach(1)
        rig.c.beginCalibration()
        rig.feed(0, 2000, open)
        rig.c.detach(1)
        assertEquals(CalibrationPhase.REJECTED, rig.last.calibrationPhase)
        assertEquals("cameraClosed", rig.last.calibrationDetail)
        rig.c.attach(2)
        rig.c.beginCalibration()
        rig.feed(rig.nowMs + 50, rig.nowMs + 3000, open, token = 2, stepMs = 50)
        assertTrue(rig.c.cancelCalibration().accepted)
        rig.feed(rig.nowMs + 50, rig.nowMs + 20_000, open, token = 2, stepMs = 50)
        assertEquals(CalibrationPhase.CANCELED, rig.last.calibrationPhase)
        assertNull(rig.last.calibrationId)
    }

    @Test
    fun coordinator_failedToneIsCountedNotHidden() {
        val rig = Rig()
        rig.started()
        rig.tone.fail = "alarmVolumeZero"
        rig.feed(rig.nowMs + 100, rig.nowMs + 1100, open)
        rig.feed(rig.nowMs + 100, rig.nowMs + 1600, closed)
        assertEquals(Signal.PROLONGED_EYE_CLOSURE, rig.last.signal)
        assertEquals(0, rig.last.tonesPlayed)
        assertEquals(1, rig.last.tonesFailed)
        assertNotNull(rig.last.sessionId)
    }

    @Test
    fun ocularAgeKeepsCountingFromFrameWhenReadingAndStarting() {
        val rig = Rig().calibrated()
        val sound = rig.soundConfirmed()
        val cal = rig.last.calibrationId!!
        val frame = rig.nowMs + 100
        rig.nowMs = frame + 650
        rig.c.observe(EyeObservation.of(1, ms(frame), ms(rig.nowMs), 1, eyes(open)))
        rig.nowMs = frame + 750
        assertTrue(rig.c.snapshot().eyesValid, "edad 750 inclusiva")
        rig.nowMs = frame + 751
        val stale = rig.c.snapshot()
        assertFalse(stale.eyesValid, "la recepción no rejuvenece el cuadro")
        assertNull(stale.earRight)
        assertEquals("staleResult", stale.eyeIssue)
        assertEquals("eyesNotEvaluable", rig.c.startSession(cal, sound).errorCode)
    }

    @Test
    fun snapshotRefreshesWatchdogBetweenTicks() {
        val rig = Rig()
        rig.started()
        rig.feed(rig.nowMs + 100, rig.nowMs + 1100, open)
        rig.feed(rig.nowMs + 100, rig.nowMs + 1600, closed)
        assertEquals(Signal.PROLONGED_EYE_CLOSURE, rig.last.signal)
        rig.nowMs += 150
        assertEquals(Signal.PROLONGED_EYE_CLOSURE, rig.c.snapshot().signal)
        rig.nowMs += 1
        val lost = rig.c.snapshot()
        assertEquals(Signal.NOT_EVALUABLE, lost.signal)
        assertEquals(Measurement.LIMITED, lost.measurement)
        rig.nowMs += 599
        assertEquals(Measurement.UNAVAILABLE, rig.c.snapshot().measurement)
    }

    @Test
    fun receivingAfterSilenceCannotBypassWatchdogWithoutATick() {
        val p = SessionPolicy(reference)
        p.feedOpen(0, 1000)
        p.onObservation(EyeObservation.of(1, ms(1100), ms(1200), 1, eyes(closed)), ms(1200))
        assertFalse(p.usable, "200 ms entre recepciones exige Krecover, aunque gap de cuadros=100")
        assertEquals(Signal.NOT_EVALUABLE, p.signal)
    }

    @Test
    fun coordinatorRechecksAgeAfterWaitingForItsLock() {
        val rig = Rig()
        rig.c.attach(1)
        rig.nowMs = 5000
        rig.c.observe(EyeObservation.of(1, ms(1000), ms(1100), 1, eyes(open)))
        assertFalse(rig.c.snapshot().eyesValid)
        val p = SessionPolicy(reference)
        p.feedOpen(0, 1000)
        p.onObservation(EyeObservation.of(1, ms(1100), ms(1150), 1, eyes(closed)), ms(2000))
        assertEquals(Measurement.UNAVAILABLE, p.measurement)
        assertEquals(Signal.NOT_EVALUABLE, p.signal)
    }

    @Test
    fun resumeKeepsSessionActivationAndToneTotals() {
        val rig = Rig()
        val id = rig.started()
        rig.feed(rig.nowMs + 100, rig.nowMs + 1100, open)
        rig.feed(rig.nowMs + 100, rig.nowMs + 1600, closed)
        assertEquals(1, rig.c.snapshot().closureActivations)
        rig.c.pauseSession(id)
        rig.c.detach(1)
        rig.c.resumeSession(id)
        assertEquals(1, rig.c.snapshot().closureActivations, "Krecover nuevo no borra el total de sesión")
        rig.c.attach(2)
        rig.feed(rig.nowMs + 100, rig.nowMs + 1100, open, token = 2)
        rig.feed(rig.nowMs + 100, rig.nowMs + 1600, closed, token = 2)
        val end = rig.c.stopSession(id).state
        assertEquals(2, end.closureActivations)
        assertEquals(2, end.tonesPlayed)
    }

    @Test
    fun exitAndCancellationStopPreparationAudio() {
        val rig = Rig()
        rig.c.attach(1)
        rig.c.testSound()
        val beforeExit = rig.tone.stops
        rig.c.detach(1)
        assertTrue(rig.tone.stops > beforeExit, "salir detiene el tono de prueba")
        rig.c.attach(2)
        rig.c.beginCalibration()
        val beforeCancel = rig.tone.stops
        rig.c.cancelCalibration()
        assertTrue(rig.tone.stops > beforeCancel, "cancelar detiene el pitido de guía")
    }
}
