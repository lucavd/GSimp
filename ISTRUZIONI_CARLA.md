# Istruzioni per l'imputazione del file carla.xlsx con GSimp

## Panoramica

Questo documento contiene le istruzioni per eseguire l'imputazione dei valori mancanti nel file `carla.xlsx` utilizzando **GSimp** (Gibbs Sampler based Imputation).

## Requisiti

- **R** (versione >= 3.5)
- **RStudio** (consigliato ma opzionale)
- Tutti i pacchetti necessari sono disponibili su CRAN e Bioconductor

## Procedura

### Passo 1: Installazione dei pacchetti

Prima di eseguire l'analisi, è necessario installare tutti i pacchetti richiesti.

**Da terminale:**
```bash
cd /Users/utente/Documents/Projects/GSimp
Rscript install_packages.R
```

**Oppure da RStudio/R console:**
```r
setwd("/Users/utente/Documents/Projects/GSimp")
source("install_packages.R")
```

Questo installerà automaticamente:

#### Pacchetti CRAN:
- Amelia
- abind
- doParallel
- FNN
- foreach
- ggplot2
- glmnet
- knitr
- magrittr
- markdown
- missForest
- pheatmap
- randomForest
- reshape2
- vegan
- readxl (per leggere file Excel)

#### Pacchetti Bioconductor:
- impute
- imputeLCMD
- ropls

**Nota:** L'installazione può richiedere diversi minuti.

### Passo 2: Esecuzione dell'imputazione

Una volta installati i pacchetti, puoi eseguire l'imputazione:

**Da terminale:**
```bash
cd /Users/utente/Documents/Projects/GSimp
Rscript run_gsimp_carla.R
```

**Oppure da RStudio/R console:**
```r
setwd("/Users/utente/Documents/Projects/GSimp")
source("run_gsimp_carla.R")
```

### Passo 3: Verifica dei risultati

Lo script genererà automaticamente i seguenti file:

1. **`carla_imputed.csv`**: Dataset completo con tutti i valori mancanti imputati
2. **`carla_imputation_report.csv`**: Report dettagliato che mostra:
   - Posizione dei valori imputati (riga e colonna)
   - Nome della colonna
   - Valore imputato

## Processo di imputazione

Lo script segue la pipeline raccomandata da GSimp:

1. **Lettura dati**: Caricamento del file Excel
2. **Log-trasformazione**: Per normalizzare i dati
3. **Inizializzazione**: Usando QRILC (Quantile Regression Imputation of Left-Censored data)
4. **Centralizzazione e scaling**: Per l'algoritmo elastic-net
5. **Imputazione GSimp**: 
   - 10 iterazioni globali (`iters_all=10`)
   - 50 iterazioni per variabile (`iters_each=50`)
   - 2 cores paralleli (`n_cores=2`)
   - Modello: glmnet (elastic-net)
6. **Recovery**: Trasformazioni inverse per ottenere i dati nella scala originale
7. **Esportazione**: Salvataggio dei risultati

## Parametri configurabili

Se vuoi modificare i parametri di imputazione, puoi editare il file `run_gsimp_carla.R` alla riga dove viene chiamato `GS_impute()`:

```r
result <- data_raw_log_sc %>% GS_impute(
  ., 
  iters_each = 50,      # Numero iterazioni per variabile
  iters_all = 10,       # Numero iterazioni globali
  initial = data_raw_log_qrilc_sc_df,
  lo = -Inf,            # Limite inferiore (left-censored)
  hi = 'min',           # Limite superiore (minimo per variabile)
  n_cores = 2,          # Numero di cores
  imp_model = 'glmnet_pred'
)
```

### Parametri comuni da modificare:

- **`iters_each`**: Aumenta per maggiore convergenza (es. 100), ma aumenta il tempo di calcolo
- **`iters_all`**: Aumenta per maggiore accuratezza (es. 20)
- **`n_cores`**: Aumenta se hai più cores disponibili per velocizzare il calcolo
- **`hi`**: 
  - `'min'` = minimo per variabile (default per left-censored)
  - `'max'` = massimo per variabile
  - `'mean'` = media per variabile
  - Valore numerico specifico

## Formato del file di input

Il file `carla.xlsx` deve avere il seguente formato:

- **Prima riga**: Intestazioni delle colonne (nomi delle variabili)
- **Prima colonna** (opzionale): ID o nomi dei campioni
- **Celle**: Valori numerici (i valori mancanti possono essere lasciati vuoti o indicati come NA)

Esempio:
```
Sample_ID    Metabolite1    Metabolite2    Metabolite3
Sample1      123.4          NA             567.8
Sample2      234.5          345.6          678.9
Sample3      NA             456.7          789.0
```

## Note importanti

1. **Tempo di esecuzione**: L'imputazione può richiedere diversi minuti a seconda della dimensione del dataset
2. **Missing data type**: GSimp è ottimizzato per dati **left-censored MNAR** (Missing Not At Random), tipici dei dati di metabolomica
3. **Memoria**: Per dataset molto grandi, potrebbe essere necessaria molta RAM
4. **Seed**: Lo script usa `set.seed(123)` per garantire riproducibilità

## Troubleshooting

### Errore: "Package X not found"
Esegui nuovamente `install_packages.R` per installare i pacchetti mancanti.

### Errore durante l'imputazione
Verifica che il file Excel:
- Contenga solo dati numerici (esclusa eventuale prima colonna con ID)
- Non abbia colonne completamente vuote
- Abbia almeno alcuni valori non mancanti per ogni variabile

### L'imputazione è troppo lenta
Riduci i parametri:
- `iters_all = 5`
- `iters_each = 25`

Nota: parametri più bassi riducono l'accuratezza ma aumentano la velocità.

## Riferimenti

Per maggiori dettagli su GSimp, consulta:
- **README.md**: Documentazione completa del metodo
- **Paper**: Wei, R., Wang, J., Jia, E., Chen, T., Ni, Y., & Jia, W. (2017). GSimp: A Gibbs sampler based left-censored missing value imputation approach for metabolomics studies. PLOS Computational Biology.
- **DOI**: [10.1371/journal.pcbi.1005973](https://doi.org/10.1371/journal.pcbi.1005973)

## Supporto

Per problemi o domande, controlla il README originale del progetto o verifica la documentazione dei singoli pacchetti R utilizzati.
