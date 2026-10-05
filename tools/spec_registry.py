#!/usr/bin/env python3
"""VIG-001 · Registro y validación de la especificación vigente de Vigía.

Uso (desde la raíz del repositorio, Python 3.10+ sin dependencias externas):

    python tools/spec_registry.py build   # regenera docs/spec-index.json,
                                          # docs/traceability.json y
                                          # docs/release-checklist.json
    python tools/spec_registry.py check   # valida hashes, IDs, conteos y
                                          # referencias QA contra las fuentes

`build` es determinista: no escribe fechas ni datos del equipo, de modo que
regenerar sin cambios en docs/source/ deja el diff vacío. `check` vuelve a
extraer todo desde docs/source/ y compara; nunca modifica archivos.

Las fuentes de docs/source/ son de solo lectura para este script.
"""

from __future__ import annotations

import base64
import gzip
import hashlib
import json
import re
import sys
from collections import Counter, OrderedDict
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE_DIR = ROOT / "docs" / "source"
SPEC_INDEX = ROOT / "docs" / "spec-index.json"
TRACEABILITY = ROOT / "docs" / "traceability.json"
RELEASE_CHECKLIST = ROOT / "docs" / "release-checklist.json"

GENERATOR = "tools/spec_registry.py build"

# ---------------------------------------------------------------------------
# Metadatos curados de las fuentes. Ruta, tamaño y hash se calculan; versión
# y fecha son las declaradas en el propio documento (evidencia = texto literal
# que `check` busca en el archivo).
# ---------------------------------------------------------------------------

RECEIVED_SOURCES = [
    {
        "logicalId": "A01-PRD",
        "area": "01",
        "title": "PRD: producto y alcance de la primera versión",
        "file": "Vigia_01_PRD_Producto_y_Alcance_v1.1 (1).md",
        "citedAs": "Vigia_01_PRD_Producto_y_Alcance_v1.1.md",
        "declaredVersion": "1.1",
        "declaredDate": "1 de octubre de 2026",
        "versionEvidence": "Área 01 · Versión 1.1 de la especificación · 1 de octubre de 2026",
        "authority": "Alcance y 126 criterios RF/RNF: 96 RF y 30 RNF",
        "notes": [
            "El nombre real lleva el sufijo ' (1)'; las Áreas 03, 04 y 08 lo citan sin sufijo. "
            "Se conserva el nombre real sin renombrar (ver OI-01).",
        ],
    },
    {
        "logicalId": "A02-UX",
        "area": "02",
        "title": "Experiencia de usuario, flujos y navegación",
        "file": "Vigia_02_UX_Flujos_y_Navegacion_v1.0.md",
        "citedAs": "Vigia_02_UX_Flujos_y_Navegacion_v1.0.md",
        "declaredVersion": "1.0",
        "declaredDate": None,
        "versionEvidence": "**Versión:** 1.0",
        "authority": "66 criterios UX, IDs P01–P18/D01–D08, acciones, estados y guardas",
        "notes": ["El encabezado no declara fecha."],
    },
    {
        "logicalId": "A03-BRIEF",
        "area": "03",
        "title": "Brief de diseño para Claude Design",
        "file": "Vigia_03_Brief_Diseno_Claude_Design_v1.0.md",
        "citedAs": "Vigia_03_Brief_Diseno_Claude_Design_v1.0.md",
        "declaredVersion": "1.0",
        "declaredDate": "1 de octubre de 2026",
        "versionEvidence": "Área 03 y Área 04 · Versión 1.0 · 1 de octubre de 2026",
        "authority": "Referencia visual; no modifica estados ni criterios funcionales",
        "notes": [
            "El encabezado dice 'Área 03 y Área 04'; el Área 04 vigente es el documento de arquitectura.",
        ],
    },
    {
        "logicalId": "A03-INSTRUCTIONS",
        "area": "03",
        "title": "Instrucciones de trabajo para Claude Design",
        "file": "Vigia_03_Instrucciones_Claude_Design_v1.0.md",
        "citedAs": "Vigia_03_Instrucciones_Claude_Design_v1.0.md",
        "declaredVersion": "1.0",
        "declaredDate": "1 de octubre de 2026",
        "versionEvidence": "Versión 1.0 · 1 de octubre de 2026",
        "authority": "Orden y entregables de diseño B1–B5; referencia visual",
        "notes": [],
    },
    {
        "logicalId": "A04-ARCHITECTURE",
        "area": "04",
        "title": "Arquitectura técnica y contratos",
        "file": "Vigia_04_Arquitectura_Tecnica_y_Contratos_v1.0.md",
        "citedAs": "Vigia_04_Arquitectura_Tecnica_y_Contratos_v1.0.md",
        "declaredVersion": "1.0",
        "declaredDate": "3 de octubre de 2026",
        "versionEvidence": "Versión 1.0 · 3 de octubre de 2026",
        "authority": "Componentes, autoridad, estados, comandos/eventos y AT01–AT22",
        "notes": [],
    },
    {
        "logicalId": "A05-AI",
        "area": "05",
        "title": "IA y protocolo de evaluación",
        "file": "Vigia_05_IA_y_Protocolo_de_Evaluacion_v1.0.md",
        "citedAs": "Vigia_05_IA_y_Protocolo_de_Evaluacion_v1.0.md",
        "declaredVersion": "1.0",
        "declaredDate": "3 de octubre de 2026",
        "versionEvidence": "Versión 1.0 · 3 de octubre de 2026",
        "authority": "Q/Kcal/política experimental, AI01–AI28, EV01–EV13, SC01–SC14",
        "notes": [
            "Parámetros del §7 con profileId=lab-eye-rules-0.1 y qualificationStatus=experimental; "
            "no son política de producción (ver OI-05).",
        ],
    },
    {
        "logicalId": "A06-DATA",
        "area": "06",
        "title": "Modelo de datos y privacidad",
        "file": "Vigia_06_Modelo_de_Datos_y_Privacidad_v1.0.md",
        "citedAs": "Vigia_06_Modelo_de_Datos_y_Privacidad_v1.0.md",
        "declaredVersion": "1.0",
        "declaredDate": "3 de octubre de 2026",
        "versionEvidence": "Versión 1.0 · 3 de octubre de 2026",
        "authority": "DDL/contratos de datos, borrado/exportación, DT01–DT24 y DS00–DS08",
        "notes": [],
    },
    {
        "logicalId": "A07-QA",
        "area": "07",
        "title": "Plan de pruebas, calidad y distribución",
        "file": "Vigia_07_Plan_de_Pruebas_Calidad_y_Distribucion_v1.0.md",
        "citedAs": "Vigia_07_Plan_de_Pruebas_Calidad_y_Distribucion_v1.0.md",
        "declaredVersion": "1.0",
        "declaredDate": "3 de octubre de 2026, America/Bogota",
        "versionEvidence": "Versión 1.0 · 3 de octubre de 2026, America/Bogota",
        "authority": "QA01–QA40, etapas E0–E4, G01–G10, RL01–RL12 y 310 IDs trazados",
        "notes": [],
    },
    {
        "logicalId": "A08-IMPLEMENTATION",
        "area": "08",
        "title": "Plan de implementación y colaboración",
        "file": "Vigia_08_Plan_de_Implementacion_y_Colaboracion_v1.0.md",
        "citedAs": "Vigia_08_Plan_de_Implementacion_y_Colaboracion_v1.0.md",
        "declaredVersion": "1.0",
        "declaredDate": "5 de octubre de 2026 (UTC)",
        "versionEvidence": "**Versión:** 1.0 · **Fecha:** 5 de octubre de 2026 (UTC)",
        "authority": "Orden de construcción, propiedad de cambios, backlog y cierre de tareas",
        "notes": [],
    },
    {
        "logicalId": "B5.2-HTML",
        "area": "03",
        "title": "Prototipo B5.2 completo (HTML standalone)",
        "file": "Vigia B5.2 Completo (standalone).html",
        "citedAs": "HTML completo B5.2",
        "declaredVersion": "B5.2 · v1 · tokens B4.2",
        "declaredDate": "2 oct 2026",
        "versionEvidence": [
            "Vigía · B5.2 completo · Monocromo y aura (B4.2) · P01–P18 y D01–D08",
            "v1 · 2 oct 2026 · tokens B4.2 con grafito violeta en oscuro",
        ],
        "versionEvidenceLocation": (
            "Texto dentro del bundle comprimido (plantilla y script de la app); "
            "el <title> del HTML es 'Bundled Page'."
        ),
        "authority": "Referencia visual; no modifica estados ni criterios funcionales (PRD/UX prevalecen)",
        "notes": [
            "Recibido. Las Áreas 04 (§1), 07 (§1, §16) y 08 (§2, §12) lo daban por faltante (ver OI-02).",
            "La recepción no acredita pruebas Android, TalkBack, contraste medido en pantalla, "
            "rendimiento ni implementación de la interfaz Flutter.",
            "Las afirmaciones internas del HTML (120 vistas, 1440 combinaciones, contraste calculado) "
            "son evidencia de diseño declarada por la herramienta, no resultados independientes.",
            "Inventario completo de vistas, tokens, recursos y motion: VIG-032.",
        ],
    },
]

MISSING_SOURCES = [
    {
        "logicalId": "BASE-v0.2",
        "title": "Base del proyecto",
        "expectedFile": "Vigia_Base_Proyecto_v0.2.md",
        "versionCited": "0.2",
        "citedBy": [
            {"logicalId": "A01-PRD", "location": "encabezado, línea 5"},
            {"logicalId": "A04-ARCHITECTURE", "location": "§1, tabla de fuentes"},
        ],
        "notes": [
            "La versión 0.2 procede del nombre citado, no del documento, que no se recibió.",
            "Área 04 §1: el PRD y la UX vigentes sustituyen su numeración e inventario iniciales.",
        ],
    },
    {
        "logicalId": "B5.2-SUMMARY",
        "title": "Resumen de Claude del B5.2 completo",
        "expectedFile": None,
        "versionCited": None,
        "citedBy": [
            {"logicalId": "A04-ARCHITECTURE", "location": "§1 ('Compartido el 03/10/2026')"},
            {"logicalId": "A07-QA", "location": "§1"},
            {"logicalId": "A08-IMPLEMENTATION", "location": "§2"},
        ],
        "notes": [
            "No se recibió como archivo. Las fuentes indican que no es evidencia independiente.",
        ],
    },
    {
        "logicalId": "B4.2-B5.2-BRIEF",
        "title": "Brief B4.2/B5.2 como documento separado",
        "expectedFile": None,
        "versionCited": None,
        "citedBy": [
            {"logicalId": "A08-IMPLEMENTATION", "location": "§2 ('Área 03, brief B4.2/B5.2 + HTML completo por recibir') y VIG-033"},
        ],
        "notes": [
            "Solo se recibió el brief v1.0, que no fija paleta. Los tokens B4.2 que cita VIG-033 "
            "(#24232B, #302E39, #3B3845, #F7F5FA, #CEC9D5) aparecen dentro del HTML B5.2.",
            "Puede tratarse del mismo entregable B5.2; no se asume sin confirmación.",
        ],
    },
]

# ---------------------------------------------------------------------------
# Familias de IDs base (Área 07 §18/§19).
# ---------------------------------------------------------------------------

FAMILY_ORDER = ["RF.CA", "RNF.CA", "UX.CA", "AT", "AI", "EV", "DT", "SC", "DS", "UT"]
FAMILY_KIND = {
    "RF.CA": "acceptanceCriterion",
    "RNF.CA": "acceptanceCriterion",
    "UX.CA": "acceptanceCriterion",
    "AT": "architectureTest",
    "AI": "aiDeterministicFixture",
    "EV": "aiEvaluationCriterion",
    "DT": "dataTest",
    "SC": "evaluationScenario",
    "DS": "syntheticDataset",
    "UT": "userTask",
}
# Estado inicial exigido (Área 07 §3, §18; Área 08 §15).
FAMILY_STATUS = {f: "notRun" for f in FAMILY_ORDER}
FAMILY_STATUS.update({"SC": "planned", "DS": "planned", "UT": "planned"})

# Dónde se define cada familia de tabla y con qué código la cita el anexo del Área 07.
TABLE_FAMILIES = {
    "AT": ("A04-ARCHITECTURE", "A04"),
    "AI": ("A05-AI", "A05"),
    "EV": ("A05-AI", "A05"),
    "SC": ("A05-AI", "A05"),
    "DT": ("A06-DATA", "A06"),
    "DS": ("A02-UX", "UX"),
    "UT": ("A02-UX", "UX"),
}
BULLET_FAMILIES = {
    "RF.CA": ("A01-PRD", "PRD"),
    "RNF.CA": ("A01-PRD", "PRD"),
    "UX.CA": ("A02-UX", "UX"),
}


# ---------------------------------------------------------------------------
# Utilidades
# ---------------------------------------------------------------------------

def src_path(file_name: str) -> Path:
    return SOURCE_DIR / file_name


def rel(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def read_lines(logical_id: str) -> list[str]:
    meta = next(s for s in RECEIVED_SOURCES if s["logicalId"] == logical_id)
    text = src_path(meta["file"]).read_bytes().decode("utf-8")
    return text.split("\n")


def file_of(logical_id: str) -> str:
    meta = next(s for s in RECEIVED_SOURCES if s["logicalId"] == logical_id)
    return rel(src_path(meta["file"]))


def split_row(line: str) -> list[str]:
    inner = line.strip()
    assert inner.startswith("|") and inner.endswith("|"), line
    return [c.strip() for c in inner[1:-1].split("|")]


def heading_at(lines: list[str], index: int) -> str | None:
    for i in range(index, -1, -1):
        if re.match(r"^#{2,4} ", lines[i]):
            return lines[i].lstrip("#").strip()
    return None


def family_of(entry_id: str) -> str:
    m = re.match(r"^(RF|RNF|UX)\d{2}\.CA\d$", entry_id)
    if m:
        return m.group(1) + ".CA"
    return re.match(r"^[A-Z]+", entry_id).group(0)


def id_sort_key(entry_id: str):
    fam = family_of(entry_id)
    nums = [int(n) for n in re.findall(r"\d+", entry_id)]
    return (FAMILY_ORDER.index(fam), nums)


def dump_json(path: Path, data) -> str:
    return json.dumps(data, ensure_ascii=False, indent=2) + "\n"


# ---------------------------------------------------------------------------
# Inventario del bundle HTML (solo lectura; se decodifica en memoria)
# ---------------------------------------------------------------------------

def html_bundle(html_text: str):
    def block(kind: str):
        m = re.search(r'<script type="__bundler/%s">(.*?)</script>' % re.escape(kind), html_text, re.S)
        return m.group(1) if m else None

    manifest = json.loads(block("manifest"))
    ext = json.loads(block("ext_resources") or "[]")
    origin = {e["uuid"]: e["id"] for e in ext}
    template = json.loads(block("template"))
    resources = []
    decoded_texts = [template]
    for uuid, entry in manifest.items():
        data = base64.b64decode(entry["data"])
        if entry.get("compressed"):
            data = gzip.decompress(data)
        if entry["mime"].startswith("text/"):
            decoded_texts.append(data.decode("utf-8"))
        resources.append(OrderedDict([
            ("uuid", uuid),
            ("mime", entry["mime"]),
            ("compressedInBundle", bool(entry.get("compressed"))),
            ("decodedBytes", len(data)),
            ("decodedSha256", sha256_bytes(data)),
            ("declaredOrigin", origin.get(uuid)),
        ]))
    resources.sort(key=lambda r: r["uuid"])
    return resources, template, decoded_texts


# ---------------------------------------------------------------------------
# Construcción de spec-index.json
# ---------------------------------------------------------------------------

def build_spec_index():
    received = []
    for meta in RECEIVED_SOURCES:
        path = src_path(meta["file"])
        data = path.read_bytes()
        item = OrderedDict()
        item["logicalId"] = meta["logicalId"]
        item["area"] = meta["area"]
        item["title"] = meta["title"]
        item["path"] = rel(path)
        item["fileName"] = meta["file"]
        item["citedAs"] = meta["citedAs"]
        item["declaredVersion"] = meta["declaredVersion"]
        item["declaredDate"] = meta["declaredDate"]
        item["versionEvidence"] = meta["versionEvidence"]
        if "versionEvidenceLocation" in meta:
            item["versionEvidenceLocation"] = meta["versionEvidenceLocation"]
        item["sizeBytes"] = len(data)
        item["sha256"] = sha256_bytes(data)
        item["receptionStatus"] = "received"
        item["authority"] = meta["authority"]
        item["notes"] = meta["notes"]
        if path.suffix == ".html":
            resources, template, texts = html_bundle(data.decode("utf-8"))
            views = sorted(set(re.findall(r"[PD][01][0-9]__[a-z0-9_]*__v1", "\n".join(texts))))
            item["bundle"] = OrderedDict([
                ("format", "Página empaquetada: manifest de recursos base64 (gzip opcional) + plantilla JSON"),
                ("templateSha256", sha256_bytes(template.encode("utf-8"))),
                ("resources", resources),
                ("observedViewIdCount", len(views)),
                ("observedViewIdPattern", "[PD][01][0-9]__<estado>__v1"),
                ("observedViewIdNote", "Conteo de identificadores de vista encontrados en el código; "
                                       "no inspecciona ni aprueba cada vista (VIG-032)."),
            ])
        received.append(item)

    missing = []
    for meta in MISSING_SOURCES:
        item = OrderedDict()
        item["logicalId"] = meta["logicalId"]
        item["title"] = meta["title"]
        item["expectedFile"] = meta["expectedFile"]
        item["versionCited"] = meta["versionCited"]
        item["sizeBytes"] = None
        item["sha256"] = None
        item["receptionStatus"] = "missing"
        item["citedBy"] = meta["citedBy"]
        item["notes"] = meta["notes"]
        missing.append(item)

    return OrderedDict([
        ("schemaVersion", 1),
        ("task", "VIG-001"),
        ("generatedBy", GENERATOR),
        ("hashAlgorithm", "SHA-256 sobre los bytes exactos del archivo"),
        ("receptionStatusValues", {
            "received": "Archivo presente en docs/source/ con tamaño y hash calculados",
            "missing": "Citado por una fuente vigente pero no recibido; sin hash, tamaño ni contenido inventado",
        }),
        ("precedence", "Área 08 §2: PRD/UX definen comportamiento; arquitectura/IA/datos definen garantías; "
                       "QA define la demostración; el diseño define presentación. Las contradicciones "
                       "se registran en docs/decisions/open-issues.md."),
        ("sources", received),
        ("missingSources", missing),
    ])


# ---------------------------------------------------------------------------
# Extracción de los 310 IDs base
# ---------------------------------------------------------------------------

def extract_bullet_definitions():
    """RFxx.CAx / RNFxx.CAx (PRD) y UXxx.CAx (UX) con su requisito padre."""
    out = {}
    duplicates = []
    for logical_id, fam_regex, parent_regex in (
        ("A01-PRD", r"(?:RF|RNF)", r"^#{3,4} ((?:RF|RNF)\d{2}) — (.+)$"),
        ("A02-UX", r"UX", r"^### (UX\d{2}) · (.+)$"),
    ):
        lines = read_lines(logical_id)
        parent = None
        for i, line in enumerate(lines):
            pm = re.match(parent_regex, line)
            if pm:
                parent = (pm.group(1), pm.group(2).strip())
                continue
            m = re.match(r"^- \*\*(%s\d{2}\.CA\d):\*\* (.*)$" % fam_regex, line)
            if not m:
                continue
            entry_id, text = m.group(1), m.group(2)
            if entry_id in out:
                duplicates.append((entry_id, file_of(logical_id), i + 1))
                continue
            if parent is None or not entry_id.startswith(parent[0] + "."):
                raise SystemExit(f"Padre no encontrado para {entry_id} en {file_of(logical_id)}:{i + 1}")
            out[entry_id] = {
                "logicalId": logical_id,
                "line": i + 1,
                "section": heading_at(lines, i),
                "parent": OrderedDict([("id", parent[0]), ("title", parent[1])]),
                "text": text,
                "row": None,
            }
    return out, duplicates


def extract_table_definitions():
    out = {}
    duplicates = []
    for family, (logical_id, _) in TABLE_FAMILIES.items():
        lines = read_lines(logical_id)
        for i, line in enumerate(lines):
            m = re.match(r"^\| (%s\d{2}) \|" % family, line)
            if not m:
                continue
            entry_id = m.group(1)
            # Cabecera = fila anterior al separador más cercano hacia arriba.
            j = i - 1
            while j > 0 and not re.match(r"^\|\s*-{3}", lines[j]):
                j -= 1
            header = split_row(lines[j - 1])
            cells = split_row(line)
            if len(header) != len(cells):
                raise SystemExit(f"Columnas inconsistentes en {file_of(logical_id)}:{i + 1}")
            if entry_id in out:
                duplicates.append((entry_id, file_of(logical_id), i + 1))
                continue
            out[entry_id] = {
                "logicalId": logical_id,
                "line": i + 1,
                "section": heading_at(lines, i),
                "parent": None,
                "text": None,
                "row": [OrderedDict([("header", h), ("value", v)]) for h, v in zip(header[1:], cells[1:])],
            }
    return out, duplicates


def extract_annex07():
    lines = read_lines("A07-QA")
    start = next(i for i, l in enumerate(lines) if l.startswith("## 19. Anexo de trazabilidad por ID"))
    rows = {}
    duplicates = []
    for i in range(start, len(lines)):
        line = lines[i]
        if not line.startswith("| ") or line.startswith("| ID ") or line.startswith("|---"):
            continue
        cells = split_row(line)
        if len(cells) != 5:
            raise SystemExit(f"Fila de anexo con {len(cells)} columnas: A07 línea {i + 1}")
        entry_id, code, text, qa, status = cells
        if entry_id in rows:
            duplicates.append((entry_id, file_of("A07-QA"), i + 1))
            continue
        rows[entry_id] = {
            "line": i + 1,
            "sourceCode": code,
            "text": text,
            "qa": [q.strip() for q in qa.split(",")],
            "status": status,
        }
    return rows, duplicates


def extract_documented_counts():
    lines = read_lines("A07-QA")
    start = next(i for i, l in enumerate(lines) if l.startswith("## 18. Verificación de esta entrega"))
    counts = OrderedDict()
    for i in range(start, len(lines)):
        if lines[i].startswith("## 19."):
            break
        m = re.match(r"^\| (RF\.CA|RNF\.CA|UX\.CA|AT|AI|EV|DT|SC|DS|UT|Total de IDs fuente) \| (\d+) \|$", lines[i])
        if m:
            counts[m.group(1)] = int(m.group(2))
    return counts


def extract_plan08():
    lines = read_lines("A08-IMPLEMENTATION")
    start = next(i for i, l in enumerate(lines) if l.startswith("## 15. Anexo"))
    end = next(i for i, l in enumerate(lines) if l.startswith("## 16."))
    rows = {}
    duplicates = []
    for i in range(start, end):
        line = lines[i]
        if not line.startswith("| ") or line.startswith("| ID fuente") or line.startswith("|---"):
            continue
        entry_id, qa, primary, support, status = split_row(line)
        if entry_id in rows:
            duplicates.append((entry_id, file_of("A08-IMPLEMENTATION"), i + 1))
            continue
        rows[entry_id] = {
            "line": i + 1,
            "qa": [q.strip() for q in qa.split(",")],
            "primaryTask": primary,
            "supportTasks": [t.strip() for t in support.split(",") if t.strip()],
            "status": status,
        }
    return rows, duplicates


def extract_tasks08():
    lines = read_lines("A08-IMPLEMENTATION")
    tasks = OrderedDict()
    for i, line in enumerate(lines):
        m = re.match(r"^#### (VIG-\d{3}) · (.+)$", line)
        if m:
            tasks[m.group(1)] = {"title": m.group(2).strip(), "line": i + 1}
    return tasks


def extract_qa_catalog():
    lines = read_lines("A07-QA")
    catalog = []
    for i, line in enumerate(lines):
        m = re.match(r"^### (QA\d{2}) · (.+)$", line)
        if m:
            catalog.append(OrderedDict([
                ("id", m.group(1)),
                ("title", m.group(2).strip()),
                ("source", OrderedDict([
                    ("logicalId", "A07-QA"),
                    ("file", file_of("A07-QA")),
                    ("section", heading_at(lines, i - 1)),
                    ("line", i + 1),
                ])),
            ]))
    return catalog


def expected_annex_text(defn) -> str:
    if defn["text"] is not None:
        return defn["text"]
    return " · ".join(c["value"] for c in defn["row"])


def build_traceability():
    bullets, dup_b = extract_bullet_definitions()
    tables, dup_t = extract_table_definitions()
    definitions = {**bullets, **tables}
    annex, dup_a = extract_annex07()
    plan08, dup_p = extract_plan08()
    qa_catalog = extract_qa_catalog()

    all_ids = sorted(set(definitions) | set(annex) | set(plan08), key=id_sort_key)
    entries = []
    for entry_id in all_ids:
        fam = family_of(entry_id)
        defn = definitions.get(entry_id)
        a = annex.get(entry_id)
        p = plan08.get(entry_id)
        e = OrderedDict()
        e["id"] = entry_id
        e["family"] = fam
        e["kind"] = FAMILY_KIND[fam]
        if defn:
            e["parent"] = defn["parent"]
            e["source"] = OrderedDict([
                ("logicalId", defn["logicalId"]),
                ("file", file_of(defn["logicalId"])),
                ("section", defn["section"]),
                ("line", defn["line"]),
            ])
            if defn["text"] is not None:
                e["text"] = defn["text"]
            else:
                e["row"] = defn["row"]
        else:
            e["parent"] = None
            e["source"] = None
        e["qa"] = a["qa"] if a else []
        e["status"] = FAMILY_STATUS[fam]
        if a:
            e["annexA07"] = OrderedDict([
                ("line", a["line"]),
                ("sourceCode", a["sourceCode"]),
                ("text", a["text"]),
                ("textMatchesSource", defn is not None and a["text"] == expected_annex_text(defn)),
                ("status", a["status"]),
            ])
        else:
            e["annexA07"] = None
        if p:
            e["planA08"] = OrderedDict([
                ("line", p["line"]),
                ("qa", p["qa"]),
                ("primaryTask", p["primaryTask"]),
                ("supportTasks", p["supportTasks"]),
                ("status", p["status"]),
            ])
        else:
            e["planA08"] = None
        entries.append(e)

    counts = Counter(e["family"] for e in entries)
    derived_from = OrderedDict(
        (meta["logicalId"], sha256_bytes(src_path(meta["file"]).read_bytes()))
        for meta in RECEIVED_SOURCES
        if meta["logicalId"] in ("A01-PRD", "A02-UX", "A04-ARCHITECTURE", "A05-AI", "A06-DATA", "A07-QA", "A08-IMPLEMENTATION")
    )
    return OrderedDict([
        ("schemaVersion", 1),
        ("task", "VIG-001"),
        ("generatedBy", GENERATOR),
        ("derivedFromSha256", derived_from),
        ("conventions", OrderedDict([
            ("text", "Texto literal del criterio en su documento de origen (viñetas '- **ID:** texto')."),
            ("row", "Celdas literales de la fila de tabla en su documento de origen, con su encabezado."),
            ("annexA07", "Fila del anexo §19 del Área 07; textMatchesSource compara su texto con la fuente "
                         "(tablas: celdas unidas por ' · ', formato del anexo)."),
            ("qa", "Familias QA asignadas por el anexo del Área 07; asignar no significa ejecutar."),
            ("status", "notRun para criterios y ensayos; planned para escenarios SC, datasets DS y tareas UT."),
            ("planA08", "Fila del anexo §15 del Área 08: responsabilidad planificada, no aceptación."),
        ])),
        ("documentedCounts", extract_documented_counts()),
        ("counts", OrderedDict(
            [(f, counts.get(f, 0)) for f in FAMILY_ORDER]
            + [("acceptanceCriteriaRfRnfUx", sum(counts.get(f, 0) for f in ("RF.CA", "RNF.CA", "UX.CA"))),
               ("total", len(entries))]
        )),
        ("extractionDuplicates", [
            OrderedDict([("id", d[0]), ("file", d[1]), ("line", d[2])]) for d in dup_b + dup_t + dup_a + dup_p
        ]),
        ("qaCatalog", qa_catalog),
        ("entries", entries),
    ])


# ---------------------------------------------------------------------------
# release-checklist.json (RL01–RL12, fuera de los 310 IDs base)
# ---------------------------------------------------------------------------

def expand_tasks(cell: str) -> list[str]:
    tasks = []
    for part in [p.strip() for p in cell.split(",")]:
        m = re.match(r"^VIG-(\d{3})–VIG-(\d{3})$", part)
        if m:
            tasks.extend(f"VIG-{n:03d}" for n in range(int(m.group(1)), int(m.group(2)) + 1))
        elif part:
            tasks.append(part)
    return tasks


def build_release_checklist():
    lines07 = read_lines("A07-QA")
    lines08 = read_lines("A08-IMPLEMENTATION")
    rows07 = OrderedDict()
    for i, line in enumerate(lines07):
        m = re.match(r"^\| (RL\d{2}) \|", line)
        if m:
            _, evidence, status = split_row(line)
            rows07[m.group(1)] = {"line": i + 1, "evidence": evidence, "status": status,
                                  "section": heading_at(lines07, i)}
    rows08 = OrderedDict()
    for i, line in enumerate(lines08):
        m = re.match(r"^\| (RL\d{2}) \|", line)
        if m:
            _, tasks, status = split_row(line)
            rows08[m.group(1)] = {"line": i + 1, "tasksCell": tasks, "tasks": expand_tasks(tasks),
                                  "status": status, "section": heading_at(lines08, i)}
    items = []
    for rl in sorted(set(rows07) | set(rows08)):
        a, b = rows07.get(rl), rows08.get(rl)
        items.append(OrderedDict([
            ("id", rl),
            ("evidenceRequired", a["evidence"] if a else None),
            ("status", (a or b)["status"].split(";")[0].strip()),
            ("sourceA07", OrderedDict([
                ("file", file_of("A07-QA")), ("section", a["section"]), ("line", a["line"]),
                ("status", a["status"]),
            ]) if a else None),
            ("planA08", OrderedDict([
                ("file", file_of("A08-IMPLEMENTATION")), ("section", b["section"]), ("line", b["line"]),
                ("tasksCell", b["tasksCell"]), ("tasks", b["tasks"]), ("status", b["status"]),
            ]) if b else None),
        ]))
    return OrderedDict([
        ("schemaVersion", 1),
        ("task", "VIG-001"),
        ("generatedBy", GENERATOR),
        ("scope", "Checklist RL de distribución. Separado de los 310 IDs base (Área 08 §15–§16)."),
        ("conventions", OrderedDict([
            ("status", "Estado documentado (pending/blocked); ninguna RL se declara cumplida."),
            ("planA08.status", "Texto literal del Área 08 §16, incluidas aclaraciones tras ';'."),
        ])),
        ("count", len(items)),
        ("items", items),
    ])


# ---------------------------------------------------------------------------
# Comandos
# ---------------------------------------------------------------------------

def cmd_build() -> int:
    outputs = [
        (SPEC_INDEX, build_spec_index()),
        (TRACEABILITY, build_traceability()),
        (RELEASE_CHECKLIST, build_release_checklist()),
    ]
    for path, data in outputs:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(dump_json(path, data).encode("utf-8"))
        print(f"escrito {rel(path)}")
    return 0


class Report:
    def __init__(self):
        self.failures: list[str] = []
        self.warnings: list[str] = []
        self.passed: list[str] = []

    def ok(self, cond: bool, label: str, detail: str = ""):
        if cond:
            self.passed.append(label)
        else:
            self.failures.append(label + (f": {detail}" if detail else ""))

    def warn(self, label: str):
        self.warnings.append(label)


def load_json(path: Path, report: Report):
    if not path.exists():
        report.ok(False, f"{rel(path)} existe")
        return None
    raw = path.read_bytes()
    report.ok(not raw.startswith(b"\xef\xbb\xbf"), f"{rel(path)} sin BOM")
    try:
        data = json.loads(raw.decode("utf-8"))
    except Exception as exc:  # noqa: BLE001
        report.ok(False, f"{rel(path)} es JSON válido", str(exc))
        return None
    report.ok(True, f"{rel(path)} es JSON válido")
    return data


def cmd_check() -> int:
    r = Report()

    # 1. spec-index: hashes, tamaños, evidencia de versión, cobertura de docs/source/.
    index = load_json(SPEC_INDEX, r)
    if index is not None:
        registered = set()
        for s in index["sources"]:
            path = ROOT / s["path"]
            registered.add(path.name)
            if not path.exists():
                r.ok(False, f"fuente {s['logicalId']} existe", s["path"])
                continue
            data = path.read_bytes()
            r.ok(len(data) == s["sizeBytes"], f"tamaño {s['logicalId']}",
                 f"registrado {s['sizeBytes']}, real {len(data)}")
            r.ok(sha256_bytes(data) == s["sha256"], f"SHA-256 {s['logicalId']}",
                 f"registrado {s['sha256']}, real {sha256_bytes(data)}")
            r.ok(s["receptionStatus"] == "received", f"estado recibido {s['logicalId']}")
            evidence = s["versionEvidence"] if isinstance(s["versionEvidence"], list) else [s["versionEvidence"]]
            haystack = data.decode("utf-8")
            if "bundle" in s:
                resources, template, texts = html_bundle(haystack)
                haystack = "\n".join(texts)
                r.ok(resources == s["bundle"]["resources"], f"recursos del bundle {s['logicalId']}")
                r.ok(sha256_bytes(template.encode("utf-8")) == s["bundle"]["templateSha256"],
                     f"hash de plantilla {s['logicalId']}")
            for ev in evidence:
                r.ok(ev in haystack, f"evidencia de versión {s['logicalId']}", ev)
        for m in index["missingSources"]:
            r.ok(m["receptionStatus"] == "missing" and m["sha256"] is None and m["sizeBytes"] is None,
                 f"faltante {m['logicalId']} sin hash ni tamaño")
            if m["expectedFile"]:
                r.ok(not (SOURCE_DIR / m["expectedFile"]).exists(),
                     f"faltante {m['logicalId']} sigue ausente", m["expectedFile"])
        on_disk = {p.name for p in SOURCE_DIR.iterdir() if p.is_file()}
        r.ok(on_disk == registered, "todo archivo de docs/source/ está registrado",
             f"sin registrar: {sorted(on_disk - registered)}; registrados ausentes: {sorted(registered - on_disk)}")
        r.ok(index == json.loads(dump_json(SPEC_INDEX, build_spec_index())),
             "spec-index.json coincide con la regeneración desde las fuentes")

    # 2. Trazabilidad: re-extracción independiente desde las fuentes.
    trace = load_json(TRACEABILITY, r)
    bullets, dup_b = extract_bullet_definitions()
    tables, dup_t = extract_table_definitions()
    definitions = {**bullets, **tables}
    annex, dup_a = extract_annex07()
    plan08, dup_p = extract_plan08()
    tasks08 = extract_tasks08()
    qa_catalog = extract_qa_catalog()
    documented = extract_documented_counts()

    r.ok(not dup_b and not dup_t, "IDs definidos una sola vez en sus fuentes",
         str(dup_b + dup_t))
    r.ok(not dup_a, "IDs únicos en el anexo §19 del Área 07", str(dup_a))
    r.ok(not dup_p, "IDs únicos en el anexo §15 del Área 08", str(dup_p))

    qa_ids = [q["id"] for q in qa_catalog]
    r.ok(qa_ids == [f"QA{n:02d}" for n in range(1, 41)], "catálogo QA01–QA40 completo y ordenado",
         f"obtenidos {len(qa_ids)}: {qa_ids}")
    qa_set = set(qa_ids)

    src_counts = Counter(family_of(i) for i in definitions)
    annex_counts = Counter(family_of(i) for i in annex)
    for fam in FAMILY_ORDER:
        exp = documented.get(fam)
        r.ok(src_counts.get(fam, 0) == exp, f"conteo en fuentes {fam}",
             f"documentado {exp}, extraído {src_counts.get(fam, 0)}")
        r.ok(annex_counts.get(fam, 0) == exp, f"conteo en anexo A07 {fam}",
             f"documentado {exp}, anexo {annex_counts.get(fam, 0)}")
    total_doc = documented.get("Total de IDs fuente")
    r.ok(len(definitions) == total_doc, "total de IDs base en fuentes",
         f"documentado {total_doc}, extraído {len(definitions)}")
    ca = sum(src_counts.get(f, 0) for f in ("RF.CA", "RNF.CA", "UX.CA"))
    r.ok(ca == 192, "192 criterios de aceptación RF/RNF/UX", f"extraídos {ca}")
    r.ok(set(definitions) == set(annex), "mismos IDs en fuentes y anexo A07",
         f"solo fuentes {sorted(set(definitions) - set(annex))}; solo anexo {sorted(set(annex) - set(definitions))}")
    r.ok(set(definitions) == set(plan08), "mismos IDs en fuentes y anexo A08",
         f"solo fuentes {sorted(set(definitions) - set(plan08))}; solo A08 {sorted(set(plan08) - set(definitions))}")

    bad_qa = sorted({(i, q) for i, a in annex.items() for q in a["qa"] if q not in qa_set})
    r.ok(not bad_qa, "referencias QA del anexo A07 existen en QA01–QA40", str(bad_qa))
    used_qa = {q for a in annex.values() for q in a["qa"]}
    r.ok(used_qa == qa_set, "cada QA01–QA40 está referenciado por al menos un ID",
         f"sin referencias: {sorted(qa_set - used_qa)}")
    qa_mismatch = sorted(i for i in annex if i in plan08 and annex[i]["qa"] != plan08[i]["qa"])
    r.ok(not qa_mismatch, "QA de A07 y A08 coinciden por ID", str(qa_mismatch[:20]))

    status_bad = sorted(i for i, a in annex.items() if a["status"] != FAMILY_STATUS[family_of(i)])
    r.ok(not status_bad, "estado inicial del anexo A07 según familia", str(status_bad[:20]))
    status_bad08 = sorted(i for i, p in plan08.items() if p["status"] != FAMILY_STATUS[family_of(i)])
    r.ok(not status_bad08, "estado inicial del anexo A08 según familia", str(status_bad08[:20]))

    code_bad = sorted(i for i, a in annex.items()
                      if i in definitions and a["sourceCode"] != dict(
                          list(BULLET_FAMILIES.values()) + list(TABLE_FAMILIES.values())
                      ).get(definitions[i]["logicalId"]))
    r.ok(not code_bad, "fuente declarada en el anexo A07 coincide con el documento de origen", str(code_bad))

    task_bad = sorted({(i, t) for i, p in plan08.items()
                       for t in [p["primaryTask"]] + p["supportTasks"] if t not in tasks08})
    r.ok(not task_bad, "tareas del anexo A08 existen entre las fichas VIG", str(task_bad[:20]))
    r.ok(list(tasks08) == [f"VIG-{n:03d}" for n in range(1, 73)], "fichas VIG-001–VIG-072 completas",
         f"obtenidas {len(tasks08)}")

    text_mismatch = sorted(i for i in annex if i in definitions
                           and annex[i]["text"] != expected_annex_text(definitions[i]))
    if text_mismatch:
        r.warn(f"{len(text_mismatch)} textos del anexo A07 difieren de su fuente de origen: "
               f"{text_mismatch}. Se conserva el texto de origen en 'text'/'row'.")
    else:
        r.ok(True, "textos del anexo A07 idénticos a sus fuentes")

    if trace is not None:
        ids = [e["id"] for e in trace["entries"]]
        r.ok(len(ids) == len(set(ids)), "cada ID aparece una sola vez en traceability.json",
             str([i for i, c in Counter(ids).items() if c > 1]))
        r.ok(set(ids) == set(definitions), "traceability.json contiene exactamente los IDs de las fuentes",
             f"faltan {sorted(set(definitions) - set(ids))}; sobran {sorted(set(ids) - set(definitions))}")
        for lid, h in trace["derivedFromSha256"].items():
            meta = next(s for s in RECEIVED_SOURCES if s["logicalId"] == lid)
            r.ok(sha256_bytes(src_path(meta["file"]).read_bytes()) == h, f"trazabilidad derivada de {lid} vigente")
        wrong_status = [e["id"] for e in trace["entries"] if e["status"] != FAMILY_STATUS[e["family"]]]
        r.ok(not wrong_status, "estados de traceability.json (notRun/planned)", str(wrong_status[:20]))
        dangling = sorted({(e["id"], q) for e in trace["entries"] for q in e["qa"] if q not in qa_set})
        r.ok(not dangling, "referencias QA de traceability.json existen", str(dangling))
        for e in trace["entries"]:
            d = definitions.get(e["id"])
            if d is None:
                continue
            if d["text"] is not None:
                if e.get("text") != d["text"]:
                    r.ok(False, f"texto literal {e['id']}")
            elif e.get("row") != json.loads(json.dumps(d["row"])):
                r.ok(False, f"fila literal {e['id']}")
        r.ok(trace["counts"]["total"] == len(trace["entries"]), "conteo total declarado = entradas")
        r.ok(trace == json.loads(dump_json(TRACEABILITY, build_traceability())),
             "traceability.json coincide con la regeneración desde las fuentes")

    # 3. Checklist RL.
    rl = load_json(RELEASE_CHECKLIST, r)
    if rl is not None:
        rl_ids = [i["id"] for i in rl["items"]]
        r.ok(rl_ids == [f"RL{n:02d}" for n in range(1, 13)], "RL01–RL12 completos y únicos", str(rl_ids))
        r.ok(not (set(rl_ids) & set(definitions)), "RL fuera de los 310 IDs base")
        for item in rl["items"]:
            a07 = item["sourceA07"]["status"] if item["sourceA07"] else None
            a08 = item["planA08"]["status"].split(";")[0].strip() if item["planA08"] else None
            r.ok(a07 == a08 == item["status"], f"estado {item['id']} coincide en A07/A08",
                 f"A07 {a07}, A08 {a08}, registro {item['status']}")
            r.ok(item["status"] in ("pending", "blocked"), f"estado {item['id']} es pending/blocked")
            if item["planA08"]:
                missing = [t for t in item["planA08"]["tasks"] if t not in tasks08]
                r.ok(not missing, f"tareas de {item['id']} existen", str(missing))
        r.ok(rl == json.loads(dump_json(RELEASE_CHECKLIST, build_release_checklist())),
             "release-checklist.json coincide con la regeneración desde las fuentes")

    # Informe.
    print("Conteos extraídos de las fuentes:")
    for fam in FAMILY_ORDER:
        print(f"  {fam:7} {src_counts.get(fam, 0):4}  (documentado {documented.get(fam)})")
    print(f"  {'total':7} {len(definitions):4}  (documentado {total_doc})")
    print(f"  CA RF/RNF/UX: {ca}; QA en catálogo: {len(qa_ids)}; fichas VIG: {len(tasks08)}")
    print(f"\nComprobaciones superadas: {len(r.passed)}")
    for w in r.warnings:
        print(f"AVISO: {w}")
    for f in r.failures:
        print(f"FALLO: {f}")
    print("\nResultado:", "FALLÓ" if r.failures else "OK")
    return 1 if r.failures else 0


def main(argv: list[str]) -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    if len(argv) != 2 or argv[1] not in ("build", "check"):
        print(__doc__)
        return 2
    return cmd_build() if argv[1] == "build" else cmd_check()


if __name__ == "__main__":
    sys.exit(main(sys.argv))
