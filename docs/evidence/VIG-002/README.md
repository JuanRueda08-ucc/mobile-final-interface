# Evidencia VIG-002 · Toolchain

Salidas literales capturadas el 2026-10-05 (America/Bogota) en el equipo de desarrollo Windows 11 10.0.26200, con las variables de usuario configuradas en VIG-002. Cada archivo indica el comando, la fecha y el código de salida.

| Archivo | Comando(s) | Resultado resumido |
|---|---|---|
| `00-entorno-previo.txt` | Estado previo (variables, Java en PATH, espacio, PATH de usuario literal) | Respaldo antes de modificar nada |
| `01-flutter-version.txt` | `flutter --version` | Flutter 3.47.6 stable · Dart 3.13.5 · DevTools 2.60.0 |
| `02-dart-version.txt` | `dart --version`, `where dart` | Dart 3.13.5 desde `D:\dev\flutter\bin` |
| `03-flutter-doctor-v.txt` | `flutter doctor -v` | Android toolchain ✓ (licencias aceptadas, JDK Temurin 21); Visual Studio ✗ (no requerido); sin dispositivo Android |
| `04-flutter-devices.txt` | `flutter devices` | Solo windows/chrome/edge |
| `05-adb-version.txt` | `adb version`, `adb devices -l` | adb 1.0.41 (platform-tools 37.0.1); lista de dispositivos vacía |
| `06-jdk-efectivo.txt` | `flutter config --list`, `java -version` (jdk-dir y PATH), `where java`, `javac -version` | Flutter usa Temurin 21.0.10; el primer `java` del PATH es Java 8 (no lo usa Flutter) |
| `07-android-sdk.txt` | `android sdk list`, `source.properties` | Paquetes instalados y revisiones |
| `08-entorno-final.txt` | Variables de usuario, PATH, espacio libre, tamaño de `D:\dev` | Estado tras la instalación |

Los caracteres «Versi¢n» en 03 y 04 son salida literal de Flutter (página de códigos de la consola) y no se han editado.
