library(httr)

# set up doi providers and prefixes
doi_prefixes <- c(10.31219, 10.31235, 10.31234, 10.31222, 10.31220, 10.31228, 10.31224, 10.31231, 10.31229, 10.31225, 10.31233, 10.31236, 10.31237, 10.31230, 10.31227, 10.31232, 10.31223, 10.31221, 10.31226, 10.31730, 10.32942, 10.35542, 10.33767)
preprint_providers <- c('osf_preprints', 'socarxiv', 'psyarxiv', 'metaarxiv', 'agrixiv', 'lawarxiv', 'engrxiv', 'mindrxiv', 'lissa', 'focus_archive', 'paleorxiv', 
                        'sportrxiv', 'thesis_commons', 'marxiv', 'inarxiv', 'nutrixiv', 'eartharxiv', 'arabixiv', 'frenxiv', 'africarxiv', 'evoecorxiv', 'edarxiv', 'mediarxiv')



url_crossref <- 'https://api.eventdata.crossref.org/v1/events?obj-id.prefix='

psyarxiv <- GET(url = paste0(url_crossref, '10.31234', '&source=plaudit&from-collected-date=2019-11-04'))
output <- fromJSON(prettify(psyarxiv))$message$events


# total plaudits
nrow(output)

# number preprints with plaudits
nrow(output %>%
  group_by(obj_id) %>%
  tally())

# number of plauditors
nrow(output %>%
  group_by(subj_id) %>%
  tally())
