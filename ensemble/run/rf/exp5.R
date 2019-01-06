library(tools)

# imageFile <- "ensemble/resultados/exp5/imageFileRF.RData"
# datasetFile <-"chat/rdas/2gram-entidades-erro.Rda"

imageFile <- "ensemble/resultados/exp5/imageFileRF-sem-key-words.RData"
datasetFile <-"chat/rdas/2gram-entidades-erro-sem-key-words.Rda"

baseResultsFiles <- "ensemble/resultados/exp5/"
baseResampleFiles <- "ensemble/resample/exp5/"

fileResults <- "ensemble/resultados/exp5/"

source(file_path_as_absolute("ensemble/run/rf/core.R"))