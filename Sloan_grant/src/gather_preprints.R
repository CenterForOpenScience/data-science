#loading libraries
library(httr)
library(tidyverse)
library(here)
library(lubridate)

url <- 'https://api.osf.io/v2/preprints/?filter[date_created][gte]='

process_pagination <- function(res) {
  # Create variable to hold original page
  combined_list <- res$data
  # Use the first page of the returned data to get the next page link
  next_page_link <- res$links$`next`
  # While next page link is not null, run loop
  while(!is.null(next_page_link)) {
    new_page <- process_json(httr::GET(next_page_link))
    next_page_link <- new_page$links$`next`
    combined_list <- c(combined_list, new_page$data)
  }
  return(combined_list)
}

process_json <- function(x) {
  rjson::fromJSON(httr::content(x, 'text', encoding = "UTF-8"))
}


#create GET request that includes base URL and filtering for preprints on and after that date & take API response & return table with needed attritbutes
get_preprints <- function(url, date) {
  call <- GET(url = paste0(url, date))
  res <- process_json(call)
  preprints <- process_pagination(res)
  guid <- preprints %>% map_chr("id")
  preprint_doi <- preprints %>% map("links") %>% map_chr("preprint_doi")
  date_created <- preprints %>% map("attributes") %>% map_chr("date_created")
  preprint_info <- as.tibble(cbind(guid, preprint_doi, date_created))
  preprint_info <- preprint_info %>%
                      mutate(date_created = ymd_hms(date_created))
  return(preprint_info)
}


#read in preprint info to date
old_preprints <- read_csv(file = here::here("data", "preprint_info.csv"))

##get most recent data that exists in preprint file
date <- date(old_preprints$date_created[1])
  
#make API call
new_preprints <- get_preprints(url, date)

#add combine new and old preprints and deduplicate (API can only filter by day, so their will be some overlap)
all_preprints <- rbind(new_preprints, old_preprints)
all_preprints <- distinct(all_preprints, guid, .keep_all = T)

#write out new file
write_csv(all_preprints, path = here::here("data", "preprint_info.csv"))


