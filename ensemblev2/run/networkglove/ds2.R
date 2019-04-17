library(tools)

baseResultsFiles <- "ensemblev2/resultados/exp4/"
baseResampleFiles <- "ensemblev2/resample/exp4/"

source(file_path_as_absolute("ipm/experimenters.R"))
source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))
source(file_path_as_absolute("ipm/glove/load.R"))

#Section: Dados classificar
# dados <- getDadosInfoGain()
dados <- getDadosChat()

try({
	maxlen <- 50
	max_words <- 40000
	source(file_path_as_absolute("ensemblev2/run/networkglove/ipmtrain_cnn_glove.R"))
})
resultados$F1
resultados$Precision
resultados$Recall