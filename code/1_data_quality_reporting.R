# Purpose: This script creates outputs:
# 1.) a csv data quality summary of the missingness and extreme values in the task dataset
# 2.) frequency histograms/ bar charts for each variable

# Import libraries
library(tidyverse)

# Import raw data
raw_data <- read.csv("data/task_dataset.csv")

### Missingness Report

# Count NAs in each column
missings <- sapply(raw_data, function(x) sum(is.na(x)))
missings <- round(missings / nrow(raw_data), 3) # Convert absolute to proportion to 3dp

# Get minimum and maximum value from each column
mins <- sapply(raw_data, function(x) min(x, na.rm=TRUE))
maxs <- sapply(raw_data, function(x) max(x, na.rm=TRUE))

# join missings, mins, maxs
summary <- data.frame(missings,
                      mins,
                      maxs)

# Sort by descending proportion missing
summary <- data.frame(summary) %>%
  arrange(desc(missings))

# Save to csv
# create output folder
if (!(dir.exists("output"))) {
  
  dir.create("output")
  
}

colnames(summary) <- c("proportion_missing", "min_of_column", "max_of_column")
write.csv(summary, "output/data_quality_summary.csv")

### Variable frequency plots

# Separate continuous (histogram) and discrete (bar chart) variables
continuous_vars <- colnames(raw_data)[sapply(raw_data, function(x) is.numeric(x))]
discrete_vars <- colnames(raw_data[sapply(raw_data, function(x) is.character(x))])

# Remove unwanted variables from plot list
discrete_vars <- setdiff(discrete_vars, c("gp_code",
                                          "pcn_code",
                                          "icb_name",
                                          "postcode"))

# Define function to plot histogram of continuous variable frequencies
plot_frequency_histogram_continuous <- function(colname) {
  
  plot <- ggplot(raw_data, aes(x=!!sym(colname))) +
    geom_histogram() +
    ggtitle(paste0("Frequency Histogram for: ", colname)) +
    xlab(colname) +
    ylab("Frequency") +
    theme_classic()
  
  ggsave(paste0("output/variable_frequency_plots/", colname, "_freq_hist.png"), plot, width=5, height=5)
  
}

# Define function to plot bar chart of discrete variable frequencies
plot_frequency_histogram_discrete <- function(colname) {
  
  plot <- ggplot(raw_data, aes(x=!!sym(colname))) +
    geom_bar(stat='count') +
    ggtitle(paste0("Frequency Bar Chart for: ", colname)) +
    xlab(colname) +
    ylab("Frequency") +
    theme_classic() +
    theme(axis.text.x = element_text(angle = 90, hjust = 1))
  
  ggsave(paste0("output/variable_frequency_plots/", colname, "_freq_bar_chart.png"), plot, width=5, height=5)
  
}

# Create folder for frequency plots
if (!(dir.exists("output/frequency_plots"))) {
  
  dir.create("output/variable_frequency_plots")
  
}

# Generate plots
walk(continuous_vars, plot_frequency_histogram_continuous)
walk(discrete_vars, plot_frequency_histogram_discrete)
