library(tools)

datasetFile <-"rdas/2gram-entidades-hora-erro-semkeywords.Rda"
baseResultsFiles <- "ensemblev2/resultados/exp4/"
baseResampleFiles <- "ensemblev2/resample/exp4/"

coreCustomizado <- 2

try({
	source(file_path_as_absolute("ensemblev2/run/svm/core.R"))
	# source(file_path_as_absolute("ensemblev2/git.R"))
})
