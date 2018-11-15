library(tools)

imageFile <- "ensemble/resultados/exp5/imageFile.RData"

datasetFile <-"chat/rdas/2gram-entidades-erro.Rda"

baseResultsFiles <- "ensemble/resultados/exp5/"
baseResampleFiles <- "ensemble/resample/exp5/"

fileResults <- "ensemble/resultados/exp5/"

source(file_path_as_absolute("ensemble/run/core.R"))