# loading libraries
remotes::install_github("ropensci/osfr") # using source b/c 'conflicts' bug fix hasn't made it to CRAN yet
library(osfr)
library(here)
library(tidyverse)
library(lubridate)

#### update historic data with new quarter ####

# download historic data
osf_retrieve_file('https://osf.io/32gdc/') %>%
  osf_download(path = here::here('user_generation/'), conflicts = "overwrite")

osf_retrieve_file('https://osf.io/czs7g/') %>%
  osf_download(path = here::here('user_generation/'), conflicts = "overwrite")

# read in quarterly & historic data files
qrt_data <- read_csv(here::here('user_generation/quarterly_user_generation_nums.csv'))
fine_grained_hist_data <- read_csv(here::here('user_generation/user_generation_sources.csv'))
agg_hist_date <- read_csv(here::here('user_generation/full_hist_cat_date.csv'))

# append new quarterly data to historic data

# determine change in invitee numbers between quarters
invitee_change <- fine_grained_hist_data %>%
  select(new_invitees, product, month) %>%
  filter(month == floor_date(Sys.Date() - months(4), 'months')) %>%
  left_join(qrt_data %>%
              select(new_invitees, product, month) %>%
              filter(month == floor_date(Sys.Date() - months(1), 'months')), by = 'product') %>%
  mutate(invitee_diff = new_invitees.y - new_invitees.x) %>%
  rename(month = 'month.y') %>%
  select(product, month, invitee_diff)

# append all of last quarters data to fine-grained running data
fine_grained_hist_data <- rbind(fine_grained_hist_data, qrt_data) %>%
                            left_join(invitee_change, by = c('month', 'product')) %>%
                            
                            # update new invitee numbers to reflect those that happened in that quarter
                            mutate(new_invitees = case_when(!is.na(invitee_diff) ~ invitee_diff,
                                                            is.na(invitee_diff) ~ new_invitees)) %>%
                            select(-invitee_diff)

# write & re-upload fine-grained historic data
write_csv(fine_grained_hist_data, here::here('user_generation/user_generation_sources.csv'))

osf_retrieve_node('https://osf.io/5hw9s/') %>% 
  osf_ls_files() %>% 
  filter(name == 'User Generation') %>%
  osf_upload(path = here::here('user_generation/user_generation_sources.csv'), conflicts = "overwrite")

#### calculate summary variables for report ####

# get monthly numbers by product type for last quarter
qrt_full_hist_cat_date <- fine_grained_hist_data %>%
                            filter(month >= floor_date(Sys.Date() - months(3), 'months')) %>%
                            mutate(product_type = case_when(grepl('preprint', product) ~ 'preprints',
                                                            grepl('osf4m', product) ~ 'osf4m',
                                                            grepl('campaign', product) | grepl('regist', product) ~ 'registries',
                                                            grepl('osf', product) ~ 'osf')) %>%
                            group_by(product_type, month) %>%
                            summarize(new_signups = sum(new_signups), new_claims = sum(new_claims), new_invitees = sum(new_invitees), 
                                      sso_newsignups = sum(sso_newsignups), sso_newclaims = sum(sso_newclaims)) %>%
                            ungroup() %>%
                            arrange(month)

# append last quarter to running summarized dataset, save and upload
agg_hist_date <- rbind(agg_hist_date, qrt_full_hist_cat_date)

write_csv(agg_hist_date, here::here('user_generation/full_hist_cat_date.csv'))

osf_retrieve_node('https://osf.io/5hw9s/') %>% 
  osf_ls_files() %>% 
  filter(name == 'User Generation') %>%
  osf_upload(path = here::here('user_generation/full_hist_cat_date.csv'), conflicts = "overwrite")

#### run quarterly report & upload to OSF ####

# run the flexdashboard
rmarkdown::render(paste0(here::here('user_generation/'), 'user_generation.Rmd'))

osf_retrieve_node('https://osf.io/34wp6/') %>% 
  osf_upload(path = here::here('user_generation/user_generation.html'), conflicts = "overwrite")
