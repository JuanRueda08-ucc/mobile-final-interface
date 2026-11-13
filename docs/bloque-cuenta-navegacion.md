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
- `flutter test` completo del paso 1 dio 938 aprobadas y una prueba con
  el selector de texto de la barra anterior. El ajuste quedó en `bdb92fe`.
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
  dirigidas de acceso 6/6. La suite global de la copia fija del paso 2
  aprobó 943/943, incluida la prueba corregida de separación normal/DEMO.
- Ocho capturas en `test/account/firebase/`, seis nuevas y dos de acceso a
  320 dp al 200 % regeneradas. Cubren «Inicia sesión» y «Crea tu cuenta» en
  360 dp al 100 % y 320 dp al 200 %, en ambos temas.
- Sin APK en este paso. El recorrido con los correos alojados se comprueba
  en el paso 4.

### Paso 3 · Versión de prueba · 2026-11-11

Commit `5da7c85` «Concentra el aviso de prueba en Cuenta y Ajustes».

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
- `flutter analyze --no-pub` sin diagnósticos y registro 500/500. El barrido
  dirigido aprobó 137 pruebas. Las otras dos
  usaban el rótulo retirado y el nombre anterior de un botón de Historial.
  Ambas pasaron al actualizar las expectativas y repetir esas pruebas.
- La suite global de la interfaz final y los cuatro renderizados del paso 4
  dio 946 aprobadas y un timeout de 30 s en la prueba de importar más de
  5000 hechos. Esa prueba y la del selector de navegación del paso 1
  pasaron en la repetición dirigida en `main` (2/2).
- La compilación para Android y la verificación con Firebase se registran
  en el paso 4.

### Paso 4 · Prueba guiada con Firebase · 2026-11-11

Commit `eae986d` «Prepara la prueba guiada de Firebase con webcam».

- El guion de esta guía cubre registro, verificación, monitoreo con webcam,
  sincronización e historial separado entre A y B. Se actualizó la ruta de
  salida en `docs/cuentas-firebase.md` y se añadió
  `test/account/firebase_verification_render_test.dart`.
- `flutter analyze --no-pub` sin diagnósticos, registro 500/500 y 4/4
  renderizados nuevos `verificacion__*.png` en `test/account/firebase/`,
  en claro y oscuro a 360 dp al 100 % y 320 dp al 200 %. Son capturas con
  dobles de la pantalla de enlace pendiente.
- Repetición final de `flutter test --no-pub` en `main`, 947/947. Se usaron
  `TMP` y `TEMP` en D: tras constatar espacio insuficiente en C: al copiar
  los archivos temporales del compilador de pruebas.
- El primer APK Debug quedó descartado. SHA-256
  `9ec712fbdfe9e3155ae4fa27353d95ed1bfda109de30df83ce4a3855a7ee880c`.
  En `vigia_pixel`, la persona usuaria observó un fallo de `libdartjni.so`
  antes de Acceso. El archivo ZIP confirmó que faltaban las bibliotecas
  de los plugins. La copia aislada de pruebas no contenía
  `.flutter-plugins-dependencies` y la compilación usó `--no-pub`.
  El binario quedó en `build/codex-validacion/vigia-debug-incompleto.apk`.
- Se regeneró el registro de plugins Android con `flutter pub get --offline`
  en la raíz antes de reconstruir el APK. El ajuste documentado para
  Gradle usa `TMP`, `TEMP` y el directorio de sockets de Java en una ruta
  ASCII para recuperar la conexión de loopback.
- APK reconstruido en modo Release con firma Android Debug, código
  `5da7c85`, 99 679 926 bytes, en
  `D:/dev/vigia-entrega/vigia-normal-cuenta-navegacion-pruebas.apk`.
  SHA-256 `19b96af98ec3d0b2f1d56db0f9bf8157b4e5cb0dddeed0c8dfbde29c0941b0f5`.
  Se comprobaron la firma, `libdartjni.so`, `libmediapipe_tasks_jni.so` y
  `libsqlite3.so` en las tres ABI, y `vigia-e1680` en el binario x86_64.
  El `base.apk` instalado coincide por SHA-256 y Android mostró
  «Inicia sesión» y «Crear cuenta».
- `vigia_pixel` inició Android con `webcam0`, gráficos de host y capa
  temporal. La persona usuaria llegó a Inicio y confirmó «Correo
  verificado» en Cuenta A. Confirmó la vista previa en directo, calibración
  aceptada, audición del tono de prueba, aviso durante el monitoreo,
  pausa, reanudación y resumen final. Encontró la misma sesión y su detalle
  en Historial y vio «Sin envíos pendientes» en Cuenta.
- Reinicio comprobado con `am force-stop`. PID anterior `3526`, ausencia
  del proceso después de detenerlo y arranque frío con PID `4088`.
  Android aún mostraba un cliente de cámara de Vigía en dos lecturas
  previas. El servicio registró la desconexión y, después del reinicio,
  se comprobó que no quedaba ningún cliente de Vigía. Queda por medir
  el momento de la liberación automática al finalizar.
- Después del reinicio, la persona usuaria confirmó que A conservaba el
  mismo resumen. Luego verificó B con otro correo y comprobó que Historial
  de B no mostraba esa sesión. Al cerrar B y volver a entrar con A,
  confirmó que reapareció el mismo resumen. El aislamiento quedó comprobado
  desde la interfaz con ambas cuentas de `vigia-e1680`.
- La evidencia es validación propia con confirmaciones de la persona
  usuaria. Se anotaron resultados sin guardar imágenes, video, puntos
  faciales ni credenciales. Quedan pendientes D1, la prueba directa de
  las reglas de Firestore entre UID, la lectura desde una instalación
  nueva y la revisión independiente del bloque.

### Ajuste de la barra lateral · 2026-11-11

La barra normal muestra solo iconos sobre el fondo de Inicio, Historial,
Ajustes y Cuenta. El destino activo se distingue con un recuadro teñido
y los controles ofrecen un área táctil de 48 dp. El cursor revela el
nombre al lado del icono. El toque abre el destino directamente. En el
menú compacto se aplica el fondo del tema y se continúa el aura de
Inicio cuando corresponde.

APK normal en modo Release con firma Android Debug:
`D:/dev/vigia-entrega/vigia-normal-barra-lateral-pruebas.apk`.
SHA-256 `9898bd848ec38bd265e8dd8e338f7047072a9e75b7a99cedcb12314c2054d5ac`.
Se verificó el mismo binario instalado y en primer plano en `vigia_pixel`.
La compilación Debug completó un hot restart y un hot reload.

Validación propia de la primera entrega: 950/950 pruebas Flutter, análisis
sin diagnósticos y registro 500/500. Se actualizaron 34 renderizados y se
añadió una muestra con la etiqueta visible.

### Limpieza de Ajustes · 2026-11-11

Ajustes de la variante normal presenta los controles disponibles y el
aviso «Versión de prueba» en «Acerca de». El alcance futuro de Datos,
Perfil local y Ayuda se consulta en las guías del proyecto. La decisión
OI-08 se registra en la documentación de alcance.

Validación propia: 87/87 pruebas dirigidas, análisis sin diagnósticos y
registro 500/500. Se actualizaron 20 renderizados. El APK normal Release
con firma Android Debug está en
`D:/dev/vigia-entrega/vigia-normal-ajustes-actualizados-pruebas.apk`.
SHA-256 `62adee2afdd0406df5a0836f98360a7997b5cbef8d872bcc77c05c1b586ce5f1`.
Se verificó el binario instalado y se abrió Ajustes en `vigia_pixel`.
La compilación Debug completó un hot restart.

### Etiquetas de navegación al pasar el cursor · 2026-11-11

Validación propia: 90/90 pruebas dirigidas de Cuenta, navegación e Inicio,
análisis sin diagnósticos y registro 500/500. La compilación Debug completó
un hot restart. El APK normal Release con firma Android Debug está en
`D:/dev/vigia-entrega/vigia-normal-etiquetas-cursor-pruebas.apk`.
SHA-256 `b80c46ded51a2624a8fbd88c0236612593016076ae84677dde51b1edfa69eea4`.
Se verificó el mismo binario instalado y abierto en `vigia_pixel`.

### Bienvenida P01 y animaciones del acceso · 2026-11-13 (Claude)

Pedido del usuario: una pantalla previa al acceso que presente Vigía, para
qué sirve y las opciones de iniciar sesión y registrarse, con animaciones.

- `AccountWelcome` (`lib/features/account/presentation/account_welcome.dart`)
  cumple P01 sin cámara ni captura. Contiene el símbolo sobre un halo
  pastel, «Vigía», la finalidad y tres filas: medición ocular con aviso,
  procesamiento en el teléfono sin imágenes ni video, y solo resúmenes en la
  cuenta. Las acciones fijas son «Crear cuenta» e «Iniciar sesión». Una
  línea breve indica «Versión de prueba. No es una ayuda validada para
  conducir», porque P01 exige mostrar las condiciones.
- Animación de entrada única de 1,6 s. Primero aparecen el halo y la marca
  con escala y brillo. Después el símbolo parpadea una vez y el texto, las
  filas y las acciones aparecen de forma escalonada. Con movimiento reducido
  todo se muestra en su estado final. No hay animaciones infinitas.
- `FirebaseAccountScreen` muestra la bienvenida mientras no hay sesión y
  vuelve a ella al cerrar sesión. Usa un fundido con desplazamiento entre
  la bienvenida, los formularios y la verificación. Los formularios tienen
  «Volver», y el botón Atrás de Android regresa a la bienvenida. Contrato
  de Firebase sin cambios.
- Pruebas en `firebase_access_test.dart`: bienvenida, ida y vuelta al
  registro, y movimiento reducido sin animaciones activas. Hay 4 PNG nuevos
  `bienvenida__*` y 8 regenerados `acceso__*` y `registro__*`, porque el
  encabezado ahora incluye «Volver».
- Validación propia: `flutter analyze --no-pub` sin diagnósticos,
  `flutter test` completo 951/951 y registro de especificaciones OK. No se
  compiló APK ni se probó en el emulador. La animación en Android y el
  recorrido con TalkBack quedan pendientes.
