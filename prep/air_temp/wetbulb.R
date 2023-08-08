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

calculate_wetbulb <- function(humidity, temperature_K) {
  pressure_Pa <- humidity
  pressure_Pa <- 101325
  T_celsius <- temperature_K - 273.15

  # Use your logic here to compute wetbulb temperature based on humidity and temperature
  # Here's a dummy function
    wetbulb_temp <- mapply(GetTWetBulbFromHumRatio, T_celsius, h_vector, pressure_Pa)
  
  
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
    
  wb_layer <- terra::app(h_layer, t_layer, fun=calculate_wetbulb)
  
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