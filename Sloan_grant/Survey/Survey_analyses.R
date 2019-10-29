##required libraries
library(osfr)
library(tidyverse)
library(here)
library(psych)
library(MOTE)
library(lmerTest)
library(lavaan)
library(semTools)
library(broom)
library(tidyLPA)
library(semPlot)

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
                       preprints_used = recode_factor(preprints_used, `Not sure` = NA_character_),
                       preprints_used = fct_relevel(preprints_used, c('No', 'Yes, once', 'Yes, a few times', 'Yes, many times')),
                       preprints_submitted = recode_factor(preprints_submitted, `Not sure` = NA_character_),
                       preprints_submitted = fct_relevel(preprints_submitted, c('No', 'Yes, once', 'Yes, a few times', 'Yes, many times')),
                       familiar = fct_relevel(familiar, c('Not familiar at all', 'Slightly familiar', 'Moderately familiar', 'Very familiar', 'Extremely familiar')),
                       acad_career_stage = fct_relevel(acad_career_stage, c('Grad Student', 'Post doc', 'Assist Prof', 'Assoc Prof', 'Full Prof'))) %>%
                mutate(hdi_level = fct_explicit_na(hdi_level, '(Missing)'),
                       familiar = fct_explicit_na(familiar, '(Missing)'),
                       discipline_collapsed = fct_explicit_na(discipline_collapsed, '(Missing)'))

#### basic sample characteristics ####

# total sample
nrow(survey_data)

# attrition rate
test <- survey_data %>%
  select(starts_with('preprint_cred'), starts_with('service')) %>%
  mutate(missing_var = rowSums(is.na(.)))

survey_data %>%
  pivot_longer(-ResponseId, names_to = 'question', values_to = 'response')

# familiarity level of sample
survey_data %>% 
  group_by(familiar) %>% 
  tally()


100*sum(survey_data$familiar == 'Extremely familiar' | survey_data$familiar == 'Very familiar', na.rm = T)/nrow(survey_data) #percentage familiar
100*sum(survey_data$familiar == 'Not familiar at all', na.rm = T)/nrow(survey_data) #percentage unfamiliar

# favorability level of sample
survey_data %>% 
  group_by(favor_use) %>% 
  tally()

100*sum(survey_data$favor_use < 0, na.rm = T)/nrow(survey_data) #percentage unfavorable
100*sum(survey_data$favor_use == 0, na.rm = T)/nrow(survey_data) #percentage neutral
100*sum(survey_data$favor_use > 0, na.rm = T)/nrow(survey_data) #percentage favorable

# preprint usage
100* sum(survey_data$preprints_used == 'Yes, many times' | survey_data$preprints_used == 'Yes, a few times' | survey_data$preprints_submitted == 'Yes, many times' | survey_data$preprints_submitted == 'Yes, a few times', na.rm = T)/nrow(survey_data)

survey_data %>% 
  group_by(preprints_submitted) %>% 
  tally()

survey_data %>% 
  group_by(preprints_used) %>% 
  tally()

100*sum(survey_data$preprints_used == 'Yes, many times' | survey_data$preprints_used == 'Yes, a few times' , na.rm = T)/nrow(survey_data) #percentage unfamiliar
100*sum(survey_data$preprints_submitted == 'Yes, many times' | survey_data$preprints_submitted == 'Yes, a few times' , na.rm = T)/nrow(survey_data) #percentage unfamiliar

# demographics #
survey_data %>% 
  group_by(acad_career_stage) %>% 
  tally()

100*sum(survey_data$acad_career_stage == 'Grad Student' | survey_data$acad_career_stage == 'Post doc' , na.rm = T)/nrow(survey_data) #percentage unfamiliar
100*sum(grepl('Prof', survey_data$acad_career_stage))/nrow(survey_data) #percentage unfamiliar
100*sum(is.na(survey_data$acad_career_stage))/nrow(survey_data) #percentage unfamiliar


survey_data %>% 
  group_by(bepress_tier1) %>%
  summarize(n = n(), percentage = 100*n/nrow(survey_data))

100*sum(survey_data$discipline_collapsed == 'Psychology', na.rm = T)/sum(survey_data$bepress_tier1 == 'Social and Behavioral Sciences', na.rm = T)

# country related variables
survey_data %>% 
  group_by(hdi_level) %>% 
  summarize(n = n(), percentage = 100*n/nrow(survey_data))

survey_data %>% 
  group_by(continent) %>% 
  summarize(n = n(), percentage = 100*n/nrow(survey_data)) %>%
  arrange(desc(n))

survey_data %>% 
  filter(continent == 'North America') %>%
  group_by(country) %>% 
  summarize(n = n(), percentage = 100*n/nrow(survey_data)) %>%
  arrange(desc(n))

#### correlates of favorability ####
r_and_cis <- survey_data %>%
  select(starts_with('preprint_cred'), favor_use) %>%
  corr.test(adjust = 'none')

r_and_cis$ci %>%
  rownames_to_column(var = 'correlation') %>%
  filter(grepl('fvr_s', correlation)) %>%
  select(-p) %>%
  column_to_rownames('correlation') %>%
  round(digits = 2) %>%
  rownames_to_column(var = 'correlation') %>%
  arrange(r)

# does favoring use correlate with use and/or submission?
rcis_favor_use <- survey_data %>%
  mutate(preprints_used = as.numeric(preprints_used)-1,
         preprints_submitted = as.numeric(preprints_submitted)-1) %>%
  select(preprints_used, preprints_submitted, favor_use) %>%
  corr.test(adjust = 'none', method = 'spearman')

#### correlates of preprint use/submission ####
r_and_cis_used <- survey_data %>% 
  mutate(preprints_used = as.numeric(preprints_used)) %>%
  select(starts_with('preprint_cred'), preprints_used) %>%
  corr.test(adjust = 'none', method = 'spearman')

r_and_cis_used$ci %>%
  rownames_to_column(var = 'correlation') %>%
  filter(grepl('prpr', correlation)) %>%
  select(-p) %>%
  column_to_rownames('correlation') %>%
  round(digits = 2) %>%
  rownames_to_column(var = 'correlation') %>%
  arrange(r)

r_and_cis_submitted <- survey_data %>% 
  mutate(preprints_submitted = as.numeric(preprints_submitted)) %>%
  select(starts_with('preprint_cred'), preprints_submitted) %>%
  corr.test(adjust = 'none', method = 'spearman')

r_and_cis_submitted$ci %>%
  rownames_to_column(var = 'correlation') %>%
  filter(grepl('prpr', correlation)) %>%
  select(-p) %>%
  column_to_rownames('correlation') %>%
  round(digits = 2) %>%
  rownames_to_column(var = 'correlation') %>%
  arrange(r)

backward_diff <- matrix(c(-3/4, 1/4, 1/4, 1/4,
                           -1/2, -1/2, 1/2, 1/2,
                            -1/4, -1/4, -1/4, 3/4), ncol = 3)

contrasts(survey_data$preprints_used) <- backward_diff
contrasts(survey_data$preprints_submitted) <- backward_diff

regression_fun <- function(question) {
  form <- paste(question, "~ favor_use + preprints_used + preprints_submitted")
  lm(as.formula(form), data = survey_data)
}

vars <- names(survey_data)[6:24]

models <- vars %>%
            set_names() %>%
            map(regression_fun)

model_parameters <- map_dfr(models, tidy, conf.int = T, .id = "variable")


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

fa2 <- fa(credibilty_qs, nfactors = 2, rotate = 'oblimin') 
fa2
fa.diagram(fa2)

# create factor variables
survey_data <- survey_data %>%
                rowwise() %>%
                mutate(fct1 = mean(c(preprint_cred4_2, preprint_cred4_1, preprint_cred4_3, preprint_cred4_4), na.rm = T),
                       fct2 = mean(c(preprint_cred5_2, preprint_cred5_3, preprint_cred5_1), na.rm = T),
                       fct3 = mean(c(preprint_cred3_1, preprint_cred3_2, preprint_cred3_3), na.rm = T),
                       fct4 = mean(c(preprint_cred1_4, preprint_cred2_1), na.rm = T),
                       fct5 = mean(c(preprint_cred2_3, preprint_cred2_4), na.rm = T),
                       fct6 = mean(c(preprint_cred1_2, preprint_cred1_1, preprint_cred1_3), na.rm = T))


#### SEM model of favorability on 6 factors ####
sem_data <- survey_data %>%
              mutate(preprints_used = as.numeric(preprints_used) - 1,
                     preprints_submitted = as.numeric(preprints_submitted) - 1)

favor_use_model <- 'traditional =~ preprint_cred1_1 + preprint_cred1_2 + preprint_cred1_3
               open_icons =~ preprint_cred4_1 + preprint_cred4_2 + preprint_cred4_3 + preprint_cred4_4
               verifications =~ preprint_cred5_1 + preprint_cred5_2 + preprint_cred5_3
               opinions =~ preprint_cred3_1 + preprint_cred3_2 + preprint_cred3_3
               other    =~ preprint_cred1_4 + preprint_cred2_1
               usage   =~ preprint_cred2_3 + preprint_cred2_4

traditional ~ favor_use + preprints_used + preprints_submitted
open_icons ~ favor_use + preprints_used + preprints_submitted
verifications ~ favor_use + preprints_used + preprints_submitted
opinions ~ favor_use + preprints_used + preprints_submitted
other ~ favor_use + preprints_used + preprints_submitted
usage ~ favor_use + preprints_used + preprints_submitted'

favoruse_fit <- cfa(favor_use_model, sem_data)
summary(favoruse_fit, fit.measures=TRUE)

parameterEstimates(favoruse_fit, ci = T, level = .95, standardized = T) %>%
  filter(op == '~')

semPaths(favoruse_fit)
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

# sem model 

backward_diff <- matrix(c(-4/5, 1/5, 1/5, 1/5, 1/5,
                          -3/5, -3/5, 2/5, 2/5, 2/5,
                          -2/5, -2/5, -2/5, 3/5, 3/5,
                          -1/5, -1/5, -1/5, -1/5, 4/5), ncol = 4)

contrasts(sem_data$acad_career_stage) <- backward_diff

career_model <- 'traditional =~ preprint_cred1_1 + preprint_cred1_2 + preprint_cred1_3
               open_icons =~ preprint_cred4_1 + preprint_cred4_2 + preprint_cred4_3 + preprint_cred4_4
               verifications =~ preprint_cred5_1 + preprint_cred5_2 + preprint_cred5_3
               opinions =~ preprint_cred3_1 + preprint_cred3_2 + preprint_cred3_3
               other    =~ preprint_cred1_4 + preprint_cred2_1
               usage   =~ preprint_cred2_3 + preprint_cred2_4

traditional ~ acad_career_stage
open_icons ~ acad_career_stage
verifications ~ acad_career_stage
opinions ~ acad_career_stage
other ~ acad_career_stage
usage ~ acad_career_stage'

career_fit <- cfa(career_model, sem_data)
summary(career_fit, fit.measures=TRUE)

parameterEstimates(career_fit, ci = T, level = .95, standardized = T) %>%
  filter(op == '~')

# by group measurement invariance
position_models <- cfa(model = base_model, data = survey_data, group = 'acad_career_stage')
summary(position_models, fit.measures = T)

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
discipline_models <- cfa(model = base_model, data = survey_data %>% filter(discipline_collapsed != 'Other' & discipline_collapsed != 'Engineering'), group = 'discipline_collapsed')
summary(discipline_models , fit.measures = T)

measurementInvariance(model = base_model, data = survey_data %>% filter(discipline_collapsed != 'Other' & discipline_collapsed != 'Engineering'), group = 'discipline_collapsed')


##LPA models
items_scores_test <- survey_data %>%
  select(starts_with('preprint_cred')) %>%
  single_imputation() %>%
  estimate_profiles(1:8,
                    variances = c("equal", "varying", "equal", "varying"),
                    covariances = c("zero", "zero", "equal", "varying")) %>%
  compare_solutions(statistics = c("AIC", "BIC"))

items_37 <- survey_data %>%
  select(starts_with('preprint_cred')) %>%
  single_imputation() %>%
  estimate_profiles(7,
                    variances = c("equal"),
                    covariances = c("equal"))

items_37 %>% plot_profiles()

factor_scores_test <- survey_data %>%
  select(starts_with('fct')) %>%
  single_imputation() %>%
  estimate_profiles(1:8,
                    variances = c("equal", "varying", "equal", "varying"),
                    covariances = c("zero", "zero", "equal", "varying")) %>%
  compare_solutions(statistics = c("AIC", "BIC"))

factor_62 <- survey_data %>%
  select(starts_with('fct')) %>%
  single_imputation() %>%
  estimate_profiles(2,
                    variances = c("varying"),
                    covariances = c("varying"))

factor_38 <- survey_data %>%
  select(starts_with('fct')) %>%
  single_imputation() %>%
  estimate_profiles(8,
                    variances = c("equal"),
                    covariances = c("equal"))

factor_38 %>% plot_profiles()
