import 'dart:async';

import 'monitoring_api.g.dart';

/// Operaciones de cámara frontal y permiso del motor (fase 5A) y análisis de
/// presencia facial (fase 5B).
///
/// La app depende de esta interfaz; las pruebas la sustituyen por un doble.
abstract interface class FrontCameraBridge {
  /// Consulta el permiso CAMERA sin solicitarlo.
  Future<CameraPermissionStatus> checkPermission();

  /// Muestra la solicitud de Android.
  Future<CameraPermissionStatus> requestPermission();

  /// Abre la información de la app en los ajustes del teléfono.
  Future<bool> openAppSettings();

  /// Abre la vista previa frontal para [token].
  Future<PreviewOpenResult> openPreview(int token);

  /// Cierra la vista previa de [token]; no hace nada si ya no es la vigente.
  Future<void> closePreview(int token);

  /// Cierres decididos por el lado nativo (segundo plano, cámara ocupada).
  Stream<PreviewClosedEvent> get closures;

  /// Resultados compactos del análisis facial de cada apertura: estado,
  /// número de rostros y contadores. Nunca imágenes ni puntos faciales.
  Stream<FaceAnalysisSnapshot> get faceAnalysis;

  /// Recarga el modelo y reinicia el análisis de [token] tras un error.
  Future<bool> restartFaceAnalysis(int token);

  /// Estado del análisis de [token] creado por el motor al responder; nulo si
  /// [token] ya no es la apertura vigente. La llamada no se puede cancelar.
  Future<FaceAnalysisSnapshot?> queryFaceAnalysis(int token);

  /// Identidad del canal por el que viajan las consultas, con `==` y
  /// `hashCode` estables: dos puentes distintos sobre el mismo canal
  /// devuelven claves iguales. Sirve para limitar las llamadas pendientes por
  /// canal, no por pantalla ni por puente.
  Object get queryChannel;
}

/// [FrontCameraBridge] sobre los mensajes generados por Pigeon.
class PigeonFrontCameraBridge implements FrontCameraBridge {
  PigeonFrontCameraBridge({FrontCameraHostApi? host})
    : _host = host ?? FrontCameraHostApi() {
    FrontCameraFlutterApi.setUp(_Events(_closures, _faceAnalysis));
  }

  final FrontCameraHostApi _host;
  final _closures = StreamController<PreviewClosedEvent>.broadcast();
  final _faceAnalysis = StreamController<FaceAnalysisSnapshot>.broadcast();

  @override
  Future<CameraPermissionStatus> checkPermission() =>
      _host.checkCameraPermission();

  @override
  Future<CameraPermissionStatus> requestPermission() =>
      _host.requestCameraPermission();

  @override
  Future<bool> openAppSettings() => _host.openAppSettings();

  @override
  Future<PreviewOpenResult> openPreview(int token) =>
      _host.openFrontPreview(token);

  @override
  Future<void> closePreview(int token) => _host.closeFrontPreview(token);

  @override
  Stream<PreviewClosedEvent> get closures => _closures.stream;

  @override
  Stream<FaceAnalysisSnapshot> get faceAnalysis => _faceAnalysis.stream;

  @override
  Future<bool> restartFaceAnalysis(int token) =>
      _host.restartFaceAnalysis(token);

  @override
  Future<FaceAnalysisSnapshot?> queryFaceAnalysis(int token) =>
      _host.getFaceAnalysis(token);

  /// El canal Pigeon lo determinan el mensajero (nulo: el predeterminado) y
  /// el sufijo del canal; el nombre base es fijo.
  @override
  Object get queryChannel => _PigeonQueryChannel(
    _host.pigeonVar_binaryMessenger,
    _host.pigeonVar_messageChannelSuffix,
  );
}

/// Clave del canal `getFaceAnalysis` de Pigeon.
final class _PigeonQueryChannel {
  const _PigeonQueryChannel(this.messenger, this.suffix);

  final Object? messenger;
  final String suffix;

  @override
  bool operator ==(Object other) =>
      other is _PigeonQueryChannel &&
      identical(other.messenger, messenger) &&
      other.suffix == suffix;

  @override
  int get hashCode => Object.hash(identityHashCode(messenger), suffix);
}

class _Events implements FrontCameraFlutterApi {
  _Events(this._sink, this._faces);

  final StreamController<PreviewClosedEvent> _sink;
  final StreamController<FaceAnalysisSnapshot> _faces;

  @override
  void onPreviewClosed(PreviewClosedEvent event) => _sink.add(event);

  @override
  void onFaceAnalysis(FaceAnalysisSnapshot snapshot) => _faces.add(snapshot);
}
