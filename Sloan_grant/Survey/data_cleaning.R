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
                                   grepl('^molecular biology$', discipline_specific, ignore.case = T) & (discipline == 'Biology' | discipline == 'Agriculural Science') ~ 'Molecular Biology',
                                   grepl('^molecular genetics$', discipline_specific, ignore.case = T) & discipline == 'Biology' ~ 'Molecular Genetics',
                                   grepl('molecular neuroscience', discipline_specific, ignore.case = T) & discipline == 'Biology' ~ 'Molecular and Cellular Neuroscience',
                                   grepl('^parasitology$', discipline_specific, ignore.case = T) & discipline == 'Biology' ~ 'Parasitology',
                                   grepl('^pharmacology$', discipline_specific, ignore.case = T) & discipline == 'Biology' ~ 'Pharmacology',
                                   grepl('^plant biology$', discipline_specific, ignore.case = T) & discipline == 'Biology' ~ 'Plant Biology',
                                   grepl('^plant pathology$', discipline_specific, ignore.case = T) & discipline == 'Biology' ~ 'Plant Pathology',
                                   grepl('^structural biology$', discipline_specific, ignore.case = T) & discipline == 'Biology' ~ 'Structural Biology',
                                   (grepl('^virology$', discipline_specific, ignore.case = T) | discipline_specific == 'Virology and Transcription') & discipline == 'Biology' |
                                     grepl('^virology$', discipline_other, ignore.case = T) | discipline_specific == 'microbiology, virology' ~ 'Virology',
                                   grepl('^zoology$', discipline_specific, ignore.case = T) & discipline == 'Biology' ~ 'Zoology',
                                   grepl('civil engineering', discipline_specific, ignore.case = T) & discipline == 'Engineering' ~ 'Civil Engineering',
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
                                   grepl('^geology$', discipline_specific, ignore.case = T) & discipline == 'Earth Science' ~ 'Geology',
                                   grepl('geomorphology', discipline_specific, ignore.case = T) & discipline == 'Earth Science' ~ 'Geomorphology',
                                   grepl('^hydrology', discipline_specific, ignore.case = T) & discipline == 'Earth Science' ~ 'Hydrology',
                                   (grepl('^seismology$', discipline_specific, ignore.case = T) & discipline == 'Earth Science') |
                                      grepl('geophysics', discipline_specific, ignore.case = T) ~ 'Geophysics and Seismology',
                                   grepl('^meteorology$', discipline_specific, ignore.case = T) & discipline == 'Earth Science' ~ 'Meteorology',
                                   (grepl('^oceanography$', discipline_specific, ignore.case = T) | grepl('^oceanograpy$', discipline_specific, ignore.case = T) ) & discipline == 'Earth Science' ~ 'Oceanography',
                                   grepl('^sedimentology$', discipline_specific, ignore.case = T) & discipline == 'Earth Science' ~ 'Sedimentology',
                                   grepl('^behavioral ecology$', discipline_specific, ignore.case = T) & discipline == 'Ecology/Evolutionary Science' |
                                     (grepl('behavioural', discipline_specific, ignore.case = T) & grepl('ecology', discipline_specific, ignore.case = T)) ~ 'Behavior and Ethology',
                                   ((grepl('marine', discipline_specific, ignore.case = T) | grepl('freshwater', discipline_specific, ignore.case = T) | grepl('forest', discipline_specific, ignore.case = T) |
                                       grepl('aquatic', discipline_specific, ignore.case = T) | grepl('grassland', discipline_specific, ignore.case = T) |
                                       grepl('freswhater', discipline_specific, ignore.case = T) | grepl('terrestrial', discipline_specific, ignore.case = T)) & grepl('ecology', discipline_specific, ignore.case = T)) | 
                                     (grepl('ecology', discipline_specific, ignore.case = T) & discipline == 'Marine Science') ~ 'Terrestrial and Aquatic Ecology',
                                   grepl('^public economics', discipline_specific, ignore.case = T) & discipline == 'Economics' ~ 'Public Economics',
                                   grepl('behavioral', discipline_specific, ignore.case = T) & grepl('economics', discipline_specific, ignore.case = T) & discipline == 'Economics' ~ 'Behavioral Economics',
                                   grepl('^development', discipline_specific, ignore.case = T) & discipline == 'Economics' ~ 'Growth and Development',
                                   (grepl('energy economics', discipline_specific, ignore.case = T) | grepl('^nvironmental economics$', discipline_specific, ignore.case = T)) & discipline == 'Economics' ~ 'Other Economics',
                                   (grepl('^finance$', discipline_specific, ignore.case = T) & discipline == 'Economics') |
                                     (grepl('finance', discipline_specific, ignore.case = T) & !grepl('behavioral', discipline_specific, ignore.case = T) & discipline == 'Economics')~ 'Finance',
                                   grepl('^Health economics$', discipline_specific, ignore.case = T) & discipline == 'Economics' ~ 'Health Economics',
                                   grepl('^international economics$', discipline_specific, ignore.case = T) & discipline == 'Economics' ~ 'International Economics',
                                   grepl('organization', discipline_specific, ignore.case = T) & discipline == 'Economics' ~ 'Industrial Organization',
                                   grepl('history', discipline_specific, ignore.case = T) & discipline == 'Economics' ~ 'Economic History',
                                   grepl('labor economics$', discipline_specific, ignore.case = T) & discipline == 'Economics' ~ 'Labor Economics',
                                   grepl('^macroeconomics$', discipline_specific, ignore.case = T) & discipline == 'Economics' ~ 'Macroeconomics',
                                   grepl('^political economy$', discipline_specific, ignore.case = T) & discipline == 'Economics' ~ 'Political Economy',
                                   grepl('^public economics$', discipline_specific, ignore.case = T) & discipline == 'Economics' ~ 'Public Economics',
                                   grepl('tissue engineering', discipline_specific, ignore.case = T) & discipline == 'Engineering' ~ 'Molecular, Cellular, and Tissue Engineering',
                                   grepl('imaging', discipline_specific, ignore.case = T) & discipline == 'Engineering' ~ 'Bioimaging and Biomedical Optics',
                                   grepl('combustion', discipline_specific, ignore.case = T) & discipline == 'Engineering' ~ 'Heat Transfer, Combustion',
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
                                   (grepl('electrical', discipline_specific, ignore.case = T) | grepl('electronic', discipline_specific, ignore.case = T)) & discipline == 'Engineering' ~ 'Electrical and Electronics',
                                   grepl('psychology', discipline_specific, ignore.case = T) & discipline == 'Kinesiology' ~ 'Psychology of Movement',
                                   grepl('exercise science', discipline_specific, ignore.case = T) & discipline == 'Kinesiology' ~ 'Exercise Science',
                                   grepl('scholarly communication', discipline_specific, ignore.case = T) & discipline == 'Library/Information Science' ~ 'Health Sciences and Medical Librarianship',
                                   grepl('health', discipline_specific, ignore.case = T) & discipline == 'Library/Information Science' ~ 'Partial Differential Equations',
                                   grepl('oceanography$', discipline_specific, ignore.case = T) & discipline == 'Marine Science' ~ 'Oceanography',
                                   discipline_specific == 'Algebra' ~ 'Algebra',
                                   grepl('partial differential equations', discipline_specific, ignore.case = T) & discipline == 'Mathematics' ~ 'Partial Differential Equations',
                                   grepl('probability', discipline_specific, ignore.case = T) & discipline == 'Mathematics' ~ 'Probability',
                                   grepl('geometry', discipline_specific, ignore.case = T) & discipline == 'Mathematics' ~ 'Geometry and Topology',
                                   grepl('epidemiology', discipline_specific, ignore.case = T) & discipline == 'Medicine' ~ 'Epidemiology',
                                   grepl('^ophthalmology$', discipline_specific, ignore.case = T) & discipline == 'Medicine' ~ 'Ophthalmology',
                                   grepl('oncology', discipline_specific, ignore.case = T) & discipline == 'Medicine' ~ 'Oncology',
                                   (grepl('neurology', discipline_specific, ignore.case = T) & discipline == 'Medicine') | grepl('neurology', discipline_other, ignore.case = T) ~ 'Neurology',
                                   grepl('^psychiatry$', discipline_specific, ignore.case = T) & discipline == 'Medicine' ~ 'Psychiatry',
                                   grepl('neuroscience', discipline_specific, ignore.case = T) & discipline == 'Medicine' ~ 'Neurosciences',
                                   grepl('microbiology', discipline_specific, ignore.case = T) & discipline == 'Medicine' ~ 'Medical Microbiology',
                                   grepl('radiology', discipline_specific, ignore.case = T) & discipline == 'Medicine' ~ 'Radiology',
                                   grepl('\\<urology$', discipline_specific, ignore.case = T) & discipline == 'Medicine' ~ 'Urology',
                                   grepl('biochemistry', discipline_specific, ignore.case = T) & discipline == 'Nutritional Science' ~ 'Molecular, Genetic, and Biochemical Nutrition',
                                   grepl('biochemistrye', discipline_specific, ignore.case = T) & discipline == 'Nutritional Science' ~ 'Biochemical Phenomena, Metabolism, and Nutrition',
                                   grepl('epidemiology', discipline_specific, ignore.case = T) & discipline == 'Nutrional Science' ~ 'Nutrition Epidemiology',
                                   discipline == 'Paleontology' ~ 'Paleontology',
                                   (grepl('^statistical', discipline_specific, ignore.case = T) | grepl('nonlinear', discipline_specific, ignore.case = T)) & discipline == 'Physics' ~ 'Statistical, Nonlinear, and Soft Matter Physics',
                                   grepl('quantum', discipline_specific, ignore.case = T) & discipline == 'Physics' ~ 'Quantum Physics',
                                   grepl('optics', discipline_specific, ignore.case = T) & discipline == 'Physics' ~ 'Optics',
                                   grepl('atomics', discipline_specific, ignore.case = T) & discipline == 'Physics' ~ 'Atomic, Molecular and Optical Physics',
                                   grepl('condensed', discipline_specific, ignore.case = T) & discipline == 'Physics' ~ 'Condensed Matter',
                                   grepl('bio', discipline_specific, ignore.case = T) & discipline == 'Physics' ~ 'Biological and Chemical Physics',
                                   grepl('fluid', discipline_specific, ignore.case = T) & discipline == 'Physics' ~ 'Fluid Dynamics',
                                   grepl('plasma', discipline_specific, ignore.case = T) & discipline == 'Physics' ~ 'Plasma and Beam Physics',
                                   grepl('^american politics$', discipline_specific, ignore.case = T) & discipline == 'Political Science' ~ 'American Politics',
                                   grepl('comparative', discipline_specific, ignore.case = T) & discipline == 'Political Science' ~ 'Comparative Politics',
                                   grepl('theory', discipline_specific, ignore.case = T) & discipline == 'Political Science' ~ 'Political Theory',
                                   grepl('method', discipline_specific, ignore.case = T) & discipline == 'Political Science' ~ 'Models and Methods',
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
                                   discipline_other == 'theoretical biophysics' ~ 'Biophysics',
                                   grepl('islamic studies', discipline_other, ignore.case = T) ~ 'Islamic Studies',
                                   discipline_other == 'Musicology' ~ 'Musicology',
                                   discipline_other == 'cosmology' ~ 'Cosmology, Relativity, and Gravity',
                                   discipline_other == 'vision science' ~ 'Vision Science',
                                   grepl('orthodontics', discipline_other, ignore.case = T) ~ 'Orthodontics and Orthodontology',
                                   grepl('health economics', discipline_other, ignore.case = T) ~ 'Health Economics',
                                   discipline_other == 'sustainability science' ~ 'Sustainability',
                                   discipline_other == 'nature conservation' ~ 'Natural Resources and Conservation',
                                   discipline_other == 'Computational Biology' ~ 'Computational Biology',
                                   grepl('parasitology', discipline_other, ignore.case = T) ~ 'Parasitology',
                                   discipline_other == 'Applied Linguistics' | discipline_other == 'Applied LInguistics' ~ 'Applied Linguistics',
                                   grepl('computational', discipline_other, ignore.case = T) & grepl('linguistic', discipline_other, ignore.case = T) ~ 'Computational Linguistics',
                                   discipline_other == 'Psycholinguistics' ~ 'Psycholinguistics and Neurolinguistics',
                                   grepl('language acquisition', discipline_other, ignore.case = T) ~ 'First and Second Language Acquisition',
                                   discipline_other == 'Medical Microbiology' ~ 'Medical Microbiology',
                                   grepl('sports medicine', discipline_other, ignore.case = T) ~ 'Sports Medicine',
                                   (grepl('cognitive', discipline_other, ignore.case = T) & grepl('neuroscience', discipline_other, ignore.case = T)) |
                                     (grepl('cognitive', discipline_specific, ignore.case = T) & grepl('neuroscience', discipline_specific, ignore.case = T)) ~ 'Cognitive Neuroscience',
                                   (grepl('computational', discipline_other, ignore.case = T) | grepl('computer science', discipline_other, ignore.case = T)) & 
                                     grepl('neuroscience', discipline_other, ignore.case = T) ~ 'Computational Neuroscience',
                                   grepl('Education Policy', discipline_other, ignore.case = T) ~ 'Education Policy',
                                   grepl('^epidemiology$', discipline_other, ignore.case = T) | 
                                     (grepl('epidemiology', discipline_other, ignore.case = T) & grepl('public health', discipline_other, ignore.case = T)) ~ 'Epidemiology',
                                   grepl('obstetrics', discipline_other, ignore.case = T) ~ 'Obstetrics and Gynecology',
                                   grepl('Physical Therapy', discipline_other, ignore.case = T) ~ 'Physical Therapy',
                                   grepl('^Pharmacology$', discipline_other, ignore.case = T) ~ 'Pharmacology',
                                   grepl('^psychiatry$', discipline_other, ignore.case = T) ~ 'Psychiatry',
                                   grepl('Sustainability', discipline_other) ~ 'Sustainability',
                                   discipline_other == 'Veterinary Pathology' ~ 'Veterinary Pathology and Pathobiology',
                                   discipline_specific == 'Veterinary Immunology' ~ 'Veterinary Microbiology and Immunobiology',
                                   discipline_other == 'Midwifery' ~ 'Nursing Midwifery',
                                   discipline_other == 'Geriatrics' ~ 'Geriatrics',
                                   grepl('family medicine', discipline_other, ignore.case = T) ~ 'Family Medicine',
                                   discipline_other == 'Couple and family therapy' ~ 'Marriage and Family Therapy and Counseling',
                                   grepl('public policy', discipline_other, ignore.case = T) ~ 'Public Policy',
                                   grepl('public administration', discipline_other, ignore.case = T) ~ 'Public Administration',
                                   grepl('Physiology/Medical sciences', discipline_other) ~ 'Medical Physiology',
                                   grepl('Plastic', discipline_other) ~ 'Plastic Surgery',
                                   grepl('preventive medicine', discipline_other) ~ 'Preventive Medicine',
                                   grepl('surgery', discipline_other, ignore.case = T) | grepl('surgery', discipline_specific, ignore.case = T) ~ 'Surgery',
                                   grepl('pediatric', discipline_other, ignore.case = T) |
                                     (grepl('pediatric', discipline_specific, ignore.case = T) & discipline != 'Psychology') ~ 'Pediatrics',
                                   (grepl('comparative', discipline_specific, ignore.case = T) | grepl('qualitative', discipline_specific, ignore.case = T) |
                                      grepl('quantitative', discipline_specific, ignore.case = T)) & 
                                      discipline == 'Sociology' ~ 'Quantitative, Qualitative, Comparative, and Historical Methodologies',
                                   grepl('psychology', discipline_specific, ignore.case =  T) & !grepl('counceling', discipline_specific, ignore.case = T) &
                                      discipline == 'Sociology' ~ 'Social Psychology and Interaction',
                                   grepl('cult', discipline_specific, ignore.case = T) & discipline == 'Sociology' ~ 'Sociology of Culture',
                                   grepl('law', discipline_specific, ignore.case = T) & discipline == 'Sociology' ~ 'Social Control, Law, Crime, and Deviance',
                                   (grepl('political socio', discipline_specific, ignore.case = T) | grepl('social movement', discipline_specific, ignore.case = T)) &
                                      discipline == 'Sociology' ~ 'Politics and Social Change',
                                   grepl('collection', discipline_specific, ignore.case = T) & discipline == 'Library/Information Science' ~ 'Collection Development and Management',
                                   grepl('literacy', discipline_specific, ignore.case = T) & discipline == 'Library/Information Science'~ 'Information Literacy',
                                   (grepl('nursing', discipline_specific, ignore.case = T) | grepl('medical', discipline_specific, ignore.case = T)) &
                                     discipline == 'Library/Information Science' ~ 'Health Sciences and Medical Librarianship',
                                   grepl('scholarly communication', discipline_specific, ignore.case = T) & discipline == 'Library/Information Science' ~ 'Scholarly Communication',
                                   grepl('archival', discipline_specific, ignore.case = T) & discipline == 'Library/Information Science' ~ 'Archival Science',
                                   grepl('toxicology', discipline_specific, ignore.case = T) & discipline == 'Marine Science' ~ 'Toxicology',
                                   grepl('oral', discipline_specific, ignore.case = T) & discipline == 'Medicine' ~ 'Oral Biology and Oral Pathology',
                                   grepl('physiology', discipline_specific, ignore.case = T) & discipline == 'Medicine' ~ 'Medical Physiology',
                                   grepl('immunology', discipline_specific, ignore.case = T) & discipline == 'Medicine' ~ 'Medical Immunology',
                                   grepl('hepatology', discipline_specific, ignore.case = T) & discipline == 'Medicine' ~ 'Hepatology',
                                   grepl('cell bio', discipline_specific, ignore.case = T) & discipline == 'Medicine' ~ 'Medical Cell Biology',
                                   grepl('pathologist', discipline_other, ignore.case = T) ~ 'Pathology',
                                   discipline_other == 'Otorhinolarygology' ~ 'Otolaryngology',
                                   grepl('pharmacology', discipline_other, ignore.case = T) & grepl('medicine', discipline_other, ignore.case = T) ~ 'Medical Pharmacology',
                                   discipline_other == 'AI & Robotics' ~ 'Artificial Intelligence and Robotics',
                                   discipline_other == 'Hearing Science' ~ 'Speech and Hearing Science',
                                   discipline == 'Electrochemistry' ~ 'Other Chemistry',
                                   discipline_specific == 'Molecular Physiology' ~ 'Cellular and Molecular Physiology'))


## bepress tier 2 recoding
survey_data <- survey_data %>% 
  mutate(bepress_tier2 = case_when(bepress_tier3 == 'Agricultural Economics' ~ 'Agriculture',
                                   bepress_tier3 == 'Food Security' ~ 'Agricultural and Resource Economics',
                                   bepress_tier3 == 'Aquaculture and Fisheries' | bepress_tier3 == 'Zoology' ~ 'Animal Sciences',
                                   bepress_tier3 == 'Partial Differential Equations' ~ 'Applied Mathematics',
                                   bepress_tier3 == 'Cosmology, Relativity, and Gravity' ~ 'Astrophysics and Astronomy',
                                   bepress_tier3 == 'Biochemistry' | bepress_tier3 == 'Biophysics' | bepress_tier3 == 'Molecular Biology' | 
                                     bepress_tier3 == 'Structural Biology' ~ 'Biochemistry, Biophysics, and Structural Biology',
                                   bepress_tier3 == 'Bioelectrical and Neuroengineering' | bepress_tier3 == 'Bioimaging and Biomedical Optics' |
                                     bepress_tier3 == 'Molecular, Cellular, and Tissue Engineering' | bepress_tier3 == 'Vision Science' ~ 'Biomedical Engineering and Bioengineering',
                                   bepress_tier3 == 'Cancer Biology' | bepress_tier3 == 'Cell Biology' | bepress_tier3 == 'Developmental Biology' ~ 'Cell and Developmental Biology',
                                   bepress_tier3 == 'Polymer Science' ~ 'Chemical Engineering',
                                   bepress_tier3 == 'Analytical Chemistry' | bepress_tier3 == 'Inorganic Chemistry' | bepress_tier3 == 'Materials Chemistry' |
                                     bepress_tier3 == 'Medicinal-Pharmaceutical Chemistry' | bepress_tier3 == 'Organic Chemistry' | bepress_tier3 == 'Other Chemistry' |
                                     bepress_tier3 == 'Physical Chemistry' | bepress_tier3 == 'Environmental Chemistry' ~ 'Chemistry',
                                   bepress_tier3 == 'Structural Engineering' | bepress_tier3 == 'Transportation Engineering' | bepress_tier3 == 'Environmental Engineering' |
                                     bepress_tier3 == 'Civil Engineering' ~ 'Civil and Environmental Engineering',
                                   bepress_tier3 == 'Speech and Hearing Science' ~ 'Communication Sciences and Disorders',
                                   bepress_tier3 == 'Robotics' ~ 'Computer Engineering',
                                   bepress_tier3 == 'Artificial Intelligence and Robotics' ~ 'Computer Sciences',
                                   bepress_tier3 == 'Orthodontics and Orthodontology' | bepress_tier3 == 'Oral Biology and Oral Pathology' ~ 'Dentistry',
                                   bepress_tier3 == 'Biogeochemistry' | bepress_tier3 == 'Geochemistry' | bepress_tier3 == 'Geology' | bepress_tier3 == 'Geomorphology' |
                                     bepress_tier3 == 'Geophysics and Seismology' | bepress_tier3 == 'Hydrology' | bepress_tier3 == 'Paleontology' |
                                     bepress_tier3 == 'Sedimentology' | bepress_tier3 == 'Soil Science' ~ 'Earth Sciences',
                                   bepress_tier3 == 'Behavior and Ethology' | bepress_tier3 == 'Evolution' | bepress_tier3 == 'Terrestrial and Aquatic Ecology' ~ 'Ecology and Evolutionary Biology',
                                   bepress_tier3 == 'Behavioral Economics' | bepress_tier3 == 'Finance' | bepress_tier3 == 'Health Economics' |
                                     bepress_tier3 == 'Growth and Development' | bepress_tier3 == 'International Economics' | bepress_tier3 == 'Labor Economics' |
                                     bepress_tier3 == 'Macroeconomics' | bepress_tier3 == 'Other Economics' | bepress_tier3 == 'Political Economy' |
                                     bepress_tier3 == 'Public Economics' | bepress_tier3 == 'Industrial Organization' | bepress_tier3 == 'Economic History' ~ 'Economics',
                                   bepress_tier3 == 'Electrical and Electronics' | bepress_tier3 == 'Nanotechnology Fabrication' | bepress_tier3 == 'Signal Processing' ~ 'Electrical and Computer Engineering',
                                   bepress_tier3 == 'Natural Resources and Conservation' | bepress_tier3 == 'Sustainability' ~ 'Environmental Sciences',
                                   bepress_tier3 == 'Computational Biology' | bepress_tier3 == 'Genetics' | bepress_tier3 == 'Genomics' | bepress_tier3 == 'Molecular Genetics' |
                                     bepress_tier3 == 'Other Genetics and Genomics' ~ 'Genetics and Genomics',
                                   bepress_tier3 == 'Parasitology' ~ 'Immunology and Infectious Disease',
                                   bepress_tier3 == 'Exercise Science' | bepress_tier3 == 'Psychology of Movement' ~ 'Kinesiology',
                                   bepress_tier3 == 'Health Sciences and Medical Librarianship' | bepress_tier3 == 'Archival Science' |
                                     bepress_tier3 == 'Collection Development and Management' | bepress_tier3 == 'Information Literacy' |
                                     bepress_tier3 == 'Scholarly Communication' ~ 'Library and Information Science',
                                   bepress_tier3 == 'Applied Linguistics' | bepress_tier3 == 'Computational Linguistics' | bepress_tier3 == 'First and Second Language Acquisition' |
                                     bepress_tier3 == 'Psycholinguistics and Neurolinguistics' ~ 'Linguistics',
                                   bepress_tier3 == 'Algebra' | bepress_tier3 == 'Geometry and Topology' ~ 'Mathematics',
                                   bepress_tier3 == 'Heat Transfer, Combustion' | bepress_tier3 == 'Ocean Engineering' ~ 'Mechanical Engineering',
                                   bepress_tier3 == 'Medical Microbiology' | bepress_tier3 == 'Sports Medicine' | bepress_tier3 == 'Medical Physiology' |
                                     bepress_tier3 == 'Medical Physiology' | bepress_tier3 == 'Medical Immunology' | bepress_tier3 == 'Medical Cell Biology' |
                                     bepress_tier3 == 'Medical Pharmacology' ~ 'Medical Sciences',
                                   bepress_tier3 == 'Marriage and Family Therapy and Counseling' ~ 'Mental and Social Health',
                                   bepress_tier3 == 'Neurology' | bepress_tier3 == 'Neurosciences' | bepress_tier3 == 'Obstetrics and Gynecology' | bepress_tier3 == 'Oncology' |
                                     bepress_tier3 == 'Ophthalmology' | bepress_tier3 == 'Psychiatry' | bepress_tier3 == 'Radiology' | bepress_tier3 == 'Urology' |
                                     bepress_tier3 == 'Geriatrics' | bepress_tier3 == 'Family Medicine' | bepress_tier3 == 'Plastic Surgery' |
                                     bepress_tier3 == 'Preventive Medicine' | bepress_tier3 == 'Surgery' | bepress_tier3 == 'Pediatrics' | bepress_tier3 == 'Hepatology' |
                                     bepress_tier3 == 'Pathology' | bepress_tier3 == 'Otolaryngology' ~ 'Medical Specialties',
                                   bepress_tier3 == 'Virology' ~ 'Microbiology',
                                   bepress_tier3 == 'Musicology' ~ 'Music',
                                   bepress_tier3 == 'Cognitive Neuroscience' | bepress_tier3 == 'Computational Neuroscience' | 
                                     bepress_tier3 == 'Molecular and Cellular Neuroscience' ~ 'Neuroscience and Neurobiology',
                                   bepress_tier3 == 'Nursing Midwifery' ~ 'Nursing',
                                   bepress_tier3 == 'Molecular, Genetic, and Biochemical Nutrition' ~ 'Nutrition',
                                   bepress_tier3 == 'Atmospheric Sciences' | bepress_tier3 == 'Meteorology' | bepress_tier3 == 'Oceanography' ~ 'Oceanography and Atmospheric Sciences and Meteorology',
                                   bepress_tier3 == 'Industrial Engineering' ~ 'Operations Research, Systems Engineering and Industrial Engineering',
                                   bepress_tier3 == 'Pharmacology' | bepress_tier3 == 'Toxicology' ~ 'Pharmacology, Toxicology and Environmental Health',
                                   bepress_tier3 == 'Optics' | bepress_tier3 == 'Quantum Physics' | bepress_tier3 == 'Statistical, Nonlinear, and Soft Matter Physics' |
                                     bepress_tier3 == 'Atomic, Molecular and Optical Physics' | bepress_tier3 == 'Condensed Matter Physics' |
                                     bepress_tier3 == 'Biological and Chemical Physics' | bepress_tier3 == 'Fluid Dynamics' | bepress_tier3 == 'Plasma and Beam Physics' ~ 'Physics',
                                   bepress_tier3 == 'Cellular and Molecular Physiology' ~ 'Physiology',
                                   bepress_tier3 == 'Plant Biology' | bepress_tier3 == 'Plant Breeding and Genetics' | bepress_tier3 == 'Plant Pathology' ~ 'Plant Sciences',
                                   bepress_tier3 == 'American Politics' | bepress_tier3 == 'Comparative Politics' | bepress_tier3 == 'International Relations' |
                                     bepress_tier3 == 'Models and Methods' | bepress_tier3 == 'Political Theory' ~ 'Political Science',
                                   bepress_tier3 == 'Biological Psychology' | bepress_tier3 == 'Clinical Psychology' | bepress_tier3 == 'Cognition and Perception' |
                                     bepress_tier3 == 'Cognitive Psychology' | bepress_tier3 == 'Comparative Psychology' | bepress_tier3 == 'Counseling Psychology' |
                                     bepress_tier3 == 'Developmental Psychology' | bepress_tier3 == 'Experimental Analysis of Behavior' | bepress_tier3 == 'Health Psychology' |
                                     bepress_tier3 == 'Industrial and Organizational Psychology' | bepress_tier3 == 'Other Psychology' | bepress_tier3 == 'Personality and Social Contexts' |
                                     bepress_tier3 == 'Quantitative Psychology' | bepress_tier3 == 'Social Psychology' ~ 'Psychology',
                                   bepress_tier3 == 'Education Policy' | bepress_tier3 == 'Public Policy' | bepress_tier3 == 'Public Administration' ~ 'Public Affairs, Public Policy and Public Administration',
                                   bepress_tier3 == 'Epidemiology' ~ 'Public Health',
                                   bepress_tier3 == 'Physical Therapy' ~ 'Rehabilitation and Therapy',
                                   bepress_tier3 == 'Islamic Studies' ~ 'Religion',
                                   bepress_tier3 == 'Criminology' | bepress_tier3 == 'Demography, Population, and Ecology' | bepress_tier3 == 'Educational Sociology' |
                                     bepress_tier3 == 'Gender and Sexuality' | bepress_tier3 == 'Inequality and Stratification' |
                                     bepress_tier3 == 'Medicine and Health' | bepress_tier3 == 'Sociology of Religion' | 
                                     bepress_tier3 == 'Quantitative, Qualitative, Comparative, and Historical Methodologies' |
                                     bepress_tier3 == 'Social Psychology and Interaction' | bepress_tier3 == 'Sociology of Culture' |
                                     bepress_tier3 == 'Politics and Social Change' | bepress_tier3 == 'Social Control, Law, Crime, and Deviance' ~ 'Sociology',
                                   bepress_tier3 == 'Applied Statistics' | bepress_tier3 == 'Biostatistics' | bepress_tier3 == 'Clinical Trials' | 
                                     bepress_tier3 == 'Design of Experiments and Sample Surveys' | bepress_tier3 == 'Probability' ~ 'Statistics and Probability',
                                   bepress_tier3 == 'Veterinary Preventive Medicine, Epidemiology, and Public Health' | bepress_tier3 == 'Veterinary Microbiology and Immunobiology' |
                                     bepress_tier3 == 'Veterinary Pathology and Pathobiology' ~ 'Veterinary Medicine',
                                   grepl('administrative', discipline_specific, ignore.case = T) & discipline == 'Law' ~ 'Administrative Law',
                                   grepl('constitu', discipline_specific, ignore.case = T) & discipline == 'Law' ~ 'Constitutional Law',
                                   grepl('technology', discipline_specific, ignore.case = T) & discipline == 'Law' ~ 'Science and Technology Law',
                                   grepl('education', discipline_specific, ignore.case = T) & discipline == 'Law' ~ 'Education Law',
                                   grepl('philosophy', discipline_specific, ignore.case = T) & discipline == 'Law' ~ 'Law and Philosophy',
                                   grepl('history', discipline_specific, ignore.case = T) & discipline == 'Law' ~ 'Legal History',
                                   grepl('science', discipline_other, ignore.case = T) & grepl('education', discipline_other, ignore.case = T) ~ 'Science and Mathematics Education',
                                   grepl('Science and Technology Studies', discipline_other, ignore.case = T) ~ 'Science and Technology Studies',
                                   grepl('sport', discipline_other, ignore.case = T) & grepl('science', discipline_other, ignore.case = T) ~ 'Sports Sciences',
                                   grepl('^chemical engineering$', discipline_specific, ignore.case = T) | 
                                     (grepl('chemi', discipline_specific, ignore.case = T) & discipline == 'Engineering') ~ 'Chemical Engineering',
                                   (grepl('copyright', discipline_specific, ignore.case = T) | grepl('intellectual', discipline_specific, ignore.case = T)) & discipline == 'Law' ~ 'Law and Philosophy',
                                   grepl('^microbiology$', discipline_specific, ignore.case = T) | grepl('^microbiology$', discipline_other, ignore.case = T) |
                                     (grepl('microbiology', discipline_specific, ignore.case = T) & discipline == 'Marine Science') ~ 'Microbiology',
                                   (grepl('^systems biology$', discipline_specific, ignore.case = T) & discipline == 'Biology') | grepl('^systems biology$', discipline_other, ignore.case = T) ~ 'Systems Biology',
                                   grepl('^social work$', discipline_other, ignore.case = TRUE) ~ 'Social Work',
                                   grepl('educational technol', discipline_other, ignore.case = TRUE) ~ 'Educational Technology',
                                   grepl('^communication', discipline_other, ignore.case = TRUE) ~ 'Communication',
                                   grepl('Astronomy', discipline_other, ignore.case = TRUE) | grepl('astrophysics', discipline_other, ignore.case = TRUE) |
                                     grepl('Astronomy', discipline_specific, ignore.case = TRUE) | grepl('astrophysic', discipline_specific, ignore.case = TRUE) ~ 'Astrophysics and Astronomy',
                                   grepl('^linguistic$', discipline_other, ignore.case = TRUE) | grepl('applied linguistics', discipline_specific, ignore.case = TRUE) |
                                     grepl('^linguistics$', discipline_other, ignore.case = TRUE)~ 'Linguistics',
                                   grepl('^Anthropology$', discipline_other, ignore.case = TRUE) |  grepl('archaeology', discipline_other, ignore.case = TRUE) ~ 'Anthropology',
                                   (grepl('^marine biology$', discipline_specific, ignore.case = T) & discipline == 'Ecology/Evolutionary Science') |
                                     ((grepl('mammals', discipline_specific, ignore.case = T) | grepl('bioacoustics', discipline_specific, ignore.case = T)) & discipline == 'Marine Science' )~ 'Marine Biology',
                                   grepl('biochemistry', discipline_other, ignore.case = TRUE) & grepl('biophysics', discipline_other) ~ 'Biochemistry, Biophysics, and Structural Biology',
                                   grepl('bioethics', discipline_other, ignore.case = TRUE) | grepl('Biomedical ethics', discipline_other) | 
                                     (grepl('ethics', discipline_other, ignore.case = TRUE) & grepl('medicine', discipline_other, ignore.case = T)) ~ 'Bioethics and Medical Ethics',
                                   grepl('Anatomy', discipline_other) & grepl('medicine', discipline_other) ~ 'Anatomy',
                                   grepl('^Accounting$', discipline_other) ~ 'Accounting',
                                   grepl('^bioinformatics$', discipline_other, ignore.case = TRUE) | (grepl('^bioinformatics$', discipline_specific, ignore.case = TRUE) & discipline == 'Biology') ~ 'Bioinformatics',
                                   grepl('Biomedical Engineering', discipline_other) | 
                                     (grepl('biomedical engineering', discipline_specific, ignore.case = T) & discipline == 'Engineering') ~ 'Biomedical Engineering and Bioengineering',
                                   grepl('Biotechnology', discipline_other) |  grepl('^Biotechnology$', discipline_specific) ~ 'Biotechnology',
                                   grepl('Educaci', discipline_other, ignore.case = TRUE) | grepl('Special Educatio', discipline_other) ~ 'Special Education and Teaching',
                                   grepl('classics', discipline_other) ~ 'Classics',
                                   grepl('^computer science$', discipline_other, ignore.case = TRUE) | grepl('computerscience', discipline_other, ignore.case = TRUE) |
                                     discipline_other == 'CS, multidisciplinary' | discipline_other == 'Computer sciense' | discipline_other == 'Computer Science/Data Science' ~ 'Computer Sciences',
                                   grepl('Urban Planning', discipline_other) ~ 'Urban Studies and Planning',
                                   grepl('^history$', discipline_other, ignore.case = TRUE) ~ 'History',
                                   grepl('^dentistry$', discipline_other, ignore.case = TRUE) ~ 'Dentistry',
                                   grepl('^environmental science', discipline_other, ignore.case = TRUE) | grepl('^environmental science$', discipline_specific, ignore.case = TRUE) |
                                     grepl('^enviromental science', discipline_other, ignore.case = TRUE)~ 'Environmental Sciences',
                                   grepl('^neuroscience$', discipline_other, ignore.case = TRUE) | 
                                     (grepl('^neuroscience$', discipline_specific, ignore.case = TRUE) & discipline == 'Biology') ~ 'Neuroscience and Neurobiology',
                                   grepl('Veterinary', discipline_other, ignore.case = TRUE) | grepl('Veterinary', discipline_specific, ignore.case = TRUE) ~ 'Veterinary Medicine',
                                   discipline_other == 'Medical Education' | discipline_specific == 'Medical Education' ~ 'Medical Education',
                                   grepl('physical education', discipline_other, ignore.case = TRUE) ~ 'Health and Physical Education',
                                   grepl('^geography$', discipline_other, ignore.case = TRUE) ~ 'Geography',
                                   grepl('Plant Science', discipline_other) | grepl('Plant Science', discipline_specific) | 
                                     (grepl('plant', discipline_other, ignore.case = T) & discipline == 'Agricultural Science') ~ 'Plant Sciences',
                                   grepl('theology', discipline_other, ignore.case = TRUE) | grepl('Religio', discipline_other, ignore.case = TRUE) ~ 'Religion',
                                   grepl('Philosophy', discipline_other) ~ 'Philosophy',
                                   grepl('^immunology$', discipline_other, ignore.case = TRUE) |
                                     (grepl('^immunology$', discipline_specific, ignore.case = TRUE) & discipline == 'Biology') |
                                     grepl('infectious', discipline_other, ignore.case = T) ~ 'Immunology and Infectious Disease',
                                   grepl('^public health$', discipline_other, ignore.case = TRUE) | grepl('^Publi health$', discipline_other) |
                                     (grepl('^public health$', discipline_specific, ignore.case = TRUE) & discipline == 'Medicine') ~ 'Public Health',
                                   grepl('^nursing', discipline_other, ignore.case = TRUE) | 
                                     (grepl('^nursing', discipline_specific, ignore.case = TRUE) & discipline == 'Medicine') ~ 'Nursing',
                                   grepl('sport management', discipline_other, ignore.case = TRUE) ~ 'Sports Management',
                                   grepl('marketing', discipline_other, ignore.case = TRUE) ~ 'Marketing',
                                   grepl('rehabilitation', discipline_other, ignore.case = TRUE) ~ 'Rehabilitation and Therapy',
                                   grepl('^physiology$', discipline_other, ignore.case = TRUE) |
                                     (grepl('^physiology$', discipline_specific, ignore.case = TRUE) & discipline == 'biology') ~ 'Physiology',
                                   grepl('arabic education', discipline_other, ignore.case = TRUE) | 
                                     grepl('english education', discipline_other, ignore.case = TRUE) ~ 'Language and Literacy Education',
                                   grepl('Information Science', discipline_other) ~ 'Library and Information Science',
                                   grepl('library', discipline_specific, ignore.case = T) & discipline == 'Physics' ~ 'Library and Information Science',
                                   grepl('psychology', discipline_specific, ignore.case = T) & discipline == 'Medicine' ~ 'Psychiatry and Psychology',
                                   grepl('translational', discipline_specific, ignore.case = T) & discipline == 'Medicine' ~ 'Translational Medical Research',
                                   discipline_specific == 'Aerospace Engineering' ~ 'Aerospace Engineering',
                                   grepl('bio', discipline_specific, ignore.case =  T) & discipline == 'Engineering' ~ 'Biomedical Engineering and Bioengineering',
                                   grepl('computer engineering', discipline_specific, ignore.case = T) & discipline == 'Engineering' ~ 'Computer Engineering',
                                   grepl('computer science', discipline_specific, ignore.case = T) & !grepl('engineering', discipline_specific, ignore.case = T) & 
                                     discipline == 'Engineering' ~ 'Computer Sciences',
                                   grepl('mechanical engineering', discipline_specific, ignore.case = T) & discipline == 'Engineering' ~ 'Mechanical Engineering',
                                   grepl('materials', discipline_specific, ignore.case = T) & discipline == 'Engineering' ~ 'Materials Science and Engineering',
                                   grepl('entomology', discipline_specific, ignore.case = T) ~ 'Entomology',
                                   grepl('agriculture', discipline_specific, ignore.case = T) ~ 'Agriculture',
                                   grepl('animal science', discipline_specific, ignore.case = T) ~ 'Animal Sciences',
                                   discipline == 'Chemistry' ~ 'Chemistry',
                                   discipline == 'Economics' ~ 'Economics',
                                   discipline == 'Kinesiology' ~ 'Kinesiology',
                                   discipline == 'Library/Information Science' ~ 'Library and Information Science',
                                   discipline == 'Physics' ~ 'Physics',
                                   discipline == 'Sociology' ~ 'Sociology',
                                   discipline == 'Political Science' ~ 'Political Science',
                                   discipline == 'Mathematics' ~ 'Mathematics',
                                   discipline == 'Ecology/Evolutionary Science' ~ 'Ecology and Evolutionary Biology'
                                   ))
          





## bepress tier 1 recoding
survey_data <- survey_data %>%
    mutate(bepress_tier1 = case_when(bepress_tier2 == 'Classics' | bepress_tier2 == 'History' | bepress_tier2 == 'Philosophy' |
                                       bepress_tier2 == 'Music' | bepress_tier2 == 'Religion' ~ 'Arts and Humanities',
                                     bepress_tier2 == 'Accounting' | bepress_tier2 == 'Marketing' | bepress_tier2 == 'Sports Management' ~ 'Business',
                                     bepress_tier2 == 'Educational Technology' | bepress_tier2 == 'Health and Physical Education' |
                                       bepress_tier2 == 'Language and Literacy Education' | bepress_tier2 == 'Science and Mathematics Education' |
                                       bepress_tier2 == 'Special Education and Teaching' ~ 'Education',
                                     bepress_tier2 == 'Biomedical Engineering and Bioengineering' | bepress_tier2 == 'Chemical Engineering' |
                                       bepress_tier2 == 'Civil and Environmental Engineering' | bepress_tier2 == 'Computer Engineering' |
                                       bepress_tier2 == 'Electrical and Computer Engineering' | bepress_tier2 == 'Operations Research, Systems Engineering and Industrial Engineering' |
                                       bepress_tier2 == 'Mechanical Engineering' | bepress_tier2 == 'Aerospace Engineering' | bepress_tier2 == 'Materials Science and Engineering' ~ 'Engineering',
                                     bepress_tier2 == 'Administrative Law' | bepress_tier2 == 'Constitutional Law' | bepress_tier2 == 'Education Law' ~ 'Law',
                                     bepress_tier2 == 'Agriculture' | bepress_tier2 == 'Animal Sciences' | bepress_tier2 == 'Biochemistry, Biophysics, and Structural Biology' |
                                       bepress_tier2 == 'Bioinformatics' | bepress_tier2 == 'Biotechnology' | bepress_tier2 == 'Cell and Developmental Biology' |
                                       bepress_tier2 == 'Ecology and Evolutionary Biology' | bepress_tier2 == 'Genetics and Genomics' |
                                       bepress_tier2 == 'Immunology and Infectious Disease' | bepress_tier2 == 'Kinesiology' |
                                       bepress_tier2 == 'Systems Biology' | bepress_tier2 == 'Pharmacology, Toxicology and Environmental Health' |
                                       bepress_tier2 == 'Nutrition' | bepress_tier2 == 'Neuroscience and Neurobiology' | bepress_tier2 == 'Microbiology' |
                                       bepress_tier2 == 'Animal Sciences' | bepress_tier2 == 'Marine Biology' | bepress_tier2 == 'Physiology' |
                                       bepress_tier2 == 'Plant Sciences' | bepress_tier2 == 'Entomology' ~ 'Life Sciences',
                                     bepress_tier2 == 'Anatomy' | bepress_tier2 == 'Bioethics and Medical Ethics' | bepress_tier2 == 'Dentistry' | bepress_tier2 == 'Veterinary Medicine' |
                                       bepress_tier2 == 'Nursing' | bepress_tier2 == 'Mental and Social Health' | bepress_tier2 == 'Medical Specialties' |
                                       bepress_tier2 == 'Medical Sciences' | bepress_tier2 == 'Medical Education' | bepress_tier2 == 'Public Health' |
                                       bepress_tier2 == 'Rehabilitation and Therapy' | bepress_tier2 == 'Sports Sciences' | 
                                       bepress_tier2 == 'Communication Sciences and Disorders' ~ 'Medicine and Health Sciences',
                                     bepress_tier2 == 'Applied Mathematics' | bepress_tier2 == 'Astrophysics and Astronomy' | bepress_tier2 == 'Chemistry' |
                                       bepress_tier2 == 'Computer Sciences' | bepress_tier2 == 'Earth Sciences' | bepress_tier2 == 'Environmental Sciences' |
                                       bepress_tier2 == 'Physics' | bepress_tier2 == 'Oceanography and Atmospheric Sciences and Meteorology' |
                                       bepress_tier2 == 'Mathematics' | bepress_tier2 == 'Statistics and Probability' ~ 'Physical Sciences and Mathematics',
                                     bepress_tier2 == 'Agricultural and Resource Economics' | bepress_tier2 == 'Anthropology' | bepress_tier2 == 'Communication' |
                                       bepress_tier2 == 'Economics' | bepress_tier2 == 'Geography' | bepress_tier2 == 'Psychology' | bepress_tier2 == 'Sociology' |
                                       bepress_tier2 == 'Library and Information Science' | bepress_tier2 == 'Linguistics' | bepress_tier2 == 'Political Science' |
                                       bepress_tier2 == 'Public Affairs, Public Policy and Public Administration' | bepress_tier2 == 'Social Work' |
                                       bepress_tier2 == 'Urban Studies and Planning' | bepress_tier2 == 'Science and Technology Studies' ~ 'Social and Behavioral Sciences',
                                     grepl('education', discipline_other, ignore.case = T) ~ 'Education',
                                     grepl('medicine', discipline_other, ignore.case = T) | grepl('health science', discipline_other, ignore.case = T) |
                                       grepl('medical', discipline_other, ignore.case = T) | grepl('^public health', discipline_other, ignore.case = T) |
                                       grepl('dentistry', discipline_other, ignore.case = T) | grepl('^health', discipline_other, ignore.case = T) |
                                       grepl('psychiatry', discipline_other, ignore.case = T) | discipline_other == 'pharmacoepidemiology' |
                                       discipline_other == 'Publi Health' | discipline_other == 'Medicne' ~ 'Medicine and Health Sciences',
                                     grepl('^business', discipline_other, ignore.case = T) | grepl('^management', discipline_other, ignore.case = T) |
                                       grepl('accounting', discipline_other, ignore.case = T) | grepl('business intelligence', discipline_other, ignore.case = T) ~ 'Business',
                                     grepl('computational social science', discipline_other, ignore.case = T) | grepl('criminology', discipline_other, ignore.case = T) |
                                       grepl('linguistic', discipline_other, ignore.case = T) | grepl('social science', discipline_other, ignore.case = T) |
                                       grepl('psychology', discipline_other, ignore.case = T) | grepl('development', discipline_other, ignore.case = T) |
                                       grepl('^library science', discipline_other, ignore.case = T) | grepl('anthropology', discipline_other, ignore.case = T) |
                                       discipline_other == 'STS' ~ 'Social and Behavioral Sciences',
                                     grepl('humanities', discipline_other, ignore.case = T) & !grepl('linguistics', discipline_other, ignore.case = T) |
                                       grepl('near east', discipline_other, ignore.case = T) | grepl('literature', discipline_other, ignore.case = T) ~ 'Arts and Humanities',
                                     grepl('bioinformatic', discipline_other, ignore.case = T) | grepl('life science', discipline_other, ignore.case = T) |
                                       grepl('genomics', discipline_other, ignore.case = T) ~ 'Life Sciences',
                                     discipline_other == 'optical engineering' ~ 'Engineering',
                                     
                                     
      discipline == 'Agricultural Science' ~ 'Life Science',
      discipline == 'Engineering' ~ 'Engineering',
      discipline == 'Medicine' ~ 'Medicine and Health Sciences',
      discipline == 'Law' ~ 'Law',
    ))
      
      
      
      
      
      grepl('My example is not typical', discipline_other, ignore.case = TRUE) | grepl('Digital Humanities, Editing', discipline_other, ignore.case = TRUE) ~ NA_character_,
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


