# loading libraries
library(tidyverse)
library(lubridate)
remotes::install_github("ropensci/osfr") # using source b/c 'conflicts' bug fix hasn't made it to CRAN yet
library(osfr)
library(googlesheets4)
library(here)


# download monthly aggregates file to be appended
osf_retrieve_file("https://osf.io/semh8/") %>% 
  osf_download(path = here::here('Registrations/'), conflicts = "overwrite")

monthly_data <- read_csv(paste0(here::here('Registrations/'), 'form_type_monthly.csv'))

# create monthly numbers for total registrations based on keen daily data
read_sheet('https://docs.google.com/spreadsheets/d/1ti6iEgjvr-hXyMT5NwCNfAg-PJaczrMUX9sr6Cj6_kM/', 
           col_types = '??iiii') %>%
    select(keen.timestamp, registered_projects.total, registered_projects.withdrawn, registered_projects.embargoed_v2) %>%
    mutate(keen.timestamp = ymd_hms(keen.timestamp),
           year_month  = format(keen.timestamp, "%Y-%m")) %>%
    group_by(year_month) %>%
    filter(keen.timestamp == max(keen.timestamp)) %>%
    ungroup() %>%
    mutate(registered_projects.monthly_diff = registered_projects.total - lag(registered_projects.total),
           monthly_diff_withdraws = registered_projects.withdrawn - lag(registered_projects.withdrawn),
           monthly_diff_embargo = registered_projects.embargoed_v2 - lag(registered_projects.embargoed_v2)) %>%
    write_csv(path = here::here('Registrations/monthly_total_regs.csv'))
                    

# get yyyy-mm of previous month
last_month <- floor_date(Sys.Date() - months(1), "month") %>%
                  str_sub(1, 7)

# create file name to look for in osf project
file_name <- paste0('form_types_', last_month, '.csv')

# download that particular file to the directory 
osf_retrieve_node('https://osf.io/r83uz/') %>% 
  osf_ls_files() %>% 
  filter(name == 'Registries') %>% 
  osf_ls_files(n_max = 100) %>% 
  filter(name == file_name) %>%
  osf_download(path = here::here('Registrations/'))



last_month_data <- read_csv(paste0(here::here('Registrations/'), file_name)) %>%
                      mutate(year = year(event_date), 
                             month = month(event_date)) %>%
                      mutate(form_type = case_when(name == 'Prereg Challenge' | name == 'OSF Preregistration' ~ 'OSF Preregistration',
                                                   TRUE ~ name)) %>%
                      group_by(year, month, form_type) %>%
                      summarize(reg_events = sum(reg_events), retract_events = sum(retract_events), net_events = sum(net_events)) %>%
                      mutate(date = date(paste0(year, '-', month, '-01'))) %>%
                      rename(name = form_type)

monthly_data <- bind_rows(monthly_data, last_month_data)

# write out file and upload back to OSF project
write_csv(monthly_data, path = here::here('Registrations/form_type_monthly.csv'))

osf_retrieve_node('https://osf.io/r83uz/') %>% 
  osf_ls_files() %>% 
  filter(name == 'Registries') %>%
  osf_upload(path = here::here('Registrations/form_type_monthly.csv'), conflicts = "overwrite")

