library(tools)

baseResultsFiles <- "ensemblev3/resultados/ds2/"
baseResampleFiles <- "ensemblev2/resample/ds2/"

source(file_path_as_absolute("ipm/experimenters.R"))
source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))
source(file_path_as_absolute("ipm/glove/load.R"))

#Section: Dados classificar
dados <- getDadosChat()

try({
	save <- 1
	maxlen <- 38
	max_words <- 16615
	source(file_path_as_absolute("ensemblev3/run/networkglove/ipmtrain_cnn_glove.R"))
})
