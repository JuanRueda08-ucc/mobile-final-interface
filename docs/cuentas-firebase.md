# Cuentas e historial por cuenta con Firebase

Vigía usa Firebase Authentication con correo, contraseña y verificación
por enlace. Cloud Firestore guarda resúmenes de sesiones experimentales
por UID. La detección facial y el registro de hechos se ejecutan en el
teléfono. A Firestore llegan fechas, estado, integridad y agregados
confirmados. La cámara, las muestras oculares, la calibración y la línea
temporal se quedan en el teléfono.

## Configurar el servicio alojado

Proyecto registrado de Vigía: `vigia-e1680`. La app Android
`com.juanrueda.vigia` se comprobó contra el archivo de configuración
facilitado por el usuario. Las definiciones de compilación generadas quedan
en `.dart_tool/vigia-firebase.json`.

1. Crea el proyecto Vigía en la [consola de Firebase](https://console.firebase.google.com/).
2. Registra una app Android con el paquete `com.juanrueda.vigia`.
   Descarga su `google-services.json`.
3. En Authentication, habilita el proveedor **Correo electrónico/contraseña**.
   Revisa las plantillas de verificación y recuperación. Configura una
   política de contraseña con mínimo de ocho caracteres, como el formulario.
4. En Firestore Database, crea la base predeterminada en edición Standard
   y modo de producción. Guarda el ID del proyecto.
5. Con [Firebase CLI](https://firebase.google.com/docs/cli) autenticado y
   acceso al proyecto, despliega las reglas versionadas.

```powershell
firebase login
firebase deploy --only firestore:rules --project ID_DEL_PROYECTO
```

La app lee solo `users/{uid}/sessions/{id}`. Las reglas exigen el UID del
propietario y un correo verificado. El identificador del journal es la clave
de sincronización. Si el servidor ya tiene el mismo resumen, el reintento
confirma la copia local sin crear otra. Si la proyección detecta posteriormente
un error de integridad, las reglas permiten retirar los totales publicados.
Los registros anteriores a las cuentas conservan su perfil local.

## Compilar el APK

```powershell
python tools/firebase_build_config.py "RUTA\google-services.json"
flutter build apk --release --dart-define-from-file=.dart_tool/vigia-firebase.json
```

El script verifica el paquete Android y deja las definiciones dentro de
`.dart_tool`. El APK con cuentas habilita red. Las compilaciones de
prototipo sin esa configuración y la variante DEMO release mantienen sus
manifiestos sin acceso a Internet.

En una copia nueva, ejecuta `flutter pub get` antes de usar `--no-pub`.
El registro generado `.flutter-plugins-dependencies` permite incluir los
plugins de Android. Comprueba que el APK incluye `libdartjni.so` y
`libmediapipe_tasks_jni.so` para las ABI entregadas y que abre el acceso.

Para la publicación, configura una clave de distribución en
`android/key.properties` con `storeFile`, `storePassword`, `keyAlias` y
`keyPassword`. Usa la misma clave para futuras actualizaciones. Gradle usa
la clave de depuración para compilar sin esa configuración. Comprueba el
certificado del APK destinado a GitHub Releases con `apksigner verify
--print-certs` y publica su SHA-256 junto al archivo. Una instalación
previa con otra firma requiere reinstalación. Conserva sus datos antes de
desinstalar si los necesitas.

## Comprobar antes de publicar

- Crea dos cuentas reales. Antes de verificar el correo, comprueba que
  Inicio y las rutas de Historial están bloqueados. Verifica el correo de
  cada cuenta, reinicia la app y prueba recuperar la contraseña.
- Completa una sesión con A. Cierra sesión desde Cuenta y abre B. Comprueba
  que B no ve el resumen de A y que Firestore rechaza una lectura o escritura
  cruzada. Prueba una escritura con un campo ajeno al resumen y otra desde
  una cuenta sin verificar.
- Cierra una sesión con A sin red. Al recuperar red, vuelve a Historial y
  reintenta. Comprueba que existe un solo documento. Inicia A desde otra
  instalación y abre el resumen sincronizado.
- Revisa la pantalla de acceso en tema claro y oscuro con texto al 200 %.
  Comprueba la acción principal, el desplazamiento y el foco con el teclado.
- Verifica el APK final y su firma. La prueba de cámara real y calibración
  se completa en Android físico cuando esté disponible.

El [guion de Cuenta, navegación y acceso](bloque-cuenta-navegacion.md#recorrido-guiado-en-vigia-e1680)
documenta la prueba guiada con webcam y dos cuentas en el proyecto alojado.

## Publicar en GitHub Releases

Con la compilación validada y el código aprobado disponible en GitHub,
crea una etiqueta para esa revisión. Adjunta el APK firmado y publica su
SHA-256 en las notas. Comprueba que el archivo se puede descargar desde la
vista pública del repositorio.

```powershell
gh auth status
Get-FileHash build/app/outputs/flutter-apk/app-release.apk -Algorithm SHA256
gh release create TAG build/app/outputs/flutter-apk/app-release.apk --verify-tag --generate-notes
```

## Trabajo de interfaz con dobles

La ruta de acceso activa usa `FirebaseAccountScreen` y comparte
`AccountForm` con el trabajo de interfaz anterior. Para otro chat, usa este
encargo.

> Revisa acceso, registro, verificación por enlace y recuperación de Vigía
> con el sistema B5.2. Reutiliza AccountForm y los componentes de Vigía.
> Trabaja sobre la presentación y usa dobles para los estados de
> Firebase Authentication. Comprueba claro, oscuro y texto al 200 %.
> Conserva el contrato de verificación por enlace y coordina cualquier
> cambio de rutas, SDK o persistencia con el bloque de integración.
