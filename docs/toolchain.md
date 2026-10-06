# Vigía · Toolchain de desarrollo

**Creado en:** VIG-002 (base `ad51cb2`, commit `3adb678`) · **Actualizado en:** VIG-003 (rama `task/VIG-003-bootstrap`) · **Fecha:** 2026-10-05, America/Bogota
**Máquina de desarrollo:** Windows 11 Home Single Language 10.0.26200 (25H2), x64, 15,8 GB de RAM
**Repositorio de trabajo:** `D:\dev\vigia` desde VIG-003 (ver «Ubicación del repositorio»)
**Evidencia:** [`docs/evidence/VIG-002/`](evidence/VIG-002/) (instalación) y [`docs/evidence/VIG-003/`](evidence/VIG-003/) (compilación)

## Estados usados en este documento

| Estado | Significado |
|---|---|
| **Instalado/verificado** | Presente en la máquina, con versión confirmada por la propia herramienta |
| **Verificado por compilación** | Usado en la compilación real del APK de VIG-003 (dos compilaciones con la misma resolución) |
| **Candidato** | Versión propuesta, sin comprobar por compilación o pendiente de ensayo físico |
| **Pendiente** | Sin decidir o sin resolver. No instalado ni añadido al proyecto |

Ninguna dependencia futura de IA, cámara o almacenamiento (Pigeon, CameraX, MediaPipe, Room, Drift, Riverpod, go_router) se ha añadido al proyecto, y ninguna se declara compatible. **La compilación de VIG-003 no prueba compatibilidad en equipos**: no hay D1 (ver `docs/testing.md`).

## Matriz

| Componente | Versión | Ruta / origen | Estado | Evidencia |
|---|---|---|---|---|
| Flutter SDK | **3.47.6** stable · framework `5fc346839b` · engine `692136cb65` | `D:\dev\flutter` (zip oficial, SHA-256 `a01bb0d26de9…04796`, coincide con `releases_windows.json`) | Verificado por compilación | VIG-002/01, VIG-003/01 |
| Dart | **3.13.5**, el del SDK de Flutter | `D:\dev\flutter\bin\dart` | Verificado por compilación | VIG-002/02, VIG-003/06 |
| Gradle (wrapper) | **9.3.1** · `distributionSha256Sum` `17f27786…6e43` · `gradle-wrapper.jar` oficial 9.3.1 (`b3a875dd…ec13`) | `android/gradle/wrapper/` (versionado). Distribución en `D:\dev\gradle-home` | Verificado por compilación | VIG-003/02, 08 |
| JDK de Gradle | **Temurin 21.0.10+7 LTS** | `D:\Program Files\Eclipse Adoptium\jdk-21` | Verificado (ver «Selección del JDK») | VIG-003/02, 10 |
| Android Gradle Plugin | **9.1.0** (plantilla Flutter 3.47.6) | `android/settings.gradle.kts` (app); `packages/monitoring_engine/android/build.gradle.kts` (plugin) | Verificado por compilación | VIG-003/compilacion-* |
| Kotlin Gradle Plugin / stdlib | **2.4.0** (plantilla). Los scripts de Gradle usan el Kotlin embebido 2.2.21 | Ídem | Verificado por compilación | VIG-003/02, compilacion-*-gradle-* |
| compileSdk / targetSdk | **36 / 36**, fijados explícitamente en `android/app/build.gradle.kts`. El APK reporta `compileSdkVersion='36'` y `targetSdkVersion:'36'` | App | Verificado por compilación. Requisitos de Play: revalidar en VIG-069 | VIG-003/07 |
| minSdk | **26** (el APK reporta `minSdkVersion:'26'`; app y plugin) | App y plugin | **Candidato**: compila, pero sin D3 no se declara probado (Área 07 §5) | VIG-003/07 |
| Android SDK · Platform android-36 · Build-Tools 36.1.0 · Platform-Tools 37.0.1 · cmdline-tools 23.0 | Ver VIG-002 | `D:\dev\android-sdk` | Instalado/verificado. Usados en la compilación | VIG-002/07 |
| NDK | 28.2.13676358 (`flutter.ndkVersion`, que Flutter pasa a Gradle) | `D:\dev\android-sdk\ndk\28.2.13676358` | Instalado. Uso efectivo en la compilación no verificado por separado | VIG-002/07 |
| CMake | 4.1.2 | `D:\dev\android-sdk\cmake\4.1.2` | Instalado. No lo usa la base actual | VIG-002/07 |
| `pubspec.lock` (app) | `cupertino_icons` 1.0.9 · `flutter_lints` 6.0.0 · `plugin_platform_interface` 2.1.8 · `monitoring_engine` 0.1.0 (path) | `pubspec.lock` (versionado; SHA-256 `30245718…cc14`) | Verificado: sin cambios tras dos compilaciones con `--enforce-lockfile` | VIG-003/06, compilacion-*-resumen |
| Pigeon | 29.0.6 (pub.dev) | No añadido. VIG-007/VIG-008 | Candidato | — |
| CameraX | 1.6.2 (última estable en Google Maven) | No añadido. VIG-010 | Pendiente | — |
| MediaPipe Tasks Vision | 1.0.0 (último listado en Google Maven) | No añadido. VIG-011 | Pendiente | — |
| Room | 2.8.5 | No añadido. VIG-012 | Pendiente | — |
| Drift / SQLite | `drift` 2.35.1. `sqlite3_flutter_libs` está en fin de vida (→ `sqlite3` 3.x) | No añadido. VIG-023 | Pendiente | — |
| Riverpod / go_router | `flutter_riverpod` 3.4.3 / `go_router` 18.0.2 | No añadidos. VIG-034/VIG-038 | Pendiente | — |

### Gradle 9.3.1: qué significa

Gradle 9.3.1 es la **versión que usa la plantilla de Flutter 3.47.6** (`templateDefaultGradleVersion` en `packages/flutter_tools/lib/src/android/gradle_utils.dart`). Es también el **límite superior conocido por esa versión del tooling** (`maxKnownAndSupportedGradleVersion = '9.3.1'`), es decir, la versión más alta que Flutter 3.47.6 sabe evaluar en sus comprobaciones de compatibilidad.

Esto no es una declaración de soporte general de Gradle 9.3.1. Lo único comprobado es que **este proyecto compila con Gradle 9.3.1 + AGP 9.1.0 + Kotlin 2.4.0 + JDK 21** en esta máquina (VIG-003). La versión de VIG-002 de este documento lo describía como «máximo conocido y soportado»; queda corregido aquí.

## Selección del JDK

**Mecanismo actual:**
1. `flutter config --jdk-dir "D:\Program Files\Eclipse Adoptium\jdk-21"` (configuración de Flutter del usuario, aplicada en VIG-002).
2. Cuando Flutter compila (`flutter build`), lanza `android\gradlew.bat`, y el daemon de Gradle arranca con `D:\Program Files\Eclipse Adoptium\jdk-21\bin\java.exe`. Esto consta en el log detallado de la compilación, con los daemons detenidos antes ([evidencia VIG-003/10](evidence/VIG-003/10-jdk-gradle-desde-flutter.txt)).
3. Cuando se invoca `android/gradlew` directamente, Gradle usa `JAVA_HOME`, que en usuario y máquina apunta al mismo Temurin 21. `gradlew -version` reporta `Launcher JVM: 21.0.10 (Eclipse Adoptium 21.0.10+7-LTS)` y `Daemon JVM: D:\Program Files\Eclipse Adoptium\jdk-21 (no Daemon JVM specified, using current Java home)` ([evidencia VIG-003/02](evidence/VIG-003/02-gradle-version-jdk.txt)).
4. El proyecto no fija `org.gradle.java.home` ni criterios de toolchain del daemon. Si cambiara `JAVA_HOME` o `jdk-dir`, cambiaría el JDK.

**Evidencia nueva y evidencia histórica:**
- **Histórica (VIG-002, evidencias 03 y 06):** solo `flutter doctor -v` y `java -version`. Probaban qué JDK tiene configurado Flutter, pero **no** el que usa Gradle.
- **Nueva (VIG-003, evidencias 02 y 10):** ejecución real de Gradle, tanto lanzado por Flutter como directamente.

**Java 8:** sigue siendo el primer `java` del PATH. No se usa ni en el camino de Flutter ni en el de Gradle descritos arriba. No se desinstaló ni se movió.

## Cambios de configuración del sistema

### Variables, PATH y Flutter (VIG-002)

Respaldo previo literal en [`VIG-002/00-entorno-previo.txt`](evidence/VIG-002/00-entorno-previo.txt).

| Cambio | Ámbito | Valor |
|---|---|---|
| `ANDROID_HOME` | Variable de usuario (nueva) | `D:\dev\android-sdk` |
| `PUB_CACHE` | Variable de usuario (nueva) | `D:\dev\pub-cache` |
| `GRADLE_USER_HOME` | Variable de usuario (nueva) | `D:\dev\gradle-home` |
| PATH de usuario | Añadidas 3 entradas, 0 eliminadas | `D:\dev\flutter\bin` (al inicio); `D:\dev\android-sdk\platform-tools` y `D:\dev\android-sdk\cmdline-tools\latest\bin` (al final) |
| `jdk-dir` de Flutter | Configuración de Flutter del usuario | `D:\Program Files\Eclipse Adoptium\jdk-21` (antes: sin valor) |

Para revertir: restaurar el PATH de usuario desde la evidencia 00, borrar las tres variables nuevas y ejecutar `flutter config --jdk-dir=""`.

### ACL de `D:\dev` (VIG-002)

- **Por qué:** C: tenía 2,1 GB libres. En D:, la raíz solo concede `(OI)(CI)(RX)` a `BUILTIN\Usuarios` y a `Authenticated Users`, y `(F)` a `Administradores` y `SYSTEM` (observado con `icacls D:\` antes del cambio). El usuario no podía crear carpetas.
- **Qué se hizo:** el responsable ejecutó, en PowerShell como administrador, los comandos que se le indicaron:
  ```powershell
  New-Item -ItemType Directory -Force D:\dev
  icacls D:\dev /grant "DESKTOP-O9J2TLR\Edwin Rueda:(OI)(CI)F"
  ```
  El primer `icacls` indicado (`icacls D:\dev /grant "Edwin Rueda:(OI)(CI)F"`) no dejó el permiso aplicado: después de crear la carpeta, una prueba de escritura dio «Acceso denegado» e `icacls D:\dev` solo mostraba las ACE heredadas. Por eso se indicó la segunda forma, con la cuenta completa.
- **Alcance:** solo `D:\dev` y lo que contiene (herencia `OI`/`CI`). No se modificaron `D:\` ni otras carpetas.
- **Estado actual** ([evidencia VIG-003/09](evidence/VIG-003/09-acl-d-dev.txt)):
  - permiso explícito: `DESKTOP-O9J2TLR\Edwin Rueda:(OI)(CI)(F)`;
  - entradas heredadas de `D:\`: `Usuarios` y `Authenticated Users` en `RX`, `Administradores` y `SYSTEM` en `F`.
- **Estado previo de `D:\dev`:** no existía. El intento del agente de crear `D:\dev\downloads` falló con «Acceso denegado a la ruta de acceso 'dev'», al intentar crear `dev`; esa salida se observó en la sesión, pero no se guardó como archivo de evidencia. No hay una ACL anterior de `D:\dev` que restaurar.
- **Datos que faltan, no registrados y no inventados:**
  - la salida literal de los comandos del responsable;
  - la ACL de `D:\dev` entre su creación y la concesión (no se capturó);
  - si el primer `icacls` llegó a ejecutarse, devolvió error o se aplicó a otra cuenta.
- **Reversión posible (no ejecutada):** en PowerShell como administrador, `icacls D:\dev /remove "DESKTOP-O9J2TLR\Edwin Rueda"` quita el permiso explícito y deja solo las ACE heredadas de `D:\`. Hacerlo impediría a la cuenta escribir en el SDK, las cachés y el repositorio.

## Ubicación del repositorio (VIG-003)

La ruta original `C:\Users\Edwin Rueda\Documents\Diseño de interfaces\mobile-final-interface` contiene «ñ», y hace fallar dos herramientas:
- **`flutter analyze`:** el servidor de análisis LSP sale con código 255 por un mensaje JSON truncado. En la misma ruta `dart analyze` funciona, y en una copia con ruta ASCII `flutter analyze` funciona.
- **AGP 9.1.0:** rechaza la ruta («Your project path contains non-ASCII characters… Please move your project to a different directory»).

Decisión del responsable: **copiar el repositorio a `D:\dev\vigia`** (con `.git` y el trabajo sin commitear, excluyendo solo `build`, `.dart_tool` y `.gradle`), en una ruta ASCII sin espacios y en la misma unidad que las cachés. Así desaparece también el riesgo de compilación incremental de Kotlin entre unidades: no se observó el aviso «different roots» en los logs. La carpeta de C: queda intacta; borrarla es decisión del responsable. No se usó `android.overridePathCheck`. Detalle en [VIG-003/00-incidencias.txt](evidence/VIG-003/00-incidencias.txt).

## Mitigación aplicada solo en la sesión del agente

En la sesión de Claude Code, la JVM no pudo crear sockets AF_UNIX bajo `AppData\Local` («Unable to establish loopback connection»). Lo reproduje con un programa Java mínimo; apunta a una restricción del entorno de ejecución de la sesión. Los comandos de Gradle de esa sesión usaron `JAVA_TOOL_OPTIONS=-Djdk.net.unixdomain.tmpdir=D:\dev\tmp`, solo en el entorno del comando: no está en el sistema ni en el repositorio.

En una terminal propia del responsable no debería hacer falta, aunque no está verificado. Si aparece el mismo error, la misma variable lo resuelve.

## Observaciones abiertas

1. **Sin teléfono Android (D1):** la instalación, el arranque físico y la compatibilidad en equipos de VIG-003 están **pendientes**. Ver `docs/testing.md`.
2. **Emulador no instalado,** por decisión del responsable. EM y P16K pendientes.
3. **Permiso `INTERNET` en el APK debug:** viene del `src/debug/AndroidManifest.xml` de la plantilla (necesario para hot reload/depuración). `src/main/AndroidManifest.xml` no declara permisos. La auditoría del manifiesto fusionado de las variantes reales sin `INTERNET` corresponde a VIG-004.
4. **Telemetría:** no se modificaron las analíticas de Flutter/Dart (decisión del responsable).
5. **Codificación de la evidencia VIG-002:** «Versi¢n» es salida literal de `flutter doctor`.
