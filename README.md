# Provisional death data

This repo contains code that can be used to perform standard cleaning and transformations on the provisional (weekly) Minnesota death file. This .readme file contains psuedocode, or step-by-by descriptions, that details how to execute the included code and describes what it does. The code itself is located in this same repo.

# Data cleaning and transformation

The data cleaning and transformations steps in this repo are broken down into short self-defined scripts that each accomplish a single task. Alternatively, they could be combined into a single, longer script, but this approach is designed to make the process easier to understand and adjust. As a result, this process uses the death_main.R script as an orchestrator. Within this script, users can set values specific to their use, as well as directly running the other small scripts from inside of it

## Modify the main

-   Define file path
-   Define file name
-   Define...

## Run the main script which will invoke the following steps

### Step X - Load data

Run load_data.R

### Step X - Geography

Run geography.R
