library(tools)

source(file_path_as_absolute("ipm/experimenters.R"))
source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))

baseResultsFiles <- "ensemblev3/resultados/ds2/"
baseResampleFiles <- "ensemblev2/resample/ds2/"
embeddingFile <- "adhoc/exportembedding/ds2/cnn_10_epocas_8_filters164.txt"

dados <- getDadosChat()

try({
	source(file_path_as_absolute("ensemblev3/run/xgboost/xgboost_core.R"))
	source(file_path_as_absolute("ensemblev2/git.R"))
})
