# loading libraries
library(osfr)
library(here)
library(tidyverse)

#### update historic data with new quarter ####

# download historic data
osf_retrieve_file() %>%
  osf_download()

# read in quarterly & historic data
qrt_data <- read_csv()
hist_data <- read_csv()

# append new quarterly data to historic data
hist_data <- bind_rows(hist_data, qrt_data)

# write & re-upload historic data
write_csv(hist_data, "")

osf_upload()

#### calculate summary variables for report ####

# get monthly numbers by product type
hist_cat_data <- hist_data %>%
                    mutate(product_type = case_when(grepl('preprints', name) ~ 'preprints',
                                                    grepl('osf4m', name) ~ 'osf4m',
                                                    grepl('campaign', name) | grepl('regist', name) ~ 'registries',
                                                    TRUE ~ 'osf')) %>%
                    group_by(product_type, month) %>%
                    summarize(new_signups = sum(new_signups), new_claims = sum(new_claims), new_sources = sum(new_sources), 
                              sso_newsignups = sum(sso_newsignups), sso_newclaims = sum(sso_newclaims))

