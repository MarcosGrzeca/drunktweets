library(tools)

imageFile <- "ensemble/resultados/exp6/imageFileRede.RData"

baseResultsFiles <- "ensemble/resultados/exp6/"
baseResampleFiles <- "ensemble/resample/exp6/"

fileResults <- "ensemble/resultados/exp6/"

source(file_path_as_absolute("ipm/experimenters.R"))
source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("utils/getDadosAmazon.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))
source(file_path_as_absolute("ipm/glove/load.R"))

#Section: Dados classificar
dados <- getDadosAmazon()

try({
	save <- 0
	maxlen <- 45
	max_words <- 10000
	source(file_path_as_absolute("ensemble/run/networkglove/ipmtrain_embedding_sem_enriquecimento.R"))
})
resultados$F1
resultados$Precision
resultados$Recall