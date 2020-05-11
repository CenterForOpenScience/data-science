library(rmarkdown)
library(osfr)
library(lubridate)
library(tidyverse)



# get pre-aggregated datafile
osf_retrieve_file('https://osf.io/a7w36/') %>%
  osf_download(path = '/Users/courtneysoderberg/Documents/data-science/Monthly_Reports/Data_Usage/osf_storage_metrics.csv', overwrite = T)

# get raw data zip file for this month and unzip into a folder
last_month <- date(floor_date(Sys.time() - months(1), unit = 'month'))

osf_retrieve_node('https://osf.io/r83uz/') %>% 
  osf_ls_files('Data Storage Usage', pattern = as.character(last_month)) %>%
  osf_download(path = '/Users/courtneysoderberg/Documents/data-science/Monthly_Reports/Data_Usage/raw_data.zip', overwrite = T)

unzip('/Users/courtneysoderberg/Documents/data-science/Monthly_Reports/Data_Usage/raw_data.zip', 
      exdir = '/Users/courtneysoderberg/Documents/data-science/Monthly_Reports/Data_Usage/raw_data')

# create 1 file of all raw data
all_raw_nodedata <- list.files(path = '/Users/courtneysoderberg/Documents/data-science/Monthly_Reports/Data_Usage/raw_data', pattern = "*node*") %>% 
  map_df(~read_csv(paste0('/Users/courtneysoderberg/Documents/data-science/Monthly_Reports/Data_Usage/raw_data/',.), col_types = cols(deleted_on = col_datetime(),
                                                                                                                                      target_spam_status = col_double()))) %>%
  filter(target_type == "b'osf.node'" & target_is_deleted == FALSE & is.na(deleted_on)) %>%
  select(-c(target_content_type_id, region, target_title, target_spam_status, target_is_supplementary_node))

write_csv(all_raw_nodedata, 'all_raw_nodedata.csv')

rmarkdown::render("/Users/courtneysoderberg/Documents/data-science/Monthly_Reports/Data_Usage/monthly_usage_report.Rmd", 'html_document')

osf_retrieve_node('https://osf.io/scbfy/') %>%
osf_upload("/Users/courtneysoderberg/Documents/data-science/Monthly_Reports/Data_Usage/monthly_usage_report.html", overwrite = T)