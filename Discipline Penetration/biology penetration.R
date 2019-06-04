library(tidyverse)



node_wiki_data  <- read_csv('/Users/courtneysoderberg/Downloads/nodes_and_wiki.csv')
file_data <- read_csv('/Users/courtneysoderberg/Downloads/nodes_files_filetags.csv', col_types = list(tag_name = col_character(),
                                                                                                   tag_created = col_datetime()))
node_contributors <- read_csv('/Users/courtneysoderberg/Downloads/node_contributors.csv')
node_tags <- read_csv('/Users/courtneysoderberg/Downloads/nodes_tags.csv')

file_pattern <- c('\\.gz$', '\\.sds$', '\\.czi$', '\\.pzf$', '\\.fcs$', '\\.pzfx$', '\\.mol$', '\\.rxn$', '\\.sdf$', '\\.rgf$', '\\.lmd$',
                  '\\.sraw$', '\\.cfl$', '\\.fastq.gz$', '\\.rnai.gct$', '\\.igv$', ' \\.bam.list$', '\\.mrxs$', '\\.wsp$', '\\.jo$',
                  '\\.yep$', '\\.bag$', '\\.fid$', '\\.tdf$', '\\.wiff$', '\\.lcd$', '\\.mrc$', '\\.sff$', '\\.fastq.gz$', '\\.qual$',
                  '\\.ab1$', '\\.abi$', '\\.abd$', '\\.alx$', '\\.mseq$', '\\.embl$', '\\.fasta$', '\\.fas$', '\\.fap$', '\\.nt$', '\\.aa$', 
                  '\\.fna$', '\\.fap$', '\\.frn$', '\\.faa$', '\\.mfa$', '\\.seq$', '\\.gcg$', '\\.pro$', '\\.pep$', '\\.gbk$', '\\.gp$',
                  '\\.genbank$', '\\.genpept$', '\\.gnv$', '\\.meg$', '\\.msa$', '\\.cif$', '\\.novafold$', '\\.antibody$', '\\.novadock$', 
                  '\\.phd$', '\\.pcr$', '\\.structure$', '\\.pad$', '\\.pdb$', '\\.ent$', '\\.pdb.gz$', '\\.ent.gz$', '\\.ct$', '\\.scf$',
                  '\\.sbd$', '\\.sqd$', '\\.star$', '\\.starff$', '\\.spf$', '\\.dna$', '\\.prot$', '\\.ndt$', '\\.lif$', '\\.gel$', '\\.dcm$',
                  '\\.rdml$', '\\.mzxml$')

word_pattern <- c('\\<biol', '\\<onco', '\\<PCR\\>', '\\<lipid', '\\<protein', '\\<proteo', 'omnic\\>', 'omnics\\>', '\\<genom', 'eome\\>', 
                  'eomes\\>', '\\<RNA\\>', 'RNA\\>','\\<RNA', '\\<DNA\\>', '\\<cellu', '\\<biomed', '\\<nucelo', '\\<immuno', '\\<metab', '\\<microb', 
                  '\\<neuro','\\<biochem', '\\<molec', '\\<pharma', '\\<CRISPR\\>', '\\<chemi', '\\<enzy', '\\<histol',
                  '\\<embryo', '\\<gene\\>', '\\<patho', 'virus', '\\<viro', '\\<bioinf', '\\<lipo', 'cancer', 'plasma\\>', 'scopy\\>',
                  '\\<antibod', '\\<cyto', '\\<plasma', '\\<xeno', '\\<fluor', '\\<spect', 'PCR\\>', '\\<transfect', 'drosophilia')

processed_file_data <- file_data %>%
                          mutate(file_ending = grepl(paste(file_pattern, collapse="|"),file_name)) %>%
                          mutate(file_tags = grepl(paste(word_pattern, collapse="|"), tag_name, ignore.case = T)) %>%
                          mutate(file_name_match = grepl(paste(word_pattern, collapse="|"), file_name, ignore.case = T)) %>%
                          mutate(file_biology = case_when(file_ending == TRUE | file_tags == TRUE | file_name_match == TRUE ~ 1,
                                                          TRUE ~ 0))

processed_file_data %>% 
  filter(file_tags == TRUE | file_ending == TRUE | file_name_match == TRUE) %>% 
  filter(is.na(deleted_on)) %>%
  filter(spam_status == 4 | is.na(spam_status)) %>%
  group_by(node_id, file_id, file_name) %>% 
  tally() %>% 
  select(node_id, file_id, file_name) %>%
  write_csv('file_matches.csv')

##number of non-deleted, not on spam nodes files (excluding folders, includes osfstorage files and add-on files that have been touched by the API)
processed_file_data %>%
  filter(is.na(deleted_on)) %>%
  filter(spam_status == 4 | is.na(spam_status)) %>%
  filter(!grepl('folder', file_type)) %>%
  filter(file_tags == TRUE | file_ending == TRUE | file_name_match == TRUE) %>%
  group_by(file_id, file_name) %>%
  tally() %>%
  nrow()

##categorize nodes as bio vs. not based on files
node_file_summary <- processed_file_data %>%
                    group_by(node_id, spam_status) %>%
                    summarize(bio_files = max(file_biology)) %>%
                    rename(id = node_id)


processed_nodetag_data <- node_tags %>%
                                mutate(node_tag = grepl(paste(word_pattern, collapse="|"), tag_name, ignore.case = T))

##cateogize nodes as bio vs. not based on node tags
nodetag_data_summary <- processed_nodetag_data %>%
                            group_by(id) %>%
                            mutate(bio_tag = as.numeric(node_tag)) %>%
                            summarize(bio_tags = max(bio_tag))



processed_node_data <- node_wiki_data %>%
                            mutate(node_title = grepl(paste(word_pattern, collapse="|"), title, ignore.case = T)) %>%
                            mutate(node_description = grepl(paste(word_pattern, collapse="|"), description, ignore.case = T)) %>%
                            mutate(node_wikiname = grepl(paste(word_pattern, collapse="|"), wiki_name, ignore.case = T)) %>%
                            mutate(node_wiki = grepl(paste(word_pattern, collapse="|"), wiki_content, ignore.case = T)) %>%
                            mutate(bio_node = case_when(node_title == TRUE | node_description == TRUE | node_wikiname == TRUE | node_wiki == TRUE ~ 1,
                                                        TRUE ~ 0))

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


overall_categorization <- left_join(node_data_summary, nodetag_data_summary, by = 'id') %>%
                              left_join(node_file_summary, by = 'id') %>%
                              mutate(biology_categorization = case_when(biology_node == 1 | bio_tags == 1 | bio_files == 1 ~ 1,
                                                                        TRUE ~ 0)) %>%
                              filter(spam_status == 4 | is.na(spam_status))




##number of non-deleted, non-spam top level projects that have at least 1 node categorized as biology (even if that particular node was deleted but the toplevel project still exists)
overall_categorization %>%
  filter(type == 'osf.node') %>%
  group_by(root_id) %>%
  summarize(bio_categorization = max(biology_categorization)) %>%
  left_join(node_data_summary, by = c('root_id' = 'id')) %>%
  select(root_id, bio_categorization, is_deleted, node_created, node_modified) %>%
  filter(is_deleted == FALSE & bio_categorization == 1) %>%
  nrow()

##number of non-deleted, non-spam top level registrations that have at least 1 node categorized as biology (even if that particular node was deleted but the toplevel project still exists)
overall_categorization %>%
  filter(type == 'osf.registration') %>%
  group_by(root_id) %>%
  summarize(bio_categorization = max(biology_categorization)) %>%
  left_join(node_data_summary, by = c('root_id' = 'id')) %>%
  select(root_id, bio_categorization, is_deleted, node_created, node_modified) %>%
  filter(is_deleted == FALSE & bio_categorization == 1) %>%
  nrow()


##bio categorized nodes and their contributors
bionode_contributors <- overall_categorization %>%
                            left_join(node_contributors, by = 'id') %>%
                            group_by(root_id.x) %>%
                            mutate(project_bio = case_when(any(biology_categorization == 1) ~ 1, TRUE ~ 0)) %>%
                            ungroup() %>%                          
                            filter(project_bio == 1)
                            
bionode_contributors %>%
  group_by(user_id) %>%
  tally() %>%
  nrow()

processed_node_data %>% 
  filter(node_title == TRUE | node_description == TRUE | node_wikiname == TRUE | node_wiki == TRUE) %>% 
  filter(is_deleted == FALSE) %>%
  write_csv('node_matches.csv')

processed_file_data %>% 
  filter(file_ending == TRUE) %>% 
  filter(is.na(deleted_on)) %>%
  group_by(node_id, file_id, file_name) %>% 
  tally()

processed_file_data %>% 
  filter(file_ending == TRUE) %>% 
  filter(is.na(deleted_on)) %>%
  group_by(root_id) %>% 
  tally()


processed_file_data %>%
    filter(file_ending == FALSE) %>%
    filter(file_tags == TRUE)



project_creation_dates <- overall_categorization %>%
  filter(type == 'osf.node') %>%
  group_by(root_id) %>%
  summarize(bio_categorization = max(biology_categorization), project_created = min(node_created)) %>%
  left_join(node_data_summary, by = c('root_id' = 'id')) %>%
  select(root_id, bio_categorization, is_deleted, project_created) %>%
  filter(is_deleted == FALSE & bio_categorization == 1)


