# Vigía · Estado del prototipo

Resumen para retomar el trabajo en una sesión nueva. Plan activo y reglas: `AGENTS.md`. Guías: `docs/fase2-recorrido-demo.md` (recorrido) y `docs/fase3-historial-ajustes.md` (app DEMO, historial y Ajustes). Entorno: `docs/toolchain.md`.

**Actualizado:** 2026-10-06.

## Fases

| Fase | Estado | Commits |
|---|---|---|
| 1. Instrucciones, base visual e Inicio (P03) | Aprobada por Codex y subida a `origin/main` | hasta `f4f62bc` |
| 2. Recorrido demostrativo (P04–P07, D01/D02/D05) | Aprobada por Codex y subida a `origin/main` | `e7a2381`, `a211c5c`, `3ff7707`, `f771d34`, `26fe51a` |
| 3. App DEMO separada, persistencia, Historial y Ajustes | Implementada; revisada por Codex con dos hallazgos (P1, P2), ya corregidos. **Pendiente de nueva revisión**. Solo local, sin subir | `7481d87`, `07528db`, `96bf5e9`, `f9b4828`, `9d54956` y el commit de correcciones que sigue |
| 4. Comprobación final y entrega | No iniciada; requiere autorización expresa | — |

Las revisiones de las fases 1 y 2 están cerradas, dentro del alcance del prototipo y con las limitaciones de «No comprobado». La fase 4 no empieza ni se sube la fase 3 hasta que Codex la revise.

## Fase 3 (pendiente de revisión)

| Commit | Bloque |
|---|---|
| `07528db` | App DEMO separada. Gradle deriva `com.juanrueda.vigia.demo` («Vigía DEMO») de `VIGIA_DEMO`; la normal sigue siendo `com.juanrueda.vigia` («Vigía»). Añade el canal `vigia/app` y la exclusión de copias de seguridad |
| `96bf5e9` | Historial DEMO con Drift/SQLite (`vigia_history_demo_v1.sqlite`) y su repositorio, separado del controlador y de los widgets |
| `f9b4828` | Arranque coherente con el applicationId; el recorrido guarda y lee del repositorio; registro interrumpido; P08, P09, P12 y P13; pruebas y renderizados |

Decisiones y límites (detalle en `docs/fase3-historial-ajustes.md`):

- **Esquema.** Es un subconjunto DEMO de Área 06 §6: sin modelo, política ni hashes inventados; los tiempos se calculan desde los hechos; IDs `S-DEMO-NNNN`.
- **Cierre.** Se guarda una sola vez. Si la app se cierra sin cierre confirmado, al reabrirla la sesión queda **Interrumpida**: no se reanuda, no tiene fin ni totales, y el último registro es el último hecho guardado.
- **Preferencias.** Tema y movimiento reducido se guardan y se aplican; la reducción de movimiento de Android se respeta siempre. El patrón de sonido solo cambia si se guardó y obliga a repetir la prueba de sonido.
- **No implementado:**
  - P10, P11 y P14–P18;
  - exportación, borrado y retención;
  - D03, D04 y D06–D08.
  
  **OI-08 sigue abierto** (RF27.CA2 sin tocar).
- **Referencia de calibración.** Sigue en memoria: tras reabrir la app hay que calibrar de nuevo.

## Correcciones de la revisión de la fase 3 (pendientes de revisión)

1. **P1 · segundo guardado de preferencias.** El INSERT omitía `singleton`, que SQLite trata como rowid (INTEGER PRIMARY KEY). En la segunda escritura proponía `singleton=2` y el CHECK la rechazaba (`SqliteException(275)`) antes de llegar al conflicto. Ahora se fija `singleton=1`.
2. **P2 · operaciones simultáneas.** `PreferencesController` encola las escrituras en el orden pedido, y cada cambio se aplica sobre las últimas preferencias guardadas:
   - tema y movimiento se ven mientras se guardan; el patrón cambia solo al guardarse;
   - un fallo retira su cambio y se informa como «Preferencia no guardada», sin perder lo ya guardado. Antes, un tema no guardado quedaba aplicado;
   - al terminar, memoria, interfaz y SQLite coinciden.

Regresiones:

- `test/history/preferences_persistence_test.dart`, con SQLite en disco, conexiones nuevas y escrituras liberadas por la prueba:
  - patrón y tema en ambos órdenes;
  - combinaciones;
  - fallos;
  - respuesta tardía de la prueba con el patrón anterior;
  - alerta siguiente con el patrón guardado.
- `test/demo/fase3_flow_test.dart`: «Guardar» de Sonido por semántica, tras otra preferencia ya guardada, en claro y oscuro.

**Detección de los defectos.** Con el código anterior, las 7 regresiones de P1/P2 (todas salvo la de respuesta tardía, que ya pasaba) y las 2 semánticas fallaban. Con solo P1 corregido, seguían fallando 4 de P2; la de orden inverso pasaba ya con el código anterior.

**Resultados reales:**

- `flutter analyze`: sin problemas.
- `test/monitoring`, `test/history` y `test/demo/fase3_flow_test.dart`: pasan las 55 pruebas.
- `build/review/fase3_review_test.dart`: pasan 25 de 26. La que falla («guardar patrón y cambiar tema sin esperar») ahora termina con SQLite y la interfaz en `patron_2/dark`. Falla después, en su `requestStart()`: tras cambiar el patrón la prueba de sonido queda pendiente, como exige RF29.CA3, y la reproducción no la repite. La regresión propia cubre ese caso repitiendo la prueba.
- `build/review/fase2_review_test.dart`: no compila. Sus reproductores falsos no aceptan el parámetro `patternId` que la fase 3 añadió a `AlertSoundPlayer.play`. No se modificó ese archivo de Codex.
- No se repitieron, por indicación: la suite completa, el contraste, los renderizados ni las compilaciones Android.

## Comprobado (fase 3)

- `flutter analyze`: sin problemas.
- `flutter test`: pasan 534 pruebas, entre ellas:
  - el repositorio sobre SQLite real, con relectura desde otra instancia de la base;
  - el reinicio simulado (desmontar la app y reabrirla sobre la misma base);
  - las preferencias;
  - la separación DEMO/normal;
  - la activación semántica;
  - la matriz de disposición con 10 estados nuevos.
- `python tools/spec_registry.py check`: OK.
- **Renderizados.** Los de la fase 3 están en `test/goldens/fase3/` (44). Cambian P03 «último resumen» y P07 de la fase 2, que ahora leen el dato guardado.
- **APK normal.** `flutter build apk --release`: `package: name='com.juanrueda.vigia'`, `application-label:'Vigía'` (aapt). Atención: ese APK normal se compiló desde el árbol de trabajo antes de los commits de la fase 3. La compilación DEMO posterior lo sobrescribió en la misma ruta, así que ya no existe. Es anterior a las correcciones P1/P2. No acredita una compilación normal actual de la fase 3. Además, el primer intento de compilación normal falló (`java.util` en el script de Gradle, corregido con `import java.util.Base64`), y aapt leyó entonces el APK de la fase 2 que seguía en esa ruta.
- **APK DEMO.** `flutter build apk --release --dart-define=VIGIA_DEMO=true`:
  - `package: name='com.juanrueda.vigia.demo'`, `application-label:'Vigía DEMO'`;
  - `libsqlite3.so` para arm64-v8a, armeabi-v7a y x86_64;
  - `allowBackup=false` con las dos reglas de exclusión;
  - 56 997 370 bytes, SHA-256 `09afe83ff10ea72ac3cd6552045a0e2a07e2df2159a3b8813d87315a71524081`.
  
  Ese APK es **anterior a las correcciones P1/P2**: no las incluye hasta recompilarlo.

## No comprobado

- **Sin teléfono D1:**
  - instalación de las dos apps;
  - reinicio real del proceso Android: el de las pruebas es el desmontaje de la app sobre la misma base;
  - copia de seguridad y transferencia;
  - audio físico de los tres patrones;
  - TalkBack real.
- **Simulación.** Se rotula siempre «DEMO — datos simulados»; no hay cámara ni IA reales.

## Siguiente acción

Nueva revisión de Codex de las correcciones de la fase 3, sobre el commit que sigue a `9d54956`. Antes de entregar o subir:
- recompilar el APK DEMO;
- compilar y comprobar de nuevo el APK normal.

La fase 4 no empieza sin autorización expresa.
