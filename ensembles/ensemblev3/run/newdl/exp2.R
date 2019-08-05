library(tools)

baseResultsFiles <- "ensemblev3/resultados/exp2/newdl/"
baseResampleFiles <- "ensemblev2/resample/exp2/"
embeddingsFile <- "adhoc/redemaluca/ds1/oficial/ensemble/q2_with_PCA_12.RData"

source(file_path_as_absolute("ipm/experimenters.R"))
source(file_path_as_absolute("utils/getDados.R"))
source(file_path_as_absolute("baseline/dados.R"))
source(file_path_as_absolute("utils/tokenizer.R"))

#Section: Dados classificar
dados <- getDadosBaselineByQ("q2")
try({
	save <- 1
	maxlen <- 38
	max_words <- 4315
	source(file_path_as_absolute("ensemblev3/run/newdl/core.R"))
})
