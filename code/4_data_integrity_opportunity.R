# Purpose: this script highlights GP practices that present opportunity to improve data collection and collation activities

# Import libraries
library(tidyverse)

# Import data 
raw_data <- read_csv("data/task_dataset.csv")

# Look at data lacking integrity or completeness
bad_data <- raw_data %>%
  filter(icb_name %in% c("NHS North Central London Integrated Care Board",
                         "NHS North West London Integrated Care Board",
                         "NHS North East London Integrated Care Board",
                         "NHS South East London Integrated Care Board",
                         "NHS South West London Integrated Care Board"
  )) %>%
  filter(icb_name == "NHS North Central London Integrated Care Board") %>%
  select(gp_code,
         AttendanceOutcome_Unknown,
         ApptModality_Unknown,
         BookingtoApptGap_UnknownDataIssue) %>%
  mutate(bad_datapoints = rowSums(across(c(AttendanceOutcome_Unknown, ApptModality_Unknown,BookingtoApptGap_UnknownDataIssue)), na.rm = TRUE))

# PLot histogram of bad datapoints

bad_data_hist <- ggplot(bad_data, aes(x=bad_datapoints)) +
  geom_histogram() +
  theme_classic() +
  ggtitle("Histogram of total bad data points per GP practice") +
  xlab("Total Bad Datapoints") +
  ylab("Frequency")

bad_data_hist

filter(bad_data, bad_datapoints >= 1000)$gp_code
         