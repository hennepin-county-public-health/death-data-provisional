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
    c_cc_fentanyl = if_else(if_any(c(starts_with("cause_dth")), ~str_detect(., "FENTANYL") & !is.na(.)), 1, 0), #added 3/29/23
    
    c_covid = if_else(acme_unly_cause_dth == "U071", 1, 0),
    c_cc_covid = if_else(if_any(contains("rac_icd"), ~str_detect(., "U071")), 1, 0), 
    c_xylazine = if_else(if_any(c(starts_with("cause_dth")), ~str_detect(., "XYLAZINE|XYLOZINE") & !is.na(.)), 1, 0), #added 3/15/23
    
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