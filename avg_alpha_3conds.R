#Alpha statistics on 2-second alpha (10-12s)

setwd("/Volumes/ELEMENTS/imagery/eeg")
my_colors <- c("Pl" = "#91cf60", "N" = "#006ba6ff", "Un" = "#d81134ff")

alphastats <- readxl::read_xlsx("/Volumes/ELEMENTS/imagery/eeg/alpha2s_stats_nobsl.xlsx")
alphastats_long <- pivot_longer(
  alphastats, 
  cols = c(Pl, N, Un), 
  names_to = "Condition", 
  values_to = "Value"
) %>%
  mutate(Condition = factor(Condition, levels = c("Pl", "N", "Un"))) 

alpha_earlybsl <- readxl::read_xlsx("/Volumes/ELEMENTS/imagery/eeg/alpha2s_stats_earlybsl.xlsx")
alphastats_early_long <- pivot_longer(
  alpha_earlybsl, 
  cols = c(Pl, N, Un), 
  names_to = "Condition", 
  values_to = "Value"
) %>%
  mutate(Condition = factor(Condition, levels = c("Pl", "N", "Un"))) 

alpha_latebsl <- readxl::read_xlsx("/Volumes/ELEMENTS/imagery/eeg/alpha2s_stats_latebsl.xlsx")
alphastats_late_long <- pivot_longer(
  alpha_latebsl, 
  cols = c(Pl, N, Un), 
  names_to = "Condition", 
  values_to = "Value"
) %>%
  mutate(Condition = factor(Condition, levels = c("Pl", "N", "Un"))) 


ggplot(alphastats_long, aes(x = Condition, y = Value, fill = Condition)) +
  geom_boxplot(alpha = 0.5, width = 0.4, outlier.shape = NA) +
  geom_line(aes(group = Par), color = "gray40", alpha = 0.4, linewidth = 0.6) +
  geom_point(aes(color = Condition), size = 3) +
  scale_fill_manual(values = my_colors) +
  scale_color_manual(values = my_colors) +
  scale_x_discrete(labels = c("Pl" = "Pleasant", "N" = "Neutral", "Un" = "Unpleasant")) +
  theme_minimal() +
  labs(
    title = "Alpha Power By Condition",
    x = "Condition",
    y = "Alpha Power (µV)"
  ) +
  theme_classic(base_size = 18) +
  theme(legend.position = "none" )




### Violin Plots ####
ggplot(alphastats_early_long, aes(x = Condition, y = Value, fill = Condition)) +
  # 1. Violin plot shows the true shape of the distribution
  geom_violin(alpha = 0.3, width = 0.5, color = NA, trim = TRUE) +
  # 2. Boxplot (narrowed) stays to show the median and quartiles
  geom_boxplot(alpha = 0.5, width = 0.15, outlier.shape = NA, color = "black") +
  # 3. Paired lines show the within-subject direction of change
  geom_line(aes(group = Par), color = "gray40", alpha = 0.5, linewidth = 0.5) +
  # 4. Individual points show the exact sample size and spread
  geom_point(aes(color = Condition), size = 3, alpha = 0.8) +
  scale_x_discrete(
    labels = c("Pl" = "Pleasant", "N" = "Neutral", "Un" = "Unpleasant"),
    expand = expansion(mult = c(.15, .15)) 
  ) +
  scale_fill_manual(values = my_colors) +
  scale_color_manual(values = my_colors) +
  labs(
    title = "Alpha Power By Condition",
    x = "Condition",
    y = "Alpha Power (µV)"
  ) +
  theme_classic(base_size = 16) +
  theme(
    legend.position = "none",
    plot.title = element_text(hjust = 0.5)
  )

setwd("/UF Dropbox/Sarah Gardy/LabFiles/Paper Drafts/ImageryPaper")
ggsave(
  "imagery_avg_alpha_parbycond.pdf",
  plot = last_plot(),
  scale = 1,
  width = 6,
  height = 6,
  units = c("in"),
  dpi = 300
)
