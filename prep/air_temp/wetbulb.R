#######
## determining wetbulb temps
#######

library(terra)
library(psychrolib)
library(dplyr)

SetUnitSystem("SI")

humidity_loc <- "/home/shares/ohi/stressors_2021/_raw_data/NOAA_cmip6_land_downscale/humidity"
temp_loc <- "/home/shares/ohi/stressors_2021/_raw_data/NOAA_cmip6_land_downscale/data"

temp_list <- gsub("tasmax_", "", list.files(temp_loc))
humidity_list <- gsub("hurs_", "", list.files(humidity_loc))
#setdiff(temp_list, humidity_list)
#setdiff(humidity_list, temp_list)

calculate_wetbulb <- function(temperature_K=t_layer, humidity=h_layer) {
  pressure_Pa <- temperature_K
  pressure_Pa[] <- 101325
  T_celsius <- temperature_K - 273.15

  Twb <- T_celsius * atan(0.151977 * (humidity + 8.313659)^(1/2)) + 
    atan(T_celsius + humidity) - atan(humidity - 1.676331) + 
    0.00391838 * humidity^(3/2) * atan(0.023101 * humidity) - 4.686035
  df <- as.data.frame(stack, xy=TRUE)
  
  df <- as.data.frame(c(T_celsius, humidity), xy=TRUE)
  sds(T_celsius)
  
  pressure_Pa <- 101325  # Atmospheric pressure in Pascal at sea level
  
  
  df$wb <- GetTWetBulbFromHumRatio(df[,3], df[,4], pressure_Pa)
  
  df <- df %>%
    select(x, y, wb)
  
  wb_rast <- rast(df, type="xyz")
  crs(wb_rast) <- "EPSG:4326"  # Example for WGS 84
  
  wb_rast <- project(wb_rast, Twb)
  
  plot(wb_rast - Twb)
  
  VGetTWetBulbFromHumRatio <- Vectorize(GetTWetBulbFromHumRatio)
  
  wetbulb_temp <- VGetTWetBulbFromHumRatio(T_celsius, humidity[1], pressure_Pa[1])
  

  return(wetbulb_temp)
}

shared_list <- intersect(temp_list, humidity_list)

for(list in shared_list){ # list = shared_list[1]
humidity_raster <- terra::rast(grep(list, list.files(humidity_loc, full=TRUE), value=TRUE)) 
temp_raster <- terra::rast(grep(list, list.files(temp_loc, full=TRUE), value=TRUE)) 
#plot(humidity_raster[[1]])

t1 <- Sys.time()
wb_daily <- rast(nlyr=365)
wb_daily <- project(wb_daily, temp_raster)

for(i in 1:365){ # i = 3
 h_layer = humidity_raster[[i]]
 t_layer = temp_raster[[i]]
    
 # Stack the layers
 stacked_raster <- c(t_layer, h_layer)
 
 # Use lapp to apply function across layers
 wb_layer <- lapp(stacked_raster, calculate_wetbulb)
  
  # Append to the result raster
  result[[i]] <- wb_layer


df <- as.data.frame(stack, xy=TRUE)

df$T_celsius <- df[,4] - 273.15
  
pressure_Pa <- 101325  # Atmospheric pressure in Pascal at sea level


df$wb <- GetTWetBulbFromHumRatio(df[,5], df[,3], pressure_Pa)

df <- df %>%
  select(x, y, wb)

wb_rast <- rast(df, type="xyz")
names(wb_rast) <- paste0("day_", i)
wb_daily <- c(wb_daily, wb_rast)
cat(i)
}
writeRaster(wb_daily, sprintf("/home/shares/ohi/stressors_2021/_dataprep/T_air/wb_daily/%s", gsub(".nc", ".tif", list)),
            overwrite=TRUE)

t2 <- Sys.time()
cat(list, "\n")