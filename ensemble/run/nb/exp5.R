library(tools)

# imageFile <- "ensemble/resultados/exp5/imageFileNB.RData"
# datasetFile <-"chat/rdas/2gram-entidades-erro.Rda"

imageFile <- "ensemble/resultados/exp5/imageFileNB_semkeywords.RData"
datasetFile <-"chat/rdas/2gram-entidades-erro-sem-key-words.Rda"


baseResultsFiles <- "ensemble/resultados/exp5/"
baseResampleFiles <- "ensemble/resample/exp5/"

fileResults <- "ensemble/resultados/exp5/"

source(file_path_as_absolute("ensemble/run/nb/core.R"))