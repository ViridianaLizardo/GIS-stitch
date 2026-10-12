# ===================================================================
# SCRIPT: PROCESAMIENTO DE PERIODOS BIOCLIMÁTICOS (1976-2025)
# ===================================================================
# Descripción: Aplica process_bioclim() para 5 períodos de 10 años
#              cubriendo desde 1976 hasta 2025
# ===================================================================

# ====== 1. CONFIGURACIÓN INICIAL ======

# Limpiar entorno (opcional, comentar si no se desea)
# rm(list = ls())

# Cargar librerías necesarias
library(AOI)
library(geodata)
library(climateR)

library(fastbioclim)
library(macroBiome)
library(terra)

# Cargar función
source('process_bioclim.R')

# Definir el Área de Interés (AOI)

mex <- AOI::aoi_get(country = 'Mexico')

# ====== 2. DEFINICIÓN DE PERIODOS ======

# Método 1: Definir manualmente los años de inicio
periodos <- data.frame(
  inicio = c(1976, 1986, 1996, 2006, 2016),
  fin    = c(1985, 1995, 2005, 2015, 2025),
  nombre = c("1976-1985", "1986-1995", "1996-2005", "2006-2015", "2016-2025")
)

# ====== 3. Aplicar función ======
anos_inicio <- seq(1956, 2025, by = 10)

lapply(anos_inicio, 
       function(x) process_bioclim(start = x, AOI = mex))


# Revisión: solo los .tif de Köppen (el patrón 'koppen' también atrapaba koppen_names.csv)
list.files(pattern = '^koppen_.*\\.tif$', recursive = TRUE) |>
  rast()
