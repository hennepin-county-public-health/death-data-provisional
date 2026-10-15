_The code in this repo is currently in development and not finalized._

# Provisional death data

This repo contains R code that does standard cleaning and transformation on the provisional (weekly) Minnesota death file. This is made publicly available to reduce duplication of work between local public health departments and make it easier for them report data using the same standards. The end result of this code is a finalized death file that can be reliably used for reporting and analysis. These step-by-by descriptions detail how to execute the code and describe what it does. The actual code files are located in this Github repository as well.

You can read through this directly on Github, or if it's more convenient you can download this .readme file and open it on your device in programs such as RStudio, notepad, or Microsoft Word. Before running the code in this repository, users will first need to clone this repository to their computer to make the code available to them. Please read [Cloning a repository - GitHub Docs](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository) for more information about how to do this, or look for guidance specific to the software you prefer to use (RStudio, Visual Studio Code).

For additional documentation about working with the provisional death data, see the **data dictionary** and **some documentation describing the data***.* All content in this repo, including documentation, was assembled by Minnesota local public health staff that are part of the Death Data Collaborative. The goal of this collaborative is to develop and share best practices for working with death data.

# Data cleaning and transformation

Code for data cleaning and transformation is broken down into several short R scripts, each intended to accomplish a particular step. This approach was intended to make the code easier to understand than if it was combined into a single longer script. As a result, the provisional_main.R file is used as an "orchestrator" file. Running this script will run each individual task in the correct order, ending with a cleaned file.

Throughout this text, we use use a few pieces of terminology that are useful to know.

-   Raw data: this is data in the original form you receive it, without any changes. Raw provisional death data likely comes directly from the Minnesota Department of Health (MDH) Cloud Drive. Please keep the original file names (i.e. 2026_MNDEATHS_20260921.csv) because having the date in the file name is important for this process.

-   Trusted data: this is data in its final form, after it's been cleaned and transformed. This data should be a reliable source for analysis and reporting.

## Modify main.R

Although users can run all code in this repository through main.R it should be pretty simple. In the first part of the script, users should set a few values that will be unique to them. This is the only step that includes manual changes. Users must set the following values:

-   Input folder: the path to the folder where the raw data is stored. All files in this folder will be used.
-   Export folder: the path to the folder where the trusted file should be written. Should be a different folder than specified for input.
-   Export file name: the name of the final trusted file.
-   Output format: the preferred file format of the trusted data. Both "csv" and "parquet" are supported options.
-   Trusted format: if there are multiple years of data, should they be written to a single combined file, separate annual files, or both? Leave `trusted_format <- c("Combined", "Annual")` for both, otherwise remove the unwanted option.

The remainder of the orchestration script will run each step in order. No manual changes should be necessary. Users should receive occasional messages in their console as each step runs and complete. Once all steps are completed, they should find the trusted data saved in their specified folder.

## The main script will execute the following steps

### Step 1. Validate input values

This quick step makes sure all necessary manual values were added, and makes sure the values are valid when relevant.

### Step 2. Install and load packages

This step ensures all required R packages are installed and loads them for future steps. Required packages are: *tidyverse, janitor, arrow, readxl, remotes,* and *albert.*

\**And potentially that they're the correct version.*

### Step 3. Load data

This step reads in raw data, which will be transformed in future steps. New weekly files are cumulative, meaning each new files contains all records from the previous one. As a result, this step will seek out the most recent file associated with each year included in the folder, then read that in. This step pulls column formatting information from the data dictionary in this repo.

This step is not designed to read in out-of-state files because they're no longer regularly available.

\***Would this detail a concern when publishing this publicly?**

### Step 4. Cause of death coding

Once the data has been loaded, cleaning and transformation can begin. First, this step creates cause of death categories based on the ICD-10 information associated with each record. For a list of created categories, see *XXXXX*. These categories were agreed upon by members of the death data collaborative.

### Step 5. Other transformations, including race and ethnicity coding

After cause of death coding, this steps performs a few addition data cleaning tasks. The biggest is creating a combined race and ethnicity category from the many related variables included in the death data. This code also includes some smaller tasks like creating a measure of years of potential life lost (YPLL) and removing inconsistent missing placeholder values.

### Step 6. Write trusted data

Finally, this step arranges the variables in the data and writes the trusted file. After this is executed, the process is complete.

### Additional ideas

The description above covers all of the steps needed to transform Minnesota's weekly death data into a clean and ready-for-analysis file. *Something about the group having code related to all of this, unless we don't want to extend ourselves that way.*

-   Age adjustment

-   Junk code monitoring

-   Death delay monitoring

-   Geocoding

To do/notes

-   Might we eventually include python (or other) code for the same process? If so, should that affect how the repo is structured?

-   Mention pull requests if there are any changes. Can we change a setting so people can't push back to main? Option for people to develop in other branches

-   How edited do we want the data dict to be?

-   Need to determine standard race and ethnicity names. Still have questions to address in our internal data after reviewing Olmsted's process.

-   Rename documentation so it's in a consistent format

-   Maybe join with more info about underlying cause of death rankings
