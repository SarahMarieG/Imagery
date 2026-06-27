library(tidyverse)
library(ggdist)
library(patchwork)

ratings <- readxl::read_xlsx("C:/Users/sarah/Downloads/DemoSAMPostQ.xlsx")

# Pivot to long format
ratings_long <- ratings %>%
  pivot_longer(
    cols = -subject,
    names_to = c("rating_type", "condition"),
    names_pattern = "^(val|ar)_(.+)$"
  ) %>%
  # Add valence category grouping based on condition name
  mutate(
    valence_category = case_when(
      condition %in% c("PerPl", "Erotic11", "ScRew2")  ~ "Pleasant",
      condition %in% c("Neu22", "PerNeu")                ~ "Neutral",
      condition %in% c("Contam1", "PerUn", "SurThr1")     ~ "Unpleasant"
    ),
    rating_type = recode(rating_type, val = "Valence", ar = "Arousal")
  )


library(tidyverse)
library(patchwork)

# --- 1. Summarize to category level per participant ---
df_category <- ratings_long %>%
  group_by(subject, rating_type, valence_category) %>%
  summarise(mean_rating = mean(value, na.rm = TRUE), .groups = "drop") %>%
  mutate(valence_category = factor(valence_category,
                                   levels = c("Pleasant", "Neutral", "Unpleasant")))

# --- 2. Shared elements ---
category_colors <- c(
  "Pleasant"   = "#2980B9",
  "Neutral"    = "#7F8C8D",
  "Unpleasant" = "#C0392B"
)

affective_theme <- theme_classic(base_size = 14) +
  theme(
    legend.position = "none",
    axis.title.x    = element_blank(),
    axis.text.x     = element_text(size = 14),
    plot.title      = element_text(face = "bold", size = 14, hjust = 0.5),
    plot.margin     = margin(t = 5, r = 10, b = 5, l = 5)
  )

# --- 3. Valence panel ---
p_val <- df_category %>%
  filter(rating_type == "Valence") %>%
  ggplot(aes(x = valence_category, y = mean_rating,
             color = valence_category, group = subject)) +
  
  geom_line(aes(group = subject), color = "gray70", alpha = 0.6, linewidth = 0.4) +
  geom_point(size = 2.5, alpha = 0.6) +
  
  stat_summary(aes(group = 1), fun = mean, geom = "line",
               color = "gray30", linewidth = 1.2) +
  stat_summary(aes(group = 1), fun.data = mean_se, geom = "errorbar",
               color = "gray30", width = 0, linewidth = 1.2) +
  stat_summary(aes(group = 1), fun = mean, geom = "point",
               color = "gray30", size = 2.5) +
  
  scale_color_manual(values = category_colors) +
  scale_y_continuous(limits = c(1, 9), breaks = seq(1, 9, 2),
                     expand = expansion(mult = c(0.02, 0.02))) +
  scale_x_discrete(expand = expansion(add = c(0.3, 0.3))) +
  labs(title = "Valence", y = "Mean Rating (1–9)") +
  affective_theme

# --- 4. Arousal panel ---
p_ar <- df_category %>%
  filter(rating_type == "Arousal") %>%
  ggplot(aes(x = valence_category, y = mean_rating,
             color = valence_category, group = subject)) +
  
  geom_line(aes(group = subject), color = "gray70", alpha = 0.6, linewidth = 0.4) +
  geom_point(size = 2.5, alpha = 0.6) +
  
  stat_summary(aes(group = 1), fun = mean, geom = "line",
               color = "gray30", linewidth = 1.2) +
  stat_summary(aes(group = 1), fun.data = mean_se, geom = "errorbar",
               color = "gray30", width = 0, linewidth = 1.2) +
  stat_summary(aes(group = 1), fun = mean, geom = "point",
               color = "gray30", size = 2.5) +
  
  scale_color_manual(values = category_colors) +
  scale_y_continuous(limits = c(1, 9), breaks = seq(1, 9, 2),
                     expand = expansion(mult = c(0.02, 0.02))) +
  scale_x_discrete(expand = expansion(add = c(0.3, 0.3))) +
  labs(title = "Arousal", y = "") +
  affective_theme

# --- 5. Combine and save ---
p_final <- p_val + p_ar +
  plot_layout(widths = c(1, 1)) +
  plot_annotation(
    title   = "Affective Ratings by Condition",
    #caption = "Points are individual participant means. Lines connect the same participant across categories. Error bars reflect ±1 SE of the mean.",
    theme   = theme(
      plot.title   = element_text(hjust = 0.5, face = "bold", size = 14),
      #plot.caption = element_text(size = 9, color = "gray40", hjust = 0),
      plot.margin  = margin(t = 5, r = 5, b = 5, l = 5)
    )
  )

p_final

setwd("/Users/sarah/UF Dropbox/Sarah Gardy/LabFiles/Paper Drafts/ImageryPaper")
ggsave("affective_ratings.pdf", p_final,
       width = 7, height = 4, units = "in", device = cairo_pdf)
