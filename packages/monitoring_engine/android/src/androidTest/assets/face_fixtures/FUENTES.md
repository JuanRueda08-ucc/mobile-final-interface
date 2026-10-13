# Imágenes de prueba de la fase 5B (procedencia y licencia)

Solo se usan en `FaceLandmarkerInstrumentedTest` (APK de pruebas del plugin).
**No** forman parte del APK de la app. Descargadas el 2026-10-12.

| Archivo | Caso | Origen | Licencia | SHA-256 del archivo |
|---|---|---|---|---|
| `one_face_nasa_s85-41895_500px.jpg` | Un rostro | NASA, retrato oficial S85-41895 (octubre de 1985). Wikimedia Commons, [File:Official Portrait - Astronaut Michael A. Baker.jpg](https://commons.wikimedia.org/wiki/File:Official_Portrait_-_Astronaut_Michael_A._Baker.jpg). Miniatura de 500 px que genera Wikimedia a partir del original (2400×3000; SHA-1 `e8d6ba797f187f2ff07ac081f544002d7feb3dbf`, comprobado): `https://upload.wikimedia.org/wikipedia/commons/thumb/8/80/Official_Portrait_-_Astronaut_Michael_A._Baker.jpg/500px-Official_Portrait_-_Astronaut_Michael_A._Baker.jpg` | Dominio público (obra de la NASA; Commons: «Public domain», `Copyrighted: False`) | `4328cc7628483fbd682322b41be30ed2d9754d4d1d475d0746880af7d36d5cb4` |
| `two_faces_nasa_s65-56188.jpg` | Dos rostros | NASA, foto S65-56188 (1965-10-20): Thomas P. Stafford y Walter M. Schirra Jr. Wikimedia Commons, [File:Gemini 6 Crew (Stafford und Schirra).jpg](https://commons.wikimedia.org/wiki/File:Gemini_6_Crew_(Stafford_und_Schirra).jpg). Archivo original (592×476; SHA-1 `324cdd2c2b9875fd4644917b8295b32da276c48f`, comprobado) | Dominio público (obra de la NASA) | `f3edccf0e96880275072b46b5072f6466985a54893a3e62ce038ac69b82e2390` |
| `no_face_nasa_apollo17_500px.jpg` | Sin rostro | NASA, «The Blue Marble» (Apolo 17, 1972-12-07). Wikimedia Commons, [File:The Earth seen from Apollo 17.jpg](https://commons.wikimedia.org/wiki/File:The_Earth_seen_from_Apollo_17.jpg). Miniatura de 500 px que genera Wikimedia: `https://upload.wikimedia.org/wikipedia/commons/thumb/9/97/The_Earth_seen_from_Apollo_17.jpg/500px-The_Earth_seen_from_Apollo_17.jpg`. El original no se pudo descargar en esa sesión (Wikimedia devolvió una página de error), así que su SHA-1 no se comprobó | Dominio público (obra de la NASA) | `2075157c388887df11e7f4e1320717f5c0a38673d30c59340e3df6a059ae2f3e` |

La licencia se tomó de los metadatos de Commons (`LicenseShortName`, `UsageTerms`, `Copyrighted`) consultados con la API de Commons el 2026-10-12. Las obras de la NASA no tienen derechos de autor en EE. UU.; Commons las marca como dominio público. Son retratos públicos de astronautas y no se usan para identificar a nadie: la prueba solo cuenta rostros.

Además, la prueba genera una imagen **sintética** uniforme, sin rostro. Solo acredita el caso «sin rostro» en esa imagen.
