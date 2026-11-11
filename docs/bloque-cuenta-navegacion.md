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

## Recorrido guiado en `vigia-e1680`

Usa el APK de prueba de la variante normal, con las definiciones de
`.dart_tool/vigia-firebase.json`. Para webcam, usa `vigia_pixel` con
`-read-only -no-snapshot-load -no-snapshot-save -camera-front webcam0
-camera-back none`. Identifica las cuentas como A y B en el registro. La
persona usuaria introduce las credenciales en el emulador y abre los enlaces
en sus correos.

1. Registra A. Comprueba «Verifica tu correo» y el bloqueo de Inicio e
   Historial mientras el enlace esté pendiente. Abre el enlace y pulsa
   «Ya verifiqué mi correo». En Cuenta debe aparecer «Correo verificado».
2. Con la persona sentada frente a la cámara, abre «Preparar sesión».
   Confirma vista previa en directo, un rostro y calibración aceptada.
   Pulsa «Probar tono» y confirma «Lo escuché» después de oírlo.
3. Inicia el monitoreo. Comprueba un aviso con un cierre ocular voluntario,
   su cese al reabrir, la pausa y la reanudación. Finaliza y compara el
   resumen con Inicio, Historial y detalle. Comprueba el estado de envío en
   Cuenta y la conservación del registro tras volver a abrir la app.
4. Cierra sesión desde Cuenta. Registra y verifica B. Comprueba que B no ve
   el resumen de A en Inicio, Historial ni por el acceso al detalle. Si hay
   tiempo para otra sesión, guarda un resumen con B y repite la comprobación
   al volver a A. Identifica qué resúmenes se observaron desde cada cuenta.
5. Registra el resultado de cada acción, el dispositivo y el SHA-256 del APK.
   Distingue la detección del motor de las confirmaciones de la persona
   usuaria, en particular la audición del tono. La evidencia se anota como
   texto, sin credenciales, direcciones de correo ni imágenes de la cámara.

## Registro de Codex

Codex anota aquí cada paso terminado para que Claude retome sin releer el
código: fecha, commit, archivos o pantallas tocados, decisiones tomadas y
por qué, resultado de las comprobaciones (cifras), APK y SHA-256 si se
compiló, y qué queda pendiente o no se pudo comprobar.

### Paso 1 · Cuenta y navegación lateral · 2026-11-11

Commit `0cde331` «Añade Cuenta y navegación lateral a la variante normal».

- `/cuenta` abre `AccountScreen`. Muestra correo y verificación, consulta el
  proveedor de envío del UID activo y permite reintentar si falla. Comparte
  con Acceso la consulta del motor antes de cerrar sesión. Ajustes retira
  «Mi cuenta». Archivos `router.dart`, `account_screen.dart`,
  `firebase_account.dart`, `firebase_account_screen.dart`, `inicio_screen.dart`,
  `experimental_history_screens.dart`, `settings_screen.dart`,
  `vigia_scaffold.dart` y `vigia_icons.dart`. Pruebas en
  `account_navigation_test.dart` e `inicio_layout_test.dart`.
- `VigiaScaffold` usa los iconos de B5.2, áreas de toque de al menos 48 dp,
  etiqueta semántica, tooltip y relleno para el destino seleccionado. La
  barra de 56 dp es fija a 360 dp al 100 %. Por debajo de 360 dp o con texto
  ampliado se abre desde el encabezado para evitar estrechar el contenido.
  [Panel claro a 320 dp al 200 %](../test/account/navegacion/cuenta_panel__claro_320_200.png)
  y [panel oscuro a 320 dp al 200 %](../test/account/navegacion/cuenta_panel__oscuro_320_200.png).
- `flutter analyze` sin diagnósticos. Registro de especificaciones 500/500.
- 18 PNG nuevos en `test/account/navegacion/` y 34 goldens regenerados de Inicio
  normal (`inicio/` y `experimental_entry/`), Inicio/Historial 5D y Ajustes
  P12 (`fase5e/` y `fase5e_review/`). La comprobación usa dobles del motor y
  Firebase para navegar y observar el estado de Cuenta.
- Sin APK en este paso. Quedan por comprobar TalkBack en Android, el
  recorrido con cámara y la sincronización alojada con dos cuentas. El
  emulador detectó la cámara «HD User Facing» como `webcam0`.

### Paso 2 · Acceso y registro · 2026-11-11

Commit `bdb92fe` «Rediseña el acceso y el registro de Vigía».

- `FirebaseAccountScreen` reutiliza `AccountForm`. La portada comparte
  `ScreenAura` con Inicio y usa un motivo ocular, un título de mayor tamaño
  y una transición breve respetuosa del movimiento reducido. La acción
  principal queda fija y los campos y enlaces se alcanzan desplazando el
  formulario a 320 dp y texto al 200 %.
- Cambiar de formulario conserva el correo y limpia la contraseña. Los
  campos indican el error local y la acción muestra el progreso de la
  solicitud. Las pruebas con dobles comprueban el envío de verificación,
  la actualización del token y la recuperación por enlace.
- Archivos `firebase_account_screen.dart`, `account_form.dart`,
  `screen_aura.dart`, `inicio_screen.dart` y `firebase_access_test.dart`.
  `fase3_flow_test.dart` comprueba la navegación por tooltip en la prueba
  de separación normal/DEMO que todavía buscaba texto de la barra inferior.
- `flutter analyze --no-pub` sin diagnósticos y registro 500/500. Pruebas
  dirigidas de acceso 6/6. La suite global se inició en una copia fija de
  este paso para preservar el estado de los otros pasos.
- Ocho capturas en `test/account/firebase/`, seis nuevas y dos de acceso a
  320 dp al 200 % regeneradas. Cubren «Inicia sesión» y «Crea tu cuenta» en
  360 dp al 100 % y 320 dp al 200 %, en ambos temas.
- Sin APK en este paso. El recorrido con los correos alojados se comprueba
  en el paso 4.

### Paso 3 · Versión de prueba · 2026-11-11

Commit «Concentra el aviso de prueba en Cuenta y Ajustes».

- Se revisó la presentación de Inicio, preparación, Monitoreo (P06),
  finalización, resumen, Historial y detalle. El componente
  `TrialVersionNotice` aparece una vez en Cuenta y una vez en la sección
  «Acerca de» de Ajustes. Describe el estado de los valores candidatos y
  el límite de uso para conducir.
- Los registros, `qualification: 'experimental'`, `lab-eye-rules-0.1`, las
  reglas del motor y el rótulo DEMO se conservan. Las expectativas de las
  pruebas de UI se actualizaron para comprobar los textos nuevos y la
  ausencia de avisos repetidos en el recorrido.
- Archivos `trial_version_notice.dart`, `account_screen.dart`,
  `settings_screen.dart`, `inicio_screen.dart`,
  `experimental_monitoring_screen.dart` y los tres archivos de presentación
  `experimental_home_section.dart`, `experimental_history_blocks.dart` y
  `experimental_history_screens.dart`. Pruebas en
  `account_navigation_test.dart`, `experimental_monitoring_test.dart`,
  `experimental_history_ui_test.dart` y `fase5d_render_test.dart`.
- Ocho PNG nuevos de Cuenta y Acerca de en `test/account/navegacion/` y 80
  goldens regenerados. Se actualizaron 10 de navegación, 8 de Inicio y
  Encuadre, 4 de Inicio normal, 12 de 5C, 24 de P06, 20 de 5D y 2 de P12.
  [Cuenta a 360 dp al 100 %](../test/account/navegacion/cuenta_version__oscuro_360_100.png)
  y [Acerca de a 320 dp al 200 %](../test/account/navegacion/ajustes_acerca__claro_320_200.png).
- Registro 500/500. El barrido dirigido aprobó 137 pruebas. Las otras dos
  usaban el rótulo retirado y el nombre anterior de un botón de Historial.
  Ambas pasaron al actualizar las expectativas y repetir esas pruebas.
- La compilación para Android y la verificación con Firebase se registran
  en el paso 4.
