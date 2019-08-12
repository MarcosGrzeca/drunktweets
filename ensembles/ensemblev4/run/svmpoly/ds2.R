library(tools)

source(file_path_as_absolute("ipm/experimenters.R"))
source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))

baseResultsFiles <- "ensembles/ensemblev4/resultados/ds2/"
baseResampleFiles <- "ensembles/ensemblev2/resample/ds2/"
embeddingsFile <- "adhoc/redemaluca/ds2/dados/oficial/ensemble/ds2_with_PCA_50.RData"

try({
	source(file_path_as_absolute("ensembles/ensemblev4/run/svmpoly/svmpoly_core_new.R"))
})
