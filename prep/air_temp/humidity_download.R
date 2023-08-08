library(tidyverse)

years <- c(1995:2014, 2021:2040, 2021:2040, 2041:2060, 2081:2100)
raw_data_loc <- "/home/shares/ohi/stressors_2021/_raw_data/NOAA_cmip6_land_downscale/humidity"

data_list <- read.csv("/home/shares/ohi/stressors_2021/_raw_data/NOAA_cmip6_land_downscale/gddp-cmip6-files.csv") %>%
  filter(grepl("hurs", fileURL)) %>%
  filter(grepl(paste(paste0("_", years, ".nc"), collapse="|"), fileURL)) %>%
  pull(fileURL)

for(data in data_list[(length(list.files(raw_data_loc))-1):length(data_list)]){ # data=data_list[2]
  
  cmip_url <- trimws(data)
  save_loc <- file.path(raw_data_loc, basename(cmip_url))
  
  download.file(cmip_url, save_loc)
  cat("finished = ", cmip_url, "\n")
  
}
