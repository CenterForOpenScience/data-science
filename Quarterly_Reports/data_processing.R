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

# get monthly data for all product types for all months (so add in 0s)

date <- as_tibble(seq(as.Date('2012-09-01'), floor_date(as.Date(Sys.time()), 'month'), by = 'month')) %>%
          rename(date = value) %>%
          mutate(date = as_datetime(date),
                 date = floor_date(date, 'month'),
                 placeholder = 1)
        
products <- as_tibble(c('osf4m', 'preprints', 'registries', 'osf')) %>%
              rename(product_type = value) %>%
              mutate(placeholder = 1)

full_hist_cat_date <- full_join(date, products, by = 'placeholder') %>%
                          left_join(hist_cat_data, by = c("date" = "month", 'product_type' = 'product_type')) %>%
                          select(-placeholder) %>%
                          replace(., is.na(.), 0) %>%
                          group_by(product_type) %>%
                          mutate(cum_new_signups = cumsum(new_signups),  #create columns for running totals
                                 cum_new_claims = cumsum(new_claims),
                                 cum_new_sources = cumsum(new_sources),
                                 cum_sso_newsignups = cumsum(sso_newsignups),
                                 cum_sso_newclaims = cumsum(sso_newclaims))


