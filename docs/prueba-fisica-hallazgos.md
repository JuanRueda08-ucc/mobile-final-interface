# Hallazgos de la prueba en teléfono físico (2026-11-15)

El usuario instaló el APK publicado en `9ae65af`, con firma Debug y
`vigia-e1680`, en un teléfono Android físico y lo probó en persona. Los
hallazgos son observaciones suyas. El dispositivo y la versión de Android
aún no están registrados. El usuario adjuntará un GIF de referencia para
el monitoreo. Están aplicados los puntos 1 (estabilidad), 3 (barra) y 4 (voz); se añadieron animaciones base. Falta el rediseño de P06 con el GIF.

## 1. Pantalla de monitoreo (P06)

- El usuario quiere rediseñarla tomando como base el GIF que enviará.
- **Inestabilidad durante la sesión activa.** El estado alternaba entre
  «Sin señales persistentes» y «No evaluable» (o «ninguna señal
  percibida»). La pantalla «titilaba»: al cambiar la frase cambiaba el
  tamaño y se movía la vista previa.
- Diagnóstico en el código, sin reproducir todavía en el teléfono:
  - En `experimental_monitoring_screen.dart`, `_sessionStatus` crea una
    `StatusCard` distinta según la señal. «Sin señales persistentes» tiene
    un texto corto fijo. «No evaluable» usa `eyeIssueText(...)`, con causas
    de una o varias líneas («Los resultados llegan con retraso», «Hubo un
    hueco entre observaciones», «El último resultado llegó tarde y no se
    usa»…). La tarjeta va **encima** de la vista previa
    (`FrontCameraStage`). Cada cambio de alto desplaza la cámara y todo lo
    que sigue.
  - Las causas temporales (`resultsDelayed`, `gap`, `staleResult`) indican
    que, en ese teléfono, los resultados de MediaPipe llegan con pausas
    mayores que las que admite el perfil `lab-eye-rules-0.1`. Es la
    intermitencia conocida de «No evaluable». Los umbrales no se cambian
    sin una decisión expresa.
- Corrección propuesta para la interfaz:
  - un área de estado de alto fijo, con la causa en una sola línea
    reservada;
  - transiciones de color y texto en lugar de cambiar el tamaño;
  - la vista previa en una posición estable.
  - Se puede añadir una suavización solo visual entre «Sin señales» y «No
    evaluable», por ejemplo mostrar el cambio si dura ≥ 1 s. El aviso de
    cierre prolongado se muestra siempre al instante. La suavización se
    documenta como presentación y no cambia el motor ni el registro.

### Corrección aplicada (2026-11-15, Claude)

- `SteadyHeight` (`lib/core/design_system/widgets/steady_height.dart`):
  durante la sesión, el área de estado y el grupo de ojos solo crecen.
  Recuerdan el alto máximo y el crecimiento se anima. Se reinician al pausar
  o al cambiar el ancho o la escala del texto. La tarjeta ocupa el alto
  reservado y la vista previa ya no salta al cambiar la frase.
- `_Paced` en `experimental_monitoring_screen.dart`: durante la sesión, la
  señal mostrada y «Ojos medibles» cambian como mucho una vez por segundo.
  El primer cambio se ve al instante. Los siguientes esperan al segundo y
  entonces se muestra el valor vigente. El aviso de cierre prolongado entra
  y sale al instante, sin fundido. Los demás cambios de tarjeta se funden en
  220 ms; con movimiento reducido no hay animación. El valor se resuelve en
  cada dibujo, porque la señal caduca con el tiempo sin notificar. Es solo
  presentación: el motor, el registro y los umbrales no cambian.
- Pruebas:
  - nueva regresión en `experimental_monitoring_test.dart`;
  - la prueba de pérdida de conexión espera el fundido;
  - el arnés de `fase5c_render_test.dart` simula un motor y una cámara que
    siguen emitiendo cada 100 ms;
  - se regeneraron 4 capturas de P06 a 320 dp al 200 %, con el alto
    reservado.
- Validación propia: análisis sin diagnósticos, 952/952 pruebas y registro
  OK.
- APK: `D:/dev/vigia-entrega/vigia-normal-sesion-estable-pruebas.apk`,
  100 293 159 bytes. SHA-256
  `f5e01327e6b319a4518001363f1a672576b3eac06c6e498eba63ecf234507808`. No se
  probó en el teléfono físico. El usuario debe confirmar que ya no titila.
  La intermitencia del motor sigue y se ve, como mucho, una vez por segundo.

## 2. Animaciones y aspecto general

- El usuario ve la aplicación «muy plana» fuera de la bienvenida. Pide
  animaciones en todo el recorrido, como cambios de estado, tarjetas,
  aviso y transiciones, respetando siempre el movimiento reducido.

### Animaciones aplicadas (2026-11-15, Claude)

- `lib/core/design_system/widgets/motion.dart` contiene `EntranceItem`,
  `PulseOnce` y `PopSwitcher`. Son finitas y se anulan con movimiento
  reducido.
- Entrada de pantallas: `VigiaScaffold` envuelve cada bloque en
  `EntranceItem`, con fundido y 14 px de subida. El escalonado es de 25 ms
  por bloque, hasta 6, más 260 ms de animación; se ejecuta una vez. Al
  terminar se retiran los envoltorios y una `GlobalKey` conserva el estado
  del contenido (foco, texto, desplazamiento). Así las capturas no cambian
  por ruido de subpíxel.
- `StatusCard`: el color y el borde cambian con `AnimatedContainer`, y el
  icono entra con escala (`PopSwitcher`). En el aviso de cierre prolongado
  el icono late 3 veces al aparecer (`PulseOnce`).
- `CheckRow`: la marca ✓/✗ cambia de color y entra con un rebote de escala.
- Pruebas: en el motor simulado, `keepFresh()` y una observación nueva tras
  confirmar el sonido. La entrada alarga las esperas de las pruebas y la
  validez de una misma observación caducaba, algo que no ocurre con el
  motor real, que emite sin parar. En `experimental_lifecycle_test.dart` se
  emite un estado nuevo tras abrir. La prueba del resumen DEMO espera a que
  termine la entrada antes de comprobar que no hay animaciones.
- Validación propia: análisis sin diagnósticos, 953/953 pruebas y registro
  OK. No cambió ninguna captura.
- APK: `D:/dev/vigia-entrega/vigia-normal-animaciones-pruebas.apk`,
  100 309 575 bytes. SHA-256
  `15e81106a4626763ecfac33bb9e5f4d9c99f67d36eaeeda87a8d703c8a466ab8`. No se
  probó en el teléfono.

## 3. Barra lateral

- No le gusta la barra fija. Quiere una **barra desplegable**: cerrada,
  solo se ven la pantalla y el botón de menú (tres rayas); abierta, entra
  deslizando una columna de iconos (solo iconos). Hoy la barra es fija a
  partir de 360 dp sin texto ampliado, y solo usa cajón en pantallas
  estrechas o con texto ampliado (`VigiaScaffold`).

### Barra desplegable aplicada (2026-11-15, Claude)

- `VigiaScaffold` usa el cajón en todos los tamaños (`compact = side`). Se
  retira la columna fija de 360 dp. Cerrada, solo se ve el botón de menú
  («Abrir navegación») junto a la marca, y el contenido ocupa todo el
  ancho. Abierta, la columna de iconos entra deslizando desde la izquierda,
  con el borde derecho redondeado (28) y la pantalla oscurecida. Al elegir
  un destino se cierra. Se conservan las áreas de 48 dp, la semántica
  seleccionada y la etiqueta al pasar el cursor.
- Pruebas adaptadas: en `account_navigation_test.dart`, la barra cerrada
  por defecto y la etiqueta con la barra abierta; en
  `real_preferences_test.dart`, se abre el menú antes de ir a Ajustes. Se
  regeneraron 37 capturas de Inicio, Historial, Ajustes, Cuenta y
  navegación a 360 dp. Hay capturas nuevas `cuenta_panel__*_360_100`.
- Validación propia: análisis sin diagnósticos, 953/953 pruebas y registro
  OK.
- APK: `D:/dev/vigia-entrega/vigia-normal-barra-desplegable-pruebas.apk`,
  100 309 575 bytes. SHA-256
  `a5ebdeb01f88b0bbcf69b891bfab29030af5bcad634e458f065e5c993b1d2be2`. No
  se probó en el teléfono.

## 4. Calibración con voz

- El tono solo no deja claro cuándo abrir o cerrar los ojos, y el texto en
  pantalla «no se nota mucho». Propuesta: **narración por voz** de las
  instrucciones de calibración, por ejemplo «Abre los ojos y mira a la
  cámara», «Cierra los ojos», «Ábrelos» y «Calibración aceptada».
- Implementación prevista: síntesis de voz del sistema Android
  (`TextToSpeech`), en el motor Kotlin o con un plugin. No usa micrófono ni
  red. Depende de que el teléfono tenga una voz en español; si no la tiene,
  se mantienen el tono y el texto. Se puede activar o desactivar en
  Ajustes › Sonido. El texto en pantalla también debe ganar jerarquía.

### Voz guía aplicada (2026-11-15, Claude)

- Canal nativo `vigia/voice` en `MainActivity.kt` con `TextToSpeech`. Usa
  la voz `es` del sistema y audio de accesibilidad, sin micrófono ni red.
  El motor se inicia la primera vez que se pide una frase. Si no hay motor
  o voz en español, devuelve la causa. El manifiesto declara la consulta
  `TTS_SERVICE`, que Android 11+ exige.
- `lib/core/audio/voice_guide.dart` contiene `VoiceGuide`,
  `AndroidVoiceGuide` y el interruptor `calibrationVoiceEnabledProvider`.
  El interruptor vive solo durante la ejecución y está activado por
  defecto. Sin canal nativo, como en las pruebas, no muestra aviso.
- Narración en P04 › Calibración (`calibrationVoice`): «Mira al frente con
  los ojos abiertos.», «Cierra los ojos. Mantenlos cerrados hasta oír el
  pitido.», «Abre los ojos y mira al frente.», «Calibración aceptada.» y
  «Calibración no aceptada. Puedes intentarlo de nuevo.». Solo se narran
  los cambios ocurridos con la pantalla abierta. «Aceptada» o «rechazada»
  solo se dicen tras una calibración vista en curso. La voz se detiene al
  salir, al ir a segundo plano o al desactivarla.
- El botón «Voz guía activada/desactivada» va bajo la instrucción. Si
  Android no puede hablar, aparece «Sin voz: <causa>. Sigue el texto y el
  tono.». Los títulos de las instrucciones de calibración pasan de 22 a
  28.
- Prueba nueva con voz simulada: comprueba las frases en orden, que no se
  narra al abrir con una calibración aceptada y que el interruptor detiene
  y silencia. Se regeneraron 6 capturas `F5C_calibracion_*`.
- Validación propia: análisis sin diagnósticos, 953/953 pruebas y registro
  OK.
- APK: `D:/dev/vigia-entrega/vigia-normal-voz-calibracion-pruebas.apk`,
  100 309 575 bytes. SHA-256
  `e5c77120df0200ae90cfe1f17e68199a28d69bcf4c2cf2aa26f580993a28ea43`.
- Sin comprobar: la voz real en el teléfono, la voz en español instalada y
  el solapamiento con el pitido de la calibración. El interruptor aún no se
  guarda en Ajustes › Sonido, porque requiere migrar la tabla de
  preferencias.

## 5. Otros

- El usuario indicó que hay «más cositas» sin detallar. Se añadirán aquí.

## Orden sugerido

1. Estabilidad de P06, por ser un defecto.
2. Rediseño de P06 con el GIF.
3. Voz en la calibración.
4. Barra lateral desplegable.
5. Animaciones en el resto del recorrido.
