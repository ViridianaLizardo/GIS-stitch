#' Procesar variables bioclimáticas para un período de 10 años
#'
#' Esta función descarga datos climáticos mensuales de TerraClim para un Área de Interés (AOI),
#' calcula promedios mensuales, deriva variables bioclimáticas y clasificaciones de biomas,
#' y guarda los resultados en archivos raster.
#'
#' @param start Año de inicio del período de 10 años (por defecto = 1976)
#' @param AOI Objeto espacial que define el Área de Interés (por defecto = mex)
#' 
#' @return NULL (los resultados se guardan en disco)
#' 
#' @examples
#' \dontrun{
#' process_bioclim(start = 2000, AOI = mexico_shape)
#' }
#'
#' @importFrom climateR getTerraClim
#' @importFrom terra nlyr writeRaster
process_bioclim <- function(start = 1976, AOI = mex) {
  
  # ====== 1. VALIDACIÓN DE ENTRADAS ======
  if (!is.numeric(start) || length(start) != 1) {
    stop("El parámetro 'start' debe ser un número entero único.")
  }
  
  # TerraClimate empieza en 1958: un periodo que inicia antes se recorta a 1958
  # y se nombra con los años que realmente contiene (p. ej. 1956 -> "1958-1965").
  end <- start + 9
  if (start < 1958) {
    warning(paste0("TerraClimate empieza en 1958: el periodo ", start, "-", end,
                   " se recorta a 1958-", end, "."))
    start <- 1958
  }
  
  # ====== 2. CONFIGURACIÓN DEL PERÍODO ======
  years_name <- paste0(start, '-', end)
  startDate <- paste0(start, '-01-01')
  endDate <- paste0(end, '-12-01')
  
  message(paste("Procesando período:", years_name))
  
  # ====== 3. CREACIÓN DE DIRECTORIO ======
  if (dir.exists(years_name)) {
    warning(paste("El directorio", years_name, "ya existe. Los archivos serán sobrescritos."))
  } else {
    dir.create(years_name, recursive = TRUE)
    message(paste("✓ Directorio creado:", years_name))
  }
  
  # ====== 4. DESCARGA DE DATOS CLIMÁTICOS ======
  message("  ↳ Descargando datos climáticos de TerraClim...")
  tryCatch({
    monthly_ts <- climateR::getTerraClim(
      AOI = AOI,
      varname = c('tmax', 'tmin', 'ppt', 'srad', 'soil'),
      startDate = startDate,
      endDate = endDate
    )
    message("  ✓ Datos descargados exitosamente.")
  }, error = function(e) {
    stop(paste("Error en la descarga de datos:", e$message))
  })
  
  # ====== 5. CÁLCULO DE PROMEDIOS MENSUALES ======
  nyears <- terra::nlyr(monthly_ts[[1]]) / 12
  message(paste("  ↳ Calculando promedios para", nyears, "años..."))
  
  # Índice para promediar por meses (12 meses repetidos N años)
  month_index <- rep(1:12, times = nyears)
  
  # Función auxiliar para calcular promedios con manejo de errores
  calc_avg_safe <- function(data, var_name) {
    tryCatch({
      result <- calculate_average(
        x = data,
        index = month_index,
        output_names = var_name,
        overwrite = TRUE
      )
      return(result)
    }, error = function(e) {
      stop(paste("Error calculando promedio para", var_name, ":", e$message))
    })
  }
  
  tmin_avg <- calc_avg_safe(monthly_ts$tmin, 'tmin')
  tmax_avg <- calc_avg_safe(monthly_ts$tmax, 'tmax')
  prcp_avg <- calc_avg_safe(monthly_ts$ppt, 'prcp')
  srad_avg <- calc_avg_safe(monthly_ts$srad, 'srad')
  mois_avg <- calc_avg_safe(monthly_ts$soil, 'mois')
  
  # Temperatura media anual para clasificaciones de biomas
  t_avg <- (tmin_avg + tmax_avg) / 2
  
  message("  ✓ Promedios mensuales calculados.")
  
  # ====== 6. DERIVACIÓN DE VARIABLES BIOCLIMÁTICAS ======
  message("  ↳ Derivando variables bioclimáticas (BIO1-35)...")
  tryCatch({
    bios_mex <- derive_bioclim(
      bios = 1:35,
      tmin = tmin_avg,
      tmax = tmax_avg,
      prcp = prcp_avg,
      srad = srad_avg,
      mois = mois_avg,
      output_dir = years_name,
      overwrite = TRUE
    )
    
    # Agregar período a los nombres de las capas
    names(bios_mex) <- paste(names(bios_mex), years_name, sep = "_")
    message("  ✓ Variables bioclimáticas derivadas.")
    
  }, error = function(e) {
    stop(paste("Error derivando bioclimáticas:", e$message))
  })
  
  # ====== 7. CLASIFICACIONES DE BIOMAS ======
  message("  ↳ Calculando clasificaciones de biomas...")
  
  tryCatch({
    # Clasificación Köppen
    koppen <- cliKoppenGrid(rs.temp = t_avg, rs.prec = prcp_avg)
    names(koppen) <- paste('koppen', years_name, sep = "_")
    
    # Clasificación Holdridge
    holdridge <- cliHoldridgeGrid(rs.temp = t_avg, rs.prec = prcp_avg)
    names(holdridge) <- paste('holdridge', years_name, sep = "_")
    
    message("  ✓ Clasificaciones de biomas calculadas.")
    
  }, error = function(e) {
    warning(paste("Error calculando clasificaciones de biomas:", e$message))
    # Continuar aunque fallen las clasificaciones
  })
  
  # ====== 8. GUARDADO DE ARCHIVOS ======
  message("  ↳ Guardando archivos raster...")
  
  # Verificar que los objetos existen antes de guardar

  if (exists("koppen") && !is.null(koppen)) {
    terra::writeRaster(
      koppen,
      filename = file.path(years_name, paste0('koppen_', years_name, '.tif')),
      overwrite = TRUE
    )
    message("  ✓ Clasificación Köppen guardada.")
  }
  
  if (exists("holdridge") && !is.null(holdridge)) {
    terra::writeRaster(
      holdridge,
      filename = file.path(years_name, paste0('holdridge_', years_name, '.tif')),
      overwrite = TRUE
    )
    message("  ✓ Clasificación Holdridge guardada.")
  }
  
  # ====== 9. REPORTE FINAL ======
  message(paste("✅ Procesamiento completado para", years_name))
  message(paste("   Archivos guardados en:", years_name, "/"))
  
  # Retorno invisible (opcional para depuración)
  invisible(list(
    period = years_name,
    directory = years_name,
    files = list.files(years_name, pattern = "\\.tif$")
  ))
}