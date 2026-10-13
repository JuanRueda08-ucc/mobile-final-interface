import 'dart:async';

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
  /// noticias del análisis: el último resultado deja de mostrarse como
  /// vigente aunque el motor no haya podido avisar.
  final bool faceSilent;

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
    return switch (f.status) {
      FaceAnalysisStatus.noFace when !faceSilent => FacePresencePhase.noFace,
      FaceAnalysisStatus.oneFace when !faceSilent => FacePresencePhase.oneFace,
      FaceAnalysisStatus.multipleFaces when !faceSilent =>
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
      (faceSilent || (face?.expired ?? false));

  FrontCameraState withFace(
    FaceAnalysisSnapshot? face, {
    bool silent = false,
  }) => FrontCameraState(
    phase: phase,
    permission: permission,
    preview: preview,
    errorCode: errorCode,
    bridgeFailure: bridgeFailure,
    face: face,
    faceSilent: silent,
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
/// - Fase 5B: solo se aceptan resultados faciales del token vigente. Si pasan
///   [faceSilenceLimit] sin ninguno (el motor manda un latido cada segundo),
///   el último deja de mostrarse como vigente.
class FrontCameraController extends Notifier<FrontCameraState> {
  static int _tokenSeq = 0;

  /// Silencio máximo del análisis antes de dejar de mostrar su último
  /// resultado: 3000 ms, propuesta de transporte de Área 04 §9
  /// (experimental). No sustituye a Tstale, que aplica el motor.
  static const faceSilenceLimit = Duration(milliseconds: 3000);

  /// Último resultado facial del token vigente, aunque llegue durante la
  /// apertura (antes de que la cámara esté disponible).
  FaceAnalysisSnapshot? _face;
  Timer? _faceWatchdog;
  bool _restartingFace = false;

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
    _face = null;
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
      _face = null;
    }
    state = FrontCameraState(
      phase: phase,
      permission: result.status == PreviewOpenStatus.permissionMissing
          ? CameraPermissionStatus.denied
          : state.permission,
      preview: available ? result : null,
      errorCode: result.errorCode,
      face: available ? _face : null,
    );
    if (available) _armFaceWatchdog();
  }

  /// Resultado facial del motor. Los de otra apertura se descartan.
  void _onFace(FaceAnalysisSnapshot snapshot) {
    if (snapshot.token != _token || !ref.mounted) return;
    _face = snapshot;
    if (state.phase != CameraCheckPhase.available) return;
    state = state.withFace(snapshot);
    _armFaceWatchdog();
  }

  /// Vigilancia de Flutter: sin noticias en [faceSilenceLimit], el último
  /// resultado deja de mostrarse como vigente.
  void _armFaceWatchdog() {
    _faceWatchdog?.cancel();
    final token = _token;
    _faceWatchdog = Timer(faceSilenceLimit, () {
      if (!ref.mounted || token == null || _token != token) return;
      if (state.phase != CameraCheckPhase.available) return;
      state = state.withFace(_face, silent: true);
    });
  }

  void _onClosed(PreviewClosedEvent event) {
    if (event.token != _token || !ref.mounted) return;
    _token = null;
    _face = null;
    _faceWatchdog?.cancel();
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
    _face = null;
    _faceWatchdog?.cancel();
    _faceWatchdog = null;
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
