// Contrato Pigeon del motor (Área 04 §7: `pigeons/monitoring_api.dart`).
//
// Fase 5A: vista previa de la cámara frontal y permiso CAMERA.
// Fase 5B: presencia facial con MediaPipe Face Landmarker (resultados
// compactos; los puntos faciales no salen de Kotlin).
// Fase 5C: recorrido experimental (calibración, sesión única, cierre ocular
// prolongado y tono) con el perfil candidato `lab-eye-rules-0.1`. Es un
// subconjunto del Área 04 §7: sin journal, registros ni borrado.
//
// Regenerar (desde packages/monitoring_engine):
//   dart run pigeon --input pigeons/monitoring_api.dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/src/monitoring_api.g.dart',
    dartPackageName: 'monitoring_engine',
    kotlinOut: 'android/src/main/kotlin/com/juanrueda/monitoring_engine/MonitoringApi.g.kt',
    kotlinOptions: KotlinOptions(package: 'com.juanrueda.monitoring_engine'),
    copyrightHeader: 'pigeons/copyright.txt',
  ),
)
/// Estado del permiso CAMERA según Android.
enum CameraPermissionStatus {
  /// Concedido. No implica que la cámara esté disponible.
  granted,

  /// Denegado; Android permite volver a solicitarlo.
  denied,

  /// Denegado, y la implementación infiere que Android ya no mostrará la
  /// solicitud: antes de ella `shouldShowRequestPermissionRationale` era
  /// verdadero y, tras el rechazo, falso. Es una inferencia, no una garantía
  /// de la API; se comprobó en un AVD con API 36. Se ofrece abrir los ajustes
  /// del teléfono. Un diálogo descartado sin responder es [denied].
  requiresSettings,
}

/// Resultado de una apertura de la vista previa frontal.
enum PreviewOpenStatus {
  /// La cámara informó estado abierto y la vista previa está vinculada.
  opened,

  /// Falta el permiso CAMERA en el momento de abrir.
  permissionMissing,

  /// El teléfono no tiene cámara frontal disponible para CameraX.
  noFrontCamera,

  /// Otra aplicación usa la cámara (causa confirmada por CameraX; ER02).
  cameraInUse,

  /// La cámara está desactivada por política del dispositivo.
  cameraDisabled,

  /// Fallo de apertura sin causa determinada (ER03).
  failed,

  /// Una apertura o un cierre posteriores sustituyeron esta petición; no se
  /// abrió nada para ella.
  superseded,
}

/// Motivo de un cierre decidido por el lado nativo.
enum PreviewCloseReason {
  /// La Activity dejó de estar visible (segundo plano, ajustes del teléfono).
  background,

  /// Otra aplicación tomó la cámara.
  cameraInUse,

  /// Error de la cámara después de abrirse.
  cameraError,

  /// La Activity o el plugin se desconectaron del motor de Flutter.
  detached,
}

class PreviewOpenResult {
  PreviewOpenResult({required this.token, required this.status});

  /// Identificador de la petición, elegido por Flutter.
  int token;
  PreviewOpenStatus status;

  /// Solo con [PreviewOpenStatus.opened]: textura de Flutter.
  int? textureId;

  /// Tamaño de la imagen ya derecha (tras [rotationDegrees]), en píxeles.
  int? width;
  int? height;

  /// Giro horario (0, 90, 180, 270) que Flutter debe aplicar para mostrar la
  /// imagen derecha; 0 si el motor de Flutter ya la gira.
  int? rotationDegrees;

  /// `true` si la vista debe mostrarse espejada (cámara frontal).
  bool? mirrored;

  /// Código técnico del fallo, para diagnóstico. No es un texto de interfaz.
  String? errorCode;
}

/// Estado del análisis de presencia facial de una apertura (fase 5B).
enum FaceAnalysisStatus {
  /// Verificando el modelo empaquetado y creando el detector.
  loadingModel,

  /// Modelo listo, sin resultado vigente: todavía no llegó ninguno o el
  /// último caducó. No significa que falte el rostro.
  waitingResults,

  /// Resultado vigente con cero rostros.
  noFace,

  /// Resultado vigente con un rostro.
  oneFace,

  /// Resultado vigente con dos o más rostros (el detector busca hasta
  /// [FaceAnalysisSnapshot.maxFaces]).
  multipleFaces,

  /// El análisis terminó (cierre de la vista previa).
  stopped,

  /// El modelo no se pudo cargar: ausente, alterado o incompatible
  /// ([FaceAnalysisSnapshot.errorCode]). Se puede reintentar la carga.
  modelError,

  /// La inferencia falló. Se puede reintentar.
  analysisError,
}

/// Resultado compacto del análisis facial. No contiene imágenes ni puntos
/// faciales: solo el estado, el número de rostros y contadores técnicos.
class FaceAnalysisSnapshot {
  FaceAnalysisSnapshot({
    required this.token,
    required this.sequence,
    required this.generation,
    required this.status,
    required this.maxFaces,
    required this.staleAfterMs,
    required this.framesSubmitted,
    required this.resultsAccepted,
    required this.framesDropped,
    required this.resultsDiscarded,
    required this.expired,
  });

  /// Apertura de vista previa a la que pertenece.
  int token;

  /// Orden de publicación dentro de la apertura: estrictamente creciente.
  /// Flutter descarta un mensaje con un número ya visto o menor (repetido o
  /// atrasado).
  int sequence;

  /// Carga del modelo dentro de la apertura; cambia al reintentar y al
  /// detener. Nunca disminuye.
  int generation;
  FaceAnalysisStatus status;

  /// Rostros del resultado vigente; nulo sin resultado vigente.
  int? faceCount;

  /// Identidad de la inferencia que se informa, única en la apertura; nula
  /// sin resultado vigente. Un latido repite el valor del último resultado:
  /// solo un valor nuevo es una inferencia nueva.
  int? resultId;

  /// Edad del resultado **al crear este mensaje** en el motor: reloj
  /// monotónico de Android en ese instante menos la entrega del cuadro al
  /// analizador, en ms. No incluye el tiempo del puente: Flutter lo suma
  /// cuando el mensaje responde a [FrontCameraHostApi.getFaceAnalysis].
  int? resultAgeMs;

  /// Rostros como máximo que busca el detector.
  int maxFaces;

  /// Vigencia máxima de un resultado (Tstale, experimental), en ms.
  int staleAfterMs;

  int framesSubmitted;
  int resultsAccepted;

  /// Cuadros no enviados al modelo (sin modelo listo, orden o conversión).
  int framesDropped;

  /// Resultados descartados por antiguos, desordenados o desconocidos.
  int resultsDiscarded;

  /// `true` si se volvió a esperar porque el último resultado caducó.
  bool expired;

  /// Tamaño y giro horario de los cuadros analizados (diagnóstico).
  int? frameWidth;
  int? frameHeight;
  int? frameRotationDegrees;

  /// Código técnico del error, para diagnóstico. No es un texto de interfaz.
  String? errorCode;
}

class PreviewClosedEvent {
  PreviewClosedEvent({required this.token, required this.reason});

  int token;
  PreviewCloseReason reason;
  String? errorCode;
}

/// Operaciones de Flutter hacia Kotlin.
@HostApi()
abstract class FrontCameraHostApi {
  /// Consulta el permiso sin solicitarlo. Nunca devuelve
  /// [CameraPermissionStatus.requiresSettings]: Android solo lo revela al
  /// responder una solicitud.
  CameraPermissionStatus checkCameraPermission();

  /// Muestra la solicitud de Android (o responde de inmediato si Android ya
  /// no la muestra). Peticiones simultáneas comparten la misma solicitud.
  @async
  CameraPermissionStatus requestCameraPermission();

  /// Abre la pantalla de información de la app en los ajustes del teléfono.
  /// `false` si no se pudo abrir.
  bool openAppSettings();

  /// Abre la vista previa frontal para [token]. Sustituye cualquier petición
  /// anterior, que se cierra y responde [PreviewOpenStatus.superseded].
  @async
  PreviewOpenResult openFrontPreview(int token);

  /// Cierra y libera la vista previa de [token] y su análisis facial. Si
  /// [token] ya no es la petición vigente, no hace nada.
  void closeFrontPreview(int token);

  /// Vuelve a cargar el modelo y reinicia el análisis facial de [token] tras
  /// un error. `false` si [token] no es la apertura vigente.
  bool restartFaceAnalysis(int token);

  /// Estado del análisis facial de [token], creado en el hilo de análisis en
  /// el momento de responder (su `resultAgeMs` es la edad en ese instante).
  /// Nulo si [token] no es la apertura vigente. Es la única vía por la que
  /// Flutter acepta un rostro como vigente: mide en Dart el tiempo completo
  /// de esta consulta y lo suma a `resultAgeMs`.
  @async
  FaceAnalysisSnapshot? getFaceAnalysis(int token);
}

/// Avisos de Kotlin hacia Flutter.
@FlutterApi()
abstract class FrontCameraFlutterApi {
  /// La vista previa vigente se cerró por decisión nativa.
  void onPreviewClosed(PreviewClosedEvent event);

  /// Nuevo estado del análisis facial, o latido periódico con el vigente.
  /// Su demora no se puede acotar: Flutter no muestra un rostro a partir de
  /// este aviso; ante una detección, consulta [FrontCameraHostApi.getFaceAnalysis].
  void onFaceAnalysis(FaceAnalysisSnapshot snapshot);
}

/// Paso de la calibración experimental (Kcal, Área 05 §8).
enum CalibrationStep {
  /// Sin calibración en curso ni resultado en este motor.
  idle,

  /// Referencia con los ojos abiertos (8000 ms).
  openReference,

  /// Aviso «Cierra los ojos» antes de medir el cierre (prototipo).
  closeLeadIn,

  /// Medición del cierre voluntario (1000 ms).
  closedProbe,

  /// Reapertura comprobada (2000 ms continuos con los ojos abiertos).
  reopen,

  /// Referencia aceptada ([MonitoringSnapshot.calibrationId]).
  accepted,

  /// Rechazada ([MonitoringSnapshot.calibrationRejection]).
  rejected,

  /// Cancelada; nunca aceptada.
  canceled,
}

/// Ciclo de la sesión experimental (Área 04 §4.1, subconjunto).
enum EngineSessionLifecycle { none, active, paused, finalized }

/// Eje de medición (Área 04 §4.1).
enum EngineMeasurement { initializing, usable, limited, unavailable }

/// Señal que admite la política (Área 04 §4.1). La advertencia por
/// acumulación (W) no está implementada en esta fase.
enum EngineSignal { notEvaluable, noPersistentSignals, prolongedEyeClosure }

/// Estado compacto del coordinador experimental (fase 5C). Sin imágenes ni
/// puntos faciales: solo mediciones oculares agregadas por observación.
class MonitoringSnapshot {
  MonitoringSnapshot({
    required this.engineInstanceId,
    required this.sequence,
    required this.profileId,
    required this.qualificationStatus,
    required this.eyesValid,
    required this.calibrationStep,
    required this.calibrationAttempt,
    required this.calibrationProbe,
    required this.soundTestPlayed,
    required this.soundHeard,
    required this.lifecycle,
    required this.resumePending,
    required this.measurement,
    required this.signal,
    required this.activeMs,
    required this.pausedMs,
    required this.evaluableMs,
    required this.closureActivations,
    required this.tonesPlayed,
    required this.tonesFailed,
  });

  /// Instancia del coordinador; cambia si el plugin se recrea.
  String engineInstanceId;

  /// Orden de emisión dentro de la instancia: estrictamente creciente.
  int sequence;

  /// Perfil de parámetros (`lab-eye-rules-0.1`) y su calificación
  /// (`experimental`): no es una política aceptada.
  String profileId;
  String qualificationStatus;

  /// Apertura de cámara vinculada al coordinador, si la hay.
  int? attachedToken;

  /// Última observación ocular vigente y con Q válida.
  bool eyesValid;

  /// Motivo técnico por el que los ojos no son medibles (código de Q).
  String? eyeIssue;

  /// EAR de cada ojo anatómico en la última observación vigente.
  double? earRight;
  double? earLeft;

  /// EAR / referencia abierta de cada ojo, si hay referencia.
  double? ratioRight;
  double? ratioLeft;

  /// Edad de la última observación al crear este estado, en ms.
  int? observationAgeMs;

  CalibrationStep calibrationStep;
  int calibrationAttempt;

  /// Comprobación de cierre en curso (1..2); 0 si no aplica.
  int calibrationProbe;
  int? stepElapsedMs;
  int? stepDurationMs;
  int? stepValidSamples;
  String? calibrationId;

  /// insufficientObservations, invalidEyeQuality o unstableReference.
  String? calibrationRejection;

  /// Causa técnica del rechazo (diagnóstico, no texto de interfaz).
  String? calibrationDetail;
  double? openEarRight;
  double? openEarLeft;
  int? calibrationSamples;
  double? calibrationCoverage;

  /// Prueba de sonido técnica y confirmación humana (sin micrófono).
  String? soundTestId;
  bool soundTestPlayed;
  bool soundHeard;
  String? soundFailure;

  EngineSessionLifecycle lifecycle;

  /// Reanudación pedida: la pausa sigue abierta hasta cumplir Krecover.
  bool resumePending;
  String? sessionId;
  EngineMeasurement measurement;
  EngineSignal signal;

  /// Causa técnica de la última pérdida de medición.
  String? measurementCause;

  /// Tiempos de la sesión (monotónicos, en ms).
  int activeMs;
  int pausedMs;
  int evaluableMs;

  /// Activaciones del cierre ocular prolongado (no son reproducciones).
  int closureActivations;

  /// Intentos de tono de aviso: iniciados y fallidos.
  int tonesPlayed;
  int tonesFailed;

  /// Duración del tramo cerrado en curso, en ms.
  int? closedRunMs;
}

/// Resultado de una orden al coordinador experimental.
class MonitoringCommandResult {
  MonitoringCommandResult({required this.accepted, required this.snapshot});

  bool accepted;

  /// Código técnico del rechazo (p. ej. `sessionActive`), o nulo.
  String? errorCode;
  MonitoringSnapshot snapshot;
}

/// Órdenes del recorrido experimental (fase 5C). Kotlin vuelve a comprobar
/// cada precondición: la habilitación de un botón no la sustituye.
@HostApi()
abstract class ExperimentalMonitoringHostApi {
  MonitoringSnapshot getMonitoringSnapshot();

  /// Requiere cámara vinculada y ninguna sesión vigente.
  MonitoringCommandResult beginCalibration();
  MonitoringCommandResult cancelCalibration();

  /// Tono local de prueba; devuelve el identificador de la prueba.
  MonitoringCommandResult testSound();
  MonitoringCommandResult confirmSoundHeard(String soundTestId);

  /// Única sesión: con la referencia y la prueba de sonido indicadas.
  MonitoringCommandResult startSession(
    String calibrationId,
    String soundTestId,
  );

  /// Corta la medición, detiene el tono y libera la cámara.
  MonitoringCommandResult pauseSession(String sessionId);

  /// La pausa sigue abierta hasta reunir observaciones válidas (Krecover).
  MonitoringCommandResult resumeSession(String sessionId);

  /// Termina la sesión: detiene evaluación y tono y libera la cámara.
  MonitoringCommandResult stopSession(String sessionId);
}

/// Avisos del coordinador experimental hacia Flutter: cada cambio y un
/// latido cada 1000 ms.
@FlutterApi()
abstract class ExperimentalMonitoringFlutterApi {
  void onMonitoring(MonitoringSnapshot snapshot);
}
