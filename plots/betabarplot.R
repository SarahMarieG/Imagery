# Manuscript-ready grouped bar plot: P / N / U means x 4 clusters
## Mean +/- SEM across 18 participants, with individual points
## ============================================================

## Packages -------------------------------------------------------
library(tidyverse)

out_path    <- "/Users/sgardy/UF Dropbox/Sarah Gardy/LabFiles/Paper Drafts/ImageryPaper/beta_bar_plot.pdf"                  # output file (pdf/png/tiff/eps)
cond_labels  <- c(Pleasant = "PMean", Neutral = "NMean", Unpleasant = "UMean")  # legend labels
cond_colors  <- c(Pleasant = "#91cf60", Neutral = "#006ba6ff", Unpleasant = "#d81134ff")      # bar colors
show_points  <- TRUE     # overlay individual participant points?
y_lab        <- "Mean Betas"
y_breaks     <- seq(-2, 2, by = 0.5)   # y-axis tick spacing (edit e.g. to 0.5)
x_lab         <- "Clusters"

#df <- readxl::read_xlsx("/Volumes/ELEMENTS/imagery/fmri/beta_paramod_emovneu.xlsx")

df <-readxl::read_xlsx("/Volumes/ELEMENTS/imagery/fmri/group_results_paramod_graymask/Betas/emo_clusts_paramod.xlsx")


long <- df %>%
  pivot_longer(-Participant, names_to = "colname", values_to = "value") %>%
  mutate(
    condition = str_extract(colname, "^[A-Za-z]+"),          # P / N / U
    cluster     = str_extract(colname, "\\d+"),                # 1-6 clusters
    #condition = str_remove(condition, "Mean"),
    condition = factor(condition, levels = names(cond_labels), labels = cond_labels)
  )
long$condition <- factor(long$condition, levels = cond_labels)

## ---- 3. Summary stats (mean +/- SEM across participants) ----------------
summary_df <- long %>%
  group_by(cluster, condition) %>%
  dplyr::summarise(
    n    = dplyr::n(),
    mean = mean(value, na.rm = TRUE),
    sd   = sd(value, na.rm = TRUE),
    sem  = sd / sqrt(n)  )

## ---- 4. Plot ---------------------------------------------------------
p <- ggplot(summary_df, aes(x = cluster, y = mean, fill = condition)) +
  geom_col(
    position = position_dodge(width = 0.75),
    width = 0.7, color = "black", linewidth = 0.4
  ) +
  geom_errorbar(
    aes(ymin = mean - sem, ymax = mean + sem),
    position = position_dodge(width = 0.75),
    width = 0.25, linewidth = 0.5, color = "black"
  ) +
  geom_line(
    data = long,
    aes(x = cluster, y = value, group = interaction(Participant, cluster)),
    position = position_dodge(width = 0.75),
    color = "grey40", alpha = 0.5, linewidth = 0.4,
    inherit.aes = FALSE
  ) +
    geom_point(
      data = long,
      aes(x = cluster, y = value, fill = condition),
      position = position_jitterdodge(jitter.width = 0.08, dodge.width = 0.75),
      size = 1.8, alpha = 0.55, shape = 21, color = "black", stroke = 0.5,
      show.legend = FALSE
    ) +
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





long$condition <- factor(long$condition, levels = cond_labels)
long$cluster   <- factor(long$cluster)   # same levels as summary_df$cluster

n_cond   <- nlevels(long$condition)
dodge_w  <- 0.75

long <- long %>%
  mutate(
    x_pos = as.numeric(cluster) +
      (as.numeric(condition) - (n_cond + 1) / 2) * (dodge_w / n_cond)
  )

dodge <- position_dodge(width = dodge_w)

ggplot(summary_df, aes(x = cluster, y = mean, fill = condition)) +
  geom_col(position = dodge, width = 0.7, color = "black", linewidth = 0.4) +
  geom_errorbar(
    aes(ymin = mean - sem, ymax = mean + sem),
    position = dodge, width = 0.25, linewidth = 0.5, color = "black"
  ) +
  # one line per participant per cluster, running through the 3 conditions
  geom_line(
    data = long,
    aes(x = x_pos, y = value, group = interaction(Participant, cluster)),
    color = "grey40", alpha = 0.5, linewidth = 0.4,
    inherit.aes = FALSE
  ) +
  geom_point(
    data = long,
    aes(x = x_pos, y = value, fill = condition),
    size = 1.8, alpha = 0.9, shape = 21, color = "black", stroke = 0.5,
    show.legend = FALSE, inherit.aes = FALSE
  ) +
  geom_hline(yintercept = 0, linewidth = 0.6, color = "black") +
  scale_fill_manual(values = setNames(cond_colors, cond_labels)) +
  scale_y_continuous(breaks = y_breaks) +
  labs(x = x_lab, y = y_lab, fill = NULL) +
  theme_classic(base_size = 14)

ggsave(out_path, plot = p, width = 4.5, height = 4.5, units = "in", dpi = 300)




####################
library(dplyr); library(ggplot2)

long <- long %>%
  mutate(condition = factor(condition,
                            levels = c("PMean", "NMean", "UMean"),
                            labels = c("Pleasant", "Neutral", "Unpleasant")))

k <- nlevels(long$condition)

# Cousineau-Morey within-subject SEM, computed per cluster
summary_df <- long %>%
  group_by(cluster, Participant) %>% mutate(subj_mean = mean(value)) %>%
  group_by(cluster)              %>% mutate(grand_mean = mean(value)) %>%
  ungroup() %>%
  mutate(value_w = value - subj_mean + grand_mean) %>%
  group_by(cluster, condition) %>%
  dplyr::summarise(
    n     = sum(!is.na(value)),
    mean  = mean(value, na.rm = TRUE),
    sem_w = sd(value_w, na.rm = TRUE) / sqrt(n) * sqrt(k / (k - 1)),
    .groups = "drop"
  )

ggplot(long, aes(x = condition, y = value, fill = condition)) +
  geom_hline(yintercept = 0, linewidth = 0.4, color = "grey30") +
  geom_point(data = summary_df, aes(y = mean),
             shape = 22, size = 4, stroke = 0.9, color = "black") +
  geom_errorbar(data = summary_df,
                aes(y = mean, ymin = mean - sem_w, ymax = mean + sem_w),
                width = 0.25, linewidth = 0.7) +
  geom_line(aes(group = Participant), color = "grey50", alpha = 0.6, linewidth = 0.3) +
  geom_point(shape = 21, size = 2, alpha = 0.65, color = "grey10", stroke = 0.5) +
  scale_fill_manual(values = setNames(cond_colors, levels(long$condition))) +
  scale_y_continuous(
    breaks = scales::breaks_pretty(n = 4),
    labels = function(x) format(x, drop0trailing = TRUE)
  )+
  facet_wrap(~ cluster, nrow = 2, ncol = 3, scales = "free_y",
             labeller = labeller(cluster = function(x) paste("Cluster", x))) +
  labs(x = NULL, y = "Mean beta", fill = NULL) +
  theme_classic(base_size = 13) +
  theme(
    strip.background = element_blank(),
    strip.text       = element_text(face = "bold"),
    axis.text.x      = element_text(color = "black"),   # no rotation needed now
    legend.position  = "none",
   # panel.spacing    = unit(1, "lines")
  )

ggsave("cluster_betas.png", width = 8, height = 6, dpi = 300)




library(tidyr)

contrasts <- long %>%
  select(cluster, Participant, condition, value) %>%
  pivot_wider(names_from = condition, values_from = value) %>%
  mutate(P_minus_U = Pleasant - Unpleasant,
         P_minus_N = Pleasant - Neutral,
         U_minus_N = Unpleasant - Neutral) %>%
  pivot_longer(c(P_minus_U, P_minus_N, U_minus_N),
               names_to = "contrast", values_to = "diff") %>%
  group_by(cluster, contrast) %>%
  dplyr::summarise(m = mean(diff), n = n(),
            ci = qt(.975, n - 1) * sd(diff) / sqrt(n), .groups = "drop")

ggplot(contrasts, aes(x = m, y = contrast)) +
  geom_vline(xintercept = 0, color = "grey40") +
  geom_pointrange(aes(xmin = m - ci, xmax = m + ci)) +
  facet_wrap(~ cluster, nrow = 2) +
  labs(x = "Difference in beta (95% CI)", y = NULL) +
  theme_classic(base_size = 13)









long %>%
  group_by(cluster, condition) %>%
  dplyr::summarise(sem_plain = sd(value) / sqrt(n()), .groups = "drop") %>%
  left_join(summary_df %>% select(cluster, condition, sem_w),
            by = c("cluster", "condition")) %>%
  mutate(ratio = sem_w / sem_plain)
