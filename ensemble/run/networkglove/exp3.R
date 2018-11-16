library(tools)

imageFile <- "ensemble/resultados/exp3/imageFileRede.RData"

baseResultsFiles <- "ensemble/resultados/exp3/"
baseResampleFiles <- "ensemble/resample/exp3/"

fileResults <- "ensemble/resultados/exp3/"

source(file_path_as_absolute("ipm/experimenters.R"))
source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))
# source(file_path_as_absolute("ipm/glove/load.R"))

#Section: Dados classificar
dados <- getDadosBaseline()

try({
	source(file_path_as_absolute("ensemble/run/networkglove/ipmtrain_embedding.R"))
})
resultados$F1
resultados$Precision
resultados$Recall