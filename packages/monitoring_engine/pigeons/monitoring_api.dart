// Contrato Pigeon del motor (Área 04 §7: `pigeons/monitoring_api.dart`).
//
// Fase 5A: solo la vista previa de la cámara frontal y el permiso CAMERA.
// Sin análisis de imagen, calibración, sesiones ni alertas: esas operaciones
// del Área 04 §7 se añadirán cuando se autoricen.
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

  /// Denegado y Android confirmó que ya no muestra la solicitud: antes de
  /// ella ofrecía explicación y, tras el rechazo, ya no. Hay que abrir los
  /// ajustes del teléfono. Un diálogo descartado sin responder es [denied].
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

  /// Cierra y libera la vista previa de [token]. Si [token] ya no es la
  /// petición vigente, no hace nada.
  void closeFrontPreview(int token);
}

/// Avisos de Kotlin hacia Flutter.
@FlutterApi()
abstract class FrontCameraFlutterApi {
  /// La vista previa vigente se cerró por decisión nativa.
  void onPreviewClosed(PreviewClosedEvent event);
}
