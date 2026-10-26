message("Step 1. Validating manually input values.")

#Ensure access to base R pipe. If this is a major obstacle, could switch to tidy one
req_r_version <- "4.1.0" #added in this release
cur_r_version <- getRversion()

if (cur_r_version < req_r_version){
  stop(
    paste0("This project requires R >= ", req_r_version, " because it uses the base R pipe. ",
           "Your R version is ", cur_r_version, ". Please upgrade before using this code.")
  )
}

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
rm(values, mn_counties, req_r_version, cur_r_version)

message("Manually input values validated.")