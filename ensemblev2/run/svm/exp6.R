library(tools)

datasetFile <- "amazon/rdas/2gram-entidades-erro.Rda"
baseResultsFiles <- "ensemblev2/resultados/exp6/"
baseResampleFiles <- "ensemblev2/resample/exp6/"

try({
	coreCustomizado <- 2
	source(file_path_as_absolute("ensemblev2/run/svm/core.R"))
	source(file_path_as_absolute("ensemblev2/git.R"))
})