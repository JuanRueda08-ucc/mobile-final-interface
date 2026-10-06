# Evidencia VIG-003 · App Flutter y plugin local

Capturada el 2026-10-05 (America/Bogota) en `D:\dev\vigia`, rama `task/VIG-003-bootstrap`, base `3adb678`. Las salidas de Gradle incluyen «Picked up JAVA_TOOL_OPTIONS», la mitigación aplicada solo en la sesión del agente (ver `00-incidencias.txt` y `docs/toolchain.md`).

| Archivo | Contenido | Resultado |
|---|---|---|
| `00-incidencias.txt` | `flutter analyze` y AGP con la ruta «Diseño…»; socket AF_UNIX en la sesión | Resueltas: repositorio copiado a `D:\dev\vigia`; mitigación solo de sesión |
| `01-flutter-version.txt` | `flutter --version` | 3.47.6 / Dart 3.13.5 |
| `02-gradle-version-jdk.txt` | `android/gradlew -version` | Gradle 9.3.1; Launcher y Daemon JVM Temurin 21.0.10 |
| `03-flutter-analyze.txt` | `flutter analyze` (app y plugin) | No issues found (salida 0, ambos) |
| `04-flutter-test.txt` | `flutter test` (app y plugin) | 3 + 3 pruebas superadas |
| `05-dart-format.txt` | `dart format --set-exit-if-changed` | 0 archivos cambiados |
| `06-pub-deps.txt` | `flutter pub deps --style=compact` | Árbol resuelto desde `pubspec.lock` |
| `07-apk-badging.txt` | `aapt2 dump badging` del APK | `com.juanrueda.vigia`, versionName 0.1.0, versionCode 1, minSdk 26, targetSdk 36, etiqueta «Vigía» |
| `08-gradle-wrapper.txt` | Propiedades y hashes del wrapper | Jar y distribución coinciden con los SHA-256 oficiales de Gradle 9.3.1 |
| `09-acl-d-dev.txt` | `icacls D:\dev` (lectura) | Permiso explícito del usuario + herencia de `D:\` |
| `10-jdk-gradle-desde-flutter.txt` | Extracto de `flutter build apk --debug -v` | Daemon de Gradle lanzado con `D:\Program Files\Eclipse Adoptium\jdk-21\bin\java.exe` |
| `kotlin-testDebugUnitTest.txt` | `./gradlew :monitoring_engine:testDebugUnitTest` | 1 prueba Kotlin superada |
| `compilacion-1-*`, `compilacion-2-*` | `tools/vig003_build.sh` (pub get `--enforce-lockfile`, `flutter build apk --debug`, árboles de dependencias Gradle). La compilación 2 se hizo tras `flutter clean` | Mismo SHA-256 de `pubspec.lock`, árboles Gradle idénticos, 0 versiones dinámicas «+» y mismo SHA-256 del APK |

**APK** (no versionado en Git): `build/app/outputs/flutter-apk/app-debug.apk`, 150 494 442 bytes, SHA-256 `44153886f652ce5939b4c4eb520a67f1fa4df85843f3ceabab5d5fb87bf137a0`. Es un APK debug firmado con la clave de depuración local, no un artefacto de distribución.

**No ejecutado:** instalación y arranque en dispositivo (no hay D1), compilación release, auditoría del manifiesto de variantes reales (VIG-004).
