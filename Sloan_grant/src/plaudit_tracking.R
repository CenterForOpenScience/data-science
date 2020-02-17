library(httr)
library(jsonlite)
library(dplyr)
library(purrr)
library(ggplot2)
library(lubridate)

# set up doi providers and prefixes
doi_prefixes <- c('10.31219', '10.31235', '10.31234', '10.31222', '10.31220', '10.31228', '10.31224', '10.31231', '10.31229', 
                  '10.31225', '10.31233', '10.31236', '10.31237', '10.31230', '10.31227', '10.31232', '10.31223', '10.31221', 
                  '10.31226', '10.31730', '10.32942', '10.35542', '10.33767')
preprint_providers <- c('osf_preprints', 'socarxiv', 'psyarxiv', 'metaarxiv', 'agrixiv', 'lawarxiv', 'engrxiv', 'mindrxiv', 'lissa', 'focus_archive', 'paleorxiv', 
                        'sportrxiv', 'thesis_commons', 'marxiv', 'inarxiv', 'nutrixiv', 'eartharxiv', 'arabixiv', 'frenxiv', 'africarxiv', 'evoecorxiv', 'edarxiv', 'mediarxiv')

# set up all urls
urls <- paste0('https://api.eventdata.crossref.org/v1/events?obj-id.prefix=', doi_prefixes, '&source=plaudit&from-collected-date=2019-11-04')

# function to call and handle each API return
cleaning <- function(url){
  output <- GET(url)
  fromJSON(prettify(output))$message$events 
}

# apply function to each DOI prefix and save in a df
plaudits <- map_dfr(urls, ~ cleaning(.)) %>%
                select(obj_id, occurred_at, subj_id, id, action, source_id, timestamp, relation_type_id)
            

# total plaudits
nrow(plaudits)

### plaudits per preprint descriptives
plaudits_per_pp <- plaudits %>%
                      group_by(obj_id) %>%
                      tally()
# number pps with plaudits
nrow(plaudits_per_pp)

# basic distribution
ggplot(plaudits_per_pp, aes(n)) +
  geom_histogram(binwidth = 1)

### plaudits per user descriptives
plaudits_per_user <- plaudits %>%
                        group_by(subj_id) %>%
                        tally()

# number users with plaudits
nrow(plaudits_per_user)

# basic distribution
ggplot(plaudits_per_user , aes(n)) +
  geom_histogram(binwidth = 1)


### plaudits by month
plaudits %>% 
  mutate(timestamp = ymd_hms(timestamp)) %>%
  mutate(month = month(timestamp)) %>%
  group_by(month) %>%
  tally() %>%
  arrange(n)
