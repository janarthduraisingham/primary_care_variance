# Purpose: this script generates a histogram of the distribution of missing or bad data across GPs and identifies practices 
# falling under extreme quantiles

# Import libraries
library(tidyverse)

# Import data 
raw_data <- read_csv("data/task_dataset.csv")

# Create save directory
if (!dir.exists("output")) {
  
  dir.create("output")
  
}

if (!dir.exists("output/data_integrity_opportunity")) {
  
  dir.create("output/data_integrity_opportunity")
  
}

# Sum columns indicating missing or bad data points
bad_data <- raw_data %>%
  filter(icb_name %in% c("NHS North Central London Integrated Care Board",
                         "NHS North West London Integrated Care Board",
                         "NHS North East London Integrated Care Board",
                         "NHS South East London Integrated Care Board",
                         "NHS South West London Integrated Care Board"
  )) %>%
  filter(icb_name == "NHS North Central London Integrated Care Board") %>% # COMMENT OUT TO LOOK AT ALL LONDON ICBS
  select(gp_code,
         AttendanceOutcome_Unknown,
         ApptModality_Unknown,
         BookingtoApptGap_UnknownDataIssue) %>%
  mutate(bad_datapoints = rowSums(across(c(AttendanceOutcome_Unknown, ApptModality_Unknown,BookingtoApptGap_UnknownDataIssue)), na.rm = TRUE))

# PLot histogram of number of bad datapoints

bad_data_hist <- ggplot(bad_data, aes(x=bad_datapoints)) +
  geom_histogram() +
  theme_classic() +
  ggtitle("Histogram of total bad data points per GP practice") +
  xlab("Total Bad Datapoints") +
  ylab("Frequency")

ggsave("output/data_integrity_opportunity/bad_missing_data_histogram.png", bad_data_hist)

opportunities <- filter(bad_data, bad_datapoints >= 1000)$gp_code

write.csv(opportunities, "output/data_integrity_opportunity/gps_with_data_integrity_opportunity.csv")
         