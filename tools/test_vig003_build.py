#!/usr/bin/env python3
"""Pruebas dirigidas de tools/vig003_build.sh (VIG-003). Python estándar + Git Bash.

    python -m unittest tools/test_vig003_build.py -v

SON PRUEBAS SIMULADAS: ejecutan el script real en un directorio temporal con
`flutter`, `android/gradlew`, `sha256sum` y dos JDK falsos (Temurin 21.0.10 y
Java 8). No compilan la app ni usan las herramientas reales de Flutter/Android.
Cada herramienta falsa anota sus invocaciones en calls.log, lo que permite
comprobar qué pasos NO se ejecutaron tras un fallo. Los fallos se fuerzan con
variables de entorno:
  FAKE_PUB_EXIT, FAKE_BUILD_EXIT, FAKE_GRADLE_VERSION_EXIT,
  FAKE_GRADLE_FAIL (lista de proyecto/configuración, p. ej. ":app/debugRuntimeClasspath"),
  FAKE_SHA_FAIL_AT=<n> con FAKE_SHA_MODE=exit31|empty|malformed (n-ésima llamada a
  sha256sum; las demás delegan en el sha256sum real de Git Bash).
"""

from __future__ import annotations

import hashlib
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
    """Bash de Git for Windows (evita el bash.exe de WSL de System32).

    Se prefiere usr/bin/bash.exe: el lanzador bin/bash.exe antepone /mingw64/bin y
    /usr/bin al PATH, lo que ocultaría las herramientas falsas (p. ej. sha256sum).
    """
    for candidate in (r"C:\Program Files\Git\usr\bin\bash.exe", r"C:\Program Files\Git\bin\bash.exe"):
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

# sha256sum falso: cuenta sus llamadas y puede fallar en la n-ésima; si no, delega en el real.
FAKE_SHA256SUM = textwrap.dedent("""\
    #!/usr/bin/env bash
    n=$(( $(cat "$FAKE_SHA_COUNT" 2>/dev/null || echo 0) + 1 ))
    echo "$n" > "$FAKE_SHA_COUNT"
    echo "sha256sum #$n ${*:--}" >> "$FAKE_CALLS"
    if [ "${FAKE_SHA_FAIL_AT:-0}" = "$n" ]; then
      case "${FAKE_SHA_MODE:-exit31}" in
        exit31) cat > /dev/null; echo "sha256sum: error simulado" >&2; exit 31 ;;
        empty) cat > /dev/null; exit 0 ;;
        malformed) cat > /dev/null; echo "zzzz-no-es-un-hash  ${1:--}"; exit 0 ;;
      esac
    fi
    exec /usr/bin/sha256sum "$@"
""")

# Orden de los cálculos de SHA-256 en una ejecución completa del script.
HASH_POINTS = {
    1: "pubspec-antes",
    2: "apk",
    3: "pubspec-despues",
    4: "gradle-debugRuntimeClasspath",
    5: "gradle-releaseRuntimeClasspath",
    6: "gradle-plugin-releaseRuntimeClasspath",
}

QUERY_NAMES = ("debugRuntimeClasspath", "releaseRuntimeClasspath", "plugin-releaseRuntimeClasspath")


def fake_java(version_line: str, vendor_line: str) -> str:
    return f'#!/usr/bin/env bash\necho \'{version_line}\' >&2\necho \'{vendor_line}\' >&2\nexit 0\n'


def write_exec(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8", newline="\n")
    path.chmod(path.stat().st_mode | stat.S_IEXEC)


def snapshot(root: Path) -> dict[str, str]:
    """Mapa ruta relativa → SHA-256 (o 'DIR') de todo lo que hay bajo root."""
    result = {}
    for p in sorted(root.rglob("*")):
        rel = p.relative_to(root).as_posix()
        result[rel] = "DIR" if p.is_dir() else hashlib.sha256(p.read_bytes()).hexdigest()
    return result


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
        write_exec(bins / "sha256sum", FAKE_SHA256SUM)
        write_exec(self.root / "jdk21" / "bin" / "java",
                   fake_java('openjdk version "21.0.10" 2026-01-20 LTS',
                             "OpenJDK Runtime Environment Temurin-21.0.10+7 (build 21.0.10+7-LTS)"))
        write_exec(self.root / "java8" / "java",
                   fake_java('java version "1.8.0_503"', "Java(TM) SE Runtime Environment (build 1.8.0_503-b01)"))
        self.calls = self.root / "calls.log"
        self.sha_count = self.root / "sha-count"
        self.out = self.root / "evid"

    def tearDown(self):
        self._tmp.cleanup()

    def run_script(self, label: str = "t", *, jdk: str | None = "jdk21", **fake_env) -> subprocess.CompletedProcess:
        for f in (self.calls, self.sha_count):
            if f.exists():
                f.unlink()
        env = {k: v for k, v in os.environ.items() if k not in ("JAVA_HOME", "JAVA_TOOL_OPTIONS")}
        # Proceso invocador SIN JAVA_HOME y con Java 8 primero en PATH.
        env["PATH"] = os.pathsep.join([str(self.root / "java8"), str(self.root / "fakebin"), env.get("PATH", "")])
        env["FAKE_CALLS"] = str(self.calls)
        env["FAKE_SHA_COUNT"] = str(self.sha_count)
        if jdk is not None:
            env["VIG003_JDK_HOME"] = str(self.root / jdk)
        env.update({k: str(v) for k, v in fake_env.items()})
        return subprocess.run([BASH, "tools/vig003_build.sh", label, "evid"], cwd=self.root, env=env,
                              capture_output=True, text=True, encoding="utf-8")

    def run_dir(self, label: str = "t") -> Path:
        return self.out / label

    def lines(self) -> list[str]:
        return self.calls.read_text(encoding="utf-8").splitlines() if self.calls.exists() else []

    def summary(self, label: str = "t") -> str:
        return (self.run_dir(label) / "resumen.txt").read_text(encoding="utf-8")

    def tool_calls(self, prefix: str) -> list[str]:
        return [l for l in self.lines() if l.startswith(prefix)]

    def gradle_calls(self) -> list[str]:
        return self.tool_calls("gradlew ")

    # --- éxito ---------------------------------------------------------------

    def test_success_runs_all_steps_and_exits_zero(self):
        res = self.run_script()
        self.assertEqual(res.returncode, 0, res.stdout + res.stderr)
        self.assertEqual(self.tool_calls("flutter "),
                         ["flutter pub get --enforce-lockfile", "flutter build apk --debug"])
        self.assertEqual(len(self.gradle_calls()), 4)  # -version + 3 consultas
        self.assertEqual(len(self.tool_calls("sha256sum ")), len(HASH_POINTS))
        rd = self.run_dir()
        self.assertIn("Launcher JVM:  21.0.10", (rd / "gradle-version.txt").read_text(encoding="utf-8"))
        for name in QUERY_NAMES:
            self.assertTrue((rd / f"gradle-{name}.txt").exists(), name)
            self.assertFalse((rd / f"gradle-{name}.FALLIDA.txt").exists(), name)
        summary = self.summary()
        self.assertIn("APK: build/app/outputs/flutter-apk/app-debug.apk", summary)
        expected_apk = hashlib.sha256(b"apk-simulado").hexdigest()
        self.assertIn(f"SHA-256 {expected_apk}", summary)
        self.assertIn("Resultado: OK (salida 0)", summary)

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
        self.assertEqual(self.tool_calls("flutter ") + self.gradle_calls(), [])

    def test_wrong_jdk_version_fails_before_any_step(self):
        write_exec(self.root / "jdk17" / "bin" / "java",
                   fake_java('openjdk version "17.0.12" 2024-07-16', "OpenJDK Runtime Environment Temurin-17.0.12+7"))
        res = self.run_script(jdk="jdk17")
        self.assertEqual(res.returncode, 3, res.stdout + res.stderr)
        self.assertIn("no es Temurin 21.0.10", res.stderr)
        self.assertEqual(self.tool_calls("flutter ") + self.gradle_calls(), [])

    # --- fallo de pub get / compilación / gradlew -version -------------------

    def test_pub_get_failure_stops_before_build_and_queries(self):
        res = self.run_script(FAKE_PUB_EXIT=23)
        self.assertEqual(res.returncode, 4, res.stdout + res.stderr)
        self.assertEqual(self.tool_calls("flutter ") + self.gradle_calls(), ["flutter pub get --enforce-lockfile"])
        self.assertIn("FALLO en paso 'pub-get': salida 23", self.summary())
        self.assertNotIn("APK:", self.summary())
        self.assertEqual(list(self.run_dir().glob("gradle-*")), [])

    def test_build_failure_skips_apk_and_queries(self):
        res = self.run_script(FAKE_BUILD_EXIT=17)
        self.assertEqual(res.returncode, 5, res.stdout + res.stderr)
        self.assertEqual(self.tool_calls("flutter ") + self.gradle_calls(),
                         ["flutter pub get --enforce-lockfile", "flutter build apk --debug"])
        self.assertIn("FALLO en paso 'build': salida 17", self.summary())
        self.assertNotIn("APK:", self.summary())
        self.assertEqual(list(self.run_dir().glob("gradle-*")), [])

    def test_gradle_version_failure_skips_queries(self):
        res = self.run_script(FAKE_GRADLE_VERSION_EXIT=13)
        self.assertEqual(res.returncode, 7, res.stdout + res.stderr)
        self.assertIn("FALLO en paso 'gradle-jvm'", self.summary())
        self.assertEqual(len(self.gradle_calls()), 1)  # solo -version; ninguna consulta
        self.assertEqual(list(self.run_dir().glob("gradle-*Classpath*")), [])

    # --- fallo de cada consulta Gradle ---------------------------------------

    QUERIES = {
        ":app/debugRuntimeClasspath": "debugRuntimeClasspath",
        ":app/releaseRuntimeClasspath": "releaseRuntimeClasspath",
        ":monitoring_engine/releaseRuntimeClasspath": "plugin-releaseRuntimeClasspath",
    }

    def test_failure_of_each_gradle_query(self):
        for key, name in self.QUERIES.items():
            with self.subTest(consulta=key):
                res = self.run_script(FAKE_GRADLE_FAIL=key)
                self.assertEqual(res.returncode, 6, res.stdout + res.stderr)
                self.assertIn(f"consultas fallidas: {name}", res.stderr)
                self.assertIn("FALLO en paso 'gradle-dependencies'", self.summary())
                self.assertNotIn("Resultado: OK", self.summary())
                rd = self.run_dir()
                failed = rd / f"gradle-{name}.FALLIDA.txt"
                self.assertTrue(failed.exists())
                self.assertIn("FAILURE: consulta", failed.read_text(encoding="utf-8"))
                self.assertFalse((rd / f"gradle-{name}.txt").exists(), "un fallo no se presenta como árbol válido")
                for other in set(self.QUERIES.values()) - {name}:
                    self.assertTrue((rd / f"gradle-{other}.txt").exists(), other)
                    self.assertFalse((rd / f"gradle-{other}.FALLIDA.txt").exists(), other)
                self.assertEqual(len(self.gradle_calls()), 4)

    def test_stale_valid_tree_is_removed_before_a_failed_rerun(self):
        self.assertEqual(self.run_script().returncode, 0)
        res = self.run_script(FAKE_GRADLE_FAIL=":app/debugRuntimeClasspath")
        self.assertEqual(res.returncode, 6)
        self.assertFalse((self.run_dir() / "gradle-debugRuntimeClasspath.txt").exists())

    # --- P1: etiqueta, rutas y limpieza --------------------------------------

    def assert_rejected_without_writes(self, label: str):
        before = snapshot(self.root)
        res = self.run_script(label)
        self.assertEqual(res.returncode, 2, f"{label!r}: {res.stdout}{res.stderr}")
        self.assertIn("FALLO en paso 'uso'", res.stderr)
        after = snapshot(self.root)
        self.assertEqual(after, before, f"{label!r} modificó archivos")
        self.assertFalse(self.out.exists(), f"{label!r} creó la carpeta de evidencia")

    def test_parent_traversal_label_rejected_without_changes(self):
        history = self.root / "history"
        history.mkdir()
        (history / "resumen.txt").write_text("evidencia ajena\n", encoding="utf-8")
        self.assert_rejected_without_writes("../history")
        self.assertEqual((history / "resumen.txt").read_text(encoding="utf-8"), "evidencia ajena\n")

    def test_empty_and_separator_labels_rejected_without_writes(self):
        for label in ("", "a/b", "a\\b", "/abs", "C:", "..", ".", "a.b", "t.", "con espacio", "eñe", "a*b", "a\nb"):
            with self.subTest(etiqueta=label):
                self.assert_rejected_without_writes(label)

    def test_valid_labels_accepted(self):
        for label in ("t", "compilacion-5", "A_b-9"):
            with self.subTest(etiqueta=label):
                res = self.run_script(label)
                self.assertEqual(res.returncode, 0, res.stdout + res.stderr)
                self.assertTrue((self.run_dir(label) / "resumen.txt").exists())

    def _seed_foreign_evidence(self) -> dict[str, str]:
        # Evidencia de otra etiqueta en ambos formatos: carpeta exclusiva y nombres planos históricos.
        hist = self.out / "t-gradle-history"
        hist.mkdir(parents=True)
        for name in ("resumen.txt", "gradle-debugRuntimeClasspath.txt", "gradle-debugRuntimeClasspath.FALLIDA.txt"):
            (hist / name).write_text(f"historia {name}\n", encoding="utf-8")
        for name in ("t-gradle-history-resumen.txt", "t-gradle-history-gradle-debugRuntimeClasspath.txt",
                     "t-gradle-debugRuntimeClasspath.txt", "t-resumen.txt", "compilacion-4-resumen.txt"):
            (self.out / name).write_text(f"plano {name}\n", encoding="utf-8")
        return {k: v for k, v in snapshot(self.out).items() if not k.startswith("t/")}

    def test_label_t_preserves_t_gradle_history_and_flat_evidence(self):
        foreign = self._seed_foreign_evidence()
        for kwargs in ({}, {"FAKE_GRADLE_FAIL": ":app/debugRuntimeClasspath"}, {"FAKE_PUB_EXIT": 1}):
            with self.subTest(**{k: str(v) for k, v in kwargs.items()}):
                self.run_script("t", **kwargs)
                now = {k: v for k, v in snapshot(self.out).items() if not k.startswith("t/") and k != "t"}
                self.assertEqual(now, foreign)

    def test_repeating_a_label_only_affects_its_own_evidence(self):
        foreign = self._seed_foreign_evidence()
        self.assertEqual(self.run_script("t").returncode, 0)
        note = self.run_dir("t") / "nota-manual.txt"  # archivo ajeno al script dentro de la carpeta
        note.write_text("no es del script\n", encoding="utf-8")
        self.assertEqual(self.run_script("otra").returncode, 0)
        otra = {k: v for k, v in snapshot(self.out).items() if k.startswith("otra/")}
        self.assertEqual(self.run_script("t", FAKE_PUB_EXIT=9).returncode, 4)
        after = snapshot(self.out)
        self.assertEqual({k: v for k, v in after.items() if k in foreign}, foreign)
        self.assertEqual({k: v for k, v in after.items() if k.startswith("otra/")}, otra)
        self.assertEqual(note.read_text(encoding="utf-8"), "no es del script\n")
        self.assertFalse((self.run_dir("t") / "gradle-debugRuntimeClasspath.txt").exists())

    def test_symlinked_label_folder_rejected(self):
        target = self.root / "fuera"
        target.mkdir()
        self.out.mkdir()
        try:
            os.symlink(target, self.out / "t", target_is_directory=True)
        except (OSError, NotImplementedError):
            self.skipTest("este Windows no permite crear enlaces simbólicos sin privilegios")
        res = self.run_script("t")
        self.assertEqual(res.returncode, 2, res.stdout + res.stderr)
        self.assertEqual(list(target.iterdir()), [])

    # --- P2: SHA-256 como paso comprobado ------------------------------------

    def test_each_hash_point_failing_with_exit_31_fails_globally(self):
        for n, point in HASH_POINTS.items():
            with self.subTest(punto=point):
                res = self.run_script(FAKE_SHA_FAIL_AT=n, FAKE_SHA_MODE="exit31")
                self.assertEqual(res.returncode, 8, res.stdout + res.stderr)
                self.assertIn(f"FALLO en paso 'hash:{point}'", res.stderr)
                self.assertIn("salida 31", res.stderr)
                self.assert_hash_failure_effects(n, point)

    def test_each_hash_point_with_empty_or_malformed_output_fails_globally(self):
        for mode in ("empty", "malformed"):
            for n, point in HASH_POINTS.items():
                with self.subTest(modo=mode, punto=point):
                    res = self.run_script(FAKE_SHA_FAIL_AT=n, FAKE_SHA_MODE=mode)
                    self.assertEqual(res.returncode, 8, res.stdout + res.stderr)
                    self.assertIn(f"FALLO en paso 'hash:{point}'", res.stderr)
                    self.assertIn("no devolvió un SHA-256 válido", res.stderr)
                    self.assert_hash_failure_effects(n, point)

    def assert_hash_failure_effects(self, n: int, point: str):
        summary = self.summary()
        self.assertNotIn("Resultado: OK", summary)
        self.assertIn(f"FALLO en paso 'hash:{point}'", summary)
        self.assertNotIn("zzzz", summary.split("FALLO en paso")[0])
        for line in summary.splitlines():
            if line.startswith(("FALLO en paso", "Resultado:")):
                continue
            if "SHA-256" in line or "pubspec.lock" in line:
                self.assertRegex(line, r"[0-9a-f]{64}", f"hash vacío o inválido registrado: {line!r}")
        # No continúa tras el fallo: ninguna llamada a sha256sum posterior y pasos dependientes omitidos.
        self.assertEqual(len(self.tool_calls("sha256sum ")), n)
        if point == "pubspec-antes":
            self.assertEqual(self.tool_calls("flutter ") + self.gradle_calls(), [])
        if point in ("apk", "pubspec-despues"):
            self.assertEqual(self.gradle_calls(), [])
            self.assertNotIn("pubspec.lock después", summary)
        if point == "apk":
            self.assertNotIn("APK:", summary)
        if point.startswith("gradle-"):
            name = point[len("gradle-"):]
            index = QUERY_NAMES.index(name)
            self.assertEqual(len(self.gradle_calls()), 2 + index)  # -version + consultas hasta la del fallo
            self.assertFalse((self.run_dir() / f"gradle-{name}.txt").exists(),
                             "un árbol cuyo hash falló no se presenta como evidencia válida")
            for later in QUERY_NAMES[index + 1:]:
                self.assertFalse((self.run_dir() / f"gradle-{later}.txt").exists(), later)

    def test_usage_error(self):
        env = dict(os.environ, VIG003_JDK_HOME=str(self.root / "jdk21"))
        res = subprocess.run([BASH, "tools/vig003_build.sh", "solo-uno"], cwd=self.root, env=env,
                             capture_output=True, text=True, encoding="utf-8")
        self.assertEqual(res.returncode, 2)
        self.assertFalse(self.out.exists())


if __name__ == "__main__":
    unittest.main(verbosity=2)
