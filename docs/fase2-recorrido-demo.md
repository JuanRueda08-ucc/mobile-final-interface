# Vigía · Fase 2: recorrido demostrativo

Guía breve para ejecutar, comprobar y presentar el recorrido de la fase 2 del plan activo (`AGENTS.md`):

**Inicio → Preparación → Calibración → Monitoreo → Pausa/reanudación → Finalizar → Resumen → Inicio.**

Todo lo que muestra este recorrido es **simulado** y lleva el rótulo «DEMO — datos simulados» en cada pantalla y diálogo (RF32). No hay cámara, modelo de IA ni plugin nativo en el recorrido. Lo único real es el tono local de la prueba de sonido y de las alertas.

## Modos de la app

| Definición al compilar | Modo | Qué se ve |
|---|---|---|
| (ninguna) | Real | Inicio con «Estado del motor no comprobado». Preparación bloqueada, sin rótulo DEMO ni rutas del recorrido |
| `--dart-define=VIGIA_DEMO=true` | Recorrido demostrativo | El recorrido completo con datos simulados |
| `--dart-define=VIGIA_DEMO_INICIO=<variante>` | Revisión de Inicio | Una variante fija de P03. Sus acciones muestran un aviso, porque la variante no es una sesión iniciada |

`VIGIA_DEMO=true` y `VIGIA_DEMO_INICIO` no se combinan. La app rechaza esa combinación al arrancar, igual que un valor de `VIGIA_DEMO` distinto de `true` o `false`.

## Ejecutar y compilar

```bash
flutter run --dart-define=VIGIA_DEMO=true
```

```bash
flutter build apk --release --dart-define=VIGIA_DEMO=true
```

El APK queda en `build/app/outputs/flutter-apk/app-release.apk`. Si Gradle falla con «Unable to establish loopback connection», `TEMP` apunta a una ruta demasiado larga para el socket local del JDK: compila con `TEMP` y `TMP` cortos (p. ej., `D:\dev	mp`). Está firmado con la clave de depuración de la plantilla de Flutter; sirve para demostración, no para distribución.

## Guion de presentación (unos 3 minutos)

1. **Inicio (P03).** Rótulo DEMO y «Aún no tienes sesiones». Pulsa **Preparar sesión**.
2. **Preparación (P04).** La vista previa dice «DEMO · sin cámara». Hay seis comprobaciones. Iniciar queda bloqueado por «Calibración pendiente · Prueba de sonido pendiente».
   - Opcional: en **Simulación DEMO**, apaga «Ojos evaluables» para ver la causa «Rostro detectado, pero no puedo evaluar los ojos». Después vuelve a encenderlo.
3. **Calibrar → Calibración (P05).** Pulsa **Comenzar**. Aparece «Recogiendo referencia», sin porcentaje. En el panel, elige un **Rechazo**: se ven la causa y **Reintentar**. Reintenta, pulsa **Aceptar referencia** y después **Usar referencia aceptada**.
4. **Sonido.** Pulsa **Probar sonido**: suena un tono en el teléfono. **Lo escuché** solo se habilita tras la reproducción. Confírmalo.
5. **Cambié la posición** (opcional). La referencia deja de ser aplicable e Iniciar vuelve a bloquearse. Hay que recalibrar.
6. **Iniciar monitoreo → Monitoreo (P06).** Aparece «Iniciando…», sin ID. Al confirmarse, se asigna `S-DEMO-0001`. Guion de señales, por tiempo activo, sin contar pausas:

   | Tiempo | Qué se ve |
   |---|---|
   | 0–2 s | Inicializando |
   | 8 s | Advertencia, con tono |
   | 20 s | **Cierre ocular prolongado**, con tono y sin pedir respuesta |
   | 30 s | No puedo evaluar |
   | 34 s | Recuperando medición |
   | 37 s | Sin señales persistentes |

   El ciclo se repite cada 43 s.
7. **Pausar.** Aparece «Pausando…» y después «Monitoreo pausado / Evaluación suspendida», con el mismo ID. El tiempo monitoreado se detiene. **Reanudar**: la medición vuelve a inicializarse.
8. **Volver (‹).** Abre D05. Con **Volver al inicio**, Inicio muestra «Sesión en curso» con el mismo ID y Preparar bloqueado. **Volver al monitoreo** abre la misma sesión.
9. **Finalizar.** Abre D02. **Continuar sesión** la conserva. **Finalizar** muestra «Finalizando…» y abre el **Resumen (P07)**, calculado desde los eventos de esa sesión: cobertura, tiempos, episodios y avisos sonoros.
10. **Volver al inicio.** Inicio muestra el último resumen de esta ejecución.

## Qué es simulado y qué no

- **Simulados:**
  - las condiciones del equipo (permiso, cámara, modelo, rostro, ojos);
  - el resultado de la calibración;
  - la confirmación del «motor» (unos 700 ms);
  - las señales y alertas, que salen de un guion fijo (`lib/features/monitoring/domain/demo_script.dart`).
  
  Esos instantes no son W, C, Tclose, Eend, Rrepeat, Tstale ni Krecover, que siguen pendientes en el Área 05.
- **Reales:**
  - el tono local (`ToneGenerator` por el canal `vigia/demo_sound`);
  - el tiempo monotónico de la sesión;
  - la lógica de bloqueos, órdenes, identidad y resumen.
- **En memoria:** la referencia, la sesión y el resumen se pierden al cerrar la app. La persistencia y el Historial llegan en la fase 3.
- **Sin permisos:** no se pide ningún permiso de Android, y no hay red, micrófono, GPS ni cuentas.

## Comprobación

```bash
flutter test
```

Pruebas propias de la fase 2:

| Ruta | Qué cubre |
|---|---|
| `test/monitoring/` | Dominio con tiempo controlado |
| `test/demo/demo_flow_test.dart` | Recorrido, bloqueos, diálogos, rutas, semántica y movimiento reducido |
| `test/demo/demo_layout_test.dart` | Matriz de 21 estados × claro/oscuro × 360/100 %, 320/200 % y 412/200 %, con el comprobador de contraste |

Los registros de cobertura del contraste quedan en `build/contrast_coverage/fase2_*.txt`. En los diálogos, solo se exige el contraste del diálogo: el contenido bajo el velo está inactivo.

Los renderizados de referencia están en `test/goldens/fase2/` y se generan con `flutter test --update-goldens test/goldens/fase2_render_test.dart`.

## Pendiente (no comprobado)

- Instalación y recorrido en un teléfono Android físico: no hay equipo D1 (`docs/testing.md`).
- **Audio físico:**
  - si el tono se oye a un volumen adecuado;
  - el comportamiento con No molestar, Bluetooth y llamadas;
  - la latencia decisión→sonido.
  
  En pruebas, el reproductor se sustituye por uno falso.
- TalkBack real (orden, foco de diálogos, anuncios). Solo se comprobaron la semántica y las acciones en `flutter test`.
- No representados en la demo:
  - «Confirmación pendiente» tras 5 s, porque el motor simulado siempre confirma;
  - los rechazos de inicio, pausa, reanudación o cierre;
  - la desconexión UI–motor;
  - la repetición de avisos (Rrepeat).
- El permiso real (P02) y la bienvenida (P01) quedan fuera de esta fase.
