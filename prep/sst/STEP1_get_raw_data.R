library(tidyverse)
library(here)
options(timeout=500)

links <- read_csv(here("prep/sst_future/inputs/get_all_urls.csv")) %>% pull(url)
links <- grep(".nc4", links, value=TRUE)

obtained <- dir("/home/shares/ohi/stressors_2021/_raw_data/sst_Xu")
grep(paste(obtained, collapse = "|"), links)
links <- links[284:284]

 for(link in links){
   # link = links[1]
   saveName = sub(".*fileName=", "", link)
   download.file(link, sprintf("/home/shares/ohi/stressors_2021/_raw_data/sst_Xu/%s", saveName),
                 method = "wget", extra="--wait=20 --random-wait --retry-on-http-error=429")
 }

# final check for missing
#link_names <- gsub(".*fileName=", "", links)
#setdiff(link_names, obtained)
#grep("atm_hist_2002_01.nc4", link_names)