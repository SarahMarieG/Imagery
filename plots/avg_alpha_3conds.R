#Alpha statistics on 2-second (10-12s) @ 8-12 hz and for parametric modulation alpha
library(dplyr)
library(tidyr)
library(ggplot2)
library(ggdist)
library(patchwork)
library(purrr)

my_colors <- c("P" = "#91cf60", "N" = "#006ba6ff", "Un" = "#d81134ff")

# Alpha (10.4 hz) occipital sensors used in Parametric modulation
# NEED TO CHANGE TO 8-12 HZ?
demeaned <-readxl::read_xlsx("/Volumes/ELEMENTS/imagery/eeg/repmat104stats_occavg_demeaned.xlsx")

demeaned_long <- pivot_longer(
  demeaned, 
  cols = c(P, N, Un),
  names_to = "Condition", 
  values_to = "Value"
) %>%
  mutate(Condition = factor(Condition, levels = c("P", "N", "Un"))) 



# 1. Calculate the group mean and standard error for the summary overlay
summary_df <- demeaned_long %>%
  dplyr::group_by(Condition) %>%
  dplyr::summarise(
    sd = sd(Value),
    se = sd/sqrt(18),
      mean = mean(Value),
      .groups = "drop"
    )



# 2. Plot
ggplot() +
  geom_line(data = demeaned_long, 
            aes(x = Condition, y = Value, group = Par), 
            color = "slategray", alpha = 0.4, linewidth = 0.6) +
  geom_point(data = demeaned_long, 
             aes(x = Condition, y = Value, group = Par), 
             color = "slategray", alpha = 0.25, size = 1.5) +
  
  # Add shaded Standard Error (SEM) region for the population
  geom_ribbon(data = summary_df, 
              aes(x = Condition, ymin = mean - se, ymax = mean + se, group = 1), 
              fill = "firebrick", alpha = 0.15) +
  
  # Draw the overall bold population mean line
  geom_line(data = summary_df, 
            aes(x = Condition, y = mean, group = 1), 
            color = "firebrick", linewidth = 1.3) +
  geom_point(data = summary_df, 
             aes(x = Condition, y = mean), 
             color = "firebrick", size = 3) +
  
  labs(
    title = "Within-Subject Changes Across Conditions (N=18)",
    subtitle = "Faded individual profiles shown under population mean ± SEM",
    x = "Condition",
    y = "Demeaned Alpha Amplitude (µV)"
  ) +
  theme_classic(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold"),
  )






ggplot(demeaned_long, aes(x = Condition, y = Value, fill = Condition)) +
  geom_line(aes(group = Par), color = "gray40", alpha = 0.4, linewidth = 0.6) +
  geom_point(aes(color = Condition), size = 2, alpha = .6) +
  # FIX: Added y = NULL to prevent geom_ribbon from looking for the global 'Value' column
  geom_ribbon(data = summary_df, 
              aes(x = as.numeric(Condition), y = NULL, ymin = mean - se, ymax = mean + se, group = 1), 
              fill = "gray40", alpha = 0.45) +
  
  geom_line(data = summary_df, 
            aes(x = Condition, y = mean, group = 1), 
            color = "gray40", linewidth = 1.3) +
  geom_point(data = summary_df, 
             aes(x = Condition, y = mean), 
             color = "gray40", size = 3) +
  scale_fill_manual(values = my_colors) +
  scale_color_manual(values = my_colors) +
  scale_x_discrete(expand = c(.05, .05), labels = c("P" = "Pleasant", "N" = "Neutral", "U" = "Unpleasant")) +
  theme_classic(base_size = 14) +
  labs(
    x = "Condition",
    y = "Demeaned Alpha Amplitude (µV)"
  ) +
  theme(legend.position = "none")

ggsave(
  "/Users/sgardy/UF Dropbox/Sarah Gardy/LabFiles/Paper Drafts/ImageryPaper/imagery_alpha_nocorr_demeanedbycond.pdf",
  plot = last_plot(),
  scale = 1,
  width = 4,
  height = 4,
  units = c("in"),
  dpi = 300
)




## Parametric Modulation Alpha 
paramalpha_pl <- readxl::read_xlsx("/Volumes/ELEMENTS/imagery/group_alpha4parmod_pleasant_med.xlsx")
paramalpha_n <- readxl::read_xlsx("/Volumes/ELEMENTS/imagery/group_alpha4parmod_neutral_med.xlsx")
paramalpha_un <- readxl::read_xlsx("/Volumes/ELEMENTS/imagery/group_alpha4parmod_unpleasant_med.xlsx")

df_list <- list(
  "P" = paramalpha_pl,
  "N" = paramalpha_n,
  "Un" = paramalpha_un
)

paramalpha_all <- bind_rows(df_list, .id = "Condition") %>%
  pivot_longer(
    cols = -c(Condition, Trials), # Keeps 'Condition' intact. Add other IDs here if needed (e.g., -c(Condition, Subject_ID))
    names_to = "Participant",  # The column name for your old wide headers
    values_to = "Value"    # The column name for the actual data points
  )



summary_param <- paramalpha_all %>%
  dplyr::group_by(Participant, Condition) %>%
  dplyr::summarise(
    sd = sd(Value, na.rm = TRUE),
    se = sd/sqrt(18),
    Value_mean = mean(Value, na.rm = TRUE),
    .groups = "drop"
  )

groupmean <- summary_param %>%
  dplyr::group_by(Condition) %>%
  dplyr::summarise(
    sd = sd(Value_mean, na.rm = TRUE),
    se = sd/sqrt(18),
    grand_mean = mean(Value_mean, na.rm = TRUE),
    .groups = "drop"
  )


# Define the explicit order you want
condition_order <- c("P", "N", "Un")

# Apply this order to both data frames
summary_param$Condition <- factor(summary_param$Condition, levels = condition_order)
groupmean$Condition     <- factor(groupmean$Condition,     levels = condition_order)


ggplot(summary_param, aes(x = Condition, y = Value_mean, fill = Condition)) +
  geom_line(aes(group = Participant), color = "gray40", alpha = 0.4, linewidth = 0.6) +
  geom_point(aes(color = Condition), size = 2, alpha = .6) +
  # FIX: Added y = NULL to prevent geom_ribbon from looking for the global 'Value' column
  geom_ribbon(data = groupmean, 
              aes(x = as.numeric(Condition), y = NULL, ymin = grand_mean - se, ymax = grand_mean + se, group = 1), 
              fill = "gray40", alpha = 0.15) +
  geom_line(data = groupmean, 
            aes(x = Condition, y = grand_mean, group = 1), 
            color = "gray40", linewidth = 1.3) +
  geom_point(data = groupmean, 
             aes(x = Condition, y = grand_mean), 
             color = "gray40", size = 3) +
  scale_fill_manual(values = my_colors) +
  scale_color_manual(values = my_colors) +
  scale_x_discrete(expand = c(.05, .05), labels = c("P" = "Pleasant", "N" = "Neutral", "Un" = "Unpleasant")) +
  theme_classic(base_size = 14) +
  labs(
    x = "Condition",
    y = "Parametric Alpha Amplitude (µV)"
  ) +
  theme(legend.position = "none")


## participant means over condition and demeaned
demeaned_alpha4param <- summary_param %>%
  dplyr::group_by(Participant) %>%
  mutate(condmean = mean(Value_mean)) %>%
  mutate(demeaned = Value_mean - condmean)

grandest_demeaned <- demeaned_alpha4param %>%
  dplyr::group_by(Condition) %>%
  dplyr::summarise(
    sd = sd(demeaned),
    se = sd/sqrt(18),
    mean = mean(demeaned),
    .groups = "drop"
  )


ggplot(demeaned_alpha4param, aes(x = Condition, y = demeaned, fill = Condition)) +
  geom_line(aes(group = Participant), color = "gray40", alpha = 0.4, linewidth = 0.6) +
  geom_point(aes(color = Condition), size = 2, alpha = .6) +
  # FIX: Added y = NULL to prevent geom_ribbon from looking for the global 'Value' column
  geom_ribbon(data = grandest_demeaned, 
              aes(x = as.numeric(Condition), y = NULL, ymin = mean - se, ymax = mean + se, group = 1), 
              fill = "gray40", alpha = 0.15) +
  
  geom_line(data = grandest_demeaned, 
            aes(x = Condition, y = mean, group = 1), 
            color = "gray40", linewidth = 1.3) +
  geom_point(data = grandest_demeaned, 
             aes(x = Condition, y = mean), 
             color = "gray40", size = 3) +
  scale_fill_manual(values = my_colors) +
  scale_color_manual(values = my_colors) +
  scale_x_discrete(expand = c(.05, .05), labels = c("P" = "Pleasant", "N" = "Neutral", "Un" = "Unpleasant")) +
  theme_classic(base_size = 14) +
  labs(
    x = "Condition",
    y = "Parametric Alpha Amplitude (µV)"
  ) +
  theme(legend.position = "none")


ggsave(
  "/Users/sgardy/UF Dropbox/Sarah Gardy/LabFiles/Paper Drafts/ImageryPaper/imagery_alpha4parmod_demeanedcond.pdf",
  plot = last_plot(),
  scale = 1,
  width = 4,
  height = 4,
  units = c("in"),
  dpi = 300
)
