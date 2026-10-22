#This scripts appends each step together into a single script for users that prefer that.
#This should update on commit using the pre-commit Git hook. 
#This works through Git Bash. If someone with a different setup made commits I'm not quite sure what would happen.

steps_folder <- "./steps/"
comb_folder <- "./combined_steps/"
comb_file <- "all_steps_combined.R"

#List all individual files - read from main.R to get correct order
main_code <- readLines("./main.R")
steps <- main_code[grepl("^source", main_code)]
steps <- gsub("source.*steps\\/", "", steps)
steps <- gsub("(\\.R).*", "\\1", steps)

#Also use that script to grab the manual fields
inputs <- main_code[1:(which(main_code == "#Run scripts") - 2)]

#Create combined script
comb_script <- file(paste0(comb_folder, comb_file), open = "w")
update_text <- paste0("### Combined script last updated ", Sys.time(), " ###\n")
writeLines(update_text, comb_script)
writeLines(inputs, comb_script)

for (s in steps){
  writeLines(paste0("\n### Step: ", basename(s), " ###\n"), comb_script)
  step <- suppressWarnings(readLines(paste0(steps_folder, s))) #there's an irrelevant warning here. hide
  writeLines(step, comb_script)
  
}

close(comb_script)

#Write git hook that will auto-run this script on commit
hook_path <- ".git/hooks/pre-commit"

writeLines(c(
  "#!/bin/sh",
  "echo 'Updating combined R script'",
  "Rscript combined_steps/combine_steps.R",
  "git add combined_steps/all_steps_combined.R"
), hook_path)

Sys.chmod(hook_path, mode = "0755")

message("Combined script updated.")
