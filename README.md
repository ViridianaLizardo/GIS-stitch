# GIS-stitch

Un sistema de información geográfica hecho en punto de cruz. ¿Cuánto cambió el clima de México desde que naciste? Esta página lo calcula y lo convierte en un
patrón de punto de cruz: **una celda de 0.5° (unos 55 km) = una puntada**.

Proyecto para el taller *Algoritmos, máquinas y rituales*.

- **Página interactiva** (`docs/`): escribes tu año de nacimiento, eliges temperatura o lluvia,
  ves el bordado y descargas el patrón (PDF, PNG, lista de hilos).
- **Publicación** (`post/clima-en-punto.Rmd`): el método con código y resultados, para el sitio personal.
- **Pieza bordada**: mi mapa, de 1989 a hoy, hecho a mano.

## La regla

Para cada celda: promedio de los **10 años a partir del año de nacimiento** contra el de los
**últimos 10 años**. Temperatura en °C; lluvia en %.

## Estructura

```
analysis/
  clases.R                 colores, cortes y símbolos (única fuente; la página los recibe en datos.js)
  03_series_anuales.R      TerraClimate mensual -> serie anual 0.5° (CSV + docs/datos.js)
  02_patron_bordado.R      patrón ggplot (PDF/PNG) y lista de hilos; función ventanas()
  01_exportar_malla_05.R   versión anterior: décadas fijas desde "chelsa prep"
  00_terraclimate/         scripts de climatologías decenales (versión anterior)
  METODO.md
data/       series_anuales_05deg.csv (y clima_decadas_05deg.csv, versión anterior)
docs/       página (GitHub Pages: Settings › Pages › Deploy from branch › main /docs)
post/       Rmd de la publicación
patrones/   salidas de 02 (PDF, PNG, CSV)
```

## Reproducir

Desde la raíz del repo (abriendo `GIS_stitch.Rproj`):

```r
source("analysis/03_series_anuales.R")   # descarga 1958-2025; tarda; guarda caché en data-raw/
source("analysis/02_patron_bordado.R")   # patrones de 1989-1998 frente a 2016-2025
rmarkdown::render("post/clima-en-punto.Rmd")
```

Paquetes: `terra`, `climateR`, `AOI`, `jsonlite`, `ggplot2`, `rmarkdown`.

La página no necesita R ni servidor: lee `docs/datos.js`. Para verla localmente basta abrir
`docs/index.html` en el navegador.

## Datos y créditos

- Clima: TerraClimate (Abatzoglou et al., 2018).
- Colores: MetBrewer, paletas OKeeffe2 (temperatura) y OKeeffe1 (lluvia; el centro se cambió a gris
  perla para que se vea sobre tela blanca).
- Hilos sugeridos: el hilo DMC más cercano a cada color (ΔE2000), con los valores RGB de
  [flossverter](https://github.com/JuliaSzulc/flossverter). Son aproximaciones de pantalla.
- Decisiones y limitaciones: `analysis/METODO.md`.

## Compartir

La página guarda el año y la variable en el enlace (`?anio=1989&var=lluvia`), de modo que cada
persona comparte su propio mapa. `docs/og.png` es la imagen de vista previa (1200 × 630); las
etiquetas `og:` de `docs/index.html` usan la URL absoluta de GitHub Pages: hay que ajustarla si cambia.

## Licencia

El código está bajo licencia [MIT](LICENSE). Los datos de TerraClimate conservan sus propias
condiciones de uso.
