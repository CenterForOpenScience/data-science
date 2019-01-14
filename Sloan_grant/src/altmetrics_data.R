#loading libraries
#library(devtools)
#install_github("centerforopenscience/osfr")
library(osfr)
library(tidyverse)
library(rAltmetric)
library(here)
library(lubridate)

almetric_api_url <- 'https://api.altmetric.com/v1/'
api_key <- Sys.getenv("altmetric_key")

osf_altmetrics_node <- osf_retrieve_node('wh8ks')


safe_altmetrics <- safely(altmetrics, otherwise = NULL)
#step 1: pull in lates file with all the preprint DOIs
#current_dois <- read_csv(file = here::here("preprint_info.csv")) %>%
#                  select(preprint_doi)

current_dois <- read_csv(file = '/Users/courtneysoderberg/Documents/data-science/Sloan_grant/src/preprint_info.csv') %>% select(preprint_doi)

call_count <- 0
result <- list()

for (i in 1:nrow(current_dois)) {
  call_count <- call_count + 1
  print(call_count)
  if(call_count %% 500 == 0){
    Sys.sleep(5)
  }
  result[length(result) + 1] <- list(safe_altmetrics(doi = current_dois[i, 1], apikey = api_key))
}

#step 2: from each call, retain the DOI, todays altmetrics score, and counts for each medium [as well as the time the call was made]
counts <- result %>%
            map("result") %>%
            compact(.) %>%
            modify_depth(1, altmetric_data) %>%
            reduce(bind_rows) %>%
            select(doi, starts_with("cited"), starts_with("readers"), score)

#step 3: for eeach day, save the resulting DF as a file
day <- date(Sys.time())
file_name <- paste0('altmetrics_count_info_', day, '.csv')
write_csv(counts, path = here::here(file_name))

osf_upload(osf_altmetrics_node, path = here::here(file_name))









