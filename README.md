# European Region Development Classification

Project for the Statistica II course at the University of Pisa.

This repository contains a classification analysis on European NUTS-2 regions
using Eurostat data from 2021. The aim is to predict the regional development
class used in EU cohesion policy from socioeconomic indicators other than GDP.

## Data

The data are downloaded from Eurostat through the `eurostat` R package.

Datasets used:

| Code | Content | Role |
|---|---|---|
| `tgs00006` | GDP per capita in PPS, as percentage of the EU average | defines the class |
| `tgs00010` | unemployment rate | predictor |
| `tgs00109` | tertiary education | predictor |
| `tgs00042` | R&D expenditure as percentage of GDP | predictor |
| `tgs00059` | high-tech employment indicator | predictor |
| `isoc_r_broad_h` | household broadband access | predictor |

The response variable has three classes:

| Class | Definition |
|---|---|
| `meno_sviluppata` | GDP per capita below 75% of the EU average |
| `transizione` | GDP per capita between 75% and 100% |
| `piu_sviluppata` | GDP per capita above 100% |

GDP is used only to define the class and is not used as a predictor.

After joining the selected indicators and filtering missing values, the dataset
contains 155 NUTS-2 regions from 23 EU countries. The data are split into 75%
training and 25% test observations.

## Method

The analysis compares three classifiers:

| Model | Description |
|---|---|
| KNN | non-parametric classifier; K selected with 10-fold cross-validation |
| LDA | linear discriminant analysis |
| QDA | quadratic discriminant analysis |

All predictors are standardized before fitting the models. The value of K for
KNN is selected on the training set only, while the test set is reserved for the
final comparison.

## Results

| Model | Accuracy | Macro sensitivity | Macro specificity |
|---|---:|---:|---:|
| KNN | 0.667 | 0.659 | 0.829 |
| LDA | 0.821 | 0.814 | 0.907 |
| QDA | 0.744 | 0.738 | 0.866 |

LDA gives the best test accuracy. The transition class is the most difficult to
classify, while less developed regions are identified more clearly.

## Repository Structure

```text
.
├── R/
│   ├── 01_load_data.R
│   ├── 02_eda.R
│   ├── 03_modeling.R
│   └── 04_evaluation.R
├── data/
├── figures/
├── output/
├── report.Rmd
└── report.pdf
```

## Reproducing the Report

From the repository root:

```r
rmarkdown::render("report.Rmd")
```

The scripts in `R/` can also be run in order to rebuild the dataset, figures
and model outputs.
