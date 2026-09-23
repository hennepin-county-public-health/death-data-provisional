#Set mandatory values
input_folder <- NULL
ouput_folder <- NULL
output_file <- NULL
output_format <- NULL # "csv" or "parquet"
trusted_format <- c("Combined", "Annual")

#Validate manually input values

#Run scripts
source("./steps/install_packages.R")
source("./steps/load_data.R")
