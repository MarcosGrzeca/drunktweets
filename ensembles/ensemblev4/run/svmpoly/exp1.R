library(tools)

source(file_path_as_absolute("ipm/experimenters.R"))
source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))

baseResultsFiles <- "ensembles/ensemblev4/resultados/exp1/"
baseResampleFiles <- "ensembles/ensemblev2/resample/exp1/"
embeddingsFile <- "adhoc/redemaluca/ds1/oficial/ensemble/q1_with_PCA_13.RData"

try({
	maxlen <- 38
	max_words <- 7574
	source(file_path_as_absolute("ensembles/ensemblev4/run/svmpoly/svmpoly_core.R"))
})
