# Vigía

Aplicación Android (Flutter + motor Kotlin local) para observar señales oculares relacionadas con somnolencia, emitir avisos locales y registrar sesiones. Autor del proyecto: Juan José Rueda Viveros. «Vigía» es un nombre provisional.

> **Estado: prototipo académico, fase 1 de 4** (plan activo en [`AGENTS.md`](AGENTS.md)). La app tiene la base visual de B5.2 y la pantalla **Inicio (P03)**. **No** usa la cámara, **no** ejecuta IA, **no** crea sesiones ni emite alertas. Los datos de revisión son simulados y se rotulan «DEMO — datos simulados». No sirve para monitorear la conducción.

## Estructura

| Ruta | Contenido |
|---|---|
| `lib/core/design_system/` | Tokens B5.2 (`tokens.dart`), temas claro/oscuro e Inter (`theme.dart`), iconos B5.2 (`vigia_icons.dart`) y componentes (`widgets/`) |
| `lib/features/inicio/` | P03 Inicio: modelo de estado y pantalla |
| `lib/demo/` | **Datos DEMO** (simulados) para revisar las variantes de Inicio, separados de los reales |
| `lib/app/` | Composición de la app y elección de la fuente de datos de Inicio |
| `packages/monitoring_engine/` | Plugin local Kotlin (base del motor; todavía sin cámara ni IA) |
| `assets/fonts/Inter/` | Inter 400/500 y su licencia OFL ([`docs/licenses.md`](docs/licenses.md)) |
| `test/` | Pruebas; `test/goldens/inicio/` contiene los renderizados de referencia de P03 |
| `docs/source/` | Especificaciones originales (PRD, UX, arquitectura y diseño B5.2) |
| `docs/toolchain.md` | Versiones del entorno (Flutter 3.47.6, JDK 21, Gradle 9.3.1, AGP 9.1.0) |

La ruta del repositorio debe ser ASCII y sin espacios (actualmente `D:\dev\vigia`).

## Fase 1 · Base visual e Inicio

- **Tokens de B5.2:**
  - paletas clara y oscura («grafito violeta»), colores del aura pastel;
  - escala tipográfica, espaciados, radios y movimiento.
- **Tema:** sigue al del sistema. La elección persistente del tema llega con Ajustes, en la fase 3.
- **Componentes compartidos:**
  - botones primario, secundario y deshabilitado con borde discontinuo, CTA sobre aura y botón sobre papel, todos con escala 0,98 al pulsar;
  - tarjeta de estado con icono, texto y color;
  - aura (`HERO`), papel de resumen y filas clave–valor;
  - encabezado, rótulo DEMO, barra principal y aviso temporal.
- **Aura:** reproduce `vgA1`, `vgA2` y `vgC` (6 s, ease-in-out, una iteración). Con movimiento reducido queda estática. Es decorativa: no representa medición.
- **P03 Inicio:** cinco variantes de B5.2:
  - sin historial;
  - último resumen (DS01);
  - sesión vigente;
  - registro interrumpido (DS02);
  - estado del motor desconocido.
- **Acciones pendientes:**
  - Preparar sesión, Volver al monitoreo, Ver último resumen, Consultar estado → aviso de disponibilidad pendiente (fase 2);
  - Historial, Ajustes, Revisar registro → aviso de disponibilidad pendiente (fase 3).

  No navegan ni simulan esas pantallas.

### Datos DEMO frente a datos reales

- Sin opciones, la app usa el **estado real**. En la fase 1 todavía no existen el motor ni el historial, así que Inicio muestra «sin historial» **sin** rótulo DEMO, porque no presenta nada simulado.
- Las variantes de revisión se eligen al ejecutar o compilar (los datos están en `lib/demo/inicio_demo.dart` y siempre llevan el rótulo DEMO):

  ```bash
  flutter run --dart-define=VIGIA_DEMO_INICIO=ultimo_resumen
  ```

  Valores admitidos: `sin_historial`, `ultimo_resumen`, `sesion_vigente`, `registro_interrumpido`, `motor_desconocido`. Un valor desconocido produce un error; nunca se sustituye en silencio.

### Decisiones de adaptación (texto al 200 %)

- **Barra principal:** B5.2 limitaba sus etiquetas al 135 %, lo que incumple RNF03.CA1 y UX22.CA1 (OI-04). Aquí escalan sin tope. Si los tres destinos no caben en una fila, la barra pasa a una lista vertical dentro de la misma pastilla.
- **Tarjeta de estado:** si una palabra no cabe junto al icono, el icono pasa encima del texto. En 320 px y al 200 % la palabra «interrumpida» (44 px) sigue sin caber en el ancho disponible y se parte. El texto no se reduce: es un límite registrado de esa combinación extrema.
- **Filas clave–valor:** se mantienen como bloques separados por 16, como en B5.2.

## Comandos (fase 1)

```bash
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test                                    # incluye la matriz y los renderizados
flutter test --update-goldens test/goldens      # regenera los PNG de test/goldens/inicio
flutter build apk --debug
python tools/spec_registry.py check
```

- **`test/inicio/inicio_layout_test.dart`:** comprueba las 60 combinaciones (5 variantes × claro/oscuro × 320/360/412 × texto 100/200 %):
  - sin desbordes ni texto cortado;
  - botones ≥ 48 y alcanzables;
  - barra completa;
  - pautas de Flutter de área táctil, etiquetado y contraste.

  También comprueba el aura con movimiento normal y reducido.
- **Renderizados:** los genera el motor de dibujo de Flutter en `flutter test` (no un teléfono): 360×800 al 100 % y 320×2400 al 200 %, en claro y oscuro.

**No verificado todavía:** instalación y arranque en un teléfono Android (no hay equipo D1; ver [`docs/testing.md`](docs/testing.md)), TalkBack real y rendimiento del aura en el dispositivo.
