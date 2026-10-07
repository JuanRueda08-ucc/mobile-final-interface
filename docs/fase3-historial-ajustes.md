# Vigía · Fase 3: app DEMO, historial persistente y Ajustes

Guía para compilar, comprobar y presentar la fase 3 del plan activo (`AGENTS.md`). La fase 2 está en `docs/fase2-recorrido-demo.md`: su guion sigue siendo válido para el recorrido Preparación → Monitoreo → Resumen.

Todo lo que produce el recorrido DEMO es **simulado** y lleva el rótulo «DEMO — datos simulados» (RF32). Lo nuevo de esta fase es que esas sesiones simuladas **se guardan** en el teléfono, en un almacén solo de la app DEMO, y se consultan en Inicio, Resumen e Historial.

## Dos aplicaciones Android

| Compilación | applicationId | Nombre en el lanzador | Datos |
|---|---|---|---|
| Sin definiciones | `com.juanrueda.vigia` | Vigía | Ninguno: motor no comprobado, preparación bloqueada, no escribe nada |
| `--dart-define=VIGIA_DEMO=true` | `com.juanrueda.vigia.demo` | Vigía DEMO | `vigia_history_demo_v1.sqlite` (historial y preferencias) |
| `--dart-define=VIGIA_DEMO_INICIO=<variante>` | `com.juanrueda.vigia` | Vigía | Ninguno: vista de revisión de Inicio, sin escrituras |

Las dos apps se pueden instalar a la vez y no comparten datos.

La coherencia entre Android y Dart se garantiza dos veces:

1. **Al compilar.** `android/app/build.gradle.kts` lee `VIGIA_DEMO` de la propiedad `dart-defines` que Flutter pasa a Gradle, la misma definición que lee Dart. De ahí salen el applicationId y el nombre. Un valor distinto de `true`/`false` detiene la compilación.
2. **Al arrancar.** `lib/app/bootstrap.dart` pide el applicationId real por el canal `vigia/app` y lo compara con el modo. Si no coinciden, no abre ninguna base y muestra «No se pudo abrir Vigía». El modo real y la revisión de Inicio nunca abren la base.

## Comandos

Ejecutar en un teléfono o emulador conectado:

```bash
flutter run --dart-define=VIGIA_DEMO=true
```

APK de la app DEMO:

```bash
flutter build apk --release --dart-define=VIGIA_DEMO=true
```

El APK queda en `build/app/outputs/flutter-apk/app-release.apk`. Si Gradle falla con «Unable to establish loopback connection», compila con `TEMP` y `TMP` cortos (p. ej., `D:\dev\tmp`), como en la fase 2. El APK está firmado con la clave de depuración de la plantilla: sirve para demostración, no para distribución.

Comprobar el applicationId y el nombre del APK construido:

```bash
D:/dev/android-sdk/build-tools/36.0.0/aapt.exe dump badging build/app/outputs/flutter-apk/app-release.apk
```

Debe mostrar `package: name='com.juanrueda.vigia.demo'` y `application-label:'Vigía DEMO'`.

App normal, para comparar:

```bash
flutter build apk --release
```

Si se cambia el esquema de `lib/data/demo_history/demo_history_database.dart`, se regenera el código de Drift:

```bash
dart run build_runner build
```

`analyzer` está fijado por debajo de 14.5.0 en `dev_dependencies`: build_runner 2.16.1 usa una API que analyzer 14.5.0 retiró.

## Qué se guarda (Área 06, subconjunto DEMO)

Base `vigia_history_demo_v1.sqlite` en el directorio privado de la app (Área 06 §16), con Drift 2.35.1 y SQLite 3.53 que aporta `sqlite3` 3.5.2. Las claves foráneas están activas.

- **`demo_sessions`.** Guarda:
  - el ID `S-DEMO-NNNN` (el número no se reutiliza entre ejecuciones);
  - el origen permanente `demo`, impuesto por una restricción CHECK;
  - el inicio civil (epoch UTC y offset);
  - el ciclo (`active`, `paused`, `stopping`, `finalized`, `interrupted`);
  - el fin confirmado y el último desplazamiento durable;
  - la referencia de calibración y la integridad.
  
  Los totales del resumen se escriben **una sola vez** al confirmar el cierre: evaluable, no evaluable, pausado, desconocido, **tiempo monitoreado sin pausas**, episodios, avisos y pausas. En una interrumpida quedan nulos.
- **`demo_session_events`.** Los hechos de la sesión simulada, en orden, con su desplazamiento desde el inicio. De ellos se calculan los totales. Un hecho repetido (misma sesión y secuencia) no se duplica.
- **`preferences`.** Una sola fila: tema, patrón de sonido y movimiento reducido.

El controlador de sesión escribe por `DemoHistoryRepository`, y las escrituras se aplican en orden. Inicio (P03), Resumen (P07), Historial (P08) y Detalle (P09) leen del **mismo** repositorio. Ninguna pantalla usa una lista en memoria.

### Registro interrumpido (RF19, UX13)

Si la app se cierra con una sesión activa, pausada o cerrándose, al reabrirla esa sesión pasa a **Interrumpida** antes de que se pueda iniciar otra. Entonces:

- no se reanuda ni se abre el monitoreo;
- Inicio muestra «Sesión interrumpida» con Revisar registro y Preparar sesión;
- el detalle muestra el inicio, el último registro confirmado (hora y desplazamiento), «Final: Desconocido», «Duración: No disponible» y «Cobertura: No disponible»;
- el último registro es el último hecho guardado: no se extiende hasta la reapertura.

Si falla la escritura del cierre, el Resumen muestra «Registro incompleto» y no se puede iniciar otra sesión en esa ejecución (Área 06 §3). Al reabrir, esa sesión queda interrumpida.

## Pantallas nuevas

| ID | Pantalla | Qué hace |
|---|---|---|
| P08 | Historial | Más reciente primero; filtros Todas / Finalizadas / Interrumpidas. Cargando, error y vacío se distinguen. Vacío ofrece «Preparar primera sesión» |
| P09 | Detalle de sesión | Finalizada: tiempos, cobertura, episodios, avisos y línea temporal. Interrumpida: solo lo confirmado. Con sesión vigente muestra «Sesión en curso», también por ruta directa |
| P12 | Ajustes | Tema Claro/Oscuro/Sistema, movimiento (Según Android / Reducido) y Sonido. Con sesión vigente solo se cambia el tema |
| P13 | Sonido | Patrón 1, 2 o 3: probar y guardar. Salir sin guardar pregunta «Descartar cambios / Seguir editando». Bloqueado con sesión vigente |

- **Tema.** Se aplica en el acto y se guarda. Si la escritura falla, se aplica igual y avisa «Preferencia no guardada».
- **Movimiento reducido.** La preferencia se suma a la de Android: si Android pide reducir el movimiento, se reduce siempre.
- **Sonido.**
  - El patrón cambia solo si se guardó.
  - Guardar otro patrón vuelve a exigir «Probar sonido» y «Lo escuché» en Preparación (RF29.CA3).
  - Las alertas usan el patrón guardado.
  - Los tres patrones son tonos distintos de `ToneGenerator`. El catálogo definitivo sigue pendiente de design system y audio.

La barra principal de Inicio, Historial y Ajustes navega entre las tres secciones en la app DEMO. En la app normal muestra un aviso: sin motor no hay historial ni ajustes en este prototipo.

## Guion de presentación (unos 4 minutos)

1. **Inicio vacío.** Abre «Vigía DEMO». Aparecen el rótulo DEMO y «Aún no tienes sesiones».
2. **Sesión.** Sigue los pasos 2 a 9 del guion de la fase 2: preparar, calibrar, probar sonido, iniciar, pausar, reanudar y finalizar. El Resumen dice «Completo · guardado» e incluye «Tiempo monitoreado (sin pausas)».
3. **Detalle.** Pulsa **Ver detalle**. Se ve la misma sesión con su origen («DEMO — datos simulados»), los tiempos y la línea temporal.
4. **Historial.** Pulsa Volver. La sesión aparece en la lista con fecha, estado y cobertura. Prueba los filtros.
5. **Inicio.** Muestra «Último resumen» con el mismo ID y la misma cobertura.
6. **Ajustes.**
   - Cambia a Oscuro: se aplica en el acto.
   - Elige Movimiento «Reducido».
   - En **Sonido**, elige Patrón 2, pulsa **Probar sonido** y **Guardar**.
   - Vuelve a Preparación: la prueba de sonido está otra vez pendiente.
7. **Reinicio (opcional, en el teléfono).** Inicia otra sesión, ciérrala con el botón «Forzar detención» de la información de la app y vuelve a abrirla. Inicio debe mostrar «Sesión interrumpida». **Revisar registro** abre el detalle con el final desconocido. El tema, el movimiento y el patrón siguen guardados.

## Comprobación

```bash
flutter analyze
```

```bash
flutter test
```

```bash
python tools/spec_registry.py check
```

Pruebas propias de la fase 3:

| Ruta | Qué cubre |
|---|---|
| `test/history/demo_history_repository_test.dart` | Con SQLite real: cierre guardado una vez sin duplicar hechos; relectura con **otra instancia** de la base (archivo); interrumpida sin fin ni totales; orden, filtros, origen DEMO y claves foráneas |
| `test/history/write_failure_test.dart` | Cierre no guardado (Registro incompleto, sin otra sesión); tema y patrón no guardados |
| `test/demo/fase3_flow_test.dart` | Resumen, detalle, lista e Inicio con los mismos datos; una fila por sesión; dos sesiones en una ejecución; **reinicio** (interrumpida, Historial y último resumen reconstruidos); filtros; bloqueos con sesión vigente; tema, movimiento y patrón aplicados y guardados; app normal y revisión sin historial; activación semántica |
| `test/app/bootstrap_test.dart` | Modo ↔ applicationId; la app normal no abre la base y rechaza el modo DEMO |
| `test/demo/demo_layout_test.dart` | Matriz de la fase 2 ampliada con 10 estados nuevos × claro/oscuro × 360/100 %, 320/200 % y 412/200 %, con contraste, áreas táctiles y textos sin cortar |

Las sesiones de las pruebas salen del recorrido real (controlador y repositorio) sobre SQLite en memoria o en un archivo temporal. El «reinicio» de las pruebas desmonta la app y la vuelve a abrir sobre la misma base con otra instancia del repositorio: **no es un reinicio del proceso Android**.

Los renderizados de la fase 3 están en `test/goldens/fase3/` y se generan con:

```bash
flutter test --update-goldens test/goldens/fase3_render_test.dart
```

Cambian P03 «último resumen» y P07 de la fase 2, porque ahora leen el dato guardado.

## Limitaciones del prototipo

- **Esquema.** Es un subconjunto de Área 06 §6 para el motor simulado:
  - sin modelo, política, instantánea de calibración ni hashes, que no existen en la demostración y no se inventan;
  - sin intervalos, transiciones ni intentos de aviso como tablas propias: los tiempos se calculan desde los hechos;
  - IDs legibles `S-DEMO-NNNN` en vez de UUID;
  - no hay migraciones porque no hay otra versión distribuida.
  
  No es el journal Room del motor real, que queda fuera de esta fase.
- **Referencia de calibración.** No se guarda: tras reabrir la app hay que calibrar de nuevo. Su número sí continúa la numeración guardada.
- **No implementado:**
  - Detalle de episodio y valoración (P10);
  - Tendencias (P11);
  - Datos: exportación, borrado y retención (P14–P15);
  - Ayuda (P16–P17) y Perfil local (P18);
  - D03, D04, D06, D07 y D08.
  
  Ajustes lo indica sin botones que aparenten funcionar. **OI-08 sigue abierto**: RF27.CA2 no se ha modificado ni resuelto.
- **Movimiento reducido.** Es una preferencia de la app añadida en esta fase. En B5.2 era un control del prototipo HTML.
- **Copias de seguridad.** `allowBackup=false` y las reglas de exclusión de Área 06 §17 están en el manifiesto, pero no se han comprobado en un equipo.

## Pendiente (no comprobado)

- **Sin teléfono D1:**
  - instalación de las dos apps lado a lado;
  - reinicio real del proceso (forzar detención y reabrir);
  - copia de seguridad y transferencia;
  - audio físico de los tres patrones;
  - TalkBack real.
- **Cámara e IA reales:** fuera del prototipo.
