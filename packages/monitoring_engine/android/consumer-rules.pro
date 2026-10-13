# Fase 5B: reglas de R8 que el plugin aporta a la app.
#
# MediaPipe Tasks Vision 1.0.0 no publica reglas propias. Sin estas, la
# compilación release falla al crear el detector: R8 renombra los campos de
# sus mensajes protobuf-lite, que se leen por reflexión («Field platform_ ...
# not found»), y el código nativo llama a clases Java de MediaPipe por nombre.
-keep class com.google.mediapipe.** { *; }
-keep class * extends com.google.protobuf.GeneratedMessageLite { *; }

# Al conservar MediaPipe entero, R8 revisa dos métodos que no se usan
# (perfilador y plantillas de grafo) y que citan clases que el AAR no incluye.
-dontwarn com.google.mediapipe.proto.CalculatorProfileProto$CalculatorProfile
-dontwarn com.google.mediapipe.proto.GraphTemplateProto$CalculatorGraphTemplate

# Flogger (registro interno de MediaPipe) localiza a quien lo llama recorriendo
# la pila; si R8 renombra o integra sus clases falla con «no caller found on
# the stack».
-keep class com.google.common.flogger.** { *; }
