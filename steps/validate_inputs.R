message("Step 1. Validating manually input values.")

#Make a couple options case-insenstive
output_format <- tolower(output_format)
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

#Cleanup
rm(values)

message("Manually input values validated.")