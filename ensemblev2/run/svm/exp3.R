library(tools)

try ({
	datasetFile <-"ensemble/datasets/exp3/2-Gram-dbpedia-types-enriquecimento-info-q3-not-null_info_entidades.Rda"
	baseResultsFiles <- "ensemblev2/resultados/exp3/"
	baseResampleFiles <- "ensemblev2/resample/exp3/"

	source(file_path_as_absolute("ensemblev2/run/svm/core.R"))
	#source(file_path_as_absolute("ensemblev2/git.R"))
})