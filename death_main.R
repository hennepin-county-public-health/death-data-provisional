## Install and load packages
# - do I need to load them here? Does that carry over?
# - check to make sure necessary packages are installed.
#- do we want to handle updates here too? Or maybe just set to a specific version
package_dependencies <- c(
  "tidyverse",
  "albert",
  "janitor",
  "arrow" #for now.. does this install have any dependencies that could be a problem?
)

uninstalled <- package_dependencies[!package_dependencies %in% rownames(installed.packages())]

if (length(uninstalled) != 0){
  for (p in uninstalled){
    
    if (p == "albert"){
      remotes::install_github("hennepin-county-public-health/albert")
    } else {
      install.packages(p)
    }
    
    print(paste0("Installed package: ", p))
  }

}

#Set important values
input_folder <- ""
input_file <- 

#Run scripts

