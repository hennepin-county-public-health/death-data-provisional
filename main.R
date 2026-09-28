#Set mandatory values
input_folder <- NULL
output_folder <- NULL
output_file <- NULL #year will be appended after if "annual" format is chosen
output_format <- NULL # "csv" or "parquet"
trusted_format <- c("combined", "annual")

#Run scripts
source("./steps/validate_inputs.R")
source("./steps/install_packages.R")
source("./steps/load_data.R")
source("./steps/cause_of_death.R")
source("./steps/race_ethn.R")
source("./steps/write_trusted.R")
