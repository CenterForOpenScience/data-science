#load libraries
library(tidyverse)
library(httr)
library(jsonlite)
library(googlesheets4)
library(googledrive)


# force authentication with googledrive first
drive_auth()
sheets_auth(token = drive_token())

# get keys
keen_projectid <- Sys.getenv("production_osfprivate_projectid")
keen_read_key <- Sys.getenv("keen_read_key")

# query API for all node_summary variables we store
nodesummary_output <- GET(paste0('https://api.keen.io/3.0/projects/', 
                                 keen_projectid, 
                                 '/queries/extraction?api_key=', 
                                 keen_read_key, 
                                 '&event_collection=node_summary&timeframe=previous_1_month&property_names=keen.created_at&property_names=keen.timestamp&property_names=projects.public&property_names=registered_projects.total&property_names=registered_projects.withdrawn&property_names=registered_projects.embargoed_v2'))

# query API for files variables we store
filesummary_output <- GET(paste0('https://api.keen.io/3.0/projects/', 
                                 keen_projectid, 
                                 '/queries/extraction?api_key=', 
                                 keen_read_key, 
                                 '&event_collection=file_summary&timeframe=previous_1_week&property_names=keen.created_at&property_names=keen.timestamp&property_names=osfstorage_files_including_quickfiles.public&property_names=osfstorage_files_including_quickfiles.total'))


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
                select(keen.created_at, keen.timestamp, projects.public, registered_projects.total, registered_projects.withdrawn, registered_projects.embargoed_v2)

# clean files data
file_data <- fromJSON(prettify(filesummary_output))$result %>%
  
  #handle nested dataframes in created from json output
  map_if(., is.data.frame, list) %>%
  as_tibble() %>%
  unnest() %>%
  
  #rename to match existing column names              
  rename(keen.timestamp = timestamp, 
         keen.created_at = created_at, 
         osfstorage_files_including_quickfiles.total = total, 
         osfstorage_files_including_quickfiles.public = public) %>%             
  arrange(keen.created_at) %>%
  
  #handle if keen accidently ran more than once in a night
  group_by(keen.timestamp) %>%
  slice(1L) %>%
  ungroup() %>%
  
  #make sure column order correct
  select(keen.timestamp, keen.created_at, osfstorage_files_including_quickfiles.public, osfstorage_files_including_quickfiles.total)

##read in existing data & add newer data 
nodes_gdrive_file <- 'https://docs.google.com/spreadsheets/d/1ti6iEgjvr-hXyMT5NwCNfAg-PJaczrMUX9sr6Cj6_kM/'
files_grdrive_file <- 'https://docs.google.com/spreadsheets/d/1gOodKyhEhegXd0sTnc0IURq282wMgZgwAgoZS8brVUQ/'

read_sheet(nodes_gdrive_file) %>%
  rbind(node_data) %>%
  write_csv('node_data.csv')

read_sheet(files_grdrive_file) %>%
  rbind(file_data) %>%
  write_csv('files_data.csv')

## update googlesheet with new appended date (switch to more targetted update once googlesheets4 has write capabilities)
drive_update(file = nodes_gdrive_file, media = 'node_data.csv')
drive_update(file = files_grdrive_file, media = 'files_data.csvs')

