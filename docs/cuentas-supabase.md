# Vigía · Cuentas e historial por cuenta

El usuario eligió Firebase para la publicación. La guía vigente es
[Cuentas e historial por cuenta con Firebase](cuentas-firebase.md). Este
documento conserva el plan anterior.

El usuario eligió **Supabase Auth + PostgreSQL** el 2026-11-10. Este bloque
parte de la variante normal con P03, preparación por pasos y P06. El APK
local de P06 ya está compilado. Las cuentas, el esquema remoto y la
sincronización están por implementar. El estado de las comprobaciones
anteriores está en [Estado del prototipo](estado-prototipo.md).

## Decisiones del primer bloque

- **Acceso por código de correo.** «Crear cuenta» permite dar de alta un
  correo nuevo. «Iniciar sesión» solicita un código para una cuenta existente.
  Ambas acciones llevan a «Verificar código». Supabase emite y renueva los
  tokens. Flutter confirma el acceso al recibir una sesión válida y guarda
  las credenciales de sesión en almacenamiento seguro de Android. La UI
  muestra mensajes de acceso y envío que no revelen si un correo está registrado.
  [Acceso por correo](https://supabase.com/docs/guides/auth/auth-email-passwordless)
- **Monitoreo local.** Kotlin sigue siendo la fuente durable. Internet se
  usa para autenticar o sincronizar, fuera de la ruta de cámara, calibración,
  evaluación y avisos. Una cuenta ya reconocida en el dispositivo puede
  guardar localmente sin conexión. La primera verificación y el cambio a
  otra cuenta requieren conexión. El perfil local anterior permite seguir
  consultando registros históricos locales, separados de las cuentas.
- **Propietario fijado al empezar.** Al confirmar el inicio, el hecho de
  apertura en el journal conserva el UUID de la cuenta o el ámbito local.
  En una misma transacción se graban la apertura y su propietario. Al
  recuperar una sesión interrumpida se conserva ese propietario. El puente
  transmite el identificador, sin tokens. Los hechos anteriores se importan
  como locales y conservan sus hashes originales. Su incorporación a una
  cuenta sería una acción explícita posterior.
- **Solo resúmenes durables.** Sincronizar cierres completos y sesiones
  interrumpidas confirmadas por el journal. Los abiertos y los incompletos
  se muestran localmente con su estado. Los resúmenes remotos contienen ID
  de sesión, propietario, estado, fechas confirmadas, tiempos y contadores
  aplicables. Una interrumpida conserva el último registro confirmado y el
  final desconocido. Cámara, video, puntos faciales, EAR por muestra y
  referencias de calibración se quedan fuera de la sincronización.

## Configurar Supabase de desarrollo

1. Crea un proyecto **`vigia-dev`** en [Supabase Dashboard](https://supabase.com/dashboard)
   dentro de tu organización. Elige la región más cercana a quienes harán
   la prueba. Guarda la contraseña de la base en tu gestor de contraseñas.
   Usa este proyecto para datos de prueba. Producción tendrá otro proyecto.
2. En **Connect** copia la URL del proyecto y en **Settings → API Keys**
   localiza la clave **Publishable** (`sb_publishable_…`). Son los valores que
   necesitará el cliente con los nombres `SUPABASE_URL` y
   `SUPABASE_PUBLISHABLE_KEY`. La contraseña de Postgres, la clave secreta y
   `service_role` son credenciales administrativas. Consérvalas fuera del
   APK, del repositorio y de los chats. [Claves de Supabase](https://supabase.com/docs/guides/getting-started/api-keys)
3. En **Authentication → Sign In / Providers** revisa que **Email** y el
   registro de nuevos usuarios estén habilitados en desarrollo. En
   **Authentication → Email Templates**, edita **Magic Link** para mostrar
   el código `{{ .Token }}` en el cuerpo en vez de un enlace. La longitud
   acordada para la primera versión es seis dígitos. La interfaz recibe esa
   longitud y el plazo de reenvío desde el integrador. [OTP por correo](https://supabase.com/docs/guides/auth/auth-email-passwordless#with-otp)
4. Prepara dos buzones bajo tu control para probar A y B. El SMTP incluido
   se limita a miembros del equipo del proyecto. Para probar con direcciones
   externas y antes de abrir el registro al público, configura **Custom SMTP**
   en **Authentication → Emails → SMTP Settings**, con un remitente verificado
   y credenciales configuradas en Supabase. [SMTP de Supabase](https://supabase.com/docs/guides/auth/auth-smtp)
5. Deja que la integración agregue el esquema y las políticas mediante
   migraciones versionadas en `supabase/migrations/`. El proyecto remoto de
   desarrollo se verifica antes de aplicar una migración. Las pruebas se
   ejecutan con el rol de usuarios autenticados, además de la prueba sin
   cuenta. [Migraciones de Supabase](https://supabase.com/docs/guides/local-development/database-migrations)

## Orden de integración y comprobación

| Paso | Entrega | Comprobación |
|---|---|---|
| 1. Esquema y autorización | Tabla `session_summaries` con clave compuesta `(user_id, session_id)`, `user_id` relacionado con `auth.users.id`, estados y campos mínimos. RLS para lectura e inserción con `auth.uid()` igual al propietario. Actualización y borrado se reservan para el flujo de gestión de datos. | A inserta y recupera sus filas. B no lee ni modifica las de A aunque conozca el ID. B no puede escribir con `user_id` de A. Una petición anónima queda rechazada. |
| 2. Cuenta en Flutter | Inicializar `supabase_flutter` solo en la variante normal con la URL y la clave publicable. Permiso de red en esa variante. El SDK solicita OTP con `shouldCreateUser` según el modo y verifica con `OtpType.email`. El integrador restaura y renueva la sesión, adapta errores y conecta las vistas a las rutas. | Registro, acceso, cierre de sesión de la cuenta, restauración tras reinicio, código erróneo o caducado, reenvío y ausencia de conexión. Cerrar sesión o cambiar de cuenta queda bloqueado mientras haya un inicio pendiente o una sesión de monitoreo vigente. |
| 3. Propietario y proyección local | Extender la apertura del journal y su proyección Drift con un propietario inmutable, compatible con hechos anteriores. Inicio, Historial, detalle y sus rutas filtran por el ámbito activo. Limpiar la vista y las consultas pendientes al cambiar de cuenta. | A y B usan el mismo teléfono. Las filas de A quedan fuera de vistas y rutas de B, incluso sin conexión o tras reinicio. Una sesión interrumpida conserva su cuenta. Un registro previo sigue disponible en el ámbito local. |
| 4. Sincronización | Cola persistente por cuenta. Reintentar con el mismo ID y confirmar que existe la misma fila antes de marcarla sincronizada si ya estaba subida. En una segunda instalación, los registros remotos se rotulan como resúmenes y muestran los campos disponibles. | Finalizar sin red, reiniciar y volver a conectar produce un solo resumen. Al cambiar de cuenta, las subidas pendientes de A quedan retenidas hasta volver a A. Una respuesta tardía de A no aparece en B. La DEMO nunca conecta ni se sincroniza. |
| 5. Distribución | Preparar el entorno de producción, política de datos y eliminación de cuenta, correo, migraciones revisadas y APK firmado. | Repetir el aislamiento con dos cuentas, comprobar la instalación y el recorrido real en Android, y adjuntar el APK a GitHub Releases después de la revisión. |

El paso 1 usa la política por propietario como control en la base, además
del filtro de Flutter. En el paso 4, una subida incluye el propietario
grabado al crear la sesión y solo sale con la cuenta correspondiente. Si el
estado de identidad es incierto, la subida espera una sesión válida. La
conexión tampoco debe bloquear el cierre durable en Kotlin.
[RLS](https://supabase.com/docs/guides/database/postgres/row-level-security) ·
[Verificación OTP en Flutter](https://supabase.com/docs/reference/dart/auth-verifyotp) ·
[GitHub Releases](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository)

## Contrato para el chat de interfaz

El chat de interfaz trabaja en `lib/features/account/presentation/` y
`test/account/presentation/`. Reutiliza los tokens y componentes de Vigía
de `lib/core/design_system/`. Entrega vistas que reciben su estado y
acciones del integrador. Las pruebas simulan esas acciones. La integración
se encarga de `pubspec.yaml`, el SDK, bootstrap, rutas globales y datos.

| Vista | Entradas | Acciones |
|---|---|---|
| `AccountEmailScreen` | `AccountAccessMode` (`signIn` o `signUp`), `initialEmail`, `isSubmitting` y `errorText` opcional. | `onSubmit(String email)`, `onSwitchMode()` y `onBack` opcional. |
| `AccountCodeScreen` | `email`, `codeLength`, `isVerifying`, `isResending`, `resendAvailableIn` (`Duration`), `notice` y `errorText` opcionales. El integrador suministra el estado y el tiempo. | `onVerify(String code)`, `onResend()` y `onChangeEmail()`. |

- Copys principales: «Iniciar sesión», «Crear cuenta», «Enviar código»,
  «Verificar código», «Reenviar código» y «Cambiar correo». Los formularios
  aceptan pegado de correo y código. El reenvío y la verificación muestran
  progreso y evitan duplicar solicitudes.
- Prever correo inválido, código incorrecto o caducado, tiempo restante de
  reenvío y falta de conexión. El error puede anunciarse con TalkBack y la
  acción primaria sigue alcanzable con teclado y texto ampliado.
- Probar claro y oscuro al 100 % y al 200 %, al menos a 320 y 360 dp,
  con botones de 48×48 dp o mayores. Entregar pruebas de widgets y
  renderizados identificados como datos de prueba. La navegación global
  será responsabilidad del integrador.
