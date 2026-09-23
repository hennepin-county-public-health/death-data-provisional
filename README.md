# Provisional death data

This repo contains R code that does standard cleaning and transformation on the provisional (weekly) Minnesota death file. This is made publicly available to reduce duplication of work between local public health departments and make it easier for them report data using the same standards. The end result of this code is a finalized death file that can be reliably used for reporting and analysis. These step-by-by descriptions detail how to execute the code and describe what it does. The actual code files are located in this Github repository as well.

You can read through this directly on Github, or if it's more convenient you can download this .readme file and open it on your device in programs such as RStudio, notepad, or Microsoft Word. Before running the code in this repository, users will first need to clone this repository to their computer to make the code available to them. Please read [Cloning a repository - GitHub Docs](https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repository) for more information about how to do this, or look for guidance specific to the software you prefer to use (RStudio, Visual Studio Code).

For additional documentation about working with the provisional death data, see the **data dictionary** and **some documentation describing the data***.* All content in this repo, including documentation, was assembled by Minnesota local public health staff that are part of the Death Data Collaborative. The goal of this collaborative is to develop and share best practices for working with death data.

# Data cleaning and transformation

Code for data cleaning and transformation is broken down into several short R scripts, each intended to accomplish a particular task. This approach was intended to make the code easier to understand than if it was combined into a single longer script. As a result, the provisional_main.R file is used as an "orchestrator" file. Running this script will run each individual task in the correct order, ending with a cleaned file.

Throughout this text, we use use a few pieces of terminology that are useful to know.

-   Raw data: this is data in the original form you receive it, without any changes. Raw provisional death data likely comes directly from the Minnesota Department of Health (MDH) Cloud Drive.

-   Trusted data: this is data in its final form, after it's been cleaned and transformed. This data should be a reliable source for analysis and reporting.

## Modify main.R

Although users can run all code in this repository through main.R it should be pretty simple. In the first part of the script, users should set a few values that will be unique to them. This is the only step that includes manual changes. Users must set the following values:

-   Input folder: the path to the folder where the raw data is stored.
-   Export folder: the path to the folder where the trusted file should be written.
-   Export file name: the name of the final trusted file.
-   Output format: the preferred file format of the trusted data. Both "csv" and "parquet" are supported options.
-   Trusted format: if there are multiple years of data, should they be written to a single combined file, separate annual files, or both? \`Leave trusted_format \<- c("Combined", "Annual")\`

Additionally, users can choose to supply information to the following values:

-   Input file name pattern: a common naming pattern shared across all raw data. By default, all data in the input folder will be used, but supplying this will filter data down

-   Input file name: the name of the raw file. This will likely be the name of the file as downloaded from the Cloud Drive.

    -   *No this will likely be a bunch of files, so probably don't want to take this approach. Maybe can set an optional value that would only take files with a certain naming scheme.*

It's strongly recommended that each analyst preserve the raw version of their data, rather than overwriting. This allows the analyst to go back and re-run code against the original data at any time to re-generated their trusted data or look for the cause of a discrepancy or error. In addition, it's often using to store raw and trusted data in different location or folders, so the two types of data are kept distinct.

Finally, the remainder of the orchestration script will run each task inorder. It's of course possible to run the tasks individually as well, but keep in mind that they should be executed in the order described in this guide. *In addition, you'd need to manually specify the values described in this guide as well.*

## Run the main script which will invoke the following steps

### Step 1 - Install and load packages

The first script that should be run ensures all necessary R packages are installed and loaded. *And potentially that they're the correct version.*

### Step 2 - Load data

Run load_data.R

New files are typically available each week, and for two different years at a time. Even after a year ends, MDH analysts See *documentation* for a full discussion of how provisional files arrive (*probably just move all of this there)*.

### Step 3 - Cause of death coding

Run geography.R

IDEAS

-   "extra": likely quality monitoring, delay monitoring?

-   Might we eventually include python (or other) code for the same process? If so, should that affect how the repo is structured?

-   The goal is to make sure agencies have consistent reporting

-   Example age-adjusted death rate script

-   Mention pull requests if there are any changes. Can we change a setting so people can't push back to main? Option for people to develop in other branches

-   Space to add their own code?
