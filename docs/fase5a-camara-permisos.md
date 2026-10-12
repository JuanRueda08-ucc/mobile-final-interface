# Vigía · Fase 5A: cámara frontal real y permisos

**Autorizada por el usuario:** 2026-10-12. **Estado:** implementada, pendiente de revisión de Codex. No integra MediaPipe.

## Alcance

En la **variante normal** (`com.juanrueda.vigia`, «Vigía»):

- Inicio ofrece «Comprobar cámara», que abre la pantalla **Cámara frontal** (`/camara`).
- Esa pantalla explica el permiso (texto de P02) y lo solicita **solo al pulsar «Permitir cámara»**.
- Con el permiso, abre la **vista previa real** de la cámara frontal (CameraX, solo el caso de uso Preview).
- Muestra «Cámara disponible» y «Detección de fatiga pendiente». Calibrar e Iniciar monitoreo siguen deshabilitados.

**Fuera de alcance:** detección facial, MediaPipe, calibración real, sesiones, alertas de fatiga, fotografía, grabación y almacenamiento de imágenes.

**El recorrido DEMO no cambia.** La app DEMO (`com.juanrueda.vigia.demo`) no declara ni solicita CAMERA, no muestra la ruta `/camara` y no abre ninguna cámara.

## Arquitectura

| Pieza | Archivo | Papel |
|---|---|---|
| Contrato Pigeon | `packages/monitoring_engine/pigeons/monitoring_api.dart` | `FrontCameraHostApi` (consultar/solicitar permiso, abrir ajustes, abrir/cerrar vista previa) y `FrontCameraFlutterApi` (cierre decidido en Kotlin) |
| Código generado | `lib/src/monitoring_api.g.dart`, `android/.../MonitoringApi.g.kt` | Versionado; no se edita a mano |
| Puente Dart | `packages/monitoring_engine/lib/src/front_camera.dart` | Interfaz `FrontCameraBridge` y su implementación Pigeon |
| Permiso | `android/.../camera/FrontCameraHost.kt` | Solicitud con `requestPermissions`; las peticiones simultáneas comparten una sola |
| Cámara | `android/.../camera/FrontCameraPreview.kt` | **Único propietario** de la cámara en el proceso |
| Reglas puras | `android/.../camera/CameraRules.kt` | Permiso tras solicitud, errores de CameraX, giro y `PreviewGate` |
| Controlador | `lib/features/camera/front_camera_controller.dart` | Estados, generaciones y tokens |
| Pantalla | `lib/features/camera/front_camera_screen.dart` | Componentes B5.2 existentes (`CheckGroup`, `StatusCard`, `VigiaButton`) |

### Ciclo de vida de la cámara

- **Apertura.** Cada apertura crea su propio `LifecycleOwner`, que pasa a RESUMED al abrir y a DESTROYED al cerrar. La vista previa se entrega por `SurfaceProducer`, como textura de Flutter.
- **«Disponible».** Se responde solo cuando CameraX informa `CameraState.OPEN`; si no llega en 10 s, la apertura falla con `openTimeout`. El permiso concedido no basta.
- **Liberación.** La cámara se libera:
  - al salir de la pantalla (`dispose` → `closeFrontPreview`);
  - al dejar de verse la app, por dos vías independientes: `AppLifecycleListener.onHide` en Dart y `onStop` de la Activity en Kotlin;
  - al desconectarse la Activity o el plugin.
- **Al volver.** `onShow` consulta de nuevo el permiso y, si sigue concedido, reabre la vista. Esto cubre también la vuelta desde los ajustes del teléfono.
- **Peticiones repetidas o tardías.**
  - Cada apertura lleva un token único en el proceso.
  - En Kotlin, una apertura nueva sustituye a la anterior, que responde `superseded`; el cierre de un token antiguo no cierra la petición vigente.
  - En Dart, cada visita, salida o paso a segundo plano incrementa una generación. Una respuesta de otra generación se descarta y, si había abierto la cámara, se cierra.
  - Los toques repetidos durante una solicitud o apertura no crean otra.

### Estados

| Fase (Dart) | Origen |
|---|---|
| `explain` | Sin permiso y sin solicitud en esta visita |
| `requesting` | Diálogo de Android visible |
| `denied` | Rechazado; Android permite repetir (ER01) |
| `requiresSettings` | Rechazado y Android ya no muestra la solicitud: «Abrir ajustes» (UX02.CA2). Al volver sin permiso, el bloqueo se conserva |
| `opening` | Apertura en curso |
| `available` | CameraX informó OPEN |
| `noFrontCamera` | `hasCamera(DEFAULT_FRONT_CAMERA)` es falso |
| `inUse` / `disabled` / `failed` | Error de CameraX: en uso (ER02), desactivada por política, o sin causa determinada (ER03) |
| `suspended` | App en segundo plano; la cámara está liberada |

**Limitación conocida.** Si en la primera solicitud el usuario descarta el diálogo sin responder, Android tampoco ofrece explicación. Ese caso se informa como `requiresSettings`, aunque el permiso se pueda volver a pedir desde los ajustes.

**Giro y espejo.**
- Kotlin informa el giro de `SurfaceRequest.TransformationInfo`. Si la textura de Flutter ya gira la imagen (`handlesCropAndRotation`), informa 0.
- El espejo sale de `isMirroring`.
- El giro se calcula al abrir. La Activity no se recrea al rotar, así que un giro posterior no se reajusta hasta reabrir.

## Separación de manifiestos

`android/app/build.gradle.kts` añade a cada variante un manifiesto superpuesto (`androidComponents.onVariants`):

- **normal** (`src/normal/AndroidManifest.xml`): `CAMERA`, más `android.hardware.camera` y `android.hardware.camera.front` con `required=false`. Sin ellas, aapt deduciría la cámara trasera como obligatoria;
- **DEMO** (`src/demo/AndroidManifest.xml`): retira el servicio interno de CameraX `MetadataHolderService`, que viene deshabilitado y no exportado.

Manifiestos finales comprobados con `aapt dump badging` y `xmltree`:

| APK | Permisos | Funciones | Menciones «camera» en el manifiesto |
|---|---|---|---|
| normal | `CAMERA`, `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` | `camera` y `camera.front` no obligatorias | 6 (permiso, 2 funciones, servicio de CameraX) |
| DEMO | `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`, igual que el DEMO de la fase 4 | ninguna de cámara | **0** |

No se añadieron micrófono, ubicación, red ni servicios en segundo plano. `INTERNET` aparece solo en el APK debug, por la plantilla de Flutter.

## Regenerar Pigeon

```bash
cd packages/monitoring_engine
dart run pigeon --input pigeons/monitoring_api.dart
dart format lib pigeons
```

## Dependencias efectivas

| Componente | Versión | Comprobación |
|---|---|---|
| Pigeon (dev del plugin) | **29.0.8** exacta | Genera Kotlin con `suspend`, lo que exige corrutinas |
| CameraX `camera-core`, `camera-camera2`, `camera-lifecycle` | **1.6.2** exacta, última estable de Google Maven (2026-08-26) | Resueltas a 1.6.2, más `camera-camera2-pipe` 1.6.2 |
| `kotlinx-coroutines-android` | **1.11.0** exacta | Resuelta a 1.11.0, por encima de la 1.9.0 que pide CameraX |
| Transitivas observadas | `androidx.core` 1.13.1 y `lifecycle-runtime` 2.7.0 | — |

Todas compilan en debug y release con AGP 9.1.0, Kotlin 2.4.0, Gradle 9.3.1, JDK 21 y compileSdk 36.

**Entorno.** En esta sesión Gradle fallaba al arrancar con «Unable to establish loopback connection», porque el `TMP` de `C:` estaba casi lleno (2 GB libres). Se compila con `TMP`/`TEMP` en `D:\dev\tmp\jtmp`.

## Pruebas

### Con dobles (sin cámara real)

- **`test/camera/front_camera_controller_test.dart`** (21 pruebas, con `FakeFrontCameraBridge`):
  - permiso: explica sin solicitar, concedido, rechazado, ajustes y su conservación al volver, solicitud compartida, revocación y permiso ausente al abrir;
  - estado de cámara para cada resultado de apertura, y Reintentar;
  - aperturas repetidas, salida y segundo plano durante la apertura (la respuesta tardía se cierra y no reactiva la vista), reapertura, cierre nativo de un token antiguo o vigente, desecho del controlador y tokens únicos.
  - **Detección:** sin la comprobación de generación y token de `_open`, fallan 2 de estas pruebas («salir durante la apertura…» y «segundo plano durante la apertura…»).
- **`test/camera/front_camera_screen_test.dart`** (8 pruebas):
  - Inicio normal ofrece «Comprobar cámara» sin pedir permiso;
  - estado disponible con Calibrar e Iniciar deshabilitados y sin rótulo DEMO;
  - sin cámara frontal; Abrir ajustes;
  - volver a Inicio libera la cámara;
  - segundo plano libera y reabre;
  - la ruta `/camara` solo existe en la variante normal, y las vistas de revisión no la ofrecen.
- **`CameraRulesTest.kt`** (6 pruebas JVM): mapeo de permiso y de errores de CameraX, giro, tamaño y `PreviewGate`, incluido que el cierre de un token antiguo no cierra la vista vigente.
- **Renderizados** `test/goldens/fase5a/`: 8 estados × claro/oscuro, a 360 px y texto al 100 %. La textura se dibuja vacía en la prueba. Además se actualizaron los 4 renderizados de P03 «motor no comprobado», que ahora muestran la entrada a la cámara.

### Ejecución real en el emulador

**Entorno:** AVD `vigia_pixel` (Pixel 8, Android 16 / API 36, x86_64).

**Fuente de cámara:**
- La AVD tiene `hw.camera.front=none`, y con ella se probó la ausencia de cámara frontal.
- Para abrir la cámara, `hw.camera.front` se cambió temporalmente a `emulated`: la escena sintética del emulador, no una webcam. Después se restauró `none`.
- **Esto no acredita el funcionamiento en D1 ni con una cámara física.**

**APK:** `vigia-normal-fase5a-release.apk`, instalado con `adb install -r` sin borrar datos. Interacción mediante `uiautomator`/`input tap`. Los clientes de cámara se leyeron con `dumpsys media.camera`.

| Paso | Resultado |
|---|---|
| Entrar desde Inicio | Explicación de P02; no aparece ningún diálogo hasta pulsar |
| «Permitir cámara» → Don’t allow | «Cámara sin permiso»; se puede repetir |
| Segundo rechazo | «Android ya no muestra la solicitud…» y «Abrir ajustes» |
| Abrir ajustes → volver sin conceder | Se conserva el bloqueo de ajustes |
| Conceder en ajustes → volver, con `front=none` | Permiso «Concedido»; «Abriendo…» y después «Cámara frontal no encontrada» (CameraX agotó sus reintentos de inicialización en unos 5 s) |
| `front=emulated`: entrar | Vista previa derecha, «Disponible», «Cámara disponible». `media.camera`: cliente activo `com.juanrueda.vigia` |
| Volver a Inicio | 0 clientes activos |
| Reabrir | Disponible otra vez |
| HOME (segundo plano) | 0 clientes; al volver, se reabre y queda disponible |
| Ráfaga de 7 entradas y 6 salidas, más 2 toques extra | Una sola conexión al servicio de cámara, «Disponible» al final, 0 clientes tras salir, sin errores en logcat |
| `pm revoke` con la vista abierta | Android termina el proceso, 0 clientes; al reabrir, explicación del permiso |
| Diálogo → «While using the app» | Disponible |
| Modo noche del emulador | Tema oscuro y la vista sigue activa (restaurado después) |
| App DEMO (`adb install -r`) | Sin CAMERA en `dumpsys package`; historial de la fase 4 conservado (S-DEMO-0003 interrumpida); Preparación simulada; ninguna conexión de la app DEMO a la cámara |

**Capturas:** 12, en `D:\dev\vigia-entrega\capturas\fase5a\`.

## No comprobado

- **Teléfono D1 y cualquier cámara física:**
  - imagen real de un rostro;
  - giro y espejo en un sensor real;
  - rotación del teléfono con la vista abierta.
- **Cámara ocupada por otra app (ER02) y cámara desactivada por política.** Solo se cubren con dobles y con el mapeo de errores.
- **Interruptor de privacidad de cámara de Android 12+.**
- **Descarte del diálogo sin responder** (limitación descrita arriba).
- **TalkBack.**
