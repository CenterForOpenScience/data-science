## required libraries
library(osfr)
library(tidyverse)
library(likert)
library(here)
library(skimr)
library(gt)
library(wesanderson)
library(corrplot)

## reading in data
osf_retrieve_file("https://osf.io/86upq/") %>% 
  osf_download(overwrite = T)

survey_data <- read_csv(here::here('cleaned_data.csv'), col_types = cols(.default = col_number(),
                                                                         StartDate = col_datetime(format = '%m/%d/%y %H:%M'),
                                                                         EndDate = col_datetime(format = '%m/%d/%y %H:%M'),
                                                                         ResponseId = col_character(),
                                                                         position_7_TEXT = col_character(), 
                                                                         familiar = col_factor(),
                                                                         preprints_submitted = col_factor(),
                                                                         preprints_used = col_factor(),
                                                                         position = col_factor(),
                                                                         acad_career_stage = col_factor(),
                                                                         country = col_factor(),
                                                                         continent = col_factor(),
                                                                         discipline = col_character(),
                                                                         discipline_specific = col_character(),
                                                                         discipline_other = col_character(),
                                                                         bepress_tier1 = col_character(),
                                                                         bepress_tier2 = col_character(),
                                                                         bepress_tier3 = col_character(),
                                                                         discipline_collapsed = col_factor(),
                                                                         how_heard = col_character(),
                                                                         hdi_level = col_factor(),
                                                                         age = col_character())) %>%
                  mutate(acad_career_stage = fct_relevel(acad_career_stage, 'Full Prof', 'Assoc Prof', 'Assist Prof', 'Post doc', 'Grad Student'),
                         preprints_used = fct_relevel(preprints_used, 'No', 'Yes, once', 'Yes, a few times', 'Yes, many times', 'Not sure'),
                         preprints_submitted = fct_relevel(preprints_submitted, 'No', 'Yes, once', 'Yes, a few times', 'Yes, many times', 'Not sure'))

## Overall icons importance
preprint_cred <- survey_data %>%
  dplyr::select(preprint_cred1_1:preprint_cred5_3)

choices  <- c('Not at all important', 'Slightly important', 'Moderately important', 'Very important', 'Extremely important')

colnames(preprint_cred) <- c(preprint_cred1_1 = "Author's previous work",
                             preprint_cred1_2 = "Author's institutions",
                             preprint_cred1_3 = "Professional Identify links (e.g. ORCID, GoogleScholar)",
                             preprint_cred1_4 = "COI disclosures",
                             preprint_cred1_5 = "Author(s) general levels open scholarship",
                             preprint_cred2_1 = "Funder(s) of the research",
                             preprint_cred2_2 = "Preprint submitted to a journal",
                             preprint_cred2_3 = "Usage metrics about the preprint",
                             preprint_cred2_4 = "Citations of the preprint",
                             preprint_cred3_1 = "Anonymous users comments",
                             preprint_cred3_2 = "Identified user comments",
                             preprint_cred3_3 = "Simplified endorsement by users",
                             preprint_cred4_1 = "Links to any available study data",
                             preprint_cred4_2 = "Links to any available analysis scripts",
                             preprint_cred4_3 = "Links to any available materials",
                             preprint_cred4_4 = "Links to any pre-registrations or pre-analysis plans",
                             preprint_cred5_1 = "Info about whether indep groups could access linked info",
                             preprint_cred5_2 = "Info about indep reproductions",
                             preprint_cred5_3 = "Info about indep robustness checks")

preprint_cred <- preprint_cred %>%
  mutate_all(factor, levels=1:5, labels=choices, ordered=TRUE)

cred_preprints<- expression(atop("When assessing the credibility of a preprint", paste("how important would it be to have each of the following pieces of information?")))
pdf("icon_cred.pdf", width=12.5, height=10)
plot(likert(as.data.frame(preprint_cred)), ordered=T, text.size = 4) + 
  ggtitle(cred_preprints)+
  theme(plot.title = element_text(hjust = 0.5), legend.title = element_blank(), legend.text=element_text(size=12), axis.text = element_text(size = 12))
dev.off()


# table by academic discipline
preprintcred_means_by_position <- survey_data %>%
  select(-c(consent, HDI_2017)) %>%
  group_by(acad_career_stage) %>%
  skim_to_wide() %>%
  rename(question = variable) %>%
  select(acad_career_stage, question, complete, mean, sd) %>%
  filter(grepl('preprint', question)) %>%
  filter(!is.na(mean)) %>%
  mutate(mean = as.numeric(mean),
         sd = as.numeric(sd),
         complete = as.numeric(complete)) %>%
  gather(variable, value, -(question:acad_career_stage)) %>% 
  unite(temp, acad_career_stage, variable) %>% 
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
                              question == 'preprint_cred3_1' ~ "Anonymous comments",
                              question == 'preprint_cred3_2' ~ "Identified comments",
                              question == 'preprint_cred3_3' ~ "Simplified endorsements",
                              question == 'preprint_cred4_1' ~ "Link to study data",
                              question == 'preprint_cred4_2' ~ "Link to study analysis scripts",
                              question == 'preprint_cred4_3' ~ "Link to materials",
                              question == 'preprint_cred4_4' ~ "Link to pre-reg",
                              question == 'preprint_cred5_1' ~ "Info about indep groups accessing linked info",
                              question == 'preprint_cred5_2' ~ "Info about indep group reproductions",
                              question == 'preprint_cred5_3' ~ "Info about indep robustness checks",
                              TRUE ~ 'Courtney missed a question')) %>%
  select(var_name, starts_with('Grad'), starts_with('Post'), starts_with('Assist'), starts_with('Assoc'), starts_with('Full'))

#building table
preprintcred_means_by_position %>% 
  gt() %>%
  tab_header(title = 'Career Stage') %>%
  cols_hide(columns = vars(`Grad Student_complete`, `Post doc_complete`, `Assist Prof_complete`,`Assoc Prof_complete`, `Full Prof_complete` )) %>%
  data_color(
    columns = vars(`Grad Student_mean`,`Post doc_mean`,`Assist Prof_mean`, `Assoc Prof_mean`, `Full Prof_mean`),
    colors = scales::col_numeric(
      palette = paletteer::paletteer_d(
        package = "RColorBrewer",
        palette = "BrBG"
      ),
      domain = c(1, 5))
  ) %>%
  cols_merge(col_1 = vars(`Grad Student_mean`), col_2 = vars(`Grad Student_sd`), pattern = '{1} ({2})') %>%
  cols_merge(col_1 = vars(`Post doc_mean`), col_2 = vars(`Post doc_sd`), pattern = '{1} ({2})') %>%
  cols_merge(col_1 = vars(`Assist Prof_mean`), col_2 = vars(`Assist Prof_sd`), pattern = '{1} ({2})') %>%
  cols_merge(col_1 = vars(`Assoc Prof_mean`), col_2 = vars(`Assoc Prof_sd`), pattern = '{1} ({2})') %>%
  cols_merge(col_1 = vars(`Full Prof_mean`), col_2 = vars(`Full Prof_sd`), pattern = '{1} ({2})') %>%
  tab_spanner(label = 'Grad Student', columns = 'Grad Student_mean') %>%
  tab_spanner(label = 'Post doc', columns = 'Post doc_mean') %>%
  tab_spanner(label = 'Assist Prof', columns = 'Assist Prof_mean') %>%
  tab_spanner(label = 'Assoc Prof', columns = 'Assoc Prof_mean') %>%
  tab_spanner(label = 'Full Prof', columns = 'Full Prof_mean') %>%
  cols_align(align = 'center', columns = ends_with('mean')) %>%
  cols_label(var_name = 'Potential Icon',
             `Grad Student_mean` = paste0('n = ', min(preprintcred_means_by_position$`Grad Student_complete`),'-', max(preprintcred_means_by_position$`Grad Student_complete`)),
             `Post doc_mean` = paste0('n = ',min(preprintcred_means_by_position$`Post doc_complete`),'-', max(preprintcred_means_by_position$`Post doc_complete`)),
             `Assist Prof_mean` = paste0('n = ',min(preprintcred_means_by_position$`Assist Prof_complete`),'-', max(preprintcred_means_by_position$`Assist Prof_complete`)),
             `Assoc Prof_mean` = paste0('n = ',min(preprintcred_means_by_position$`Assoc Prof_complete`),'-', max(preprintcred_means_by_position$`Assoc Prof_complete`)),
             `Full Prof_mean` = paste0('n = ',min(preprintcred_means_by_position$`Full Prof_complete`),'-', max(preprintcred_means_by_position$`Full Prof_complete`)))



# table by academic discipline

preprintcred_means_by_discipline <-survey_data %>%
  select(-c(consent, HDI_2017)) %>%
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
                              question == 'preprint_cred3_1' ~ "Anonymous comments",
                              question == 'preprint_cred3_2' ~ "Identified comments",
                              question == 'preprint_cred3_3' ~ "Simplified endorsements",
                              question == 'preprint_cred4_1' ~ "Link to study data",
                              question == 'preprint_cred4_2' ~ "Link to study analysis scripts",
                              question == 'preprint_cred4_3' ~ "Link to materials",
                              question == 'preprint_cred4_4' ~ "Link to pre-reg",
                              question == 'preprint_cred5_1' ~ "Info about indep groups accessing linked info",
                              question == 'preprint_cred5_2' ~ "Info about indep group reproductions",
                              question == 'preprint_cred5_3' ~ "Info about indep robustness checks",
                              TRUE ~ 'Courtney missed a variable')) %>%
  select(var_name, starts_with('Psychology'), starts_with('Other Social'), starts_with('Life'), starts_with('Medicine'), starts_with('Physical'))

#building table
preprintcred_means_by_discipline  %>% 
  gt() %>%
  tab_header(title = 'Credibility of Preprints by Discipline') %>%
  cols_hide(columns = ends_with('complete')) %>%
  data_color(
    columns = ends_with('mean'),
    colors = scales::col_numeric(
      palette = paletteer::paletteer_d(
        package = "RColorBrewer",
        palette = "BrBG"
      ),
      domain = c(1, 5))
  ) %>%
  cols_merge(col_1 = vars(Psychology_mean), col_2 = vars(Psychology_sd), pattern = '{1} ({2})') %>%
  cols_merge(col_1 = vars(`Life Sciences (Biology)_mean`), col_2 = vars(`Life Sciences (Biology)_sd`), pattern = '{1} ({2})') %>%
  cols_merge(col_1 = vars(`Other Social Sciences_mean`), col_2 = vars(`Other Social Sciences_sd`), pattern = '{1} ({2})') %>%
  cols_merge(col_1 = vars(`Physical Sciences and Mathematics_mean`), col_2 = vars(`Physical Sciences and Mathematics_sd`), pattern = '{1} ({2})') %>%
  cols_merge(col_1 = vars(`Medicine and Health Sciences_mean`), col_2 = vars(`Medicine and Health Sciences_sd`), pattern = '{1} ({2})') %>%
  tab_spanner(label = 'Psychology', columns = 'Psychology_mean') %>%
  tab_spanner(label = 'Life Sci (Bio)', columns = 'Life Sciences (Biology)_mean') %>%
  tab_spanner(label = 'Med & Health Sci', columns = 'Medicine and Health Sciences_mean') %>%
  tab_spanner(label = 'Other Soc Sci', columns = 'Other Social Sciences_mean') %>%
  tab_spanner(label = 'Phys Sci & Math', columns = 'Physical Sciences and Mathematics_mean') %>%
  cols_align(align = 'center', columns = ends_with('mean')) %>%
  cols_label(var_name = 'Potential Icon',
             Psychology_mean = paste0('n = ', min(preprintcred_means_by_discipline$Psychology_complete),'-', max(preprintcred_means_by_discipline$Psychology_complete)),
             `Life Sciences (Biology)_mean` = paste0('n = ',min(preprintcred_means_by_discipline$`Life Sciences (Biology)_complete`),'-', max(preprintcred_means_by_discipline$`Life Sciences (Biology)_complete`)),
             `Physical Sciences and Mathematics_mean` = paste0('n = ',min(preprintcred_means_by_discipline$`Physical Sciences and Mathematics_complete`),'-', max(preprintcred_means_by_discipline$`Physical Sciences and Mathematics_complete`)),
             `Medicine and Health Sciences_mean` = paste0('n = ',min(preprintcred_means_by_discipline$`Medicine and Health Sciences_complete`),'-', max(preprintcred_means_by_discipline$`Medicine and Health Sciences_complete`)),
             `Other Social Sciences_mean` = paste0('n = ',min(preprintcred_means_by_discipline$`Other Social Sciences_complete`),'-', max(preprintcred_means_by_discipline$`Other Social Sciences_complete`)))




## Overall service credibilitys

service_cred <- survey_data %>%
  dplyr::select(services_cred1_1:service_credible4_5)

choices <- c('Decrease a lot', "Moderately decrease", "Slightly decrease", "Neither decrease nor increase", "Slightly increase", "Moderately increase", "Increase a lot")

colnames(service_cred) <- c(services_cred1_1 = "Service moderators that screen for spam and non-scholarly content", 
                            services_cred1_2 = "Scholars in my field are involved in the operation of the service (e.g., via an advisory board)",
                            services_cred1_3 = "Service has clear policies about misconduct and plagiarism and a mechanism to flag content that may breach these policies", 
                            services_cred1_4 = "Service assesses the reproducibility of reported findings and indicates the results of their assessment on each preprint",
                            service_cred2_1 = "The software running the service is open source (e.g. openly licensed)", 
                            service_cred2_2 = "The service’s business model is transparent, stable and sustainable", 
                            service_cred2_3 = "Service has a mechanism for long-term preservation of content",
                            service_cred2_4 = "Service is free for preprint submitters and readers", 
                            service_cred3_1 = "Service enables preprints to be submitted to journals directly from the service site", 
                            service_cred3_2 = "Service clearly indicates which content, if any, has been published in a peer-reviewed journal",
                            service_cred3_3 = "Service allows endorsements of preprints by independent users (i.e. non-authors)", 
                            service_cred3_4 = "Service is indexed by search and discovery services (e.g., Google Scholar, Crossref)", 
                            service_cred3_5 = "Service is popular in my discipline", 
                            service_credible4_1 = "Ability to assign a DOI to the preprint", 
                            service_credible4_2 = "Service enables anonymous posting of preprints", 
                            service_credible4_3 = "Service allows authors to remove their preprints for any reason",
                            service_credible4_4 = "Once posted, the service controls remove/withdrawal of preprints", 
                            service_credible4_5 = "Service enables submission of new versions of the preprint")


service_cred <- service_cred %>%
  mutate_all(factor, levels=-3:3, labels=choices, ordered=TRUE)

service_preprints<- expression(atop("To what extent would having each of the following features ", paste("decrease or increase the credibility of a preprint service?")))
pdf("service_cred.pdf", width=12.5, height=10)
plot(likert(as.data.frame(service_cred)), ordered=T) + ggtitle(service_preprints)+
  theme(plot.title = element_text(hjust = 0.5), legend.title = element_blank())
dev.off()

# use/submissions of preprints by discipline
survey_data %>%
    mutate(preprints_used = fct_rev(preprints_used)) %>%
    group_by(discipline_collapsed, preprints_used) %>%
    tally() %>%
    mutate(perc = round(100*n/sum(n),2)) %>%
    filter(!is.na(preprints_used), discipline_collapsed != 'Other', discipline_collapsed != '(Missing)', preprints_used != 'Not sure') %>%
    ggplot(aes(fill = preprints_used, x = discipline_collapsed, y = perc)) +
    geom_col(position = 'dodge') +
    geom_text(aes(label = perc), size = 4, position = position_dodge(width = 1), hjust= -.1) +
    coord_flip() +
    guides(fill = guide_legend(reverse = TRUE)) +
    scale_fill_manual(values = wes_palette("IsleofDogs2"))

survey_data %>%
  mutate(preprints_submitted = fct_rev(preprints_submitted)) %>%
  group_by(discipline_collapsed, preprints_submitted) %>%
  tally() %>%
  mutate(perc = round(100*n/sum(n),2)) %>%
  filter(!is.na(preprints_submitted), discipline_collapsed != 'Other', discipline_collapsed != '(Missing)', preprints_submitted != 'Not sure') %>%
  ggplot(aes(fill = preprints_submitted, x = discipline_collapsed, y = perc)) +
  geom_col(position = 'dodge') +
  coord_flip() +
  guides(fill = guide_legend(reverse = TRUE)) +
  scale_fill_manual(values = wes_palette("IsleofDogs2"))


# favor-use by discipline
discipline_favor <- survey_data %>% 
                    mutate(favor_use = as.factor(favor_use),
                           favor_use = fct_recode(favor_use, `Very unfavorable` = '-3', `Somewhat unfavorable` = '-2', `Slightly unfavorable` = '-1', `Neither unfavorable nor favorable` = '0', `Slightly favorable` = '1', `Somewhat favorable` = '2', `Very favorable`= '3')) %>% 
                    select(favor_use, discipline_collapsed, ResponseId) %>% 
                    filter(!is.na(discipline_collapsed) & discipline_collapsed != 'Other') %>%
                    pivot_wider(names_from = discipline_collapsed, values_from = favor_use, id_cols = ResponseId) %>%
                    select(-ResponseId)

plot(likert(as.data.frame(discipline_favor)))
  

# use/submissions of preprints by academic career stage
survey_data %>%
  mutate(preprints_used = fct_rev(preprints_used)) %>%
  group_by(acad_career_stage, preprints_used) %>%
  tally() %>%
  mutate(perc = round(100*n/sum(n),2)) %>%
  filter(!is.na(preprints_used), acad_career_stage != '(Missing)', preprints_used != 'Not sure') %>%
  ggplot(aes(fill = preprints_used, x = acad_career_stage, y = perc)) +
  geom_col(position = 'dodge') +
  coord_flip() +
  guides(fill = guide_legend(reverse = TRUE)) +
  scale_fill_manual(values = wes_palette("IsleofDogs2"))

survey_data %>%
  mutate(preprints_submitted = fct_rev(preprints_submitted)) %>%
  group_by(acad_career_stage, preprints_submitted) %>%
  tally() %>%
  mutate(perc = round(100*n/sum(n),2)) %>%
  filter(!is.na(preprints_submitted), acad_career_stage != '(Missing)', preprints_submitted != 'Not sure') %>%
  ggplot(aes(fill = preprints_submitted, x = acad_career_stage, y = perc)) +
  geom_col(position = 'dodge') +
  geom_text(aes(label = perc), size = 4, position = position_dodge(width = 1), hjust= -.1) +
  coord_flip() +
  guides(fill = guide_legend(reverse = TRUE)) +
  scale_fill_manual(values = wes_palette("IsleofDogs2"))


# favor-use by career stage
career_stage <- survey_data %>% 
  mutate(favor_use = as.factor(favor_use),
         favor_use = fct_recode(favor_use, `Very unfavorable` = '-3', `Somewhat unfavorable` = '-2', `Slightly unfavorable` = '-1', `Neither unfavorable nor favorable` = '0', `Slightly favorable` = '1', `Somewhat favorable` = '2', `Very favorable`= '3')) %>% 
  select(favor_use, acad_career_stage, ResponseId) %>% 
  filter(!is.na(acad_career_stage)) %>%
  pivot_wider(names_from = acad_career_stage, values_from = favor_use, id_cols = ResponseId) %>%
  select(-ResponseId)

plot(likert(as.data.frame(career_stage)))

# correlation favor-use/use/submissions and credibility questions
correlations1 <- survey_data %>%
  select(preprints_used, preprints_submitted, starts_with('preprint_cred')) %>%
  mutate(preprints_used = as.numeric(preprints_used),
         preprints_submitted = as.numeric(preprints_submitted)) %>%
  cor(use = 'pairwise.complete.obs', method = 'spearman')

correlations2 <- survey_data %>%
  select(favor_use, starts_with('preprint_cred')) %>%
  cor(use = 'pairwise.complete.obs')

correlations <- cbind(correlations1[3:21, 1:2], correlations2[2:20, 1])

as.data.frame(correlations) %>%
  rownames_to_column('question') %>% 
  mutate(var_name = case_when(question == 'preprint_cred1_1' ~ "Author's previous work",
                              question == 'preprint_cred1_2' ~ "Author's institution",
                              question == 'preprint_cred1_3' ~ "Professional identity links",
                              question == 'preprint_cred1_4' ~ "COI disclosures",
                              question == 'preprint_cred1_5' ~ "Author's level of open scholarship",
                              question == 'preprint_cred2_1' ~ "Funders of research",
                              question == 'preprint_cred2_2' ~ "Preprint submitted to a journal",
                              question == 'preprint_cred2_3' ~ "Usage metrics",
                              question == 'preprint_cred2_4' ~ "Citations of preprints",
                              question == 'preprint_cred3_1' ~ "Anonymous comments",
                              question == 'preprint_cred3_2' ~ "Identified comments",
                              question == 'preprint_cred3_3' ~ "Simplified endorsements",
                              question == 'preprint_cred4_1' ~ "Link to study data",
                              question == 'preprint_cred4_2' ~ "Link to study analysis scripts",
                              question == 'preprint_cred4_3' ~ "Link to materials",
                              question == 'preprint_cred4_4' ~ "Link to pre-reg",
                              question == 'preprint_cred5_1' ~ "Info about indep groups accessing linked info",
                              question == 'preprint_cred5_2' ~ "Info about indep group reproductions",
                              question == 'preprint_cred5_3' ~ "Info about indep robustness checks",
                              TRUE ~ 'Courtney missed a variable')) %>%
  select(-question) %>%
  gt(rowname_col = 'var_name') %>%
  fmt_number(everything(), decimals = 2) %>%
  data_color(
    columns = vars(V3,preprints_used,preprints_submitted),
    colors = scales::col_numeric(
      palette = paletteer::paletteer_d(
        package = "RColorBrewer",
        palette = "BrBG"
      ),
      domain = c(-1, 1))
  ) %>%
  cols_label(
    V3 = 'Favor use',
    preprints_used = 'View/Downloaded Preprints',
    preprints_submitted = 'Submitted Preprints'
  ) %>%
  cols_align(align = 'center')
  
  
  


