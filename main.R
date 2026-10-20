#Set mandatory values
input_folder <- NULL
output_folder <- "./trusted_data/"
output_file <- "trusted_death_data"
output_format <- c("csv", "parquet")
trusted_format <- c("combined", "annual")

#If you want to filter the trusted data to a particular county or counties, specify here
residence_county <- c("", "")

#Run scripts
source("./steps/validate_inputs.R")
source("./steps/install_packages.R")
source("./steps/load_data.R")
source("./steps/cause_of_death.R")
source("./steps/race_ethn.R")
source("./steps/write_trusted.R")
