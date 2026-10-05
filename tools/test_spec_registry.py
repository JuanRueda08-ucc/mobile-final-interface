#!/usr/bin/env python3
"""Regresiones de tools/spec_registry.py (VIG-001). Python estándar, sin red.

    python -m unittest tools/test_spec_registry.py -v

Cada caso negativo copia docs/source/, el baseline y las decisiones a un
directorio temporal, altera SOLO esa copia con datos simulados, regenera los
registros sobre la copia (cambio coordinado fuente+anexos+registro) y ejecuta
`spec_registry.py check --root <copia>` como proceso aparte. Se exige código
de salida 1 y la línea FALLO concreta; un aviso no basta.

Las fuentes reales no se modifican: se verifica su SHA-256 antes y después.
"""

from __future__ import annotations

import hashlib
import json
import re
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
SCRIPT = REPO / "tools" / "spec_registry.py"

A04 = "Vigia_04_Arquitectura_Tecnica_y_Contratos_v1.0.md"
A07 = "Vigia_07_Plan_de_Pruebas_Calidad_y_Distribucion_v1.0.md"
A08 = "Vigia_08_Plan_de_Implementacion_y_Colaboracion_v1.0.md"


def source_hashes() -> dict:
    return {p.name: hashlib.sha256(p.read_bytes()).hexdigest()
            for p in sorted((REPO / "docs" / "source").iterdir()) if p.is_file()}


def run(root: Path, command: str) -> subprocess.CompletedProcess:
    return subprocess.run([sys.executable, str(SCRIPT), command, "--root", str(root)],
                          capture_output=True, text=True, encoding="utf-8")


class Sandbox:
    """Copia temporal con la estructura que espera el validador."""

    def __init__(self):
        self._tmp = tempfile.TemporaryDirectory(prefix="vig001-")
        self.root = Path(self._tmp.name)
        shutil.copytree(REPO / "docs" / "source", self.root / "docs" / "source")
        (self.root / "docs" / "decisions").mkdir(parents=True)
        shutil.copy2(REPO / "docs" / "spec-baseline.json", self.root / "docs" / "spec-baseline.json")
        for name in ("open-issues.md", "text-exceptions.json"):
            shutil.copy2(REPO / "docs" / "decisions" / name, self.root / "docs" / "decisions" / name)

    def path(self, name: str) -> Path:
        return self.root / "docs" / "source" / name

    def sub(self, name: str, pattern: str, repl: str, count: int = 1) -> None:
        """Sustituye exactamente `count` líneas que cumplen `pattern` (falla si no hay)."""
        p = self.path(name)
        text = p.read_bytes().decode("utf-8")
        new, n = re.subn(pattern, repl, text, flags=re.M)
        if n != count:
            raise AssertionError(f"{name}: {n} coincidencias de {pattern!r}, esperadas {count}")
        p.write_bytes(new.encode("utf-8"))

    def duplicate_line(self, name: str, pattern: str) -> None:
        self.sub(name, rf"^({pattern}.*)$", r"\1\n\1")

    def build_and_check(self) -> subprocess.CompletedProcess:
        b = run(self.root, "build")
        if b.returncode != 0:
            raise AssertionError(f"build falló:\n{b.stdout}\n{b.stderr}")
        return run(self.root, "check")

    def close(self):
        self._tmp.cleanup()


class SpecRegistryRegression(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.hashes_before = source_hashes()

    @classmethod
    def tearDownClass(cls):
        assert source_hashes() == cls.hashes_before, "las fuentes reales cambiaron durante las pruebas"

    def setUp(self):
        self.sb = Sandbox()

    def tearDown(self):
        self.sb.close()

    def assertFails(self, result: subprocess.CompletedProcess, *expected: str):
        self.assertEqual(result.returncode, 1, f"se esperaba código 1:\n{result.stdout}\n{result.stderr}")
        self.assertIn("Resultado: FALLÓ", result.stdout)
        failures = [l for l in result.stdout.splitlines() if l.startswith("FALLO: ")]
        for exp in expected:
            self.assertTrue(any(exp in f for f in failures),
                            f"falta un FALLO que contenga {exp!r}; fallos:\n" + "\n".join(failures))

    # --- caso válido -------------------------------------------------------

    def test_valid_repository_as_committed(self):
        """El repositorio real, sin regenerar, pasa (solo lectura)."""
        res = subprocess.run([sys.executable, str(SCRIPT), "check"], capture_output=True,
                             text=True, encoding="utf-8")
        self.assertEqual(res.returncode, 0, res.stdout)
        self.assertNotIn("FALLO", res.stdout)

    def test_valid_copy_rebuilt(self):
        res = self.sb.build_and_check()
        self.assertEqual(res.returncode, 0, res.stdout)
        self.assertIn("Resultado: OK", res.stdout)

    # --- hallazgo 1: estados RL --------------------------------------------

    def test_rl09_pending_coordinated_in_a07_a08_and_registry_fails(self):
        self.sb.sub(A07, r"^(\| RL09 \| .* \| )blocked( \|)$", r"\1pending\2")
        self.sb.sub(A08, r"^(\| RL09 \| VIG-067, VIG-071 \| )blocked( \|)$", r"\1pending\2")
        res = self.sb.build_and_check()
        self.assertFails(res, "estado RL09 en A07 §15 = baseline (blocked)",
                         "estado RL09 en A08 §16 = baseline (blocked)",
                         "estado RL09 del registro = baseline (blocked)")

    # --- hallazgo 2: duplicados --------------------------------------------

    def test_duplicate_vig_card_fails_with_locations(self):
        self.sb.duplicate_line(A08, r"#### VIG-005 · ")
        res = self.sb.build_and_check()
        self.assertFails(res, "sin duplicados en fichas VIG del Área 08: VIG-005 en ",
                         "apariciones originales = IDs únicos en fichas VIG del Área 08")
        line = next(l for l in res.stdout.splitlines() if "sin duplicados en fichas VIG" in l)
        self.assertEqual(len(re.findall(re.escape(A08) + r":\d+", line)), 2, line)

    def test_duplicate_rl_rows_fail_in_each_catalog(self):
        self.sb.duplicate_line(A07, r"\| RL03 \| ")
        self.sb.duplicate_line(A08, r"\| RL03 \| ")
        res = self.sb.build_and_check()
        self.assertFails(res, "sin duplicados en RL del Área 07 §15: RL03 en ",
                         "sin duplicados en RL del Área 08 §16: RL03 en ",
                         "apariciones originales = IDs únicos en RL del Área 07 §15")

    # --- hallazgo 3: baseline independiente --------------------------------

    def test_extra_at23_coordinated_with_documented_311_fails(self):
        self.sb.sub(A04, r"^(\| AT22 \| .*)$", r"\1\n| AT23 | Ensayo simulado de regresión | RF01 |")
        self.sb.sub(A07, r"^(\| AT22 \| A04 \| .*)$",
                    r"\1\n| AT23 | A04 | Ensayo simulado de regresión · RF01 | QA01 | notRun |")
        self.sb.sub(A08, r"^(\| AT22 \| QA\d\d.*)$", r"\1\n| AT23 | QA01 | VIG-009 | VIG-052 | notRun |")
        self.sb.sub(A07, r"^\| AT \| 22 \|$", "| AT | 23 |")
        self.sb.sub(A07, r"^\| Total de IDs fuente \| 310 \|$", "| Total de IDs fuente | 311 |")
        res = self.sb.build_and_check()
        self.assertFails(res, "IDs de las fuentes = baseline: ausentes []; adicionales ['AT23']",
                         "IDs de traceability.json = baseline",
                         "conteo AT en fuentes = baseline",
                         "conteo documentado AT (A07 §18) = baseline",
                         "total documentado (A07 §18) = baseline: baseline 310, documentado 311")

    def test_documented_total_311_alone_fails(self):
        self.sb.sub(A07, r"^\| Total de IDs fuente \| 310 \|$", "| Total de IDs fuente | 311 |")
        res = self.sb.build_and_check()
        self.assertFails(res, "total documentado (A07 §18) = baseline: baseline 310, documentado 311")

    def test_missing_id_fails(self):
        self.sb.sub(A04, r"^\| AT22 \| .*\n", "")
        res = self.sb.build_and_check()
        self.assertFails(res, "IDs de las fuentes = baseline: ausentes ['AT22']")

    def test_tampered_baseline_fails(self):
        p = self.sb.root / "docs" / "spec-baseline.json"
        data = json.loads(p.read_text(encoding="utf-8"))
        data["ids"].append("AT23")
        data["familyCounts"]["AT"] = 23
        data["total"] = 311
        p.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        res = self.sb.build_and_check()
        self.assertFails(res, "huella del baseline coincide con la fijada en el validador")

    # --- hallazgo 4: textos discrepantes -----------------------------------

    def _alter_annex_text(self):
        self.sb.sub(A07, r"^(\| RF01\.CA1 \| PRD \| .*?)( \| QA01 \| notRun \|)$",
                    r"\1 Texto simulado añadido.\2")

    def test_text_discrepancy_fails_and_keeps_source_literal(self):
        self._alter_annex_text()
        res = self.sb.build_and_check()
        self.assertFails(res, "texto discrepante RF01.CA1 sin excepción documentada")
        trace = json.loads((self.sb.root / "docs" / "traceability.json").read_text(encoding="utf-8"))
        entry = next(e for e in trace["entries"] if e["id"] == "RF01.CA1")
        self.assertFalse(entry["annexA07"]["textMatchesSource"])
        self.assertNotIn("Texto simulado", entry["text"])

    def test_incomplete_exception_fails(self):
        self._alter_annex_text()
        self._write_exceptions([{"id": "RF01.CA1", "openIssue": "OI-01"}])
        res = self.sb.build_and_check()
        self.assertFails(res, "excepción de texto RF01.CA1 completa",
                         "texto discrepante RF01.CA1 sin excepción documentada")

    def test_exception_to_unknown_issue_fails(self):
        self._alter_annex_text()
        self._write_exceptions([self._full_exception("OI-98")])
        res = self.sb.build_and_check()
        self.assertFails(res, "excepción de texto RF01.CA1 referencia un hallazgo abierto",
                         "texto discrepante RF01.CA1 sin excepción documentada")

    def test_documented_exception_with_specific_open_issue_is_accepted(self):
        """Mecanismo de excepción sobre datos simulados (OI-99 solo existe en la copia)."""
        self._alter_annex_text()
        oi = self.sb.root / "docs" / "decisions" / "open-issues.md"
        text = oi.read_text(encoding="utf-8")
        text = text.replace("| OI-08 |", "| OI-99 | Simulado para prueba | Abierto | Prueba |\n| OI-08 |", 1)
        text += "\n## OI-99 · Discrepancia simulada de prueba\n"
        oi.write_text(text, encoding="utf-8")
        self._write_exceptions([self._full_exception("OI-99")])
        res = self.sb.build_and_check()
        self.assertEqual(res.returncode, 0, res.stdout)
        self.assertIn("Discrepancia de texto RF01.CA1 aceptada por excepción documentada", res.stdout)

    def test_stale_exception_without_discrepancy_fails(self):
        self._write_exceptions([self._full_exception("OI-01", annex_text="texto viejo")])
        res = self.sb.build_and_check()
        self.assertFails(res, "excepción de texto RF01.CA1 corresponde a una discrepancia real")

    def _full_exception(self, oi: str, annex_text: str | None = None) -> dict:
        lines07 = self.sb.path(A07).read_bytes().decode("utf-8").split("\n")
        n = next(i for i, l in enumerate(lines07) if l.startswith("| RF01.CA1 | PRD |"))
        annex = lines07[n].split(" | ")[2]
        prd = next(p for p in (self.sb.root / "docs" / "source").iterdir() if p.name.startswith("Vigia_01"))
        lines01 = prd.read_bytes().decode("utf-8").split("\n")
        m = next(i for i, l in enumerate(lines01) if l.startswith("- **RF01.CA1:** "))
        return {
            "id": "RF01.CA1",
            "openIssue": oi,
            "source": {"file": f"docs/source/{prd.name}", "line": m + 1,
                       "text": lines01[m][len("- **RF01.CA1:** "):]},
            "annex": {"file": f"docs/source/{A07}", "line": n + 1, "text": annex_text or annex},
        }

    def _write_exceptions(self, exceptions: list) -> None:
        p = self.sb.root / "docs" / "decisions" / "text-exceptions.json"
        data = json.loads(p.read_text(encoding="utf-8"))
        data["exceptions"] = exceptions
        p.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    unittest.main(verbosity=2)
