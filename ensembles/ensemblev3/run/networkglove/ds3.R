library(tools)

baseResultsFiles <- "ensemblev3/resultados/ds3/"
baseResampleFiles <- "ensemblev2/resample/ds3/"

source(file_path_as_absolute("ipm/experimenters.R"))
source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/getDadosAmazon.R"))
source(file_path_as_absolute("utils/tokenizer.R"))
source(file_path_as_absolute("ipm/glove/load.R"))

#Section: Dados classificar
dados <- getDadosAmazon()

try({
	save <- 1
	maxlen <- 38
	max_words <- 9052
	source(file_path_as_absolute("ensemblev3/run/networkglove/ipmtrain_cnn_glove.R"))
})
