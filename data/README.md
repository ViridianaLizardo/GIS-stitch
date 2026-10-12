# data/

## clima_decadas_05deg.csv

Generado por `analysis/01_exportar_malla_05.R`. Formato largo: una fila por celda, periodo y variable.

| columna      | descripción                                                        |
|--------------|--------------------------------------------------------------------|
| `periodo`    | década, `AAAA-AAAA`                                                |
| `anio_ini`   | año inicial del rótulo                                             |
| `anio_fin`   | año final                                                          |
| `variable`   | `temperatura` o `precipitacion`                                    |
| `codigo`     | variable bioclimática de origen (`bio01`, `bio12`)                 |
| `unidad`     | `grados_C` o `mm_anio`                                             |
| `lon`, `lat` | centro de la celda de 0.5° (WGS84, EPSG:4326)                      |
| `valor`      | media de la celda                                                  |
| `frac_datos` | fracción de pixeles de ~4 km con dato dentro de México (0.5–1)     |

Valores absolutos, no anomalías: la página calcula la diferencia entre las dos décadas elegidas.
