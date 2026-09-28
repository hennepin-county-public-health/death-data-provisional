message("Step 3. Loading raw data.")

## Identify most recent file for each year ##
files <- tibble(file = list.files(input_folder, pattern = "MNDEATHS")) |>
  separate_wider_delim(file, delim = "_", names = c("year", NA, "date"), cols_remove = FALSE) |>
  mutate(date = str_remove(date, ".csv"),
         date = ymd(date)) |>
  filter(date == max(date), .by = year) |> #get most recent file for each data year
  slice(1, .by = year) #in case there are multiples with the same date (has happened)

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

message("Raw data loaded from the files below.")
print(files |> select(-file))

## Cleanup ##
rm(files, col_specs)
