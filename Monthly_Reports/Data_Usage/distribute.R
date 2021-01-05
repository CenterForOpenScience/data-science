# load libraries
library(rmarkdown)
library(osfr)
library(lubridate)
library(tidyverse)


# get pre-aggregated datafile
osf_retrieve_file('https://osf.io/a7w36/') %>%
  osf_download(path = here::here('Data_Usage/'), conflicts = "overwrite")

# get raw data zip file for this month and unzip into a folder
last_month <- date(floor_date(Sys.time() - months(1), unit = 'month'))

osf_retrieve_node('https://osf.io/r83uz/') %>% 
  osf_ls_files('Data Storage Usage', pattern = as.character(last_month)) %>%
  osf_download(path = here::here('Data_Usage/'))

months_zipfile <- as_tibble(list.files(path = here::here('Data_Usage/'))) %>%
                    filter(grepl(last_month, value))

months_zipfile <- months_zipfile[[1]]                    

unzip(paste0(here::here('Data_Usage/'), months_zipfile), 
      exdir = paste0(here::here('Data_Usage/'), str_sub(months_zipfile, 1, nchar(months_zipfile) - 4)))

# create 1 file of all raw data
nondel_nodedata <- list.files(path = paste0(here::here('Data_Usage/'), str_sub(months_zipfile, 1, nchar(months_zipfile) - 4)), pattern = "*node*") %>% 
  map_df(~read_csv(paste0(here::here('Data_Usage/'), str_sub(months_zipfile, 1, nchar(months_zipfile) - 4), '/',.), col_types = cols(deleted_on = col_datetime(),
                                                                                                                                      target_spam_status = col_double()))) %>%
  filter(target_type == "b'osf.node'" & target_is_deleted == FALSE & is.na(deleted_on)) %>%
  dplyr::select(-c(target_content_type_id, region, target_title, target_spam_status, target_is_supplementary_node)) %>%
  mutate(target_guid = str_sub(target_guid, 3, 7)) %>%
  mutate(target_root = str_sub(target_root, 3, 7))

write_csv(nondel_nodedata, path = paste0(here::here('Data_Usage/'),'nondel_nodedata.csv'))

rmarkdown::render(paste0(here::here('Data_Usage/'), 'monthly_usage_report.Rmd'), 'html_document')

osf_retrieve_node('https://osf.io/scbfy/') %>%
osf_upload(paste0(here::here('Data_Usage/'), 'monthly_usage_report.html'), conflict = 'overwrite')
