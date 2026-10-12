# =====================================================================
# 01_exportar_malla_05.R
# ---------------------------------------------------------------------
# De las climatologías decenales de TerraClimate (BIO01, BIO12; ~4 km)
# a una malla de 0.5° alineada con CRU TS (centros en .25/.75),
# lista para convertirse en patrón de bordado (1 celda = 1 puntada).
#
# Entrada : <DIR_IN>/<AAAA-AAAA>/bio01.tif, bio12.tif
#           (salida de process_bioclim.R en el repo "chelsa prep")
# Salida  : data/clima_decadas_05deg.csv  (formato largo)
#
# Las anomalías NO se calculan aquí: la página web las calcula entre
# cualesquiera dos décadas a partir de los valores absolutos.
# =====================================================================

library(terra)

# ---- 1. Parámetros ---------------------------------------------------
# Ruta a las décadas. Por defecto asume que ambos repos viven en la
# misma carpeta (Documents/GitHub). Se puede pasar como argumento:
#   Rscript analysis/01_exportar_malla_05.R "ruta/a/by_me"
#   Rscript analysis/01_exportar_malla_05.R "ruta/a/by_me" "salida.csv" "limite_mexico.gpkg"
args      <- commandArgs(trailingOnly = TRUE)
DIR_IN    <- if (length(args) >= 1) args[1] else "../chelsa prep/by_me"
OUT       <- if (length(args) >= 2) args[2] else "data/clima_decadas_05deg.csv"
MASK_PATH <- if (length(args) >= 3) args[3] else NA   # NA = usar AOI::aoi_get()

RES_OUT    <- 0.5     # grados
UMBRAL_TIE <- 0.5     # fracción mínima de pixeles de México con dato para conservar la celda

VARS <- data.frame(
  variable = c("temperatura", "precipitacion"),
  codigo   = c("bio01", "bio12"),
  unidad   = c("grados_C", "mm_anio")   # ASCII a propósito: evita problemas de codificación en Windows
)

stopifnot(dir.exists(DIR_IN))

# ---- 1b. Límite de México --------------------------------------------
# Las climatologías de "chelsa prep" vienen recortadas al rectángulo
# envolvente de México (incluyen sur de EE. UU., Guatemala, Belice), no
# enmascaradas. Se enmascara aquí, a ~4 km, ANTES de agregar.
if (is.na(MASK_PATH)) {
  mex <- vect(AOI::aoi_get(country = "Mexico"))   # mismo límite que process_bioclim.R
} else {
  mex <- vect(MASK_PATH)
}
mex <- project(mex, "EPSG:4326")

periodos <- sort(grep("^\\d{4}-\\d{4}$", list.dirs(DIR_IN, full.names = FALSE,
                                                    recursive = FALSE), value = TRUE))
stopifnot(length(periodos) > 0)
message("Periodos encontrados: ", paste(periodos, collapse = ", "))

# ---- 2. Función: un raster -> malla 0.5° -----------------------------
a_malla_05 <- function(r) {
  # Los tif traen un CRS geográfico "unknown" basado en WGS84: se declara EPSG:4326
  stopifnot(is.lonlat(r))
  crs(r) <- "EPSG:4326"
  r <- mask(r, mex)

  fact <- round(RES_OUT / res(r)[1])
  # checkpoint: la resolución debe dividir exactamente 0.5°
  stopifnot(abs(res(r)[1] * fact - RES_OUT) < 1e-9,
            abs(res(r)[2] * fact - RES_OUT) < 1e-9)

  # Extender a bordes múltiplos de 0.5° para que los bloques coincidan
  # con las celdas CRU (TerraClimate de México NO empieza en un borde de 0.5°)
  e <- ext(r)
  e_snap <- ext(floor(xmin(e) / RES_OUT) * RES_OUT,
                ceiling(xmax(e) / RES_OUT) * RES_OUT,
                floor(ymin(e) / RES_OUT) * RES_OUT,
                ceiling(ymax(e) / RES_OUT) * RES_OUT)
  r2 <- extend(r, e_snap)
  # checkpoint: el origen tras extender cae en un borde de 0.5°
  stopifnot(abs(xmin(r2) / RES_OUT - round(xmin(r2) / RES_OUT)) < 1e-6,
            abs(ymin(r2) / RES_OUT - round(ymin(r2) / RES_OUT)) < 1e-6)

  media <- aggregate(r2, fact = fact, fun = "mean", na.rm = TRUE)
  frac  <- aggregate(!is.na(r2), fact = fact, fun = "mean")
  media[frac < UMBRAL_TIE] <- NA
  list(media = media, frac = frac)
}

# ---- 3. Recorrer periodos y variables --------------------------------
salida <- list()
for (p in periodos) {
  for (i in seq_len(nrow(VARS))) {
    f <- file.path(DIR_IN, p, paste0(VARS$codigo[i], ".tif"))
    if (!file.exists(f)) { warning("Falta: ", f); next }

    m  <- a_malla_05(rast(f))
    df <- as.data.frame(c(m$media, m$frac), xy = TRUE, na.rm = FALSE)
    names(df) <- c("lon", "lat", "valor", "frac_datos")
    df <- df[!is.na(df$valor), ]

    anios <- as.integer(strsplit(p, "-")[[1]])
    salida[[paste(p, VARS$codigo[i])]] <- data.frame(
      periodo    = p,
      anio_ini   = anios[1],
      anio_fin   = anios[2],
      variable   = VARS$variable[i],
      codigo     = VARS$codigo[i],
      unidad     = VARS$unidad[i],
      lon        = round(df$lon, 2),
      lat        = round(df$lat, 2),
      valor      = round(df$valor, 3),
      frac_datos = round(df$frac_datos, 3)
    )
  }
}
tab <- do.call(rbind, salida)
rownames(tab) <- NULL

# ---- 4. Checkpoints --------------------------------------------------
# a) centros en .25 / .75 (misma malla que CRU TS y que México Climático)
stopifnot(all(abs((tab$lon * 4) %% 2 - 1) < 1e-6),
          all(abs((tab$lat * 4) %% 2 - 1) < 1e-6))

# b) mismas celdas en todos los periodos y variables
n_celdas <- tapply(tab$lon, list(tab$periodo, tab$codigo), length)
print(n_celdas)
if (length(unique(as.vector(n_celdas))) != 1)
  warning("El número de celdas cambia entre periodos/variables: revisar máscaras.")

# c) resumen nacional por periodo (media simple de celdas)
print(aggregate(valor ~ periodo + codigo, data = tab, FUN = function(x) round(mean(x), 2)))

# ---- 5. Escribir -----------------------------------------------------
dir.create(dirname(OUT), showWarnings = FALSE, recursive = TRUE)
write.csv(tab, OUT, row.names = FALSE, fileEncoding = "UTF-8")
message("Escrito: ", OUT, " (", nrow(tab), " filas)")
