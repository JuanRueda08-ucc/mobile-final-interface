# Vigía · Registro de equipos y entornos de prueba

**Creado en:** VIG-002 (Área 08, H00) · **Fecha:** 2026-10-05, America/Bogota
**Fuente de los perfiles:** Área 07 §5 (`docs/source/Vigia_07_Plan_de_Pruebas_Calidad_y_Distribucion_v1.0.md`).
**Evidencia de la comprobación:** [`docs/evidence/VIG-002/04-flutter-devices.txt`](evidence/VIG-002/04-flutter-devices.txt) y [`05-adb-version.txt`](evidence/VIG-002/05-adb-version.txt)

Este registro contiene solo equipos **realmente disponibles y comprobados**. Un perfil sin equipo asignado queda **pendiente** y no cuenta como equipo probado (Área 07 §5). No se inventan modelos ni versiones. Ningún ensayo QA se ha ejecutado: todos siguen `notRun`.

## Perfiles de equipo (Área 07 §5)

| Perfil | Requisito del plan | Equipo asignado | Estado | Ensayos que bloquea |
|---|---|---|---|---|
| D1 | Teléfono Android físico de referencia, cámara frontal y audio funcionales | — | **Pendiente: no hay teléfono Android disponible** | Instalación de VIG-003; H01 completo (VIG-010–VIG-014); recorridos, tiempos, Q/calibración, persistencia y duración |
| D2 | Teléfono físico de otro fabricante y capacidad distinta de D1 | — | Pendiente | Campaña de compatibilidad (se exigen al menos dos fabricantes) |
| D3 | Teléfono físico con la versión Android más antigua que se quiera admitir | — | Pendiente | Validar minSdk 26 candidato; sin D3 no se declara esa versión probada |
| D4 | Teléfono físico con Android 14 o posterior, preferiblemente del target | — | Pendiente | Servicio camera, permisos y continuidad (QA36) |
| P16K | Entorno Android de 16 KB con las librerías del paquete real (puede ser emulador) | — | Pendiente (emulador no instalado) | QA40, RL04, VIG-058 |
| EM | Emuladores de minSdk candidato y fronteras API 31/33/34/target | — | Pendiente (no instalado por decisión del responsable el 2026-10-05) | UI/permisos/esquemas complementarios. No sustituye D1–D4 |

Un teléfono puede cubrir varios perfiles si cumple sus condiciones (Área 07 §5).

## Comprobación realizada el 2026-10-05

| Comando | Resultado |
|---|---|
| `adb devices -l` (platform-tools 37.0.1) | Lista vacía: ningún dispositivo Android conectado ni autorizado |
| `flutter devices` | 3 dispositivos, ninguno Android: `windows` (desktop), `chrome` y `edge` (web). No corresponden a ningún perfil D1–D4/P16K/EM |

Observación: solo se detectó un iPhone emparejado por Bluetooth con el equipo de desarrollo. No aplica a ningún perfil, porque iOS queda fuera de V1 (Área 01 §13) y no puede ejecutar la variante Android.

## Estado tras VIG-003 (2026-10-05)

VIG-003 compiló el APK debug `com.juanrueda.vigia` 0.1.0 (1) con minSdk 26 y targetSdk 36. Su instalación, su arranque físico y la compatibilidad en equipos siguen **pendientes**, porque no hay D1. VIG-003 no se cierra hasta instalar ese APK, o uno equivalente reconstruido desde el mismo lockfile, en D1 y comprobar el arranque (Área 08 VIG-003, «Cierre»).

## Datos que se registrarán por equipo (Área 07 §5)

Cuando se asigne un equipo, su fila incluirá:
- deviceId de ensayo;
- fabricante/modelo, Android/API, buildFingerprint, parche de seguridad, ABI y tamaño de página;
- RAM reportada, viewport lógico/densidad y tasa de refresco real;
- cámara/resolución/fps reales;
- volumen/canal/salida de audio, DND, ahorro de batería y estado térmico disponible;
- montaje y fuente de alimentación.

**No** se registrarán IMEI, número telefónico ni cuenta personal. Los valores se tomarán de `adb shell getprop` y de mediciones reales, no de fichas comerciales.

## Para habilitar D1

1. Teléfono Android físico con cámara frontal y audio funcionales.
2. Activar *Opciones de desarrollador* y *Depuración por USB*.
3. Instalar el driver USB del fabricante, si Windows no lo reconoce.
4. Conectar por USB, autorizar la huella RSA en el teléfono y comprobar con `adb devices -l` y `flutter devices`.
5. Registrar el equipo en la tabla, con evidencia en `docs/evidence/`.

## Entornos (Área 07 §4) disponibles hoy

| Entorno | Estado |
|---|---|
| Host Dart/Kotlin | Dart 3.13.5 disponible (Flutter 3.47.6). Kotlin/Gradle se resolverán por proyecto en VIG-003 |
| Widget Flutter | Disponible cuando exista la app (VIG-003) |
| Emulador Android | No instalado (pendiente EM/P16K) |
| demo / labReal / candidateReal | Se definen en VIG-004 |

La ruta definitiva de la evidencia de ejecuciones sigue abierta (`qa/runs/` frente a `docs/evidence/`, OI-06) y se decide en VIG-006.
