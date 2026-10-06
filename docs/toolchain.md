# Vigía · Toolchain de desarrollo (VIG-002)

**Tarea:** VIG-002 · Fijar toolchain y equipos de referencia (Área 08, H00)
**Rama:** `task/VIG-002-toolchain` · **Base:** `ad51cb2` (VIG-001 aceptada) · **Fecha:** 2026-10-05, America/Bogota
**Máquina de desarrollo:** Windows 11 Home Single Language 10.0.26200 (25H2), x64
**Evidencia:** [`docs/evidence/VIG-002/`](evidence/VIG-002/) (salidas literales de las herramientas)

## Estados usados en este documento

| Estado | Significado |
|---|---|
| **Instalado/verificado** | Presente en esta máquina, con versión confirmada por la propia herramienta (evidencia enlazada) |
| **Candidato** | Versión propuesta (plantilla de Flutter 3.47.6 o última estable publicada a 2026-10-05) y **no** comprobada compilando. Se confirma o cambia en VIG-003 |
| **Pendiente** | Sin decidir o sin resolver. No instalado |

Ninguna dependencia de la futura app (Pigeon, CameraX, MediaPipe, Room, Drift, Riverpod, go_router) está instalada ni se declara compatible: la compatibilidad se comprobará **por compilación** en VIG-003 (Área 08 §3, VIG-002 «Cierre»). minSdk 26 sigue siendo **candidato**.

## Matriz

| Componente | Versión | Ruta / origen | Estado | Evidencia |
|---|---|---|---|---|
| Flutter SDK | **3.47.6** stable · framework `5fc346839b` (2026-09-30) · engine `692136cb65` | `D:\dev\flutter` · zip oficial `flutter_windows_3.47.6-stable.zip`, SHA-256 `a01bb0d26de91bc23c97cd9ccfaad281a612fb8304213fdd5df1119a09404796` (coincide con `releases_windows.json`) | Instalado/verificado | 01, 03 |
| Dart | **3.13.5** (stable), incluido en el SDK de Flutter | `D:\dev\flutter\bin\dart` (no hay otro Dart instalado) | Instalado/verificado | 02 |
| DevTools | 2.60.0 | Incluido en Flutter | Instalado/verificado | 01 |
| Pigeon | 29.0.6 (pub.dev, publicado 2026-10-02; requiere Dart ^3.11.0) | Dependencia de desarrollo del plugin (VIG-003/VIG-008) | Candidato | — |
| Kotlin (Gradle plugin) | 2.4.0 (plantilla Flutter 3.47.6); última estable publicada: 2.4.20 | Por proyecto (`settings.gradle.kts`) | Candidato | — |
| JDK usado por Flutter/Gradle | **Temurin 21.0.10+7 LTS** | `D:\Program Files\Eclipse Adoptium\jdk-21` (instalación previa, reutilizada) | Instalado/verificado (Flutter); Gradle se confirma en VIG-003 | 03, 06 |
| Gradle | 9.3.1 (plantilla de Flutter 3.47.6 = máximo conocido y soportado por esta versión de Flutter) | Wrapper por proyecto (VIG-003); no hay Gradle global. Caché: `GRADLE_USER_HOME=D:\dev\gradle-home` | Candidato | — |
| Android Gradle Plugin (AGP) | 9.1.0 (plantilla). Flutter 3.47.6 conoce hasta 9.2; última estable publicada: 9.4.1 | Por proyecto | Candidato | — |
| Android SDK · Command-line Tools | 23.0 (paquete `commandlinetools-win-16111833_latest.zip`, SHA-1 `57d04f2d75eb8e8fffc5000a987e5de4b5a63e9d`, coincide con el repositorio de Google). Incluye Android CLI 1.0.16500706 | `D:\dev\android-sdk\cmdline-tools\latest` | Instalado/verificado | 07 |
| Android SDK · Platform-Tools (`adb`) | 37.0.1 (adb 1.0.41, build 37.0.1-15733141) | `D:\dev\android-sdk\platform-tools` | Instalado/verificado | 05, 07 |
| Android SDK · Platform | android-36 (Android 16), revisión 2 | `D:\dev\android-sdk\platforms\android-36` | Instalado/verificado | 03, 07 |
| Android SDK · Build-Tools | 36.1.0 | `D:\dev\android-sdk\build-tools\36.1.0` | Instalado/verificado (AGP puede pedir otra versión al compilar; VIG-003) | 03, 07 |
| Android SDK · NDK | 28.2.13676358 (la que fija `FlutterExtension.ndkVersion` en 3.47.6) | `D:\dev\android-sdk\ndk\28.2.13676358` | Instalado/verificado | 07 |
| Android SDK · CMake | 4.1.2 | `D:\dev\android-sdk\cmake\4.1.2` | Instalado/verificado (uso real por confirmar en VIG-003) | 07 |
| Licencias del Android SDK | Aceptadas por el responsable del proyecto al instalar con Android CLI | `D:\dev\android-sdk\licenses` | Verificado («All Android licenses accepted») | 03 |
| compileSdk / targetSdk | 36 / 36 (plantilla). El Área 07 §14 exige target ≥ 36 para Play desde 31/08/2026; se revalida al distribuir (VIG-069) | Por proyecto | Candidato | — |
| minSdk | **26** (Área 04 §2, Área 07 §5). La plantilla de Flutter usa 24 por defecto | Por proyecto | Candidato | — |
| CameraX | 1.6.2 (última estable en Google Maven; existe 1.7.0-alpha03, no se usará una alpha) | Dependencia Android del plugin | Pendiente (versión candidata sin resolver) | — |
| MediaPipe Tasks Vision (Face Landmarker) | 1.0.0 (último listado en Google Maven `com.google.mediapipe:tasks-vision`); modelo `.task` con hash y licencia en VIG-011 | Dependencia Android del plugin | Pendiente | — |
| Room | 2.8.5 (última estable en Google Maven) | Dependencia Android del plugin (journal) | Pendiente | — |
| Drift | 2.35.1 (`drift` y `drift_dev`, pub.dev 2026-09-30) | Dependencia Dart de la app | Pendiente | — |
| SQLite nativo para Drift | `sqlite3_flutter_libs` aparece como **fin de vida** (0.6.0+eol: «update to version 3.x of package:sqlite3»); `sqlite3` 3.7.0 | Dependencia Dart de la app | Pendiente: decidir en VIG-003 la integración SQLite compatible con Drift 2.35 | — |
| Riverpod / go_router | `flutter_riverpod` 3.4.3 / `go_router` 18.0.2 (pub.dev) | Dependencias Dart de la app | Pendiente | — |

## Selección de Java (resuelta)

Situación previa (evidencia 00 y 06), conservada sin cambios:
- El **primer `java` del PATH es Oracle Java 8** (`1.8.0_503`, vía `C:\Program Files (x86)\Common Files\Oracle\Java\java8path`).
- `JAVA_HOME` (usuario y máquina) apunta a **Temurin 21** (`D:\Program Files\Eclipse Adoptium\jdk-21`).

Decisión aplicada:
- `flutter config --jdk-dir "D:\Program Files\Eclipse Adoptium\jdk-21"`. `flutter doctor -v` confirma «Java binary at: D:\Program Files\Eclipse Adoptium\jdk-21\bin\java · This JDK is specified in your Flutter configuration · Temurin-21.0.10+7».
- Flutter pasa ese JDK a Gradle al compilar. El wrapper de Gradle invocado directamente usa `JAVA_HOME` (también Temurin 21). Que Gradle use realmente JDK 21 se confirmará en VIG-003 con `gradlew -version`.
- **No** se desinstaló Java 8 ni se cambió su posición en el PATH. Afecta solo a quien invoque `java` sin ruta. Flutter/Gradle no lo usan.

## Cambios de configuración realizados (y cómo revertirlos)

Respaldo previo literal en [`00-entorno-previo.txt`](evidence/VIG-002/00-entorno-previo.txt).

| Cambio | Ámbito | Valor |
|---|---|---|
| `ANDROID_HOME` | Variable de usuario (nueva) | `D:\dev\android-sdk` |
| `PUB_CACHE` | Variable de usuario (nueva) | `D:\dev\pub-cache` |
| `GRADLE_USER_HOME` | Variable de usuario (nueva) | `D:\dev\gradle-home` |
| PATH de usuario | Añadidas 3 entradas, 0 eliminadas | `D:\dev\flutter\bin` (al inicio); `D:\dev\android-sdk\platform-tools` y `D:\dev\android-sdk\cmdline-tools\latest\bin` (al final) |
| `jdk-dir` de Flutter | Configuración de Flutter del usuario | `D:\Program Files\Eclipse Adoptium\jdk-21` (antes: sin valor) |

Para revertir: restaurar el PATH de usuario desde la evidencia 00, borrar las tres variables nuevas y ejecutar `flutter config --jdk-dir=""`.

**Motivo de usar `D:\dev`:** C: tenía 2,1 GB libres al empezar. D: tiene NTFS fijo, 84 GB libres, y la ruta no tiene espacios, como recomienda la guía de Flutter. La raíz `D:\` solo permite escritura a Administradores; el responsable creó `D:\dev` y concedió control total a su usuario con `icacls`.

**Uso de disco tras la instalación** (evidencia 08): `flutter` 3,25 GB · `android-sdk` 2,59 GB · `pub-cache` 0,11 GB · `downloads` 1,94 GB (zips de instalación conservados para trazabilidad; prescindibles) · `gradle-home` 0 GB.

## Resultado de `flutter doctor -v` (evidencia 03)

| Categoría | Resultado | Relevancia para Vigía |
|---|---|---|
| Flutter | ✓ 3.47.6 stable | Requerido |
| Windows Version | ✓ | — |
| Android toolchain | ✓ SDK 36.1.0, platform android-36, build-tools 36.1.0, JDK Temurin 21, licencias aceptadas. «Emulator version unknown» (emulador no instalado por decisión del responsable) | Requerido |
| Chrome | ✓ | No requerido (sin WebView ni web en V1) |
| Visual Studio | ✗ no instalado | **No requerido**: solo sirve para apps de escritorio Windows, fuera del alcance (Android primero) |
| Connected device | Windows, Chrome, Edge. **Ningún dispositivo Android** | Bloquea D1 (ver `docs/testing.md`) |
| Network resources | ✓ | — |

## Observaciones y bloqueos

1. **Ningún teléfono Android conectado.** `adb devices -l` está vacío y `flutter devices` no lista Android. VIG-003 exige «Instalación en D1»: queda **bloqueado** en ese punto hasta disponer de D1 (ver `docs/testing.md`).
2. **Emulador no instalado**, por decisión del responsable (sin emulador por ahora). El perfil EM queda pendiente.
3. **El proyecto y la caché están en unidades distintas.** El repositorio está en `C:` y `PUB_CACHE`/`GRADLE_USER_HOME` en `D:`. Kotlin tiene un problema conocido de compilación incremental cuando el proyecto y la caché de Pub están en raíces distintas. Se comprobará en VIG-003. Si aparece, se valorará mover el repositorio a `D:\dev` o desactivar la compilación incremental de Kotlin.
4. **Android CLI sustituye a `sdkmanager`.** `sdkmanager` está obsoleto en cmdline-tools 23.0, y `--licenses` «ya no es necesario»: las licencias se aceptan al instalar. Por eso Flutter no reconocía el SDK con `flutter doctor --android-licenses` hasta que existió `licenses/` o `platform-tools/` (comprobado en `android_sdk.dart`). Los paquetes se instalaron con `android.exe --no-metrics sdk install …`, ejecutado por el responsable.
5. **SQLite para Drift:** `sqlite3_flutter_libs` está marcado como fin de vida. Hay que decidir la integración nativa de SQLite al fijar dependencias en VIG-003.
6. **Telemetría:** Flutter/Dart muestran el aviso de analíticas. No se modificó esa preferencia (se desactiva con `flutter --disable-analytics`, a decisión del responsable).
7. **Codificación de la evidencia:** `flutter doctor` imprime «Versi¢n» al leer la versión de Windows desde la consola. Es salida literal de la herramienta y se conserva sin editar.

## Siguiente paso (VIG-003, no iniciado)

Crear la app Flutter y el plugin local Kotlin con el wrapper de Gradle, fijar las versiones de la tabla mediante compilación, y verificar:
- que la segunda compilación no modifica la resolución;
- `gradlew -version` (JDK efectivo);
- el problema de unidades distintas;
- la instalación en D1.

Mientras no exista D1, la parte de instalación en dispositivo de VIG-003 queda bloqueada.
