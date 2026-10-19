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

message("Trusted data written. Data cleaning completed.")