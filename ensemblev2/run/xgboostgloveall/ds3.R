library(tools)

source(file_path_as_absolute("ipm/experimenters.R"))
source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))
source(file_path_as_absolute("utils/getDadosAmazon.R"))

baseResultsFiles <- "ensemblev2/resultados/ds3/"
baseResampleFiles <- "ensemblev2/resample/ds3/"
embeddingFile <- "adhoc/exportembedding/glove_50epocas_5l.txt"

dados <- getDadosAmazon()

try({
	source(file_path_as_absolute("ensemblev2/run/xgboostgloveall/xgboost_core.R"))
	#source(file_path_as_absolute("ensemblev2/git.R"))
})
