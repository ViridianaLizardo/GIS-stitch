# 00_terraclimate/

Scripts originales del repositorio `chelsa prep`, copiados **sin modificar**.
Producen las climatologías decenales (`by_me/<AAAA-AAAA>/bio*.tif`) que usa
`../01_exportar_malla_05.R`.

| Archivo | Papel |
|---|---|
| `process_bioclim.R` | Función `process_bioclim()`: descarga TerraClimate para 10 años, calcula climatologías mensuales, BIO1–35, Köppen y Holdridge. **Versión de referencia.** |
| `apply bioclim.R` | Aplica `process_bioclim()` a las décadas de 1956 a 2016. |
| `climatologias_10años.R` | Borrador exploratorio previo a `process_bioclim.R`. |
| `plots.R` | Mapas de Köppen (exploratorio). |
| `koppen_names.csv` | Nombres de clases Köppen que usa `plots.R`. |

Orden: `apply bioclim.R` (carga `process_bioclim.R`) → `../01_exportar_malla_05.R` → `../02_patron_bordado.R`.

## Correcciones respecto a `chelsa prep`

Copiados de `chelsa prep` y corregidos aquí (los originales no se tocaron):

- `process_bioclim.R`: si el periodo empieza antes de 1958 (inicio de TerraClimate), se recorta a 1958
  y se nombra con los años reales (1956 → `1958-1965`), con aviso.
- `climatologias_10años.R` (borrador): quitado `start = 2016`, que pisaba el argumento; `macrobiome` → `macroBiome`;
  `t_avg` ahora se calcula dentro de la función (antes se tomaba del entorno global);
  `names(holdridge)` en lugar de renombrar dos veces `koppen`; quitada la descarga duplicada de 1995–2025;
  comentado `get3DEP()` (elevación de EE. UU., no cubre México y no se usaba).
- `apply bioclim.R`: carga `terra`; `%>%` → `|>`; el patrón `koppen` ahora solo toma los `.tif`
  (antes también atrapaba `koppen_names.csv`).
- `plots.R`: carga `dplyr` y `stringr`; `koppen` se crea antes de usarse; mismo arreglo del patrón de archivos.

Sin probar en ejecución (en este entorno no están `climateR`, `fastbioclim` ni `AOI`): solo se verificó que
los cuatro scripts se analizan sin errores de sintaxis. La sintaxis de `tm_raster()` en `plots.R` mezcla
argumentos de tmap 3 (`colorNA`) y tmap 4 (`col.scale`); revisar según la versión instalada.
