#load libraries
library(tidyverse)
library(httr)
library(jsonlite)
library(googlesheets4)

# get keys
nodesummary_projectid <- Sys.getenv("nodesummary_projectid")
keen_read_key <- Sys.getenv("keen_read_key")

# query API for all node_summary variables we store
nodesummary_output <- GET(paste0('https://api.keen.io/3.0/projects/', 
                                 nodesummary_projectid, 
                                 '/queries/extraction?api_key=', 
                                 keen_read_key, 
                                 '&event_collection=node_summary&timeframe=this_7_days&property_names=keen.created_at&property_names=keen.timestamp&property_names=projects.public&property_names=registered_projects.total&property_names=registered_projects.withdrawn&property_names=registered_projects.embargoed_v2'))

# clean API result and get in same order as existing data
node_data <- fromJSON(prettify(nodesummary_output))$result %>%
                
                #handle nested dataframes in created from json output
                map_if(., is.data.frame, list) %>%
                as_tibble() %>%
                unnest() %>%
  
                #rename to match existing column names              
                rename(keen.timestamp = timestamp, 
                       keen.created_at = created_at, 
                       registered_projects.total = total, 
                       registered_projects.withdrawn = withdrawn, 
                       registered_projects.embargoed_v2 = embargoed_v2, 
                       projects.public = public) %>%             
                arrange(keen.created_at) %>%
  
                #handle if keen accidently ran more than once in a night
                group_by(keen.timestamp) %>%
                slice(1L) %>%
                ungroup() %>%
                
                #make sure column order correct
                select(keen.created_at, keen.timestamp, public, registered_projects.total, registered_projects.withdrawn, registered_projects.embargoed_v2)

