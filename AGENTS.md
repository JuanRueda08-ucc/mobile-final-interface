# Vigía — instrucciones comunes del proyecto

Aplican a Claude Code y a Codex. `CLAUDE.md` importa este archivo. Autor del proyecto: Juan José Rueda Viveros.

## Plan activo (actualización expresa del usuario, 2026-10-06)

Para la entrega académica, el usuario sustituyó la secuencia de tareas del Área 08 por este **plan por fases**, que es el **plan activo**:

1. Instrucciones del proyecto, base visual e Inicio.
2. Recorrido principal: Preparación, Calibración demostrativa, Monitoreo, alertas, pausa/reanudación, finalización y resumen.
3. Historial persistente y Ajustes.
4. Revisión visual, comprobación de ejecución y APK entregable.

- Solo se trabaja en la fase que el usuario haya autorizado expresamente. Al terminarla, se detiene el trabajo para la revisión de Codex. **No se avanza a otra fase por iniciativa propia.**
- La secuencia VIG-001…VIG-072 del Área 08 (`docs/source/Vigia_08_…`) queda **aplazada**. No determina automáticamente la siguiente tarea: VIG-004 y siguientes no se ejecutan salvo petición expresa.
- Siguen vigentes como referencia:
  - PRD (Área 01) y UX (Área 02): comportamiento, textos, estados y restricciones;
  - arquitectura (Área 04), IA (05), datos (06) y QA (07);
  - diseño B5.2: referencia visual en `docs/source/Vigia B5.2 Completo (standalone).html`.

  Si el prototipo simplifica algo de esas fuentes, lo documenta como limitación del prototipo; no lo presenta como cumplido.

### Precedencia

Esta actualización del usuario prevalece sobre las instrucciones anteriores que exijan ramas por tarea, PRs, fichas VIG o seguir VIG-004 por defecto (Área 08 §5, §9 y §10; instrucciones de sesiones previas). Si hay conflicto, rige este archivo y la indicación más reciente del usuario en el chat.

## Colaboración y Git

- **Claude implementa y Codex revisa** cada bloque (fase) terminado. Claude no declara aprobada una revisión de Codex.
- Se trabaja en la rama `main`, con commits por fase o por corrección de revisión. Las PRs no son obligatorias.
- Un bloque revisado y aprobado puede subirse a `main` en `origin` sin otra ceremonia. No se hace push de trabajo sin revisar salvo petición del usuario.
- No se reescribe historia publicada (sin `--amend` ni `push --force` sobre commits subidos) ni se borra trabajo previo.
- Ruta de trabajo: `D:\dev\vigia`, en ASCII y sin espacios. AGP y `flutter analyze` fallan con rutas no ASCII (ver `docs/toolchain.md`).

## Documentación

- Solo se crea la documentación necesaria para **desarrollar, comprobar y presentar** la aplicación.
- No se crean fichas, registros ni evidencia de ceremonia que no aporten a esos fines.
- Los documentos existentes (`docs/source/`, registros de VIG-001, `docs/toolchain.md`, `docs/testing.md`, evidencias) se conservan. Las fuentes de `docs/source/` no se modifican.

## Producto y honestidad del prototipo

- Android primero, con interfaz Flutter (`lib/`) y un único plugin local Kotlin (`packages/monitoring_engine`).
- **La simulación se identifica siempre.** Mientras no haya cámara ni IA reales, todo dato o resultado simulado lleva el rótulo visible «DEMO — datos simulados» (RF32). Nunca se presenta como detección real de IA ni como medición de la cámara.
- Restricciones del producto:
  - no se usan «Seguro», «Puedes conducir» ni porcentajes de fatiga (RF10, UX07);
  - no se añaden backend, cuentas, GPS ni micrófono;
  - las alertas no exigen respuesta.
- Se conservan los IDs de pantalla, diálogo y requisito de las fuentes (P01–P18, D01–D08, RF, UX) en el código y la documentación cuando ayuden a la trazabilidad.

## Comprobación mínima de cada fase

Antes de entregar a revisión:
- `flutter analyze`;
- `flutter test`;
- `python tools/spec_registry.py check`;
- renderizados de las pantallas nuevas, en tema claro y oscuro.

Se informa lo que no se ejecutó (por ejemplo, el teléfono D1 ausente) en vez de darlo por aprobado.
