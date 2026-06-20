# 02_eda.R — Exploratory analysis of EU NUTS-2 regional development data

library(dplyr)
library(ggplot2)
library(tidyr)

dir.create("figures", showWarnings = FALSE)

train <- read.csv("data/regions_train.csv", stringsAsFactors = FALSE)
train$dev_class <- factor(train$dev_class,
                          levels = c("meno_sviluppata","transizione","piu_sviluppata"))

pred_labels <- c(
  unemp_rate      = "Disoccupazione (%)",
  educ_tertiary   = "Istruzione terziaria (%)",
  rnd_gdp_pct     = "Spesa R&S (% PIL)",
  hitech_emp_pct  = "Impiego high-tech (%)",
  broadband_pct   = "Banda larga famiglie (%)"
)
class_colors <- c(meno_sviluppata = "#d73027",
                  transizione     = "#fee08b",
                  piu_sviluppata  = "#1a9850")

# ── Boxplots per predictor × class ──────────────────────────────────────────
long <- train %>%
  select(dev_class, names(pred_labels)) %>%
  pivot_longer(-dev_class, names_to = "variable", values_to = "value") %>%
  mutate(variable = factor(variable, levels = names(pred_labels),
                           labels = pred_labels))

p_box <- ggplot(long, aes(dev_class, value, fill = dev_class)) +
  geom_boxplot(outlier.size = 0.8, alpha = 0.85) +
  facet_wrap(~variable, scales = "free_y", ncol = 3) +
  scale_fill_manual(values = class_colors, guide = "none") +
  scale_x_discrete(labels = c("Meno sv.", "Transiz.", "Più sv.")) +
  labs(x = NULL, y = NULL,
       title = "Distribuzione dei predittori per categoria di sviluppo (training set)") +
  theme_minimal(base_size = 10) +
  theme(strip.text = element_text(size = 8))
ggsave("figures/boxplots.png", p_box, width = 8, height = 5, dpi = 150)

# ── Scatter: disoccupazione vs istruzione, colorato per classe ────────────────
p_scatter <- ggplot(train, aes(unemp_rate, educ_tertiary, color = dev_class)) +
  geom_point(size = 2, alpha = 0.8) +
  scale_color_manual(values = class_colors,
                     labels = c("Meno sviluppata","Transizione","Più sviluppata"),
                     name = "Categoria") +
  labs(x = "Tasso di disoccupazione (%)",
       y = "Istruzione terziaria (% pop. 25-64)",
       title = "Disoccupazione vs Istruzione per categoria di sviluppo") +
  theme_minimal()
ggsave("figures/scatter_unemp_educ.png", p_scatter, width = 7, height = 4.5, dpi = 150)

# ── Correlation matrix ────────────────────────────────────────────────────────
cor_mat <- train %>%
  select(names(pred_labels)) %>%
  cor(use = "complete.obs")

# Save as CSV for report
write.csv(round(cor_mat, 3), "output/cor_matrix.csv")

cat("EDA complete. Figures: boxplots.png, scatter_unemp_educ.png\n")
cat("\nCorrelazioni principali:\n")
print(round(cor_mat, 2))
