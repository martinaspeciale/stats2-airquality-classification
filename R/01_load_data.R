# 01_load_data.R
# Download Eurostat data for EU NUTS-2 regions (2021, most recent complete year).
# Response: Cohesion Policy development category derived from GDP per capita (PPS)
#   - "meno_sviluppata"  (less developed):  GDP < 75% EU average
#   - "transizione"      (transition):       75% ≤ GDP ≤ 100%
#   - "piu_sviluppata"   (more developed):   GDP > 100%
# Predictors: unemployment, tertiary education, R&D expenditure, employment in
#             high-tech, broadband access — indicators NOT used to define the class.
#
# Source: Eurostat via eurostat R package (https://ec.europa.eu/eurostat)
# Reference datasets: tgs00006, tgs00010, tgs00109, tgs00042, tgs00059, isoc_r_broad_h

library(eurostat)
library(dplyr)

set.seed(2026)
dir.create("data",   showWarnings = FALSE)
dir.create("output", showWarnings = FALSE)

fetch <- function(code, value_col, year = 2021) {
  message("Fetching ", code, "...")
  df <- tryCatch(
    get_eurostat(code, time_format = "num", cache = TRUE) %>%
      filter(TIME_PERIOD == year, nchar(geo) == 4) %>%   # NUTS-2: 4-char code
      group_by(geo) %>%
      summarise(!!value_col := mean(values, na.rm = TRUE), .groups = "drop"),
    error = function(e) { message("  ✗ ", e$message); NULL }
  )
  if (!is.null(df)) message("  → ", nrow(df), " regions")
  df
}

# GDP per capita in PPS (% of EU average) — defines the response class
gdp_raw <- tryCatch(
  get_eurostat("tgs00006", time_format = "num", cache = TRUE),
  error = function(e) stop("Cannot fetch GDP data: ", e$message)
)
gdp <- gdp_raw %>%
  filter(TIME_PERIOD == 2021, nchar(geo) == 4) %>%
  group_by(geo) %>%
  summarise(gdp_pps_pct = mean(values, na.rm = TRUE), .groups = "drop")
message("GDP: ", nrow(gdp), " NUTS-2 regions")

# Predictors
unemp  <- fetch("tgs00010",      "unemp_rate")      # unemployment rate (%)
educ   <- fetch("tgs00109",      "educ_tertiary")   # tertiary education, % pop 25-64
rnd    <- fetch("tgs00042",      "rnd_gdp_pct")     # R&D expenditure % GDP
hitech <- fetch("tgs00059",      "hitech_emp_pct")  # high-tech employment %
broad  <- fetch("isoc_r_broad_h","broadband_pct")   # broadband households %

# Join all
datasets <- Filter(Negate(is.null), list(gdp, unemp, educ, rnd, hitech, broad))
regions  <- Reduce(function(a, b) inner_join(a, b, by = "geo"), datasets)

# Add country code and drop non-EU / overseas territories
regions <- regions %>%
  mutate(country = substr(geo, 1, 2)) %>%
  filter(
    country %in% c("AT","BE","BG","CY","CZ","DE","DK","EE","EL","ES",
                   "FI","FR","HR","HU","IE","IT","LT","LU","LV","MT",
                   "NL","PL","PT","RO","SE","SI","SK"),
    !is.na(gdp_pps_pct)
  )

# Define 3-class response from GDP per capita (PPS % of EU average)
regions <- regions %>%
  mutate(
    dev_class = case_when(
      gdp_pps_pct <  75  ~ "meno_sviluppata",
      gdp_pps_pct <= 100 ~ "transizione",
      TRUE               ~ "piu_sviluppata"
    ),
    dev_class = factor(dev_class,
                       levels = c("meno_sviluppata","transizione","piu_sviluppata"))
  )

# Drop GDP (it defines the class — must not be a predictor)
predictors <- c("unemp_rate","educ_tertiary","rnd_gdp_pct","hitech_emp_pct","broadband_pct")
aq <- regions %>% select(geo, country, dev_class, all_of(predictors))

# Remove regions with too many NAs in predictors
aq <- aq %>% filter(rowSums(is.na(select(., all_of(predictors)))) <= 1)

# Impute remaining single NAs with column median (within class)
for (col in predictors) {
  med <- median(aq[[col]], na.rm = TRUE)
  aq[[col]][is.na(aq[[col]])] <- med
}

stopifnot(nrow(aq) >= 100, !anyNA(aq))

write.csv(aq, "data/regions_raw.csv",   row.names = FALSE)
write.csv(regions, "data/regions_full.csv", row.names = FALSE)

# Train/test split 75/25
n         <- nrow(aq)
train_idx <- sample(seq_len(n), size = floor(0.75 * n))
train     <- aq[train_idx, ]
test      <- aq[-train_idx, ]

write.csv(train, "data/regions_train.csv", row.names = FALSE)
write.csv(test,  "data/regions_test.csv",  row.names = FALSE)

cat(sprintf("\nDataset: %d regioni NUTS-2  (%d train / %d test)\n", n, nrow(train), nrow(test)))
cat("Distribuzione classi:\n"); print(table(aq$dev_class))
cat("\nPaesi presenti:", length(unique(aq$country)), "\n")
cat("Predittori:", paste(predictors, collapse=", "), "\n")
