# tools/

## spec_registry.py · validador de la especificación (VIG-001)

Herramienta auxiliar de documentación. **No forma parte del runtime de Vigía**
(app Flutter, plugin Kotlin ni build Android) y no se empaqueta en ningún APK.

| Requisito | Valor |
|---|---|
| Intérprete | Python 3.13 (verificado con 3.13.15 en Windows 11; requiere ≥ 3.10) |
| Dependencias | Solo biblioteca estándar (`json`, `hashlib`, `re`, `gzip`, `base64`, `pathlib`, `collections`; pruebas: `unittest`, `subprocess`, `tempfile`, `shutil`) |
| Red | No usa red |
| Escritura | `build` escribe solo `docs/spec-index.json`, `docs/traceability.json` y `docs/release-checklist.json`. `check` y las pruebas no escriben en el repositorio. Nada modifica `docs/source/` |

### Comandos (desde la raíz del repositorio)

```bash
python tools/spec_registry.py check                 # valida; salida 0 = OK, 1 = cualquier fallo
python tools/spec_registry.py build                 # regenera los tres JSON desde docs/source/
python -m unittest tools/test_spec_registry.py -v   # regresiones (copias temporales)
```

La opción `--root DIR` ejecuta `build`/`check` sobre otra raíz con la misma estructura. Las pruebas la usan sobre copias temporales.

### Qué valida `check`

1. **Fuentes:** SHA-256, tamaño y evidencia de versión de cada archivo de `docs/source/`, y que no hay archivos sin registrar.
2. **Duplicados por catálogo:** definiciones de origen, anexo §19 del Área 07, anexo §15 del Área 08, fichas VIG, catálogo QA, RL del Área 07 §15 y RL del Área 08 §16. Cada aparición se anota **antes** de insertarla en un diccionario. Un duplicado falla con el ID y todas sus ubicaciones (`archivo:línea`), y se compara el número de apariciones originales con el de IDs únicos.
3. **Apariciones legítimas entre documentos:** cada ID base aparece exactamente una vez en su fuente, una vez en el anexo A07 y una vez en el anexo A08. Las RL aparecen una vez en A07 §15 y una vez en A08 §16.
4. **Baseline** (ver abajo): IDs ausentes y adicionales en fuentes, anexos y `traceability.json`, conteos por familia y conteos documentados del Área 07 §18.
5. **Referencias:** QA01–QA40 existentes y todos usados, QA iguales en A07 y A08, y tareas VIG-001–VIG-072 existentes.
6. **Estados:** `notRun` para criterios y ensayos, `planned` para SC/DS/UT.
7. **RL:** estado de cada RL en A07 §15, en A08 §16 y en el registro igual al baseline (**RL09 = blocked; las otras once = pending**). Un cambio coordinado en los tres sitios falla.
8. **Textos:** toda discrepancia entre el texto de origen y el del anexo A07 **falla** (código 1). No hay excepciones en este baseline (ver abajo). El registro conserva siempre el literal de origen.
9. **Regeneración:** los tres JSON coinciden exactamente con lo que produciría `build`.

### Baseline: `docs/spec-baseline.json`

- **Procedencia:** extraído una sola vez del commit revisado `02b8798a6fd8a7ea976fe4d79ada094b7eeaffc8` (`docs/traceability.json` y `docs/release-checklist.json` de ese commit) y confirmado por el responsable del proyecto al corregir la revisión de Codex.
- **Contenido:** los 310 IDs exactos y estos conteos:

  | RF.CA | RNF.CA | UX.CA | AT | AI | EV | DT | SC | DS | UT | Total |
  |---|---|---|---|---|---|---|---|---|---|---|
  | 96 | 30 | 66 | 22 | 28 | 13 | 24 | 14 | 9 | 8 | 310 |

  También fija 192 CA RF/RNF/UX, 40 QA, 72 fichas VIG y los estados RL01–RL12.
- **Independencia:** `build` no lo lee ni lo escribe. `check` verifica su huella SHA-256 (campos `ids`, `familyCounts`, `total`, `acceptanceCriteriaRfRnfUx`, `qaCount`, `taskCount` y `releaseStatuses`) contra la constante `BASELINE_DIGEST` del validador.
- **Cambiarlo** modifica el alcance verificado y requiere una revisión explícita del alcance: nueva versión de la fuente, ADR en `docs/decisions/`, y actualizar el baseline y `BASELINE_DIGEST` en el mismo commit revisado.

### Textos: sin excepciones en el baseline VIG-001

**Política:** en este baseline **no se admiten excepciones de texto**.
- Toda discrepancia entre el texto de origen y la fila del anexo §19 del Área 07 produce `FALLO` y código de salida 1, cite o no un hallazgo abierto.
- `docs/decisions/text-exceptions.json` debe tener la lista `exceptions` vacía. Cualquier entrada, completa o no, falla con «excepciones de texto no admitidas en el baseline VIG-001».
- Los hallazgos de `docs/decisions/open-issues.md` (por ejemplo, OI-08 sobre RF27.CA2) **documentan** contradicciones, pero no sustituyen la comparación literal ni vuelven aceptable una discrepancia.
- No existe lógica que convierta una discrepancia en aceptable (constante `TEXT_EXCEPTIONS_ALLOWED = False` en el validador).

**Alcance:**
- La política cubre la coherencia entre las fuentes y el anexo A07 del baseline VIG-001. Hoy los 310 textos coinciden.
- No corrige ni reinterpreta ningún requisito: RF27.CA2 conserva su literal y su contradicción sigue en OI-08.
- Admitir excepciones en el futuro requeriría una revisión explícita de esta política, con ADR, cambio del validador y nuevas pruebas, y no se haría para ocultar casos de prueba.

### Regresiones (`tools/test_spec_registry.py`)

Cada caso copia las fuentes a un directorio temporal, altera **solo la copia** con datos simulados, regenera los registros y ejecuta `check --root` como proceso aparte. Los casos negativos exigen código de salida 1 y la línea `FALLO` concreta, no un aviso. El conjunto verifica además que el SHA-256 de las fuentes reales no cambia.

| Caso | Resultado exigido |
|---|---|
| Repositorio real sin regenerar / copia regenerada | OK (código 0) |
| RL09 → pending, coordinado en A07, A08 y registro | Falla contra el baseline en los tres |
| Ficha VIG-005 duplicada | Falla con ambas ubicaciones |
| Fila RL03 duplicada en A07 y A08 | Falla en cada catálogo |
| AT23 coordinado (fuente, anexos, conteo AT 23 y total 311) | Falla: ID adicional y conteos |
| Solo total documental 311 | Falla |
| AT22 eliminado de la fuente | Falla: ID ausente |
| Baseline alterado (AT23 / 311) | Falla: huella distinta |
| Texto del anexo distinto del origen | Falla y conserva el literal de origen |
| Excepción incompleta | Falla |
| Excepción completa citando un OI ajeno (OI-03) a RF01.CA1 | Falla |
| Excepción citando OI-08 para otra discrepancia simulada de RF27.CA2 | Falla |
| Excepción completa con OI simulado que documenta el ID y ambas citas exactas | Falla |
| Cualquier entrada en `text-exceptions.json`, aunque no haya discrepancia | Falla |

### Límites

- Valida la coherencia documental, no el funcionamiento de la app.
- Un `OK` no aprueba criterios, ensayos QA, gates ni RL.
- Las pruebas usan mutaciones simuladas y no cubren cualquier alteración posible de los documentos. La extracción se basa en el formato Markdown actual (viñetas `- **ID:**` y filas de tabla).
