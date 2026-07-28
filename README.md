# stats2-airquality-classification

Living document: decisions, data details, model results.

---

## Fonte dei dati

**Eurostat** — ufficio statistico ufficiale dell'Unione Europea.
API: dataset scaricati con `eurostat::get_eurostat(codice)`.
Schede Eurostat: `tgs00006`, `tgs00010`, `tgs00109`, `tgs00042`,
`tgs00059`, `isoc_r_broad_h`.
Accesso tramite pacchetto R `eurostat` (wrapper ufficiale dell'API Eurostat).

Anno di riferimento: **2021** (anno più recente con dati regionali completi).
Livello geografico: **NUTS-2** (regioni di secondo livello, ~240 regioni UE).

---

## Dataset Eurostat utilizzati

| Codice | Contenuto | Ruolo |
|---|---|---|
| `tgs00006` | PIL pro capite in PPS (% media UE-27) | **Definisce la classe** |
| `tgs00010` | Tasso di disoccupazione | Predittore |
| `tgs00109` | Istruzione terziaria (% pop. 25-64) | Predittore |
| `tgs00042` | Spesa in R&S (% PIL) | Predittore |
| `tgs00059` | Occupazione in settori high-tech (%) | Predittore |
| `isoc_r_broad_h` | Famiglie con accesso banda larga (%) | Predittore |

---

## Variabile risposta

Soglie ufficiali politica di coesione UE (PIL PPS % media UE-27):
- **meno_sviluppata**: PIL < 75%
- **transizione**: 75% ≤ PIL ≤ 100%
- **piu_sviluppata**: PIL > 100%

Il PIL viene usato SOLO per definire la classe, poi rimosso dai predittori.
Questo rende la classificazione non banale: i predittori misurano dimensioni
strutturali indipendenti dal reddito.

---

## Campione

- Regioni iniziali NUTS-2: 285 (dopo filtro EU-27)
- Dopo inner join su tutti e 5 i predittori: **155 regioni** (23 paesi)
- Regioni escluse: principalmente piccole isole/regioni periferiche con dati mancanti
- Split: 75% train (116), 25% test (39), `set.seed(2026)`
- Distribuzione classi: 52 meno sviluppate / 50 transizione / 53 più sviluppate (quasi bilanciato)

---

## Preprocessing

- Standardizzazione (z-score): media 0, SD 1 per tutti i predittori
- Parametri di standardizzazione calcolati sul training set e applicati al test
- Imputation: max 1 NA per riga tollerato (imputato con mediana globale)

---

## Modelli

### KNN
- K scelto tramite 10-fold CV sul training set: **K = 12**
- CV error al minimo: ~0.278 (28% errore CV)
- Test accuracy: 66.7%

### LDA (Linear Discriminant Analysis)
- Assume distribuzioni gaussiane con covarianza comune tra classi
- Frontiere di decisione lineari
- Test accuracy: **82.1%** ← modello migliore

### QDA (Quadratic Discriminant Analysis)
- Covarianza diversa per classe, frontiere quadratiche
- Test accuracy: 74.4%

---

## Risultati sul test set (39 regioni)

| Modello | Accuratezza | Sensitività media | Specificità media |
|---|---|---|---|
| KNN (K=12) | 0.667 | 0.659 | 0.829 |
| LDA | **0.821** | **0.814** | **0.907** |
| QDA | 0.744 | 0.738 | 0.866 |

LDA superiore perché la separazione tra classi è approssimativamente lineare.
La classe "transizione" è la più difficile (confusa con entrambe le adiacenti).
La classe "meno sviluppata" è classificata quasi perfettamente: profilo strutturale distinto.

---

## Decisioni e motivazioni

| Decisione | Motivazione |
|---|---|
| Rimuovere GDP dai predittori | Evita classificazione banale (la classe è definita da GDP) |
| Standardizzazione obbligatoria per KNN | La distanza euclidea è sensibile alla scala |
| Standardizzare anche LDA/QDA | Coefficienti discriminanti comparabili |
| K scelto con CV, non test set | Principio fondamentale: test set solo per valutazione finale |
| Anno 2021 | Più recente con dati completi per tutte le variabili |
| Inner join (non left join) | Nessuna imputation massiva; preferita completezza dei dati |

---

## Compliance con la guida del corso

| Requisito | Stato |
|---|---|
| Fonte certificata (non Kaggle) | ✅ Eurostat (istituzione UE ufficiale, citata dal prof) |
| Dati grezzi con link preciso | ✅ URL API Eurostat nel report |
| Classificazione | ✅ 3 classi (meno sviluppata / transizione / più sviluppata) |
| KNN con CV per K | ✅ 10-fold CV, K=12 |
| LDA e QDA | ✅ Entrambi implementati |
| Matrice di confusione | ✅ Per tutti e 3 i modelli (tabella + heatmap) |
| Accuracy, sensitivity, specificity | ✅ Medie macro per classe |
| Dilemma bias-varianza discusso | ✅ Nella curva CV di KNN |
| Test set usato solo per valutazione finale | ✅ |
| Report PDF ~7 pagine in italiano | ✅ xelatex |
| Codice consegnato separatamente | ✅ File `R/01_load_data.R` – `R/04_evaluation.R` allegati come da consegna (guida richiede solo CSV+PDF+codice, l'appendice nel PDF è opzionale) |
| Dati CSV caricabili | ✅ data/regions_raw.csv |
