# combine climate model humidity data by averaging

library(tidyverse)

raw_data_loc <- "/home/shares/ohi/stressors_2021/_raw_data/NOAA_cmip6_land_downscale/humidity"
raw_data_list <- list.files(raw_data_loc, full=TRUE)

file_list_basename <- list.files("/home/shares/ohi/stressors_2021/_raw_data/NOAA_cmip6_land_downscale/humidity")

combos <- data.frame(stringr::str_split_fixed(file_list_basename, "_", 7))[,c(3,4,7)] 

names(combos) <- (c("model", "scenario", "year"))

combos <- combos %>%
  mutate(year = gsub(".tif", "", year)) %>%
  filter(model %in% unique(model[scenario=="ssp370"]))

table(combos$scenario)
table(combos$model, combos$scenario)

included_models <- paste(unique(combos$model), collapse="|")

scenario_list = c("ssp126", "ssp245", "ssp370", "ssp585")
year_list = paste0(c(2015:2020, 2021:2040, 2041:2060, 2081:2100), ".nc")

for(scenario in scenario_list){ # scenario = scenarios[1]
  
  scenario_files <- grep(scenario, raw_data_list, value=TRUE)
  scenario_files <- grep(included_models, scenario_files, value=TRUE)
  scenario_files <- grep("HadGEM3-GC31-LL|HadGEM3-GC31-MM|KACE|UKESM1", scenario_files, value=TRUE, invert=TRUE) # didn't have at least 365 days!
  
  for(year in year_list){ #year = "2020.nc"
    ensemble_files <- grep(year, scenario_files, value=TRUE)
    n_ensemble_files <- length(ensemble_files)
    ensemble_files <- paste(ensemble_files, collapse=" ")
    
    saveFile <- sprintf("/home/shares/ohi/stressors_2021/_dataprep/T_air/relhumidity_ensemble/humidity_%s_%s_%s", n_ensemble_files, scenario, year)
    
    cdo_command <- sprintf("cdo ensmean %s  %s", ensemble_files, saveFile)
    
    system(cdo_command)
  }
}
