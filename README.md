# Variance in Primary Care Performance between London ICBS and within NCL ICB


> Describe your project in 1-3 sentences.

This repository contains four R scripts comprising part of a tool to aid decision in making in allocating additional resource to GP Practices in North Central London Integrated Care Board (NCL ICB)

## Description

The scripts aim to illustrate variations in outcomes for people who use, or need to use, GP Practices in NCL ICB, in respect of three areas:

* Measures of local access to GPs
* Measures of patient engagement with GPs
* Measures of opportunity for improving operational data integrity within GPS

## Prerequisites

* R 4.2.2
* RTools 4.2

Packages (To check, run sessionInfo() in Console)

* tidyverse_2.0.0
* leaflet_2.2.2
* sf_1.0-16
* readxl_1.4.3
* htmlwidgets_1.6.2
* rmarkdown_2.24

## Getting Started

1. Clone the repository

2. Create a folder named "data" in the top level of the repository

3. In the data folder, add the following files:

	* The task dataset, task_dataset.csv
	* ICB polygons, Integrated_Care_Boards_April_2023_EN_BFC_-2681674902471387656.geojson
		* https://geoportal.statistics.gov.uk/datasets/da81300d4b624a0b81376416c8b5d90e_0/explore
	* LAD polygons, Local_Authority_Districts_May_2024_Boundaries_UK_BFC_-6788913184658251542.geojson
		* https://geoportal.statistics.gov.uk/datasets/f23beaa3769a4488b6a5f0cfb7980f51_0/explore
	* Ward polygons, Wards_May_2024_Boundaries_UK_BFE_2105195262474198835.geojson
		* https://geoportal.statistics.gov.uk/datasets/c9566ad511814e7bad24f0ed611c94b5_0/explore?location=54.959083%2C-3.316939%2C5.76
	* Postcode to ONS geographies lookup, PCD_OA21_LSOA21_MSOA21_LAD_AUG24_UK_LU.csv
		* https://geoportal.statistics.gov.uk/datasets/b8451168e985446eb8269328615dec62/about
	* MSOA to Ward lookup, Middle_Layer_Super_Output_Area_(2021)_to_Ward_to_LAD_(May_2023)_Lookup_in_England_and_Wales.csv
		* https://geoportal.statistics.gov.uk/datasets/ons::msoa-2021-to-ward-2023-to-lad-2023-best-fit-lookup-in-ew/about
	* MSOA level population lookup, sapemsoaquinaryagetablefinal.xlsx
		* https://www.ons.gov.uk/peoplepopulationandcommunity/populationandmigration/populationestimates/datasets/middlesuperoutputareamidyearpopulationestimatesnationalstatistics
	* ICB level population lookup, sapehealthgeogstablefinal.xlsx
		* https://www.ons.gov.uk/peoplepopulationandcommunity/populationandmigration/populationestimates/datasets/clinicalcommissioninggroupmidyearpopulationestimates

4. In the code folder, run the following scripts:

	* 1_data_quality_reporting.R (outputs a simple data quality report and variable frequency plots)
	* 2_gp_access_leaflets.R (outputs leaflets illustrating local access to GPs)
	* 3_patient_engagement_quantiles.R (identifies GP Practices repeatedly scoring low in patient engagement metrics)
	* 4_data_integrity_opportunity.R (identifies GP Practices with large opportunity to improve operational data integrity)

_Note: The scripts will automatically create the output folder and respective subfolders

unately the [ability to create a project from template](https://docs.gitlab.com/ee/user/project/working_with_projects.html#create-a-project-from-a-custom-template) is not available on the NHS England GitLab, so the process of using this template is rather manual.

## Acknowledgements
- North Central London Integrated Care Board, for task_dataset.csv and task_metadata.csv
- North Central London Integrated Care Board, for the README.md template this document is based on
