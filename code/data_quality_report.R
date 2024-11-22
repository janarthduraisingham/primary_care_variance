# Purpose: This script creates a csv report describing the missingness in the task dataset

# Import libraries
library(tidyverse)

# Import raw data
raw_data <- read.csv("data/task_dataset.csv")

# Count NAs in each column
missings <- sapply(raw_data, function(x) sum(is.na(x)))
missings <- round(missings / nrow(raw_data), 3) # Convert absolute to 3 decimal place proportion

# Sort by descending proportion missing
missings <- data.frame(missings) %>%
  arrange(desc(missings))

# Save to csv
colnames(missings) <- c("proportion_missing")
write.csv(missings, "output/missingness_report.csv")

                   