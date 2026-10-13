# Vigía — instrucciones comunes del proyecto

Aplican a Claude Code y a Codex. `CLAUDE.md` importa este archivo. Autor del proyecto: Juan José Rueda Viveros.

**Al retomar el trabajo en una sesión nueva**, lee primero `docs/estado-prototipo.md`: estado verificado, commits, pendientes y siguiente acción.

## Plan activo (actualización expresa del usuario, 2026-10-06)

Para la entrega académica, el usuario sustituyó la secuencia de tareas del Área 08 por este **plan por fases**, que es el **plan activo**:

1. Instrucciones del proyecto, base visual e Inicio.
2. Recorrido principal: Preparación, Calibración demostrativa, Monitoreo, alertas, pausa/reanudación, finalización y resumen.
3. Historial persistente y Ajustes.
4. Revisión visual, comprobación de ejecución y APK entregable.

Las fases 1–4 (prototipo DEMO) están aprobadas y publicadas. **Ampliación expresa del usuario (2026-10-12): fase 5A**, cámara frontal real y permisos en la variante normal (solo vista previa CameraX en `packages/monitoring_engine`, puente Pigeon, estados de permiso y cámara). No incluye detección facial, MediaPipe, calibración real, sesiones ni alertas de fatiga; el recorrido DEMO sigue separado y sin permiso CAMERA. **Aprobada por Codex y publicada (2026-10-12).** Guía: `docs/fase5a-camara-permisos.md`.

**Autorización expresa del usuario (2026-10-12): fase 5B**, integración local de MediaPipe Face Landmarker en la variante normal: modelo empaquetado sin Internet, ImageAnalysis junto a la vista previa de 5A, y resultados reales de **presencia facial** (sin rostro, uno, varios) con caducidad. Calibración, sesiones y alertas de fatiga siguen bloqueadas; no se implementan reglas ni alertas de fatiga. La DEMO sigue sin CAMERA ni ejecución del modelo. **Revisiones de Codex desfavorables sobre `3be9bf1`, `c5c0503`, `a935729`, `8f715dd` y `b08cfec` (vigencia y consultas); corregidos.** Guía: `docs/fase5b-mediapipe.md`.

**Cambio expreso del plan (usuario, 2026-10-13): prototipo real experimental por bloques funcionales.** Claude implementa un bloque integrado completo y Codex lo revisa **una vez al final**, sin revisión intermedia de cada corrección. Primer bloque integrado:

1. cierre de las correcciones pendientes de 5B (quinta ronda, sobre `b08cfec`);
2. **fase 5C, «Monitoreo experimental»**: cámara frontal → un rostro → mediciones oculares en Kotlin → calibración → iniciar → cierre ocular sostenido → aviso y tono → finalizar, con una sola sesión, pausa/reanudación y la configuración experimental del Área 05 (`lab-eye-rules-0.1`), decidida en el motor nativo con tiempo monotónico. Sin persistencia real, exportación, backend ni funciones ajenas al recorrido; inferencia local y sin red; el DEMO sigue independiente y su guion no produce señales reales.

Guía: `docs/fase5c-monitoreo-experimental.md`. **Pendiente de la revisión integrada de Codex.**

**Cambio autorizado del flujo (usuario, 2026-10-13):** Codex puede revisar y reparar los errores reproducibles del bloque integrado **5B + 5C**. Claude queda detenido mientras Codex trabaja. Esta autorización sustituye la restricción de revisión sin modificaciones para este bloque: reproducir antes de corregir, añadir regresiones, conservar cambios ajenos y aceptaciones no afectadas, y validar con análisis y pruebas dirigidas. Recompilar/probar Android cuando el cambio lo justifique. No ampliar umbrales, ocultar fallos, añadir funciones ajenas ni convertir pendientes de producción en tareas. Actualizar continuidad y guías; crear commits locales de corrección, sin amend, push ni PR. La validación de las reparaciones propias no equivale a una revisión independiente.

- Solo se trabaja en la fase o bloque que el usuario haya autorizado expresamente. Al terminar el bloque integrado, se detiene el trabajo para la revisión de Codex. **No se avanza a otro bloque por iniciativa propia.**
- La secuencia VIG-001…VIG-072 del Área 08 (`docs/source/Vigia_08_…`) queda **aplazada**. No determina automáticamente la siguiente tarea: VIG-004 y siguientes no se ejecutan salvo petición expresa.
- Siguen vigentes como referencia:
  - PRD (Área 01) y UX (Área 02): comportamiento, textos, estados y restricciones;
  - arquitectura (Área 04), IA (05), datos (06) y QA (07);
  - diseño B5.2: referencia visual en `docs/source/Vigia B5.2 Completo (standalone).html`.

  Si el prototipo simplifica algo de esas fuentes, lo documenta como limitación del prototipo; no lo presenta como cumplido.

### Precedencia

Esta actualización del usuario prevalece sobre las instrucciones anteriores que exijan ramas por tarea, PRs, fichas VIG o seguir VIG-004 por defecto (Área 08 §5, §9 y §10; instrucciones de sesiones previas). Si hay conflicto, rige este archivo y la indicación más reciente del usuario en el chat.

## Colaboración y Git

- **Claude implementa y Codex revisa** cada bloque (fase) terminado. Para el bloque integrado 5B + 5C rige la excepción autorizada arriba: Codex también puede reparar sus hallazgos y Claude permanece detenido. Ninguno presenta la validación de sus propios cambios como revisión independiente.
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
- **La simulación se identifica siempre.** Todo dato o resultado simulado lleva el rótulo visible «DEMO — datos simulados» (RF32). Nunca se presenta como detección real de IA ni como medición de la cámara.
- **Lo experimental también se identifica.** El recorrido real de la variante normal se presenta como «Monitoreo experimental», con valores de laboratorio candidatos, nunca como política de producción ni como ayuda validada para conducir.
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
