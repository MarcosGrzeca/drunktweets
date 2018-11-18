library(tools)

imageFile <- "ensemble/resultados/exp3/imageFileSVMVw2.RData"

datasetFile <-"ensemble/datasets/exp3/2-Gram-dbpedia-types-enriquecimento-info-q3-not-null_info_entidades.Rda"

baseResultsFiles <- "ensemble/resultados/exp3/"
baseResampleFiles <- "ensemble/resample/exp3/"

fileResults <- "ensemble/resultados/exp3/"

source(file_path_as_absolute("ensemble/run/svm/core_adpatado.R"))