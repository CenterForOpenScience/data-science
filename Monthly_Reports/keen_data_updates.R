#load libraries
library(tidyverse)
library(httr)
library(jsonlite)
library(googlesheets4)

# get keys
keen_projectid <- Sys.getenv("production_osfprivate_projectid")
keen_read_key <- Sys.getenv("keen_read_key")

# function to create keen calls
keen_extraction_call <- function(event_collection, timeframe, variable_list){
  variables <- str_c(variable_list, collapse = '&property_names=')
  
  output <- GET(paste0('https://api.keen.io/3.0/projects/', 
                       keen_projectid, 
                       '/queries/extraction?api_key=', 
                       keen_read_key,
                       '&event_collection=',
                       event_collection,
                       '&timeframe=',
                       timeframe,
                       '&property_names=',
                       variables))
  return(output)
}

# function to clean API response calls
clean_api_response <- function(api_output){
  
  cleaned_result <- fromJSON(prettify(api_output))$result %>%
    
    #handle nested dataframes in created from json output
    map_if(., is.data.frame, list) %>%
    as_tibble() %>%
    unnest() %>%
    
    #handle if keen accidently ran more than once in a night
    arrange(created_at) %>%
    group_by(timestamp) %>%
    slice(1L) %>%
    ungroup()
  return(cleaned_result)
}


### Make and store api calls
nodesummary_output <- keen_extraction_call('node_summary', 'previous_1_months', variable_list = c('keen.created_at', 'keen.timestamp', 'projects.public', 'registered_projects.total', 'registered_projects.withdrawn', 'registered_projects.embargoed_v2'))
filesummary_output <- keen_extraction_call('file_summary', 'previous_1_month', variable_list = c('keen.created_at', 'keen.timestamp', 'osfstorage_files_including_quickfiles.public', 'osfstorage_files_including_quickfiles.total'))
usersummary_output <- keen_extraction_call('user_summary', 'previous_1_months', variable_list = c('keen.created_at', 'keen.timestamp', 'status.active'))
download_output <- keen_extraction_call('download_count_summary', 'previous_1_months', variable_list = c('keen.created_at', 'keen.timestamp', 'files.total'))
preprint_output <- keen_extraction_call('preprint_summary', 'previous_1_months', variable_list = c('keen.created_at', 'keen.timestamp', 'provider.name', 'provider.total'))

### clean API results and make sure new df names and order match existing gsheets

node_data <- clean_api_response(nodesummary_output) %>%

                #rename to match existing column names              
                rename(keen.timestamp = timestamp, 
                       keen.created_at = created_at, 
                       registered_projects.total = total, 
                       registered_projects.withdrawn = withdrawn, 
                       registered_projects.embargoed_v2 = embargoed_v2, 
                       projects.public = public) %>%             
  
                #make sure column order correct
                select(keen.created_at, keen.timestamp, projects.public, registered_projects.total, registered_projects.withdrawn, registered_projects.embargoed_v2)

file_data <- clean_api_response(filesummary_output) %>%

                #rename to match existing column names              
                rename(keen.timestamp = timestamp, 
                       keen.created_at = created_at, 
                       osfstorage_files_including_quickfiles.total = total, 
                       osfstorage_files_including_quickfiles.public = public) %>%             
               
                #make sure column order correct
                select(keen.timestamp, keen.created_at, osfstorage_files_including_quickfiles.public, osfstorage_files_including_quickfiles.total)

user_data <- clean_api_response(usersummary_output) %>%
  
                      #rename to match existing column names              
                      rename(keen.timestamp = timestamp, 
                             keen.created_at = created_at, 
                             status.active = active) %>%
                      
                      #make sure column order correct
                      select(keen.created_at, keen.timestamp, status.active)

download_data <- clean_api_response(download_output) %>%
  
                    
                    #rename to match existing column names              
                    rename(keen.timestamp = timestamp, 
                           keen.created_at = created_at, 
                           files.total = total) %>%
                    
                    #make sure column order correct
                    select(keen.timestamp, keen.created_at, files.total)

# can't use function for preprint data b/c need to handling groupings differently
preprint_data <- fromJSON(prettify(preprint_output))$result %>%

                    #handle nested dataframes in created from json output
                    map_if(., is.data.frame, list) %>%
                    as_tibble() %>%
                    unnest() %>%
                    
                    #handle if keen accidently ran more than once in a night
                    arrange(created_at) %>%
                    group_by(timestamp, name) %>%
                    slice(1L) %>%
                    ungroup() %>%
                    
                    #rename to match existing column names              
                    rename(keen.timestamp = timestamp, 
                           keen.created_at = created_at, 
                           provider.name = name,
                           provider.total = total) %>%
                    
                    #make sure column order correct
                    select(keen.created_at, keen.timestamp, provider.name, provider.total)

##existing sheet IDs
nodes_gdrive_file <- 'https://docs.google.com/spreadsheets/d/1ti6iEgjvr-hXyMT5NwCNfAg-PJaczrMUX9sr6Cj6_kM/'
files_grdrive_file <- 'https://docs.google.com/spreadsheets/d/1gOodKyhEhegXd0sTnc0IURq282wMgZgwAgoZS8brVUQ/'
user_gdrive_file <- 'https://docs.google.com/spreadsheets/d/1qEhmANiAIcdavuugUNPKqVjijxvlihA99vIU9KuBhww/'
download_gdrive_file <- 'https://docs.google.com/spreadsheets/d/1vs-yRamfmBo_dYs0LsTJ4JZoefPwArQvgA4N4YuTZ8w/'
preprint_gdrive_file <- 'https://docs.google.com/spreadsheets/d/14K6dlo0G5-PA0W14d2DDg4ZHK8cG40JQ8XybQ9yWQYY/'

## append new data to googlesheet
sheets_append(node_data, ss = nodes_gdrive_file)
sheets_append(file_data, ss = files_grdrive_file)
sheets_append(user_data, ss = user_gdrive_file)
sheets_append(download_data, ss = download_gdrive_file)
sheets_append(preprint_data, ss = preprint_gdrive_file)


## calculating monthly numbers

#calculate start and end of needed range
end_2_month <- floor_date(now('utc'), 'day') - months(1) - days(1)
end_last_month <- floor_date(now('utc'), 'day') - days(1)

# set up function to return only needed rows for each sheet
startend_dates <- function(gsheet) {
                    
                    #retain only needed rows for calculations  
                    startend_sheet <- read_sheet(gsheet) %>%
                        mutate(keen.timestamp = ymd_hms(keen.timestamp)) %>%
                        filter(keen.timestamp == end_last_month | keen.timestamp == end_2_month) 
                      
                    # return resulting sheet
                    return(startend_sheet)
}

nodes_startend <- startend_dates(nodes_gdrive_file)
files_startend <- startend_dates(files_grdrive_file)
users_startend <- startend_dates(user_gdrive_file)

# additional process for pps to collapse across providers
preprints_startend <- startend_dates(preprint_gdrive_file) %>%
                        group_by(keen.timestamp) %>%
                        summarize(total_pps = sum(provider.total))

# downloads are a sum rather than a difference
read_sheet(download_gdrive_file, col_types = '??i') %>%
  filter(keen.timestamp >= floor_date(now('utc'), 'day') - months(1)) %>%
  summarize(total = sum(files.total))



#calculate monthly values
nodes_startend[2, 'projects.public'] - nodes_startend[1, 'projects.public']
nodes_startend[2, 'registered_projects.total'] - nodes_startend[1, 'registered_projects.total']

files_startend[2, 'osfstorage_files_including_quickfiles.public'] - files_startend[1, 'osfstorage_files_including_quickfiles.public']
files_startend[2, 'osfstorage_files_including_quickfiles.total'] - files_startend[1, 'osfstorage_files_including_quickfiles.total']

users_startend[2, 'status.active'] - users_startend[1, 'status.active']

preprints_startend[2, 'total_pps'] - preprints_startend[1, 'total_pps']             
