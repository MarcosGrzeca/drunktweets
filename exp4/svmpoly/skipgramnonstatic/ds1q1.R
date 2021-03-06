library(tools)

source(file_path_as_absolute("ipm/experimenters.R"))
source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))

embeddingsFile <- "adhoc/redemaluca/skipgramnonstatic/q1_skipgram_cnn_PCA.RData"

try({
	source(file_path_as_absolute("exp4/svmpoly/svmvalidator.R"))
})
