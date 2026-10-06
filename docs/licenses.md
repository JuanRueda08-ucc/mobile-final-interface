# Vigía · Recursos de terceros incluidos en la app

| Recurso | Versión | Origen | Licencia | Archivos en el repositorio | SHA-256 |
|---|---|---|---|---|---|
| Fuente Inter | 4.1 (`Version 4.001;git-9221beed3`) | Publicación oficial `rsms/inter` v4.1: `https://github.com/rsms/inter/releases/download/v4.1/Inter-4.1.zip` (descargada el 2026-10-06; zip SHA-256 `9883fdd4a49d4fb66bd8177ba6625ef9a64aa45899767dde3d36aa425756b11e`) | SIL Open Font License 1.1 | `assets/fonts/Inter/Inter-Regular.ttf` (peso 400) | `40d692fce188e4471e2b3cba937be967878f631ad3ebbbdcd587687c7ebe0c82` |
| | | | | `assets/fonts/Inter/Inter-Medium.ttf` (peso 500) | `97ad806f526e41546d46365bb3a393145f75b7b1568913db74549ad8b8dba872` |
| | | | | `assets/fonts/Inter/OFL.txt` (texto de la licencia, copiado de `LICENSE.txt` del zip) | `262481e844521b326f5ecd053e59b98c8b2da78c8ee1bdbb6e8174305e54935a` |

- Solo se incluyen los pesos 400 y 500, que son los que usa el diseño B5.2. Los archivos TTF están sin modificar.
- La API de GitHub no publica un *digest* para ese zip; la procedencia se apoya en la descarga HTTPS desde la publicación oficial del repositorio y en los hashes anteriores.
- La licencia se distribuye con la app: `OFL.txt` se declara como asset y se registra en `LicenseRegistry` (`registerVigiaLicenses`, `lib/app/vigia_app.dart`).
- No se cargan fuentes remotas. El HTML B5.2 trae Inter en WOFF2, un formato que Flutter no admite, por eso se usan los TTF oficiales.

**Iconos:** son los trazos SVG propios del prototipo B5.2 (`IC`), redibujados con `CustomPaint` en `lib/core/design_system/vigia_icons.dart`. No hay bibliotecas de iconos de terceros.
