library(tools)

source(file_path_as_absolute("ipm/experimenters.R"))
source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))

embeddingsFile <- "adhoc/redemaluca/ds1/oficial/q3_glove_PCA9.RData"

try({
	source(file_path_as_absolute("exp4/xgboost/xgboost.R"))
})
