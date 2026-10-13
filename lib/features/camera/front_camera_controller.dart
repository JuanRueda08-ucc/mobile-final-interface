import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monitoring_engine/monitoring_engine.dart';

/// Fase de la comprobación de la cámara frontal (fase 5A, variante normal).
///
/// La presencia facial de la fase 5B va aparte ([FacePresencePhase]): solo
/// existe con la cámara en [CameraCheckPhase.available].
///
/// Separa permiso ausente, cámara inexistente, apertura en curso, vista
/// disponible y error de apertura. «Disponible» solo llega con la respuesta
/// del motor de que la cámara está abierta, nunca por tener el permiso.
enum CameraCheckPhase {
  /// Consultando el permiso.
  checking,

  /// Sin permiso y sin solicitud todavía: se explica antes de pedirlo (P02).
  explain,

  /// Solicitud de Android visible.
  requesting,

  /// Rechazado; se puede volver a solicitar (ER01).
  denied,

  /// Rechazado; Android ya no muestra la solicitud: abrir ajustes (UX02.CA2).
  requiresSettings,

  /// Abriendo la cámara frontal.
  opening,

  /// Cámara abierta con vista previa.
  available,

  /// El teléfono no tiene cámara frontal.
  noFrontCamera,

  /// Otra aplicación usa la cámara (ER02).
  inUse,

  /// Cámara desactivada por política del dispositivo.
  disabled,

  /// Fallo de apertura sin causa determinada (ER03), o el motor no respondió
  /// a una consulta, solicitud o apertura ([FrontCameraState.bridgeFailure]).
  failed,

  /// La app pasó a segundo plano: la cámara se liberó y se reabrirá al volver.
  suspended,

  /// Pantalla abandonada: la cámara se liberó.
  closed,
}

/// Presencia facial tal como la muestra la pantalla (fase 5B).
///
/// Solo [noFace], [oneFace] y [multipleFaces] proceden de un resultado
/// explícito y vigente del motor. La falta de resultados nunca se muestra
/// como ausencia de rostro: es [waitingResults].
enum FacePresencePhase {
  /// Sin cámara abierta: no hay análisis.
  stopped,

  /// Cámara abierta; el motor verifica y carga el modelo.
  loadingModel,

  /// Modelo listo, sin resultado vigente (aún no llegó, caducó, o Flutter
  /// dejó de recibir noticias del motor).
  waitingResults,
  noFace,
  oneFace,
  multipleFaces,

  /// Modelo ausente, alterado o incompatible: «Reintentar carga» (ER04).
  modelError,

  /// La inferencia falló: «Reintentar».
  analysisError,
}

@immutable
class FrontCameraState {
  const FrontCameraState({
    this.phase = CameraCheckPhase.closed,
    this.permission,
    this.preview,
    this.errorCode,
    this.bridgeFailure = false,
    this.face,
    this.faceSilent = false,
    this.faceStale = false,
  });

  final CameraCheckPhase phase;

  /// Último estado de permiso conocido; nulo antes de consultarlo.
  final CameraPermissionStatus? permission;

  /// Vista previa abierta; solo en [CameraCheckPhase.available].
  final PreviewOpenResult? preview;

  /// Código técnico del último fallo, para diagnóstico.
  final String? errorCode;

  /// `true` si el fallo fue del canal con el motor (excepción de la
  /// consulta, la solicitud o la apertura), no una respuesta de CameraX.
  final bool bridgeFailure;

  /// Último resultado compacto del análisis facial de la apertura vigente.
  final FaceAnalysisSnapshot? face;

  /// `true` si Flutter lleva [FrontCameraController.faceSilenceLimit] sin
  /// noticias del motor (ni avisos ni respuestas a consultas).
  final bool faceSilent;

  /// `true` si el resultado facial dejó de ser vigente en Flutter: su edad
  /// efectiva (edad en el motor + tiempo de la consulta + tiempo desde que
  /// llegó) alcanzó Tstale, o llegó ya caducado.
  final bool faceStale;

  bool get permissionGranted => permission == CameraPermissionStatus.granted;

  /// Presencia facial que se muestra. Fuera de [CameraCheckPhase.available]
  /// el análisis está detenido.
  FacePresencePhase get facePhase {
    if (phase != CameraCheckPhase.available) return FacePresencePhase.stopped;
    final f = face;
    if (f == null) {
      return faceSilent
          ? FacePresencePhase.waitingResults
          : FacePresencePhase.loadingModel;
    }
    final vigente = !faceSilent && !faceStale;
    return switch (f.status) {
      FaceAnalysisStatus.noFace when vigente => FacePresencePhase.noFace,
      FaceAnalysisStatus.oneFace when vigente => FacePresencePhase.oneFace,
      FaceAnalysisStatus.multipleFaces when vigente =>
        FacePresencePhase.multipleFaces,
      FaceAnalysisStatus.loadingModel => FacePresencePhase.loadingModel,
      FaceAnalysisStatus.modelError => FacePresencePhase.modelError,
      FaceAnalysisStatus.analysisError => FacePresencePhase.analysisError,
      FaceAnalysisStatus.stopped => FacePresencePhase.stopped,
      _ => FacePresencePhase.waitingResults,
    };
  }

  /// El último resultado caducó en el motor o Flutter dejó de recibirlo.
  bool get faceExpired =>
      facePhase == FacePresencePhase.waitingResults &&
      (faceSilent || faceStale || (face?.expired ?? false));

  FrontCameraState withFace(
    FaceAnalysisSnapshot? face, {
    bool silent = false,
    bool stale = false,
  }) => FrontCameraState(
    phase: phase,
    permission: permission,
    preview: preview,
    errorCode: errorCode,
    bridgeFailure: bridgeFailure,
    face: face,
    faceSilent: silent,
    faceStale: stale,
  );
}

/// Puente con el motor. Las pruebas lo sustituyen por un doble.
final frontCameraBridgeProvider = Provider<FrontCameraBridge>(
  (ref) => PigeonFrontCameraBridge(),
);

final frontCameraProvider =
    NotifierProvider<FrontCameraController, FrontCameraState>(
      FrontCameraController.new,
    );

/// Controlador de la comprobación de cámara. Pide acciones al motor y
/// representa su respuesta; no decide que la cámara funcione.
///
/// - Cada visita, paso a segundo plano o cierre incrementa una generación:
///   la respuesta de una operación de otra generación se descarta y, si abrió
///   la cámara, se cierra.
/// - Cada apertura lleva un token nuevo y único en el proceso; el motor
///   ignora el cierre de un token antiguo.
/// - Pulsaciones repetidas durante una solicitud o apertura no crean otra.
/// - Una excepción del puente termina la operación en un fallo recuperable;
///   la de una operación antigua no toca el estado vigente.
/// - Al desecharse, toda operación en curso queda invalidada: tras cada salto
///   asíncrono se comprueba la generación y `ref.mounted` antes de usar el
///   Ref o el estado.
/// - Fase 5B: solo se aceptan resultados faciales del token vigente, en
///   orden (`sequence` creciente, `generation` que no retrocede). Tras
///   `stopped`, ningún mensaje de esa apertura reactiva el análisis.
/// - **Un rostro solo se muestra a partir de una consulta**
///   ([FrontCameraBridge.queryFaceAnalysis]), cuya demora se mide en Dart:
///   edad efectiva = `resultAgeMs` (edad en el motor al crear la respuesta)
///   + tiempo completo de la consulta, medido con un cronómetro monotónico
///   iniciado antes de llamar. Sobreestima la edad; nunca la rejuvenece. No
///   se comparan relojes de Dart y Android.
/// - Si la edad efectiva supera [faceStaleAfter], el resultado no se muestra.
///   Si no, sigue vigente solo `faceStaleAfter − edad efectiva`. Un mensaje
///   con el mismo `resultId` nunca alarga ese plazo.
/// - Los avisos del motor ([FrontCameraBridge.faceAnalysis]) tienen una
///   demora sin cota: nunca muestran un rostro. Una detección avisada solo
///   dispara una consulta; los demás estados (cargando, esperando, errores,
///   detenido) sí se aceptan, porque no afirman la presencia de nadie.
///   Además, con la cámara abierta se consulta cada [facePollInterval].
/// - [faceSilenceLimit] es el límite de silencio del motor (sin avisos ni
///   respuestas), no un plazo de vigencia de un rostro.
class FrontCameraController extends Notifier<FrontCameraState> {
  static int _tokenSeq = 0;

  /// Silencio máximo del motor (sin avisos ni respuestas): 3000 ms,
  /// propuesta de transporte de Área 04 §9 (experimental).
  static const faceSilenceLimit = Duration(milliseconds: 3000);

  /// Tstale (Área 05 §7, experimental): edad efectiva máxima de un resultado
  /// facial para mostrarlo. Igual a 750 ms sigue vigente; más, no.
  static const faceStaleAfter = Duration(milliseconds: 750);

  /// Periodo de consulta con la cámara abierta (experimental). Menor que
  /// Tstale para que un rostro estable no se interrumpa entre inferencias.
  static const facePollInterval = Duration(milliseconds: 200);

  /// Último resultado facial aceptado del token vigente, aunque llegue durante
  /// la apertura (antes de que la cámara esté disponible).
  FaceAnalysisSnapshot? _face;
  bool _restartingFace = false;

  /// Orden de los mensajes de la apertura vigente (ver [_accept]).
  int _faceSequence = 0;
  int _faceGeneration = 0;

  /// La apertura vigente informó `stopped`: es definitivo.
  bool _faceStopped = false;

  /// Silencio del motor.
  Timer? _silenceTimer;
  bool _faceSilent = false;

  /// Vigencia del resultado facial mostrado: cuánto le quedaba al aceptarlo
  /// y un cronómetro monotónico (`clock.stopwatch`) desde entonces.
  int? _vigenteResultId;

  /// `resultId` crece dentro de la apertura: ningún resultado con un id menor
  /// o igual a este (caducado o sustituido por un estado sin rostro) vuelve
  /// a mostrarse.
  int _retiredUpTo = 0;
  Duration? _vigenteLeft;
  Stopwatch? _vigenteWatch;
  Timer? _vigenciaTimer;
  bool _faceStale = false;

  /// Consultas: una a la vez; otra pendiente si se pidió durante ella. Una
  /// consulta sin respuesta durante más de [faceStaleAfter] se abandona (su
  /// respuesta ya llegaría caducada) para no bloquear las siguientes.
  Timer? _pollTimer;
  int _queryId = 0;
  int? _inFlightQuery;
  Stopwatch? _inFlightWatch;
  bool _queryAgain = false;

  var _generation = 0;
  var _visible = false;
  int? _token;

  /// Última respuesta a una solicitud en esta visita: tras «Abrir ajustes» y
  /// volver sin permiso, el bloqueo sigue exigiendo los ajustes.
  CameraPermissionStatus? _lastRequest;

  late FrontCameraBridge _bridge;

  @override
  FrontCameraState build() {
    // Se guarda el puente: al desecharse el controlador se libera la cámara
    // sin volver a leer proveedores.
    _bridge = ref.read(frontCameraBridgeProvider);
    final sub = _bridge.closures.listen(_onClosed);
    final faces = _bridge.faceAnalysis.listen(_onFace);
    ref.onDispose(() {
      _visible = false;
      _generation++;
      sub.cancel();
      faces.cancel();
      _release();
    });
    return const FrontCameraState();
  }

  /// La pantalla se abre: consulta el permiso y, si está concedido, abre.
  Future<void> enter() async {
    _visible = true;
    _generation++;
    _lastRequest = null;
    await _refresh();
  }

  /// La pantalla se cierra: libera la cámara en el acto. El estado se
  /// actualiza justo después, porque puede llamarse desde `dispose` y Riverpod
  /// no admite cambios durante la construcción del árbol.
  void leave() {
    _visible = false;
    _generation++;
    _release();
    Future.microtask(() {
      if (!_visible && ref.mounted) {
        state = FrontCameraState(permission: state.permission);
      }
    });
  }

  /// La app deja de verse: libera la cámara sin abandonar la pantalla.
  void suspend() {
    if (!_visible) return;
    _generation++;
    _release();
    state = FrontCameraState(
      phase: CameraCheckPhase.suspended,
      permission: state.permission,
    );
  }

  /// La app vuelve a verse (también al volver de los ajustes del teléfono):
  /// consulta de nuevo el permiso, que pudo concederse o retirarse.
  Future<void> resume() async {
    if (!_visible) return;
    _generation++;
    await _refresh();
  }

  /// «Permitir cámara».
  Future<void> requestPermission() async {
    if (!_visible || _busy) return;
    final gen = _generation;
    state = FrontCameraState(
      phase: CameraCheckPhase.requesting,
      permission: state.permission,
    );
    final CameraPermissionStatus status;
    try {
      status = await _bridge.requestPermission();
    } catch (e) {
      if (_live(gen)) _fail(e);
      return;
    }
    if (!_live(gen)) return;
    _lastRequest = status;
    if (status == CameraPermissionStatus.granted) {
      state = FrontCameraState(
        phase: CameraCheckPhase.opening,
        permission: status,
      );
      await _open(gen);
    } else {
      state = FrontCameraState(
        phase: _blockedPhase(status),
        permission: status,
      );
    }
  }

  /// «Reintentar carga» o «Reintentar» del análisis facial tras un error. El
  /// motor ignora la petición si el token ya no es el vigente o si no hay
  /// error; un fallo del canal deja el estado como estaba, sin bloquear.
  Future<void> retryFaceAnalysis() async {
    final token = _token;
    if (!_visible || token == null || _restartingFace) return;
    final f = state.facePhase;
    if (f != FacePresencePhase.modelError &&
        f != FacePresencePhase.analysisError) {
      return;
    }
    _restartingFace = true;
    try {
      await _bridge.restartFaceAnalysis(token);
    } catch (e) {
      debugPrint('Vigía · reinicio del análisis $token no confirmado: $e');
    } finally {
      _restartingFace = false;
    }
  }

  /// «Abrir ajustes». Al volver, [resume] consulta el permiso.
  Future<bool> openSettings() => _bridge.openAppSettings();

  /// «Reintentar» tras un fallo de apertura.
  Future<void> retry() async {
    if (!_visible || _busy) return;
    _generation++;
    await _refresh();
  }

  bool get _busy => switch (state.phase) {
    CameraCheckPhase.checking ||
    CameraCheckPhase.requesting ||
    CameraCheckPhase.opening => true,
    _ => false,
  };

  Future<void> _refresh() async {
    final gen = _generation;
    _release();
    state = FrontCameraState(
      phase: CameraCheckPhase.checking,
      permission: state.permission,
    );
    final CameraPermissionStatus status;
    try {
      status = await _bridge.checkPermission();
    } catch (e) {
      if (_live(gen)) _fail(e);
      return;
    }
    if (!_live(gen)) return;
    if (status == CameraPermissionStatus.granted) {
      _lastRequest = status;
      state = FrontCameraState(
        phase: CameraCheckPhase.opening,
        permission: status,
      );
      await _open(gen);
      return;
    }
    // Sin permiso: si ya se rechazó en esta visita, se conserva ese bloqueo.
    final known = _lastRequest;
    state = FrontCameraState(
      phase: known == null || known == CameraPermissionStatus.granted
          ? CameraCheckPhase.explain
          : _blockedPhase(known),
      permission: known == CameraPermissionStatus.requiresSettings
          ? known
          : status,
    );
  }

  Future<void> _open(int gen) async {
    final token = ++_tokenSeq;
    _token = token;
    _resetFace();
    final PreviewOpenResult result;
    try {
      result = await _bridge.openPreview(token);
    } catch (e) {
      // Pudo quedar una apertura parcial: se cierra solo este token (el
      // motor ignora el cierre de un token que ya no es el vigente).
      _closeQuietly(token);
      if (_token == token) _token = null;
      if (_live(gen)) _fail(e);
      return;
    }
    if (!_live(gen) || _token != token) {
      // Respuesta antigua: nunca reactiva una vista cerrada.
      if (result.status == PreviewOpenStatus.opened) _closeQuietly(token);
      if (_token == token) _token = null;
      return;
    }
    final phase = switch (result.status) {
      PreviewOpenStatus.opened => CameraCheckPhase.available,
      PreviewOpenStatus.permissionMissing => CameraCheckPhase.explain,
      PreviewOpenStatus.noFrontCamera => CameraCheckPhase.noFrontCamera,
      PreviewOpenStatus.cameraInUse => CameraCheckPhase.inUse,
      PreviewOpenStatus.cameraDisabled => CameraCheckPhase.disabled,
      PreviewOpenStatus.failed ||
      PreviewOpenStatus.superseded => CameraCheckPhase.failed,
    };
    final available = phase == CameraCheckPhase.available;
    if (!available) {
      _token = null;
      _resetFace();
    }
    state = FrontCameraState(
      phase: phase,
      permission: result.status == PreviewOpenStatus.permissionMissing
          ? CameraPermissionStatus.denied
          : state.permission,
      preview: available ? result : null,
      errorCode: result.errorCode,
      face: available ? _face : null,
      faceSilent: available && _faceSilent,
      faceStale: available && _faceStale,
    );
    if (available) {
      // Sin ningún mensaje aún, el silencio empieza al abrir; si ya llegó
      // alguno, sigue corriendo desde su llegada.
      _silenceTimer ??= _startSilenceTimer();
      _pollTimer = Timer.periodic(facePollInterval, (_) => _queryFace());
      _queryFace();
    }
  }

  /// Aviso del motor. Su demora no tiene cota: una detección avisada solo
  /// dispara una consulta y nunca se muestra; los demás estados se aceptan
  /// (ver [_accept]).
  void _onFace(FaceAnalysisSnapshot snapshot) {
    if (snapshot.token != _token || !ref.mounted || _faceStopped) return;
    if (_isDetection(snapshot.status)) {
      _queryFace();
      return;
    }
    _accept(snapshot, effectiveAge: null);
  }

  /// Consulta el estado al motor y mide en Dart el tiempo completo de la
  /// consulta, con un cronómetro monotónico iniciado antes de llamar. Una a
  /// la vez; otra petición durante ella se encadena.
  Future<void> _queryFace() async {
    final token = _token;
    if (token == null || !ref.mounted || _faceStopped) return;
    final pending = _inFlightWatch;
    if (_inFlightQuery != null &&
        pending != null &&
        pending.elapsed <= faceStaleAfter) {
      _queryAgain = true;
      return;
    }
    final id = ++_queryId;
    final watch = clock.stopwatch()..start();
    _inFlightQuery = id;
    _inFlightWatch = watch;
    FaceAnalysisSnapshot? answer;
    try {
      answer = await _bridge.queryFaceAnalysis(token);
    } catch (e) {
      debugPrint('Vigía · consulta del análisis $token no respondida: $e');
    }
    watch.stop();
    if (_inFlightQuery == id) {
      _inFlightQuery = null;
      _inFlightWatch = null;
    }
    if (!ref.mounted || _token != token) return;
    if (answer != null && answer.token == token) {
      final age = answer.resultAgeMs;
      _accept(
        answer,
        effectiveAge: age == null
            ? null
            : Duration(milliseconds: age) + watch.elapsed,
      );
    }
    if (_queryAgain && _inFlightQuery == null) {
      _queryAgain = false;
      unawaited(_queryFace());
    }
  }

  /// Acepta un mensaje del motor, en orden.
  ///
  /// Se descartan: cualquier mensaje tras `stopped` de esta apertura; un
  /// `sequence` ya visto o menor (repetido o atrasado); una `generation`
  /// anterior a la última aceptada. Una detección solo llega aquí desde una
  /// consulta, con su [effectiveAge]; sin ella, no se muestra.
  void _accept(
    FaceAnalysisSnapshot snapshot, {
    required Duration? effectiveAge,
  }) {
    if (_faceStopped) return;
    if (snapshot.sequence <= _faceSequence) return;
    if (snapshot.generation < _faceGeneration) return;
    _faceSequence = snapshot.sequence;
    _faceGeneration = snapshot.generation;
    _face = snapshot;
    // Noticia del motor: reinicia el límite de silencio.
    _faceSilent = false;
    _silenceTimer?.cancel();
    _silenceTimer = _startSilenceTimer();
    if (snapshot.status == FaceAnalysisStatus.stopped) {
      _faceStopped = true;
      _silenceTimer?.cancel();
      _pollTimer?.cancel();
      _setStale(false);
    } else if (_isDetection(snapshot.status)) {
      _applyVigencia(snapshot.resultId, effectiveAge);
    } else {
      _clearVigencia();
    }
    _publishFace();
  }

  /// Calcula cuánto le queda al resultado. Con el mismo `resultId`, el
  /// plazo es el menor de los conocidos: nunca se alarga.
  void _applyVigencia(int? resultId, Duration? effectiveAge) {
    if (resultId == null || effectiveAge == null) {
      _clearVigencia();
      _setStale(true);
      return;
    }
    final current = _vigenteResultId;
    if (resultId <= _retiredUpTo || (current != null && resultId < current)) {
      // Caducado, retirado o anterior al mostrado: no revive.
      _setStale(true);
      return;
    }
    final remaining = faceStaleAfter - effectiveAge;
    final sameResult = resultId == current;
    // Con el mismo resultado, lo que le quede nunca supera lo ya conocido.
    final known = sameResult ? _vigenteLeftNow() : null;
    final left = known != null && known < remaining ? known : remaining;
    _vigenteResultId = resultId;
    _vigenteLeft = left;
    _vigenteWatch = clock.stopwatch()..start();
    _vigenciaTimer?.cancel();
    if (left.isNegative) {
      _retire(resultId);
      return;
    }
    _setStale(false);
    // Vigente mientras edad ≤ Tstale: caduca justo después del límite.
    _vigenciaTimer = Timer(left + const Duration(microseconds: 1), () {
      if (!ref.mounted) return;
      _retire(resultId);
      _publishFace();
    });
  }

  /// Vigencia que le queda ahora al resultado mostrado.
  Duration? _vigenteLeftNow() {
    final left = _vigenteLeft;
    final watch = _vigenteWatch;
    if (left == null || watch == null) return null;
    return left - watch.elapsed;
  }

  /// El resultado [resultId] dejó de ser vigente para siempre.
  void _retire(int resultId) {
    if (resultId > _retiredUpTo) _retiredUpTo = resultId;
    _setStale(true);
  }

  void _clearVigencia() {
    final shown = _vigenteResultId;
    if (shown != null && shown > _retiredUpTo) _retiredUpTo = shown;
    _vigenciaTimer?.cancel();
    _vigenciaTimer = null;
    _vigenteLeft = null;
    _vigenteWatch = null;
    _setStale(false);
  }

  void _setStale(bool stale) => _faceStale = stale;

  Timer _startSilenceTimer() {
    final token = _token;
    return Timer(faceSilenceLimit, () {
      if (!ref.mounted || token == null || _token != token) return;
      _faceSilent = true;
      _publishFace();
    });
  }

  void _publishFace() {
    if (!ref.mounted || state.phase != CameraCheckPhase.available) return;
    state = state.withFace(_face, silent: _faceSilent, stale: _faceStale);
  }

  static bool _isDetection(FaceAnalysisStatus s) =>
      s == FaceAnalysisStatus.noFace ||
      s == FaceAnalysisStatus.oneFace ||
      s == FaceAnalysisStatus.multipleFaces;

  void _resetFace() {
    _face = null;
    _silenceTimer?.cancel();
    _silenceTimer = null;
    _vigenciaTimer?.cancel();
    _vigenciaTimer = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    _faceSequence = 0;
    _faceGeneration = 0;
    _faceStopped = false;
    _faceSilent = false;
    _faceStale = false;
    _vigenteResultId = null;
    _retiredUpTo = 0;
    _vigenteLeft = null;
    _vigenteWatch = null;
    _inFlightQuery = null;
    _inFlightWatch = null;
    _queryAgain = false;
  }

  void _onClosed(PreviewClosedEvent event) {
    if (event.token != _token || !ref.mounted) return;
    _token = null;
    _resetFace();
    _generation++;
    state = FrontCameraState(
      phase: switch (event.reason) {
        PreviewCloseReason.background ||
        PreviewCloseReason.detached => CameraCheckPhase.suspended,
        PreviewCloseReason.cameraInUse => CameraCheckPhase.inUse,
        PreviewCloseReason.cameraError => CameraCheckPhase.failed,
      },
      permission: state.permission,
      errorCode: event.errorCode,
    );
  }

  void _release() {
    final token = _token;
    _token = null;
    _resetFace();
    if (token != null) _closeQuietly(token);
  }

  /// La operación de [gen] sigue vigente y el controlador no se desechó.
  bool _live(int gen) => gen == _generation && ref.mounted;

  /// Fallo recuperable: libera el bloqueo de la operación (la fase deja de
  /// ser `checking`/`requesting`/`opening`) y permite Reintentar.
  void _fail(Object error) {
    state = FrontCameraState(
      phase: CameraCheckPhase.failed,
      permission: state.permission,
      errorCode: error is PlatformException ? error.code : 'bridgeError',
      bridgeFailure: true,
    );
  }

  /// Cierra [token] sin dejar excepciones sin capturar: un fallo del canal
  /// al cerrar no cambia el estado (la cámara ya no se muestra).
  void _closeQuietly(int token) {
    try {
      _bridge
          .closePreview(token)
          .then(
            (_) {},
            onError: (Object e) {
              debugPrint('Vigía · cierre de cámara $token no confirmado: $e');
            },
          );
    } catch (e) {
      debugPrint('Vigía · cierre de cámara $token no confirmado: $e');
    }
  }

  static CameraCheckPhase _blockedPhase(CameraPermissionStatus s) =>
      s == CameraPermissionStatus.requiresSettings
      ? CameraCheckPhase.requiresSettings
      : CameraCheckPhase.denied;
}
