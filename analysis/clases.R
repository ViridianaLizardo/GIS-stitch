# =====================================================================
# clases.R
# Única fuente de verdad para colores, cortes y símbolos.
# La usan 02_patron_bordado.R, el Rmd y (exportada a JSON por
# 03_series_anuales.R) la página web.
# =====================================================================

CLASES <- list(
  temperatura = list(
    # Pasos de 0.4 °C; la primera clase separa las celdas que se ENFRIARON
    cortes    = c(-Inf, 0, 0.4, 0.8, 1.2, 1.6, 2.0, Inf),
    etiquetas = c("≤ 0 °C (enfriamiento)", "0–0.4 °C", "0.4–0.8 °C", "0.8–1.2 °C",
                  "1.2–1.6 °C", "1.6–2.0 °C", "> 2.0 °C"),
    colores   = c("#fbe3c2", "#f2c88f", "#ecb27d", "#e69c6b", "#d37750", "#b9563f", "#92351e"),
    paleta    = "MetBrewer OKeeffe2",
    dmc       = c("739", "3855", "3854", "402", "21", "3830", "3777"),   # hilo sugerido (aprox.)
    simbolos  = c(1, 2, 0, 5, 4, 3, 8),                   # ○ △ □ ◇ x + *
    titulo    = "Cambio de temperatura media anual"
  ),
  precipitacion = list(
    # Pasos de 10 puntos porcentuales, simétricos alrededor de ±5 %
    cortes    = c(-Inf, -45, -35, -25, -15, -5, 5, 15, 25, 35, 45, Inf),
    etiquetas = c("< −45 %", "−45 a −35 %", "−35 a −25 %", "−25 a −15 %", "−15 a −5 %",
                  "−5 a +5 %",
                  "+5 a +15 %", "+15 a +25 %", "+25 a +35 %", "+35 a +45 %", "> +45 %"),
    # Centro (−5 a +5 %): gris perla (DMC 415) en lugar del casi blanco #f6f2ee de
    # OKeeffe1, que desaparece sobre tela Aida blanca (ΔE2000 ≈ 3.5; con el gris ≈ 9.6).
    colores   = c("#6b200c", "#973d21", "#da6c42", "#ee956a", "#fbc2a9", "#d3d3d6",
                  "#bad6f9", "#7db0ea", "#447fdd", "#225bb2", "#133e7e"),
    paleta    = "MetBrewer OKeeffe1 (centro gris)",
    dmc       = c("3857", "355", "720", "722", "3771", "415",
                  "3325", "3755", "322", "312", "336"),                 # hilo sugerido (aprox.)
    simbolos  = c(17, 15, 4, 6, 2, 1, 0, 5, 3, 8, 16),    # ▲ ■ x ▽ △ ○ □ ◇ + * ●
    titulo    = "Cambio relativo de precipitación anual"
  )
)
# Los hex son los colores originales de MetBrewer::MetPalettes$OKeeffe2 y $OKeeffe1
# (salvo el centro de precipitación); se escriben aquí para que la página no dependa de R.
# Hilos DMC: el más cercano a cada color por ΔE2000 (CIELAB), usando los valores RGB de
# la lista de flossverter (https://github.com/JuliaSzulc/flossverter, GPL-3.0). Son
# aproximaciones de pantalla: conviene comparar con la carta de colores física.

stopifnot(length(CLASES$temperatura$colores) == 7,
          length(CLASES$precipitacion$colores) == 11,
          length(CLASES$temperatura$dmc) == 7,
          length(CLASES$precipitacion$dmc) == 11,
          !anyDuplicated(CLASES$temperatura$simbolos),
          !anyDuplicated(CLASES$precipitacion$simbolos))

# Símbolo blanco sobre colores oscuros, negro sobre claros
color_simbolo <- function(hex) {
  rgb <- grDevices::col2rgb(hex) / 255
  lum <- 0.2126 * rgb[1, ] + 0.7152 * rgb[2, ] + 0.0722 * rgb[3, ]
  ifelse(lum < 0.45, "white", "black")
}
