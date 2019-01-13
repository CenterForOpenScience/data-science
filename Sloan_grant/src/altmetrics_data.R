#loading libraries
library(tidyverse)
library(rAltmetric)
library(here)
library(lubridate)

almetric_api_url <- 'https://api.altmetric.com/v1/'
api_key <- Sys.getenv("Altmetrics_API_key")

#step 1: pull in lates file with all the preprint DOIs
current_dois <- read_csv(file = here::here("preprint_info.csv")) %>%
                  select(preprint_doi)

call_count <- 0
result <- list()

for (i in 1:nrows(current_dois)) {
  call_count <- call_count + 1
  if(call_count %% 4 == 0){
    Sys.sleep(5)
  }
  request <- append(request, safe_altmetrics(doi = current_dois[i, 1], apikey = api_key))
}

#step 2: from each call, retain the DOI, todays altmetrics score, and counts for each medium [as well as the time the call was made]
results <- request %>%
            map("result") %>%
            compact(.) %>%
            modify_depth(1, altmetric_data) %>%
            reduce(bind_rows) %>%
            select(doi, starts_with("cited"), starts_with("readers"), score)

#step 3: for eeach day, save the resulting DF as a file
day <- date(Sys.time())
file_name <- paste0('altmetrics_count_info_', day, '.csv')
write_csv(results, path = here::here(file_name))

drive_upload(file = paste0('Sloan Signals of Trust Grant/Data/Altmetrics/', file_name), media = paste0(filename, '.csv'))









