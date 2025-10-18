# Script per l'imputazione di valori mancanti usando GSimp
# File input: carla.xlsx
# ============================================================================

# Impostazioni
options(stringsAsFactors = FALSE)
set.seed(123)  # Per riproducibilità

# Caricamento librerie
cat("Caricamento librerie...\n")
library(magrittr)
library(readxl)
library(imputeLCMD)

# Caricamento codice sorgente GSimp
cat("Caricamento codice sorgente GSimp...\n")
source('Trunc_KNN/Imput_funcs.r')
source('GSimp_evaluation.R')
source('GSimp.R')
source('Impute_wrapper.R')
source('MVI_global.R')

# ============================================================================
# STEP 1: Lettura dati
# ============================================================================
cat("\n=== STEP 1: Lettura dati ===\n")

# Leggi il file Excel
cat("Lettura file carla.xlsx...\n")
data_raw <- read_excel('carla.xlsx')

# Mostra informazioni sul dataset
cat("\nDimensioni dataset:", nrow(data_raw), "righe x", ncol(data_raw), "colonne\n")

# Se la prima colonna contiene ID/nomi dei campioni, impostala come rownames
if (!is.numeric(data_raw[[1]])) {
  cat("Prima colonna non numerica - impostata come nomi delle righe\n")
  rownames(data_raw) <- data_raw[[1]]
  data_raw <- data_raw[, -1]
}

# Converti in dataframe numerico
data_raw <- as.data.frame(data_raw)
data_raw <- data.frame(lapply(data_raw, as.numeric))

# IMPORTANTE: Converti gli zeri in NA (i valori mancanti sono codificati come 0)
cat("\nConversione degli zeri in NA (valori mancanti)...\n")
num_zeros <- sum(data_raw == 0, na.rm = TRUE)
cat("Zeri trovati da convertire:", num_zeros, "\n")
data_raw[data_raw == 0] <- NA

# Analisi valori mancanti
total_values <- nrow(data_raw) * ncol(data_raw)
missing_values <- sum(is.na(data_raw))
missing_percentage <- (missing_values / total_values) * 100

cat("\nAnalisi valori mancanti:\n")
cat("  - Totale valori:", total_values, "\n")
cat("  - Valori mancanti:", missing_values, "\n")
cat("  - Percentuale mancanti:", round(missing_percentage, 2), "%\n")

# Conta valori mancanti per variabile
na_per_var <- colSums(is.na(data_raw))
vars_with_na <- sum(na_per_var > 0)
cat("  - Variabili con valori mancanti:", vars_with_na, "su", ncol(data_raw), "\n")

# Rimuovi colonne con troppi NA (>80% o tutte NA)
threshold <- 0.8
na_proportion <- na_per_var / nrow(data_raw)
cols_to_remove <- which(na_proportion > threshold)

if (length(cols_to_remove) > 0) {
  cat("\nRimozione di", length(cols_to_remove), "colonne con >", threshold*100, "% di valori mancanti\n")
  cat("Colonne rimosse (prime 10):", paste(head(names(data_raw)[cols_to_remove], 10), collapse=", "), "...\n")
  data_raw <- data_raw[, -cols_to_remove]
  cat("Nuove dimensioni:", nrow(data_raw), "righe x", ncol(data_raw), "colonne\n")
  
  # Ricalcola statistiche
  total_values <- nrow(data_raw) * ncol(data_raw)
  missing_values <- sum(is.na(data_raw))
  missing_percentage <- (missing_values / total_values) * 100
  cat("Nuova percentuale mancanti:", round(missing_percentage, 2), "%\n")
}

# ============================================================================
# STEP 2: Pre-processing e Imputazione con GSimp
# ============================================================================
cat("\n=== STEP 2: Imputazione con GSimp ===\n")
cat("Questo processo può richiedere alcuni minuti...\n\n")

# Funzione wrapper con pre-processing completo
# (come da README, include log-trasformazione, QRILC initialization, scaling, ecc.)
pre_processing_GS_wrapper <- function(data) {
  data_raw <- data
  # Log transformation
  data_raw_log <- data_raw %>% log()
  # Initialization con QRILC
  data_raw_log_qrilc <- impute.QRILC(data_raw_log) %>% extract2(1)
  # Centralization and scaling
  data_raw_log_qrilc_sc <- scale_recover(data_raw_log_qrilc, method = 'scale')
  # Data after centralization and scaling
  data_raw_log_qrilc_sc_df <- data_raw_log_qrilc_sc[[1]]
  # Parameters for centralization and scaling (for scaling recovery)
  data_raw_log_qrilc_sc_df_param <- data_raw_log_qrilc_sc[[2]]
  # NA position
  NA_pos <- which(is.na(data_raw), arr.ind = T)
  # NA introduced to log-scaled-initialized data
  data_raw_log_sc <- data_raw_log_qrilc_sc_df
  data_raw_log_sc[NA_pos] <- NA
  # Feed initialized and missing data into GSimp imputation
  result <- data_raw_log_sc %>% GS_impute(., iters_each=50, iters_all=10, 
                                             initial = data_raw_log_qrilc_sc_df,
                                             lo=-Inf, hi= 'min', n_cores=2,
                                             imp_model='glmnet_pred')
  data_imp_log_sc <- result$data_imp
  # Data recovery
  data_imp <- data_imp_log_sc %>% 
    scale_recover(., method = 'recover', 
                  param_df = data_raw_log_qrilc_sc_df_param) %>% 
    extract2(1) %>% exp()
  return(data_imp)
}

# Esegui l'imputazione
cat("Inizio imputazione...\n")
data_imputed <- pre_processing_GS_wrapper(data_raw)

cat("\nImputazione completata!\n")

# ============================================================================
# STEP 3: Salvataggio risultati
# ============================================================================
cat("\n=== STEP 3: Salvataggio risultati ===\n")

# Salva il dataset imputato
output_file <- "carla_imputed.csv"
write.csv(data_imputed, output_file, row.names = TRUE)
cat("Dataset imputato salvato in:", output_file, "\n")

# Crea un report di confronto
cat("\nCreazione report di confronto...\n")

# Identifica le posizioni dei valori imputati
NA_positions <- which(is.na(data_raw), arr.ind = TRUE)

# Crea un dataframe con i valori imputati
if (nrow(NA_positions) > 0) {
  imputed_values <- data.frame(
    Riga = NA_positions[, 1],
    Colonna = NA_positions[, 2],
    Colonna_Nome = colnames(data_raw)[NA_positions[, 2]],
    Valore_Imputato = data_imputed[NA_positions]
  )
  
  report_file <- "carla_imputation_report.csv"
  write.csv(imputed_values, report_file, row.names = FALSE)
  cat("Report valori imputati salvato in:", report_file, "\n")
  
  cat("\nPrime 10 imputazioni:\n")
  print(head(imputed_values, 10))
}

# Statistiche finali
cat("\n=== STATISTICHE FINALI ===\n")
cat("Valori originali (non mancanti):", total_values - missing_values, "\n")
cat("Valori imputati:", missing_values, "\n")
cat("Totale valori nel dataset finale:", nrow(data_imputed) * ncol(data_imputed), "\n")

cat("\n✓ Processo completato con successo!\n")
cat("\nFile output:\n")
cat("  1.", output_file, "- Dataset completo imputato\n")
if (exists("report_file")) {
  cat("  2.", report_file, "- Report dettagliato dei valori imputati\n")
}
