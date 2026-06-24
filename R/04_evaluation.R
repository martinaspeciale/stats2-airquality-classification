# 04_evaluation.R — Plots and detailed evaluation of classification models

library(ggplot2)
library(dplyr)
library(tidyr)
library(MASS)

dir.create("figures", showWarnings = FALSE)

results  <- readRDS("output/classification_results.rds")
cv_res   <- read.csv("output/knn_cv_results.csv")
lda_fit  <- readRDS("output/lda_fit.rds")

# ── CV error curve for KNN ───────────────────────────────────────────────────
best_K <- cv_res$K[which.min(cv_res$cv_error)]

p_cv <- ggplot(cv_res, aes(K, cv_error)) +
  geom_line(color = "steelblue") +
  geom_point(size = 1.5, color = "steelblue") +
  geom_vline(xintercept = best_K, linetype = "dashed", color = "red") +
  annotate("text", x = best_K + 1.2, y = max(cv_res$cv_error) * 0.97,
           label = paste0("K=", best_K), color = "red", hjust = 0, size = 3.5) +
  labs(title = "Errore di convalida incrociata per KNN",
       x = "K (numero di vicini)", y = "Errore CV medio (10 fold)") +
  theme_minimal()
ggsave("figures/knn_cv_curve.png", p_cv, width = 6, height = 3.5, dpi = 150)

# ── Confusion matrices as heatmaps ───────────────────────────────────────────
plot_cm <- function(cm_table, title) {
  df <- as.data.frame(cm_table)
  colnames(df) <- c("Predetto","Reale","N")
  lvl_labels <- c("Meno sv.", "Transiz.", "Più sv.")
  df$Predetto <- factor(df$Predetto,
    levels = c("meno_sviluppata","transizione","piu_sviluppata"),
    labels = lvl_labels)
  df$Reale <- factor(df$Reale,
    levels = c("meno_sviluppata","transizione","piu_sviluppata"),
    labels = lvl_labels)
  ggplot(df, aes(Reale, Predetto, fill = N)) +
    geom_tile(color = "white") +
    geom_text(aes(label = N), size = 5) +
    scale_fill_gradient(low = "white", high = "#2166ac", name = "N") +
    labs(title = title, x = "Classe reale", y = "Classe predetta") +
    theme_minimal() +
    theme(axis.text = element_text(size = 9))
}

p_knn <- plot_cm(results$knn$cm$table, "Matrice di confusione — KNN")
p_lda <- plot_cm(results$lda$cm$table, "Matrice di confusione — LDA")
p_qda <- plot_cm(results$qda$cm$table, "Matrice di confusione — QDA")
ggsave("figures/cm_knn.png", p_knn, width = 5, height = 4, dpi = 150)
ggsave("figures/cm_lda.png", p_lda, width = 5, height = 4, dpi = 150)
ggsave("figures/cm_qda.png", p_qda, width = 5, height = 4, dpi = 150)

# ── LDA discriminant space plot (LD1 vs LD2) ─────────────────────────────────
train <- read.csv("data/regions_train.csv", stringsAsFactors = FALSE)
predictors <- c("unemp_rate","educ_tertiary","rnd_gdp_pct","hitech_emp_pct","broadband_pct")
X_sc <- scale(train[, predictors])
lda_scores <- predict(lda_fit, newdata = data.frame(X_sc))$x

class_colors <- c(meno_sviluppata = "#d73027",
                  transizione     = "#e6a817",
                  piu_sviluppata  = "#1a9850")

df_ld <- data.frame(LD1 = lda_scores[,1], LD2 = lda_scores[,2],
                    classe = factor(train$dev_class,
                                    levels = c("meno_sviluppata","transizione","piu_sviluppata")))
p_ld <- ggplot(df_ld, aes(LD1, LD2, color = classe)) +
  geom_point(size = 2, alpha = 0.85) +
  scale_color_manual(values = class_colors,
                     labels = c("Meno sviluppata","Transizione","Più sviluppata"),
                     name = "Categoria") +
  labs(title = "Spazio discriminante LDA (training set)",
       x = "Primo discriminante lineare (LD1)",
       y = "Secondo discriminante lineare (LD2)") +
  theme_minimal()
ggsave("figures/lda_space.png", p_ld, width = 7, height = 4.5, dpi = 150)

cat("Evaluation plots saved.\n")
