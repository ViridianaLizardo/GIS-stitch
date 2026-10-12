library(terra)
library(tmap)
library(Polychrome)
library(macroBiome)
library(dplyr)
library(stringr)

names <- read.csv('koppen_names.csv') %>%
  mutate(big = str_sub(code,start = 1,end = 1))


koppen <- list.files(
  full.names = TRUE,
  pattern = "^koppen_.*\\.tif$",   # solo los raster; 'koppen' también atrapaba koppen_names.csv
  recursive = TRUE
) |>
  rast() |>
  as.factor()

kopen_df <- koppen %>%
  as.data.frame()

n <- nrow(levels(koppen)[[1]])
pal <- Polychrome::palette36.colors(n)

tmap_mode("plot")

tm_shape(koppen) +
  tm_raster(
    col.scale = tm_scale(values = pal),
    col.legend = tm_legend(title = "Köppen class"),
    colorNA = "transparent"
  ) +
  tm_layout(
    frame = FALSE,
    legend.outside = TRUE
  )
