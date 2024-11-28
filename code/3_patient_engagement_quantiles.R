# Purpose: this script generates plots illustrating the engagement of patients with GP Practices
# and identifies GPs that consistently fall in extreme quantiles


# Import libraries
library(tidyverse)

# Import data
raw_data <- read_csv("data/task_dataset.csv")

# Set QUANTILE variable for threshold
QUANTILE <- 0.8

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
  #filter(icb_name == "NHS North Central London Integrated Care Board") %>% # COMMENT OUT TO LOOK AT ALL LONDON ICBS
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

write.table(gps_to_support, "output/patient_engagement/gps_to_support_gp_codes.csv",
            col.names = FALSE,
            row.names=FALSE)

# Get under/overindexing for NCL ICB GPs in all 3 extreme quantiles
practices <- metrics %>%
  group_by(icb_name) %>%
  summarise(practices = n()) %>% # Count GP practices per ICB
  ungroup()

extreme_quantile_practices <- metrics %>%
  filter(gp_code %in% gps_to_support) %>% # Get GPs from list to support
  group_by(icb_name) %>%
  summarise(extreme_quantile_practices = n()) %>% # Count multi extreme quantile practices per ICB
  ungroup()

# get indexes for multi extreme quantile practices
indexes <- practices %>%
  left_join(extreme_quantile_practices,
            by = 'icb_name') %>%
  mutate(practice_proportion = practices / sum(practices),
         extreme_quantile_practice_proportion = extreme_quantile_practices / sum(extreme_quantile_practices))

# Plot grouped bar to show under/overindexing
index_plot_data <- indexes %>%
  pivot_longer(cols = c("practice_proportion", "extreme_quantile_practice_proportion"),
               names_to = "proportion_type",
               values_to = "proportion")

index_plot <- ggplot(index_plot_data, aes(x = icb_name, y = proportion, fill = proportion_type)) +
  geom_bar(position = "dodge", stat = "identity") +
  theme_classic() +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.75, hjust=0)) +
  xlab("ICB") +
  ylab("Proportion") +
  ggtitle("Composition of GP practices and triple extreme quantile practices") +
  guides(fill=guide_legend(title="Proportion Type")) +
  scale_fill_discrete(labels = c("Extreme quantile practices", "All practices"))

  
