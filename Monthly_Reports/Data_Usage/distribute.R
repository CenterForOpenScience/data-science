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

rmarkdown::render("/Users/courtneysoderberg/Documents/data-science/Monthly_Reports/Data_Usage/monthly_usage_report.Rmd", 'html_document')

osf_retrieve_node('https://osf.io/scbfy/') %>%
osf_upload("/Users/courtneysoderberg/Documents/data-science/Monthly_Reports/Data_Usage/monthly_usage_report.html", overwrite = T)