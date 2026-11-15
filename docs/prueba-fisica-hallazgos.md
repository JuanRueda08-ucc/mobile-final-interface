# Hallazgos de la prueba en teléfono físico (2026-11-15)

El usuario instaló el APK publicado en `9ae65af`, con firma Debug y
`vigia-e1680`, en un teléfono Android físico y lo probó en persona. Los
hallazgos son observaciones suyas. El dispositivo y la versión de Android
aún no están registrados. El usuario adjuntará un GIF de referencia para
el monitoreo. **Pendiente de implementar**: ningún punto tiene código
todavía.

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

## 2. Animaciones y aspecto general

- El usuario ve la aplicación «muy plana» fuera de la bienvenida. Pide
  animaciones en todo el recorrido, como cambios de estado, tarjetas,
  aviso y transiciones, respetando siempre el movimiento reducido.

## 3. Barra lateral

- No le gusta la barra fija. Quiere una **barra desplegable**: cerrada,
  solo se ven la pantalla y el botón de menú (tres rayas); abierta, entra
  deslizando una columna de iconos (solo iconos). Hoy la barra es fija a
  partir de 360 dp sin texto ampliado, y solo usa cajón en pantallas
  estrechas o con texto ampliado (`VigiaScaffold`).

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

## 5. Otros

- El usuario indicó que hay «más cositas» sin detallar. Se añadirán aquí.

## Orden sugerido

1. Estabilidad de P06, por ser un defecto.
2. Rediseño de P06 con el GIF.
3. Voz en la calibración.
4. Barra lateral desplegable.
5. Animaciones en el resto del recorrido.
