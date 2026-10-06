#!/usr/bin/env bash
# VIG-003 · Compilación reproducible de la base Android y registro de su resolución.
#
# Uso (Git Bash, desde la raíz del repositorio):
#   tools/vig003_build.sh <etiqueta> <directorio_evidencia>
#
# Requisitos: flutter en PATH y ANDROID_HOME configurado (docs/toolchain.md).
#
# JDK: el script selecciona explícitamente el Temurin 21 verificado en VIG-002/003
# (VIG003_JDK_HOME, por defecto "D:\Program Files\Eclipse Adoptium\jdk-21") y
# comprueba que `java -version` informa Temurin 21.0.10 antes de empezar. Ajusta
# JAVA_HOME y PATH solo dentro de este proceso: no depende de `flutter config
# --jdk-dir` (que no afecta a las llamadas directas a gradlew) ni del Java que
# tenga el proceso invocador, y no modifica variables persistentes.
#
# Pasos y dependencias (un paso no se ejecuta si falla uno del que depende):
#   1. JDK requerido                     -> si falla: salida 3, no se ejecuta nada más
#   2. flutter pub get --enforce-lockfile -> si falla: salida 4, no se compila
#   3. flutter build apk --debug          -> si falla: salida 5, sin APK ni consultas Gradle
#   4. JVM de las llamadas directas a Gradle: `gradlew -version` debe informar
#      Launcher JVM 21.0.10              -> si falla: salida 7, sin consultas
#   5. Tres consultas de dependencias Gradle (independientes entre sí). Un árbol
#      solo se guarda como evidencia válida (<etiqueta>-gradle-<cfg>.txt) si su
#      consulta termina con 0. Si falla se conserva el diagnóstico como
#      <etiqueta>-gradle-<cfg>.FALLIDA.txt y la salida final es 6.
# Salida 0 solo si todos los pasos terminan correctamente. 2 = uso incorrecto.
set -u
set -o pipefail

readonly EXPECTED_JDK_VERSION='21.0.10'
readonly EXPECTED_JDK_VENDOR='Temurin'
jdk_home="${VIG003_JDK_HOME:-D:\\Program Files\\Eclipse Adoptium\\jdk-21}"

if [ "$#" -ne 2 ]; then
  echo "uso: tools/vig003_build.sh <etiqueta> <directorio_evidencia>" >&2
  exit 2
fi
label="$1"; out="$2"
mkdir -p "$out" || { echo "FALLO en paso 'evidencia': no se pudo crear $out" >&2; exit 2; }
log="$out/$label"
summary="$log-resumen.txt"

note() { echo "$*" >> "$summary"; }
fail() {  # fail <código> <paso> <detalle>
  note "FALLO en paso '$2': $3"
  note "Resultado: FALLÓ (salida $1)"
  echo "FALLO en paso '$2': $3" >&2
  exit "$1"
}
sha_of() { sha256sum "$1" | cut -d' ' -f1; }

# Retira evidencia previa con la misma etiqueta para no presentar resultados viejos como nuevos.
rm -f "$log"-resumen.txt "$log"-jdk.txt "$log"-gradle-version.txt "$log"-pub-get.txt "$log"-flutter-build-apk-debug.txt \
      "$log"-gradle-*.txt

{
  echo "# $label · $(date -Iseconds)"
  echo "## pubspec.lock antes: $(sha_of pubspec.lock)"
} > "$summary" || { echo "FALLO en paso 'evidencia': no se pudo escribir $summary" >&2; exit 2; }

# 1. JDK requerido (solo para este proceso).
java_bin="$jdk_home/bin/java"
[ -x "$java_bin" ] || [ -x "$java_bin.exe" ] \
  || fail 3 jdk "no existe $java_bin(.exe); se requiere Temurin $EXPECTED_JDK_VERSION (VIG003_JDK_HOME)"
"$java_bin" -version > "$log-jdk.txt" 2>&1 \
  || fail 3 jdk "'$java_bin -version' terminó con error (ver $(basename "$log")-jdk.txt)"
grep -q "version \"$EXPECTED_JDK_VERSION\"" "$log-jdk.txt" && grep -q "$EXPECTED_JDK_VENDOR" "$log-jdk.txt" \
  || fail 3 jdk "$java_bin no es $EXPECTED_JDK_VENDOR $EXPECTED_JDK_VERSION (ver $(basename "$log")-jdk.txt)"
export JAVA_HOME="$jdk_home"
if command -v cygpath > /dev/null 2>&1; then
  PATH="$(cygpath -u "$jdk_home")/bin:$PATH"
else
  PATH="$jdk_home/bin:$PATH"
fi
export PATH
note "JDK: $jdk_home ($(head -n 2 "$log-jdk.txt" | tail -n 1)); JAVA_HOME y PATH ajustados solo en este proceso"

# 2. Resolución desde el lockfile.
flutter pub get --enforce-lockfile > "$log-pub-get.txt" 2>&1
code=$?
note "flutter pub get --enforce-lockfile: salida $code"
[ "$code" -eq 0 ] || fail 4 pub-get "salida $code; no se compila (ver $(basename "$log")-pub-get.txt)"

# 3. Compilación.
start=$(date +%s)
flutter build apk --debug > "$log-flutter-build-apk-debug.txt" 2>&1
code=$?
note "flutter build apk --debug: salida $code, $(( $(date +%s) - start )) s"
[ "$code" -eq 0 ] || fail 5 build "salida $code; sin APK ni consultas Gradle (ver $(basename "$log")-flutter-build-apk-debug.txt)"
apk=build/app/outputs/flutter-apk/app-debug.apk
[ -f "$apk" ] || fail 5 build "la compilación terminó con 0 pero no existe $apk"
note "APK: $apk · $(stat -c %s "$apk") bytes · SHA-256 $(sha_of "$apk")"
note "## pubspec.lock después: $(sha_of pubspec.lock)"

# 4. JVM efectiva de las llamadas directas a gradlew (usa el JAVA_HOME fijado arriba).
( cd android && ./gradlew -version ) > "$log-gradle-version.txt" 2>&1
code=$?
[ "$code" -eq 0 ] || fail 7 gradle-jvm "'gradlew -version' salida $code (ver $(basename "$log")-gradle-version.txt)"
grep -qE "^Launcher JVM: +$EXPECTED_JDK_VERSION " "$log-gradle-version.txt" \
  || fail 7 gradle-jvm "gradlew no usa $EXPECTED_JDK_VERSION (ver $(basename "$log")-gradle-version.txt)"
note "gradlew -version: $(grep -E '^(Gradle |Launcher JVM|Daemon JVM)' "$log-gradle-version.txt" | tr '\n' ';' | sed 's/;$//')"

# 5. Consultas Gradle directas (usan el JAVA_HOME fijado arriba).
failed_queries=()
query() {  # query <nombre> <proyecto> <configuración>
  local name="$1" project="$2" cfg="$3" tmp code dyn
  tmp="$log-gradle-$name.tmp"
  ( cd android && ./gradlew -q "$project:dependencies" --configuration "$cfg" ) > "$tmp" 2>&1
  code=$?
  if [ "$code" -eq 0 ]; then
    mv "$tmp" "$log-gradle-$name.txt"
    dyn=$(grep -cE ':[0-9.]*\+' "$log-gradle-$name.txt")  # grep -c devuelve 1 si cuenta 0
    note "gradle-$name ($project $cfg): salida 0; SHA-256 sin líneas 'Picked up' $(grep -v '^Picked up' "$log-gradle-$name.txt" | sha256sum | cut -d' ' -f1); versiones dinámicas '+': $dyn"
  else
    mv "$tmp" "$log-gradle-$name.FALLIDA.txt"
    note "gradle-$name ($project $cfg): FALLIDA, salida $code; diagnóstico en $(basename "$log")-gradle-$name.FALLIDA.txt (no es evidencia de resolución)"
    failed_queries+=("$name")
  fi
}
query debugRuntimeClasspath :app debugRuntimeClasspath
query releaseRuntimeClasspath :app releaseRuntimeClasspath
query plugin-releaseRuntimeClasspath :monitoring_engine releaseRuntimeClasspath

if [ "${#failed_queries[@]}" -gt 0 ]; then
  fail 6 gradle-dependencies "consultas fallidas: ${failed_queries[*]}"
fi
note "Resultado: OK (salida 0)"
exit 0
