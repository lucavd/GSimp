# Script di installazione pacchetti per GSimp
# Questo script installa tutti i pacchetti necessari da CRAN e Bioconductor

cat("Installazione pacchetti per GSimp...\n\n")

# Pacchetti CRAN
cran_packages <- c(
  "Amelia",
  "abind",
  "doParallel",
  "FNN",
  "foreach",
  "ggplot2",
  "glmnet",
  "knitr",
  "magrittr",
  "markdown",
  "missForest",
  "pheatmap",
  "randomForest",
  "reshape2",
  "vegan",
  "readxl"  # Per leggere file Excel
)

# Pacchetti Bioconductor
bioc_packages <- c(
  "impute",
  "imputeLCMD",
  "ropls"
)

# Funzione per installare pacchetti CRAN se non presenti
install_if_missing <- function(pkg) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat("Installazione", pkg, "da CRAN...\n")
    install.packages(pkg, repos = "https://cloud.r-project.org/")
  } else {
    cat(pkg, "già installato.\n")
  }
}

# Funzione per installare pacchetti Bioconductor se non presenti
install_bioc_if_missing <- function(pkg) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat("Installazione", pkg, "da Bioconductor...\n")
    if (!requireNamespace("BiocManager", quietly = TRUE)) {
      install.packages("BiocManager", repos = "https://cloud.r-project.org/")
    }
    BiocManager::install(pkg, update = FALSE, ask = FALSE)
  } else {
    cat(pkg, "già installato.\n")
  }
}

# Installa pacchetti CRAN
cat("\n=== PACCHETTI CRAN ===\n")
for (pkg in cran_packages) {
  install_if_missing(pkg)
}

# Installa pacchetti Bioconductor
cat("\n=== PACCHETTI BIOCONDUCTOR ===\n")
for (pkg in bioc_packages) {
  install_bioc_if_missing(pkg)
}

cat("\n\nInstallazione completata!\n")
cat("Verifica dei pacchetti installati:\n\n")

# Verifica finale
all_packages <- c(cran_packages, bioc_packages)
missing <- c()

for (pkg in all_packages) {
  if (require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat("✓", pkg, "\n")
  } else {
    cat("✗", pkg, "NON INSTALLATO\n")
    missing <- c(missing, pkg)
  }
}

if (length(missing) > 0) {
  cat("\n\nATTENZIONE: I seguenti pacchetti non sono stati installati correttamente:\n")
  cat(paste(missing, collapse = ", "), "\n")
} else {
  cat("\n\nTutti i pacchetti sono stati installati con successo!\n")
}
