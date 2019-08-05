library(tools)

baseResultsFiles <- "ensemblev3/resultados/ds2/newdl/"
baseResampleFiles <- "ensemblev2/resample/ds2/"
embeddingsFile <- "adhoc/redemaluca/ds2/dados/oficial/ensemble/ds2_with_PCA_50.RData"

source(file_path_as_absolute("ipm/experimenters.R"))
source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))

#Section: Dados classificar
dados <- getDadosChat()

try({
	save <- 1
	maxlen <- 38
	max_words <- 16615
	source(file_path_as_absolute("ensemblev3/run/newdl/core.R"))
})
