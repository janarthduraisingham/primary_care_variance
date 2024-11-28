# Purpose: this script outputs leaflet choropleths illustrating local access to GPs

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
population_lookup <- read_excel("data/sapemsoaquinaryagetablefinal.xlsx", sheet = "Mid-2022 MSOA 2021", skip=3) # MSOA level population lookup
ward_lookup <- read_csv("data/Middle_Layer_Super_Output_Area_(2021)_to_Ward_to_LAD_(May_2023)_Lookup_in_England_and_Wales.csv") # MSOA to Ward lookup
icb_population_lookup <- read_excel("data/sapehealthgeogstablefinal.xlsx", sheet = "Mid-2021 ICB 2023", skip = 3) # ICB level population lookup

lad_polygons <- st_read("data/Local_Authority_Districts_May_2024_Boundaries_UK_BFC_-6788913184658251542.geojson") # LAD boundaries
icb_polygons <- st_read("data/Integrated_Care_Boards_April_2023_EN_BFC_-2681674902471387656.geojson") # ICB boundaries
ward_polygons <- st_read("data/Wards_May_2024_Boundaries_UK_BFE_2105195262474198835.geojson") # Ward boundaries
 
# Create output folder if non-existent
if (!(dir.exists("output"))) {
  
  dir.create("output")
  
}

# Create leaflets folder if non_existent

if (!(dir.exists("output/leaflets"))) {
  
  dir.create("output/leaflets")
  
}

# Compute Ward population
ward_population_lookup <- population_lookup %>%
  left_join(ward_lookup, by = c("MSOA 2021 Code" = "MSOA21CD")) %>%
  group_by(WD23CD, WD23NM) %>%
  summarise(total = sum(Total)) %>%
  ungroup()

# Join ONS geographies onto postcode level raw data
data_ons <- raw_data %>%
  left_join(postcode_lookup,
            by = c('postcode' = 'pcds'))

###
### ICB level leaflets
###


# Compute total qualified GP FTE per ICB
qualified_gp <- data_ons %>%
  filter(icb_name %in% c("NHS North Central London Integrated Care Board",
                         "NHS North West London Integrated Care Board",
                         "NHS North East London Integrated Care Board",
                         "NHS South East London Integrated Care Board",
                         "NHS South West London Integrated Care Board"
                         )) %>%
  group_by(icb_name) %>%
  summarise(qualified_gp_fte = sum(qualified_gp, na.rm=TRUE)) %>% # total GP FTE in ICB
            ungroup() %>%
  left_join(icb_population_lookup, by = c("icb_name" = "ICB 2023 Name")) %>% # join population data
  mutate(pop_per_gp = Total / qualified_gp_fte) # get population per GP FTE in ICB
  

gp_obj <- icb_polygons %>%
  left_join(qualified_gp, by = c("ICB23NM" = "icb_name")) %>%
  filter(!is.na(qualified_gp_fte)) %>%
  st_transform('+proj=longlat +datum=WGS84')


# Generate and save GP FTE per ICB leaflet

my_leaflet <- leaflet() %>%
  addTiles() %>%
  setView(lat=52.47949, lng=-1.90119, zoom=6.5) %>%
  addPolygons(data = gp_obj,
              fillColor = ~colorQuantile("Greens", qualified_gp_fte, n=5)(qualified_gp_fte),
              weight = 1,
              opacity = 1,
              color = 'white',
              dashArray = "3",
              fillOpacity = 0.7,
              label = ~paste0(ICB23NM, ": ", round(qualified_gp_fte), " Qualified GP FTE"),
              labelOptions = labelOptions(
                style = list("font-weight" = "normal", padding = "3px 8px"),
                textsize = "15px",
                direction = "auto")) %>%
  addProviderTiles("CartoDB.Positron")

saveWidget(my_leaflet, file="output/leaflets/gp_fte_icb.html", selfcontained = FALSE)


# Generate and save Population per GP FTE per ICB leaflet

my_leaflet <- leaflet() %>%
  addTiles() %>%
  setView(lat=52.47949, lng=-1.90119, zoom=6.5) %>%
  addPolygons(data = gp_obj,
              fillColor = ~colorQuantile("Reds", pop_per_gp, n=5)(pop_per_gp),
              weight = 1,
              opacity = 1,
              color = 'white',
              dashArray = "3",
              fillOpacity = 0.7,
              label = ~paste0(ICB23NM, ": ", round(pop_per_gp), " Population per Qualified GP FTE"),
              labelOptions = labelOptions(
                style = list("font-weight" = "normal", padding = "3px 8px"),
                textsize = "15px",
                direction = "auto")) %>%
  addProviderTiles("CartoDB.Positron")

saveWidget(my_leaflet, file="output/leaflets/population_per_gp_fte_icb.html", selfcontained = FALSE)

###
### Ward level leaflets
###

# Compute total qualified GP FTE per Ward

qualified_gp <- data_ons %>%
  filter(icb_name %in% c("NHS North Central London Integrated Care Board",
                         "NHS North West London Integrated Care Board",
                         "NHS North East London Integrated Care Board",
                         "NHS South East London Integrated Care Board",
                         "NHS South West London Integrated Care Board"
  )) %>%
  filter(icb_name == "NHS North Central London Integrated Care Board") %>% # UNCOMMENT TO LOOK AT NCL ICB ONLY 
  left_join(ward_lookup, by = c("msoa21cd" = "MSOA21CD")) %>% # join wards
  group_by(WD23CD) %>%
  summarise(qualified_gp_fte = sum(qualified_gp, na.rm=TRUE)) %>% # total GP FTE in Ward
  ungroup() %>%
  left_join(ward_population_lookup, by = c("WD23CD" = "WD23CD")) %>%
  mutate(pop_per_gp = total / qualified_gp_fte) # get population per GP FTE in Ward

# List of wards to crop leaflet to
ward_codes <- qualified_gp %>%
  select(WD23CD)

gp_obj <- ward_polygons %>%
  left_join(qualified_gp, by = c("WD24CD" = "WD23CD")) %>%
  filter(WD24CD %in% ward_codes$WD23CD) %>%
  st_transform('+proj=longlat +datum=WGS84')

### GP FTE per Ward

# Generate and save leaflet

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
              label = ~paste0(WD24NM, ": ", round(qualified_gp_fte), " Qualified GP FTE"),
              labelOptions = labelOptions(
                style = list("font-weight" = "normal", padding = "3px 8px"),
                textsize = "15px",
                direction = "auto")) %>%
  addProviderTiles("CartoDB.Positron")

saveWidget(my_leaflet, file="output/leaflets/gp_fte_ward.html", selfcontained = FALSE)


### Population per GP FTE per Ward

# Generate and save leaflet

my_leaflet <- leaflet() %>%
  addTiles() %>%
  setView(lat=52.47949, lng=-1.90119, zoom=6.5) %>%
  addRectangles(
    lng1 = -180, lat1 = -90, # Black background so Wards with no GPs show up as black
    lng2 = 180, lat2 = 90,
    color = NULL, 
    fillColor = "black",
    fillOpacity = 1
  ) %>%
  addPolygons(data = gp_obj,
              fillColor = ~colorQuantile("Reds", pop_per_gp, n=6)(pop_per_gp),
              weight = 1,
              opacity = 1,
              color = 'white',
              dashArray = "3",
              fillOpacity = 0.7,
              label = ~paste0(WD24NM, ": ", round(pop_per_gp), " Population per Qualified GP FTE"),
              labelOptions = labelOptions(
                style = list("font-weight" = "normal", padding = "3px 8px"),
                textsize = "15px",
                direction = "auto")) %>%
  addProviderTiles("CartoDB.Positron")

saveWidget(my_leaflet, file="output/leaflets/population_per_gp_fte_ward.html", selfcontained = FALSE)





