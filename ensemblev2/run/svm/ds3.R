library(tools)

datasetFile <- "amazon/rdas/2gram-entidades-erro.Rda"
baseResultsFiles <- "ensemblev2/resultados/ds3/"
baseResampleFiles <- "ensemblev2/resample/ds3/"

try({
	coreCustomizado <- 2
	source(file_path_as_absolute("ensemblev2/run/svm/core.R"))
	# source(file_path_as_absolute("ensemblev2/git.R"))
})