# Manuscript-ready grouped bar plot: P / N / U means x 4 clusters
## Mean +/- SEM across 18 participants, with individual points
## ============================================================

## ---- 0. Packages -------------------------------------------------------
required_pkgs <- c("tidyverse")
new_pkgs <- required_pkgs[!(required_pkgs %in% installed.packages()[, "Package"])]
if (length(new_pkgs)) install.packages(new_pkgs)
library(tidyverse)


out_path    <- "/Users/sgardy/UF Dropbox/Sarah Gardy/LabFiles/Paper Drafts/ImageryPaper/beta_bar_plot.pdf"                  # output file (pdf/png/tiff/eps)
cond_labels  <- c(P = "Pleasant", N = "Neutral", U = "Unpleasant")  # legend labels
cond_colors  <- c(Pleasant = "#91cf60", Neutral = "#006ba6ff", Unpleasant = "#d81134ff")      # bar colors
show_points  <- TRUE     # overlay individual participant points?
y_lab        <- "Mean Betas"
y_breaks     <- seq(-0.5, 0.5, by = 0.1)   # y-axis tick spacing (edit e.g. to 0.5)
x_lab         <- "Clusters"

df <- readxl::read_xlsx("/Volumes/ELEMENTS/imagery/fmri/beta_paramod_emovneu.xlsx")

long <- df %>%
  pivot_longer(-Participant, names_to = "colname", values_to = "value") %>%
  mutate(
    condition = str_extract(colname, "^[A-Za-z]+"),          # P / N / U
    group     = str_extract(colname, "\\d+"),                # 1-4
    condition = str_remove(condition, "Mean"),
    group     = factor(group, levels = as.character(1:4), labels = group_labels),
    condition = factor(condition, levels = names(cond_labels), labels = cond_labels)
  )

## ---- 3. Summary stats (mean +/- SEM across participants) ----------------
summary_df <- long %>%
  group_by(group, condition) %>%
  summarise(
    n    = n(),
    mean = mean(value, na.rm = TRUE),
    sd   = sd(value, na.rm = TRUE),
    sem  = sd / sqrt(n),
    .groups = "drop"
  )

## ---- 4. Plot ---------------------------------------------------------
p <- ggplot(summary_df, aes(x = group, y = mean, fill = condition)) +
  geom_col(
    position = position_dodge(width = 0.75),
    width = 0.7, color = "black", linewidth = 0.4
  ) +
  geom_errorbar(
    aes(ymin = mean - sem, ymax = mean + sem),
    position = position_dodge(width = 0.75),
    width = 0.25, linewidth = 0.5, color = "black"
  ) +
  { if (show_points)
    geom_point(
      data = long,
      aes(x = group, y = value, fill = condition),
      position = position_jitterdodge(jitter.width = 0.08, dodge.width = 0.75),
      size = 1.8, alpha = 0.55, shape = 21, color = "black", stroke = 0.5,
      show.legend = FALSE
    )
  } +
  geom_hline(yintercept = 0, linewidth = 0.6, color = "black") +
  scale_fill_manual(values = setNames(cond_colors, cond_labels)) +
  scale_y_continuous(breaks = y_breaks  # y-axis tick spacing (edit e.g. to 0.5)
) +
  labs(x = x_lab, y = y_lab, fill = NULL) +
  theme_classic(base_size = 14) +
  theme(
    axis.line        = element_line(linewidth = 0.5, color = "black", ),
    axis.ticks       = element_line(linewidth = 0.5, color = "black"),
    axis.text        = element_text(color = "black"),
    legend.position  = "bottom",
    legend.key.size  = unit(0.4, "cm"),
    plot.margin      = margin(1, 1, 1, 1)
  )

print(p)


p <- ggplot(long, aes(x = condition, y = value, fill = condition)) +
  # group mean bars
  stat_summary(fun = mean, geom = "bar", fill = cond_colors, width = 0.6) +
  # error bars (SEM)
  stat_summary(fun.data = mean_se, geom = "errorbar", width = 0.2) +
  # individual subject dots connected by lines
  geom_point(aes(group = Participant, fill = condition, colour = "black"), 
             size = 3, alpha = 0.5, shape = 21, show.legend = FALSE) +
  geom_line(aes(group = Participant), alpha = 0.35) +
  scale_fill_manual(values = cond_colors) +
  scale_colour_manual(values = cond_colors) + # for dots and lines
 scale_y_continuous(breaks = y_breaks) +
  labs(x = x_lab, y = y_lab, fill = NULL) +
  theme_classic(base_size = 14) 

print(p)

ggsave(out_path, plot = p, width = 4.5, height = 4.5, units = "in", dpi = 300)
