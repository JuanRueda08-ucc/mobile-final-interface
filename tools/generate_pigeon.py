"""Genera el código Pigeon del motor de forma reproducible (fase 5A).

Uso, desde la raíz del repositorio:

    python tools/generate_pigeon.py          # regenera
    python tools/generate_pigeon.py --check  # regenera y falla si difiere de Git

Pasos:
1. `dart run pigeon --input pigeons/monitoring_api.dart` en el plugin
   (versión exacta fijada en su pubspec).
2. `dart format` del contrato y del Dart generado.
3. Pigeon 29.0.8 deja espacios al final de alguna línea del Kotlin generado;
   se eliminan aquí para que `git diff --check` quede limpio sin editar a mano.
"""

import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
PLUGIN = ROOT / "packages" / "monitoring_engine"
GENERATED = [
    PLUGIN / "lib" / "src" / "monitoring_api.g.dart",
    PLUGIN / "android" / "src" / "main" / "kotlin" / "com" / "juanrueda"
    / "monitoring_engine" / "MonitoringApi.g.kt",
]


def run(*cmd: str, cwd: pathlib.Path) -> None:
    # `shell=True` en Windows resuelve `dart.bat`.
    subprocess.run(" ".join(cmd), cwd=cwd, check=True, shell=True)


def strip_trailing_whitespace(path: pathlib.Path) -> bool:
    data = path.read_bytes().decode("utf-8")
    newline = "\r\n" if "\r\n" in data else "\n"
    lines = data.split(newline)
    cleaned = newline.join(line.rstrip(" \t") for line in lines)
    if cleaned != data:
        path.write_bytes(cleaned.encode("utf-8"))
        return True
    return False


def main() -> int:
    run("dart", "run", "pigeon", "--input", "pigeons/monitoring_api.dart", cwd=PLUGIN)
    run("dart", "format", "pigeons", "lib/src/monitoring_api.g.dart", cwd=PLUGIN)
    for path in GENERATED:
        if path.suffix == ".kt" and strip_trailing_whitespace(path):
            print(f"Espacios finales eliminados: {path.relative_to(ROOT)}")
    if "--check" in sys.argv:
        rel = [str(p.relative_to(ROOT)) for p in GENERATED]
        diff = subprocess.run(["git", "diff", "--exit-code", "--stat", "--", *rel], cwd=ROOT)
        if diff.returncode != 0:
            print("El código generado difiere del versionado: confírmalo o revisa el contrato.")
            return 1
        print("Código Pigeon coherente con el contrato.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
