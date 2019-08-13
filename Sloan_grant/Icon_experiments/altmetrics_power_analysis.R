library(tidyverse)
library(here)
library(lubridate)


## read in altmetrics data from May 2019
altmetrics_data <- list.files(path = here::here('Documents/data-science/Sloan_grant'), 
                              pattern = "altmetrics_count_info_2019-05-*",
                              full.names = T)
  
names(altmetrics_data) <-   list.files(path = here::here('Documents/data-science/Sloan_grant'), 
                                       pattern = "altmetrics_count_info_2019-05-*",
                                       full.names = T) %>%
                            gsub(pattern = '/Users/courtneysoderberg/Documents/data-science/Sloan_grant/altmetrics_count_info_', replacement= "")

data <- map_df(altmetrics_data, read_csv, col_types = cols(doi = col_character(),
              .default = col_double()), .id = 'date') %>%
        separate(doi, sep = "/", into=c('doi_prefix', 'osf', 'guid')) %>%
        mutate(date = ymd(str_replace(date, ".csv", "")))


# read in all preprints published in may
may_preprints <- read_csv(here::here('Documents/data-science/Sloan_grant/Icon_experiments', 'may_preprints.csv'))

# join together to retain only altemtric info about may preprints
may_data <- left_join(may_preprints, data , by = 'guid')
            

