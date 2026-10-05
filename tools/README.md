# tools/

## spec_registry.py · validador de la especificación (VIG-001)

Herramienta auxiliar de documentación. **No forma parte del runtime de Vigía**
(app Flutter, plugin Kotlin ni build Android) y no se empaqueta en ningún APK.

| Requisito | Valor |
|---|---|
| Intérprete | Python 3.13 (verificado con 3.13.15 en Windows 11; requiere ≥ 3.10) |
| Dependencias | Solo biblioteca estándar (`json`, `hashlib`, `re`, `gzip`, `base64`, `pathlib`, `collections`) |
| Red | No usa red |
| Escritura | `build` escribe solo `docs/spec-index.json`, `docs/traceability.json` y `docs/release-checklist.json`. `check` no escribe nada. Ninguno modifica `docs/source/` |

### Comandos (desde la raíz del repositorio)

```bash
python tools/spec_registry.py check   # valida; código de salida 0 = OK, 1 = fallos
python tools/spec_registry.py build   # regenera los tres JSON desde docs/source/
```

`check` vuelve a extraer los datos desde `docs/source/` y comprueba:

- SHA-256 y tamaños;
- que todos los archivos de las fuentes están registrados;
- IDs únicos;
- conteos frente al Área 07 §18 (310 IDs, 192 CA);
- referencias a QA01–QA40;
- estados `notRun`/`planned`;
- tareas VIG-001–VIG-072;
- RL01–RL12;
- que la regeneración coincide exactamente con los archivos.

`build` es determinista: si las fuentes no cambian, el diff queda vacío.

### Límites

- Valida la coherencia documental, no el funcionamiento de la app.
- Un `OK` no aprueba criterios, ensayos QA, gates ni RL.
- Si cambia una fuente, `check` falla hasta que se registre la nueva versión con `build` y se revisen los hallazgos de `docs/decisions/open-issues.md`.
