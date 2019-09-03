library(rmarkdown)
library(osfr)

osf_retrieve_file('https://osf.io/a7w36/') %>%
  osf_download(path = '/Users/courtneysoderberg/Documents/data-science/Monthly_Reports/Data_Usage/osf_storage_metrics.csv', overwrite = T)

rmarkdown::render("/Users/courtneysoderberg/Documents/data-science/Monthly_Reports/Data_Usage/monthly_usage_report.Rmd", 'html_document')

osf_retrieve_node('https://osf.io/scbfy/') %>%
osf_upload("/Users/courtneysoderberg/Documents/data-science/Monthly_Reports/Data_Usage/monthly_usage_report.html", overwrite = T)