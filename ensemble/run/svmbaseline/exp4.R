library(tools)

imageFile <- "ensemble/resultados/exp4/imageFileBaseline.RData"

datasetFile <- "rdas/3gram-25-baseline.Rda"

baseResultsFiles <- "ensemble/resultados/exp4/"
baseResampleFiles <- "ensemble/resample/exp4/"

fileResults <- "ensemble/resultados/exp4/"

source(file_path_as_absolute("ensemble/run/svmbaseline/core.R"))