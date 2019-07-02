library(tidyverse)
library(lubridate)
library(here)
library(osfr)

###importing data

osf_retrieve_file("https://osf.io/q4zf8/") %>% 
  osf_download(overwrite = T)

survey_data_choices <- read_csv(here('choice_data.csv'), col_types = cols(.default = col_factor(),
                                                                 ResponseId = col_character(),
                                                                 position_7_TEXT = col_character(), 
                                                                 discipline = col_character(),
                                                                 discipline_specific = col_character(),
                                                                 discipline_other = col_character(),
                                                                 how_heard = col_character())) %>%
                            select(ResponseId, familiar, favor_use, preprints_submitted, preprints_used, position, discipline, country)

osf_retrieve_file("https://osf.io/xnbhu/") %>% 
  osf_download(overwrite = T)

survey_data_numeric <- read_csv(here('numeric_data.csv')) %>%
                            select(-c(familiar, favor_use, preprints_submitted, preprints_used, position, discipline, country))

osf_retrieve_file("https://osf.io/7ery8/") %>% 
  osf_download(overwrite = T)

hdi_data <- read_csv(here('hdi_2017_data.csv'), col_types =cols(country = col_factor(), HDI_2017 = col_number())) %>% 
                            select(country, HDI_2017)

### merging data and recoding favor levels
survey_data <- left_join(survey_data_numeric, survey_data_choices, by = 'ResponseId') %>%
                    mutate(familiar = fct_rev(familiar), 
                           favor_use = fct_relevel(favor_use, c('Very much oppose', 'Moderately oppose', 'Slightly oppose', 'Neither oppose nor favor', 'Slightly favor', 'Moderately favor', 'Very much favor')),
                           preprints_used = fct_relevel(preprints_used, c('No', 'Yes, once', 'Yes, a few times', 'Yes, many times', 'Not sure')),
                           preprints_submitted = fct_relevel(preprints_submitted, c('No', 'Yes, once', 'Yes, a few times', 'Yes, many times', 'Not sure'))) 

hdi_data <- hdi_data %>%
  mutate(hdi_level = case_when(HDI_2017 >= .8 ~ 'very high',
                               HDI_2017 < .8 & HDI_2017 >= .7 ~ 'high',
                               HDI_2017 < .7 & HDI_2017 >= .555 ~ 'medium',
                               HDI_2017 < .555 ~ 'low',
                               TRUE ~ NA_character_))

survey_data <- left_join(survey_data, hdi_data, by = 'country')

## bepress tier 2 recoding

## psychophysiology; Public health infectious diseases; public health and social work; Public health & medical anthropology; Health research (epidemiology, psychology, biomedicine)



survey_data <- survey_data %>% 
  mutate(bepress_tier2 = case_when(grepl('My example is not typical', discipline_other, ignore.case = TRUE) | grepl('Digital Humanities, Editing', discipline_other, ignore.case = TRUE) | 
                                        grepl('Dentistry, psychiatry, neuroscience', discipline_other) | grepl('Bioinformatics/Computational Biology', discipline_other) | 
                                        grepl('Genetics, bioinformatics', discipline_other) | grepl('Computer Science and', discipline_other)  | grepl('Interdisciplinary Social/Ecological Systems', discipline_other) |
                                        grepl('Geography/ Science and Technology Studies', discipline_other) | grepl('Nursing and Economics', discipline_other) | 
                                        grepl('Veterinary Epidemiology and Public Health', discipline_other) | grepl('Public Health; Health Services Research; Health Policy Analysis', discipline_other) | 
                                        grepl('Dentistry, Anatomy', discipline_other) ~ NA_character_,
                                   grepl('medicine and biophysics', discipline) ~ 'Medical biophysics',
                                   grepl('Health economics', discipline_other) ~ 'Economics',
                                   grepl('Accounting', discipline_other) ~ 'Accounting',
                                   grepl('Anatomy', discipline_other) ~ 'Anatomy',
                                   grepl('Public health & medical anthropology', discipline_other) ~ 'Public Health',
                                   grepl('Anthropology', discipline_other, ignore.case = TRUE) |  grepl('archaeology', discipline_other, ignore.case = TRUE) ~ 'Anthropology',
                                   grepl('linguistic', discipline_other, ignore.case = TRUE) | grepl('applied linguistics', discipline_specific, ignore.case = TRUE) ~ 'Linguistics',
                                   grepl('Astronomy', discipline_other, ignore.case = TRUE) | grepl('astrophysics', discipline_other, ignore.case = TRUE) | grepl('cosmology', discipline_other) ~ 'Astrophysics and Astronomy',
                                   grepl('biochemistry', discipline_other, ignore.case = TRUE) | grepl('biophysics', discipline_other) ~ 'Biochemistry, Biophysics, and Structural Biology',
                                   grepl('bioethics', discipline_other, ignore.case = TRUE) | grepl('Biomedical ethics', discipline_other) ~ 'Bioethics and Medical Ethics',
                                   grepl('bioinformatics', discipline_other, ignore.case = TRUE) ~ 'Bioinformatics',
                                   grepl('Biomedical Engineering', discipline_other) ~ 'Biomedical Engineering and Bioengineering',
                                   grepl('Biotechnology', discipline_other) ~ 'Biotechnology',
                                   grepl('classics', discipline_other) ~ 'Classics',
                                   grepl('cognition', discipline_other) | grepl('Psychology', discipline) ~ 'Psychology',
                                   grepl('computer scien', discipline_other, ignore.case = TRUE) | grepl('computerscience', discipline_other, ignore.case = TRUE) ~ 'Computer Sciences',
                                   grepl('computational biology', discipline_other, ignore.case = TRUE) ~ 'Genetics and Genomics',
                                   grepl('communication', discipline_other, ignore.case = TRUE) ~ 'Communication',
                                   grepl('Couple and family therapy', discipline_other) ~ 'Mental and Social Health',
                                   grepl('criminology', discipline_other, ignore.case = TRUE) ~ 'Sociology',
                                   grepl('dentistry', discipline_other, ignore.case = TRUE) ~ 'Dentistry',
                                   grepl('environmental science', discipline_other, ignore.case = TRUE) | grepl('Enviromental Science', discipline_other, ignore.case = TRUE) | 
                                      grepl('Sustainability', discipline_other) | grepl('nature conservation', discipline_other)~ 'Environmental Sciences',
                                   grepl('Educaci', discipline_other, ignore.case = TRUE) | grepl('Special Educatio', discipline_other) ~ 'Special Education and Teaching',
                                   grepl('educational technol', discipline_other, ignore.case = TRUE) ~ 'Educational Technology',
                                   grepl('science education', discipline_other, ignore.case = TRUE) ~ 'Science and Mathematics Education',
                                   grepl('Education Policy', discipline_other) ~ 'Public Affairs, Public Policy and Public Administration',
                                   grepl('language', discipline_other, ignore.case = TRUE) | grepl('arabic education', discipline_other, ignore.case = TRUE) | 
                                        grepl('english education', discipline_other, ignore.case = TRUE) ~ 'Language and Literacy Education',
                                   grepl('Medical Education', discipline_other, ignore.case = TRUE) ~ 'Medical Education',
                                   grepl('Musicology', discipline_other) ~ 'Music',
                                   grepl('physical education', discipline_other, ignore.case = TRUE) ~ 'Health and Physical Education',
                                   grepl('education', discipline_other, ignore.case = TRUE) ~ NA_character_,
                                   grepl('history', discipline_other, ignore.case = TRUE) ~ 'History',
                                   grepl('immunology', discipline_other, ignore.case = TRUE) ~ 'Immunology and Infectious Disease',
                                   grepl('Library science', discipline_other, ignore.case = TRUE) | grepl('Information Science', discipline_other)~ 'Library and Information Science',
                                   grepl('ethics of medicine', discipline_other) ~ 'Bioethics and Medical Ethics',
                                   grepl('neuroscience', discipline_other, ignore.case = TRUE) ~ 'Neuroscience and Neurobiology',
                                   grepl('epidemiology', discipline_other, ignore.case = TRUE) | grepl('public health', discipline_other, ignore.case = TRUE) |
                                     grepl('Publi health', discipline_other) ~ 'Public Health',
                                   grepl('geography', discipline_other, ignore.case = TRUE) ~ 'Geography',
                                   grepl('marketing', discipline_other, ignore.case = TRUE) ~ 'Marketing',
                                   grepl('medical microbiology', discipline_other, ignore.case = TRUE) | grepl('Physiology/Medical sciences', discipline_other) ~ 'Medical Sciences',
                                   grepl('microbiology', discipline_other, ignore.case = TRUE) | grepl('Virology', discipline_other) ~ 'Microbiology',
                                   grepl('nursing', discipline_other, ignore.case = TRUE) | grepl('midwifery', discipline_other, ignore.case = TRUE) ~ 'Nursing',
                                   grepl('parasitology', discipline_other, ignore.case = TRUE) ~ 'Immunology and Infectious Disease',
                                   grepl('public policy', discipline_other, ignore.case = TRUE) | grepl('public administration', discipline_other, ignore.case = TRUE) ~ 'Public Affairs, Public Policy and Public Administration',
                                   grepl('rehabilition', discipline_other, ignore.case = TRUE) | grepl('Physical Therapy', discipline_other) ~ 'Rehabilitation and Therapy',
                                   grepl('Science and Technology Studies', discipline_other) ~ 'Science and Technology Studies',
                                   grepl('social work', discipline_other, ignore.case = TRUE) ~ 'Social Work',
                                   grepl('sports medicine', discipline_other, ignore.case = TRUE) | grepl('preventive medicine', discipline_other) |
                                      grepl('pediat', discipline_other, ignore.case = TRUE) | grepl('Obstetrics', discipline_other) | 
                                      grepl('Neurology', discipline_other) | grepl('Urology', discipline_other) | grepl('Plastic', discipline_other) |
                                      grepl('Surgery', discipline_other) | grepl('Family Medicine', discipline_other) | grepl('Geriatrics', discipline_other) ~ 'Medical Specialties',
                                   grepl('sports science', discipline_other, ignore.case = TRUE) | grepl('sport science', discipline_other, ignore.case = TRUE) ~ 'Sports Sciences',
                                   grepl('sports management', discipline_other, ignore.case = TRUE) | grepl('sport management', discipline_other, ignore.case = TRUE)~ 'Sports Management',
                                   grepl('Systems Biology', discipline_other) ~ 'Systems Biology',
                                   grepl('physiology', discipline_other, ignore.case = TRUE) ~ 'Physiology',
                                   grepl('Philosophy', discipline_other) ~ 'Philosophy',
                                   grepl('Plant Sciences', discipline_other) ~ 'Plant Sciences',
                                   grepl('theology', discipline_other, ignore.case = TRUE) | grepl('Religious Studies', discipline_other, ignore.case = TRUE) |
                                      grepl('islamic studies', discipline_other, ignore.case = TRUE) | grepl('religion', discipline_other) ~ 'Religion',
                                   grepl('Veterinary', discipline_other, ignore.case = TRUE) ~ 'Veterinary Medicine',
                                   grepl('vision science', discipline_other, ignore.case = TRUE) ~ 'Biomedical Engineering and Bioengineering',
                                   grepl('Urban Planning', discipline_other) ~ 'Urban, Community and Regional Planning')) %>%
  select(bepress_tier2, discipline, discipline_specific, discipline_other) %>%
  arrange(bepress_tier2, discipline)

## bepress tier 1 recoding
  survey_data %>%
    mutate(bepress_tier1 = case_when(grepl('My example is not typical', discipline_other, ignore.case = TRUE) | grepl('Digital Humanities, Editing', discipline_other, ignore.case = TRUE) ~ NA_character_,
                                     grepl('computational social science', discipline_other, ignore.case = TRUE) ~ 'Social and Behavioral Sciences',
                                     grepl('humanities', discipline_other, ignore.case = TRUE) ~ 'Arts and Humanities',
                                     grepl('medicine', discipline_other, ignore.case = TRUE) | grepl('Click to write Choice 23', discipline) | grepl('Dentistry, psychiatry, neuroscience', discipline_other) | 
                                       grepl('Veterinary Epidemiology and Public Health', discipline_other) | grepl('health science', discipline_other, ignore.case = TRUE) |
                                       grepl('psychiatry', discipline_other, ignore.case = TRUE) ~ 'Medicine and Health Sciences',
                                     grepl('Marketing', bepress_tier2) ~ 'Business',
                                     grepl('education', discipline_other, ignore.case = TRUE) ~ 'Education')) %>%
    select(bepress_tier1, bepress_tier2, discipline, discipline_specific, discipline_other) %>%
    arrange(bepress_tier1, discipline, discipline_specific, discipline_other, bepress_tier2)


