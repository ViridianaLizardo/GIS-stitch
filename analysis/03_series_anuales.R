# =====================================================================
# 03_series_anuales.R
# ---------------------------------------------------------------------
# Serie anual de temperatura media y precipitación total para México,
# en celdas de 0.5° (una celda = una puntada), de 1958 al último año
# completo de TerraClimate.
#
# Salidas:
#   data/series_anuales_05deg.csv   anio, lon, lat, temp (°C), prec (mm)
#   docs/datos.js                   lo mismo + clases, para la página
#
# La descarga es lo lento: cada año se guarda en data-raw/ y no se vuelve
# a bajar si el script se interrumpe.
# =====================================================================

library(terra)
library(climateR)
library(AOI)
library(jsonlite)
source("analysis/clases.R")

ANIOS  <- 1958:2025          # 1958 = inicio de TerraClimate; ajustar el final al último año publicado
RES    <- 0.5                # grados por celda (= por puntada)
UMBRAL <- 0.5                # fracción mínima de la celda con dato dentro de México
CACHE  <- "data-raw/terraclimate_anual"
dir.create(CACHE, recursive = TRUE, showWarnings = FALSE)

mex <- vect(aoi_get(country = "Mexico"))

# ---- 1. Un año: 12 meses -> temperatura media y precipitación total ----
anio_tc <- function(anio) {
  f <- file.path(CACHE, paste0(anio, ".tif"))
  if (file.exists(f)) return(rast(f))

  m <- getTerraClim(AOI = mex, varname = c("tmax", "tmin", "ppt"),
                    startDate = paste0(anio, "-01-01"), endDate = paste0(anio, "-12-01"))
  if (nlyr(m$ppt) != 12) stop(anio, ": solo hay ", nlyr(m$ppt), " meses; ¿año incompleto?")

  r <- c(mean((m$tmax + m$tmin) / 2),   # °C, media de los 12 meses
         sum(m$ppt))                     # mm, total del año
  names(r) <- c("temp", "prec")
  writeRaster(r, f)
  r
}

# ---- 2. ~4 km -> 0.5°, solo México -------------------------------------
a_malla <- function(r) {
  crs(r) <- "EPSG:4326"
  r <- mask(r, mex)
  e <- ext(r)
  r <- extend(r, ext(floor(e[1] / RES) * RES, ceiling(e[2] / RES) * RES,
                     floor(e[3] / RES) * RES, ceiling(e[4] / RES) * RES))
  fact  <- round(RES / res(r)[1])
  media <- aggregate(r, fact, mean, na.rm = TRUE)
  frac  <- aggregate(!is.na(r[[1]]), fact, mean)
  media[frac < UMBRAL] <- NA
  media
}

# ---- 3. Todos los años --------------------------------------------------
series <- do.call(rbind, lapply(ANIOS, function(a) {
  message(a)
  df <- as.data.frame(a_malla(anio_tc(a)), xy = TRUE, na.rm = TRUE)
  data.frame(anio = a, lon = df$x, lat = df$y,
             temp = round(df$temp, 2), prec = round(df$prec, 1))
}))

# Checkpoints
stopifnot(all(abs((series$lon * 4) %% 2 - 1) < 1e-6))        # centros en .25/.75
print(table(table(series$anio)))                               # mismas celdas cada año
print(aggregate(cbind(temp, prec) ~ anio, series, mean)[c(1, length(ANIOS)), ])

write.csv(series, "data/series_anuales_05deg.csv", row.names = FALSE)

# ---- 4. Datos para la página -------------------------------------------
celdas <- unique(series[c("lon", "lat")])
celdas <- celdas[order(-celdas$lat, celdas$lon), ]       # de norte a sur, de oeste a este
fila   <- match(paste(series$lon, series$lat), paste(celdas$lon, celdas$lat))
col    <- series$anio - min(ANIOS) + 1
matriz <- function(v) {                                  # una fila por celda, una columna por año
  m <- matrix(NA_real_, nrow(celdas), length(ANIOS))
  m[cbind(fila, col)] <- series[[v]]
  m
}

web <- list(
  anios  = ANIOS,
  lon    = celdas$lon,
  lat    = celdas$lat,
  temp   = unname(matriz("temp")),
  prec   = unname(matriz("prec")),
  clases = lapply(CLASES, function(cl) {
    cl$cortes <- cl$cortes[is.finite(cl$cortes)]        # solo los cortes interiores
    cl[c("cortes", "etiquetas", "colores", "dmc", "simbolos", "titulo", "paleta")]
  }),
  fuente = "TerraClimate (Abatzoglou et al. 2018), 1/24° agregado a 0.5°",
  creado = format(Sys.Date())
)
dir.create("docs", showWarnings = FALSE)
writeLines(paste0("window.CLIMA = ", toJSON(web, digits = NA, auto_unbox = TRUE), ";"),
           "docs/datos.js", useBytes = TRUE)
message("Listo: ", nrow(celdas), " celdas x ", length(ANIOS), " años")
