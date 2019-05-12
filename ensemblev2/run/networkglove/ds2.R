library(tools)

baseResultsFiles <- "ensemblev2/resultados/ds2/v3/"
baseResampleFiles <- "ensemblev2/resample/ds2/"

source(file_path_as_absolute("ipm/experimenters.R"))
source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))
source(file_path_as_absolute("ipm/glove/load.R"))

#Section: Dados classificar
# dados <- getDadosInfoGain()
dados <- getDadosChat()
# dados$textEmbedding <- removePunctuation(dados$textEmbedding)

try({
	save <- 1
	maxlen <- 38
	max_words <- 16615
	source(file_path_as_absolute("ensemblev2/run/networkglove/ipmtrain_cnn_glove.R"))
	#source(file_path_as_absolute("ensemblev2/git.R"))
})
