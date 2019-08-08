library(tools)

source(file_path_as_absolute("ipm/experimenters.R"))
source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))

baseResultsFiles <- "ensembles/ensemblev4/resultados/exp3/"
baseResampleFiles <- "ensembles/ensemblev2/resample/exp3/"

try({
	maxlen <- 38
	max_words <- 3080
	source(file_path_as_absolute("ensembles/ensemblev4/run/xgboost/xgboost_core.R"))
})
