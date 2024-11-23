# Purpose: this script outputs choropleth leaflets for various metrics

# Import libraries
library(tidyverse)
library(leaflet)
library(sf)
library(readxl)
library(htmlwidgets)
library(rmarkdown)

# Import  data
raw_data <- read.csv("data/task_dataset.csv") # task dataset
postcode_lookup <- read_csv("data/PCD_OA21_LSOA21_MSOA21_LAD_AUG24_UK_LU.csv") # postcode to ONS geography lookup
population_lookup <- read_excel("data/sapemsoaquinaryagetablefinal.xlsx", sheet = "Mid-2022 MSOA 2021", skip=3) # MSOA population lookup
msoa_polygons <- st_read("data/Middle_layer_Super_Output_Areas_December_2021_Boundaries_EW_BFC_V7_303696399389513507.geojson") # MSOA boundaries
lad_polygons <- st_read("data/Local_Authority_Districts_May_2024_Boundaries_UK_BFC_-6788913184658251542.geojson") # LAD boundaries
icb_polygons <- st_read("data/Integrated_Care_Boards_April_2023_EN_BFC_-2681674902471387656.geojson") # ICB boundaries

# Join ONS geographies onto postcode level raw data
data_ons <- raw_data %>%
  left_join(postcode_lookup,
            by = c('postcode' = 'pcds'))

# Compute total qualified GP FTE per Local Authority District
qualified_gp <- data_ons %>%
  filter(icb_name %in% c("NHS North Central London Integrated Care Board",
                         "NHS North West London Integrated Care Board",
                         "NHS North East London Integrated Care Board",
                         "NHS South East London Integrated Care Board",
                         "NHS South West London Integrated Care Board"
                         )) %>%
  left_join(population_lookup, by = c("msoa21cd" = "MSOA 2021 Code")) %>% # join population data
  group_by(ladcd) %>%
  summarise(qualified_gp_fte = sum(qualified_gp, na.rm=TRUE), # total GP FTE in LAD
            population = sum(Total, na.rm=TRUE)) %>% # total population in LAD
  ungroup() %>%
  mutate(pop_per_gp = population / qualified_gp_fte) # get population per GP FTE in LAD 
  


gp_obj <- lad_polygons %>%
  left_join(qualified_gp, by = c("LAD24CD" = "ladcd")) %>%
  filter(!is.na(qualified_gp_fte)) %>%
  st_transform('+proj=longlat +datum=WGS84')

#gp_obj <- msoa_polygons %>%
#  left_join(qualified_gp, by = c("MSOA21CD" = "msoa21cd")) %>%
#  filter(!is.na(qualified_gp_fte)) %>%
#  st_transform('+proj=longlat +datum=WGS84') 

# Define function to generate and save leaflet

my_leaflet <- leaflet() %>%
  addTiles() %>%
  setView(lat=52.47949, lng=-1.90119, zoom=6.5) %>%
  addPolygons(data = gp_obj,
              fillColor = ~colorQuantile("Greens", qualified_gp_fte, n=6)(qualified_gp_fte),
              weight = 1,
              opacity = 1,
              color = 'white',
              dashArray = "3",
              fillOpacity = 0.7,
              label = ~paste0(LAD24NM, ": ", round(qualified_gp_fte), " Qualified GP FTE"),
              labelOptions = labelOptions(
                style = list("font-weight" = "normal", padding = "3px 8px"),
                textsize = "15px",
                direction = "auto")) %>%
  addProviderTiles("CartoDB.Positron")

saveWidget(my_leaflet, file="output/gp_lad_lflt.html", selfcontained = FALSE)


pop_per_gp_lflt <- leaflet() %>%
  addTiles() %>%
  setView(lat=52.47949, lng=-1.90119, zoom=6.5) %>%
  addPolygons(data = gp_obj,
              fillColor = ~colorQuantile("Reds", pop_per_gp, n=6)(pop_per_gp),
              weight = 1,
              opacity = 1,
              color = 'white',
              dashArray = "3",
              fillOpacity = 0.7,
              label = ~paste0(MSOA21NM, ": ", round(pop_per_gp), " Population per Qualified GP FTE"),
              labelOptions = labelOptions(
                style = list("font-weight" = "normal", padding = "3px 8px"),
                textsize = "15px",
                direction = "auto")) %>%
  addProviderTiles("CartoDB.Positron")

saveWidget(pop_per_gp_lflt, file="output/pop_per_gp_msoa_lflt.html", selfcontained = FALSE)

