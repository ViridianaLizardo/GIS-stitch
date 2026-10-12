## Load required packages
# install.packages("remotes")
remotes::install_github("gepinillab/fastbioclim")
# Install to get the package example data 
remotes::install_github("gepinillab/egdata.fastbioclim")
library(AOI)
library(geodata)
library(climateR)

library(fastbioclim)
library(macroBiome)
## Get a polygon of Mexico

mex <- AOI::aoi_get(country = 'Mexico')
## Elevación
# get3DEP() es el modelo de elevación de EE. UU. (USGS 3DEP): no cubre México y no se usa abajo.
# elev <- climateR::get3DEP(mex, resolution = "30m", ID = NULL)

## Get 10-year time-series for Mexico

monthly_ts <- climateR::getTerraClim(
  
  AOI = mex,
  
  varname = c('tmax', 'tmin', 'ppt', 
               
               'srad', 'soil'),
  
  startDate = '1995-01-01',
  
  endDate = '2025-12-01')


## Extract individual SpatRasters from the 

nyears <- nlyr(monthly_ts[[1]])/12

## Calculate 30-year monthly averages

## (climatologies).

tmin_avg <- calculate_average(x = monthly_ts$tmin, 
                              
                              index = rep(x = 1:12, times = nyears), 
                              
                              output_names = 'tmin')

tmax_avg <- calculate_average(x = monthly_ts$tmax, 
                              index = rep(x = 1:12, times = nyears), 
                              output_names = 'tmax')

prcp_avg <- calculate_average(x = monthly_ts$ppt, 
                              index = rep(x = 1:12, times = nyears), 
                              output_names = 'prcp')

srad_avg <- calculate_average(x = monthly_ts$srad, 
                              index = rep(x = 1:12, times = nyears), 
                              output_names = 'srad')

mois_avg <- calculate_average(x = monthly_ts$soil, 
                              index = rep(x = 1:12, times = nyears), 
                              output_names = 'mois')

t_avg <- (tmin_avg+tmax_avg)/2


########
# BIOME






## Get bioclimatic variables

bios_mex <- derive_bioclim(
  
  bios = 1:35, # Example for subset: c(1, 12)
  
  tmin = tmin_avg, tmax = tmax_avg, 
  
  prcp = prcp_avg, srad = srad_avg, 
  
  mois = mois_avg)

library(terra)

names(bios_mex)



## Function

years <- seq(1976,2016, 10)

process_bioclim <- function(start = 1976, AOI = mex){
  end = start+9
  
  years_name <- paste0(start, '-', end)
  
  startDate = paste0(start, '-01-01')
  
  endDate = paste0(end,'-12-01')
  
  if(dir.exists(years_name)){cat('Rewriting')}else{
    dir.create(years_name)
  }
  
  ## Get 10-year time-series for Mexico
  
  monthly_ts <- climateR::getTerraClim(  AOI = mex,  
                                         varname = c('tmax', 'tmin', 
                                                     'ppt', 'srad', 'soil'),
                                         startDate = startDate,
                                         endDate = endDate)
  
  ## Extract individual SpatRasters from the 
  
  nyears <- nlyr(monthly_ts[[1]])/12
  
  ## Calculate 10-year monthly averages
  
  ## (climatologies).
  
  tmin_avg <- calculate_average(x = monthly_ts$tmin, 
                                index = rep(x = 1:12, times = nyears), 
                                output_names = 'tmin')
  
  tmax_avg <- calculate_average(x = monthly_ts$tmax, 
                                index = rep(x = 1:12, times = nyears), 
                                output_names = 'tmax')
  
  prcp_avg <- calculate_average(x = monthly_ts$ppt, 
                                index = rep(x = 1:12, times = nyears), 
                                output_names = 'prcp')
  
  srad_avg <- calculate_average(x = monthly_ts$srad, 
                                index = rep(x = 1:12, times = nyears), 
                                output_names = 'srad')
  
  mois_avg <- calculate_average(x = monthly_ts$soil, 
                                index = rep(x = 1:12, times = nyears), 
                                output_names = 'mois')
  
  t_avg <- (tmin_avg + tmax_avg) / 2
  
  ## Get bioclimatic variables
  
  bios_mex <- derive_bioclim(
    bios = 1:35, # Example for subset: c(1, 12)
    tmin = tmin_avg, tmax = tmax_avg, 
    prcp = prcp_avg, srad = srad_avg, 
    mois = mois_avg)
  
  names(bios_mex) <- paste(names(bios_mex), years_name)
  
  ## Biomes
  koppen <- cliKoppenGrid(rs.temp = t_avg,rs.prec = prcp_avg)
  names(koppen) <- paste('koppen', years_name)
  
  holdridge <-cliHoldridgeGrid(rs.temp = t_avg,rs.prec = prcp_avg)
  names(holdridge) <- paste('holdridge', years_name)
  
  
  writeRaster(bios_mex, 
              filename = paste0(years_name, '/',
                                'bioclim_', years_name, '.tif'))
  
  writeRaster(koppen, 
              filename = paste0(years_name, '/',
                                'koppen_', years_name, '.tif'))
  writeRaster(holdridge, 
              filename = paste0(years_name, '/',
                                'holdridge_', years_name, '.tif'))
  
  cat('End')
}
