#load libraries
library(hypothesisr)
library(tidyverse)
library(lubridate)
library(here)
library(osfr)

osf_grant_node <- osf_retrieve_node("h9mwd")
annotations_file <- osf_retrieve_file("9dpqm")

preprint_domains <- c('agrixiv', 'afriarxiv', 'arabixiv', 'bitss', 'eartharxiv', 'ecsarxiv', 
                      'engrxiv', 'frenxiv', 'inarxiv','marxiv', 'mindrxiv',  'nutrixiv',
                      'osf', 'paleorxiv', 'psyarxiv', 'socarxiv', 'sportrxiv', 'thesiscommons')

get_annotations = function(preprint_domains, date) {
  
  all_annotations <- distinct(map_dfr(preprint_domains, ~hs_search_all(sort = "created", custom =  list(search_after = date, uri.parts = .), order = "asc")), id, .keep_all = T)
  
  only_production <- all_annotations %>%
    filter(!grepl('cos', uri), !grepl('staging',uri), !grepl('wiki', uri), !grepl('developer', uri), 
           !grepl('github', uri), !grepl('mfr', uri), !grepl('files', uri), !grepl("blogs", uri), !grepl("register", uri)) %>%
    mutate(guid = case_when(str_detect(str_sub(uri, -1), "/") ~ str_sub(uri, -6, -2),
                            str_detect(str_sub(uri, -1), "/") == FALSE ~ str_sub(uri, -5, -1))) %>%
    mutate(created = ymd_hms(created), updated = ymd_hms(updated)) %>%
    select(updated, text, created, uri, guid, user, id, links.json, links.html, links.incontext)
  
  return(only_production)
}

osf_download(annotations_file, overwrite = T)
old_annotations <- read_csv(file = here::here("annotation_info.csv"))

##get most recent data that exists in preprint file
date <- date(old_annotations$created[1])

#make API call
new_annotations <- get_annotations(preprint_domains, date)

#add combine new and old preprints and deduplicate (API can only filter by day, so their will be some overlap)
annotation_info <- rbind(new_annotations, old_annotations)
annotation_info <- distinct(annotation_info, id, .keep_all = T) %>%
                      arrange(desc(updated))

#write out new file
write_csv(annotation_info, path = here::here("annotation_info.csv"))
osf_upload(osf_grant_node, path = here::here("annotation_info.csv"), overwrite = T)


