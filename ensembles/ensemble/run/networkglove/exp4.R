library(tools)

imageFile <- "ensemble/resultados/exp4/imageFileRede.RData"

baseResultsFiles <- "ensemble/resultados/exp4/"
baseResampleFiles <- "ensemble/resample/exp4/"

fileResults <- "ensemble/resultados/exp4/"

source(file_path_as_absolute("ipm/experimenters.R"))
source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))
source(file_path_as_absolute("ipm/glove/load.R"))

#Section: Dados classificar
# dados <- getDadosInfoGain()
dados <- getDadosSemKeyWords()

try({
	maxlen <- 50
	max_words <- 40000
	source(file_path_as_absolute("ensemble/run/networkglove/ipmtrain_embedding.R"))
})
resultados$F1
resultados$Precision
resultados$Recall