library(tools)

source(file_path_as_absolute("ipm/experimenters.R"))
source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))

baseResultsFiles <- "ensemblev3/resultados/exp2/"
baseResampleFiles <- "ensemblev2/resample/exp2/"
embeddingFile <- "adhoc/exportembedding/ds1/q2/cnn_10_epocas_8_filters164.txt"

dados <- getDadosBaselineByQ("q2")

try({
	maxlen <- 38
	max_words <- 4405
	source(file_path_as_absolute("ensemblev3/run/xgboost/xgboost_core.R"))
	# source(file_path_as_absolute("ensemblev2/git.R"))
})
