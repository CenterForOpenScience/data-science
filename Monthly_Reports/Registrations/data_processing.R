library(tidyverse)
library(lubridate)
library(osfr)
library(googlesheets4)
library(here)


## create monthly numbers for total registrations based on keen daily data
read_sheet('https://docs.google.com/spreadsheets/d/1ti6iEgjvr-hXyMT5NwCNfAg-PJaczrMUX9sr6Cj6_kM/', 
           col_types = '??ii') %>%
    select(keen.timestamp, registered_projects.total) %>%
    mutate(keen.timestamp = ymd_hms(keen.timestamp),
           year_month  = format(keen.timestamp, "%Y-%m")) %>%
    group_by(year_month) %>%
    filter(keen.timestamp == max(keen.timestamp)) %>%
    ungroup() %>%
    mutate(monthly_diff = registered_projects.total - lag(registered_projects.total)) %>%
    write_csv(here::here('Monthly_Reports/Registrations/', 'monthly_total_regs.csv'))
                    

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
write_csv(monthly_data, here::here('Monthly_Reports/Registrations/', 'form_type_monthly.csv'))

