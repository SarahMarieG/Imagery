library(tidyverse)
library(dplyr)
library(ggplot2)
library(Rmisc)


#iresp = read.csv("group_iresp_curves.csv")
iresp = read.csv("/Volumes/ELEMENTS/imagery/frontal_iresp_curves.csv")
iresp = read.csv("/Volumes/ELEMENTS/imagery/group_iresp_curves.csv")

#iresp <- iresp %>% filter(subject %in% c("par_02"))

# summary_iresp <-
#   iresp %>%
#   group_by(condition, time) %>%
#   summarise(
#     mean = mean(value, na.rm=TRUE),
#     sd = sd(value, na.rm=TRUE),
#     n = n(),
#     se = sd/sqrt(n),
#     .groups="drop"
#   )


summary_iresp <- iresp %>%
  summarySEwithin(
    measurevar = "value",
    withinvars = c("condition", "time"),
    idvar = "subject"
  )


#my_colors <- c("Pl" = "#91cf60", "N" = "#006ba6ff", "Un" = "#d81134ff")

# Plot ####
  ggplot(summary_iresp,
         aes(x=time,
             y=value,
             group = condition,
             color=condition,
             fill=condition)) +
  geom_line(size=1.3) +
  geom_ribbon(
    aes(
      ymin=value-se,
      ymax=value+se
    ),
    alpha=.20,
    colour=NA
  ) +
  
  scale_color_manual(values=c(
    pleasant="#91cf60",
    neutral="#006ba6ff",
    unpleasant="#d81134ff"
  )) +
  
  scale_fill_manual(values=c(
    pleasant="#91cf60",
    neutral="#006ba6ff",
    unpleasant="#d81134ff"
  )) +
  
  labs(
    x="TR",
    y="Mean iresp",
    title="ROI IRESP Curves"
  ) +
  theme_classic(base_size=15)


# Save figure ####
ggsave(
  "/Volumes/ELEMENTS/imagery/group_iresp_curves.png",
  p,
  width=8,
  height=5,
  dpi=300
)

### Peak of each condition
peak_table <-
  summary_iresp %>%
  group_by(condition) %>%
  max(value, n=1)

print(peak_table)

write_csv(
  peak_table,
  "/Volumes/ELEMENTS/imagery/group_peak_times.csv"
)


##########################

dat2 <-
  iresp %>%
  mutate(condition2 =
           ifelse(condition == "neutral",
                  "Neutral",
                  "Emotional"))

##########################################
# Average pleasant + unpleasant
# within each participant
##########################################

subject_means <-
  dat2 %>%
  group_by(subject, condition2, time) %>%
  summarise(
    value = mean(value),
    .groups = "drop"
  )

##########################################
# Group mean and SEM
##########################################

group_summary <-
  subject_means %>%
  group_by(condition2, time) %>%
  summarise(
    mean = mean(value),
    sd = sd(value),
    n = n(),
    se = sd/sqrt(n),
    .groups = "drop"
  )

##########################################
# Plot
##########################################

ggplot(group_summary,
       aes(time,
           mean,
           colour = condition2,
           fill = condition2)) +
  
  geom_line(linewidth = 1.3) +
  
  geom_ribbon(aes(ymin = mean-se,
                  ymax = mean+se),
              alpha = .25,
              colour = NA) +
  
  scale_colour_manual(values = c(
    "Neutral" = "#006ba6ff",
    "Emotional" = "#d81134ff"
  )) +
  
  scale_fill_manual(values = c(
    "Neutral" = "#006ba6ff",
    "Emotional" = "#d81134ff"
  )) +
  
  theme_classic(base_size = 15) +
  
  labs(
    x = "TR",
    y = "Mean iresp",
    colour = "",
    fill = ""
  )
