library(tools)

imageFile <- "ensemble/resultados/exp4/imageFile.RData"

datasetFile <-"rdas/2gram-entidades-hora-erro.Rda"

baseResultsFiles <- "ensemble/resultados/exp4/"
baseResampleFiles <- "ensemble/resample/exp4/"

fileResults <- "ensemble/resultados/exp4/"

source(file_path_as_absolute("ensemble/run/core.R"))