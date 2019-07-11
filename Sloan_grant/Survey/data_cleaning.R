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
                           preprints_submitted = fct_relevel(preprints_submitted, c('No', 'Yes, once', 'Yes, a few times', 'Yes, many times', 'Not sure')),
                           discipline = case_when(discipline == 'Click to write Choice 23' ~ 'Medicine',
                                                  TRUE ~ discipline)) 

hdi_data <- hdi_data %>%
  mutate(hdi_level = case_when(HDI_2017 >= .8 ~ 'very high',
                               HDI_2017 < .8 & HDI_2017 >= .7 ~ 'high',
                               HDI_2017 < .7 & HDI_2017 >= .555 ~ 'medium',
                               HDI_2017 < .555 ~ 'low',
                               TRUE ~ NA_character_))

survey_data <- left_join(survey_data, hdi_data, by = 'country')
                  



## bepress tier 3 recoding
survey_data <- survey_data %>%
  mutate(bepress_tier3 = case_when((grepl('veterinary', discipline_specific, ignore.case = T) & grepl('epidemiology', discipline_specific, ignore.case = T) & discipline == 'Agricultural Science') | 
                                     (grepl('veterinary', discipline_other, ignore.case = T) & grepl('epidemiology', discipline_other, ignore.case = T)) ~ 'Veterinary Preventive Medicine, Epidemiology, and Public Health',
                                   grepl('aquaculture', discipline_specific, ignore.case = T) & discipline == 'Agricultural Science' ~ 'Aquaculture and Fisheries',
                                   grepl('economics', discipline_specific, ignore.case = T) & discipline == 'Agricultural Science' ~ 'Agricultural Economics',
                                   grepl('plant breeding', discipline_specific, ignore.case = T) & discipline == 'Agricultural Science' ~ 'Plant Breeding and Genetics',
                                   grepl('plant pathology', discipline_specific, ignore.case = T) & discipline == 'Agricultural Science' ~ 'Plant Pathology',
                                   grepl('soil', discipline_specific, ignore.case = T) & discipline == 'Agricultural Science' ~ 'Soil Science',
                                   grepl('^behavioral genetics$', discipline_specific, ignore.case = T) & discipline == 'Biology' ~ 'Other Genetics and Genomics',
                                   (grepl('^biochemistry$', discipline_specific, ignore.case = T) | discipline_specific == 'Biochemisty') & discipline == 'Biology' ~ 'Biochemistry',
                                   grepl('^biophysics$', discipline_specific, ignore.case = T) & discipline == 'Biology' ~ 'Biophysics',
                                   grepl('^cancer biology$', discipline_specific, ignore.case = T) & discipline == 'Biology' ~ 'Cancer Biology',
                                   grepl('^cell biology$', discipline_specific, ignore.case = T) & discipline == 'Biology' ~ 'Cell Biology',
                                   grepl('^computational biology$', discipline_specific, ignore.case = T) & discipline == 'Biology' ~ 'Computational Biology',
                                   grepl('^developmental biology$', discipline_specific, ignore.case = T) & discipline == 'Biology' ~ 'Developmental Biology',
                                   (grepl('^genetics$', discipline_specific, ignore.case = T) | grepl('^human genetics$', discipline_specific, ignore.case = TRUE)) & discipline == 'Biology' ~ 'Genetics',
                                   grepl('^genomics$', discipline_specific, ignore.case = T) & discipline == 'Biology' ~ 'Genomics',
                                   grepl('^molecular biology$', discipline_specific, ignore.case = T) & discipline == 'Biology' ~ 'Molecular Biology',
                                   grepl('^molecular genetics$', discipline_specific, ignore.case = T) & discipline == 'Biology' ~ 'Molecular Genetics',
                                   grepl('molecular neuroscience', discipline_specific, ignore.case = T) & discipline == 'Biology' ~ 'Molecular and Cellular Neuroscience',
                                   grepl('^parasitology$', discipline_specific, ignore.case = T) & discipline == 'Biology' ~ 'Parasitology',
                                   grepl('^pharmacology$', discipline_specific, ignore.case = T) & discipline == 'Biology' ~ 'Pharmacology',
                                   grepl('^plant biology$', discipline_specific, ignore.case = T) & discipline == 'Biology' ~ 'Plant Biology',
                                   grepl('^plant pathology$', discipline_specific, ignore.case = T) & discipline == 'Biology' ~ 'Plant Pathology',
                                   grepl('^structural biology$', discipline_specific, ignore.case = T) & discipline == 'Biology' ~ 'Structural Biology',
                                   (grepl('^virology$', discipline_specific, ignore.case = T) | discipline_specific == 'Virology and Transcription') & discipline == 'Biology' ~ 'Virology',
                                   grepl('^zoology$', discipline_specific, ignore.case = T) & discipline == 'Biology' ~ 'Zoology',
                                   (grepl('^analytical chemistry$', discipline_specific, ignore.case = T) | discipline_specific == 'clinical analytical chemistry' |
                                      discipline_specific == 'Analytical biochemistry') & discipline == 'Chemistry' ~ 'Analytical Chemistry',
                                   (grepl('bio', discipline_specific, ignore.case = T) | grepl('computational', discipline_specific, ignore.case = T)) & discipline == 'Chemistry' ~ 'Other Chemistry',
                                   grepl('^environmental chemistry', discipline_specific, ignore.case = T) & discipline == 'Chemistry' ~ 'Environmental Chemistry',
                                   grepl('inorganic', discipline_specific, ignore.case = T) & discipline == 'Chemistry' ~ 'Inorganic Chemistry',
                                   grepl('^materials chemistry$', discipline_specific, ignore.case = T) & discipline == 'Chemistry' ~ 'Materials Chemistry',
                                   grepl('^organic chemistry$', discipline_specific, ignore.case = T) & discipline == 'Chemistry' ~ 'Organic Chemistry',
                                   (grepl('pharma', discipline_specific, ignore.case = T) | grepl('drug', discipline_specific, ignore.case = T) | 
                                      grepl('clinical', discipline_specific, ignore.case = T)) & discipline == 'Chemistry' ~ 'Medicinal-Pharmaceutical Chemistry',
                                   grepl('^physical chemistry$', discipline_specific, ignore.case = T) & discipline == 'Chemistry' ~ 'Physical Chemistry',
                                   grepl('^atmospheric science$', discipline_specific, ignore.case = T) & discipline == 'Earth Science' ~ 'Atmospheric Sciences',
                                   (grepl('^climate science$', discipline_specific, ignore.case = T) | grepl('^climate modeling$', discipline_specific, ignore.case = T) |
                                      grepl('^climate sciences$', discipline_specific, ignore.case = T) | grepl('^climatology$', discipline_specific, ignore.case = T)) & discipline == 'Earth Science' ~ 'Atmospheric Sciences',
                                   grepl('^geochemistry$', discipline_specific, ignore.case = T) & discipline == 'Earth Science' ~ 'Geochemistry',
                                   grepl('^geology$', discipline_specific, ignore.case = T) | grepl('^geophysics$', discipline_specific, ignore.case = T) & discipline == 'Earth Science' ~ 'Geology',
                                   grepl('geomorphology', discipline_specific, ignore.case = T) & discipline == 'Earth Science' ~ 'Geomorphology',
                                   grepl('^hydrology', discipline_specific, ignore.case = T) & discipline == 'Earth Science' ~ 'Hydrology',
                                   grepl('^seismology$', discipline_specific, ignore.case = T) & discipline == 'Earth Science' ~ 'Geophysics and Seismology',
                                   grepl('^meteorology$', discipline_specific, ignore.case = T) & discipline == 'Earth Science' ~ 'Meteorology',
                                   (grepl('^oceanography$', discipline_specific, ignore.case = T) | grepl('^oceanograpy$', discipline_specific, ignore.case = T) ) & discipline == 'Earth Science' ~ 'Oceanography',
                                   grepl('^sedimentology$', discipline_specific, ignore.case = T) & discipline == 'Earth Science' ~ 'Sedimentology',
                                   grepl('^behavioral ecology$', discipline_specific, ignore.case = T) & discipline == 'Ecology/Evolutionary Science' |
                                     (grepl('behavioural', discipline_specific, ignore.case = T) & grepl('ecology', discipline_specific, ignore.case = T)) ~ 'Behavior and Ethology',
                                   (grepl('marine', discipline_specific, ignore.case = T) | grepl('freshwater', discipline_specific, ignore.case = T) | grepl('forest', discipline_specific, ignore.case = T)) &
                                     grepl('ecology', discipline_specific, ignore.case = T) ~ 'Terrestrial and Aquatic Ecology',
                                   grepl('^public economics', discipline_specific, ignore.case = T) & discipline == 'Economics' ~ 'Public Economics',
                                   grepl('behavioral', discipline_specific, ignore.case = T) & grepl('economics', discipline_specific, ignore.case = T) & discipline == 'Economics' ~ 'Behavioral Economics',
                                   grepl('^development', discipline_specific, ignore.case = T) & discipline == 'Economics' ~ 'Growth and Development',
                                   (grepl('energy economics', discipline_specific, ignore.case = T) | grepl('^nvironmental economics$', discipline_specific, ignore.case = T)) & discipline == 'Economics' ~ 'Other Economics',
                                   grepl('^finance$', discipline_specific, ignore.case = T) & discipline == 'Economics' ~ 'Finance',
                                   grepl('^Health economics$', discipline_specific, ignore.case = T) & discipline == 'Economics' ~ 'Finance',
                                   grepl('^international economics$', discipline_specific, ignore.case = T) & discipline == 'Economics' ~ 'International Economics',
                                   grepl('labor economics$', discipline_specific, ignore.case = T) & discipline == 'Economics' ~ 'Labor Economics',
                                   grepl('^macroeconomics$', discipline_specific, ignore.case = T) & discipline == 'Economics' ~ 'Macroeconomics',
                                   grepl('^political economy$', discipline_specific, ignore.case = T) & discipline == 'Economics' ~ 'Political Economy',
                                   grepl('^public economics$', discipline_specific, ignore.case = T) & discipline == 'Economics' ~ 'Public Economics',
                                   grepl('tissue engineering', discipline_specific, ignore.case = T) & discipline == 'Engineering' ~ 'Molecular, Cellular, and Tissue Engineering',
                                   grepl('imaging', discipline_specific, ignore.case = T) & discipline == 'Engineering' ~ 'Bioimaging and Biomedical Optics',
                                   grepl('combustion', discipline_specific, ignore.case = T) & discipline == 'Engineering' ~ 'Heat transfer, Combustion',
                                   grepl('transportation', discipline_specific, ignore.case = T) & discipline == 'Engineering' ~ 'Transportation Engineering',
                                   discipline_specific == 'Structural Engineering' ~ 'Structural Engineering',
                                   grepl('signal processing', discipline_specific, ignore.case = T) & discipline == 'Engineering' ~ 'Signal Processing',
                                   grepl('robotics', discipline_specific, ignore.case = T) & discipline == 'Engineering' ~ 'Robotics',
                                   grepl('polymer', discipline_specific, ignore.case = T) & discipline == 'Engineering' ~ 'Polymer Science',
                                   grepl('ocean engineering', discipline_specific, ignore.case = T) & discipline == 'Engineering' ~ 'Ocean Engineering',
                                   grepl('neuro', discipline_specific, ignore.case = T) & discipline == 'Engineering' ~ 'Bioelectrical and Neuroengineering',
                                   grepl('nano', discipline_specific, ignore.case = T) & discipline == 'Engineering' ~ 'Nanotechnology Fabrication',
                                   grepl('industrial', discipline_specific, ignore.case = T) & discipline == 'Engineering' ~ 'Industrial Engineering',
                                   grepl('environment', discipline_specific, ignore.case = T) & discipline == 'Engineering' ~ 'Environmental Engineering',
                                   (grepl('electrical', discipline_specific, ignore.case = T) | grepl('electrical', discipline_specific, ignore.case = T)) & discipline == 'Engineering' ~ 'Electrical and Electronics',
                                   grepl('psychology', discipline_specific, ignore.case = T) & discipline == 'Kinesiology' ~ 'Psychology of Movement',
                                   grepl('exercise science', discipline_specific, ignore.case = T) & discipline == 'Kinesiology' ~ 'Exercise Science',
                                   grepl('philosophy', discipline_specific, ignore.case = T) & discipline == 'Law' ~ 'Law and Philosophy',
                                   grepl('history', discipline_specific, ignore.case = T) & discipline == 'Law' ~ 'Legal History',
                                   grepl('constitution', discipline_specific, ignore.case = T) & discipline == 'Law' ~ 'Constitutional Law',
                                   grepl('technology', discipline_specific, ignore.case = T) & discipline == 'Law' ~ 'Science and Technology Law',
                                   grepl('education', discipline_specific, ignore.case = T) & discipline == 'Law' ~ 'Education Law',
                                   (grepl('copyright', discipline_specific, ignore.case = T) | grepl('intellectual', discipline_specific, ignore.case = T)) & discipline == 'Law' ~ 'Law and Philosophy',
                                   grepl('administrative', discipline_specific, ignore.case = T) & discipline == 'Law' ~ 'Administrative Law',
                                   grepl('scholarly communication', discipline_specific, ignore.case = T) & discipline == 'Library/Information Science' ~ 'Health Sciences and Medical Librarianship',
                                   grepl('health', discipline_specific, ignore.case = T) & discipline == 'Library/Information Science' ~ 'Partial Differential Equations',
                                   grepl('oceanography$', discipline_specific, ignore.case = T) & discipline == 'Marine Science' ~ 'Oceanography',
                                   discipline_specific == 'Algebra' ~ 'Algebra',
                                   grepl('partial differential equations', discipline_specific, ignore.case = T) & discipline == 'Mathematics' ~ 'Partial Differential Equations',
                                   grepl('probability', discipline_specific, ignore.case = T) & discipline == 'Mathematics' ~ 'Probability',
                                   grepl('geometry', discipline_specific, ignore.case = T) & discipline == 'Mathematics' ~ 'Geometry and Topology',
                                   grepl('epidemiology', discipline_specific, ignore.case = T) & discipline == 'Medicine' ~ 'Epidemiology',
                                   grepl('^ophthalmology$', discipline_specific, ignore.case = T) & discipline == 'Medicine' ~ 'Opthalmology',
                                   grepl('oncology', discipline_specific, ignore.case = T) & discipline == 'Medicine' ~ 'Oncology',
                                   grepl('neurology', discipline_specific, ignore.case = T) & discipline == 'Medicine' ~ 'Neurology',
                                   grepl('^psychiatry$', discipline_specific, ignore.case = T) & discipline == 'Medicine' ~ 'Psychriatry',
                                   grepl('neuroscience', discipline_specific, ignore.case = T) & discipline == 'Medicine' ~ 'Neurosciences',
                                   grepl('microbiology', discipline_specific, ignore.case = T) & discipline == 'Medicine' ~ 'Medical Microbiology',
                                   grepl('radiology', discipline_specific, ignore.case = T) & discipline == 'Medicine' ~ 'Radiology',
                                   grepl('^urology$', discipline_specific, ignore.case = T) & discipline == 'Medicine' ~ 'Urology',
                                   grepl('biochemistry', discipline_specific, ignore.case = T) & discipline == 'Nutritional Science' ~ 'Molecular, Genetic, and Biochemical Nutrition',
                                   grepl('biochemistrye', discipline_specific, ignore.case = T) & discipline == 'Nutritional Science' ~ 'Biochemical Phenomena, Metabolism, and Nutrition',
                                   grepl('epidemiology', discipline_specific, ignore.case = T) & discipline == 'Nutrional Science' ~ 'Nutrition Epidemiology',
                                   discipline == 'Paleontology' ~ 'Paleontology',
                                   grepl('^statistical', discipline_specific, ignore.case = T) & discipline == 'Physics' ~ 'Statistical, Nonlinear, and Soft Matter Physics',
                                   grepl('quantum', discipline_specific, ignore.case = T) & discipline == 'Physics' ~ 'Quantum Physics',
                                   grepl('optics', discipline_specific, ignore.case = T) & discipline == 'Physics' ~ 'Optics',
                                   grepl('^american politics$', discipline_specific, ignore.case = T) & discipline == 'Political Science' ~ 'American Politics',
                                   grepl('^comparative politics$', discipline_specific, ignore.case = T) & discipline == 'Political Science' ~ 'Comparative Politics',
                                   grepl('^international relations', discipline_specific, ignore.case = T) & discipline == 'Political Science' ~ 'International Relations',
                                   (grepl('^clinical psychology', discipline_specific, ignore.case = T) | grepl('^clinical$', discipline_specific, ignore.case = T) |
                                      grepl('^clinical neuropsychology$', discipline_specific, ignore.case = T)) & discipline == 'Psychology' ~ 'Clinical Psychology',
                                   grepl('^cognition$', discipline_specific, ignore.case = T) & discipline == 'Psychology' ~ 'Cognition and Perception',
                                   (grepl('^cognitive psychology', discipline_specific, ignore.case = T) | grepl('^cognitive$', discipline_specific, ignore.case = T) |
                                      (grepl('cognitive neuroscience', discipline_specific, ignore.case = T)  & !grepl('social', discipline_specific, ignore.case = T) & !grepl('development', discipline_specific, ignore.case = T))) 
                                      & discipline == 'Psychology' ~ 'Cognitive Psychology',
                                   grepl('comparative psychology', discipline_specific, ignore.case = T) & discipline == 'Psychology' ~ 'Comparative Psychology',
                                   grepl('counseling psych', discipline_specific, ignore.case = T) & discipline == 'Psychology' ~ 'Counseling Psychology',
                                   grepl('I-O psychology', discipline_specific, ignore.case = T) | grepl('I/O psychology', discipline_specific, ignore.case = T) |
                                     grepl('^Organizational', discipline_specific, ignore.case = T) ~ 'Industrial and Organizational Psychology',
                                   (grepl('forensic psychology', discipline_specific, ignore.case = T) | grepl('^political psychology$', discipline_specific, ignore.case = T))
                                      & discipline == 'Psychology' ~ 'Other Psychology',
                                   grepl('^biological psychology$', discipline_specific, ignore.case = T) & discipline == 'Psychology' ~ 'Biological Psychology',
                                   (grepl('^social psychology$', discipline_specific, ignore.case = T) | grepl('^social$', discipline_specific, ignore.case = T) |
                                      grepl('^social cognition$', discipline_specific, ignore.case = T) | grepl('^social psych$', discipline_specific, ignore.case = T) |
                                      grepl('^social neuroscience$', discipline_specific, ignore.case = T) | grepl('JDM', discipline_specific, ignore.case = T) |
                                      grepl('judgement and decision', discipline_specific, ignore.case = T) | grepl('behavioral econ', discipline_specific, ignore.case = T) |
                                      grepl('^behavioural economics$', discipline_specific, ignore.case = T)) & discipline == 'Psychology' ~ 'Social Psychology',
                                   (grepl('^developmental psychology$', discipline_specific, ignore.case = T) | grepl('^developmental$', discipline_specific, ignore.case = T)) 
                                      & discipline == 'Psychology' ~ 'Developmental Psychology',
                                   grepl('experimental analysis of behavior', discipline_specific, ignore.case = T) ~ 'Experimental Analysis of Behavior',
                                   (grepl('^quantitative psychology$', discipline_specific, ignore.case = T) | grepl('^quantitative', discipline_specific, ignore.case = T) |
                                      grepl('^psychometrics$', discipline_specific, ignore.case = T)) & discipline == 'Psychology' ~ 'Quantitative Psychology',
                                   grepl('^health psychology$', discipline_specific, ignore.case = T) & discipline == 'Psychology' ~ 'Health Psychology',
                                   (grepl('^personality psychology$', discipline_specific, ignore.case = T) | grepl('^personality$', discipline_specific, ignore.case = T)) 
                                      & discipline == 'Psychology' ~ 'Personality and Social Contexts',
                                   grepl('^experimental psychology$', discipline_specific, ignore.case = T) & discipline == 'Psychology' ~ 'Experimental Analysis of Behavior',
                                   grepl('^industrial', discipline_specific, ignore.case = T) & discipline == 'Psychology' ~ 'Industrial and Organizational Psychology',
                                   grepl('^counseling psychology', discipline_specific, ignore.case = T) & discipline == 'Psychology' ~ 'Counseling Psychology',
                                   (grepl('stratification', discipline_specific, ignore.case = T) | grepl('inequalit', discipline_specific, ignore.case = T)) & discipline == 'Sociology' ~ 'Inequality and Stratification',
                                   grepl('religion', discipline_specific, ignore.case = T) & discipline == 'Sociology' ~ 'Sociology of Religion',
                                   grepl('education', discipline_specific, ignore.case = T) & discipline == 'Sociology' ~ 'Educational Sociology',
                                   grepl('criminology', discipline_specific, ignore.case = T) & discipline == 'Sociology' ~ 'Criminology',
                                   grepl('demography', discipline_specific, ignore.case = T) & discipline == 'Sociology' ~ 'Demography, Population, and Ecology',
                                   grepl('gender', discipline_specific, ignore.case = T) & discipline == 'Sociology' ~ 'Gender and Sexuality',
                                   grepl('health', discipline_specific, ignore.case = T) & discipline == 'Sociology' ~ 'Medicine and Health',
                                   grepl('applied statistics', discipline_specific, ignore.case = T) & discipline == 'Statistics' ~ 'Applied Statistics',
                                   grepl('clinical trials', discipline_specific, ignore.case = T) & discipline == 'Statistics' ~ 'Clinical Trials',
                                   grepl('biostatistic', discipline_specific, ignore.case = T) & discipline == 'Statistics' ~ 'Biostatistics',
                                   grepl('survey', discipline_specific, ignore.case = T) & discipline == 'Statistics' ~ 'Design of Experiments and Sample Surveys',
                                   grepl('biogeochemistry', discipline_specific, ignore.case = T) ~ 'Biogeochemistry',
                                   grepl('^paleontology$', discipline_specific, ignore.case = T) | grepl('vertebrate paleontology', discipline_specific, ignore.case = T) ~ 'Paleontology',
                                   grepl('^Behavioral Ecology$', discipline_specific, ignore.case = T) | grepl('^Behavioural Ecology$', discipline_specific, ignore.case = T) ~ 'Behavior and Ethology',
                                   grepl('^evolutionary biology$', discipline_specific, ignore.case = T) | grepl('^evolution', discipline_specific, ignore.case = T) ~ 'Evolution',
                                   grepl('paleobiology', discipline_specific, ignore.case = T) | grepl('palaeobiology', discipline_specific, ignore.case = ) ~ 'Paleobiology',
                                   grepl('agricultural economics', discipline_specific, ignore.case = T) & grepl('food security', discipline_specific, ignore.case = ) ~ 'Food Security',
                                   grepl('fisheries', discipline_specific, ignore.case = T) ~ 'Aquaculture and Fisheries',
                                   discipline_other == 'Biochemistry' ~ 'Biochemistry',
                                   discipline_other == 'theoretical biophysics' ~ 'Biophyics',
                                   grepl('islamic studies', discipline_other, ignore.case = T) ~ 'Islamic Studies',
                                   discipline_other == 'Musicology' ~ 'Musicology',
                                   discipline_other == 'cosmology' ~ 'Cosmology, Relativity, and Gravity',
                                   discipline_other == 'vision science' ~ 'Vision Science',
                                   grepl('orthodontics', discipline_other, ignore.case = T) ~ 'Orthodontics and Orthodontology',
                                   grepl('health economics', discipline_other, ignore.case = T) ~ 'Health economics',
                                   discipline_other == 'sustainability science' ~ 'Sustainability',
                                   discipline_other == 'nature conservation' ~ 'Natural Resources and Conservation',
                                   discipline_other == 'Computational Biology' ~ 'Computational Biology',
                                   grepl('parasitology', discipline_other, ignore.case = T) ~ 'Parasitology',
                                   discipline_other == 'Applied Linguistics' ~ 'Applied Linguistics',
                                   grepl('computational', discipline_other, ignore.case = T) & grepl('linguistic', discipline_other, ignore.case = T) ~ 'Computational Linguistics',
                                   discipline_other == 'Psycholinguistics' ~ 'Psycholinguistics and Neurolinguistics',
                                   grepl('language acquisition', discipline_other, ignore.case = T) ~ 'First and Second Language Acquisition',
                                   discipline_other == 'Medical Microbiology' ~ 'Medical Microbiology',
                                   grepl('sports medicine', discipline_other, ignore.case = T) ~ 'Sports Medicine',
                                   (grepl('cognitive', discipline_other, ignore.case = T) & grepl('neuroscience', discipline_other, ignore.case = T)) |
                                     (grepl('cognitive', discipline_specific, ignore.case = T) & grepl('neuroscience', discipline_specific, ignore.case = T)) ~ 'Cognitive Neuroscience',
                                   grepl('computational', discipline_other, ignore.case = T) & grepl('neuroscience', discipline_other, ignore.case = T) ~ 'Computational Neuroscience',
                                   grepl('Education Policy', discipline_other, ignore.case = T) ~ 'Education Policy',
                                   grepl('^epidemiology$', discipline_other, ignore.case = T) | 
                                     (grepl('epidemiology', discipline_other, ignore.case = T) & grepl('public health', discipline_other, ignore.case = T)) ~ 'Epidemiology',
                                   grepl('obstetrics', discipline_other, ignore.case = T) ~ 'Obstetrics and Gynecology',
                                   grepl('Physical Therapy', discipline_other, ignore.case = T) ~ 'Physical Therapy',
                                   grepl('^Pharmacology$', discipline_other, ignore.case = T) ~ 'Pharmacology',
                                   grepl('^psychiatry$', discipline_other, ignore.case = T) ~ 'Psychiatry',
                                   grepl('Science and Technology Studies', discipline_other, ignore.case = T) ~ 'Science and Technology Studies',
                                   grepl('science', discipline_other, ignore.case = T) & grepl('education', discipline_other, ignore.case = T) ~ 'Science and Mathematics Education',
                                   grepl('sport', discipline_other, ignore.case = T) & grepl('science', discipline_other, ignore.case = T) ~ 'Sports Sciences',
                                   ))


## bepress tier 2 recoding

## psychophysiology; Public health infectious diseases; public health and social work; Public health & medical anthropology; Health research (epidemiology, psychology, biomedicine)


grepl('^chemical engineering$', discipline_specific, ignore.case = T) ~ 'Chemical Engineering'

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
                                   grepl('^marine biology$', discipline_specific, ignore.case = T) & discipline == 'Ecology/Evolutionary Science' ~ 'Marine Biology',
                                   grepl('biochemistry', discipline_other, ignore.case = TRUE) | grepl('biophysics', discipline_other) | (grepl('^biochemistry$', discipline_specific, ignore.case = TRUE) & discipline == 'Biology') |
                                     (grepl('^biophysics$', discipline_specific, ignore.case = TRUE) & discipline == 'Biology') | grepl('^structural biology$', discipline_specific, ignore.case = TRUE)~ 'Biochemistry, Biophysics, and Structural Biology',
                                   grepl('bioethics', discipline_other, ignore.case = TRUE) | grepl('Biomedical ethics', discipline_other) ~ 'Bioethics and Medical Ethics',
                                   grepl('bioinformatics', discipline_other, ignore.case = TRUE) | (grepl('^bioinformatics$', discipline_specific, ignore.case = TRUE) & discipline == 'Biology') ~ 'Bioinformatics',
                                   grepl('Biomedical Engineering', discipline_other) ~ 'Biomedical Engineering and Bioengineering',
                                   grepl('Biotechnology', discipline_other) | (discipline_specific == 'biotechnology' & discipline != 'Engineering') | discipline_specific == 'Biotechnology' ~ 'Biotechnology',
                                   (grepl('^cell biology$', discipline_specific, ignore.case = TRUE) | grepl('^cancer biology$', discipline_specific, ignore.case = TRUE) |
                                      grepl('^developmental biology$', discipline_specific, ignore.case = TRUE)) & discipline == 'Biology' ~ 'Cell and Developmental Biology',
                                   grepl('^evolutionary biology$', discipline_specific, ignore.case = TRUE) & discipline == 'Biology' ~ 'Ecology and Evolutionary Biology',
                                   grepl('classics', discipline_other) ~ 'Classics',
                                   grepl('cognition', discipline_other) | grepl('Psychology', discipline) ~ 'Psychology',
                                   grepl('computer scien', discipline_other, ignore.case = TRUE) | grepl('computerscience', discipline_other, ignore.case = TRUE) ~ 'Computer Sciences',
                                   grepl('computational biology', discipline_other, ignore.case = TRUE) | 
                                      (grepl('^computational biology$', discipline_specific, ignore.case = TRUE) & discipline == 'Biology') ~ 'Genetics and Genomics',
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
                                   grepl('Urban Planning', discipline_other) ~ 'Urban Studies and Planning',
                                   grepl('^zoology$', discipline_specific, ignore.case = TRUE) ~ 'Animal Studies',
                                   discipline == 'Kinesiology' ~ 'Kinesiology',
                                   discipline == 'Chemistry' ~ 'Chemistry',
                                   discipline == 'Paleontology' ~ 'Earth Science',
                                   discipline == 'Biology' & is.na(discipline_specific) ~ 'Biology'))

## bepress tier 1 recoding
survey_data <- survey_data %>%
    mutate(bepress_tier1 = case_when(grepl('My example is not typical', discipline_other, ignore.case = TRUE) | grepl('Digital Humanities, Editing', discipline_other, ignore.case = TRUE) ~ NA_character_,
                                     grepl('computational social science', discipline_other, ignore.case = TRUE) ~ 'Social and Behavioral Sciences',
                                     grepl('humanities', discipline_other, ignore.case = TRUE) | bepress_tier2 == 'History' | bepress_tier2 == 'Classics' |
                                        bepress_tier2 == 'Religion' | bepress_tier2 == 'Music' | bepress_tier2 == 'Philosophy' | grepl('literature', discipline_other, ignore.case = TRUE) ~ 'Arts and Humanities',
                                     (grepl('medicine', discipline_other, ignore.case = TRUE) & is.na(bepress_tier2)) | grepl('Click to write Choice 23', discipline) | grepl('Dentistry, psychiatry, neuroscience', discipline_other) | 
                                       grepl('Veterinary Epidemiology and Public Health', discipline_other) | (grepl('health science', discipline_other, ignore.case = TRUE) & is.na(bepress_tier2)) |
                                       grepl('psychiatry', discipline_other, ignore.case = TRUE) | bepress_tier2 == 'Nursing' | bepress_tier2 == 'Anatomy' |
                                       bepress_tier2 == 'Public Health' | bepress_tier2 == 'Medical Education' | grepl('veterinary', discipline_specific, ignore.case = TRUE) |
                                       bepress_tier2 == 'Medical Specialties' | bepress_tier2 == 'Medical Sciences' | bepress_tier2 == 'Bioethics and Medical Ethics' |
                                       bepress_tier2 == 'Veterinary Medicine' | bepress_tier2 == 'Dentistry' | bepress_tier2 == 'Sports Sciences' |
                                       bepress_tier2 == 'Rehabilitation and Therapy' | bepress_tier2 == 'Mental and Social Health' ~ 'Medicine and Health Sciences',
                                     bepress_tier2 == 'Marketing' | bepress_tier2 == 'Accounting' | bepress_tier2 == 'Sports Management' | grepl('management', discipline_other, ignore.case = TRUE) |
                                        discipline_other == 'Business' | discipline_other == 'Business Administration' ~ 'Business',
                                     discipline == 'Chemistry' | discipline == 'Physics' | discipline == 'Statistics' | discipline == 'Mathematics' | 
                                        bepress_tier2 == 'Astrophysics and Astronomy' | bepress_tier2 == 'Computer Sciences' | 
                                        bepress_tier2 == 'Environmental Sciences' | discipline == 'Paleontology' ~ 'Physical Sciences and Mathematics',
                                     discipline == 'Political Science' | discipline == 'Psychology' | discipline == 'Economics' | discipline == 'Sociology' |
                                        bepress_tier2 == 'Anthropology' | bepress_tier2 == 'Linguistics' | bepress_tier2 == 'Communication' |
                                        bepress_tier2 == 'Social Work' | bepress_tier2 == 'Geography' | bepress_tier2 == 'Sociology' | bepress_tier2 == 'Economics' |
                                        bepress_tier2 == 'Library and Information Science' | discipline == 'Library/Information Science' | 
                                        bepress_tier2 == 'Public Affairs, Public Policy and Public Administration' | bepress_tier2 == 'Psychology' |
                                        bepress_tier2 == 'Science and Technology Studies' | bepress_tier2 == 'Urban Studies and Planning' ~ 'Social and Behavioral Science',
                                     (grepl('education', discipline_other, ignore.case = TRUE) & is.na(bepress_tier2)) | (grepl('Education', bepress_tier2) & !grepl('Medical Education', bepress_tier2)) ~ 'Education',
                                     discipline == 'Law' ~ 'Law',
                                     bepress_tier2 == 'Biomedical Engineering and Bioengineering' ~ 'Engineering',
                                     (discipline == 'Biology' & grepl('ecology', discipline_specific, ignore.case = TRUE)) | discipline == 'Ecology/Evolutionary Science' |
                                        (grepl('immunology', discipline_specific, ignore.case = TRUE) & discipline == 'Biology') | bepress_tier2 == 'Immunology and Infectious Disease' | 
                                        discipline == 'Kinesiology' | bepress_tier2 == 'Neuroscience and Neurobiology' | bepress_tier2 == 'Biochemistry, Biophysics, and Structural Biology' |
                                        bepress_tier2 == 'Bioinformatics' | bepress_tier2 == 'Biotechnology' | bepress_tier2 == 'Systems Biology' | bepress_tier2 == 'Genetics and Genomics' |
                                        bepress_tier2 == 'Microbiology' | bepress_tier2 == 'Physiology' | bepress_tier2 == 'Plant Sciences' | bepress_tier2 == 'Animal Studies' |
                                        bepress_tier2 == 'Cell and Developmental Biology' | bepress_tier2 == 'Ecology and Evolutionary Biology' ~ 'Life Science')) %>%
    select(bepress_tier1, bepress_tier2, discipline, discipline_specific, discipline_other) %>%
    arrange(bepress_tier1, discipline, discipline_specific, discipline_other, bepress_tier2)


