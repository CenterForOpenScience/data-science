library(tidyverse)
library(lubridate)
library(skimr)
library(kableExtra)

remotes::install_github("rstudio/gt")
library(gt)
options(digits = 2)

survey_data_choices <- read_csv('/Users/courtneysoderberg/Downloads/Sloan+Preprints+Grant_May+28%2C+2019_09.21.csv', col_types = cols(.default = col_factor(),
                                                                                                                                ResponseId = col_character(),
                                                                                                                                position_7_TEXT = col_character(), 
                                                                                                                                discipline_specific = col_character(),
                                                                                                                                discipline_other = col_character(),
                                                                                                                                how_heard = col_character())) %>%
                          select(ResponseId, familiar, favor_use, preprints_submitted, preprints_used, position, discipline, country)
survey_data_numeric <- read_csv('/Users/courtneysoderberg/Downloads/Sloan+Preprints+Grant_May+29%2C+2019_16.12.csv') %>%
                          select(-c(familiar, favor_use, preprints_submitted, preprints_used, position, discipline, country))


survey_data <- left_join(survey_data_numeric, survey_data_choices, by = 'ResponseId') %>%
                   mutate(familiar = fct_rev(familiar), 
                          favor_use = fct_relevel(favor_use, c('Very much oppose', 'Moderately oppose', 'Slightly oppose', 'Neither oppose nor favor', 'Slightly favor', 'Moderately favor', 'Very much favor')),
                          favor_use_collapsed = fct_collapse(favor_use,
                                                             opposed = c('Very much oppose', 'Moderately oppose', 'Slightly oppose'),
                                                             neutral = 'Neither oppose nor favor',
                                                             favor = c('Slightly favor', 'Moderately favor', 'Very much favor')),
                          discipline_collapsed = fct_collapse(discipline,
                                                              Psychology = 'Psychology',
                                                              `Other Social Sciences` = c("Library/Information Science", "Political Science", "Sociology", "Economics"),
                                                              Biology = 'Biology',
                                                              `Other Life Sciences` = c("Ecology/Evolutionary Science", "Kinesiology", "Agricultural Science", "Nutritional Science", "Marine Science","Click to write Choice 23"),
                                                              `Physical Science & Math` = c("Statistics", "Physics", "Chemistry", "Engineering", "Paleontology", "Earth Science", "Mathematics", "Electrochemistry"),
                                                              `Humanities/Law` = c("Media Studies", "Law"),
                                                              Other = 'Other')) 

hdi_data <- read_csv('/Users/courtneysoderberg/Downloads/hdi_2017_data.csv', col_types =cols(country = col_factor(), HDI_2017 = col_number())) %>% select(country, HDI_2017)

hdi_data <- hdi_data %>%
  mutate(hdi_level = case_when(HDI_2017 >= .8 ~ 'very high',
                               HDI_2017 < .8 & HDI_2017 >= .7 ~ 'high',
                               HDI_2017 < .7 & HDI_2017 >= .555 ~ 'medium',
                               HDI_2017 < .555 ~ 'low',
                               TRUE ~ NA_character_))

survey_data <- left_join(survey_data, hdi_data, by = 'country')

overall_mean <- survey_data %>%
  select(-c(Progress, Status, Finished, `Duration (in seconds)`, consent, HDI_2017)) %>%
  skim_to_wide() %>%
  filter(type == 'numeric') %>%
  select(variable, complete, mean, sd, hist) %>%
  mutate(mean = as.numeric(mean),
         sd = as.numeric(sd),
         complete = as.numeric(complete))

# overall descriptive for Preprint Credibility
overall_mean_preprint_cred <- overall_mean %>%
                                  filter(grepl('preprint', variable)) %>%
                                  mutate(var_name = case_when(variable == 'preprint_cred1_1' ~ "Author's previous work",
                                                              variable == 'preprint_cred1_2' ~ "Author's institution",
                                                              variable == 'preprint_cred1_3' ~ "Professional identity links",
                                                              variable == 'preprint_cred1_4' ~ "COI disclosures",
                                                              variable == 'preprint_cred1_5' ~ "Author's level of open scholarship",
                                                              variable == 'preprint_cred2_1' ~ "Funders of research",
                                                              variable == 'preprint_cred2_2' ~ "Preprint submitted to a journal",
                                                              variable == 'preprint_cred2_3' ~ "Usage metrics",
                                                              variable == 'preprint_cred2_4' ~ "Citations of preprints",
                                                              variable == 'preprintcred3_1' ~ "Anonymouse comments",
                                                              variable == 'preprintcred3_2' ~ "Identified comments",
                                                              variable == 'preprintcred3_3' ~ "Simplified endorsements",
                                                              variable == 'preprint_cred4_1' ~ "Link to study data",
                                                              variable == 'preprint_cred4_2' ~ "Link to study analysis scripts",
                                                              variable == 'preprint_cred4_3' ~ "Link to materials",
                                                              variable == 'preprint_cred4_4' ~ "Link to pre-reg",
                                                              variable == 'preprint_cred5_1' ~ "Info about independent groups accessing linked info",
                                                              variable == 'preprint_cred5_2' ~ "Info about independent group reproductions",
                                                              variable == 'preprint_cred5_3' ~ "Infor about independent robustness checks",
                                                                TRUE ~ 'Courtney missed a variable')) %>%
                                  select(var_name, mean, sd, complete, hist)

overall_mean_preprint_cred %>%
  gt() %>%
  tab_header(title = 'Overall Importance of Icons for Preprint Credibility Judgements') %>%
  tab_source_note(source_note = 'Response Scale: 1 - Not at all important, 2 - Slightly important, 3 - Moderately important, 4 - Very Important, 5 - Extremely Important') %>%
  data_color(
    columns = vars(mean),
    colors = scales::col_numeric(
      palette = paletteer::paletteer_d(
        package = "Redmonder",
        palette = "dPBIRdGn"
      ),
      domain = c(1, 5))
  ) %>%
  cols_merge(col_1 = vars(mean), col_2 = vars(sd), pattern = '{1} ({2})') %>%
  cols_align(align = 'center', columns = vars(mean, complete, hist)) %>%
  cols_label(var_name = 'Potential Icon',
             mean = 'Mean (SD)',
             complete = 'N',
             hist = 'Responses Histograms')




# overall descriptive for Service Credibility
overall_mean_service_cred <- overall_mean %>%
                                filter(grepl('service', variable)) %>%
                                mutate(var_name = case_when(variable == 'services_cred1_1' ~ "Moderators the screen for spam",
                                                            variable == 'services_cred1_2' ~ "Scholars involved in operation",
                                                            variable == 'services_cred1_3' ~ "Clear policies for plagiarism/misconduct",
                                                            variable == 'services_cred1_4' ~ "Assesment of reproducibility",
                                                            variable == 'service_cred2_1' ~ "Software open source",
                                                            variable == 'service_cred2_2' ~ "Business moderal transparent and sustainable",
                                                            variable == 'service_cred2_3' ~ "Mechanism for long-term content preservation",
                                                            variable == 'service_cred2_4' ~ "Free for submitters and readers",
                                                            variable == 'service_cred3_1' ~ "Submit to journal from service",
                                                            variable == 'service_cred3_2' ~ "Indicates publication status",
                                                            variable == 'service_cred3_3' ~ "Allows endorsement of prerints",
                                                            variable == 'service_cred3_4' ~ "Indexed by search/discovery services",
                                                            variable == 'service_cred3_5' ~ "Popular in my discipline",
                                                            variable == 'service_credible4_1' ~ "Assign DOI to preprint",
                                                            variable == 'service_credible4_2' ~ "Allows anonymous posting of preprints",
                                                            variable == 'service_credible4_3' ~ "Authos can remove preprint for any reason",
                                                            variable == 'service_credible4_4' ~ "Service controls removal/withdrawl of preprints",
                                                            variable == 'service_credible4_5' ~ "Can submit new versions of preprints",
                                                            TRUE ~ 'Courtney missed a variable')) %>%
                                  select(var_name, mean, sd, complete, hist)


overall_mean_service_cred %>%
  gt() %>%
  tab_header(title = 'Overall Importance of Icons for Service Credibility Judgements') %>%
  tab_source_note(source_note = 'Response Scale: -3 - Decrease a lot, -2 - Moderately decrease, -1 - Slightly decrease, 0 - Neither decrease nor increase, 1 - Slightly increase, 2 - Moderately increase, 3 - Increase a lot') %>%
  fmt_number(columns = vars(mean), decimals = 2) %>%
  data_color(
    columns = vars(mean),
    colors = scales::col_numeric(
      palette = paletteer::paletteer_d(
        package = "Redmonder",
        palette = "dPBIRdGn"
      ),
      domain = c(-2, 3))
  ) %>%
  cols_merge(col_1 = vars(mean), col_2 = vars(sd), pattern = '{1} ({2})') %>%
  cols_align(align = 'center', columns = vars(mean, complete, hist)) %>%
  cols_label(var_name = 'Potential Icon',
             mean = 'Mean (SD)',
             complete = 'N',
             hist = 'Responses Histograms')



##### Preprint credibility descriptives broken out by whether respondents favored use 

#formatting data
preprintcred_means_by_favor <- survey_data %>%
  select(-c(Progress, Status, Finished, `Duration (in seconds)`, consent, HDI_2017)) %>%
  group_by(favor_use_collapsed) %>%
  skim_to_wide() %>%
  rename(question = variable) %>%
  select(favor_use_collapsed, question, complete, mean, sd) %>%
  filter(grepl('preprint', question)) %>%
  filter(!is.na(mean)) %>%
  mutate(mean = as.numeric(mean),
         sd = as.numeric(sd),
         complete = as.numeric(complete)) %>%
  gather(variable, value, -(question:favor_use_collapsed)) %>% 
  unite(temp, favor_use_collapsed, variable) %>% 
  spread(temp, value) %>%
  mutate(var_name = case_when(question == 'preprint_cred1_1' ~ "Author's previous work",
                              question == 'preprint_cred1_2' ~ "Author's institution",
                              question == 'preprint_cred1_3' ~ "Professional identity links",
                              question == 'preprint_cred1_4' ~ "COI disclosures",
                              question == 'preprint_cred1_5' ~ "Author's level of open scholarship",
                              question == 'preprint_cred2_1' ~ "Funders of research",
                              question == 'preprint_cred2_2' ~ "Preprint submitted to a journal",
                              question == 'preprint_cred2_3' ~ "Usage metrics",
                              question == 'preprint_cred2_4' ~ "Citations of preprints",
                              question == 'preprintcred3_1' ~ "Anonymouse comments",
                              question == 'preprintcred3_2' ~ "Identified comments",
                              question == 'preprintcred3_3' ~ "Simplified endorsements",
                              question == 'preprint_cred4_1' ~ "Link to study data",
                              question == 'preprint_cred4_2' ~ "Link to study analysis scripts",
                              question == 'preprint_cred4_3' ~ "Link to materials",
                              question == 'preprint_cred4_4' ~ "Link to pre-reg",
                              question == 'preprint_cred5_1' ~ "Info about independent groups accessing linked info",
                              question == 'preprint_cred5_2' ~ "Info about independent group reproductions",
                              question == 'preprint_cred5_3' ~ "Infor about independent robustness checks",
                              TRUE ~ 'Courtney missed a question')) %>%
  select(var_name, starts_with('opposed'), starts_with('neutral'), starts_with('favor'))

#building table
preprintcred_means_by_favor %>% 
  gt() %>%
  tab_header(title = 'Favor the User of Preprints') %>%
  tab_source_note(source_note = 'Response Scale: 1 - Not at all important, 2 - Slightly important, 3 - Moderately important, 4 - Very Important, 5 - Extremely Important') %>%
  tab_source_note(source_note = 'Categories: Originally a 7 point scale that has been tricotomized for descriptive purpose') %>%
  tab_source_note(source_note = 'Missing Date: 6-8 participants who responded to icon questions did not respond to the favorability question and are not included in the table') %>%
  cols_hide(columns = vars(favor_complete, neutral_complete, opposed_complete)) %>%
  data_color(
    columns = vars(opposed_mean, neutral_mean, favor_mean),
    colors = scales::col_numeric(
      palette = paletteer::paletteer_d(
        package = "Redmonder",
        palette = "dPBIRdGn"
      ),
      domain = c(1, 5))
  ) %>%
  cols_merge(col_1 = vars(opposed_mean), col_2 = vars(opposed_sd), pattern = '{1} ({2})') %>%
  cols_merge(col_1 = vars(neutral_mean), col_2 = vars(neutral_sd), pattern = '{1} ({2})') %>%
  cols_merge(col_1 = vars(favor_mean), col_2 = vars(favor_sd), pattern = '{1} ({2})') %>%
  tab_spanner(label = 'Opposed', columns = 'opposed_mean') %>%
  tab_spanner(label = 'Neutral', columns = 'neutral_mean') %>%
  tab_spanner(label = 'Favor', columns = 'favor_mean') %>%
  cols_align(align = 'center', columns = vars(opposed_mean, neutral_mean, favor_mean)) %>%
  cols_label(var_name = 'Potential Icon',
             opposed_mean = paste0('n = ', max(preprintcred_means_by_favor$opposed_complete),'-', min(preprintcred_means_by_favor$opposed_complete)),
             neutral_mean = paste0('n = ',max(preprintcred_means_by_favor$neutral_complete),'-', min(preprintcred_means_by_favor$neutral_complete)),
             favor_mean = paste0('n = ',max(preprintcred_means_by_favor$favor_complete),'-', min(preprintcred_means_by_favor$favor_complete)))
  


###### Service credibility descriptives broken out by whether respondents favored use
servicecred_means_by_favor <- survey_data %>%
  select(-c(Progress, Status, Finished, `Duration (in seconds)`, consent, HDI_2017)) %>%
  group_by(favor_use_collapsed) %>%
  skim_to_wide() %>%
  rename(question = variable) %>%
  select(favor_use_collapsed, question, complete, mean, sd) %>%
  filter(grepl('service', question)) %>%
  filter(!is.na(mean)) %>%
  mutate(mean = as.numeric(mean),
         sd = as.numeric(sd),
         complete = as.numeric(complete)) %>%
  gather(variable, value, -(question:favor_use_collapsed)) %>% 
  unite(temp, favor_use_collapsed, variable) %>% 
  spread(temp, value) %>%
  mutate(var_name = case_when(question == 'services_cred1_1' ~ "Moderators the screen for spam",
                              question == 'services_cred1_2' ~ "Scholars involved in operation",
                              question == 'services_cred1_3' ~ "Clear policies for plagiarism/misconduct",
                              question == 'services_cred1_4' ~ "Assesment of reproducibility",
                              question == 'service_cred2_1' ~ "Software open source",
                              question == 'service_cred2_2' ~ "Business moderal transparent and sustainable",
                              question == 'service_cred2_3' ~ "Mechanism for long-term content preservation",
                              question == 'service_cred2_4' ~ "Free for submitters and readers",
                              question == 'service_cred3_1' ~ "Submit to journal from service",
                              question == 'service_cred3_2' ~ "Indicates publication status",
                              question == 'service_cred3_3' ~ "Allows endorsement of prerints",
                              question == 'service_cred3_4' ~ "Indexed by search/discovery services",
                              question == 'service_cred3_5' ~ "Popular in my discipline",
                              question == 'service_credible4_1' ~ "Assign DOI to preprint",
                              question == 'service_credible4_2' ~ "Allows anonymous posting of preprints",
                              question == 'service_credible4_3' ~ "Authos can remove preprint for any reason",
                              question == 'service_credible4_4' ~ "Service controls removal/withdrawl of preprints",
                              question == 'service_credible4_5' ~ "Can submit new versions of preprints",
                              TRUE ~ 'Courtney missed a variable')) %>%
  select(var_name, starts_with('opposed'), starts_with('neutral'), starts_with('favor'))



servicecred_means_by_favor %>%
  gt() %>%
  tab_header(title = 'Favor the User of Preprints') %>%
  tab_source_note(source_note = 'Response Scale: -3 - Decrease a lot, -2 - Moderately decrease, -1 - Slightly decrease, 0 - Neither decrease nor increase, 1 - Slightly increase, 2 - Moderately increase, 3 - Increase a lot') %>%
  tab_source_note(source_note = 'Categories: Originally a 7 point scale that has been tricotomized for descriptive purpose') %>%
  tab_source_note(source_note = 'Missing Date: 5-7 participants who responded to icon questions did not respond to the favorability question and are not included in the table') %>%
  cols_hide(columns = vars(favor_complete, neutral_complete, opposed_complete)) %>%
  data_color(
    columns = vars(favor_mean, neutral_mean, opposed_mean),
    colors = scales::col_numeric(
      palette = paletteer::paletteer_d(
        package = "Redmonder",
        palette = "dPBIRdGn"
      ),
      domain = c(-2, 3))
  ) %>%
  cols_merge(col_1 = vars(opposed_mean), col_2 = vars(opposed_sd), pattern = '{1} ({2})') %>%
  cols_merge(col_1 = vars(neutral_mean), col_2 = vars(neutral_sd), pattern = '{1} ({2})') %>%
  cols_merge(col_1 = vars(favor_mean), col_2 = vars(favor_sd), pattern = '{1} ({2})') %>%
  tab_spanner(label = 'Opposed', columns = 'opposed_mean') %>%
  tab_spanner(label = 'Neutral', columns = 'neutral_mean') %>%
  tab_spanner(label = 'Favor', columns = 'favor_mean') %>%
  cols_align(align = 'center', columns = vars(opposed_mean, neutral_mean, favor_mean)) %>%
  cols_label(var_name = 'Potential Icon',
             opposed_mean = paste0('n = ', max(servicecred_means_by_favor$opposed_complete),'-', min(servicecred_means_by_favor$opposed_complete)),
             neutral_mean = paste0('n = ',max(servicecred_means_by_favor$neutral_complete),'-', min(servicecred_means_by_favor$neutral_complete)),
             favor_mean = paste0('n = ',max(servicecred_means_by_favor$favor_complete),'-', min(servicecred_means_by_favor$favor_complete)))



######## Group disciplines


# Preprint credibility descriptives broken out by discipline 
preprintcred_means_by_discipline <-survey_data %>%
  select(-c(Progress, Status, Finished, `Duration (in seconds)`, consent, HDI_2017)) %>%
  group_by(discipline_collapsed) %>%
  skim_to_wide() %>%
  rename(question = variable) %>%
  select(discipline_collapsed, question, complete, mean, sd) %>%
  filter(grepl('preprint', question)) %>%
  filter(!is.na(mean)) %>%
  mutate(mean = as.numeric(mean),
         sd = as.numeric(sd),
         complete = as.numeric(complete)) %>%
  gather(variable, value, -(question:discipline_collapsed)) %>% 
  unite(temp, discipline_collapsed, variable) %>% 
  spread(temp, value) %>%
  mutate(var_name = case_when(question == 'preprint_cred1_1' ~ "Author's previous work",
                              question == 'preprint_cred1_2' ~ "Author's institution",
                              question == 'preprint_cred1_3' ~ "Professional identity links",
                              question == 'preprint_cred1_4' ~ "COI disclosures",
                              question == 'preprint_cred1_5' ~ "Author's level of open scholarship",
                              question == 'preprint_cred2_1' ~ "Funders of research",
                              question == 'preprint_cred2_2' ~ "Preprint submitted to a journal",
                              question == 'preprint_cred2_3' ~ "Usage metrics",
                              question == 'preprint_cred2_4' ~ "Citations of preprints",
                              question == 'preprintcred3_1' ~ "Anonymouse comments",
                              question == 'preprintcred3_2' ~ "Identified comments",
                              question == 'preprintcred3_3' ~ "Simplified endorsements",
                              question == 'preprint_cred4_1' ~ "Link to study data",
                              question == 'preprint_cred4_2' ~ "Link to study analysis scripts",
                              question == 'preprint_cred4_3' ~ "Link to materials",
                              question == 'preprint_cred4_4' ~ "Link to pre-reg",
                              question == 'preprint_cred5_1' ~ "Info about independent groups accessing linked info",
                              question == 'preprint_cred5_2' ~ "Info about independent group reproductions",
                              question == 'preprint_cred5_3' ~ "Infor about independent robustness checks",
                              TRUE ~ 'Courtney missed a variable')) %>%
  select(var_name, starts_with('Psychology'), starts_with('Other'), starts_with('Biology'), starts_with('Physical'), starts_with('Humanities'), starts_with('NA'))
  


#building table
preprintcred_means_by_discipline  %>% 
  gt() %>%
  tab_header(title = 'Credibility of Preprints by Discipline') %>%
  tab_source_note(source_note = 'Response Scale: 1 - Not at all important, 2 - Slightly important, 3 - Moderately important, 4 - Very Important, 5 - Extremely Important') %>%
  tab_source_note(source_note = "Categories: 'Other' has not been cleaned yet, and will likely eventually be rolled into the other categories; 'Missing' are participants who did not fill out a discipline") %>%
  cols_hide(columns = ends_with('complete')) %>%
  data_color(
    columns = ends_with('mean'),
    colors = scales::col_numeric(
      palette = paletteer::paletteer_d(
        package = "Redmonder",
        palette = "dPBIRdGn"
      ),
      domain = c(1, 5))
  ) %>%
  cols_move(columns = vars(`Other Life Sciences_mean`, Other_mean), after = vars(Biology_mean)) %>%
  cols_move(columns = vars(`Humanities/Law_mean`), after = vars(NA_mean)) %>%
  cols_merge(col_1 = vars(Psychology_mean), col_2 = vars(Psychology_sd), pattern = '{1} ({2})') %>%
  cols_merge(col_1 = vars(Biology_mean), col_2 = vars(Biology_sd), pattern = '{1} ({2})') %>%
  cols_merge(col_1 = vars(Other_mean), col_2 = vars(Other_sd), pattern = '{1} ({2})') %>%
  cols_merge(col_1 = vars(NA_mean), col_2 = vars(NA_sd), pattern = '{1} ({2})') %>%
  cols_merge(col_1 = vars(`Other Life Sciences_mean`), col_2 = vars(`Other Life Sciences_sd`), pattern = '{1} ({2})') %>%
  cols_merge(col_1 = vars(`Other Social Sciences_mean`), col_2 = vars(`Other Social Sciences_sd`), pattern = '{1} ({2})') %>%
  cols_merge(col_1 = vars(`Physical Science & Math_mean`), col_2 = vars(`Physical Science & Math_sd`), pattern = '{1} ({2})') %>%
  cols_merge(col_1 = vars(`Humanities/Law_mean`), col_2 = vars(`Humanities/Law_sd`), pattern = '{1} ({2})') %>%
  tab_spanner(label = 'Psychology', columns = 'Psychology_mean') %>%
  tab_spanner(label = 'Biology', columns = 'Biology_mean') %>%
  tab_spanner(label = 'Other', columns = 'Other_mean') %>%
  tab_spanner(label = 'Missing', columns = 'NA_mean') %>%
  tab_spanner(label = 'Other Life Sci', columns = 'Other Life Sciences_mean') %>%
  tab_spanner(label = 'Other Social Sci', columns = 'Other Social Sciences_mean') %>%
  tab_spanner(label = 'Physical Sci & Math', columns = 'Physical Science & Math_mean') %>%
  tab_spanner(label = 'Hum & Law', columns = 'Humanities/Law_mean') %>%
  cols_align(align = 'center', columns = ends_with('mean')) %>%
  cols_label(var_name = 'Potential Icon',
             Psychology_mean = paste0('n = ', max(preprintcred_means_by_discipline$Psychology_complete),'-', min(preprintcred_means_by_discipline$Psychology_complete)),
             Biology_mean = paste0('n = ',max(preprintcred_means_by_discipline$Biology_complete),'-', min(preprintcred_means_by_discipline$Biology_complete)),
             Other_mean = paste0('n = ',max(preprintcred_means_by_discipline$Other_complete),'-', min(preprintcred_means_by_discipline$Other_complete)),
             NA_mean = paste0('n = ',max(preprintcred_means_by_discipline$NA_complete),'-', min(preprintcred_means_by_discipline$NA_complete)),
             `Physical Science & Math_mean` = paste0('n = ',max(preprintcred_means_by_discipline$`Physical Science & Math_complete`),'-', min(preprintcred_means_by_discipline$`Physical Science & Math_complete`)),
             `Other Life Sciences_mean` = paste0('n = ',max(preprintcred_means_by_discipline$`Other Life Sciences_complete`),'-', min(preprintcred_means_by_discipline$`Other Life Sciences_complete`)),
             `Other Social Sciences_mean` = paste0('n = ',max(preprintcred_means_by_discipline$`Other Social Sciences_complete`),'-', min(preprintcred_means_by_discipline$`Other Social Sciences_complete`)),
             `Humanities/Law_mean` = paste0('n = ',max(preprintcred_means_by_discipline$`Humanities/Law_complete`),'-', min(preprintcred_means_by_discipline$`Humanities/Law_complete`)))





# Service credibility descriptives broken out by discipline 
servicecred_means_by_discipline <-survey_data %>%
  select(-c(Progress, Status, Finished, `Duration (in seconds)`, consent, HDI_2017)) %>%
  group_by(discipline_collapsed) %>%
  skim_to_wide() %>%
  rename(question = variable) %>%
  select(discipline_collapsed, question, complete, mean, sd) %>%
  filter(grepl('service', question)) %>%
  filter(!is.na(mean)) %>%
  mutate(mean = as.numeric(mean),
         sd = as.numeric(sd),
         complete = as.numeric(complete)) %>%
  gather(variable, value, -(question:discipline_collapsed)) %>% 
  unite(temp, discipline_collapsed, variable) %>% 
  spread(temp, value) %>%
  mutate(var_name = case_when(question == 'services_cred1_1' ~ "Moderators the screen for spam",
                              question == 'services_cred1_2' ~ "Scholars involved in operation",
                              question == 'services_cred1_3' ~ "Clear policies for plagiarism/misconduct",
                              question == 'services_cred1_4' ~ "Assesment of reproducibility",
                              question == 'service_cred2_1' ~ "Software open source",
                              question == 'service_cred2_2' ~ "Business moderal transparent and sustainable",
                              question == 'service_cred2_3' ~ "Mechanism for long-term content preservation",
                              question == 'service_cred2_4' ~ "Free for submitters and readers",
                              question == 'service_cred3_1' ~ "Submit to journal from service",
                              question == 'service_cred3_2' ~ "Indicates publication status",
                              question == 'service_cred3_3' ~ "Allows endorsement of prerints",
                              question == 'service_cred3_4' ~ "Indexed by search/discovery services",
                              question == 'service_cred3_5' ~ "Popular in my discipline",
                              question == 'service_credible4_1' ~ "Assign DOI to preprint",
                              question == 'service_credible4_2' ~ "Allows anonymous posting of preprints",
                              question == 'service_credible4_3' ~ "Authos can remove preprint for any reason",
                              question == 'service_credible4_4' ~ "Service controls removal/withdrawl of preprints",
                              question == 'service_credible4_5' ~ "Can submit new versions of preprints",
                              TRUE ~ 'Courtney missed a variable')) %>%
    select(var_name, starts_with('Psychology'), starts_with('Other'), starts_with('Biology'), starts_with('Physical'), starts_with('Humanities'), starts_with('NA'))
  
servicecred_means_by_discipline  %>% 
  gt() %>%
  tab_header(title = 'Credibility of Service by Discipline') %>%
  tab_source_note(source_note = 'Response Scale: -3 - Decrease a lot, -2 - Moderately decrease, -1 - Slightly decrease, 0 - Neither decrease nor increase, 1 - Slightly increase, 2 - Moderately increase, 3 - Increase a lot') %>%
  tab_source_note(source_note = "Categories: 'Other' has not been cleaned yet, and will likely eventually be rolled into the other categories; 'Missing' are participants who did not fill out a discipline") %>%
  cols_hide(columns = ends_with('complete')) %>%
  data_color(
    columns = ends_with('mean'),
    colors = scales::col_numeric(
      palette = paletteer::paletteer_d(
        package = "Redmonder",
        palette = "dPBIRdGn"
      ),
      domain = c(-1.02, 3))
  ) %>%
  cols_move(columns = vars(`Other Life Sciences_mean`, Other_mean), after = vars(Biology_mean)) %>%
  cols_move(columns = vars(`Humanities/Law_mean`), after = vars(NA_mean)) %>%
  cols_merge(col_1 = vars(Psychology_mean), col_2 = vars(Psychology_sd), pattern = '{1} ({2})') %>%
  cols_merge(col_1 = vars(Biology_mean), col_2 = vars(Biology_sd), pattern = '{1} ({2})') %>%
  cols_merge(col_1 = vars(Other_mean), col_2 = vars(Other_sd), pattern = '{1} ({2})') %>%
  cols_merge(col_1 = vars(NA_mean), col_2 = vars(NA_sd), pattern = '{1} ({2})') %>%
  cols_merge(col_1 = vars(`Other Life Sciences_mean`), col_2 = vars(`Other Life Sciences_sd`), pattern = '{1} ({2})') %>%
  cols_merge(col_1 = vars(`Other Social Sciences_mean`), col_2 = vars(`Other Social Sciences_sd`), pattern = '{1} ({2})') %>%
  cols_merge(col_1 = vars(`Physical Science & Math_mean`), col_2 = vars(`Physical Science & Math_sd`), pattern = '{1} ({2})') %>%
  cols_merge(col_1 = vars(`Humanities/Law_mean`), col_2 = vars(`Humanities/Law_sd`), pattern = '{1} ({2})') %>%
  tab_spanner(label = 'Psychology', columns = 'Psychology_mean') %>%
  tab_spanner(label = 'Biology', columns = 'Biology_mean') %>%
  tab_spanner(label = 'Other', columns = 'Other_mean') %>%
  tab_spanner(label = 'Missing', columns = 'NA_mean') %>%
  tab_spanner(label = 'Other Life Sci', columns = 'Other Life Sciences_mean') %>%
  tab_spanner(label = 'Other Social Sci', columns = 'Other Social Sciences_mean') %>%
  tab_spanner(label = 'Physical Sci & Math', columns = 'Physical Science & Math_mean') %>%
  tab_spanner(label = 'Hum & Law', columns = 'Humanities/Law_mean') %>%
  cols_align(align = 'center', columns = ends_with('mean')) %>%
  cols_label(var_name = 'Potential Icon',
             Psychology_mean = paste0('n = ', max(servicecred_means_by_discipline$Psychology_complete),'-', min(servicecred_means_by_discipline$Psychology_complete)),
             Biology_mean = paste0('n = ',max(servicecred_means_by_discipline$Biology_complete),'-', min(servicecred_means_by_discipline$Biology_complete)),
             Other_mean = paste0('n = ',max(servicecred_means_by_discipline$Other_complete),'-', min(servicecred_means_by_discipline$Other_complete)),
             NA_mean = paste0('n = ',max(servicecred_means_by_discipline$NA_complete),'-', min(servicecred_means_by_discipline$NA_complete)),
             `Physical Science & Math_mean` = paste0('n = ',max(servicecred_means_by_discipline$`Physical Science & Math_complete`),'-', min(servicecred_means_by_discipline$`Physical Science & Math_complete`)),
             `Other Life Sciences_mean` = paste0('n = ',max(servicecred_means_by_discipline$`Other Life Sciences_complete`),'-', min(servicecred_means_by_discipline$`Other Life Sciences_complete`)),
             `Other Social Sciences_mean` = paste0('n = ',max(servicecred_means_by_discipline$`Other Social Sciences_complete`),'-', min(servicecred_means_by_discipline$`Other Social Sciences_complete`)),
             `Humanities/Law_mean` = paste0('n = ',max(servicecred_means_by_discipline$`Humanities/Law_complete`),'-', min(servicecred_means_by_discipline$`Humanities/Law_complete`)))




############# Group by HDI level 
preprintcred_means_by_hdilevel <-survey_data %>%
  select(-c(Progress, Status, Finished, `Duration (in seconds)`, consent, HDI_2017)) %>%
  group_by(hdi_level) %>%
  skim_to_wide() %>%
  rename(question = variable) %>%
  select(hdi_level, question, complete, mean, sd) %>%
  filter(grepl('preprint', question)) %>%
  filter(!is.na(mean)) %>%
  mutate(mean = as.numeric(mean),
         sd = as.numeric(sd),
         complete = as.numeric(complete)) %>%
  gather(variable, value, -(question:hdi_level)) %>% 
  unite(temp, hdi_level, variable) %>% 
  spread(temp, value) %>%
  mutate(var_name = case_when(question == 'preprint_cred1_1' ~ "Author's previous work",
                              question == 'preprint_cred1_2' ~ "Author's institution",
                              question == 'preprint_cred1_3' ~ "Professional identity links",
                              question == 'preprint_cred1_4' ~ "COI disclosures",
                              question == 'preprint_cred1_5' ~ "Author's level of open scholarship",
                              question == 'preprint_cred2_1' ~ "Funders of research",
                              question == 'preprint_cred2_2' ~ "Preprint submitted to a journal",
                              question == 'preprint_cred2_3' ~ "Usage metrics",
                              question == 'preprint_cred2_4' ~ "Citations of preprints",
                              question == 'preprintcred3_1' ~ "Anonymouse comments",
                              question == 'preprintcred3_2' ~ "Identified comments",
                              question == 'preprintcred3_3' ~ "Simplified endorsements",
                              question == 'preprint_cred4_1' ~ "Link to study data",
                              question == 'preprint_cred4_2' ~ "Link to study analysis scripts",
                              question == 'preprint_cred4_3' ~ "Link to materials",
                              question == 'preprint_cred4_4' ~ "Link to pre-reg",
                              question == 'preprint_cred5_1' ~ "Info about independent groups accessing linked info",
                              question == 'preprint_cred5_2' ~ "Info about independent group reproductions",
                              question == 'preprint_cred5_3' ~ "Infor about independent robustness checks",
                              TRUE ~ 'Courtney missed a variable')) %>%
  select(var_name, starts_with('very'), starts_with('high'), starts_with('medium'), starts_with('low'), starts_with('NA'))


preprintcred_means_by_hdilevel  %>% 
  gt() %>%
  tab_header(title = 'Credibility of Preprints by Country HDI Level') %>%
  tab_source_note(source_note = 'Response Scale: 1 - Not at all important, 2 - Slightly important, 3 - Moderately important, 4 - Very Important, 5 - Extremely Important') %>%
  cols_hide(columns = ends_with('complete')) %>%
  data_color(
    columns = ends_with('mean'),
    colors = scales::col_numeric(
      palette = paletteer::paletteer_d(
        package = "Redmonder",
        palette = "dPBIRdGn"
      ),
      domain = c(1, 5))
  ) %>%
  cols_merge(col_1 = vars(`very high_mean`), col_2 = vars(`very high_sd`), pattern = '{1} ({2})') %>%
  cols_merge(col_1 = vars(high_mean), col_2 = vars(high_sd), pattern = '{1} ({2})') %>%
  cols_merge(col_1 = vars(medium_mean), col_2 = vars(medium_sd), pattern = '{1} ({2})') %>%
  cols_merge(col_1 = vars(low_mean), col_2 = vars(low_sd), pattern = '{1} ({2})') %>%
  cols_merge(col_1 = vars(NA_mean), col_2 = vars(NA_sd), pattern = '{1} ({2})') %>%
  tab_spanner(label = 'Very High', columns = 'very high_mean') %>%
  tab_spanner(label = 'High', columns = 'high_mean') %>%
  tab_spanner(label = 'Medium', columns = 'medium_mean') %>%
  tab_spanner(label = 'Low', columns = 'low_mean') %>%
  tab_spanner(label = 'Missing', columns = 'NA_mean') %>%
  cols_align(align = 'center', columns = ends_with('mean')) %>%
  cols_label(var_name = 'Potential Icon',
             `very high_mean` = paste0('n = ', max(preprintcred_means_by_hdilevel$`very high_complete`),'-', min(preprintcred_means_by_hdilevel$`very high_complete`)),
             high_mean = paste0('n = ',max(preprintcred_means_by_hdilevel$high_complete),'-', min(preprintcred_means_by_hdilevel$high_complete)),
             medium_mean = paste0('n = ',max(preprintcred_means_by_hdilevel$medium_complete),'-', min(preprintcred_means_by_hdilevel$medium_complete)),
             low_mean = paste0('n = ',max(preprintcred_means_by_hdilevel$low_complete),'-', min(preprintcred_means_by_hdilevel$low_complete)),
             NA_mean = paste0('n = ',max(preprintcred_means_by_hdilevel$NA_complete),'-', min(preprintcred_means_by_hdilevel$NA_complete)))






servicecred_means_by_hdilevel <-survey_data %>%
  select(-c(Progress, Status, Finished, `Duration (in seconds)`, consent, HDI_2017)) %>%
  group_by(hdi_level) %>%
  skim_to_wide() %>%
  rename(question = variable) %>%
  select(hdi_level, question, complete, mean, sd) %>%
  filter(grepl('service', question)) %>%
  filter(!is.na(mean)) %>%
  mutate(mean = as.numeric(mean),
         sd = as.numeric(sd),
         complete = as.numeric(complete)) %>%
  gather(variable, value, -(question:hdi_level)) %>% 
  unite(temp, hdi_level, variable) %>% 
  spread(temp, value) %>%
  mutate(var_name = case_when(question == 'services_cred1_1' ~ "Moderators the screen for spam",
                              question == 'services_cred1_2' ~ "Scholars involved in operation",
                              question == 'services_cred1_3' ~ "Clear policies for plagiarism/misconduct",
                              question == 'services_cred1_4' ~ "Assesment of reproducibility",
                              question == 'service_cred2_1' ~ "Software open source",
                              question == 'service_cred2_2' ~ "Business moderal transparent and sustainable",
                              question == 'service_cred2_3' ~ "Mechanism for long-term content preservation",
                              question == 'service_cred2_4' ~ "Free for submitters and readers",
                              question == 'service_cred3_1' ~ "Submit to journal from service",
                              question == 'service_cred3_2' ~ "Indicates publication status",
                              question == 'service_cred3_3' ~ "Allows endorsement of prerints",
                              question == 'service_cred3_4' ~ "Indexed by search/discovery services",
                              question == 'service_cred3_5' ~ "Popular in my discipline",
                              question == 'service_credible4_1' ~ "Assign DOI to preprint",
                              question == 'service_credible4_2' ~ "Allows anonymous posting of preprints",
                              question == 'service_credible4_3' ~ "Authos can remove preprint for any reason",
                              question == 'service_credible4_4' ~ "Service controls removal/withdrawl of preprints",
                              question == 'service_credible4_5' ~ "Can submit new versions of preprints",
                              TRUE ~ 'Courtney missed a variable')) %>%
    select(var_name, starts_with('very'), starts_with('high'), starts_with('medium'), starts_with('low'), starts_with('NA'))
  

servicecred_means_by_hdilevel  %>% 
  gt() %>%
  tab_header(title = 'Credibility of Services by Country HDI Level') %>%
  tab_source_note(source_note = 'Response Scale: -3 - Decrease a lot, -2 - Moderately decrease, -1 - Slightly decrease, 0 - Neither decrease nor increase, 1 - Slightly increase, 2 - Moderately increase, 3 - Increase a lot') %>%
  cols_hide(columns = ends_with('complete')) %>%
  data_color(
    columns = ends_with('mean'),
    colors = scales::col_numeric(
      palette = paletteer::paletteer_d(
        package = "Redmonder",
        palette = "dPBIRdGn"
      ),
      domain = c(-1.01, 3))
  ) %>%
  cols_merge(col_1 = vars(`very high_mean`), col_2 = vars(`very high_sd`), pattern = '{1} ({2})') %>%
  cols_merge(col_1 = vars(high_mean), col_2 = vars(high_sd), pattern = '{1} ({2})') %>%
  cols_merge(col_1 = vars(medium_mean), col_2 = vars(medium_sd), pattern = '{1} ({2})') %>%
  cols_merge(col_1 = vars(low_mean), col_2 = vars(low_sd), pattern = '{1} ({2})') %>%
  cols_merge(col_1 = vars(NA_mean), col_2 = vars(NA_sd), pattern = '{1} ({2})') %>%
  tab_spanner(label = 'Very High', columns = 'very high_mean') %>%
  tab_spanner(label = 'High', columns = 'high_mean') %>%
  tab_spanner(label = 'Medium', columns = 'medium_mean') %>%
  tab_spanner(label = 'Low', columns = 'low_mean') %>%
  tab_spanner(label = 'Missing', columns = 'NA_mean') %>%
  cols_align(align = 'center', columns = ends_with('mean')) %>%
  cols_label(var_name = 'Potential Icon',
             `very high_mean` = paste0('n = ', max(servicecred_means_by_hdilevel$`very high_complete`),'-', min(servicecred_means_by_hdilevel$`very high_complete`)),
             high_mean = paste0('n = ',max(servicecred_means_by_hdilevel$high_complete),'-', min(servicecred_means_by_hdilevel$high_complete)),
             medium_mean = paste0('n = ',max(servicecred_means_by_hdilevel$medium_complete),'-', min(servicecred_means_by_hdilevel$medium_complete)),
             low_mean = paste0('n = ',max(servicecred_means_by_hdilevel$low_complete),'-', min(servicecred_means_by_hdilevel$low_complete)),
             NA_mean = paste0('n = ',max(servicecred_means_by_hdilevel$NA_complete),'-', min(servicecred_means_by_hdilevel$NA_complete)))



# Group by preprint submission 
preprintcred_means_by_preprints_submitted <-survey_data %>%
  select(-c(Progress, Status, Finished, `Duration (in seconds)`, consent, HDI_2017)) %>%
  group_by(preprints_submitted) %>%
  skim_to_wide() %>%
  rename(question = variable) %>%
  select(preprints_submitted, question, complete, mean, sd) %>%
  filter(grepl('preprint', question)) %>%
  filter(!is.na(mean)) %>%
  mutate(mean = as.numeric(mean),
         sd = as.numeric(sd),
         complete = as.numeric(complete)) %>%
  gather(variable, value, -(question:preprints_submitted)) %>% 
  unite(temp, preprints_submitted, variable) %>% 
  spread(temp, value) %>%
  mutate(var_name = case_when(question == 'preprint_cred1_1' ~ "Author's previous work",
                              question == 'preprint_cred1_2' ~ "Author's institution",
                              question == 'preprint_cred1_3' ~ "Professional identity links",
                              question == 'preprint_cred1_4' ~ "COI disclosures",
                              question == 'preprint_cred1_5' ~ "Author's level of open scholarship",
                              question == 'preprint_cred2_1' ~ "Funders of research",
                              question == 'preprint_cred2_2' ~ "Preprint submitted to a journal",
                              question == 'preprint_cred2_3' ~ "Usage metrics",
                              question == 'preprint_cred2_4' ~ "Citations of preprints",
                              question == 'preprintcred3_1' ~ "Anonymouse comments",
                              question == 'preprintcred3_2' ~ "Identified comments",
                              question == 'preprintcred3_3' ~ "Simplified endorsements",
                              question == 'preprint_cred4_1' ~ "Link to study data",
                              question == 'preprint_cred4_2' ~ "Link to study analysis scripts",
                              question == 'preprint_cred4_3' ~ "Link to materials",
                              question == 'preprint_cred4_4' ~ "Link to pre-reg",
                              question == 'preprint_cred5_1' ~ "Info about independent groups accessing linked info",
                              question == 'preprint_cred5_2' ~ "Info about independent group reproductions",
                              question == 'preprint_cred5_3' ~ "Infor about independent robustness checks",
                              TRUE ~ 'Courtney missed a variable')) %>%
  select(var_name, starts_with('No'), starts_with('Yes'))


preprintcred_means_by_preprints_submitted %>% 
  gt() %>%
  tab_header(title = 'Credibility of Preprints by Preprint Submitted') %>%
  tab_source_note(source_note = 'Response Scale: 1 - Not at all important, 2 - Slightly important, 3 - Moderately important, 4 - Very Important, 5 - Extremely Important') %>%
  tab_source_note(source_note = 'Missing Date: 9 - 11 participants who responded to icon questions did not respond to preprint submission questions and are not included in the table') %>%
  cols_hide(columns = ends_with('complete')) %>%
  data_color(
    columns = ends_with('mean'),
    colors = scales::col_numeric(
      palette = paletteer::paletteer_d(
        package = "Redmonder",
        palette = "dPBIRdGn"
      ),
      domain = c(1, 5))
  ) %>%
  cols_merge(col_1 = vars(No_mean), col_2 = vars(No_sd), pattern = '{1} ({2})') %>%
  cols_merge(col_1 = vars(`Not sure_mean`), col_2 = vars(`Not sure_sd`), pattern = '{1} ({2})') %>%
  cols_merge(col_1 = vars(`Yes, a few times_mean`), col_2 = vars(`Yes, a few times_sd`), pattern = '{1} ({2})') %>%
  cols_merge(col_1 = vars(`Yes, many times_mean`), col_2 = vars(`Yes, many times_sd`), pattern = '{1} ({2})') %>%
  cols_merge(col_1 = vars(`Yes, once_mean`), col_2 = vars(`Yes, once_sd`), pattern = '{1} ({2})') %>%
  cols_move(columns = vars(`Not sure_mean`), after = vars(`Yes, once_mean`)) %>%
  cols_move(columns = vars(`Yes, a few times_mean`, `Yes, many times_mean`), after = vars(`Yes, once_mean`)) %>%
  tab_spanner(label = 'No', columns = 'No_mean') %>%
  tab_spanner(label = 'Yes, once', columns = 'Yes, once_mean') %>%
  tab_spanner(label = 'Yes, a few times', columns = 'Yes, a few times_mean') %>%
  tab_spanner(label = 'Yes, many times', columns = 'Yes, many times_mean') %>%
  tab_spanner(label = 'Not sure', columns = 'Not sure_mean') %>%
  cols_align(align = 'center', columns = ends_with('mean')) %>%
  cols_label(var_name = 'Potential Icon',
             No_mean = paste0('n = ', max(preprintcred_means_by_preprints_submitted$No_complete),'-', min(preprintcred_means_by_preprints_submitted$No_complete)),
             `Yes, once_mean` = paste0('n = ',max(preprintcred_means_by_preprints_submitted$`Yes, once_complete`),'-', min(preprintcred_means_by_preprints_submitted$`Yes, once_complete`)),
             `Yes, a few times_mean` = paste0('n = ',max(preprintcred_means_by_preprints_submitted$`Yes, a few times_complete`),'-', min(preprintcred_means_by_preprints_submitted$`Yes, a few times_complete`)),
             `Yes, many times_mean` = paste0('n = ',max(preprintcred_means_by_preprints_submitted$`Yes, many times_complete`),'-', min(preprintcred_means_by_preprints_submitted$`Yes, many times_complete`)),
             `Not sure_mean` = paste0('n = ',max(preprintcred_means_by_preprints_submitted$`Not sure_complete`),'-', min(preprintcred_means_by_preprints_submitted$`Not sure_complete`)))






servicecred_means_by_preprints_submitted <-survey_data %>%
  select(-c(Progress, Status, Finished, `Duration (in seconds)`, consent, HDI_2017)) %>%
  group_by(preprints_submitted) %>%
  skim_to_wide() %>%
  rename(question = variable)
  select(preprints_submitted, question, complete, mean, sd) %>%
  filter(grepl('service', question)) %>%
  filter(!is.na(mean)) %>%
  mutate(mean = as.numeric(mean),
         sd = as.numeric(sd),
         complete = as.numeric(complete)) %>%
  gather(variable, value, -(question:preprints_submitted)) %>% 
  unite(temp, preprints_submitted, variable) %>% 
  spread(temp, value) %>%
  mutate(var_name = case_when(question == 'services_cred1_1' ~ "Moderators the screen for spam",
                              question == 'services_cred1_2' ~ "Scholars involved in operation",
                              question == 'services_cred1_3' ~ "Clear policies for plagiarism/misconduct",
                              question == 'services_cred1_4' ~ "Assesment of reproducibility",
                              question == 'service_cred2_1' ~ "Software open source",
                              question == 'service_cred2_2' ~ "Business moderal transparent and sustainable",
                              question == 'service_cred2_3' ~ "Mechanism for long-term content preservation",
                              question == 'service_cred2_4' ~ "Free for submitters and readers",
                              question == 'service_cred3_1' ~ "Submit to journal from service",
                              question == 'service_cred3_2' ~ "Indicates publication status",
                              question == 'service_cred3_3' ~ "Allows endorsement of prerints",
                              question == 'service_cred3_4' ~ "Indexed by search/discovery services",
                              question == 'service_cred3_5' ~ "Popular in my discipline",
                              question == 'service_credible4_1' ~ "Assign DOI to preprint",
                              question == 'service_credible4_2' ~ "Allows anonymous posting of preprints",
                              question == 'service_credible4_3' ~ "Authos can remove preprint for any reason",
                              question == 'service_credible4_4' ~ "Service controls removal/withdrawl of preprints",
                              question == 'service_credible4_5' ~ "Can submit new versions of preprints",
                              TRUE ~ 'Courtney missed a variable')) %>%
  select(var_name, `Not sure`, No, `Yes, once`, `Yes, a few times`, `Yes, many times`,`<NA>`)


# Group by preprint used 
preprintcred_means_by_preprints_used <-survey_data %>%
  select(-c(Progress, Status, Finished, `Duration (in seconds)`, consent, HDI_2017)) %>%
  group_by(preprints_used) %>%
  skim_to_wide() %>%
  select(preprints_used, variable, complete, mean, sd, hist) %>%
  filter(grepl('preprint', variable)) %>%
  filter(!is.na(mean)) %>%
  mutate(mean = as.numeric(mean),
         sd = as.numeric(sd),
         complete = as.numeric(complete)) %>%
  select(preprints_used, variable, mean) %>%
  spread(key = preprints_used, value = mean, drop = F) %>%
  mutate(var_name = case_when(variable == 'preprint_cred1_1' ~ "Author's previous work",
                              variable == 'preprint_cred1_2' ~ "Author's institution",
                              variable == 'preprint_cred1_3' ~ "Professional identity links",
                              variable == 'preprint_cred1_4' ~ "COI disclosures",
                              variable == 'preprint_cred1_5' ~ "Author's level of open scholarship",
                              variable == 'preprint_cred2_1' ~ "Funders of research",
                              variable == 'preprint_cred2_2' ~ "Preprint submitted to a journal",
                              variable == 'preprint_cred2_3' ~ "Usage metrics",
                              variable == 'preprint_cred2_4' ~ "Citations of preprints",
                              variable == 'preprintcred3_1' ~ "Anonymouse comments",
                              variable == 'preprintcred3_2' ~ "Identified comments",
                              variable == 'preprintcred3_3' ~ "Simplified endorsements",
                              variable == 'preprint_cred4_1' ~ "Link to study data",
                              variable == 'preprint_cred4_2' ~ "Link to study analysis scripts",
                              variable == 'preprint_cred4_3' ~ "Link to materials",
                              variable == 'preprint_cred4_4' ~ "Link to pre-reg",
                              variable == 'preprint_cred5_1' ~ "Info about independent groups accessing linked info",
                              variable == 'preprint_cred5_2' ~ "Info about independent group reproductions",
                              variable == 'preprint_cred5_3' ~ "Infor about independent robustness checks",
                              TRUE ~ 'Courtney missed a variable')) %>%
  select(var_name, `Not sure`, No, `Yes, once`, `Yes, a few times`, `Yes, many times`,`<NA>`)


servicecred_means_by_preprints_used <- survey_data %>%
  select(-c(Progress, Status, Finished, `Duration (in seconds)`, consent, HDI_2017)) %>%
  group_by(preprints_used) %>%
  skim_to_wide() %>%
  select(preprints_used, variable, complete, mean, sd, hist) %>%
  filter(grepl('service', variable)) %>%
  filter(!is.na(mean)) %>%
  mutate(mean = as.numeric(mean),
         sd = as.numeric(sd),
         complete = as.numeric(complete)) %>%
  select(preprints_used, variable, mean) %>%
  spread(key = preprints_used, value = mean, drop = F) %>%
  mutate(var_name = case_when(variable == 'services_cred1_1' ~ "Moderators the screen for spam",
                              variable == 'services_cred1_2' ~ "Scholars involved in operation",
                              variable == 'services_cred1_3' ~ "Clear policies for plagiarism/misconduct",
                              variable == 'services_cred1_4' ~ "Assesment of reproducibility",
                              variable == 'service_cred2_1' ~ "Software open source",
                              variable == 'service_cred2_2' ~ "Business moderal transparent and sustainable",
                              variable == 'service_cred2_3' ~ "Mechanism for long-term content preservation",
                              variable == 'service_cred2_4' ~ "Free for submitters and readers",
                              variable == 'service_cred3_1' ~ "Submit to journal from service",
                              variable == 'service_cred3_2' ~ "Indicates publication status",
                              variable == 'service_cred3_3' ~ "Allows endorsement of prerints",
                              variable == 'service_cred3_4' ~ "Indexed by search/discovery services",
                              variable == 'service_cred3_5' ~ "Popular in my discipline",
                              variable == 'service_credible4_1' ~ "Assign DOI to preprint",
                              variable == 'service_credible4_2' ~ "Allows anonymous posting of preprints",
                              variable == 'service_credible4_3' ~ "Authos can remove preprint for any reason",
                              variable == 'service_credible4_4' ~ "Service controls removal/withdrawl of preprints",
                              variable == 'service_credible4_5' ~ "Can submit new versions of preprints",
                              TRUE ~ 'Courtney missed a variable')) %>%
  select(var_name, `Not sure`, No, `Yes, once`, `Yes, a few times`, `Yes, many times`,`<NA>`)




kable(servicecred_means_by_preprints_used,
      col.names = c('Question', 'Not sure', 'No', 'Yes, once', 'Yes, a few times', 'Yes, many times', 'Missing data')) %>%
  kable_styling(bootstrap_options = c("striped", "hover"))
