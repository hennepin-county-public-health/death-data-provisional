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