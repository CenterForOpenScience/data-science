library(tidyverse)
library(lubridate)
library(osfr)

last_month <- floor_date(Sys.Date() - months(1), "month") %>%
                  str_sub(1, 7)


file_name <- paste0('form_types_', last_month, '.csv')

osf_retrieve_file("https://osf.io/semh8/") %>% 
  osf_download(overwrite = T)


osf_retrieve_node('https://osf.io/r83uz/') %>% 
  osf_ls_files() %>% 
  filter(name == 'Registries') %>% 
  osf_ls_files() %>% 
  filter(name == file_name) %>%
  osf_download(overwrite = T)

monthly_data <- read_csv('form_type_monthly.csv')

last_month_data <- read_csv(file_name) %>%
                      mutate(year = year(event_date), 
                             month = month(event_date)) %>%
                      mutate(form_type = case_when(name == 'Prereg Challenge' | name == 'OSF Preregistration' ~ 'OSF Preregistration',
                                                   TRUE ~ name)) %>%
                      group_by(year, month, form_type) %>%
                      summarize(reg_events = sum(reg_events), retract_events = sum(retract_events), net_events = sum(net_events)) %>%
                      mutate(date = date(paste0(year, '-', month, '-01')))

monthly_data <- rbind(monthly_data, last_month_data)
write_csv(monthly_data, 'form_type_monthly.csv')

osf_upload()

