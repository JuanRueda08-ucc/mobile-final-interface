# Bloque · Cuenta, navegación lateral, acceso y rótulo de prueba

Autorizado por el usuario el 2026-11-11. Lo implementa **Codex** mientras
Claude está sin cuota. Base: `431b48f` (Cuentas Firebase, Inicio con aura,
preparación por pasos y P06). Variante normal; la DEMO sigue separada.

## Decisiones del usuario

1. **Apartado de Cuenta.** Pantalla nueva con correo, estado de
   verificación, cerrar sesión (hoy está en Ajustes), estado de la
   sincronización del historial y el aviso de versión de prueba (punto 4).
2. **Barra lateral en lugar de la barra inferior.** Barra de solo iconos
   con Inicio, Historial, Ajustes y Cuenta, con etiqueta o tooltip
   accesible y destino seleccionado visible. Debe funcionar a 320 dp con
   texto al 200 %. Si allí no cabe, se documenta la alternativa elegida
   (por ejemplo, barra lateral desplegable) con capturas.
3. **Rediseño de «Inicia sesión» y «Crea tu cuenta».** El usuario los ve
   apagados y simples; la materia es Diseño de Interfaces y se pide una
   interfaz de vanguardia. Dirección: portada con el aura y el motivo
   ocular de Inicio, jerarquía tipográfica marcada, campos con estados
   trabajados (foco, error, carga), transición entre acceso y registro,
   dentro del sistema B5.2. Se conserva `AccountForm`, el contrato de
   verificación por enlace y la recuperación de contraseña.
4. **Rótulo «experimental» en un solo lugar.** Se quita «experimental» de
   títulos, botones y etiquetas repetidas («Monitoreo experimental» →
   «Monitoreo», «Iniciar monitoreo experimental» → «Iniciar monitoreo»,
   «Historial experimental» → «Historial», etc.). Se deja **un** aviso
   discreto de «Versión de prueba» (en Cuenta y en Ajustes › Acerca de)
   que explique que la detección usa valores candidatos no validados y no
   es una ayuda validada para conducir. Motivo: el perfil
   `lab-eye-rules-0.1` sigue candidato (Área 05 §1); aceptarlo exige un
   piloto anotado, fuera del alcance. Los datos internos
   (`qualification: 'experimental'`, perfil, Firestore) **no** cambian.
   Esta decisión sustituye, solo en la presentación, la regla de
   AGENTS.md que pedía rotular lo experimental en cada pantalla.
5. **Prueba del recorrido completo** al final: cámara real, calibración,
   sesión con aviso, pausa/reanudación, final, historial, y dos cuentas
   verificadas en `vigia-e1680` con aislamiento. Requiere teléfono físico
   o webcam con la persona usuaria; si no está disponible, se deja
   preparado y anotado como pendiente.

Orden: 1 + 2 → 3 → 4 → 5.

## Límites

- No cambiar cámara, inferencia, calibración, umbrales, reglas oculares ni
  el esquema de Firestore/SQLite salvo lo imprescindible y documentado.
- Sin RF10/UX07: nada de «Seguro», «Puedes conducir» ni porcentajes.
- La DEMO conserva «DEMO — datos simulados» (RF32); este bloque no toca ese
  rótulo.
- Commits locales en `main`, sin amend, push ni PR.
- Comprobación por paso: `flutter analyze`, `flutter test`,
  `python tools/spec_registry.py check` y renderizados nuevos en claro y
  oscuro (360 dp al 100 %, 320 dp al 200 %). Los goldens que cambien por
  el rediseño se regeneran y se dice cuáles.

## Registro de Codex

Codex anota aquí cada paso terminado para que Claude retome sin releer el
código: fecha, commit, archivos o pantallas tocados, decisiones tomadas y
por qué, resultado de las comprobaciones (cifras), APK y SHA-256 si se
compiló, y qué queda pendiente o no se pudo comprobar.

### Paso 1 · Cuenta y navegación lateral · 2026-11-11

Commit «Añade Cuenta y navegación lateral a la variante normal».

- `/cuenta` abre `AccountScreen`. Muestra correo y verificación, consulta el
  proveedor de envío del UID activo y permite reintentar si falla. Comparte
  con Acceso la consulta del motor antes de cerrar sesión. Ajustes retira
  «Mi cuenta». Cambios en `router.dart`, `lib/features/account/`, Inicio,
  Historial y Ajustes.
- `VigiaScaffold` usa los iconos de B5.2, áreas de toque de al menos 48 dp,
  etiqueta semántica, tooltip y relleno para el destino seleccionado. La
  barra de 56 dp es fija a 360 dp al 100 %. Por debajo de 360 dp o con texto
  ampliado se abre desde el encabezado para evitar estrechar el contenido.
  [Panel claro a 320 dp al 200 %](../test/account/navegacion/cuenta_panel__claro_320_200.png)
  y [panel oscuro a 320 dp al 200 %](../test/account/navegacion/cuenta_panel__oscuro_320_200.png).
- `flutter analyze` sin diagnósticos. Registro de especificaciones 500/500.
- 18 PNG nuevos en `test/account/navegacion/`. Goldens regenerados de Inicio
  normal (`inicio/` y `experimental_entry/`), Inicio/Historial 5D y Ajustes
  P12 (`fase5e/` y `fase5e_review/`). La comprobación usa dobles del motor y
  Firebase para navegar y observar el estado de Cuenta.
- Sin APK en este paso. Quedan por comprobar TalkBack en Android, el
  recorrido con cámara y la sincronización alojada con dos cuentas. El
  emulador detectó la cámara «HD User Facing» como `webcam0`.
