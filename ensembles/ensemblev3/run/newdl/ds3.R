library(tools)

baseResultsFiles <- "ensemblev3/resultados/ds3/newdl/"
baseResampleFiles <- "ensemblev2/resample/ds3/"
embeddingsFile <- "adhoc/redemaluca/ds3/oficial/ensemble/ds3_with_PCA_15.RData"

source(file_path_as_absolute("ipm/experimenters.R"))
source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/getDadosAmazon.R"))
source(file_path_as_absolute("utils/tokenizer.R"))

#Section: Dados classificar
dados <- getDadosAmazon()

try({
	save <- 1
	maxlen <- 38
	max_words <- 9052
	source(file_path_as_absolute("ensemblev3/run/newdl/core.R"))
})
