# Provisional death data

This repo contains code that can be used to perform standard cleaning and transformations on the provisional (weekly) Minnesota death file. This .readme file contains psuedocode, or step-by-by descriptions, that details how to execute the included code and describes what it does. The code itself is located in this same repo.

For additional documentation about working with the provisional death data, see *the data dictionary* and *some documentation describing the data.*

# Data cleaning and transformation

The data cleaning and transformations steps in this repo are broken down into short self-defined scripts that each accomplish a single task. Alternatively, they could be combined into a single, longer script, but this approach is designed to make the process easier to understand and adjust. As a result, this process uses the death_main.R script as an orchestrator. Within this script, users can set values specific to their use, as well as directly running the other small scripts from inside of it. You can also run them individually, but this approach is likely the simplest option for most people.

Throughout this repo, we use use a few pieces of terminology that are useful to know.

-   Raw data: this is the data in the original form you receive it, llikely from the Minnesota Department of Health Cloud Drive, completely unedited.

-   Trusted data: this is the data in its final form, after its gone through all necessary cleaning and transformation. This data should be a reliable source for analysis and reporting.

-   Intermediate data: this is data that exists somewhere in between raw and trusted. It's the results of code applied to raw data, but not yet in its final form.

## Modify the main

The first task of the death_main.R script is to ensure all R packages necessary for the code in this repo to run are installed. When run, the script will identify any missing R packages and install them. In general, this code relies on packages from the R Tidyverse.

The second purpose of the script is to set some values that will be unique to each user. These include:

-   Input folder path: define the location of the raw data. The scripts will pull data from this to clean and transform.
-   Input file name: the name of the raw file. This will likely be the name of the file as downloaded from the Cloud Drive.
-   Export folder path: the location the final trusted file will be written to.
-   Export file name: the name of the final trusted file.

It's strongly recommended that each analyst preserve the raw version of their data, rather than overwriting. This allows the analyst to go back and re-run code against the original data at any time to re-generated their trusted data or look for the cause of a discrepancy or error. In addition, it's often using to store raw and trusted data in different location or folders, so the two types of data are kept distinct.

## Run the main script which will invoke the following steps

### Step X - Load data

Run load_data.R

### Step X - Geography

Run geography.R

IDEAS

-   "extra": likely quality monitoring, delay monitoring?
