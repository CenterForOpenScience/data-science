# load libraries
library(osfr)
library(rmarkdown)

# run dashboard
rmarkdown::render(paste0(here::here('product_downloads/'), 'downloads_by_product.Rmd'))

# upload resulting dashboard to osf project
osf_retrieve_node('https://osf.io/34wp6/') %>%
  osf_upload(paste0(here::here('product_downloads/'), 'downloads_by_product.html'), conflict = 'overwrite')
