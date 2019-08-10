library(tools)

source(file_path_as_absolute("ipm/experimenters.R"))
source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))

embeddingsFile <- "adhoc/redemaluca/ds3/oficial/ensemble/ds3_with_PCA_15.RData"

try({
	source(file_path_as_absolute("svmoverdl/svmdl.R"))
})
