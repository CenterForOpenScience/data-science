#loading libraries
library(httr)
library(tidyverse)
library(here)
library(jsonlite)
library(lubridate)

# setup api connection and authorization
url <- 'https://api.osf.io/_/metrics/preprints/'

auth_header <- httr::add_headers('Authorization' = paste('Bearer', osf_impact_auth))

# function to clean api output into table with columns for date, guid, and impact count
impact_tibble <- function(call_output) {
  pretty_result <- prettify(call_output)
  json_to_r <- fromJSON(pretty_result)
  
  # turn json output into dataframe
  call_data <- as.data.frame(unlist(json_to_r)) %>% 
    rownames_to_column() %>% 
    filter(!is.na(unlist(json_to_r))) %>% 
    rename(downloads = `unlist(json_to_r)`) %>% 
    slice(-1) %>%
    
    # separate and retain column to get date and GUID, then rename
    separate(col = rowname, into = paste("V", 1:4, sep = '_'), sep = "\\.") %>% 
    select(V_2,V_4,downloads) %>% 
    rename(date = V_2, preprint_guid = V_4) %>% 
    mutate(preprint_guid = str_sub(preprint_guid, 1, 5)) %>%
    
    # fix column types
    as_tibble() %>% 
    mutate(downloads = as.numeric(as.character(downloads))) %>% 
    mutate(date = ymd_hms(date))
  
  return(call_data)
}





