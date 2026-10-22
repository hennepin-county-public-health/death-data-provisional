### Combined script last updated 2026-10-22 15:55:21.024856 ###

#Set mandatory values
input_folder <- NULL
output_folder <- "./trusted_data/"
output_file <- "trusted_death_data"
output_format <- c("csv", "parquet")
trusted_format <- c("combined", "annual")

#If you want to filter the trusted data to a particular county or counties, specify here
residence_county <- c("")

### Step: validate_inputs.R ###

message("Step 1. Validating manually input values.")

#Make a couple options case-insensitive
output_format <- gsub("\\.", "", tolower(output_format))
trusted_format <- tolower(trusted_format)

#Validate manually input values
values <- list(input_folder, output_folder, output_file, output_format, trusted_format)

if (any(sapply(values, is.null))){
  stop("Not all mandatory values specified.")
}

if (!any(output_format %in% c("csv", "parquet"))){
  stop("Invalid output format specified. Please select csv or parquet.")
}

if (!any(trusted_format %in% c("combined", "annual"))){
  stop("Invalid output format specified. Please select csv or parquet.")
}

#If missing, add a backslash to the end of folder paths
input_folder <- if (grepl("/$", input_folder)) {
  input_folder
} else {
  paste0(input_folder, "/")
}

output_folder <- if (grepl("/$", output_folder)) {
  output_folder
} else {
  paste0(output_folder, "/")
}

#If default trusted folder is selected, create if it doesn't exist
if (!file.exists("./trusted_data/")){
  dir.create(output_folder)
}

#Validate county filter selections
mn_counties <- read.csv("./documentation/mn_counties.csv")$county
residence_county <- residence_county[!residence_county == ""]
residence_county <- toupper(residence_county)
residence_county <- gsub("ST. |ST ", "SAINT ", residence_county)

if (length(residence_county) != 0 & !all(residence_county %in% mn_counties)){
  county_error <- residence_county[!residence_county %in% mn_counties][1] #just take first
  
  error_dist <- data.frame(
    county = mn_counties,
    dist = adist(mn_counties, county_error))
  
  closest_matches <- error_dist[error_dist$dist == min(error_dist$dist),]$county
  
  stop(paste0(county_error, 
              " is not a valid county selection. Could you have meant one of the following options? - \n",
              paste0(closest_matches, collapse = ", ")))
}

#Cleanup
rm(values, mn_counties)

message("Manually input values validated.")

### Step: install_packages.R ###

message("Step 2. Loading packages.")

# Install packages
#- do we want to set version here too?
package_dependencies <- c(
  "tidyverse", #may be worth using the individual packages to prevent so much being loaded
  "janitor", #may be able to replace this depending on how it's used
  "arrow", #for now.. does this install have any dependencies that could be a problem?
  "readxl",
  "remotes", #install github package
  "albert"
)

#add general descriptions of how each package is used above

uninstalled <- package_dependencies[!package_dependencies %in% rownames(installed.packages())]

if (length(uninstalled) != 0){
  for (p in uninstalled){
    
    if (p == "albert"){
      remotes::install_github("hennepin-county-public-health/albert")
    } else {
      install.packages(p)
    }
    
    message(paste0("Installed package: ", p))
  }
  
}

#Load packages
library(tidyverse)
library(janitor)
library(readxl)
library(arrow)
library(albert)

#Clean up
rm(package_dependencies, uninstalled)


message("All required packages installed and loaded.")

### Step: load_data.R ###

message("Step 3. Loading raw data.")

## Identify most recent file for each year ##
files <- tibble(file = list.files(input_folder, pattern = "MNDEATHS")) |>
  mutate(file_clean = str_remove(file, "\\(.*\\)")) |> #may be common if multiple versions have been downloaded
  separate_wider_delim(file_clean, delim = "_", names = c("year", NA, "date")) |>
  mutate(date = str_remove(date, ".csv"),
         date = ymd(date)) |>
  filter(date == max(date), .by = year) |> #get most recent file for each data year
  slice(1, .by = year) #in case there are multiples with the same date (seems like it could easily happen)

last_file <- max(files$date) #will be used in a future step too

## Make sure all files are csv, otherwise won't be read in ##
if (sum(!str_detect(files$file, ".csv")) != 0){
  stop("Not all files in the expected format.")
}

## Get correct column types from the data dictionary ##
col_specs <- read_xlsx(str_c("./documentation/", "Death data dictionary.xlsx"),
                       sheet = "Death Data - Provisional") |>
  filter(!str_detect(Notes, "Created by HCPH") | is.na(Notes)) |>  #remove variables created later
  consult_dictionary("Variable Name", "Type", date_format = "%m/%d/%Y", datetime_format = "%Y-%m-%d %H:%M:%S")

## Read in most recent file for each year ##
dth_raw <- map(files$file, function(f){
  read_csv(str_c(input_folder, f),
           col_types = col_specs) |>
    mutate(file_year = as.numeric(str_sub(f, 1, 4)))
}) |>
  list_rbind()

if (length(residence_county) != 0){
  dth_raw <- dth_raw |>
    filter(decd_res_cnty %in% residence_county)
}

message("Raw data loaded from the files below.")
print(files |> select(-file))

## Cleanup ##
rm(files, col_specs)

### Step: cause_of_death.R ###

message("Step 4. Cause of death coding started.")

#Notes on ICD10 codes
#Letters signify broad categories, while numbers are more specific causes. Numbers only go up to 99 but there are plenty of three digit numbers.
#These should be interpreted as decimals, so X102 should actually be read as X10.2, and included in any ranges that X10 would have been included in. 
#In practice, the final digit is often dropped when calculating new vars. A good list of the codes with decimal examples: https://www.icd10data.com/ICD10CM/Codes.

#Used for especially complex categories below
c_mv_cats <- c("V090", "V092", "V190", "V191", "V192", "V194", "V195", "V196", "V803", "V804", "V805", "V810", "V811", "V820", "V821", "V890", "V892")
c_firearm_cats <- c("X93", "X94", "X95", "X72", "X73", "X74", "W32", "W33", "W34", "Y22", "Y23", "Y24", "Y350", "U014", "Y364")

dth_cod <- dth_raw |>
  mutate(
    dataset_last_updated = last_file,
    across(contains("rac_icd"), ~ifelse(is.na(.), "", .)),
    acme_unly_cause_dth = ifelse(is.na(acme_unly_cause_dth), "", str_trim(acme_unly_cause_dth)),
    acme_trim = str_sub(acme_unly_cause_dth, 1, 3),
    
    c_injury_suicide = case_when(
      acme_trim >= "X60" & acme_trim <= "X84" ~ 1,
      acme_unly_cause_dth == "Y870" ~ 1,
      acme_unly_cause_dth == "U03" ~ 1,
      .default = 0),
    c_heartdisease = case_when(
      acme_trim >= "I00" & acme_trim <= "I09" ~ 1,
      acme_trim == "I11" ~ 1,
      acme_trim == "I13" ~ 1,
      acme_trim >= "I20" & acme_trim <= "I51" ~ 1,
      .default = 0),
    c_cancer = if_else(acme_trim >= "C00" & acme_trim <= "C97", 1, 0),
    c_clrd = if_else(acme_trim >= "J40" & acme_trim <= "J47", 1, 0),
    c_stroke = if_else(acme_trim >= "I60" & acme_trim <= "I69", 1, 0),
    c_unintent_injury = case_when(
      acme_trim >= "V01" & acme_trim <= "V99" ~ 1,
      acme_trim >= "W00" & acme_trim <= "W99" ~ 1,
      acme_trim >= "X00" & acme_trim <= "X59" ~ 1,
      acme_trim >= "Y85" & acme_trim <= "Y86" ~ 1,
      .default = 0),
    c_alzheimers = if_else(acme_trim == "G30", 1, 0),
    c_diabetes = if_else(acme_trim >= "E10" & acme_trim <= "E14", 1, 0),
    c_nephritis = case_when(
      acme_trim >= "N00" & acme_trim <= "N07" ~ 1,
      acme_trim >= "N17" & acme_trim <= "N19" ~ 1,
      acme_trim >= "N25" & acme_trim <= "N27" ~ 1,
      .default = 0),
    c_influenza_pneu = if_else(acme_trim >= "J09" & acme_trim <= "J18", 1, 0),
    c_sids = if_else(acme_trim %in% c("R95", "R96", "W75", "W83", "W84"), 1, 0),
    c_influenza = if_else(acme_trim >= "J09" & acme_trim <= "J11", 1, 0),
    c_maternal = if_else(acme_trim >= "O00" & acme_trim <= "O99", 1, 0),
    c_aids = if_else(acme_trim >= "B20" & acme_trim <= "B24", 1, 0),
    c_homicide = case_when(
      acme_trim >= "X85" & acme_trim <= "X99" ~ 1,
      acme_trim >= "Y00" & acme_trim <= "Y09" ~ 1,
      acme_unly_cause_dth == "Y871" ~ 1,
      acme_trim >= "U01" & acme_trim <= "U02" ~ 1,
      .default = 0),
    c_liver = if_else(acme_trim %in% c("K70", "K73", "K74"), 1, 0),
    c_mv = case_when(
      acme_unly_cause_dth %in% c_mv_cats ~ 1,
      acme_trim >= "V02" & acme_trim <= "V04" ~ 1,
      acme_trim >= "V12" & acme_trim <= "V14" ~ 1, 
      acme_trim >= "V20" & acme_trim <= "V79" ~ 1,
      acme_trim >= "V83" & acme_trim <= "V86" ~ 1,
      str_sub(acme_unly_cause_dth, 1, 4) >= "V870" & str_sub(acme_unly_cause_dth, 1, 4) <= "V878" ~ 1,
      str_sub(acme_unly_cause_dth, 1, 4) >= "V880" & str_sub(acme_unly_cause_dth, 1, 4) <= "V888" ~ 1,
      .default = 0),
    c_septicemia = if_else(acme_trim >= "A40" & acme_trim <= "A41", 1, 0),
    c_drug_overdose = case_when( 
      acme_trim >= "X40" & acme_trim <= "X44" ~ 1,
      acme_trim >= "X60" & acme_trim <= "X64" ~ 1,
      acme_trim == "X85" ~ 1,
      acme_trim >= "Y10" & acme_trim <= "Y14" ~ 1,
      .default = 0),
    c_firearmany = if_else(acme_unly_cause_dth %in% c_firearm_cats, 1, 0),
    c_firearmhom = if_else(acme_unly_cause_dth %in% c("X93", "X94", "X95", "Y350"), 1, 0),
    c_firearmaccid = if_else(acme_unly_cause_dth %in% c("W32", "W33", "W34"), 1, 0),
    c_firearmsuic = if_else(acme_unly_cause_dth %in% c("X72", "X73", "X74"), 1, 0),
    
    c_cc_anyopioidoh = if_else(if_any(contains("rac_icd"), ~ . %in% c("T402", "T403", "T404")), 1, 0), #this is based on the macro in the syntax document; meaning seems to be whether opioid was a coding as a cod
    #this ^ was called c_cc_opioid in the old provisional syntax, but changed it to this to match the annual file format
    c_drug_overdose_opioid = if_else(c_drug_overdose == 1 & c_cc_anyopioidoh == 1, 1, 0), #if drug overdose death involved opioids
    
    #this COD coding is included in the provisional files.. adding for consistency 11/8/22
    c_suffocation = if_else(acme_trim >= "W75" & acme_trim <= "W84", 1, 0), 
    c_drowning = if_else(acme_trim >= "W65" & acme_trim <= "W74", 1, 0),
    c_poisoning = if_else(acme_trim >= "X40" & acme_trim <= "X49", 1, 0),
    c_drugs = if_else(acme_trim >= "X40" & acme_trim <= "X44", 1, 0),
    c_burn = if_else(acme_trim >= "X00" & acme_trim <= "X19", 1, 0),
    c_fall = if_else(acme_trim >= "W00" & acme_trim <= "W19", 1, 0),
    c_unintentother = case_when(
      acme_trim >= "W20" & acme_trim <= "W46" ~ 1,
      acme_trim >= "W49" & acme_trim <= "W64" ~ 1,
      acme_trim >= "X20" & acme_trim <= "X39" ~ 1,
      acme_trim >= "X50" & acme_trim <= "X59" ~ 1,
      acme_trim >= "Y85" & acme_trim <= "Y86" ~ 1,
      .default = 0),
    c_other_transport = case_when(
      acme_trim >= "V01" & acme_trim <= "V04" ~ 1,
      acme_trim >= "V09" & acme_trim <= "V99" ~ 1,
      .default = 0),
    c_cc_heroine = if_else(if_any(contains("rac_icd"), ~ . == "T401"), 1, 0),
    c_cc_cocaine = if_else(if_any(contains("rac_icd"), ~ . == "T405"), 1, 0),
    c_cc_anyopioid = if_else(if_any(contains("rac_icd"), ~ . %in% paste0("T", c(400:404, 406))), 1, 0),
    c_cc_methadone = if_else(if_any(contains("rac_icd"), ~ . == "T403"), 1, 0),
    c_cc_alcohol = if_else(if_any(contains("rac_icd"), ~ . == "T51"), 1, 0), 
    c_cc_methamphetamine = if_else(if_any(contains("rac_icd"), ~ . == "T436"), 1, 0),
    c_cc_benzodiazepines = if_else(if_any(contains("rac_icd"), ~ . == "T424"), 1, 0),
    c_cc_fentanyl = ifelse(if_any(c(starts_with("cause_dth")), ~str_detect(., "FENTANYL") & !is.na(.)), 1, 0), #added 3/29/23
    
    c_covid = ifelse(if_any(contains("rac_icd"), ~str_detect(., "U071")), 1, 0), #added 3/10/23
    c_xylazine = ifelse(if_any(c(starts_with("cause_dth")), ~str_detect(., "XYLAZINE|XYLOZINE") & !is.na(.)), 1, 0), #added 3/15/23
    
    c_cancer_detail = case_when(
      !str_detect(acme_unly_cause_dth, "^C") ~ as.character(NA), #non-cancer
      acme_trim >= "C00" & acme_trim <= "C14"~ "Head and Neck Cancers", #maybe some addl things that should be included here? larynx?
      acme_trim == "C50" ~ "Breast Cancer",
      acme_trim %in% c("C18", "C19", "C20") ~ "Colorectal Cancer",
      acme_trim %in% c("C43") ~ "Melanoma", #doesn't inc non-melanoma skin cancer (C44, I believe?)
      acme_trim == "C67" ~ "Bladder Cancer",
      acme_trim == "C22" ~ "Liver Cancer",
      acme_trim == "C61" ~ "Prostate Cancer",
      acme_trim == "C34" ~ "Lung & Bronchus Cancer",
      #acme_trim == "C81" ~ "Hodgkin Lymphoma", #remove for now, very small
      acme_trim %in% c("C82", "C83", "C84", "C85") ~ "Non-Hodgkin Lymphoma",
      acme_trim %in% c("C64", "C65") ~ "Kidney & Renal Pelvis",
      acme_trim == "C25" ~ "Pancreatic Cancer",
      acme_trim == "C73" ~ "Thyroid Cancer",
      acme_trim %in% c("C91", "C92", "C93", "C94", "C95") ~ "Leukemia",
      acme_trim %in% c("C69", "C70", "C71", "C72") ~ "Brain & Central Nervous Systems Cancers",
      acme_trim == "C80" ~ "Cancer at Non-specified Site",
      acme_trim == "C15" ~ "Esophageal Cancer",
      acme_trim == "C16" ~ "Stomach Cancer",
      acme_trim == "C90" ~ "Multiple Myeloma", #includes a couple sub-types that I think should be included
      acme_trim %in% c("C54", "C55") ~ "Endometrial (Uterine) Cancer", #I think it makes sense to separate out the female sexual organs?
      acme_trim == "C56" ~ "Ovarian Cancer", #could also add more catch-all cats for this and others.. but doesn't seem like it would be useful for browsing
      .default = "Other Cancers"),
    
    c_unintent_injury_detail = case_when(
      c_unintent_injury != 1 ~ as.character(NA),
      c_fall == 1 ~ "Falls",
      c_drowning == 1 ~ "Drowning",
      c_suffocation == 1 ~ "Suffocation",
      c_burn == 1 ~ "Burns",
      c_drugs == 1 ~ "Drugs",
      c_mv == 1 ~ "Motor Vehicles",
      acme_trim >= "X30" & acme_trim <= "X39" ~ "Exposure to Forces of Nature",
      acme_trim >= "X45" & acme_trim <= "X49" ~ "Non-drug Poisoning",
      acme_trim == "X59" ~ "Exposure to Unspecified Factors",
      acme_trim >= "W20" & acme_trim <= "W49" ~ "Machinery & Inanimate Objects",
      .default = "Other Causes"),
    
    suicide_firearm = if_else(acme_unly_cause_dth >= "X72" & acme_unly_cause_dth <= "X75", 1, 0), #x75 is suicide by explosive material, but was included previously
    suicide_suffocation = if_else(acme_unly_cause_dth == "X70", 1, 0),
    suicide_poisoning = if_else(acme_unly_cause_dth >= "X60" & acme_unly_cause_dth <= "X69", 1, 0),
    suicide_poisoning_und = if_else(str_sub(acme_unly_cause_dth, end = 1) == "Y" & as.numeric(str_sub(acme_unly_cause_dth, 2)) %in% c(10:12, 16, 17), 1, 0),
    suicide_fall = if_else(acme_unly_cause_dth == "X80", 1, 0),
    suicide_object = if_else(acme_unly_cause_dth == "X81", 1, 0),
    suicide_car = if_else(acme_unly_cause_dth == "X82", 1, 0),
    suicide_drowning = if_else(acme_unly_cause_dth == "X71", 1, 0),
    suicide_smoke = if_else(acme_unly_cause_dth == "X76" | acme_unly_cause_dth == "X77", 1, 0),
    suicide_cutting = if_else(acme_unly_cause_dth == "X78" | acme_unly_cause_dth == "X79", 1, 0),
    suicide_other = if_else(acme_unly_cause_dth == "X83" | acme_unly_cause_dth == "X84", 1, 0)) 

## Cleanup ##
rm(dth_raw, c_mv_cats, c_firearm_cats)

message("Cause of death coding completed.")

### Step: race_ethn.R ###

message("Step 5. Race and ethnicity cleaning started.")

#Read in ICD code dict
icd_dict <- suppressMessages(read_csv("./documentation/ICD10_code_dictionary.csv"))

dth_cln <- dth_cod |>
  mutate(across(c(me_first_referred_dt, me_refer_dt, me_reassign_dt, me_assumed_dt, me_approved_dt), as_date), #these were originally dttm, could change back if necessary
         #remove NA placeholders
         across(c(decd_res_cntry_fips_cd, ifrmt_addr_cntry_fips_cd, ifrmt_addr_st_fips_cd, injury_loc_st_fips_cd, injury_loc_cntry_fips_cd), ~if_else(. == "ZZ", as.character(NA), .)),
         across(c(decd_brth_cty_fips_cd, injury_loc_cty_fips_cd), ~ifelse(. == 99999, NA, .)),
         injury_loc_cnty_fips_cd = if_else(injury_loc_cnty_fips_cd == 999, NA, injury_loc_cnty_fips_cd),
         across(c(decd_res_cty_fips_cd, ifrmt_addr_cty_fips_cd, decd_dth_cty_fips_cd), ~ ifelse(. == 0, as.character(NA), .)),
         subject_racebrg = if_else(subject_racebrg == "99", as.character(NA), subject_racebrg), 
         
         across(contains("fips_cd"), as.character),
         #there are some cases where the person is not an MN resident based on other info, but this var still says they are.
         decd_res_st_fips_cd = if_else(decd_res_st_fips_cd == "MN" & decd_res_st != "MINNESOTA", NA, decd_res_st_fips_cd),
         
         #create YPLL (years of life lost)
         mleyr = 75, #male/female expected years of life
         fleyr = 75, 
         ypll_75 = case_when(
           decd_age_yr >= 0 & decd_sex == "M" & decd_age_yr < mleyr ~ mleyr - 0.5 - decd_age_yr, #Use 0.5 to equalize age variation among each year
           decd_age_yr >= 0 & decd_sex == "F" & decd_age_yr < fleyr ~ fleyr - 0.5 - decd_age_yr, 
           .default = 0), #all cases where age is 75+
         
         #create race/ethnicity cats. 
         subject_asian_pi = if_else(
           if_any(
             c(subject_asian_indian, subject_chinese, subject_filipino, subject_japanese, subject_korean, subject_vietnamese, subject_hmong,
               subject_cambodian, subject_laotian, subject_other_asian, subject_hawaiian, subject_guamanian_chamorro, subject_samoan,
               subject_other_pacific_islander),
             ~.x == "Y"),
           "Y", "N"),
         subject_black = ifelse(
           if_any(
             c(subject_african_american, subject_somali, subject_ethiopian, subject_liberian, subject_kenyan, subject_sudanese, subject_nigerian,
               subject_ghanian, subject_other_african),
             ~.x == "Y"),
           "Y", "N"),
         num_races = str_count(paste0(subject_white, subject_american_indian, subject_asian_pi, subject_black, subject_other), "Y"),
         num_races_drop = ifelse(num_races == 2 & !is.na(subject_other) & subject_other == "Y", 1, num_races), #drop 'other' if two races are selected
         race_decedent_6 = case_when(
           num_races_drop > 1 ~ 6, #Two or more
           subject_american_indian == "Y" ~ 1, #American Indian or Alaska Native alone
           subject_asian_pi == "Y" ~ 2, #Asian/Pacific Islander alone
           subject_black == "Y" ~ 3, #Black/African-American alone
           subject_white == "Y" ~ 4, #White alone
           subject_other == "Y" ~ 5, #other alone
           .default = 9), #Unknown/missing
         subject_hisp = case_when(
           subject_not_hispanic == "Y" ~ "N",
           if_any(c(subject_mexican, subject_puerto_rican, subject_cuban, subject_other_spanish), ~.x == "Y") ~ "Y",
           .default = "U"),
         subject_race_ethn = case_when(
           subject_hisp == "Y" ~ 5, #Hispanic
           race_decedent_6 == 5 ~ 6, #Other-non-Hispanic
           race_decedent_6 == 6 ~ 7, #Two or more-non-Hispanic
           .default = race_decedent_6),
         
         #create race/ethnicity with American Indian trumping
         subject_race_ethn_ai = if_else(
           subject_american_indian == "Y" & !is.na(subject_american_indian), 1, subject_race_ethn), #American Indian or Alaska Native any race/ethn
        ) |>
  left_join(icd_dict |> select(code, acme_unly_cause_dth_desc = description), 
            by = c("acme_unly_cause_dth" = "code")) |>
  select(-c(num_races, num_races_drop))

#Cleanup
rm(icd_dict, dth_cod)

message("Race and ethnicity coding completed.")

### Step: write_trusted.R ###

message("Writing trusted data.")

dth_final <- dth_cln |>
  select(st_file_nbr, file_year, dataset_last_updated,decd_frst_nme:decd_brth_cty_fips_cd, decd_armf_fl:decd_mrtl_status, decd_preg_desc, decd_preg_cd, decd_educ_cd:decd_idsty, #demographic, birth stuff
         decd_res_nursing:decd_res_cty_twnshp_limits, decd_dth_dt:decd_dth_tm_modifier, decd_plce_dth_typ:decd_dth_cnty_fips_cd, #residence, death info
         dt_last_seen_day:cause_dth_othr, acme_unly_cause_dth, acme_unly_cause_dth_desc, mnl_unly_cause_dth, tobacco_contributed, injury_fl:injury_loc_transport_cd, mleyr:ypll_75, #injury, ypll
         subject_race_ethn, subject_race = race_decedent_6, subject_hisp, subject_not_hispanic:subject_white, subject_black, subject_african_american:subject_tribe_txt2, subject_asian_pi, subject_asian_indian:subject_notobtainable_race, #race
         subject_racebrg, sps_frst_nme:sps_lst_nme, sps_married_lst_nme, fthr_frst_nme:mthr_sfx_nme, #family
         ifrmt_type:ifrmt_addr_intl_cd, disp_mthd_burial:fd_sfx_nme, me_contacted:ca_injury_or_trauma_describe, me_autpsy, me_autpsy_res_avlbl, me_rlgs_objctn_to_autpsy:me_approved_dt, certfr_manner_dth:cmplt_fl, #burial etc
         c_injury_suicide:suicide_other, #created cod
         contains("rac_icd"), contains("rac_created"), #cause of death codes
         subject_race_mvr:subject_ethnic5c, #other race vars
  ) |> #this will catch anything else, although all variables should be captured above
  arrange(file_year, st_file_nbr)

#Cleanup
rm(dth_cln)

#Write final file
output_path <- str_c(output_folder, output_file) |>
  str_remove("\\.csv|\\.parquet") #remove if present, will get from other input

#Write combined file, if applicable
if ("combined" %in% trusted_format){
  
  if ("csv" %in% output_format){
    
    write_csv(dth_final, str_c(output_path, ".csv"))
    
  } 
  
  if ("parquet" %in% output_format){
    
    write_parquet(dth_final, str_c(output_path, ".parquet"))
  }
  
  message("Trusted combined file(s) written.")
}

if ("annual" %in% trusted_format){
  yrs <- unique(dth_final$file_year)
  
  if ("csv" %in% output_format){
    
    for (yr in yrs){
      dth_final |>
        filter(file_year == yr) |>
        write_csv(str_c(output_path, "_", yr, ".csv"), na = "")
    }
    
  } 
  
  if ("parquet" %in% output_format){
    
    for (yr in yrs){
      dth_final |>
        filter(file_year == yr) |>
        write_parquet(str_c(output_path, "_", yr, ".parquet"))
    }
  }
  message("Trusted annual file(s) written.")
}

#ADD
#If trusted file already exists, share info on changes since the last file was written similar to our email notification.
#Else be silent
rm(dth_final) #don't encourage analysis here
message("Trusted data written. Data cleaning completed.")
