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

colnames(preprint_cred) <- c(preprint_cred1_1 = "Information about an author's previous work",
                             preprint_cred1_2 = "Institutional information of the author(s)",
                             preprint_cred1_3 = "Links to author’s professional identities through services such as ORCID or Google Scholar",
                             preprint_cred1_4 = "Disclosure statement about conflicts of interest for the author(s)",
                             preprint_cred1_5 = "Information showing author(s) general levels of transparency and open scholarship (e.g., frequency of data sharing)",
                             preprint_cred2_1 = "Information about the funder(s) of the research",
                             preprint_cred2_2 = "Indication of whether the preprint has been submitted to a journal",
                             preprint_cred2_3 = "Usage metrics about the preprint (e.g., views, downloads, media mentions)",
                             preprint_cred2_4 = "Citations of the preprint in other research papers, policy briefs, or other reports",
                             preprintcred3_1 = "Information about anonymous users’ thoughts about the preprint (e.g. comments)",
                             preprintcred3_2 = "Information about identified users’ thoughts about the preprint (e.g. comments)",
                             preprintcred3_3 = "Information about endorsements by independent users in a simplified format (e.g. thumbs-up/thumbs-down on the preprint)",
                             preprint_cred4_1 = "Links to any available study data provided by the author(s)",
                             preprint_cred4_2 = "Links to any available analysis scripts/code/files provided by the author(s)",
                             preprint_cred4_3 = "Links to any available research materials provided by the author(s)",
                             preprint_cred4_4 = "Links to any pre-registrations or pre-analysis plans for the reported studies provided by the author(s)",
                             preprint_cred5_1 = "Information about whether independent groups (e.g. non-authors, preprint services) could access the linked data, code, or materials",
                             preprint_cred5_2 = "Information about whether independent groups could reproduce the reported findings",
                             preprint_cred5_3 = "Information about whether independent groups found that the findings were robust to variations in the statistical models (e.g., different covariates or exclusion rules)")

preprint_cred <- preprint_cred %>%
  mutate_all(factor, levels=1:5, labels=choices, ordered=TRUE)

cred_preprints<- expression(atop("When assessing the credibility of a preprint", paste("how important would it be to have each of the following pieces of information?")))
pdf("icon_cred.pdf", width=12.5, height=10)
plot(likert(as.data.frame(preprint_cred)), ordered=T) + 
  ggtitle(cred_preprints)+
  theme(plot.title = element_text(hjust = 0.5), legend.title = element_blank())
dev.off()


## Overall service credibilitys

service_cred <- survey_data %>%
  select(services_cred1_1:service_credible4_5)

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



