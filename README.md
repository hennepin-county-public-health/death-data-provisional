*The code in this repo is currently in development and not finalized.*

# Getting started

This repository (repo) contains R code for standard cleaning and transformation of the provisional (weekly) Minnesota death file. Running it will produce a finalized death file for reliable reporting and analysis. This repo is publicly available to reduce the duplication of work between local public health departments and make it easier for them to report data using the same standards. The description below provides a step-by-step description of how to run the code and describes what it does.

For additional documentation about working with the provisional death data, see the [data dictionary](https://github.com/hennepin-county-public-health/death-data-provisional/blob/main/documentation/Death%20data%20dictionary.xlsx) and **some documentation describing the data***.* All content in this repo, including documentation, was assembled by Minnesota local public health staff that are part of the Death Data Collaborative. The goal of this collaborative is to develop and share best practices for working with death data.

## Prerequisites

-   Download provisional death files to a folder on your computer.

-   Download R and and your preferred integrated developed environment (IDE) such as RStudio or Visual Studio Code.

# Cloning this repo

Running the death data cleaning code doesn't require extensive experience with GitHub, but users will need to download code from this repo to their local computer to run it. This is referred to as "cloning" a repo. All code files are located within the repo, along with these instructions and other documentation. Please read [Cloning a repository - GitHub Docs](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository) for information about how to clone this repo from your browser, or look for guidance specific to the software you prefer to use (RStudio, Visual Studio Code). Since this repo is public, users do not need a GitHub account to clone it.

*Think through this guidance. They don't need to go through all steps, could just download it from browser. Develop description for both options.*

# Data cleaning and transformation

Code for data cleaning and transformation is broken down into several short R scripts, each intended to accomplish a particular task. This format was intended to make the code easier to understand than if it was combined into a single longer script. As a result, the *main.R* file is used as an "orchestrator" file. Running this script will run each individual task in the correct order, producing a cleaned file.

If you prefer running all code in a single script, use *combined_steps/all_steps_combined.R* instead. The description below will still be relevant.

Throughout this text, we use use a couple pieces of terminology that are useful to know.

-   Raw data: this is data in the original form you receive it, without any changes. Raw provisional death data comes directly from the Minnesota Department of Health (MDH) Cloud Drive. Please keep the original file names (i.e. 2026_MNDEATHS_20260921.csv) because having the date in the file name is important for this process.

-   Trusted data: this is data in its final form, after it's been cleaned and transformed. This data is a reliable source for analysis and reporting.

## Modify main.R

First, open the *death-data-provisional* R project in your cloned repo using your IDE.

All code in this repo can be run using *main.R*. It requires the user to fill in a few pieces of information unique to them before running the code. This is the only part of running the code that should require any manual input. Users must set the following values:

-   **Input folder**: the path to the folder where the raw data is stored. All files in this folder will be used. Like all strings in R, the folder path should be within quotes.

    -   Example: "*C:/Users/\<user\>/Documents/provisional_death_files/*"
    -   Keep in mind that back-slashes get messy in R, so you should use forward-slashes in your path. Leave a trailing forward-slash at the end of your path, consistent with the example.

-   **Output folder**: the path to the folder where the trusted file should be written. We recommend saving your trusted data to a different location than your raw files.

    -   The default option will create a new folder to store this data inside the downloaded repo. Keep this, or add your preferred destination.

-   **Output file name**: the name of the final trusted file.

    -   The default option is *trusted_death_data*. Users can adjust this as needed.

    **Output format**: the preferred file format of the trusted data. Both "csv" and "parquet" are supported options.

    -   To write both types of files, keep the default `output_format <- c("csv", "parquet")`. Otherwise, remove one of the two file types.

-   **Trusted format:** select whether you want to write a single trusted file that includes all years of data, separate files for each year, or both.

    -   Similar to the last argument, keep `trusted_format <- c("combined", "annual")` to write both types of files or remove one.
    -   The year will be appended the name of annual files, for instance *mn_provisional_data_2026.csv*.

-   **Residence county filter**: add the name of one or more counties you'd like data for. The trusted data will be filtered to only include these counties using the *decd_res_cnty* variable. Otherwise, leaving this blank will return data for all Minnesota counties.

    -   Examples: `residence_county <- c("TODD")` or `residence_county <- c("TODD", "STEARNS")`.

The remainder of the orchestration script will run each step in order. No manual changes should be necessary. Users will receive occasional messages in their console as each step runs and complete. Once all steps are completed, they should find the trusted data saved in their specified folder. The code generally shouldn't take more than a minute to finish, although it may be a bit slower the first time it's run.

## The main script will execute the following steps

Each step is executed in *main.R* using code like `source("./steps/validate_inputs.R")`. The dot at the beginning of the path is shorthand for a reference to your current working directory (the cloned repo). So, *main.R* looks inside the *steps* folder in the repo to find each the code for each step.

### Step 1. Validate input values

This quick step makes sure all necessary manual values were added, and makes sure the values are valid when relevant.

### Step 2. Install and load packages

This step ensures all required R packages are installed and loads them for future steps. Required packages are: *tidyverse, janitor, arrow, readxl, remotes,* and *albert.*

\**And potentially that they're the correct version.*

### Step 3. Load data

This step reads in the raw data that will be transformed in future steps. New weekly files are cumulative, meaning each new file contains all records from the previous one. As a result, this step will seek out the most recent file for each year to read. This step pulls column formatting metadata from the data dictionary in this repo.

### Step 4. Cause of death coding

Once the data has been loaded, cleaning and transformation can begin. First, this step creates cause of death categories based on the ICD-10 codes of each record. For a list of created categories, see ***XXXXX***. These categories were agreed upon by members of the death data collaborative.

### Step 5. Other transformations, including race and ethnicity coding

After cause of death coding, this step performs a few addition data cleaning tasks. The biggest is creating a combined race and ethnicity category from the many related variables included in the death data. This code also includes some smaller tasks like creating a measure of years of potential life lost (YPLL) and removing inconsistent missing placeholder values.

### Step 6. Write trusted data

Finally, this step arranges the variables in the data and writes the trusted file. After this is executed, the process is complete.

## Additional ideas

The directions above cover everything needed to cleaned weekly death files so they're ready for analysis and reporting. However, there are opportunities for adding additional features to trusted data. A couple ideas are listed below. Members of the Death Data Collaborative group have related code that can be shared if there's any interest.

**Age adjustment**

In addition to presenting crude death rates, reporting and analysis often benefits from using age-adjusted deaths rates.

**Death delay monitoring**

There is some delay between when a death occurs and when it's included in the death data. The length of the delay depends on several factors, especially the complexity of the investigation that stems from factors like cause of death. Knowing how delayed weekly data is, especially by cause of death, can be important for using weekly data for monitoring population health.

For instance, knowing 95% of deaths from a certain cause are present in the data within 4 months of occurring can help inform how you can monitor that group of deaths.

**Garbage code monitoring**

Garbage codes are cause of death codes that provide information that's inaccurate or not useful. They include things like impossible causes of death, non-specific causes, intermediate causes, and other codes that shouldn't be considered an underlying cause of death.

**Geocoding**

Users may wish to geocode location information for more accurate reporting.

## To do

-   Need to determine standard race and ethnicity names. Still have questions to address in our internal data after reviewing Olmsted's process.

-   Rename documentation so it's in a consistent format

-   Maybe join with more info about underlying cause of death rankings

-   Add script that combines all steps into a single files. Probably in another folder. Add note to description that alternatively you can run all the code in a single script.
