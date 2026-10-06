#!/usr/bin/env bash
# VIG-003 · Compilación reproducible de la base Android y registro de su resolución.
#
# Uso (Git Bash, desde la raíz del repositorio):
#   tools/vig003_build.sh <etiqueta> <directorio_evidencia>
#
# Etiqueta: solo letras ASCII, números, guion y guion bajo ([A-Za-z0-9_-]+). Se
# valida antes de crear, escribir o borrar nada. La evidencia de cada ejecución
# se escribe en una carpeta exclusiva <directorio_evidencia>/<etiqueta>/, y solo
# se reemplazan en ella los archivos exactos que produce el script (lista
# RUN_FILES); nunca se borra por patrones ni se toca evidencia de otra etiqueta
# o de ejecuciones anteriores con nombres planos (p. ej. compilacion-4-*.txt).
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
#      solo se guarda como evidencia válida (gradle-<nombre>.txt) si su consulta
#      termina con 0. Si falla se conserva el diagnóstico como
#      gradle-<nombre>.FALLIDA.txt y la salida final es 6.
# Cada SHA-256 (pubspec.lock antes y después, APK y los tres árboles) es un paso
# comprobado: si sha256sum falla o no devuelve 64 caracteres hexadecimales, el
# script termina con salida 8 identificando el archivo, sin registrar el hash.
# Salida 0 solo si todos los pasos terminan correctamente. 2 = uso o etiqueta
# inválidos, o carpeta de evidencia no utilizable.
set -u
set -o pipefail

readonly EXPECTED_JDK_VERSION='21.0.10'
readonly EXPECTED_JDK_VENDOR='Temurin'
readonly QUERY_NAMES=(debugRuntimeClasspath releaseRuntimeClasspath plugin-releaseRuntimeClasspath)
jdk_home="${VIG003_JDK_HOME:-D:\\Program Files\\Eclipse Adoptium\\jdk-21}"

usage_error() { echo "FALLO en paso 'uso': $1" >&2; exit 2; }

# --- Validación de argumentos ANTES de cualquier operación en disco ----------------
[ "$#" -eq 2 ] || usage_error "uso: tools/vig003_build.sh <etiqueta> <directorio_evidencia>"
label="$1"; out="$2"
[[ "$label" =~ ^[A-Za-z0-9_-]+$ ]] \
  || usage_error "etiqueta inválida '$label': solo letras ASCII, números, '-' y '_' (sin vacío, '.', '/' ni '\\')"
[ -n "$out" ] || usage_error "directorio de evidencia vacío"
[ ! -L "$out" ] || usage_error "el directorio de evidencia '$out' es un enlace simbólico"
[ ! -e "$out" ] || [ -d "$out" ] || usage_error "'$out' existe y no es un directorio"
run_dir="$out/$label"
[ ! -L "$run_dir" ] || usage_error "la carpeta de la etiqueta '$run_dir' es un enlace simbólico"
[ ! -e "$run_dir" ] || [ -d "$run_dir" ] || usage_error "'$run_dir' existe y no es un directorio"

# Archivos exactos de una ejecución (relativos a run_dir). Nada fuera de esta lista se borra.
RUN_FILES=(resumen.txt jdk.txt pub-get.txt flutter-build-apk-debug.txt gradle-version.txt)
for name in "${QUERY_NAMES[@]}"; do
  RUN_FILES+=("gradle-$name.txt" "gradle-$name.FALLIDA.txt" "gradle-$name.tmp")
done

mkdir -p "$run_dir" || usage_error "no se pudo crear '$run_dir'"
# La carpeta real de la ejecución debe ser hija directa de la carpeta de evidencia.
[ "$(cd "$run_dir" && pwd -P)" = "$(cd "$out" && pwd -P)/$label" ] \
  || usage_error "'$run_dir' no resuelve dentro de '$out'"

for f in "${RUN_FILES[@]}"; do
  [ ! -L "$run_dir/$f" ] || usage_error "'$run_dir/$f' es un enlace simbólico"
  rm -f -- "$run_dir/$f" || usage_error "no se pudo retirar '$run_dir/$f'"
done

summary="$run_dir/resumen.txt"
note() { echo "$*" >> "$summary"; }
fail() {  # fail <código> <paso> <detalle>
  note "FALLO en paso '$2': $3"
  note "Resultado: FALLÓ (salida $1)"
  echo "FALLO en paso '$2': $3" >&2
  exit "$1"
}

# hash_file <paso> <archivo> [filtrado]: deja el SHA-256 comprobado en HASH o termina con salida 8.
# "filtrado" excluye las líneas 'Picked up ...' que añade la JVM con JAVA_TOOL_OPTIONS.
HASH=''
hash_file() {
  local step="$1" file="$2" result code
  HASH=''
  if [ "${3:-}" = filtrado ]; then
    result=$(sed '/^Picked up /d' "$file" | sha256sum)
  else
    result=$(sha256sum "$file")
  fi
  code=$?
  [ "$code" -eq 0 ] || fail 8 "hash:$step" "sha256sum de '$file' terminó con salida $code"
  result="${result%% *}"
  [[ "$result" =~ ^[0-9a-f]{64}$ ]] \
    || fail 8 "hash:$step" "sha256sum de '$file' no devolvió un SHA-256 válido: '$result'"
  HASH="$result"
}

echo "# $label · $(date -Iseconds)" > "$summary" \
  || usage_error "no se pudo escribir '$summary'"
hash_file pubspec-antes pubspec.lock
note "## pubspec.lock antes: $HASH"

# 1. JDK requerido (solo para este proceso).
java_bin="$jdk_home/bin/java"
[ -x "$java_bin" ] || [ -x "$java_bin.exe" ] \
  || fail 3 jdk "no existe $java_bin(.exe); se requiere Temurin $EXPECTED_JDK_VERSION (VIG003_JDK_HOME)"
"$java_bin" -version > "$run_dir/jdk.txt" 2>&1 \
  || fail 3 jdk "'$java_bin -version' terminó con error (ver jdk.txt)"
grep -q "version \"$EXPECTED_JDK_VERSION\"" "$run_dir/jdk.txt" && grep -q "$EXPECTED_JDK_VENDOR" "$run_dir/jdk.txt" \
  || fail 3 jdk "$java_bin no es $EXPECTED_JDK_VENDOR $EXPECTED_JDK_VERSION (ver jdk.txt)"
export JAVA_HOME="$jdk_home"
if command -v cygpath > /dev/null 2>&1; then
  PATH="$(cygpath -u "$jdk_home")/bin:$PATH"
else
  PATH="$jdk_home/bin:$PATH"
fi
export PATH
note "JDK: $jdk_home ($(grep -m1 'version' "$run_dir/jdk.txt")); JAVA_HOME y PATH ajustados solo en este proceso"

# 2. Resolución desde el lockfile.
flutter pub get --enforce-lockfile > "$run_dir/pub-get.txt" 2>&1
code=$?
note "flutter pub get --enforce-lockfile: salida $code"
[ "$code" -eq 0 ] || fail 4 pub-get "salida $code; no se compila (ver pub-get.txt)"

# 3. Compilación.
start=$(date +%s)
flutter build apk --debug > "$run_dir/flutter-build-apk-debug.txt" 2>&1
code=$?
note "flutter build apk --debug: salida $code, $(( $(date +%s) - start )) s"
[ "$code" -eq 0 ] || fail 5 build "salida $code; sin APK ni consultas Gradle (ver flutter-build-apk-debug.txt)"
apk=build/app/outputs/flutter-apk/app-debug.apk
[ -f "$apk" ] || fail 5 build "la compilación terminó con 0 pero no existe $apk"
apk_size=$(stat -c %s "$apk") || fail 5 build "no se pudo leer el tamaño de $apk"
hash_file apk "$apk"
note "APK: $apk · $apk_size bytes · SHA-256 $HASH"
hash_file pubspec-despues pubspec.lock
note "## pubspec.lock después: $HASH"

# 4. JVM efectiva de las llamadas directas a gradlew (usa el JAVA_HOME fijado arriba).
( cd android && ./gradlew -version ) > "$run_dir/gradle-version.txt" 2>&1
code=$?
[ "$code" -eq 0 ] || fail 7 gradle-jvm "'gradlew -version' salida $code (ver gradle-version.txt)"
grep -qE "^Launcher JVM: +$EXPECTED_JDK_VERSION " "$run_dir/gradle-version.txt" \
  || fail 7 gradle-jvm "gradlew no usa $EXPECTED_JDK_VERSION (ver gradle-version.txt)"
note "gradlew -version: $(grep -E '^(Gradle |Launcher JVM|Daemon JVM)' "$run_dir/gradle-version.txt" | tr '\n' ';' | sed 's/;$//')"

# 5. Consultas Gradle directas (usan el JAVA_HOME fijado arriba).
failed_queries=()
query() {  # query <nombre> <proyecto> <configuración>
  local name="$1" project="$2" cfg="$3" tmp code dyn
  tmp="$run_dir/gradle-$name.tmp"
  ( cd android && ./gradlew -q "$project:dependencies" --configuration "$cfg" ) > "$tmp" 2>&1
  code=$?
  if [ "$code" -eq 0 ]; then
    # El hash se calcula antes de dar al árbol el nombre de evidencia válida; si falla, queda como .tmp.
    hash_file "gradle-$name" "$tmp" filtrado
    mv -- "$tmp" "$run_dir/gradle-$name.txt" || fail 6 gradle-dependencies "no se pudo guardar gradle-$name.txt"
    dyn=$(grep -cE ':[0-9.]*\+' "$run_dir/gradle-$name.txt")  # grep -c devuelve 1 si cuenta 0
    note "gradle-$name ($project $cfg): salida 0; SHA-256 sin líneas 'Picked up' $HASH; versiones dinámicas '+': $dyn"
  else
    mv -- "$tmp" "$run_dir/gradle-$name.FALLIDA.txt"
    note "gradle-$name ($project $cfg): FALLIDA, salida $code; diagnóstico en gradle-$name.FALLIDA.txt (no es evidencia de resolución)"
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
