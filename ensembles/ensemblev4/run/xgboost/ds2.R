library(tools)

source(file_path_as_absolute("ipm/experimenters.R"))
source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))

baseResultsFiles <- "ensembles/ensemblev4/resultados/ds2/"
baseResampleFiles <- "ensembles/ensemblev2/resample/ds2/"

try({
	source(file_path_as_absolute("ensembles/ensemblev4/run/xgboost/xgboost_core.R"))
})
