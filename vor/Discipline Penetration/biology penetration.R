## required libraries
library(tidyverse)
library(lubridate)
library(ggplot2)
library(osfr)
library(here)


## importing data
node_wiki_data  <- osf_retrieve_file('https://osf.io/sk53t/') %>% osf_download(overwrite = T)
node_wiki_data <- read_csv(here('nodes_and_wiki.csv'))

file_data <- osf_retrieve_file('https://osf.io/zvpcq/') %>% osf_download(overwrite = T)
file_data <- read_csv(here('nodes_files_filetags.csv'), col_types = list(tag_name = col_character(),
                                                                   tag_created = col_datetime()))

node_contributors <- osf_retrieve_file('https://osf.io/32vqg/') %>% osf_download(overwrite = T) 
node_contributors <- read_csv(file = here('node_contributors.csv'))

node_tags <- osf_retrieve_file('https://osf.io/x9ctu/') %>% osf_download(overwrite = T)
node_tags <- read_csv(file = here('nodes_tags.csv'))


## setting up word match patterns
file_pattern <- c('\\.gz$', '\\.sds$', '\\.czi$', '\\.pzf$', '\\.fcs$', '\\.pzfx$', '\\.mol$', '\\.rxn$', '\\.sdf$', '\\.rgf$', '\\.lmd$',
                  '\\.sraw$', '\\.cfl$', '\\.fastq.gz$', '\\.rnai.gct$', '\\.igv$', ' \\.bam.list$', '\\.mrxs$', '\\.wsp$', '\\.jo$',
                  '\\.yep$', '\\.baf$', '\\.fid$', '\\.tdf$', '\\.wiff$', '\\.lcd$', '\\.mrc$', '\\.sff$', '\\.fastq.gz$', '\\.qual$',
                  '\\.ab1$', '\\.abi$', '\\.abd$', '\\.alx$', '\\.mseq$', '\\.embl$', '\\.fasta$', '\\.fas$', '\\.fap$', '\\.nt$', '\\.aa$', 
                  '\\.fna$', '\\.fap$', '\\.frn$', '\\.faa$', '\\.mfa$', '\\.seq$', '\\.gcg$', '\\.pro$', '\\.pep$', '\\.gbk$', '\\.gp$',
                  '\\.genbank$', '\\.genpept$', '\\.gnv$', '\\.meg$', '\\.msa$', '\\.cif$', '\\.novafold$', '\\.antibody$', '\\.novadock$', 
                  '\\.phd$', '\\.pcr$', '\\.structure$', '\\.pad$', '\\.pdb$', '\\.ent$', '\\.pdb.gz$', '\\.ent.gz$', '\\.ct$', '\\.scf$',
                  '\\.sbd$', '\\.sqd$', '\\.star$', '\\.starff$', '\\.spf$', '\\.dna$', '\\.prot$', '\\.ndt$', '\\.lif$', '\\.gel$', '\\.dcm$',
                  '\\.rdml$', '\\.mzxml$')

word_pattern <- c('\\<biol', '\\<onco', '\\<PCR\\>', '\\<lipid', '\\<protein', '\\<proteo', 'omnic\\>', 'omnics\\>', '\\<genom', 'eome\\>', 
                  'eomes\\>', '\\<RNA\\>', 'RNA\\>','\\<RNA', '\\<DNA\\>', '\\<cellu', '\\<biomed', '\\<nucelo', '\\<immuno', '\\<metab', '\\<microb', 
                  '([^social ]|[^cognitive ]|\\<)neuro([^ticism]|\\>)', '\\<biochem', '\\<molec', '\\<pharma', '\\<CRISPR\\>', '\\<chemi', '\\<enzy', '\\<histol',
                  '\\<embryo', '\\<gene\\>', '\\<patho', '\\<virus\\>', '\\<viro', '\\<bioinf', '\\<lipo', '\\<cancer\\>', 'plasma\\>', 'scopy\\>',
                  '\\<antibod', '\\<cyto', '\\<plasma', '\\<xeno([^phobia]|\\>)', '\\<fluor', '\\<spect[^rum disorder]', 'PCR\\>', '\\<transfect', '\\<drosophilia\\>')

### running regex on to classify files and projects

# categorizing files by endings, titles, or tags
processed_file_data <- file_data %>%
                          mutate(file_ending = grepl(paste(file_pattern, collapse="|"),file_name)) %>%
                          mutate(file_tags = grepl(paste(word_pattern, collapse="|"), tag_name, ignore.case = T)) %>%
                          mutate(file_name_match = grepl(paste(word_pattern, collapse="|"), file_name, ignore.case = T)) %>%
                          mutate(file_biology = case_when(file_ending == TRUE | file_tags == TRUE | file_name_match == TRUE ~ 1,
                                                          TRUE ~ 0))

# categorizing node tags
processed_nodetag_data <- node_tags %>%
                              mutate(node_tag = grepl(paste(word_pattern, collapse="|"), tag_name, ignore.case = T))

# categorizing nodes based on title, description, and wiki text
processed_node_data <- node_wiki_data %>%
  mutate(node_title = grepl(paste(word_pattern, collapse="|"), title, ignore.case = T)) %>%
  mutate(node_description = grepl(paste(word_pattern, collapse="|"), description, ignore.case = T)) %>%
  mutate(node_wikiname = grepl(paste(word_pattern, collapse="|"), wiki_name, ignore.case = T)) %>%
  mutate(node_wiki = grepl(paste(word_pattern, collapse="|"), wiki_content, ignore.case = T)) %>%
  mutate(bio_node = case_when(node_title == TRUE | node_description == TRUE | node_wikiname == TRUE | node_wiki == TRUE ~ 1,
                              TRUE ~ 0))


### summarize categorizations above to get categorizations of each node based on all criterion above (files, tags, nodes)

# categorize nodes as bio vs. not based on files
node_file_summary <- processed_file_data %>%
                            group_by(node_id) %>%
                            summarize(bio_files = max(file_biology)) %>%
                            rename(id = node_id)

# cateogize nodes as bio vs. not based on node tags
nodetag_data_summary <- processed_nodetag_data %>%
                            group_by(id) %>%
                            mutate(bio_tag = as.numeric(node_tag)) %>%
                            summarize(bio_tags = max(bio_tag))

# categorize nodes based on node title, description, or wiki (excluding RPP and CREP projects/forks)
node_data_summary <- processed_node_data %>%
                            filter(root_id != 541633 & root_id != 64976 & root_id != 126168 & root_id !=192585 & root_id !=228500 & root_id !=229590 & root_id !=570 & root_id !=64976
                                   & root_id !=126168 & root_id !=221562 & root_id !=187895 & root_id !=195640 & root_id !=212812 & root_id !=218657 & root_id !=129077 & root_id !=147792 & root_id !=236557
                                   & root_id !=192585 & root_id !=248043 & root_id !=237511 & root_id !=2949 & root_id !=24165 & root_id !=45555 & root_id !=67254 & root_id !=90826 & root_id !=133902
                                   & root_id !=135313 & root_id !=135540 & root_id !=141112 & root_id !=143672 & root_id !=150361 & root_id !=163122 & root_id !=203408 & root_id !=228976
                                   & root_id !=261444 & root_id !=275220 & root_id !=275229 & root_id !=302404 & root_id !=302420 & root_id !=453499 & root_id !=454117 & root_id !=31527 & root_id !=236061 & root_id !=261453
                                   & root_id !=500116 & root_id !=241405 & root_id !=248762 & root_id !=236026 & root_id !=248918 & root_id !=604192 & root_id !=266606 & root_id !=660482 & root_id !=660899
                                   & root_id !=279048 & root_id !=58058 & root_id !=758622 & root_id !=275331 & root_id !=146174 & root_id !=500320 & root_id !=678172 & root_id !=29020 & root_id !=192684
                                   & root_id !=184974 & root_id !=52555) %>%
                            group_by(id, root_id, is_deleted, is_public, node_created, node_modified, type) %>%
                            summarize(biology_node = max(bio_node))

# categorization based on all factors above
overall_categorization <- left_join(node_data_summary, nodetag_data_summary, by = 'id') %>%
                              left_join(node_file_summary, by = 'id') %>%
                              mutate(biology_categorization = case_when(biology_node == 1 | bio_tags == 1 | bio_files == 1 ~ 1,
                                                                        TRUE ~ 0))


#### Numbers to report:

# number of non-deleted, not on spam nodes files (excluding folders, includes osfstorage files and add-on files that have been touched by the API)
number_bio_files <- processed_file_data %>%
                          filter(is.na(deleted_on)) %>%
                          filter(!grepl('folder', file_type)) %>%
                          filter(file_tags == TRUE | file_ending == TRUE | file_name_match == TRUE) %>%
                          distinct(file_id) %>%
                          nrow()

# percentage of total files
total_files <- processed_file_data %>%
                    filter(is.na(deleted_on)) %>%
                    filter(!grepl('folder', file_type)) %>%
                    distinct(file_id) %>%
                    nrow()

number_bio_files
round((number_bio_files/total_files)*100,2)

# number of non-deleted, non-spam top level projects that have at least 1 node categorized as biology (even if that particular node was deleted but the toplevel project still exists)
number_bio_projects <- overall_categorization %>%
                          filter(type == 'osf.node') %>%
                          group_by(root_id) %>%
                          summarize(bio_categorization = max(biology_categorization)) %>%
                          left_join(node_data_summary, by = c('root_id' = 'id')) %>%
                          filter(is_deleted == FALSE & bio_categorization == 1) %>%
                          nrow()

# number of top-level, non-deleted projects
total_projects <- processed_node_data %>%
                      filter(type == 'osf.node') %>%
                      filter(is_deleted == FALSE) %>%
                      distinct(root_id) %>%
                      nrow()

number_bio_projects
round((number_bio_projects/total_projects)*100, 2)


# number of non-deleted, non-spam top level registrations that have at least 1 node categorized as biology (even if that particular node was deleted but the toplevel project still exists)
number_bio_registrations <- overall_categorization %>%
                                filter(type == 'osf.registration') %>%
                                group_by(root_id) %>%
                                summarize(bio_categorization = max(biology_categorization)) %>%
                                left_join(node_data_summary, by = c('root_id' = 'id')) %>%
                                filter(is_deleted == FALSE & bio_categorization == 1) %>%
                                nrow()

# number of top-level, non-deleted registrations
total_registrations <- processed_node_data %>%
                      filter(type == 'osf.registration') %>%
                      filter(is_deleted == FALSE) %>%
                      distinct(root_id) %>%
                      nrow()

number_bio_registrations
round((number_bio_registrations/total_registrations)*100, 2)


## bio categorized nodes and their contributors
bionode_contributors <- overall_categorization %>%
                            left_join(node_contributors, by = 'id') %>%
                            group_by(root_id.x) %>%
                            mutate(project_bio = case_when(any(biology_categorization == 1) ~ 1, TRUE ~ 0)) %>%
                            ungroup() %>%                          
                            filter(project_bio == 1)

number_bio_contributors <- bionode_contributors %>%
                              group_by(user_id) %>%
                              tally() %>%
                              nrow()

number_bio_contributors
round((number_bio_contributors/142931)*100, 2)



####Graph of bio projects overtime

##getting project creation dates
project_creation_dates <- overall_categorization %>%
  filter(type == 'osf.node') %>%
  group_by(root_id) %>%
  summarize(bio_categorization = max(biology_categorization), project_created = min(node_created)) %>%
  left_join(node_data_summary, by = c('root_id' = 'id')) %>%
  select(root_id, bio_categorization, is_deleted, project_created) %>%
  filter(is_deleted == FALSE & bio_categorization == 1)

monthly_projects <- project_creation_dates %>%
                        group_by(month = floor_date(project_created, 'month')) %>%
                        summarize(total = sum(bio_categorization))

halfyear_projects <- project_creation_dates %>%
  mutate(month = month(project_created), year = year(project_created)) %>%
  mutate(half_year = case_when(month >= 1 & month <= 6 ~ '1H',
                            month >= 7 & month <= 12 ~ '2H')) %>%
  mutate(labels = paste0(half_year, ' ', year)) %>%
  group_by(labels) %>%
  summarize(num_projects = sum(bio_categorization)) %>%
  mutate(labels = as.factor(labels)) %>%
  mutate(labels = fct_relevel(labels, c('1H 2012', '2H 2012', 
                                        '1H 2013', '2H 2013',
                                        '1H 2014', '2H 2014',
                                        '1H 2015', '2H 2015',
                                        '1H 2016', '2H 2016',
                                        '1H 2017', '2H 2017',
                                        '1H 2018', '2H 2018',
                                        '1H 2019'))) %>%
  arrange(labels) %>%
  mutate(cumulative_projects = cumsum(num_projects))


ggplot(halfyear_projects, aes(x = labels, y = cumulative_projects, group = 1)) + 
  geom_line(size = 1.5) + 
  geom_point(size = 3) + 
  scale_y_continuous('Number of Projects', breaks = round(seq(0, 15000, by = 2500),1)) +
  ggtitle('Cumulative Number of Biology Projects on OSF') +
  theme(axis.text.x  = element_text(angle=45,hjust = 1,vjust = 1),
        axis.title.x = element_blank(),
        axis.title.y = element_text(margin = margin(0, 15, 0, 0), size = 22),
        axis.text = element_text(size = 18),
        plot.title = element_text(size = 22, hjust = 0.5, face = 'bold', margin=margin(0,0,15,0)))


### Graph of bio users overtime

monthly_users <- bionode_contributors %>%
  filter(!is.na(user_confirmed)) %>%
  group_by(by_month = floor_date(user_confirmed, 'month')) %>%
  distinct(user_id) %>%
  group_by(by_month) %>%
  summarize(monthly_total = n())

halfyear_users <- monthly_users %>%
  mutate(month = month(by_month), year = year(by_month)) %>%
  mutate(half_year = case_when(month >= 1 & month <= 6 ~ '1H',
                               month >= 7 & month <= 12 ~ '2H')) %>%
  mutate(labels = paste0(half_year, ' ', year)) %>%
  group_by(labels) %>%
  summarize(num_users = sum(monthly_total)) %>%
  mutate(labels = as.factor(labels)) %>%
  mutate(labels = fct_relevel(labels, c('1H 2012', '2H 2012', 
                                        '1H 2013', '2H 2013',
                                        '1H 2014', '2H 2014',
                                        '1H 2015', '2H 2015',
                                        '1H 2016', '2H 2016',
                                        '1H 2017', '2H 2017',
                                        '1H 2018', '2H 2018',
                                        '1H 2019'))) %>%
  arrange(labels) %>%
  mutate(cumulative_users = cumsum(num_users))

ggplot(halfyear_users, aes(x = labels, y = cumulative_users, group = 1)) + 
  geom_line(size = 1.5) + 
  geom_point(size = 3) + 
  scale_y_continuous('Number of Users', breaks = round(seq(0, 25000, by = 2500),1)) +
  ggtitle('Cumulative Number of Biology Users on OSF') +
  theme(axis.text.x  = element_text(angle=45,hjust = 1,vjust = 1),
        axis.title.x = element_blank(),
        axis.title.y = element_text(margin = margin(0, 15, 0, 0), size = 22),
        axis.text = element_text(size = 18),
        plot.title = element_text(size = 22, hjust = 0.5, face = 'bold', margin=margin(0,0,15,0)))
