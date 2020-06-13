library(tools)

source(file_path_as_absolute("ipm/experimenters.R"))
source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))

embeddingsFile <- "ipmbilstm/exportembedding/ds3/ds3_representacao_with_bilstm_pca_15.RData"

try({
	source(file_path_as_absolute("exp4/svmpoly/svmvalidator.R"))
})
