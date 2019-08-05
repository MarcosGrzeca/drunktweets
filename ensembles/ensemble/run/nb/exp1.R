library(tools)

imageFile <- "ensemble/resultados/exp1/imageFileNB.RData"

datasetFile <-"ensemble/datasets/exp1/2-Gram-dbpedia-types-enriquecimento-info-q1-not-null_info_entidades.Rda"

baseResultsFiles <- "ensemble/resultados/exp1/"
baseResampleFiles <- "ensemble/resample/exp1/"

fileResults <- "ensemble/resultados/exp1/"

source(file_path_as_absolute("ensemble/run/nb/core.R"))