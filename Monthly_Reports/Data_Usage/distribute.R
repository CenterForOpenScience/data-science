library(rmarkdown)
library(here)
library(osfr)

osf_retrieve_file('https://osf.io/a7w36/') %>%
  osf_download(overwrite = T)

rmarkdown::render(here::here("/Monthly_Reports/Data_Usage","monthly_usage_report.Rmd"))

osf_retrieve_node('https://osf.io/scbfy/') %>%
osf_upload(here::here("/Monthly_Reports/Data_Usage","monthly_usage_report.html"))