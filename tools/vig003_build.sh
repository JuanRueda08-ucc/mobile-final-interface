#!/usr/bin/env bash
# VIG-003 · Compilación reproducible de la base Android y registro de su resolución.
# Uso (Git Bash, desde la raíz del repo): tools/vig003_build.sh <etiqueta> <directorio_evidencia>
# Requiere en el entorno: flutter en PATH, ANDROID_HOME, JAVA_HOME (o jdk-dir de Flutter).
set -u
label="$1"; out="$2"
mkdir -p "$out"
log="$out/$label"

{
  echo "# $label · $(date -Iseconds)"
  echo "## pubspec.lock antes: $(sha256sum pubspec.lock | cut -d' ' -f1)"
} > "$log-resumen.txt"

flutter pub get --enforce-lockfile > "$log-pub-get.txt" 2>&1
echo "flutter pub get --enforce-lockfile: salida $?" >> "$log-resumen.txt"

start=$(date +%s)
flutter build apk --debug > "$log-flutter-build-apk-debug.txt" 2>&1
code=$?
echo "flutter build apk --debug: salida $code, $(( $(date +%s) - start )) s" >> "$log-resumen.txt"

apk=build/app/outputs/flutter-apk/app-debug.apk
if [ -f "$apk" ]; then
  echo "APK: $apk · $(stat -c %s "$apk") bytes · SHA-256 $(sha256sum "$apk" | cut -d' ' -f1)" >> "$log-resumen.txt"
fi
echo "## pubspec.lock después: $(sha256sum pubspec.lock | cut -d' ' -f1)" >> "$log-resumen.txt"

( cd android && ./gradlew -q :app:dependencies --configuration debugRuntimeClasspath ) \
  > "$log-gradle-debugRuntimeClasspath.txt" 2>&1
( cd android && ./gradlew -q :app:dependencies --configuration releaseRuntimeClasspath ) \
  > "$log-gradle-releaseRuntimeClasspath.txt" 2>&1
( cd android && ./gradlew -q :monitoring_engine:dependencies --configuration releaseRuntimeClasspath ) \
  > "$log-gradle-plugin-releaseRuntimeClasspath.txt" 2>&1
for f in "$log"-gradle-*.txt; do
  echo "$(basename "$f"): SHA-256 $(grep -v '^Picked up' "$f" | sha256sum | cut -d' ' -f1); versiones dinámicas '+': $(grep -cE ':[0-9.]*\+' "$f")" >> "$log-resumen.txt"
done
exit $code
