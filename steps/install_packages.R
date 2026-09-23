message("Loading packages.")

# Install packages
#- do we want to set version here too?
package_dependencies <- c(
  "tidyverse", #may be worth using the individual packages to prevent so much being loaded
  "janitor", #may be able to replace this depending on how it's used
  "arrow", #for now.. does this install have any dependencies that could be a problem?
  "readxl",
  "remotes", #install github package
  "albert"
)

#add general descriptions of how each package is used above

uninstalled <- package_dependencies[!package_dependencies %in% rownames(installed.packages())]

if (length(uninstalled) != 0){
  for (p in uninstalled){
    
    if (p == "albert"){
      remotes::install_github("hennepin-county-public-health/albert")
    } else {
      install.packages(p)
    }
    
    message(paste0("Installed package: ", p))
  }
  
}

#Load packages
library(tidyverse)
library(janitor)
library(readxl)
library(arrow)
library(albert)

#Clean up
rm(package_dependencies, uninstalled)


message("All required packages installed and loaded.")