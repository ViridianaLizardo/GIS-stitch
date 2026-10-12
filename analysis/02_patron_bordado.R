# =====================================================================
# 02_patron_bordado.R
# ---------------------------------------------------------------------
# Patrón de punto de cruz: cambio climático entre dos periodos
# (décadas fijas o ventanas de 10 años), una celda de 0.5° = una puntada.
#
# - Temperatura (bio01): diferencia en °C, paleta SECUENCIAL de 7 colores
#   (MetBrewer "OKeeffe2", sus 7 colores originales; crema -> rojo óxido).
# - Precipitación (bio12): cambio relativo en %, paleta DIVERGENTE de 11
#   colores (MetBrewer "OKeeffe1", sus 11 colores originales; seco = rojo,
#   húmedo = azul, centro casi blanco = sin cambio).
#   Colores originales, sin interpolar: cada clase = un color real de la paleta.
# - Cada clase lleva color + símbolo; la clave indica rango, símbolo,
#   color (hex) y número de puntadas.
#
# Entrada : data/series_anuales_05deg.csv (03_series_anuales.R) vía ventanas(),
#           o data/clima_decadas_05deg.csv (01_exportar_malla_05.R)
# Clases  : analysis/clases.R
# Salida  : patrones/<variable>_<periodo>_vs_<ref>.pdf / .png
#           patrones/<variable>_<periodo>_vs_<ref>_clave.csv
# =====================================================================

library(ggplot2)

# ---- 1. Clases fijas (iguales para todas las comparaciones) ---------
# Colores, cortes y símbolos viven en clases.R (también los usa la página).
source("analysis/clases.R")

# ---- 2. Diferencias entre décadas ------------------------------------
calcular_cambio <- function(datos, variable, periodo, ref = "2016-2025") {
  a <- datos[datos$variable == variable & datos$periodo == periodo, c("lon", "lat", "valor")]
  b <- datos[datos$variable == variable & datos$periodo == ref,     c("lon", "lat", "valor")]
  stopifnot(nrow(a) > 0, nrow(b) > 0)
  m <- merge(a, b, by = c("lon", "lat"), suffixes = c("_a", "_ref"))
  # checkpoint: mismas celdas en ambas décadas
  if (nrow(m) != nrow(a) || nrow(m) != nrow(b)) warning("Las décadas no tienen las mismas celdas.")
  m$cambio <- if (variable == "temperatura") {
    m$valor_ref - m$valor_a                              # °C
  } else {
    (m$valor_ref - m$valor_a) / m$valor_a * 100          # %
  }
  m
}

# ---- 2b. Ventanas de 10 años a partir de las series anuales -----------
# Convierte la serie anual (03_series_anuales.R) al mismo formato largo que
# usan calcular_cambio() y patron_bordado(): una fila por celda y "periodo".
#   inicial: anio .. anio+9      final: ultimo-9 .. ultimo
ventanas <- function(series, anio, ultimo = max(series$anio), n = 10) {
  ini <- anio:(anio + n - 1)
  fin <- (ultimo - n + 1):ultimo
  if (max(ini) >= min(fin)) stop("Las ventanas se enciman: el periodo es menor de ", 2 * n, " años.")
  promedio <- function(anios, etiqueta) {
    s <- series[series$anio %in% anios, ]
    a <- aggregate(cbind(temp, prec) ~ lon + lat, data = s, FUN = mean)
    rbind(data.frame(variable = "temperatura",   periodo = etiqueta, lon = a$lon, lat = a$lat, valor = a$temp),
          data.frame(variable = "precipitacion", periodo = etiqueta, lon = a$lon, lat = a$lat, valor = a$prec))
  }
  et_ini <- paste0(min(ini), "-", max(ini)); et_fin <- paste0(min(fin), "-", max(fin))
  list(datos = rbind(promedio(ini, et_ini), promedio(fin, et_fin)), inicial = et_ini, final = et_fin)
}

# ---- 3. Patrón -------------------------------------------------------
patron_bordado <- function(datos, variable = c("temperatura", "precipitacion"),
                           periodo, ref = "2016-2025",
                           out_dir = "patrones", guardar = TRUE) {
  variable <- match.arg(variable)
  cl <- CLASES[[variable]]
  m  <- calcular_cambio(datos, variable, periodo, ref)

  m$clase <- cut(m$cambio, breaks = cl$cortes, labels = cl$etiquetas, right = TRUE)
  stopifnot(!anyNA(m$clase))

  # Coordenadas de puntada: columna 1 = oeste, fila 1 = norte
  m$col <- as.integer(round((m$lon - min(m$lon)) / 0.5)) + 1L
  m$fila <- as.integer(round((max(m$lat) - m$lat) / 0.5)) + 1L
  n_col <- max(m$col); n_fila <- max(m$fila)

  # Clave: rango, símbolo, color, número de puntadas
  n <- table(factor(m$clase, levels = cl$etiquetas))
  # (ASCII en el CSV para evitar problemas de codificación)
  nombres_pch <- c(`0` = "cuadro", `1` = "circulo", `2` = "triangulo", `3` = "cruz",
                   `4` = "equis", `5` = "rombo", `6` = "triangulo invertido",
                   `8` = "asterisco", `15` = "cuadro relleno", `16` = "circulo relleno",
                   `17` = "triangulo relleno")
  clave <- data.frame(clase       = seq_along(cl$etiquetas),
                      desde       = head(cl$cortes, -1),
                      hasta       = cl$cortes[-1],
                      unidad      = ifelse(variable == "temperatura", "grados_C", "porciento"),
                      color_hex   = cl$colores,
                      simbolo_pch = cl$simbolos,
                      simbolo     = unname(nombres_pch[as.character(cl$simbolos)]),
                      hilo_dmc    = cl$dmc,
                      puntadas    = as.integer(n))
  etiquetas_leyenda <- sprintf("%s · DMC %s  (%d)", cl$etiquetas, cl$dmc, clave$puntadas)
  col_sim <- color_simbolo(cl$colores)

  # Rejilla: líneas finas cada puntada, gruesas cada 10 (convención de punto de cruz)
  lin_v <- data.frame(x = seq(0.5, n_col + 0.5, 1)); lin_v$grueso <- (lin_v$x - 0.5) %% 10 == 0
  lin_h <- data.frame(y = seq(0.5, n_fila + 0.5, 1)); lin_h$grueso <- (lin_h$y - 0.5) %% 10 == 0

  ancho_cm <- round(n_col / 14 * 2.54, 1); alto_cm <- round(n_fila / 14 * 2.54, 1)

  g <- ggplot(m, aes(col, fila)) +
    geom_tile(aes(fill = clase), width = 1, height = 1) +
    geom_point(aes(shape = clase, colour = clase), size = 1.6, stroke = 0.45) +
    geom_vline(data = lin_v, aes(xintercept = x, linewidth = grueso), colour = "grey45") +
    geom_hline(data = lin_h, aes(yintercept = y, linewidth = grueso), colour = "grey45") +
    scale_linewidth_manual(values = c(`FALSE` = 0.12, `TRUE` = 0.5), guide = "none") +
    scale_fill_manual(values = setNames(cl$colores, cl$etiquetas), labels = etiquetas_leyenda,
                      drop = FALSE, name = NULL) +
    scale_shape_manual(values = setNames(cl$simbolos, cl$etiquetas), labels = etiquetas_leyenda,
                       drop = FALSE, name = NULL) +
    scale_colour_manual(values = setNames(col_sim, cl$etiquetas), labels = etiquetas_leyenda,
                        drop = FALSE, name = NULL) +
    scale_x_continuous(breaks = c(1, seq(10, n_col, 10)), position = "top",
                       expand = expansion(add = 0.6)) +
    scale_y_reverse(breaks = c(1, seq(10, n_fila, 10)), expand = expansion(add = 0.6)) +
    coord_fixed() +
    guides(fill = guide_legend(ncol = 1, override.aes = list(size = 3))) +
    labs(
      title = sprintf("%s: %s frente a %s", cl$titulo, ref, periodo),
      x = NULL, y = NULL,
      caption = paste0(
        "Clave: color + símbolo; entre paréntesis, número de puntadas. ",
        "Tela sin bordar = fuera de México.\n",
        sprintf("%d × %d puntadas; 1 puntada = 1 celda de 0.5° (lat/lon). ", n_col, n_fila),
        sprintf("En tela Aida o cuadrillé: %.1f × %.1f cm.\n", ancho_cm, alto_cm),
        "Datos: TerraClimate (Abatzoglou et al. 2018), promedios por periodo. ",
        "Colores: ", cl$paleta, ". ",
        "Hilos DMC sugeridos: aproximación por color (flossverter); comparar con la carta física."
      )
    ) +
    theme_minimal(base_size = 11) +
    theme(panel.grid = element_blank(),
          axis.text = element_text(size = 7, colour = "grey30"),
          legend.position = "right",
          legend.key.size = unit(0.6, "cm"),
          plot.title = element_text(face = "bold"),
          plot.caption = element_text(hjust = 0, size = 8, colour = "grey30"),
          plot.background = element_rect(fill = "white", colour = NA))

  if (guardar) {
    dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
    base <- file.path(out_dir, sprintf("%s_%s_vs_%s", variable, periodo, ref))
    # A3 horizontal: tamaño práctico para imprimir y contar puntadas
    ggsave(paste0(base, ".pdf"), g, width = 16.5, height = 11.7, device = grDevices::cairo_pdf)
    ggsave(paste0(base, ".png"), g, width = 16.5, height = 11.7, dpi = 200, bg = "white")
    write.csv(clave, paste0(base, "_clave.csv"), row.names = FALSE, fileEncoding = "UTF-8")
    message("Guardado: ", base, ".pdf/.png/_clave.csv")
  }
  invisible(list(grafica = g, clave = clave, datos = m))
}

# ---- 4. Uso ----------------------------------------------------------
# El Rmd usa options(clima.solo_funciones = TRUE) para cargar solo las funciones.
if (!isTRUE(getOption("clima.solo_funciones"))) {
  series <- read.csv("data/series_anuales_05deg.csv")   # salida de 03_series_anuales.R

  v <- ventanas(series, anio = 1989)                   # 1989-1998 frente a 2016-2025
  for (var in c("temperatura", "precipitacion"))
    patron_bordado(v$datos, var, periodo = v$inicial, ref = v$final)

  # Con las décadas de 01_exportar_malla_05.R:
  # datos <- read.csv("data/clima_decadas_05deg.csv")
  # patron_bordado(datos, "temperatura", periodo = "1986-1995", ref = "2016-2025")
}
