# Método y decisiones

## Versión actual: ventanas de 10 años desde el año de nacimiento

- **Datos:** TerraClimate mensual (1/24°), 1958 al último año completo (`03_series_anuales.R`).
  Por año: temperatura media = media de `(tmax + tmin) / 2` en los 12 meses; precipitación = suma de los 12 meses.
- **Malla:** máscara de México (`AOI::aoi_get`), agregación a 0.5° alineada con CRU (centros en .25/.75);
  una celda se conserva si al menos el 50 % de sus pixeles tiene dato.
- **Regla:** para un año de nacimiento *a*, ventana inicial *a … a+9* y final *último−9 … último*.
  Temperatura: diferencia de medias (°C). Lluvia: cambio relativo `(final − inicial) / inicial × 100`.
  Si las ventanas se enciman (nacimiento después de *último − 19*), no hay mapa: la página muestra solo el contorno.
- **Número de la página:** promedio nacional ponderado por área (cos(latitud)); para la lluvia,
  cambio relativo de la media nacional.
- **Clases y colores:** `analysis/clases.R` (ver abajo).

## Versión anterior: décadas fijas

## Datos de entrada

- **Fuente:** TerraClimate, mensual, resolución 1/24° (~4 km), descargado con `climateR::getTerraClim()`.
- **Periodos:** rebanadas de 10 años, de 1956–1965 a 2016–2025. Climatologías mensuales promediadas
  por década (`fastbioclim::calculate_average`) y variables BIO derivadas (`fastbioclim::derive_bioclim`).
- **Variables usadas:**
  - `bio01`: temperatura media anual (°C)
  - `bio12`: precipitación anual (mm)

## De ~4 km a 0.5° (`01_exportar_malla_05.R`)

1. **CRS.** Los tif traen un CRS geográfico "unknown" basado en WGS84; se declara EPSG:4326.
2. **Máscara.** Las climatologías están recortadas al rectángulo envolvente de México: incluyen
   el sur de EE. UU., Guatemala y Belice. Se enmascaran con el límite de México
   (`AOI::aoi_get(country = "Mexico")`) **antes** de agregar.
3. **Alineación.** La malla de TerraClimate para México no empieza en un borde de 0.5°
   (xmin = −117.1667). Se extiende a bordes múltiplos de 0.5° y se agrega por bloques de
   12 × 12 pixeles. Resultado: celdas con centros en .25/.75, **la misma malla que CRU TS**
   (y que la descarga de *México Climático*, PINCC-UNAM).
4. **Agregación.** Media de los pixeles con dato. La precipitación se promedia en mm/año.
5. **Celdas costeras.** Se conserva una celda si al menos el 50 % de sus pixeles tiene dato
   dentro de México (`UMBRAL_TIE`). Bajarlo conserva más costa y la península de Baja California
   se ve más gruesa; subirlo la adelgaza.
6. **Proyección.** No se reproyecta: la malla queda en lat/lon nativa para que cada puntada sea
   exactamente una celda. El país sale estirado de este a oeste entre ~3 % (sur) y ~16 % (frontera
   norte) por el factor cos(latitud).

## Anomalías (las calcula la página)

- Temperatura: diferencia en °C entre dos décadas.
- Precipitación: cambio relativo en %, `(P_b − P_a) / P_a × 100`.
- Los cortes de color son **fijos** para todas las comparaciones, para que las décadas sean comparables.

## Clave de hilos (`02_patron_bordado.R`)

Cada clase lleva **color + símbolo** (convención de punto de cruz; el color impreso engaña).

| Variable | Paleta (MetBrewer) | Clases |
|---|---|---|
| Temperatura (°C) | `OKeeffe2`, secuencial, sus 7 colores originales (crema → rojo óxido) | ≤ 0 (enfriamiento) · 0–0.4 · 0.4–0.8 · 0.8–1.2 · 1.2–1.6 · 1.6–2.0 · > 2.0 |
| Precipitación (%) | `OKeeffe1`, divergente, sus 11 colores originales (rojo = más seco, centro casi blanco = sin cambio, azul = más húmedo) | < −45 · −45 a −35 · −35 a −25 · −25 a −15 · −15 a −5 · −5 a +5 · +5 a +15 · +15 a +25 · +25 a +35 · +35 a +45 · > +45 |

- Se usan los colores **originales** de cada paleta, sin interpolar: cada clase corresponde a un color
  real de la paleta, lo que facilita elegir hilos.
- Temperatura: la primera clase (≤ 0 °C) aísla las celdas que se **enfriaron** (aparecen al comparar
  1996–2005 o 2006–2015 con 2016–2025); el resto avanza en pasos de 0.4 °C.
- Precipitación: pasos de 10 puntos porcentuales, simétricos. Con todas las décadas frente a 2016–2025
  se usan las 11 clases, pero ningún patrón individual las usa todas (p. ej. 1986–1995 deja vacías
  las dos más húmedas): el número de hilos de una pieza es menor que 11.
- Símbolos: 7 de temperatura y 11 de precipitación, todos distintos dentro de cada variable
  (abiertos, de líneas y rellenos).
- Ambas paletas están en la lista de paletas aptas para daltonismo de MetBrewer.
- Los extremos claros (`#FBE3C2` en temperatura, `#F6F2EE` en precipitación) casi desaparecen sobre
  Aida blanca: el símbolo los sostiene en el patrón, pero en la tela conviene un fondo de color
  (p. ej. gris claro o lino) o un hilo un tono más oscuro.
- **Centro de la lluvia en gris.** El color central de OKeeffe1 (`#f6f2ee`) casi no se distingue de la
  tela Aida blanca (ΔE2000 ≈ 3.5). Se sustituyó por gris perla `#d3d3d6` (DMC 415; ΔE ≈ 9.6 frente al blanco).
- **Hilos sugeridos.** Para cada color se eligió el hilo DMC con menor ΔE2000 (CIELAB) usando los valores
  RGB de flossverter (https://github.com/JuliaSzulc/flossverter, GPL-3.0). Los tonos cálidos coinciden bien
  (ΔE 1.8–5.1); los azules de OKeeffe1 son más saturados que los hilos disponibles (ΔE 5–7). Son
  aproximaciones de pantalla y deben compararse con la carta de colores física.

## Limitaciones conocidas

- **Primera década.** TerraClimate empieza en 1958; el periodo rotulado 1956–1965 contiene,
  a lo sumo, 8 años (1958–1965). `process_bioclim.R` ya nombra ese periodo `1958-1965`; para los datos
  existentes basta con renombrar la carpeta `by_me/1956-1965` → `by_me/1958-1965` (si `getTerraClim()`
  devolvió 96 capas mensuales, es decir, 8 años).
- **Precipitación entre décadas.** La lluvia varía mucho de una década a otra (p. ej. la media
  nacional por celda sube ~25 % de 1956–1965 a 1976–1985 y baja después). El signo del cambio depende
  de la década de referencia que se elija. La década de 1950 incluye una sequía severa en el norte,
  lo que puede inflar los aumentos relativos frente a ella. Hay que comunicarlo en la página.
- TerraClimate interpola estaciones con climatologías de alta resolución; en décadas tempranas y
  zonas con pocas estaciones la incertidumbre es mayor.
