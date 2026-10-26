message("Step 2. Loading packages.")

#Packages are installed in a local renv. See renv_manage.R for more information.
#The command below will ensure all packages specified in renv are installed and are the correct version.
renv::restore(prompt = FALSE)

#Load packages
library(dplyr)
library(tidyr)
library(lubridate)
library(stringr)
library(purrr)
library(readr)
library(tibble)
library(tidyselect)
library(readxl)
library(arrow)

#Rather than loading the entire albert package/dependencies, read in this single function
source("https://raw.githubusercontent.com/hennepin-county-public-health/albert/refs/heads/main/R/consult_dictionary.R")

message("All required packages installed and loaded.")