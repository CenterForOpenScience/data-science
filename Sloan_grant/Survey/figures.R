## required libraries
library(osfr)
library(tidyverse)
library(likert)
library(here)

## reading in data
osf_retrieve_file("https://osf.io/86upq/") %>% 
  osf_download(overwrite = T)

survey_data <- read_csv(here::here('cleaned_data.csv'), col_types = cols(.default = col_number(),
                                                                         ResponseId = col_character(),
                                                                         position_7_TEXT = col_character(), 
                                                                         familiar = col_factor(),
                                                                         favor_use = col_factor(),
                                                                         preprints_submitted = col_factor(),
                                                                         preprints_used = col_factor(),
                                                                         position = col_factor(),
                                                                         acad_career_stage = col_factor(),
                                                                         country = col_factor(),
                                                                         discipline = col_character(),
                                                                         discipline_specific = col_character(),
                                                                         discipline_other = col_character(),
                                                                         bepress_tier1 = col_character(),
                                                                         bepress_tier2 = col_character(),
                                                                         bepress_tier3 = col_character(),
                                                                         how_heard = col_character(),
                                                                         hdi_level = col_character(),
                                                                         UserLanguage = col_character(),
                                                                         DistributionChannel = col_character()))

## Overall icons importance
preprint_cred <- survey_data %>%
  select(preprint_cred1_1:preprint_cred5_3)

choices  <- c('Not at all important', 'Slightly important', 'Moderately important', 'Very important', 'Extremely important')

colnames(preprint_cred) <- c(preprint_cred1_1 = "Author's previous work",
                             preprint_cred1_2 = "Author's institution",
                             preprint_cred1_3 = "Professional identity links",
                             preprint_cred1_4 = "COI disclosures",
                             preprint_cred1_5 = "Author's level of open scholarship",
                             preprint_cred2_1 = "Funders of research",
                             preprint_cred2_2 = "Preprint submitted to a journal",
                             preprint_cred2_3 = "Usage metrics",
                             preprint_cred2_4 = "Citations of preprints",
                             preprintcred3_1 = "Anonymous comments",
                             preprintcred3_2 = "Identified comments",
                             preprintcred3_3 = "Simplified endorsements",
                             preprint_cred4_1 = "Link to study data",
                             preprint_cred4_2 = "Link to study analysis scripts",
                             preprint_cred4_3 = "Link to materials",
                             preprint_cred4_4 = "Link to pre-reg",
                             preprint_cred5_1 = "Info about indep groups accessing linked info",
                             preprint_cred5_2 = "Info about indep group reproductions",
                             preprint_cred5_3 = "Info about indep robustness checks")

preprint_cred <- preprint_cred %>%
  mutate_all(factor, levels=1:5, labels=choices, ordered=TRUE)

cred_preprints<- expression(atop("When assessing the credibility of a preprint", paste("how important would it be to have each of the following pieces of information?")))
pdf("icon_cred.pdf", width=12.5, height=10)
plot(likert(as.data.frame(preprint_cred)), ordered=T, text.size = 4) + 
  ggtitle(cred_preprints)+
  theme(plot.title = element_text(hjust = 0.5, size = 16), axis.text = element_text(size = 12), legend.title = element_blank(), legend.text=element_text(size=10))
dev.off()


## Overall service credibilitys