library(tools)

imageFile <- "ensemble/resultados/exp6/imageFileRF.RData"
datasetFile <- "amazon/rdas/2gram-entidades-erro-pruning.Rda"

baseResultsFiles <- "ensemble/resultados/exp6/"
baseResampleFiles <- "ensemble/resample/exp6/"

fileResults <- "ensemble/resultados/exp6/"

source(file_path_as_absolute("ensemble/run/rf/core.R"))