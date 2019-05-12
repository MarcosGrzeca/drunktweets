library(tools)

baseResultsFiles <- "ensemblev2/resultados/exp1/v3/"
baseResampleFiles <- "ensemblev2/resample/exp1/"

source(file_path_as_absolute("ipm/experimenters.R"))
source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))
source(file_path_as_absolute("ipm/glove/load.R"))

#Section: Dados classificar
dados <- getDadosBaselineByQ("q1")
try({
	save <- 1
	maxlen <- 38
	max_words <- 7574
	source(file_path_as_absolute("ensemblev2/run/networkglove/ipmtrain_cnn_glove.R"))
	#source(file_path_as_absolute("ensemblev2/git.R"))
})
