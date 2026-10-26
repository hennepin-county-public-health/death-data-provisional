#Will want to occasionally re-run this to update package versions.
#After update, re-run the process to ensure package updates aren't breaking.
#These changes aren't made to global library (just project) so won't affect other work
renv::init(bare = TRUE)

package_dependencies <- c(
  "dplyr", 
  "tibble",
  "tidyr", 
  "lubridate", 
  "stringr", 
  "purrr", 
  "readr", 
  "tidyselect",
  "arrow", 
  "readxl" 
)

install.packages(package_dependencies)

renv::snapshot()

#https://rstudio.github.io/renv/articles/renv.html