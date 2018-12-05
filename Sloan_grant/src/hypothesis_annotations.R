#hypothes.is API work

library(devtools)
install_github("mdlincoln/hypothesisr")
library(hypothesisr)
library(dplyr)
library(purrr)
library(stringr)

preprint_domains <- c('agrixiv', 'arabixiv', 'eartharxiv', 'ecsarxiv', 'engrxiv', 'frenxiv', 'marxiv', 'mindrxiv', 'osf', 'paleorxiv','psyarxiv', 'thesiscommons')
all_osf_annotations <- map_dfr(preprint_domains, ~hs_search_all(custom =  list(uri.parts = .)))

only_prod_annotations <- all_osf_annotations %>%
                            filter(!grepl('cos', uri), !grepl('staging',uri), !grepl('wiki', uri), !grepl('developer', uri), !grepl('github', uri), !grepl('mfr', uri), !grepl('files', uri)) %>%
                            mutate(guid = case_when(str_detect(str_sub(uri, -1), "/") ~ str_sub(uri, -6, -2),
                                                    str_detect(str_sub(uri, -1), "/") == FALSE ~ str_sub(uri, -5, -1))) %>%
                            select(updated, text, created, uri, guid, user, id, links.json, links.html, links.incontext, document.title)

View(all_osf_annotations)
View(only_prod_annotations)

