library(tools)

try({
	datasetFile <-"ensemble/datasets/exp1/2-Gram-dbpedia-types-enriquecimento-info-q1-not-null_info_entidades.Rda"
	baseResultsFiles <- "ensemblev2/resultados/exp1/"
	baseResampleFiles <- "ensemblev2/resample/exp1/"
	source(file_path_as_absolute("ensemblev2/run/svm/core.R"))
	# source(file_path_as_absolute("ensemblev2/git.R"))
})
