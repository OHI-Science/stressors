library(terra)
library(tidyverse)
library(here)

rast_base_10km_file <- terra::rast(here('_spatial/rast_base_mol_10km.tif'))
ocean <- terra::rast(here('_spatial/ocean_area_mol.tif'))
land_coast <- terra::ifel(ocean<1,  1, 0)
land <- terra::ifel(is.na(land_coast), 1, land_coast)
land_mask <- terra::ifel(land==1, 1, NA)


raw_data_loc <- "/home/shares/ohi/stressors_2021/_raw_data/NOAA_cmip6_land_downscale/data"
finished <- list.files("/home/shares/ohi/stressors_2021/_dataprep/T_air/proportion_days_35C")

nc_file_list <- list.files(raw_data_loc, full=TRUE)[(length(finished)-1):length(list.files(raw_data_loc, full=TRUE))]

threshold <- 273.15 + 35  # Change this to your desired threshold


for(nc_file in nc_file_list){ #nc_file = nc_file_list[1]
  # Use lapply to apply a function to each layer of the raster
  
  tmp <- terra::rast(nc_file)  
  
  layers <- lapply(1:dim(tmp)[3], function(i) { # i=1
    layer <- tmp[[i]]
    
    # Set values less than or equal to the threshold to 0
    layer <- ifel(layer < threshold, 0, 1)
    
    # Return the modified layer
    return(layer)
  })
  
  
  # Stack the layers back into a SpatRaster
  r_threshold <- rast(layers)
  
  # Sum the layers
  r_sum <- sum(r_threshold)
  #r_sum
  #plot(r_sum)
  
  sum_proj <- project(r_sum, rast_base_10km_file)
  
  sum_proj_gf <- sum_proj
  
  for(i in 1:20){
    i=1+i
    sum_proj_gf <- terra::focal(sum_proj_gf, w=3, fun=mean, na.rm=TRUE, na.policy="only")
    cat(i, "\n")
  }
  
  sum_proj_gf <- land_mask*sum_proj_gf
  
  prop_days <- sum_proj_gf/365
  prop_days <- ifel(prop_days>1, 1, prop_days)
  
  saveName <-  gsub(".nc", ".tif", basename(nc_file))
  writeRaster(prop_days, filename = sprintf("/home/shares/ohi/stressors_2021/_dataprep/T_air/proportion_days_35C/%s", saveName), overwrite = TRUE)
  
  
  
}

