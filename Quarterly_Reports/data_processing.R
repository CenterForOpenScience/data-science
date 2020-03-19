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


