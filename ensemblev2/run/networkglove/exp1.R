library(tools)

baseResultsFiles <- "ensemble/resultados/exp1/"
baseResampleFiles <- "ensemble/resample/exp1/"

fileResults <- "ensemble/resultados/exp1/"

source(file_path_as_absolute("ipm/experimenters.R"))
source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))
source(file_path_as_absolute("ipm/glove/load.R"))

#Section: Dados classificar
dados <- getDadosBaselineByQ("q1")
try({
	maxlen <- 38
	max_words <- 7000
	source(file_path_as_absolute("ensemblev2/run/networkglove/ipmtrain_embedding.R"))
	#source(file_path_as_absolute("ensemblev2/git.R"))
})
