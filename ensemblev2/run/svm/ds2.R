library(tools)

datasetFile <-"chat/rdas/2gram-entidades-erro-sem-key-words.Rda"
baseResultsFiles <- "ensemblev2/resultados/ds2/"
baseResampleFiles <- "ensemblev2/resample/ds2/"

# try({
	coreCustomizado <- 5
	source(file_path_as_absolute("ensemblev2/run/svm/core.R"))
	source(file_path_as_absolute("ensemblev2/git.R"))
# })
