# Purpose: this script generates plots illustrating the engagement of patients with GP Practices
# and identifies GPs that consistently fall in extreme quantiles


# Import libraries
library(tidyverse)

# Import data
raw_data <- read_csv("data/task_dataset.csv")

# Set QUANTILE variable for threshold
QUANTILE <- 0.9

# Create directory for plots
if (!(dir.exists("output"))) {
  
  dir.create("output")
  
}

if (!dir.exists("output/patient_engagement")) {
  
  dir.create("output/patient_engagement")
  
}

# Compute proportion of appointments not attended per practice
metrics <- raw_data %>%
  select(gp_code,
         icb_name,
         numberofpatients,
         AttendanceOutcome_Attended,
         AttendanceOutcome_DNA,
         AttendanceOutcome_Unknown,
         lastgpapptneeds,
         overallexp,
         gpcontactoverall) %>%
  filter(icb_name %in% c("NHS North Central London Integrated Care Board",
                         "NHS North West London Integrated Care Board",  
                         "NHS North East London Integrated Care Board",
                         "NHS South East London Integrated Care Board",
                         "NHS South West London Integrated Care Board"
  )) %>%
  filter(icb_name == "NHS North Central London Integrated Care Board") %>% # COMMENT OUT TO LOOK AT ALL LONDON ICBS
  mutate(total_appointments = AttendanceOutcome_Attended + AttendanceOutcome_DNA + AttendanceOutcome_Unknown) %>% # Compute total number of appointments
  mutate(attended_prop = AttendanceOutcome_Attended / total_appointments, # express outcomes proportionally
         dna_prop = AttendanceOutcome_DNA / total_appointments,
         unknown_prop = AttendanceOutcome_Unknown / total_appointments)

###
### Unattended appointments
###
  
# Plot histogram of proportion of unattended appointments
unattended_hist <- ggplot(metrics, aes(x=dna_prop)) +
  geom_histogram() +
  theme_classic() +
  ggtitle("Histogram of proportion of appointments not attended per practice") +
  xlab("Proportion of appointments not attended") +
  ylab("Frequency")

ggsave("output/patient_engagement/unattended_appointment_proportion_histogram.png", unattended_hist)

# Get GP practices falling in extreme quantiles
high_dna <- metrics %>%
  filter(dna_prop >= quantile(metrics$dna_prop, QUANTILE, na.rm=TRUE)) 

###
### Appointment needs met
###

# Plot histogram of proportion of last appointments where needs where met
needsmet_hist <- ggplot(metrics, aes(x=lastgpapptneeds)) +
  geom_histogram() +
  theme_classic() +
  ggtitle("Histogram of proportion of 'Needs Met' at last appointment") +
  xlab("Proportion of 'Needs Met' answered 'Yes' for last appointment") +
  ylab("Frequency")

ggsave("output/patient_engagement/needs_met_proportion_histogram.png", needsmet_hist)

# Get GP practices falling in extreme quantiles
low_needsmet <- metrics %>%
  filter(lastgpapptneeds <= quantile(metrics$lastgpapptneeds, 1-QUANTILE, na.rm=TRUE))

###
### Overall Experience
### 

# Plot histogram of proportion of 'Good' answered to overall experience 
overallexp_hist <- ggplot(metrics, aes(x=overallexp)) +
  geom_histogram() +
  theme_classic() +
  ggtitle("Histogram of proportion of 'Overall Experience' answered Good") +
  xlab("Proportion of 'Overall Experience' answered Good") +
  ylab("Frequency")

ggsave("output/patient_engagement/overall_experience_good_proportion_histogram.png", overallexp_hist)

# Get GP practices falling in extreme quantiles  
low_overallexp <- metrics %>%
  filter(overallexp <= quantile(metrics$overallexp, 1-QUANTILE, na.rm=TRUE))


# Return list of GP Practices falling in extreme quantiles for all variables of interest
gps_to_support <- Reduce(intersect, list(high_dna$gp_code,
                       low_needsmet$gp_code,
                       low_overallexp$gp_code))

write.csv(gps_to_support, "gps_to_support_gp_codes")