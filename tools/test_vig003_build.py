#!/usr/bin/env python3
"""Pruebas dirigidas de tools/vig003_build.sh (VIG-003). Python estándar + Git Bash.

    python -m unittest tools/test_vig003_build.py -v

SON PRUEBAS SIMULADAS: ejecutan el script real en un directorio temporal con
`flutter`, `android/gradlew` y dos JDK falsos (Temurin 21.0.10 y Java 8). No
compilan la app ni usan las herramientas reales. Cada herramienta falsa anota
sus invocaciones en calls.log, lo que permite comprobar qué pasos NO se
ejecutaron tras un fallo. Los fallos se fuerzan con variables de entorno:
FAKE_PUB_EXIT, FAKE_BUILD_EXIT, FAKE_GRADLE_FAIL (lista de proyecto/configuración,
p. ej. ":app/debugRuntimeClasspath").
"""

from __future__ import annotations

import os
import shutil
import stat
import subprocess
import tempfile
import textwrap
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
SCRIPT = REPO / "tools" / "vig003_build.sh"


def git_bash() -> str:
    """Bash de Git for Windows (evita el bash.exe de WSL de System32)."""
    for candidate in (r"C:\Program Files\Git\bin\bash.exe", r"C:\Program Files\Git\usr\bin\bash.exe"):
        if Path(candidate).exists():
            return candidate
    found = shutil.which("bash")
    if not found:
        raise unittest.SkipTest("Git Bash no disponible")
    return found


BASH = git_bash()

FAKE_FLUTTER = textwrap.dedent("""\
    #!/usr/bin/env bash
    echo "flutter $*" >> "$FAKE_CALLS"
    case "$1 $2" in
      "pub get") echo "pub get simulado"; exit "${FAKE_PUB_EXIT:-0}" ;;
      "build apk")
        if [ "${FAKE_BUILD_EXIT:-0}" -ne 0 ]; then echo "error de compilación simulado"; exit "$FAKE_BUILD_EXIT"; fi
        mkdir -p build/app/outputs/flutter-apk
        printf 'apk-simulado' > build/app/outputs/flutter-apk/app-debug.apk
        echo "Built build/app/outputs/flutter-apk/app-debug.apk"; exit 0 ;;
    esac
    exit 99
""")

# Emula la selección de Java del gradlew real: JAVA_HOME/bin/java o, sin JAVA_HOME, `java` del PATH.
FAKE_GRADLEW = textwrap.dedent("""\
    #!/usr/bin/env bash
    if [ -n "${JAVA_HOME:-}" ]; then javacmd="$JAVA_HOME/bin/java"; else javacmd=java; fi
    jvm=$("$javacmd" -version 2>&1 | head -n 1)
    echo "gradlew $* | JAVA_HOME=${JAVA_HOME:-<sin definir>} | java PATH=$(command -v java) | JVM=$jvm" >> "$FAKE_CALLS"
    if [ "${1:-}" = "-version" ]; then
      [ -n "${FAKE_GRADLE_VERSION_EXIT:-}" ] && exit "$FAKE_GRADLE_VERSION_EXIT"
      ver=$(echo "$jvm" | sed -E 's/.*version "([^"]+)".*/\\1/')
      echo "Gradle 9.3.1"; echo "Launcher JVM:  $ver (simulado)"; echo "Daemon JVM:    ${JAVA_HOME:-actual}"; exit 0
    fi
    cfg="${4:-}"; key="${2%:dependencies}/$cfg"
    case ",${FAKE_GRADLE_FAIL:-}," in
      *",$key,"*) echo "FAILURE: consulta $key simulada"; exit 19 ;;
    esac
    echo "$cfg - simulado"
    echo "+--- org.example:lib:1.0.0"
    exit 0
""")


def fake_java(version_line: str, vendor_line: str) -> str:
    return f'#!/usr/bin/env bash\necho \'{version_line}\' >&2\necho \'{vendor_line}\' >&2\nexit 0\n'


def write_exec(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8", newline="\n")
    path.chmod(path.stat().st_mode | stat.S_IEXEC)


class Vig003BuildScript(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory(prefix="vig003-")
        self.root = Path(self._tmp.name)
        (self.root / "pubspec.lock").write_text("packages: {}\n", encoding="utf-8", newline="\n")
        (self.root / "tools").mkdir()
        shutil.copy2(SCRIPT, self.root / "tools" / "vig003_build.sh")
        write_exec(self.root / "android" / "gradlew", FAKE_GRADLEW)
        bins = self.root / "fakebin"
        write_exec(bins / "flutter", FAKE_FLUTTER)
        write_exec(self.root / "jdk21" / "bin" / "java",
                   fake_java('openjdk version "21.0.10" 2026-01-20 LTS',
                             "OpenJDK Runtime Environment Temurin-21.0.10+7 (build 21.0.10+7-LTS)"))
        write_exec(self.root / "java8" / "java",
                   fake_java('java version "1.8.0_503"', "Java(TM) SE Runtime Environment (build 1.8.0_503-b01)"))
        self.calls = self.root / "calls.log"
        self.out = self.root / "evid"

    def tearDown(self):
        self._tmp.cleanup()

    def run_script(self, *, jdk: str | None = "jdk21", **fake_env) -> subprocess.CompletedProcess:
        env = {k: v for k, v in os.environ.items() if k not in ("JAVA_HOME", "JAVA_TOOL_OPTIONS")}
        # Proceso invocador SIN JAVA_HOME y con Java 8 primero en PATH.
        env["PATH"] = os.pathsep.join([str(self.root / "java8"), str(self.root / "fakebin"), env.get("PATH", "")])
        env["FAKE_CALLS"] = str(self.calls)
        if jdk is not None:
            env["VIG003_JDK_HOME"] = str(self.root / jdk)
        env.update({k: str(v) for k, v in fake_env.items()})
        return subprocess.run([BASH, "tools/vig003_build.sh", "t", "evid"], cwd=self.root, env=env,
                              capture_output=True, text=True, encoding="utf-8")

    def lines(self) -> list[str]:
        return self.calls.read_text(encoding="utf-8").splitlines() if self.calls.exists() else []

    def summary(self) -> str:
        return (self.out / "t-resumen.txt").read_text(encoding="utf-8")

    def gradle_calls(self) -> list[str]:
        return [l for l in self.lines() if l.startswith("gradlew ")]

    # --- éxito ---------------------------------------------------------------

    def test_success_runs_all_steps_and_exits_zero(self):
        res = self.run_script()
        self.assertEqual(res.returncode, 0, res.stdout + res.stderr)
        calls = self.lines()
        self.assertEqual(calls[0], "flutter pub get --enforce-lockfile")
        self.assertEqual(calls[1], "flutter build apk --debug")
        self.assertEqual(len(self.gradle_calls()), 4)  # -version + 3 consultas
        self.assertIn("Launcher JVM:  21.0.10", (self.out / "t-gradle-version.txt").read_text(encoding="utf-8"))
        for name in ("debugRuntimeClasspath", "releaseRuntimeClasspath", "plugin-releaseRuntimeClasspath"):
            self.assertTrue((self.out / f"t-gradle-{name}.txt").exists(), name)
            self.assertFalse((self.out / f"t-gradle-{name}.FALLIDA.txt").exists(), name)
        self.assertIn("APK: build/app/outputs/flutter-apk/app-debug.apk", self.summary())
        self.assertIn("Resultado: OK (salida 0)", self.summary())

    # --- JDK -----------------------------------------------------------------

    def test_direct_gradle_calls_use_selected_jdk_without_java_home_and_java8_first(self):
        res = self.run_script()
        self.assertEqual(res.returncode, 0, res.stdout + res.stderr)
        for call in self.gradle_calls():
            self.assertIn("JVM=openjdk version \"21.0.10\"", call)
            self.assertNotIn("1.8.0", call)
            self.assertIn("jdk21", call.split("| java PATH=")[1])  # también PATH antepone el JDK 21

    def test_missing_jdk_fails_before_any_step(self):
        res = self.run_script(jdk="no-existe")
        self.assertEqual(res.returncode, 3, res.stdout + res.stderr)
        self.assertIn("FALLO en paso 'jdk'", res.stderr)
        self.assertEqual(self.lines(), [])

    def test_wrong_jdk_version_fails_before_any_step(self):
        write_exec(self.root / "jdk17" / "bin" / "java",
                   fake_java('openjdk version "17.0.12" 2024-07-16', "OpenJDK Runtime Environment Temurin-17.0.12+7"))
        res = self.run_script(jdk="jdk17")
        self.assertEqual(res.returncode, 3, res.stdout + res.stderr)
        self.assertIn("no es Temurin 21.0.10", res.stderr)
        self.assertEqual(self.lines(), [])

    # --- fallo de pub get ----------------------------------------------------

    def test_pub_get_failure_stops_before_build_and_queries(self):
        res = self.run_script(FAKE_PUB_EXIT=23)
        self.assertEqual(res.returncode, 4, res.stdout + res.stderr)
        self.assertEqual(self.lines(), ["flutter pub get --enforce-lockfile"])
        self.assertIn("FALLO en paso 'pub-get': salida 23", self.summary())
        self.assertNotIn("APK:", self.summary())
        self.assertEqual(list(self.out.glob("t-gradle-*")), [])

    # --- fallo de compilación ------------------------------------------------

    def test_build_failure_skips_apk_and_queries(self):
        res = self.run_script(FAKE_BUILD_EXIT=17)
        self.assertEqual(res.returncode, 5, res.stdout + res.stderr)
        self.assertEqual(self.lines(), ["flutter pub get --enforce-lockfile", "flutter build apk --debug"])
        self.assertIn("FALLO en paso 'build': salida 17", self.summary())
        self.assertNotIn("APK:", self.summary())
        self.assertEqual(list(self.out.glob("t-gradle-*")), [])

    # --- fallo de cada consulta Gradle ---------------------------------------

    QUERIES = {
        ":app/debugRuntimeClasspath": "debugRuntimeClasspath",
        ":app/releaseRuntimeClasspath": "releaseRuntimeClasspath",
        ":monitoring_engine/releaseRuntimeClasspath": "plugin-releaseRuntimeClasspath",
    }

    def test_failure_of_each_gradle_query(self):
        for key, name in self.QUERIES.items():
            with self.subTest(consulta=key):
                if self.calls.exists():
                    self.calls.unlink()
                res = self.run_script(FAKE_GRADLE_FAIL=key)
                self.assertEqual(res.returncode, 6, res.stdout + res.stderr)
                self.assertIn(f"consultas fallidas: {name}", res.stderr)
                self.assertIn("FALLO en paso 'gradle-dependencies'", self.summary())
                self.assertNotIn("Resultado: OK", self.summary())
                failed = self.out / f"t-gradle-{name}.FALLIDA.txt"
                self.assertTrue(failed.exists())
                self.assertIn("FAILURE: consulta", failed.read_text(encoding="utf-8"))
                self.assertFalse((self.out / f"t-gradle-{name}.txt").exists(),
                                 "un fallo no se presenta como árbol válido")
                for other in set(self.QUERIES.values()) - {name}:
                    self.assertTrue((self.out / f"t-gradle-{other}.txt").exists(), other)
                    self.assertFalse((self.out / f"t-gradle-{other}.FALLIDA.txt").exists(), other)
                self.assertEqual(len(self.gradle_calls()), 4)

    def test_gradle_version_failure_skips_queries(self):
        res = self.run_script(FAKE_GRADLE_VERSION_EXIT=13)
        self.assertEqual(res.returncode, 7, res.stdout + res.stderr)
        self.assertIn("FALLO en paso 'gradle-jvm'", self.summary())
        self.assertEqual(len(self.gradle_calls()), 1)  # solo -version; ninguna consulta
        self.assertEqual(list(self.out.glob("t-gradle-*Classpath*")), [])

    def test_stale_valid_tree_is_removed_before_a_failed_rerun(self):
        self.assertEqual(self.run_script().returncode, 0)
        res = self.run_script(FAKE_GRADLE_FAIL=":app/debugRuntimeClasspath")
        self.assertEqual(res.returncode, 6)
        self.assertFalse((self.out / "t-gradle-debugRuntimeClasspath.txt").exists())

    def test_usage_error(self):
        env = dict(os.environ, VIG003_JDK_HOME=str(self.root / "jdk21"))
        res = subprocess.run([BASH, "tools/vig003_build.sh", "solo-uno"], cwd=self.root, env=env,
                             capture_output=True, text=True, encoding="utf-8")
        self.assertEqual(res.returncode, 2)


if __name__ == "__main__":
    unittest.main(verbosity=2)
