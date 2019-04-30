library(tools)

source(file_path_as_absolute("ipm/experimenters.R"))
source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))

baseResultsFiles <- "ensemblev2/resultados/exp1/"
baseResampleFiles <- "ensemblev2/resample/exp1/"
embeddingFile <- "adhoc/exportembedding/new_skipgrams_10_epocas_5l.txt"

dados <- getDadosBaselineByQ("q1")

try({
	maxlen <- 38
	max_words <- 7574
	source(file_path_as_absolute("ensemblev2/run/xgboostgloveall/xgboost_core.R"))
	#source(file_path_as_absolute("ensemblev2/git.R"))
})
