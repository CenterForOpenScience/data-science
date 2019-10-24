##required libraries
library(osfr)
library(tidyverse)
library(here)
library(psych)
library(MOTE)
library(lmerTest)
library(lavaan)
library(semTools)

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
                mutate(hdi_level = fct_relevel(hdi_level, c('low', 'medium', 'high', 'very high')),
                       preprints_used = fct_relevel(preprints_used, c('Not sure', 'No', 'Yes, once', 'Yes, a few times', 'Yes, many times')),
                       preprints_submitted = fct_relevel(preprints_submitted, c('Not sure', 'No', 'Yes, once', 'Yes, a few times', 'Yes, many times')),
                       familiar = fct_relevel(familiar, c('Not familiar at all', 'Slightly familiar', 'Moderately familiar', 'Very familiar', 'Extremely familiar')),
                       acad_career_stage = fct_relevel(acad_career_stage, c('Grad Student', 'Post doc', 'Assist Prof', 'Assoc Prof', 'Full Prof'))) %>%
                mutate(hdi_level = fct_explicit_na(hdi_level, '(Missing)'),
                       preprints_used = fct_explicit_na(preprints_used, '(Missing)'),
                       preprints_submitted = fct_explicit_na(preprints_submitted, '(Missing)'),
                       familiar = fct_explicit_na(familiar, '(Missing)'),
                       acad_career_stage = fct_explicit_na(acad_career_stage, '(Missing)'),
                       discipline_collapsed = fct_explicit_na(discipline_collapsed, '(Missing)'))

#### basic sample characteristics ####

# total sample
nrow(survey_data)

# familiarity level of sample
survey_data %>% 
  group_by(familiar) %>% 
  tally()

# favorability level of sample
survey_data %>% 
  group_by(favor_use) %>% 
  tally()

100*sum(survey_data$favor_use < 0, na.rm = T)/nrow(survey_data) #percentage unfavorable
100*sum(survey_data$favor_use == 0, na.rm = T)/nrow(survey_data) #percentage neutral
100*sum(survey_data$favor_use > 0, na.rm = T)/nrow(survey_data) #percentage favorable

# preprint usage
survey_data %>% 
  group_by(preprints_submitted) %>% 
  tally()

survey_data %>% 
  group_by(preprints_used) %>% 
  tally()

# demographics #
survey_data %>% 
  group_by(acad_career_stage) %>% 
  tally()

survey_data %>% 
  group_by(discipline_collapsed) %>% 
  tally()

survey_data %>% 
  group_by(hdi_level) %>% 
  tally()

survey_data %>% 
  group_by(continent) %>% 
  tally() %>%
  arrange(desc(n))

survey_data %>% 
  filter(continent == 'North America') %>%
  group_by(country) %>% 
  tally() %>%
  arrange(desc(n))

survey_data %>% 
  filter(continent == 'Europe') %>%
  group_by(country) %>% 
  tally() %>%
  arrange(desc(n))

#### correlates of favorability ####
r_and_cis <- survey_data %>%
  select(starts_with('preprint_cred'), favor_use) %>%
  corr.test(adjust = 'none')

r_and_cis$ci %>%
  rownames_to_column(var = 'correlation') %>%
  filter(grepl('fvr_s', correlation)) %>%
  column_to_rownames('correlation') %>%
  select(-p) %>%
  round(digits = 2)


#### exploratory factor analysis ####

credibilty_qs <- survey_data %>%
  dplyr::select(ResponseId,starts_with('preprint_cred')) %>%
  column_to_rownames('ResponseId')

fa.parallel(credibilty_qs)

fa6 <- fa(credibilty_qs, nfactors = 6, rotate = 'oblimin') 
fa6
fa.diagram(fa6)

fa5 <- fa(credibilty_qs, nfactors = 5, rotate = 'oblimin') 
fa5
fa.diagram(fa5)

fa3 <- fa(credibilty_qs, nfactors = 3, rotate = 'oblimin') 
fa3
fa.diagram(fa3)


#### by academic position analysis ####

credibility_data_long <- survey_data %>%
  dplyr::select(ResponseId, starts_with('preprint_cred'), discipline_collapsed, acad_career_stage) %>%
  drop_na() %>%
  pivot_longer(cols = starts_with('preprint_cred'), names_to = 'question', values_to = 'response') %>%
  mutate(question = as.factor(question))

# magnitude of between position vs. between Q differences

position_model <- lmer(response ~ acad_career_stage + question + acad_career_stage:question + (1|ResponseId), credibility_data_long)
anova_output <- anova(position_model)

academic_gespartial <- ges.partial.SS.mix(dfm = anova_output[1, 3], dfe = anova_output[1, 4], ssm = anova_output[1, 1], sss = (anova_output[1, 1] * anova_output[1, 4])/(anova_output[1, 3] * anova_output[1, 5]), sse = (anova_output[2, 1] * anova_output[2, 4])/(anova_output[2, 3] * anova_output[2, 5]), Fvalue = anova_output[1, 5], a = .05)
question_gespartial <- ges.partial.SS.mix(dfm = anova_output[2, 3], dfe = anova_output[2, 4], ssm = anova_output[2, 1], sss = (anova_output[1, 1] * anova_output[1, 4])/(anova_output[1, 3] * anova_output[1, 5]), sse = (anova_output[2, 1] * anova_output[2, 4])/(anova_output[2, 3] * anova_output[2, 5]), Fvalue = anova_output[2, 5], a = .05)

academic_gespartial$ges
academic_gespartial$geslow
academic_gespartial$geshigh

question_gespartial$ges
question_gespartial$geslow
question_gespartial$geshigh

# measurement invariance of factor model across positions
base_model <- 'traditional =~ preprint_cred1_1 + preprint_cred1_2 + preprint_cred1_3
               open_icons =~ preprint_cred4_1 + preprint_cred4_2 + preprint_cred4_3 + preprint_cred4_4
               verifications =~ preprint_cred5_1 + preprint_cred5_2 + preprint_cred5_3
               opinions =~ preprint_cred3_1 + preprint_cred3_2 + preprint_cred3_3
               other    =~ preprint_cred1_4 + preprint_cred2_1
               usage   =~ preprint_cred2_3 + preprint_cred2_4'

fit <- cfa(base_model, data = survey_data)
summary(fit, fit.measures = T)


# by group measurement invariance
measurementInvariance(model = base_model, data = survey_data, group = 'acad_career_stage')

#### by discipline analysis ####
discipline_model <- lmer(response ~ acad_career_stage + question + acad_career_stage:question + (1|ResponseId), credibility_data_long %>% filter(discipline_collapsed != 'Other' & discipline_collapsed != 'Engineering'))
anova_output <- anova(discipline_model)


discipline_gespartial <- ges.partial.SS.mix(dfm = anova_output[1, 3], dfe = anova_output[1, 4], ssm = anova_output[1, 1], sss = (anova_output[1, 1] * anova_output[1, 4])/(anova_output[1, 3] * anova_output[1, 5]), sse = (anova_output[2, 1] * anova_output[2, 4])/(anova_output[2, 3] * anova_output[2, 5]), Fvalue = anova_output[1, 5], a = .05)
question_gespartial <- ges.partial.SS.mix(dfm = anova_output[2, 3], dfe = anova_output[2, 4], ssm = anova_output[2, 1], sss = (anova_output[1, 1] * anova_output[1, 4])/(anova_output[1, 3] * anova_output[1, 5]), sse = (anova_output[2, 1] * anova_output[2, 4])/(anova_output[2, 3] * anova_output[2, 5]), Fvalue = anova_output[2, 5], a = .05)


discipline_gespartial$ges
discipline_gespartial$geslow
discipline_gespartial$geshigh

question_gespartial$ges
question_gespartial$geslow
question_gespartial$geshigh


# by group measurement invariance
measurementInvariance(model = base_model, data = survey_data, group = 'discipline_collapsed')
