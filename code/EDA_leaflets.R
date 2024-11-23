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
lad_polygons <- st_read("data/Local_Authority_Districts_May_2024_Boundaries_UK_BFC_-6788913184658251542.geojson")

# Join ONS geographies onto postcode level raw data
data_ons <- raw_data %>%
  left_join(postcode_lookup,
            by = c('postcode' = 'pcds'))

# Compute total qualified GP FTE per Local Authority District
qualified_gp <- data_ons %>%
  left_join(population_lookup, by = c("msoa21cd" = "MSOA 2021 Code")) %>% # join population data
  group_by(ladcd) %>%
  summarise(qualified_gp_fte = sum(qualified_gp, na.rm=TRUE), # total GP FTE in LAD
            population = sum(Total, na.rm=TRUE)) %>% # total population in LAD
  ungroup() %>%
  mutate(pop_per_gp = population / qualified_gp_fte) # get population per GP FTE in LAD


gp_obj <- lad_polygons %>%
  left_join(qualified_gp, by = c("LAD24CD" = "ladcd")) %>%
  st_transform('+proj=longlat +datum=WGS84')

# GP FTE MSOA leaflet

gp_lflt <- leaflet() %>%
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

saveWidget(gp_lflt, file="output/gp_lad_lflt.html", selfcontained = FALSE)

normalised_gp_lflt <- leaflet() %>%
  addTiles() %>%
  setView(lat=52.47949, lng=-1.90119, zoom=6.5) %>%
  addPolygons(data = gp_obj,
              fillColor = ~colorQuantile("Reds", pop_per_gp, n=6)(pop_per_gp),
              weight = 1,
              opacity = 1,
              color = 'white',
              dashArray = "3",
              fillOpacity = 0.7,
              label = ~paste0(LAD24NM, ": ", round(pop_per_gp), " Population per Qualified GP FTE"),
              labelOptions = labelOptions(
                style = list("font-weight" = "normal", padding = "3px 8px"),
                textsize = "15px",
                direction = "auto")) %>%
  addProviderTiles("CartoDB.Positron")

saveWidget(normalised_gp_lflt, file="output/normalised_gp_lad_lflt.html", selfcontained = FALSE)

# slots leaflet

#slots_lflt <- leaflet() %>%
#  addTiles() %>%
#  setView(lat=52.47949, lng=-1.90119, zoom=6.5) %>%
#  addPolygons(data = newobj,
#              fillColor = ~colorQuantile("Greens", count, n=6)(count),
#              weight = 1,
#              opacity = 1,
#              color = 'white',
#              dashArray = "3",
#              fillOpacity = 0.7,
#              label = ~paste0(lad20nm, ": ", 
#                              format(count, big.mark = ","), " slots (", round(slots_per_1000), " slots/1000 elig pop)"),
#              labelOptions = labelOptions(
#                style = list("font-weight" = "normal", padding = "3px 8px"),
#                textsize = "15px",
#                direction = "auto")) %>%
#  addProviderTiles("CartoDB.Positron")

#saveWidget(slots_lflt, file="slots_lflt.html", selfcontained = TRUE)

# SCATTER PLOT TO FIND NON SATURATED AREAS

sessions_raw <- read_sas("input/slots_and_donations.sas7bdat") %>%
  group_by(postcode) %>%
  summarise(slots = sum(slots),
            donations = sum(donations)) %>%
  ungroup()

# msoa lookup

msoa_lu <- read_csv("input/pcd_oa.csv") %>%
  mutate(postcode=pcds)

# Join msoa
sessions <- merge(sessions_raw, msoa_lu, by.x="postcode", by.y="pcds") %>%
  select(postcode,
         slots,
         donations,
         oa21cd,
         msoa21cd,
         lsoa21cd,
         lsoa21nm,
         msoa21nm) %>%
  group_by(msoa21cd,
           msoa21nm) %>%
  summarise(slots = sum(slots),
            donations = sum(donations)) %>%
  ungroup() %>%
  merge(pop, by.x = 'msoa21cd', by.y ='msoa21cd') %>%
  mutate(slots_per_1000_elig = 1000 * slots / eligible) %>%
  mutate(dons_per_access = donations / slots_per_1000_elig,
         dons_per_slot = donations / slots)

dons_per_slot <- ggplot(sessions, aes(x=dons_per_slot)) +
  geom_histogram() +
  theme_classic() +
  ggtitle("Histogram of collections per slot") +
  xlab("Collections per slot") +
  ylab("Number of MSOAs")

donations_slots_scatter <- ggplot(filter(sessions, slots<2000), aes(x=slots, y=donations)) +
  geom_point() +
  theme_classic() +
  ggtitle("Scatter plot of collections versus bookable slots") +
  ylab("Collections") +
  xlab("Bookable slots") +
  geom_smooth(se=T)
#geom_text(label=filter(sessions, slots <100000)$msoa21nm) +

# linear model

lm_data <- filter(sessions, slots<2000) %>%
  group_by(slots) %>%
  summarise(avg_dons = mean(donations)) %>%
  ungroup()

dons_slots_lm <- lm(donations ~ slots, data=filter(sessions, slots<2000))
summary(dons_slots_lm)

lm_scatter <- ggplot(lm_data, aes(x=slots, y=avg_dons)) +
  geom_point() +
  theme_classic() +
  ggtitle("Scatter plot of average collections versus bookable slots") +
  ylab("Average Collections") +
  xlab("Bookable slots") +
  geom_smooth(se=T)

plot(dons_slots_lm$fitted, dons_slots_lm$residuals, main="Residuals vs Fitted Values",
     xlab = "Fitted Collections Value",
     ylab = "Residual")
plot(dons_slots_lm$fitted, stdres(dons_slots_lm), main="Standardised Residuals vs Fitted Values")

dons_per_access_slots_scatter <- ggplot(filter(sessions, slots<10000), aes(x=slots, y=dons_per_access)) +
  geom_point() +
  theme_classic() +
  #geom_text(label = filter(sessions, slots <10000)$msoa21nm) +
  ggtitle("Scatter plot of collections per local access against bookable slots") +
  ylab("Collections per local access") +
  xlab("Bookable slots")

dons_pop_scatter <- ggplot(sessions, aes(x=pop, y=donations)) +
  geom_point() +
  theme_classic() +
  xlab("Local population") +
  ylab("Collections") +
  ggtitle("Scatter plot of local collections against local population")

lt_2000_slots <- sessions %>%
  filter(slots <= 2000)

pop_hist <- ggplot(lt_2000_slots, aes(x=eligible)) +
  geom_histogram() +
  theme_classic() +
  ggtitle("Histogram of local eligible population <2000 slot MSOAs") +
  xlab("Eligible population") +
  ylab("Number of MSOAs")

msoa_pop <- read_csv("input/msoa_pop.csv")

nat_pop_hist <- ggplot(filter(pop, eligible>0), aes(x=eligible)) +
  geom_histogram() +
  theme_classic() +
  ggtitle("Histogram of local eligible population across all MSOAs") +
  xlab("Local population") +
  ylab("Number of MSOAs")

### adjusted elig pop leaflet

adj_eligible <- leaflet() %>%
  addTiles() %>%
  setView(lat=52.47949, lng=-1.90119, zoom=6.5) %>%
  addPolygons(data = newobj,
              fillColor = ~colorQuantile("Greens", adj_elig, n=6)(adj_elig),
              weight = 1,
              opacity = 1,
              color = 'white',
              dashArray = "3",
              fillOpacity = 0.7,
              label = ~paste0(msoa21nm, ": ", adj_elig, "adjusted elig pop"),
              labelOptions = labelOptions(
                style = list("font-weight" = "normal", padding = "3px 8px"),
                textsize = "15px",
                direction = "auto")) %>%
  addProviderTiles("CartoDB.Positron")

saveWidget(adj_eligible, file="adjusted_eligible_lflt.html", selfcontained = TRUE)

### eligible pop > 6k leaflet

newobj_6000 <- newobj %>%
  filter(eligible > 6000)

eligible_6000 <- leaflet() %>%
  addTiles() %>%
  setView(lat=52.47949, lng=-1.90119, zoom=6.5) %>%
  addPolygons(data = newobj_6000,
              fillColor = ~colorQuantile("Greens", eligible, n=6)(eligible),
              weight = 1,
              opacity = 1,
              color = 'white',
              dashArray = "3",
              fillOpacity = 0.7,
              label = ~paste0(msoa21nm, ": ", eligible, " elig pop"),
              labelOptions = labelOptions(
                style = list("font-weight" = "normal", padding = "3px 8px"),
                textsize = "15px",
                direction = "auto")) %>%
  addProviderTiles("CartoDB.Positron")

saveWidget(eligible_6000, file="eligible_6000_lflt.html", selfcontained = TRUE)

### adjusted eligible pop > 6k leaflet

newobj_adj_6000 <- newobj_6000 %>%
  filter(adj_elig > 6000)

adj_eligible_6000 <- leaflet() %>%
  addTiles() %>%
  setView(lat=52.47949, lng=-1.90119, zoom=6.5) %>%
  addPolygons(data = newobj_adj_6000,
              fillColor = ~colorQuantile("Greens", adj_elig, n=6)(adj_elig),
              weight = 1,
              opacity = 1,
              color = 'white',
              dashArray = "3",
              fillOpacity = 0.7,
              label = ~paste0(msoa21nm, ": ", adj_elig, " adjusted elig pop"),
              labelOptions = labelOptions(
                style = list("font-weight" = "normal", padding = "3px 8px"),
                textsize = "15px",
                direction = "auto")) %>%
  addProviderTiles("CartoDB.Positron")

saveWidget(adj_eligible_6000, file="adjusted_eligible_6000_lflt.html", selfcontained = TRUE)

# Postcode analysis

postsector_pop <- read_csv("input/postsector_pop.csv")

postcode_data <- sessions_raw %>%
  mutate(dons_per_slot = donations / slots)

# compute post sector
postcode_data$postsector = substr(postcode_data$postcode, 1, nchar(postcode_data$postcode)-2)

#join population eetimates
postcode_data <- postcode_data %>%
  left_join(postsector_pop, by = c("postsector" = "postsector"))

postcode_scatter <- ggplot(postcode_data, aes(x = slots, y = donations)) +
  geom_point() +
  geom_smooth() +
  theme_classic() +
  ggtitle("Scatter plot of donations per slot by postcode") +
  xlab("Slots in postcode in last 6 months") +
  ylab("Donations in postcode in last 6 momths")

postcode_histogram <- ggplot(postcode_data, aes(x=dons_per_slot)) +
  geom_histogram() +
  ggtitle("Histogram of donations per slot by postcode") +
  xlab("Donations per slot") +
  ylab("Postcodes") +
  theme_classic()


# aggregate to post sector level
postsector_data <- postcode_data %>%
  group_by(postsector) %>%
  summarise(slots = sum(slots),
            donations = sum(donations),
            pop = sum(pop)) %>%
  ungroup() %>%
  mutate(dons_per_slot = donations / slots)

postsector_scatter <- ggplot(filter(postsector_data, slots<30000), aes(x = slots, y = donations)) +
  geom_point() +
  geom_smooth() +
  theme_classic() +
  ggtitle("Scatter plot of donations per slot by postsector") +
  xlab("Slots in postsector") +
  ylab("Donations in postsector")

lt_2000_ps <- filter(postsector_data, slots < 2000)

postsector_histogram <- ggplot(postsector_data, aes(x=dons_per_slot)) +
  geom_histogram() +
  ggtitle("Histogram of donations per slot by postsector") +
  xlab("Donations per slot") +
  ylab("Postsectors") +
  theme_classic()



postsector_pop <- ggplot(lt_2000_ps, aes(x=pop)) +
  geom_histogram() +
  ggtitle("Histogram of population in postsectors with < 2000 slots in last 6 months") +
  theme_classic() +
  xlab("Total population") +
  ylab("Postsectors")

# get age histogram of current <2000 slot programs
postsector_age_structure <- read_csv("input/insite_postsector_age.csv") %>%
  mutate(pop8_prop = pop8/total,
         working_age_prop = (pop2 + pop3 + pop4 + pop5 + pop6 + pop7)/total)

# remove spaces in postsector in both tables to be joined

for (row in 1:length(postsector_data$postsector)) {
  
  postsector_data$postsector[row] = gsub(" ", "", postsector_data$postsector[row])
  
}

for (row in 1:length(postsector_age_structure$postsector)) {
  
  postsector_age_structure$postsector[row] = gsub(" ", "", postsector_age_structure$postsector[row])
  
}

postsector_lt2000_age <- postsector_data %>%
  left_join(postsector_age_structure, by = c("postsector" = "postsector"))

# pop band 8 histogram for current program areas
pop8_hist <- ggplot(postsector_lt2000_age, aes(x=pop8_prop)) +
  geom_histogram() +
  theme_classic() +
  ggtitle("Histogram of % of band 8 population in postsectors with <2000 slots in last 6 months") +
  xlab("Proportion of band 8 population") +
  ylab("Number of postsectors")

# working age (bands 2-7) histogram for current program areas
working_age_hist <- ggplot(postsector_lt2000_age, aes(x=working_age_prop)) +
  geom_histogram() +
  theme_classic() +
  ggtitle("Histogram of % of working age population in postsectors with <2000 slots in last 6 months") +
  xlab("Proportion of working age population") +
  ylab("Number of postsectors")
