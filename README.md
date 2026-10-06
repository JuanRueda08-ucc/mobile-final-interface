# Vigía

Aplicación Android (Flutter + motor Kotlin local) para observar señales oculares relacionadas con somnolencia, emitir avisos locales y registrar sesiones. Autor del proyecto: Juan José Rueda Viveros. «Vigía» es un nombre provisional.

> **Estado actual: base técnica (VIG-003).** La app solo identifica la base y comprueba el registro del plugin nativo. **No** usa la cámara, **no** ejecuta IA, **no** crea sesiones ni emite alertas, y no debe usarse para monitorear la conducción.

## Estructura

| Ruta | Contenido |
|---|---|
| `lib/`, `test/` | App Flutter (`vigia`, applicationId/namespace `com.juanrueda.vigia`) |
| `android/` | Host Android y wrapper de Gradle 9.3.1 |
| `packages/monitoring_engine/` | Único plugin local Kotlin (`com.juanrueda.monitoring_engine`), dependencia `path` |
| `docs/source/` | Especificaciones originales (Áreas 01–08 y HTML B5.2), registradas en `docs/spec-index.json` |
| `docs/` | Registros de VIG-001, `toolchain.md`, `testing.md`, decisiones y evidencia |
| `tools/` | Validador de la especificación y script de compilación de VIG-003 |

## Entorno

Versiones y rutas en [`docs/toolchain.md`](docs/toolchain.md): Flutter 3.47.6 (Dart 3.13.5), JDK Temurin 21, Android SDK 36, Gradle 9.3.1, AGP 9.1.0, Kotlin 2.4.0. El repositorio debe estar en una ruta **ASCII sin espacios** (actualmente `D:\dev\vigia`), porque AGP y `flutter analyze` fallan con rutas no ASCII en Windows.

## Comandos verificados (VIG-003)

```bash
flutter pub get --enforce-lockfile
flutter analyze
flutter test
(cd packages/monitoring_engine && flutter test)
(cd android && ./gradlew :monitoring_engine:testDebugUnitTest)
flutter build apk --debug
python tools/spec_registry.py check
```

Instalar y arrancar en un teléfono Android **no está verificado todavía**: no hay equipo D1 disponible (ver [`docs/testing.md`](docs/testing.md)).
