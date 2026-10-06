# monitoring_engine

Plugin Flutter local de Vigía con implementación Android en Kotlin
(`com.juanrueda.monitoring_engine`). Es la base del futuro motor nativo
(`SessionCoordinator`, cámara, inferencia, política, journal, alertas;
Área 04 §3 y Área 08 §4).

Estado en VIG-003: solo registro nativo verificable con el canal de la
plantilla oficial (`getPlatformVersion`). **No** captura cámara, **no**
ejecuta IA, **no** mantiene sesiones ni reproduce alertas. Ese canal de
arranque se sustituirá por las APIs generadas con Pigeon (VIG-007/VIG-008).

La app raíz lo consume mediante una dependencia `path`
(`packages/monitoring_engine`). No incluye app de ejemplo.

Pruebas:

```bash
flutter test                                   # Dart, desde este directorio
cd android && ./gradlew :monitoring_engine:testDebugUnitTest   # Kotlin, desde la raíz del repo
```
