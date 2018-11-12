#loading libraries
library(httr)
library(purrr)

staging_url_osf <- 'https://api.staging.osf.io/v2/'

process_json <- function(x) {
  rjson::fromJSON(httr::content(x, 'text', encoding = "UTF-8"))
}

###loop through 100 pages of node results to create list of 1000 nodes
get_node_info <- function(base_url){
  call <- GET(url = paste0(base_url, 'nodes/'))
  res <- process_json(call)
  process_pagination <- function(res) {
    # Create variable to hold original page
    combined_list <- res$data
    # Use the first page of the returned data to get the next page link
    next_page_link <- res$links$`next`
    pages <- 0
    # While next page link is not null, run loop
    while(!is.null(next_page_link) & pages < 99) {
      # Call down the next page
      new_page <- process_json(httr::GET(next_page_link))
      # Save new page next page link to the next page variable
      next_page_link <- new_page$links$`next`
      # Combine current pages and new page
      combined_list <- c(combined_list, new_page$data)
      pages <- pages + 1
      print(pages)
    }
    # Return combined data
    return(combined_list)
  }
  
  nodes <- process_pagination(res)
  data <- as.data.frame(cbind(map_chr(nodes, "id"), nodes %>% map_chr(c(3, 7))))
  if (is.null(res)) {
    return(NULL)
  }
  return(data)
}

node_guids <- get_node_info(staging_url_osf)



##creating API link calls for each [subset right now for testing]
all_links <- map_chr(node_guids[1:50, 1], ~paste0(staging_url_osf, 'nodes/', ., '/files/osfstorage/?filter[kind]=file'))
                  
test_call <- map(all_links, ~GET(url = .))  
processes_call <- map(test_call, ~ process_json(.)$data)  ##keep only data section output

test_tibble <- processes_call %>% 
  set_names(node_names) %>% 
  enframe("node_ids", "processes_call") %>% 
  mutate(n_files = map_int(processes_call, length)) %>% 
  filter(n_files > 0) %>%
  mutate(file_names = processes_call %>% map(. %>% map(c(3, 12))))

narrowed <- test_tibble %>% 
  select(-processes_call) %>% 
  tidyr::unnest() %>% 
  drop_na(file_names) %>%
  mutate(file_guids = map_chr(narrowed$file_names, unlist)) %>%
  select(-n_files, -file_names)

  
  
  map(test_tibble[, 4], unlist)
