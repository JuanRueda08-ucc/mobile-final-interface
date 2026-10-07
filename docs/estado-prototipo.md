# Vigía · Estado del prototipo

Resumen para retomar el trabajo en una sesión nueva. Plan activo y reglas: `AGENTS.md`. Ejecución y guion de la fase 2: `docs/fase2-recorrido-demo.md`. Entorno: `docs/toolchain.md`.

**Actualizado:** 2026-10-06.

## Fases

| Fase | Estado | Commits |
|---|---|---|
| 1. Instrucciones, base visual e Inicio (P03) | Aprobada por Codex y subida a `origin/main` | hasta `f4f62bc` |
| 2. Recorrido demostrativo (P04–P07, D01/D02/D05) | Aprobada por Codex y subida a `origin/main` | `e7a2381`, `a211c5c`, `3ff7707`, `f771d34`, `26fe51a` |
| 3. `applicationId` demo separado, persistencia, Historial y Ajustes | No iniciada; requiere autorización expresa | — |
| 4. Comprobación final y entrega | No iniciada | — |

Las revisiones de las fases 1 y 2 están cerradas. La fase 2 se aprobó dentro del alcance del prototipo, con las limitaciones de «No comprobado». La fase 3 no empieza sin autorización expresa del usuario.

## Correcciones de la última revisión de la fase 2 (aprobadas en `26fe51a`)

1. **Sonido tardío.** Una respuesta del tono de alerta que llega después de confirmar una pausa o de pedir el cierre ya no registra `soundPlayed`/`soundFailed`, aunque la sesión se haya reanudado antes (`_alertEpoch` en `demo_session_controller.dart`).
2. **Calibración sin permiso, cámara o modelo.** La ruta `/preparacion/calibracion` redirige a Preparación si no se puede calibrar, y se reevalúa al cambiar esas condiciones. `begin`, `simulateAccepted` y `acceptCalibration` también lo comprueban; si se pierde una condición durante la adquisición, el intento se detiene sin referencia.
3. **Título «Calibración» a 320/200 %.** El título del encabezado usa `VigiaText` y se parte por sílabas («Calibra-ción»), sin dejar una letra sola.

Regresiones: `test/monitoring/demo_session_controller_test.dart`, `test/demo/demo_flow_test.dart`. Las reproducciones de Codex (`build/review/fase2_review_test.dart`) pasan.

## Comprobado

- `flutter analyze`: sin problemas.
- `flutter test`: todo pasa (403 pruebas).
- `python tools/spec_registry.py check`: OK.
- Renderizados de la fase 2 regenerados (`test/goldens/fase2/`); cambian solo los seis de P05 a 320/200 %.
- APK demo: `flutter build apk --release --dart-define=VIGIA_DEMO=true`.

## No comprobado

- Sin teléfono D1: no hay instalación Android, ni audio físico, ni TalkBack real.
- La simulación se rotula siempre «DEMO — datos simulados»; no hay cámara ni IA reales.

## Siguiente acción

Esperar la autorización expresa de la fase 3: `applicationId` demo separado, persistencia, Historial y Ajustes.
